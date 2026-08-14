import { anime, easings, prefersReducedMotion } from './utils';

export const STAGE_RANGES = [
  { id: 'intro', code: '01', kicker: 'PROGRAMMING', name: 'INTRO', from: 0, to: 0.1 },
  { id: 'html', code: '01', kicker: 'FOUNDATION', name: 'HTML', from: 0.08, to: 0.24 },
  { id: 'css', code: '02', kicker: 'FOUNDATION', name: 'CSS', from: 0.2, to: 0.36 },
  { id: 'js', code: '03', kicker: 'CORE', name: 'JAVASCRIPT', from: 0.32, to: 0.5 },
  { id: 'python', code: '04', kicker: 'CORE', name: 'PYTHON', from: 0.46, to: 0.64 },
  { id: 'java', code: '05', kicker: 'CORE', name: 'JAVA', from: 0.6, to: 0.78 },
  { id: 'react', code: '06', kicker: 'APPLIED', name: 'REACT', from: 0.74, to: 0.92 },
  { id: 'outro', code: '06', kicker: 'APPLIED', name: 'REACT', from: 0.88, to: 1 },
];

function clamp(n, min = 0, max = 1) {
  return Math.max(min, Math.min(max, n));
}

function local(p, from, to) {
  return clamp((p - from) / Math.max(0.0001, to - from));
}

function reveal(nodes, t, start, stagger, dur = 0.1) {
  nodes.forEach((node, i) => {
    const v = clamp((t - start - i * stagger) / dur);
    node.style.opacity = String(v);
    node.style.transform = `translate3d(0, ${(1 - v) * 12}px, 0)`;
  });
}

export function isCinematicJourney() {
  return !prefersReducedMotion() && window.matchMedia('(min-width: 900px)').matches;
}

export function createJourneyApplier(root) {
  const qs = (sel) => root.querySelector(sel);
  const qsa = (sel) => Array.from(root.querySelectorAll(sel));

  const world = qs('.journey-world');
  const grid = qs('.journey-grid');
  const lines = qs('.journey-lines');
  const hud = qs('.journey-hud');
  const hudCode = qs('[data-jw="hud-code"]');
  const hudKicker = qs('[data-jw="hud-kicker"]');
  const hudFill = qs('[data-jw="hud-fill"]');
  const hudDot = qs('[data-jw="hud-dot"]');
  const htmlPreview = qs('[data-jw="html-preview"]');
  const cssPreview = qs('[data-jw="css-preview"]');
  const jsBtn = qs('[data-jw="js-btn"]');
  const jsCount = qs('[data-jw="js-count"]');
  const jsNote = qs('[data-jw="js-note"]');
  const pyCursor = qs('[data-jw="py-cursor"]');
  const reactTree = qs('[data-jw="react-tree"]');
  const reactApp = qs('[data-jw="react-app"]');

  const htmlLines = qsa('[data-jw="html-line"]');
  const cssLines = qsa('[data-jw="css-line"]');
  const jsLines = qsa('[data-jw="js-line"]');
  const jsChips = qsa('[data-jw="js-chip"]');
  const pyLines = qsa('[data-jw="py-line"]');
  const pyBars = qsa('[data-jw="py-bar"]');
  const javaLines = qsa('[data-jw="java-line"]');
  const javaObjs = qsa('[data-jw="java-obj"]');
  const reactParts = qsa('[data-jw="react-part"]');
  const outroLines = qsa('[data-jw="outro-line"]');

  let lastStage = '';
  const panels = 7;

  return function apply(p, cinematic) {
    const x = cinematic ? -p * panels * 100 : 0;
    if (world) {
      world.style.transform = cinematic ? `translate3d(${x}vw, 0, 0)` : 'none';
    }
    if (grid) {
      grid.style.transform = `translate3d(${-p * 10}%, 0, 0)`;
    }
    if (lines) {
      lines.style.transform = `translate3d(${-p * 16}%, 0, 0)`;
    }

    const htmlP = local(p, 0.08, 0.24);
    const cssP = local(p, 0.2, 0.36);
    const jsP = local(p, 0.32, 0.5);
    const pyP = local(p, 0.46, 0.64);
    const javaP = local(p, 0.6, 0.78);
    const reactP = local(p, 0.74, 0.92);
    const outroP = local(p, 0.88, 1);

    reveal(htmlLines, htmlP, 0.08, 0.07, 0.12);
    reveal(cssLines, cssP, 0.1, 0.07, 0.12);
    reveal(jsLines, jsP, 0.08, 0.08, 0.12);
    reveal(pyLines, pyP, 0.08, 0.07, 0.1);
    reveal(javaLines, javaP, 0.1, 0.06, 0.1);
    reveal(outroLines, outroP, 0.05, 0.12, 0.2);

    if (htmlPreview) {
      const show = clamp((htmlP - 0.42) / 0.28);
      htmlPreview.style.opacity = String(show);
      htmlPreview.style.transform = `translate3d(0, ${(1 - show) * 18}px, 0)`;
    }

    if (cssPreview) {
      cssPreview.style.setProperty('--styled', String(cssP));
      cssPreview.style.opacity = String(clamp(0.35 + cssP * 0.65));
    }

    if (jsBtn) {
      const beat = jsP > 0.28 ? 1 + Math.sin(jsP * Math.PI * 6) * 0.06 : 1;
      const scale = (0.86 + jsP * 0.22) * beat;
      const lift = Math.sin(jsP * Math.PI) * -18;
      jsBtn.style.transform = `translate3d(${jsP * 12}px, ${lift}px, 0) scale(${scale})`;
      const label = jsP < 0.22 ? 'CLICK ME' : jsP < 0.45 ? 'HELLO' : jsP < 0.72 ? 'COUNT' : 'BUILT';
      if (jsBtn.textContent !== label) jsBtn.textContent = label;
    }
    if (jsCount) {
      jsCount.textContent = String(Math.floor(jsP * 24));
    }
    if (jsNote) {
      jsNote.style.opacity = String(clamp((jsP - 0.2) / 0.3));
    }
    jsChips.forEach((chip, i) => {
      const v = clamp((jsP - 0.28 - i * 0.12) / 0.18);
      chip.style.opacity = String(v);
      chip.style.transform = `translate3d(${(1 - v) * 16}px, 0, 0) scale(${0.9 + v * 0.1})`;
    });

    if (pyCursor) {
      pyCursor.style.opacity = pyP > 0.08 && pyP < 0.95 ? String(0.4 + Math.sin(p * 80) * 0.4) : '0';
    }
    pyBars.forEach((bar, i) => {
      const v = clamp((pyP - 0.35 - i * 0.1) / 0.25);
      bar.style.transform = `scaleX(${v})`;
    });

    javaObjs.forEach((obj, i) => {
      const v = clamp((javaP - 0.22 - i * 0.1) / 0.22);
      obj.style.opacity = String(v);
      obj.style.transform = `translate3d(${(1 - v) * (i % 2 === 0 ? -24 : 24)}px, ${(1 - v) * 20}px, 0)`;
    });

    if (reactTree) {
      const tree = clamp(1 - (reactP - 0.42) / 0.22);
      reactTree.style.opacity = String(tree);
      reactTree.style.transform = `translate3d(0, ${-(1 - tree) * 12}px, 0)`;
    }
    if (reactApp) {
      const app = clamp((reactP - 0.38) / 0.28);
      reactApp.style.opacity = String(app);
      reactApp.style.transform = `translate3d(0, ${(1 - app) * 22}px, 0) scale(${0.96 + app * 0.04})`;
    }
    reactParts.forEach((part, i) => {
      const v = clamp((reactP - 0.4 - i * 0.08) / 0.16);
      part.style.opacity = String(v);
      part.style.transform = `translate3d(0, ${(1 - v) * 14}px, 0)`;
    });

    const techP = clamp((p - 0.08) / 0.84);
    if (hudFill) hudFill.style.transform = `scaleX(${techP})`;
    if (hudDot) hudDot.style.left = `${techP * 100}%`;

    let stage = STAGE_RANGES[0];
    for (const item of STAGE_RANGES) {
      if (p >= item.from) stage = item;
    }
    const key = `${stage.code}:${stage.name}`;
    if (key !== lastStage) {
      lastStage = key;
      if (hudCode) hudCode.textContent = `${stage.code} / ${stage.name}`;
      if (hudKicker) hudKicker.textContent = stage.id === 'intro' ? 'PROGRAMMING' : `PROGRAMMING · ${stage.kicker}`;
      if (hud) {
        hud.classList.remove('is-swap');
        void hud.offsetWidth;
        hud.classList.add('is-swap');
      }
    }
  };
}

export function startProgrammingJourney(root) {
  if (!root) return () => {};

  const apply = createJourneyApplier(root);
  let target = 0;
  let current = 0;
  let raf = 0;
  let touchY = 0;
  const mq = window.matchMedia('(min-width: 900px)');
  const X_DONE = 0.88;
  const X_START = 0.02;

  const scrollProgress = () => {
    const total = Math.max(1, root.offsetHeight - window.innerHeight);
    return clamp(-root.getBoundingClientRect().top / total);
  };

  const driveX = (deltaPx) => {
    const span = Math.max(900, window.innerHeight * 4.8);
    target = clamp(target + deltaPx / span);
    if (target >= 0.995) target = 1;
    if (target <= 0.005) target = 0;
  };

  const scrollY = (px) => {
    const html = document.documentElement;
    html.style.setProperty('scroll-behavior', 'auto');
    window.scrollBy(0, px);
    html.style.removeProperty('scroll-behavior');
  };

  const wheelPx = (event) => {
    const delta =
      Math.abs(event.deltaX) > Math.abs(event.deltaY) ? event.deltaX : event.deltaY;
    if (event.deltaMode === 1) return delta * 16;
    if (event.deltaMode === 2) return delta * window.innerHeight;
    return delta;
  };

  const onJourneyInput = (px) => {
    if (px > 0 && target < X_DONE) {
      driveX(px);
      return;
    }
    if (px < 0 && target > X_START) {
      driveX(px);
      return;
    }
    if (px > 0) target = 1;
    else target = 0;
    scrollY(px);
  };

  const tick = () => {
    const cinematic = isCinematicJourney();
    if (!cinematic) target = scrollProgress();
    const ease = cinematic ? 0.14 : 0.16;
    current += (target - current) * ease;
    if (Math.abs(target - current) < 0.00025) current = target;
    apply(current, cinematic);
    raf = requestAnimationFrame(tick);
  };

  const start = () => {
    if (raf) return;
    raf = requestAnimationFrame(tick);
  };

  const stop = () => {
    if (raf) cancelAnimationFrame(raf);
    raf = 0;
  };

  const onWheel = (event) => {
    if (!isCinematicJourney()) return;
    event.preventDefault();
    onJourneyInput(wheelPx(event));
  };

  const onTouchStart = (event) => {
    touchY = event.touches[0]?.clientY ?? 0;
  };

  const onTouchMove = (event) => {
    if (!isCinematicJourney()) return;
    const y = event.touches[0]?.clientY ?? touchY;
    const px = touchY - y;
    touchY = y;
    if (Math.abs(px) < 0.5) return;
    event.preventDefault();
    onJourneyInput(px);
  };

  const onKeyDown = (event) => {
    if (!isCinematicJourney()) return;
    const r = root.getBoundingClientRect();
    if (r.bottom <= 0 || r.top >= window.innerHeight) return;
    const step = window.innerHeight * 0.22;
    if (['ArrowDown', 'ArrowRight', 'PageDown', ' '].includes(event.key)) {
      event.preventDefault();
      onJourneyInput(step);
    }
    if (['ArrowUp', 'ArrowLeft', 'PageUp'].includes(event.key)) {
      event.preventDefault();
      onJourneyInput(-step);
    }
  };

  let introPlayed = false;

  const playIntro = () => {
    if (introPlayed) return;
    introPlayed = true;
    const nodes = root.querySelectorAll('[data-jw="intro-line"]');
    if (prefersReducedMotion()) {
      nodes.forEach((node) => {
        node.style.opacity = '1';
        node.style.transform = 'none';
      });
      return;
    }
    anime({
      targets: nodes,
      opacity: [0, 1],
      translateY: [28, 0],
      delay: anime.stagger(90),
      duration: 780,
      easing: easings.out,
    });
  };

  const io = new IntersectionObserver(
    ([entry]) => {
      root.classList.toggle('is-active', entry.isIntersecting);
      if (entry.isIntersecting) {
        playIntro();
        start();
      } else stop();
    },
    { threshold: 0.001 }
  );
  io.observe(root);

  const onResize = () => {
    apply(current, isCinematicJourney());
  };

  root.addEventListener('wheel', onWheel, { passive: false });
  root.addEventListener('touchstart', onTouchStart, { passive: true });
  root.addEventListener('touchmove', onTouchMove, { passive: false });
  window.addEventListener('keydown', onKeyDown);
  window.addEventListener('resize', onResize, { passive: true });
  mq.addEventListener?.('change', onResize);

  apply(0, isCinematicJourney());
  start();

  return () => {
    stop();
    io.disconnect();
    root.removeEventListener('wheel', onWheel);
    root.removeEventListener('touchstart', onTouchStart);
    root.removeEventListener('touchmove', onTouchMove);
    window.removeEventListener('keydown', onKeyDown);
    window.removeEventListener('resize', onResize);
    mq.removeEventListener?.('change', onResize);
  };
}
