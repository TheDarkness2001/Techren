import { anime, easings, prefersReducedMotion, q, qa } from './utils';

export function playLoader(root, onComplete) {
  const finish = () => {
    root.classList.add('is-done');
    window.setTimeout(onComplete, prefersReducedMotion() ? 0 : 280);
  };

  if (prefersReducedMotion()) {
    anime.set(qa(root, '.loader-letter, .loader-line, .loader-mark'), { opacity: 1, translateY: 0, scaleX: 1 });
    finish();
    return;
  }

  const tl = anime.timeline({ easing: easings.out });

  tl.add({
    targets: q(root, '.loader-mark'),
    opacity: [0, 1],
    scale: [0.86, 1],
    duration: 420,
  })
    .add(
      {
        targets: qa(root, '.loader-letter'),
        opacity: [0, 1],
        translateY: [22, 0],
        delay: anime.stagger(42),
        duration: 480,
      },
      '-=180'
    )
    .add(
      {
        targets: q(root, '.loader-line'),
        scaleX: [0, 1],
        duration: 420,
      },
      '-=280'
    )
    .add(
      {
        targets: root,
        opacity: [1, 0],
        duration: 380,
        easing: 'easeInQuad',
        complete: finish,
      },
      '+=180'
    );
}

export function animateThemeTransition(originEl, onSwap) {
  const overlay = document.createElement('div');
  overlay.className = 'theme-wipe';
  overlay.setAttribute('aria-hidden', 'true');
  document.body.appendChild(overlay);

  if (originEl) {
    const rect = originEl.getBoundingClientRect();
    overlay.style.setProperty('--wipe-x', `${rect.left + rect.width / 2}px`);
    overlay.style.setProperty('--wipe-y', `${rect.top + rect.height / 2}px`);
  } else {
    overlay.style.setProperty('--wipe-x', '50%');
    overlay.style.setProperty('--wipe-y', '0%');
  }

  if (prefersReducedMotion()) {
    onSwap();
    overlay.remove();
    return;
  }

  anime({
    targets: overlay,
    opacity: [0, 1],
    duration: 220,
    easing: 'easeOutQuad',
    complete: () => {
      onSwap();
      anime({
        targets: overlay,
        opacity: [1, 0],
        duration: 480,
        easing: easings.out,
        complete: () => overlay.remove(),
      });
    },
  });
}

export function playNavbarSolid(nav, solid) {
  if (prefersReducedMotion()) {
    nav.classList.toggle('is-solid', solid);
    return;
  }

  nav.classList.toggle('is-solid', solid);
  anime({
    targets: nav,
    backdropFilter: solid ? 'blur(16px)' : 'blur(0px)',
    duration: 420,
    easing: easings.out,
  });
}
