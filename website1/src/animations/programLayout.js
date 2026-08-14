import { createLayout, stagger } from 'animejs4';
import { prefersReducedMotion } from './utils';

const GRID_COUNT = 4;
const HOLD_BETWEEN_MS = 2200;
const ANIM_MS = 900;

/**
 * Anime.js Auto Layout — keeps cycling forever in the background.
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

  let i = Number(stage.dataset.grid) || 1;
  let alive = true;
  let timeline = null;
  let waitId = 0;
  let running = false;

  const clearWait = () => {
    if (waitId) {
      window.clearTimeout(waitId);
      waitId = 0;
    }
  };

  const scheduleNext = (ms = HOLD_BETWEEN_MS) => {
    clearWait();
    if (!alive) return;
    waitId = window.setTimeout(() => {
      waitId = 0;
      tick();
    }, ms);
  };

  const tick = () => {
    if (!alive || running) return;
    running = true;

    try {
      timeline?.pause?.();
      timeline?.cancel?.();
    } catch {
      /* ignore */
    }

    timeline = layout.update(
      () => {
        i = (i % GRID_COUNT) + 1;
        stage.dataset.grid = String(i);
      },
      {
        duration: ANIM_MS,
        ease: 'out(3)',
        delay: stagger(70, { from: 'center' }),
        onComplete: () => {
          running = false;
          scheduleNext(HOLD_BETWEEN_MS);
        },
      },
    );

    // Safety: if onComplete never fires, keep the loop alive
    clearWait();
    waitId = window.setTimeout(() => {
      if (!alive) return;
      if (running) {
        running = false;
        scheduleNext(400);
      }
    }, ANIM_MS + 2500);
  };

  const startId = window.setTimeout(() => {
    if (alive) tick();
  }, 500);

  const replayBtn = root.querySelector('[data-layout-replay]');
  const onReplay = () => {
    if (!alive) return;
    running = false;
    clearWait();
    tick();
  };
  replayBtn?.addEventListener('click', onReplay);

  return () => {
    alive = false;
    running = false;
    window.clearTimeout(startId);
    clearWait();
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
