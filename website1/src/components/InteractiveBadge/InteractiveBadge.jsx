import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react';
import Lanyard from './Lanyard';
import BadgeFront from './BadgeFront';
import BadgeBack from './BadgeBack';
import { createBadgePhysics } from '../../physics/badgePhysics';
import { playBadgeHint, hideBadgeHint, playWelcome } from '../../animations/badgeAnimations';
import { prefersReducedMotion } from '../../animations/utils';

const HINT_KEY = 'techren-badge-hint';

export default function InteractiveBadge({ start = false }) {
  const stageRef = useRef(null);
  const badgeRef = useRef(null);
  const cardRef = useRef(null);
  const shadowRef = useRef(null);
  const strapRef = useRef(null);
  const shineRef = useRef(null);
  const reelRef = useRef(null);
  const hintRef = useRef(null);
  const welcomeRef = useRef(null);
  const physics = useRef(createBadgePhysics());
  const raf = useRef(0);
  const last = useRef(0);
  const loopRef = useRef(() => {});
  const [size, setSize] = useState({ width: 1200, height: 800 });
  const [hint, setHint] = useState(() => {
    if (typeof window === 'undefined') return true;
    return sessionStorage.getItem(HINT_KEY) !== '1';
  });
  const [welcomed, setWelcomed] = useState(false);

  const apply = useCallback(() => {
    const p = physics.current;
    const badge = badgeRef.current;
    if (badge) {
      badge.style.width = `${p.state.badgeW}px`;
      badge.style.transform = p.transform();
    }
    if (cardRef.current) {
      cardRef.current.style.height = `${Math.max(240, p.state.badgeH - 28)}px`;
      cardRef.current.style.transform = p.flipTransform();
    }
    if (shadowRef.current) {
      const s = p.shadow();
      shadowRef.current.style.transform = s.transform;
      shadowRef.current.style.opacity = String(s.opacity);
    }
    const d = p.pathD();
    if (strapRef.current) strapRef.current.setAttribute('d', d);
    if (shineRef.current) shineRef.current.setAttribute('d', d);
    if (reelRef.current) reelRef.current.setAttribute('transform', `translate(${p.state.anchorX} 0)`);
  }, []);

  const startLoop = useCallback(() => {
    if (raf.current) return;
    last.current = 0;
    const step = (now) => {
      const dt = last.current ? now - last.current : 16;
      last.current = now;
      const idle = physics.current.tick(dt);
      apply();
      if (idle) {
        raf.current = 0;
        return;
      }
      raf.current = requestAnimationFrame(loopRef.current);
    };
    loopRef.current = step;
    raf.current = requestAnimationFrame(step);
  }, [apply]);

  const stopLoop = useCallback(() => {
    if (raf.current) cancelAnimationFrame(raf.current);
    raf.current = 0;
  }, []);

  const layout = useCallback(() => {
    const stage = stageRef.current;
    if (!stage) return;
    const rect = stage.getBoundingClientRect();
    const width = rect.width || window.innerWidth;
    const height = rect.height || window.innerHeight;
    physics.current.layout(width, height);
    physics.current.state.reduced = prefersReducedMotion();
    setSize((prev) => (prev.width === width && prev.height === height ? prev : { width, height }));
    apply();
  }, [apply]);

  const hideHint = useCallback(() => {
    if (!hint) return;
    sessionStorage.setItem(HINT_KEY, '1');
    hideBadgeHint(hintRef.current, () => setHint(false));
  }, [hint]);

  useLayoutEffect(() => {
    layout();
    physics.current.hideAbove();
    apply();
  }, [apply, layout]);

  useEffect(() => {
    const stage = stageRef.current;
    const ro = new ResizeObserver(() => layout());
    if (stage) ro.observe(stage);
    window.addEventListener('resize', layout);

    return () => {
      ro.disconnect();
      window.removeEventListener('resize', layout);
      stopLoop();
      document.documentElement.classList.remove('is-grabbing');
    };
  }, [layout, stopLoop]);

  useEffect(() => {
    const reduced = prefersReducedMotion();
    physics.current.state.reduced = reduced;
    if (!start) {
      physics.current.hideAbove();
      apply();
      return undefined;
    }
    if (reduced) {
      physics.current.restNow();
      apply();
      return undefined;
    }
    physics.current.appear();
    apply();
    startLoop();
    return undefined;
  }, [apply, start, startLoop]);

  useEffect(() => {
    if (hint) playBadgeHint(hintRef.current);
  }, [hint]);

  const localPoint = (event) => {
    const rect = stageRef.current.getBoundingClientRect();
    return { x: event.clientX - rect.left, y: event.clientY - rect.top };
  };

  const onPointerDown = (event) => {
    if (event.button != null && event.button !== 0) return;
    event.preventDefault();
    hideHint();
    const { x, y } = localPoint(event);
    physics.current.down(x, y);
    event.currentTarget.setPointerCapture(event.pointerId);
    event.currentTarget.classList.add('is-dragging');
    document.documentElement.classList.add('is-grabbing');
    startLoop();
  };

  const onPointerMove = (event) => {
    if (!physics.current.state.isDragging) return;
    event.preventDefault();
    const { x, y } = localPoint(event);
    physics.current.move(x, y);
  };

  const lastClick = useRef(0);
  const flippedAt = useRef(0);

  const flipCard = () => {
    flippedAt.current = performance.now();
    physics.current.flip();
    startLoop();
  };

  const onPointerUp = () => {
    if (!physics.current.state.isDragging) return;
    const result = physics.current.up();
    badgeRef.current?.classList.remove('is-dragging');
    document.documentElement.classList.remove('is-grabbing');
    if (result.clicked) {
      const now = performance.now();
      if (now - lastClick.current < 420) {
        lastClick.current = 0;
        flipCard();
      } else {
        lastClick.current = now;
      }
    } else {
      lastClick.current = 0;
      startLoop();
    }
    if (result.pulled && !welcomed) {
      setWelcomed(true);
      playWelcome(welcomeRef.current);
    }
  };

  const onDoubleClick = (event) => {
    event.preventDefault();
    if (performance.now() - flippedAt.current < 500) return;
    hideHint();
    flipCard();
  };

  const onKeyDown = (event) => {
    if (event.key === 'Enter') {
      event.preventDefault();
      hideHint();
      flipCard();
      return;
    }
    if (event.key === ' ') {
      event.preventDefault();
      hideHint();
      physics.current.yank();
      startLoop();
    }
  };

  return (
    <div className="badge-stage" ref={stageRef}>
      <Lanyard
        strapRef={strapRef}
        shineRef={shineRef}
        reelRef={reelRef}
        width={size.width}
        height={size.height}
      />
      <div
        className="id-badge"
        ref={badgeRef}
        role="button"
        tabIndex={0}
        aria-label="TechRen ID badge. Drag to pull the lanyard. Double-click to flip. Enter flips, Space tugs."
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerUp}
        onLostPointerCapture={onPointerUp}
        onDoubleClick={onDoubleClick}
        onContextMenu={(event) => event.preventDefault()}
        onKeyDown={onKeyDown}
      >
        <span className="id-clip" aria-hidden="true">
          <span className="id-clip-ring" />
          <span className="id-clip-bar" />
        </span>
        <div className="id-scene">
          <div className="id-card-3d" ref={cardRef}>
            <BadgeFront />
            <span className="id-edge" aria-hidden="true" />
            <BadgeBack />
          </div>
        </div>
        <span className="id-shadow" ref={shadowRef} aria-hidden="true" />
        {hint ? (
          <span className="badge-hint" ref={hintRef}>
            Drag me · double-click to flip
          </span>
        ) : null}
      </div>
      <p className="badge-surprise" ref={welcomeRef} hidden>
        Welcome to TechRen
      </p>
    </div>
  );
}
