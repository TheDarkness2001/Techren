import { anime, easings, isFinePointer, prefersReducedMotion, qa } from './utils';

export function bindMagnetic(el, strength = 0.28) {
  if (!el || !isFinePointer() || prefersReducedMotion()) return () => {};

  const onMove = (event) => {
    const rect = el.getBoundingClientRect();
    const x = event.clientX - rect.left - rect.width / 2;
    const y = event.clientY - rect.top - rect.height / 2;
    anime({
      targets: el,
      translateX: x * strength,
      translateY: y * strength,
      duration: 360,
      easing: easings.out,
    });
  };

  const onLeave = () => {
    anime({
      targets: el,
      translateX: 0,
      translateY: 0,
      duration: 520,
      easing: easings.outSoft,
    });
  };

  el.addEventListener('mousemove', onMove);
  el.addEventListener('mouseleave', onLeave);
  return () => {
    el.removeEventListener('mousemove', onMove);
    el.removeEventListener('mouseleave', onLeave);
  };
}

export function bindMagnetics(root, selector = '.magnetic') {
  const cleanups = qa(root, selector).map((el) => bindMagnetic(el));
  return () => cleanups.forEach((fn) => fn());
}

export function bindProjectHovers(root) {
  if (!isFinePointer() || prefersReducedMotion()) return () => {};

  const cards = qa(root, '.project-card');
  const cleanups = cards.map((card) => {
    const visual = card.querySelector('.project-visual');
    const title = card.querySelector('.project-title');
    const arrow = card.querySelector('.project-arrow');

    const enter = () => {
      anime({ targets: visual, scale: 1.06, duration: 520, easing: easings.out });
      anime({ targets: title, translateY: -4, duration: 420, easing: easings.out });
      anime({ targets: arrow, translateX: 6, duration: 420, easing: easings.out });
    };

    const leave = () => {
      anime({ targets: visual, scale: 1, duration: 520, easing: easings.out });
      anime({ targets: title, translateY: 0, duration: 420, easing: easings.out });
      anime({ targets: arrow, translateX: 0, duration: 420, easing: easings.out });
    };

    card.addEventListener('mouseenter', enter);
    card.addEventListener('mouseleave', leave);
    return () => {
      card.removeEventListener('mouseenter', enter);
      card.removeEventListener('mouseleave', leave);
    };
  });

  return () => cleanups.forEach((fn) => fn());
}

export function bindTechField(field) {
  if (!field) return () => {};
  const badges = qa(field, '.field-badge');
  if (!isFinePointer() || prefersReducedMotion()) return () => {};

  let frame = 0;
  let pointer = { x: 0, y: 0, inside: false };

  const onMove = (event) => {
    const rect = field.getBoundingClientRect();
    pointer = {
      x: event.clientX - rect.left,
      y: event.clientY - rect.top,
      inside: true,
    };
    if (!frame) frame = requestAnimationFrame(tick);
  };

  const onLeave = () => {
    pointer.inside = false;
    if (!frame) frame = requestAnimationFrame(tick);
  };

  const tick = () => {
    frame = 0;
    badges.forEach((badge) => {
      const x = Number(badge.dataset.x);
      const y = Number(badge.dataset.y);
      const w = field.clientWidth;
      const h = field.clientHeight;
      const cx = (x / 100) * w;
      const cy = (y / 100) * h;
      const dx = pointer.x - cx;
      const dy = pointer.y - cy;
      const dist = Math.hypot(dx, dy);
      const radius = Math.min(w, h) * 0.32;
      const force = pointer.inside ? Math.max(0, 1 - dist / radius) : 0;
      const tx = pointer.inside ? dx * force * -0.12 : 0;
      const ty = pointer.inside ? dy * force * -0.12 : 0;
      badge.style.transform = `translate(-50%, -50%) translate3d(${tx}px, ${ty}px, 0)`;
      badge.style.setProperty('--proximity', force.toFixed(3));
    });

    if (!pointer.inside) {
      badges.forEach((badge) => {
        badge.style.transform = 'translate(-50%, -50%)';
        badge.style.setProperty('--proximity', '0');
      });
      return;
    }
    frame = requestAnimationFrame(tick);
  };

  field.addEventListener('mousemove', onMove);
  field.addEventListener('mouseleave', onLeave);
  return () => {
    field.removeEventListener('mousemove', onMove);
    field.removeEventListener('mouseleave', onLeave);
    if (frame) cancelAnimationFrame(frame);
  };
}
