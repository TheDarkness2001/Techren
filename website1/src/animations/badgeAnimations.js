import { anime, easings, prefersReducedMotion } from './utils';

export function playBadgeHint(node) {
  if (!node || prefersReducedMotion()) {
    if (node) node.style.opacity = '1';
    return;
  }
  anime({
    targets: node,
    opacity: [0, 1],
    translateY: [10, 0],
    delay: 1600,
    duration: 700,
    easing: easings.out,
  });
}

export function hideBadgeHint(node, onDone) {
  if (!node || prefersReducedMotion()) {
    onDone?.();
    return;
  }
  anime({
    targets: node,
    opacity: 0,
    translateY: 8,
    duration: 280,
    easing: easings.out,
    complete: onDone,
  });
}

export function playWelcome(node) {
  if (!node) return;
  node.hidden = false;
  if (prefersReducedMotion()) {
    window.setTimeout(() => {
      node.hidden = true;
    }, 1400);
    return;
  }
  anime.remove(node);
  anime({
    targets: node,
    opacity: [0, 1, 1, 0],
    translateY: [12, 0, 0, -8],
    duration: 1800,
    easing: easings.out,
    complete: () => {
      node.hidden = true;
    },
  });
}
