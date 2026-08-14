export const BADGE_CONFIG = {
  sizes: {
    desktop: { w: 272, h: 424 },
    tablet: { w: 228, h: 360 },
    mobile: { w: 196, h: 314 },
  },
  restXRatio: 0.73,
  restYRatio: 0.22,
  maxPullY: 560,
  maxPullX: 310,
  followSpring: 0.22,
  followDamp: 0.32,
  springX: 0.015,
  springY: 0.088,
  dampX: 0.028,
  dampY: 0.068,
  rotSpring: 0.042,
  rotDamp: 0.09,
  maxTilt: 18,
  flipSpring: 0.055,
  flipDamp: 0.14,
  clickThreshold: 12,
};

function clamp(n, min, max) {
  return Math.max(min, Math.min(max, n));
}

function rubber(value, rest, max) {
  const delta = value - rest;
  const abs = Math.abs(delta);
  if (abs <= max) return value;
  const extra = abs - max;
  const pulled = max + extra / (1 + extra / (max * 0.42));
  return rest + Math.sign(delta) * pulled;
}

function shortestDelta(from, to) {
  return ((((to - from) % 360) + 540) % 360) - 180;
}

export function createBadgePhysics() {
  const C = BADGE_CONFIG;
  const state = {
    x: 0,
    y: 0,
    vx: 0,
    vy: 0,
    rot: 0,
    rotVel: 0,
    flipY: 0,
    flipVel: 0,
    targetFlip: 0,
    restX: 0,
    restY: 0,
    targetX: 0,
    targetY: 0,
    anchorX: 0,
    anchorY: 8,
    w: 0,
    h: 0,
    badgeW: C.sizes.desktop.w,
    badgeH: C.sizes.desktop.h,
    isDragging: false,
    grabOX: 0,
    grabOY: 0,
    startX: 0,
    startY: 0,
    moved: false,
    lastPX: 0,
    lastPY: 0,
    lastT: 0,
    relVX: 0,
    relVY: 0,
    maxDrag: 0,
    reduced: false,
    settled: true,
    entering: false,
  };

  const limits = () => {
    const maxY = Math.min(C.maxPullY, Math.max(280, state.h * 0.58));
    const maxX = Math.min(C.maxPullX, Math.max(140, state.w * 0.32));
    return { maxX, maxY };
  };

  const freezeAtRest = () => {
    state.x = state.restX;
    state.y = state.restY;
    state.targetX = state.restX;
    state.targetY = state.restY;
    state.vx = 0;
    state.vy = 0;
    state.rot = 0;
    state.rotVel = 0;
    state.settled = true;
    state.isDragging = false;
    state.entering = false;
  };

  const stepFlip = (t) => {
    state.flipY = ((state.flipY % 360) + 360) % 360;
    const delta = shortestDelta(state.flipY, state.targetFlip);
    if (Math.abs(delta) < 0.4 && Math.abs(state.flipVel) < 0.25) {
      state.flipY = state.targetFlip;
      state.flipVel = 0;
      return false;
    }
    state.flipVel += delta * C.flipSpring * t;
    state.flipVel *= Math.max(0, 1 - C.flipDamp * t);
    state.flipY += state.flipVel * t;
    return true;
  };

  const api = {
    state,
    layout(width, height) {
      const w = Math.max(width, 320);
      const h = Math.max(height, 520);
      if (state.w && Math.abs(w - state.w) < 0.75 && Math.abs(h - state.h) < 0.75) {
        return;
      }
      state.w = w;
      state.h = h;
      const mobile = width < 768;
      const tablet = width < 1100;
      const size = mobile ? C.sizes.mobile : tablet ? C.sizes.tablet : C.sizes.desktop;
      state.badgeW = size.w;
      state.badgeH = size.h;
      state.anchorX = state.w * (mobile ? 0.78 : C.restXRatio);
      state.anchorY = 6;
      state.restX = state.anchorX - 8;
      state.restY = Math.max(mobile ? 118 : 148, state.h * (mobile ? 0.2 : C.restYRatio));
      if (!state.isDragging) {
        state.targetX = state.restX;
        state.targetY = state.restY;
        if (state.x === 0 && state.y === 0) {
          state.x = state.restX;
          state.y = -Math.max(340, state.badgeH + 90);
        } else if (state.settled && state.y >= 0) {
          state.x = state.restX;
          state.y = state.restY;
        }
      }
    },
    hideAbove() {
      state.x = state.restX;
      state.y = -Math.max(340, state.badgeH + 90);
      state.targetX = state.restX;
      state.targetY = state.restY;
      state.vx = 0;
      state.vy = 0;
      state.rot = 10;
      state.rotVel = 0;
      state.settled = true;
      state.entering = false;
      state.isDragging = false;
    },
    appear() {
      state.x = state.restX + 18;
      state.y = -Math.max(96, state.badgeH * 0.48);
      state.targetX = state.restX;
      state.targetY = state.restY;
      state.vx = 4;
      state.vy = 16;
      state.rot = 14;
      state.rotVel = -0.65;
      state.settled = false;
      state.entering = true;
    },
    restNow() {
      freezeAtRest();
    },
    down(px, py) {
      state.isDragging = true;
      state.settled = false;
      state.entering = false;
      state.moved = false;
      state.grabOX = px - state.x;
      state.grabOY = py - state.y;
      state.startX = px;
      state.startY = py;
      state.lastPX = px;
      state.lastPY = py;
      state.lastT = performance.now();
      state.relVX = 0;
      state.relVY = 0;
      state.maxDrag = 0;
    },
    move(px, py) {
      if (!state.isDragging) return;
      const now = performance.now();
      const dt = clamp(now - state.lastT, 8, 32);
      state.relVX = ((px - state.lastPX) / dt) * 16.67;
      state.relVY = ((py - state.lastPY) / dt) * 16.67;
      state.lastPX = px;
      state.lastPY = py;
      state.lastT = now;

      if (Math.hypot(px - state.startX, py - state.startY) > C.clickThreshold) state.moved = true;

      const { maxX, maxY } = limits();
      const rawX = px - state.grabOX;
      const rawY = Math.max(state.restY - 40, py - state.grabOY);
      state.targetX = clamp(rubber(rawX, state.restX, maxX), 48, state.w - 48);
      state.targetY = clamp(rubber(rawY, state.restY, maxY), 20, state.h - 80);

      const dist = Math.hypot(state.targetX - state.restX, state.targetY - state.restY);
      state.maxDrag = Math.max(state.maxDrag, dist);
    },
    up() {
      if (!state.isDragging) return { clicked: false, pulled: false, farPull: false };
      state.isDragging = false;
      const { maxY } = limits();
      const clicked = !state.moved;
      const pulled = state.maxDrag > 28;

      if (clicked) {
        freezeAtRest();
        return { clicked: true, pulled: false, farPull: false };
      }

      const pullY = Math.max(0, state.y - state.restY);
      const pullX = state.x - state.restX;
      state.targetX = state.restX;
      state.targetY = state.restY;
      state.vx = clamp(state.relVX * 0.62 + pullX * -0.028, -26, 26);
      state.vy = clamp(state.relVY * 0.12 - pullY * 0.2 - 10, -56, 8);
      state.rotVel = clamp(state.relVX * 0.24 + pullX * 0.016, -3.6, 3.6);
      state.flipVel = 0;
      state.settled = false;
      state.entering = false;

      const wrapped = ((state.flipY % 360) + 360) % 360;
      state.targetFlip = wrapped > 90 && wrapped < 270 ? 180 : 0;
      state.flipY = wrapped;
      return { clicked: false, pulled, farPull: state.maxDrag > maxY * 0.72 };
    },
    flip() {
      const wrapped = ((state.flipY % 360) + 360) % 360;
      const showingBack = wrapped > 90 && wrapped < 270;
      state.targetFlip = showingBack ? 0 : 180;
      state.flipVel += showingBack ? -11 : 11;
    },
    yank() {
      state.settled = false;
      state.isDragging = false;
      state.entering = false;
      state.y = state.restY + Math.min(240, state.h * 0.28);
      state.x = state.restX + 28;
      state.targetX = state.restX;
      state.targetY = state.restY;
      state.vy = 8;
      state.vx = 8;
      state.rot = 12;
      state.rotVel = 1.8;
    },
    tick(dtMs) {
      const t = clamp(dtMs, 8, 32) / 16.67;
      const flipping = stepFlip(t);

      if (state.reduced) {
        const tx = state.isDragging ? state.targetX : state.restX;
        const ty = state.isDragging ? state.targetY : state.restY;
        state.x += (tx - state.x) * 0.28 * t;
        state.y += (ty - state.y) * 0.28 * t;
        state.rot += (0 - state.rot) * 0.28 * t;
        state.vx = 0;
        state.vy = 0;
        if (!state.isDragging && Math.hypot(tx - state.x, ty - state.y) < 0.5) {
          freezeAtRest();
          return !flipping;
        }
        return false;
      }

      if (state.settled && !state.isDragging) {
        state.x = state.restX;
        state.y = state.restY;
        state.rot = 0;
        state.vx = 0;
        state.vy = 0;
        state.rotVel = 0;
        return !flipping;
      }

      const aimX = state.isDragging ? state.targetX : state.restX;
      const aimY = state.isDragging ? state.targetY : state.restY;
      const dx = aimX - state.x;
      const dy = aimY - state.y;
      const distY = Math.abs(dy);
      const distX = Math.abs(dx);

      let kx = state.isDragging ? C.followSpring : C.springX;
      let ky = state.isDragging ? C.followSpring : C.springY;
      let dxDamp = state.isDragging ? C.followDamp : C.dampX;
      let dyDamp = state.isDragging ? C.followDamp : C.dampY;

      if (state.entering && !state.isDragging) {
        state.vy += 1.65 * t;
        dyDamp = 0.042;
        dxDamp = 0.02;
        if (state.y > state.restY + 10) state.entering = false;
      } else if (!state.isDragging) {
        if (distY < 22) dyDamp = 0.22;
        if (distY < 8) dyDamp = 0.38;
        if (distX < 10) dxDamp = 0.12;
        if (state.y < state.restY) {
          ky = 0.11;
          dyDamp = 0.2;
        }
      }

      const yForce = state.entering ? clamp(dy * ky, -2.6, 3.4) : dy * ky;
      state.vx += dx * kx * t;
      state.vy += yForce * t;
      state.vx *= Math.max(0, 1 - dxDamp * t);
      state.vy *= Math.max(0, 1 - dyDamp * t);
      state.x += state.vx * t;
      state.y += state.vy * t;

      const tiltTarget = clamp((state.x - state.restX) * 0.04 + state.vx * 0.58, -C.maxTilt, C.maxTilt);
      state.rotVel += (tiltTarget - state.rot) * C.rotSpring * t;
      state.rotVel *= Math.max(0, 1 - C.rotDamp * t);
      state.rot = clamp(state.rot + state.rotVel * t, -C.maxTilt, C.maxTilt);

      const speed = Math.hypot(state.vx, state.vy);
      const dist = Math.hypot(state.restX - state.x, state.restY - state.y);

      if (!state.isDragging && speed < 0.32 && dist < 1.8 && Math.abs(state.rotVel) < 0.12) {
        freezeAtRest();
        return !flipping;
      }

      return false;
    },
    lanyard() {
      const ax = state.anchorX;
      const ay = state.anchorY;
      const bx = state.x;
      const by = state.y;
      const dist = Math.hypot(bx - ax, by - ay);
      const taut = clamp(dist / (state.restY * 1.15), 0, 1);
      const slack = 1 - taut;
      const swing = (bx - ax) / Math.max(dist, 1);
      const c1x = ax + (bx - ax) * 0.18 + swing * slack * 18;
      const c1y = ay + dist * (0.32 + slack * 0.22);
      const c2x = bx - (bx - ax) * 0.12 + swing * slack * 28;
      const c2y = by - 36 - slack * 48;
      return { ax, ay, c1x, c1y, c2x, c2y, bx, by };
    },
    transform() {
      return `translate3d(${state.x - state.badgeW / 2}px, ${state.y}px, 0) rotate(${state.rot}deg)`;
    },
    flipTransform() {
      const lift = Math.min(1, Math.abs(state.flipVel) / 12) * 8;
      return `rotateY(${state.flipY}deg) translateZ(${lift}px)`;
    },
    shadow() {
      const dx = (state.x - state.restX) * 0.16;
      const dy = 10 + (state.y - state.restY) * 0.06;
      const pull = clamp(Math.hypot(state.x - state.restX, state.y - state.restY) / 400, 0, 1);
      return {
        transform: `translate3d(${dx}px, ${dy}px, 0) scale(${1 + pull * 0.12})`,
        opacity: 0.28 + pull * 0.18,
      };
    },
    pathD() {
      const p = api.lanyard();
      return `M ${p.ax} ${p.ay} C ${p.c1x} ${p.c1y}, ${p.c2x} ${p.c2y}, ${p.bx} ${p.by}`;
    },
  };

  return api;
}
