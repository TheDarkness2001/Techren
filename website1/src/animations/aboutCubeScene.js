import * as THREE from 'three';
import { animate, createTimer, stagger, utils } from 'animejs4';
import { getInstances } from 'animejs4/adapters/three';

/**
 * Smooth InstancedMesh cube field (anime.js Three adapter style).
 * Returns { destroy, replay }.
 */
export function createAboutCubeScene(container, options = {}) {
  if (!container) return { destroy() {}, replay() {} };

  const colorHex = options.color || '#5ce1b8';
  const reduced = options.reducedMotion === true;

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
  let timer = null;
  let instances = null;

  const stopAnims = () => {
    animations.splice(0).forEach((a) => {
      try {
        a.pause();
        a.cancel?.();
      } catch {
        /* ignore */
      }
    });
  };

  const layoutAndAnimate = () => {
    stopAnims();
    instances = getInstances(mesh);

    utils.set(instances, {
      x: stagger([-spread, spread], { grid: [gridSize, gridSize, gridSize], axis: 'x' }),
      y: stagger([-spread, spread], { grid: [gridSize, gridSize, gridSize], axis: 'y' }),
      z: stagger([-spread, spread], { grid: [gridSize, gridSize, gridSize], axis: 'z' }),
    });

    if (reduced) {
      renderer.render(scene, camera);
      return;
    }

    animations.push(
      animate(mesh, {
        rotateY: { to: 360, duration: 9000 },
        rotateX: { to: 360, duration: 12000 },
        loop: true,
        ease: 'inOutQuad',
      }),
    );

    animations.push(
      animate(pointLight, {
        intensity: [30, 0],
        duration: 2500,
        loop: true,
        loopDelay: 500,
        alternate: true,
        ease: 'out(3)',
      }),
    );

    animations.push(
      animate(instances, {
        x: (instance) => instance.x * 10,
        y: (instance) => instance.y * 10,
        z: (instance) => instance.z * 10,
        duration: 2000,
        delay: stagger([0, 500], { grid: true, from: 'center', reversed: true, ease: 'in(3)' }),
        loop: true,
        loopDelay: 500,
        alternate: true,
        ease: 'inOutExpo',
      }),
    );
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
