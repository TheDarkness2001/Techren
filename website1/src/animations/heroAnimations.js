import { anime, easings, prefersReducedMotion, q, qa, setImmediateVisible } from './utils';

export function playHero(root) {
  const brand = q(root, '.hero-brand');
  const words = qa(root, '.hero-word');
  const ctas = qa(root, '.hero-ctas > *');
  const label = q(root, '.hero-label');
  const desc = q(root, '.hero-desc');

  if (prefersReducedMotion()) {
    setImmediateVisible([brand, label, desc, ...words, ...ctas]);
    root.classList.add('is-ready');
    return;
  }

  anime.set([brand, label, desc, ...ctas], { opacity: 0, translateY: 24 });
  anime.set(words, { opacity: 0, translateY: 52, rotate: 1.5 });

  const tl = anime.timeline({ easing: easings.out });

  tl.add({
    targets: q(root, '.hero-grid'),
    opacity: [0, 1],
    duration: 700,
  })
    .add(
      {
        targets: brand,
        opacity: [0, 1],
        translateY: [18, 0],
        duration: 520,
      },
      '-=420'
    )
    .add(
      {
        targets: label,
        opacity: [0, 1],
        translateY: [20, 0],
        duration: 560,
      },
      '-=280'
    )
    .add(
      {
        targets: words,
        opacity: [0, 1],
        translateY: [52, 0],
        rotate: [1.5, 0],
        delay: anime.stagger(150),
        duration: 860,
      },
      '-=220'
    )
    .add(
      {
        targets: desc,
        opacity: [0, 1],
        translateY: [22, 0],
        duration: 640,
      },
      '-=480'
    )
    .add(
      {
        targets: ctas,
        opacity: [0, 1],
        translateY: [18, 0],
        delay: anime.stagger(80),
        duration: 560,
        complete: () => root.classList.add('is-ready'),
      },
      '-=400'
    );
}
