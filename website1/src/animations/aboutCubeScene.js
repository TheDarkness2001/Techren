import * as THREE from 'three';
import { animate, createTimer, stagger, utils } from 'animejs4';
import { getInstances } from 'animejs4/adapters/three';

const OPEN_MS = 2800;
const CLOSE_MS = 2800;
const HOLD_MS = 900;
const GAP_MS = 700;

/**
 * Smooth InstancedMesh cube field.
 * Calls options.onPhase('open' | 'close' | 'advance') in sync with expand/contract.
 */
export function createAboutCubeScene(container, options = {}) {
  if (!container) return { destroy() {}, replay() {} };

  const colorHex = options.color || '#5ce1b8';
  const reduced = options.reducedMotion === true;
  const onPhase = typeof options.onPhase === 'function' ? options.onPhase : () => {};

  const { clientWidth: width, clientHeight: height } = container;
  const w = Math.max(width, 320);
  const h = Math.max(height, 280);

  const renderer = new THREE.WebGLRenderer({
    alpha: true,
    antialias: true,
    powerPreference: 'high-performance',
  });
  renderer.shadowMap.enabled = true;
  renderer.setSize(w, h);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.domElement.className = 'about-webgl';
  renderer.domElement.setAttribute('aria-hidden', 'true');
  container.appendChild(renderer.domElement);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(50, w / h, 0.1, 100);
  camera.position.z = 6;
  scene.add(camera);

  scene.add(new THREE.AmbientLight(0xffffff, 0.28));
  const pointLight = new THREE.PointLight(0xffffff, 8, 20, 0.4);
  pointLight.castShadow = true;
  scene.add(pointLight);

  const dirLight = new THREE.DirectionalLight(0xffffff, 2);
  dirLight.position.set(2, 3, 4);
  scene.add(dirLight);

  const gridSize = 4;
  const cellSize = 2 / gridSize;
  const spread = ((gridSize - 1) / 2) * cellSize;
  const geometry = new THREE.BoxGeometry(cellSize, cellSize, cellSize);
  const material = new THREE.MeshLambertMaterial({ color: new THREE.Color(colorHex) });
  const mesh = new THREE.InstancedMesh(geometry, material, gridSize * gridSize * gridSize);
  mesh.castShadow = mesh.receiveShadow = true;
  scene.add(mesh);

  const animations = [];
  const timeouts = [];
  let timer = null;
  let instances = null;
  let bases = [];
  let stopped = false;

  const trackTimeout = (fn, ms) => {
    const id = window.setTimeout(fn, ms);
    timeouts.push(id);
    return id;
  };

  const clearTimeouts = () => {
    while (timeouts.length) window.clearTimeout(timeouts.pop());
  };

  const stopAnims = () => {
    clearTimeouts();
    animations.splice(0).forEach((a) => {
      try {
        a.pause();
        a.cancel?.();
      } catch {
        /* ignore */
      }
    });
  };

  const staggerDelay = () =>
    stagger([0, 500], { grid: true, from: 'center', reversed: true, ease: 'in(3)' });

  const playExpand = () => {
    if (stopped || !instances) return;
    onPhase('open');
    const a = animate(instances, {
      x: (_, i) => bases[i].x * 10,
      y: (_, i) => bases[i].y * 10,
      z: (_, i) => bases[i].z * 10,
      duration: OPEN_MS,
      delay: staggerDelay(),
      ease: 'inOutExpo',
      onComplete: () => {
        if (stopped) return;
        trackTimeout(playContract, HOLD_MS);
      },
    });
    animations.push(a);
  };

  const playContract = () => {
    if (stopped || !instances) return;
    onPhase('close');
    trackTimeout(() => {
      if (!stopped) onPhase('advance');
    }, 420);
    const a = animate(instances, {
      x: (_, i) => bases[i].x,
      y: (_, i) => bases[i].y,
      z: (_, i) => bases[i].z,
      duration: CLOSE_MS,
      delay: staggerDelay(),
      ease: 'inOutExpo',
      onComplete: () => {
        if (stopped) return;
        trackTimeout(playExpand, GAP_MS);
      },
    });
    animations.push(a);
  };

  const layoutAndAnimate = () => {
    stopped = false;
    stopAnims();
    instances = getInstances(mesh);

    utils.set(instances, {
      x: stagger([-spread, spread], { grid: [gridSize, gridSize, gridSize], axis: 'x' }),
      y: stagger([-spread, spread], { grid: [gridSize, gridSize, gridSize], axis: 'y' }),
      z: stagger([-spread, spread], { grid: [gridSize, gridSize, gridSize], axis: 'z' }),
    });

    bases = instances.map((inst) => ({ x: inst.x, y: inst.y, z: inst.z }));

    if (reduced) {
      onPhase('open');
      renderer.render(scene, camera);
      return;
    }

    animations.push(
      animate(mesh, {
        rotateY: { to: 360, duration: 18000 },
        rotateX: { to: 360, duration: 24000 },
        loop: true,
        ease: 'inOutQuad',
      }),
    );

    animations.push(
      animate(pointLight, {
        intensity: [22, 2],
        duration: 4000,
        loop: true,
        loopDelay: 700,
        alternate: true,
        ease: 'out(3)',
      }),
    );

    playExpand();
  };

  layoutAndAnimate();

  if (!reduced) {
    timer = createTimer({
      onUpdate: () => renderer.render(scene, camera),
    });
  } else {
    renderer.render(scene, camera);
  }

  const onResize = () => {
    const nextW = Math.max(container.clientWidth, 320);
    const nextH = Math.max(container.clientHeight, 280);
    camera.aspect = nextW / nextH;
    camera.updateProjectionMatrix();
    renderer.setSize(nextW, nextH);
  };

  const ro = typeof ResizeObserver !== 'undefined' ? new ResizeObserver(onResize) : null;
  ro?.observe(container);
  window.addEventListener('resize', onResize);

  return {
    replay() {
      layoutAndAnimate();
      if (!timer && !reduced) {
        timer = createTimer({
          onUpdate: () => renderer.render(scene, camera),
        });
      }
    },
    setColor(hex) {
      material.color.set(hex);
    },
    destroy() {
      stopped = true;
      stopAnims();
      try {
        timer?.pause();
        timer?.cancel?.();
      } catch {
        /* ignore */
      }
      timer = null;
      ro?.disconnect();
      window.removeEventListener('resize', onResize);
      geometry.dispose();
      material.dispose();
      renderer.dispose();
      if (renderer.domElement.parentNode === container) {
        container.removeChild(renderer.domElement);
      }
    },
  };
}
