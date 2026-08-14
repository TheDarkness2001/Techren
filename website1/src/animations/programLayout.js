import { createLayout, stagger } from 'animejs4';
import { prefersReducedMotion } from './utils';

const GRID_COUNT = 4;

/**
 * Anime.js Auto Layout — cycles the programming path between bento grid sizes.
 */
export function startProgramLayout(root) {
  if (!root) return () => {};

  const stage = root.querySelector('[data-program-layout]');
  if (!stage) return () => {};

  if (prefersReducedMotion()) {
    stage.dataset.grid = '1';
    return () => {};
  }

  const layout = createLayout(stage, {
    children: '.program-layout-item',
  });

  let i = 0;
  let alive = true;
  let timeline = null;

  const tick = () => {
    if (!alive) return;
    timeline = layout.update(
      () => {
        i = (i % GRID_COUNT) + 1;
        stage.dataset.grid = String(i);
      },
      {
        duration: 900,
        ease: 'out(3)',
        delay: stagger(70, { from: 'center' }),
        onComplete: () => {
          if (!alive) return;
          window.setTimeout(tick, 2200);
        },
      },
    );
  };

  // Start after a beat so the section is visible
  const startId = window.setTimeout(tick, 600);

  const replayBtn = root.querySelector('[data-layout-replay]');
  const onReplay = () => {
    if (!alive) return;
    try {
      timeline?.pause?.();
      timeline?.cancel?.();
    } catch {
      /* ignore */
    }
    tick();
  };
  replayBtn?.addEventListener('click', onReplay);

  return () => {
    alive = false;
    window.clearTimeout(startId);
    replayBtn?.removeEventListener('click', onReplay);
    try {
      timeline?.pause?.();
      timeline?.cancel?.();
      layout.revert?.();
    } catch {
      /* ignore */
    }
  };
}
