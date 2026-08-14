import { anime, easings, prefersReducedMotion, q, qa, revealOnce, setImmediateVisible } from './utils';

export function playWhy(root) {
  return revealOnce(root, () => {
    if (prefersReducedMotion()) {
      setImmediateVisible(qa(root, '.why-card, .section-heading, .section-lead, .why-icon'));
      return;
    }

    const tl = anime.timeline({ easing: easings.out });
    tl.add({
      targets: qa(root, '.why-card'),
      opacity: [0, 1],
      translateY: [40, 0],
      delay: anime.stagger(100),
      duration: 720,
    }).add(
      {
        targets: qa(root, '.why-icon span'),
        scale: [0.6, 1],
        opacity: [0, 1],
        delay: anime.stagger(90),
        duration: 520,
      },
      '-=560'
    );
  });
}

export function playProgramming(root) {
  return () => {};
}

export function playEnglish(root) {
  return revealOnce(root, () => {
    if (prefersReducedMotion()) {
      setImmediateVisible(qa(root, '.english-skill, .english-extra, .section-heading, .section-lead, .section-kicker'));
      return;
    }

    anime({
      targets: qa(root, '.english-skill'),
      opacity: [0, 1],
      translateX: [-24, 0],
      delay: anime.stagger(90),
      duration: 720,
      easing: easings.out,
    });

    anime({
      targets: qa(root, '.english-extra'),
      opacity: [0, 1],
      translateY: [20, 0],
      delay: anime.stagger(70, { start: 200 }),
      duration: 560,
      easing: easings.out,
    });
  });
}

export function playProjects(root) {
  return revealOnce(root, () => {
    if (prefersReducedMotion()) return;
    anime({
      targets: qa(root, '.project-card'),
      opacity: [0, 1],
      translateY: [32, 0],
      delay: anime.stagger(70),
      duration: 680,
      easing: easings.out,
    });
  });
}

export function playApp(root) {
  return revealOnce(root, () => {
    if (prefersReducedMotion()) return;

    anime({
      targets: qa(root, '.device'),
      opacity: [0, 1],
      translateY: [48, 0],
      rotate: [3, 0],
      delay: anime.stagger(140),
      duration: 900,
      easing: easings.outSoft,
    });

    anime({
      targets: qa(root, '.float-card'),
      opacity: [0, 1],
      translateY: [24, 0],
      delay: anime.stagger(80, { start: 280 }),
      duration: 640,
      easing: easings.out,
    });
  });
}

export function playParents(root) {
  return revealOnce(root, () => {
    if (prefersReducedMotion()) return;
    anime({
      targets: qa(root, '.parent-card'),
      opacity: [0, 1],
      translateY: [28, 0],
      delay: anime.stagger(80),
      duration: 640,
      easing: easings.out,
    });
  });
}

export function playFounder(root) {
  return revealOnce(root, () => {
    const frame = q(root, '.founder-frame');
    if (prefersReducedMotion()) {
      if (frame) frame.style.clipPath = 'inset(0% 0 0 0)';
      return;
    }

    anime({
      targets: frame,
      clipPath: ['inset(0 0 100% 0)', 'inset(0 0 0% 0)'],
      opacity: [0.4, 1],
      duration: 1100,
      easing: easings.outSoft,
    });

    anime({
      targets: qa(root, '.founder-copy > *'),
      opacity: [0, 1],
      translateY: [22, 0],
      delay: anime.stagger(90, { start: 180 }),
      duration: 680,
      easing: easings.out,
    });
  });
}

export function playStory(root) {
  return revealOnce(root, () => {
    if (prefersReducedMotion()) return;
    anime({
      targets: qa(root, '.story-block'),
      opacity: [0, 1],
      translateY: [30, 0],
      delay: anime.stagger(120),
      duration: 760,
      easing: easings.out,
    });
  });
}

export function playTimeline(root) {
  const fill = q(root, '.day-line-fill');
  const items = qa(root, '.day-item');

  const onScroll = () => {
    const rect = root.getBoundingClientRect();
    const view = window.innerHeight;
    const start = view * 0.75;
    const progress = Math.min(1, Math.max(0, (start - rect.top) / (rect.height + start * 0.2)));
    if (fill) fill.style.transform = `scaleY(${progress})`;

    items.forEach((item, i) => {
      const threshold = (i + 0.2) / items.length;
      item.classList.toggle('is-active', progress > threshold);
    });
  };

  const cleanupReveal = revealOnce(root, () => {
    if (prefersReducedMotion()) {
      items.forEach((item) => item.classList.add('is-active'));
      if (fill) fill.style.transform = 'scaleY(1)';
      return;
    }
    anime({
      targets: items,
      opacity: [0, 1],
      translateX: [24, 0],
      delay: anime.stagger(80),
      duration: 600,
      easing: easings.out,
    });
  });

  onScroll();
  window.addEventListener('scroll', onScroll, { passive: true });
  return () => {
    cleanupReveal();
    window.removeEventListener('scroll', onScroll);
  };
}

export function playStats(root) {
  return revealOnce(root, () => {
    qa(root, '.stat-value[data-count]').forEach((el) => {
      const end = Number(el.dataset.count);
      if (Number.isNaN(end) || prefersReducedMotion()) {
        if (!Number.isNaN(end)) el.textContent = String(end);
        return;
      }
      const obj = { n: 0 };
      anime({
        targets: obj,
        n: end,
        round: 1,
        duration: 1400,
        easing: easings.outSoft,
        update: () => {
          el.textContent = String(obj.n);
        },
      });
    });
  });
}

export function playCTA(root) {
  return revealOnce(root, () => {
    if (prefersReducedMotion()) {
      setImmediateVisible(q(root, '.cta-title'));
      return;
    }
    anime({
      targets: q(root, '.cta-title'),
      opacity: [0, 1],
      translateY: [36, 0],
      duration: 860,
      easing: easings.outSoft,
    });
  });
}

export function playGeneric(root, itemSelector) {
  return revealOnce(root, () => {
    if (!itemSelector) return;
    if (prefersReducedMotion()) {
      setImmediateVisible(qa(root, itemSelector));
      return;
    }
    anime({
      targets: qa(root, itemSelector),
      opacity: [0, 1],
      translateY: [28, 0],
      delay: anime.stagger(70),
      duration: 640,
      easing: easings.out,
    });
  });
}
