import anime from 'animejs/lib/anime.es.js';

export { anime };

export const easings = {
  out: 'cubicBezier(0.16, 1, 0.3, 1)',
  outSoft: 'cubicBezier(0.22, 1, 0.36, 1)',
  inOut: 'cubicBezier(0.65, 0, 0.35, 1)',
  expo: 'easeOutExpo',
  quart: 'easeOutQuart',
};

export function prefersReducedMotion() {
  return typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

export function isFinePointer() {
  return typeof window !== 'undefined' && window.matchMedia('(hover: hover) and (pointer: fine)').matches;
}

export function isMobileViewport() {
  return typeof window !== 'undefined' && window.matchMedia('(max-width: 768px)').matches;
}

export function q(root, selector) {
  return root.querySelector(selector);
}

export function qa(root, selector) {
  return Array.from(root.querySelectorAll(selector));
}

export function revealOnce(el, onEnter, options = {}) {
  if (!el) return () => {};

  const run = () => {
    el.classList.add('is-inview');
    onEnter?.(el);
  };

  if (prefersReducedMotion()) {
    run();
    return () => {};
  }

  const io = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          run();
          io.unobserve(el);
        }
      });
    },
    { threshold: 0.16, rootMargin: '0px 0px -10% 0px', ...options }
  );

  io.observe(el);
  return () => io.disconnect();
}

export function setImmediateVisible(targets) {
  anime.set(targets, { opacity: 1, translateY: 0, translateX: 0, scale: 1, clipPath: 'inset(0% 0% 0% 0%)' });
}
