import * as THREE from 'three';
import { animate, createTimer, stagger, utils } from 'animejs4';
import { getInstances } from 'animejs4/adapters/three';

const OPEN_MS = 2600;
const CLOSE_MS = 2400;
const ZOOM_MS = 1400;
const HOLD_MS = 3200;
const GAP_MS = 600;

const PALETTE = ['#5ce1b8', '#d9f56e', '#7dd3fc', '#f9a8d4', '#fbbf24', '#c4b5fd', '#fb7185', '#34d399'];

function wrapLines(ctx, text, maxWidth) {
  const words = String(text || '').split(/\s+/);
  const lines = [];
  let line = '';
  for (const word of words) {
    const next = line ? `${line} ${word}` : word;
    if (ctx.measureText(next).width > maxWidth && line) {
      lines.push(line);
      line = word;
    } else {
      line = next;
    }
  }
  if (line) lines.push(line);
  return lines.slice(0, 7);
}

function createFaceTexture(slide, accentHex) {
  const canvas = document.createElement('canvas');
  canvas.width = 512;
  canvas.height = 512;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = '#141018';
  ctx.fillRect(0, 0, 512, 512);

  ctx.strokeStyle = accentHex;
  ctx.lineWidth = 10;
  ctx.strokeRect(18, 18, 476, 476);

  ctx.fillStyle = accentHex;
  ctx.font = '600 28px "Space Grotesk", system-ui, sans-serif';
  ctx.fillText(String(slide?.kicker || 'TechRen').toUpperCase().slice(0, 28), 48, 78);

  ctx.fillStyle = '#f4f4f1';
  ctx.font = '600 44px "Space Grotesk", system-ui, sans-serif';
  const titleLines = wrapLines(ctx, slide?.title || '', 410);
  let y = 150;
  titleLines.forEach((ln) => {
    ctx.fillText(ln, 48, y);
    y += 52;
  });

  ctx.fillStyle = 'rgba(244,244,241,0.72)';
  ctx.font = '500 24px "Manrope", system-ui, sans-serif';
  const body = slide?.lead || (slide?.points && slide.points[0]) || '';
  wrapLines(ctx, body, 410).forEach((ln) => {
    ctx.fillText(ln, 48, y + 18);
    y += 34;
  });

  const tex = new THREE.CanvasTexture(canvas);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.needsUpdate = true;
  return tex;
}

function randomColor() {
  return new THREE.Color(PALETTE[Math.floor(Math.random() * PALETTE.length)]);
}

/**
 * Cube field with expand → zoom to random cube (info on face) → close → next.
 * Click any cube to paint it a random color.
 */
export function createAboutCubeScene(container, options = {}) {
  if (!container) return { destroy() {}, replay() {}, setSlide() {} };

  const colorHex = options.color || '#5ce1b8';
  const reduced = options.reducedMotion === true;
  const onPhase = typeof options.onPhase === 'function' ? options.onPhase : () => {};
  const getSlide = typeof options.getSlide === 'function' ? options.getSlide : () => ({
    kicker: 'TechRen',
    title: 'Learn. Build. Grow.',
    lead: 'Programming and English as skills you can use.',
  });

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
  renderer.domElement.style.cursor = 'pointer';
  container.appendChild(renderer.domElement);

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(50, w / h, 0.1, 100);
  const camHome = new THREE.Vector3(0, 0.15, 6.2);
  camera.position.copy(camHome);
  scene.add(camera);

  scene.add(new THREE.AmbientLight(0xffffff, 0.32));
  const pointLight = new THREE.PointLight(0xffffff, 8, 24, 0.35);
  pointLight.position.set(2, 3, 4);
  scene.add(pointLight);
  const dirLight = new THREE.DirectionalLight(0xffffff, 1.8);
  dirLight.position.set(-2, 4, 5);
  scene.add(dirLight);

  const gridSize = 4;
  const cellSize = 2 / gridSize;
  const spread = ((gridSize - 1) / 2) * cellSize;
  const count = gridSize * gridSize * gridSize;
  const geometry = new THREE.BoxGeometry(cellSize * 0.92, cellSize * 0.92, cellSize * 0.92);
  const material = new THREE.MeshLambertMaterial({ color: new THREE.Color(colorHex) });
  const mesh = new THREE.InstancedMesh(geometry, material, count);
  mesh.castShadow = mesh.receiveShadow = true;
  mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
  const colors = new Float32Array(count * 3);
  const baseColor = new THREE.Color(colorHex);
  for (let i = 0; i < count; i += 1) {
    baseColor.toArray(colors, i * 3);
  }
  mesh.instanceColor = new THREE.InstancedBufferAttribute(colors, 3);
  scene.add(mesh);

  const focusGeo = new THREE.BoxGeometry(cellSize * 1.15, cellSize * 1.15, cellSize * 1.15);
  let faceTexture = createFaceTexture(getSlide(), colorHex);
  const faceMat = new THREE.MeshStandardMaterial({
    map: faceTexture,
    roughness: 0.45,
    metalness: 0.08,
  });
  const sideMat = new THREE.MeshStandardMaterial({
    color: new THREE.Color(colorHex),
    roughness: 0.4,
    metalness: 0.12,
    emissive: new THREE.Color(colorHex),
    emissiveIntensity: 0.18,
  });
  const focusMats = [sideMat, sideMat, sideMat, sideMat, faceMat, sideMat];
  const focusMesh = new THREE.Mesh(focusGeo, focusMats);
  focusMesh.visible = false;
  scene.add(focusMesh);

  const dummy = new THREE.Object3D();
  const worldPos = new THREE.Vector3();
  const raycaster = new THREE.Raycaster();
  const pointer = new THREE.Vector2();

  const animations = [];
  const timeouts = [];
  let timer = null;
  let instances = null;
  let bases = [];
  let stopped = false;
  let focusIndex = 0;
  let meshSpin = null;

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
    stagger([0, 420], { grid: true, from: 'center', reversed: true, ease: 'in(3)' });

  const refreshFace = () => {
    const slide = getSlide();
    const next = createFaceTexture(slide, sideMat.color.getStyle());
    faceTexture.dispose();
    faceTexture = next;
    faceMat.map = faceTexture;
    faceMat.needsUpdate = true;
  };

  const pickFocusIndex = () => {
    let next = Math.floor(Math.random() * count);
    if (count > 1) {
      while (next === focusIndex) next = Math.floor(Math.random() * count);
    }
    focusIndex = next;
    return focusIndex;
  };

  const instanceWorldPosition = (index, out = worldPos) => {
    const inst = instances[index];
    dummy.position.set(inst.x, inst.y, inst.z);
    dummy.scale.set(inst.scale ?? 1, inst.scale ?? 1, inst.scale ?? 1);
    dummy.rotation.set(0, 0, 0);
    dummy.updateMatrix();
    // Instances are under spinning mesh — bake mesh world matrix
    out.copy(dummy.position).applyMatrix4(mesh.matrixWorld);
    return out;
  };

  const playZoomIn = () => {
    if (stopped || !instances) return;
    const idx = pickFocusIndex();
    refreshFace();
    onPhase('open');

    // Hide the chosen instance while focus mesh shows it
    utils.set(instances[idx], { scale: 0.001 });
    instanceWorldPosition(idx, worldPos);
    focusMesh.position.copy(worldPos);
    focusMesh.scale.setScalar(0.35);
    focusMesh.visible = true;
    focusMesh.lookAt(camera.position);

    const camTarget = worldPos.clone().add(new THREE.Vector3(0, 0.1, 1.55));
    const look = worldPos.clone();

    animations.push(
      animate(focusMesh.scale, {
        x: 1.65,
        y: 1.65,
        z: 1.65,
        duration: ZOOM_MS,
        ease: 'inOutCubic',
      }),
    );

    animations.push(
      animate(camera.position, {
        x: camTarget.x,
        y: camTarget.y,
        z: camTarget.z,
        duration: ZOOM_MS,
        ease: 'inOutCubic',
        onUpdate: () => camera.lookAt(look),
        onComplete: () => {
          if (stopped) return;
          camera.lookAt(look);
          trackTimeout(playZoomOut, HOLD_MS);
        },
      }),
    );
  };

  const playZoomOut = () => {
    if (stopped || !instances) return;
    onPhase('close');

    animations.push(
      animate(focusMesh.scale, {
        x: 0.4,
        y: 0.4,
        z: 0.4,
        duration: ZOOM_MS * 0.85,
        ease: 'inOutCubic',
      }),
    );

    animations.push(
      animate(camera.position, {
        x: camHome.x,
        y: camHome.y,
        z: camHome.z,
        duration: ZOOM_MS * 0.85,
        ease: 'inOutCubic',
        onUpdate: () => camera.lookAt(0, 0, 0),
        onComplete: () => {
          if (stopped) return;
          focusMesh.visible = false;
          utils.set(instances[focusIndex], { scale: 1 });
          trackTimeout(() => {
            if (!stopped) onPhase('advance');
            playContract();
          }, 200);
        },
      }),
    );
  };

  const playExpand = () => {
    if (stopped || !instances) return;
    const a = animate(instances, {
      x: (_, i) => bases[i].x * 8.5,
      y: (_, i) => bases[i].y * 8.5,
      z: (_, i) => bases[i].z * 8.5,
      duration: OPEN_MS,
      delay: staggerDelay(),
      ease: 'inOutExpo',
      onComplete: () => {
        if (stopped) return;
        trackTimeout(playZoomIn, 280);
      },
    });
    animations.push(a);
  };

  const playContract = () => {
    if (stopped || !instances) return;
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
    focusMesh.visible = false;
    camera.position.copy(camHome);
    camera.lookAt(0, 0, 0);

    instances = getInstances(mesh);
    utils.set(instances, {
      x: stagger([-spread, spread], { grid: [gridSize, gridSize, gridSize], axis: 'x' }),
      y: stagger([-spread, spread], { grid: [gridSize, gridSize, gridSize], axis: 'y' }),
      z: stagger([-spread, spread], { grid: [gridSize, gridSize, gridSize], axis: 'z' }),
      scale: 1,
    });
    bases = instances.map((inst) => ({ x: inst.x, y: inst.y, z: inst.z }));

    if (reduced) {
      refreshFace();
      onPhase('open');
      renderer.render(scene, camera);
      return;
    }

    meshSpin = animate(mesh, {
      rotateY: { to: 360, duration: 22000 },
      rotateX: { to: 18, duration: 14000 },
      loop: true,
      ease: 'linear',
    });
    animations.push(meshSpin);

    animations.push(
      animate(pointLight, {
        intensity: [18, 4],
        duration: 4200,
        loop: true,
        alternate: true,
        ease: 'inOutSine',
      }),
    );

    playExpand();
  };

  const onPointerDown = (event) => {
    if (stopped) return;
    const rect = renderer.domElement.getBoundingClientRect();
    pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
    pointer.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
    raycaster.setFromCamera(pointer, camera);
    const hits = raycaster.intersectObject(mesh, false);
    if (!hits.length) {
      // Also allow clicking the focus cube
      const focusHits = raycaster.intersectObject(focusMesh, false);
      if (focusHits.length && focusMesh.visible) {
        const c = randomColor();
        sideMat.color.copy(c);
        sideMat.emissive.copy(c);
        refreshFace();
      }
      return;
    }
    const id = hits[0].instanceId;
    if (id == null) return;
    const c = randomColor();
    mesh.setColorAt(id, c);
    mesh.instanceColor.needsUpdate = true;
    if (id === focusIndex && focusMesh.visible) {
      sideMat.color.copy(c);
      sideMat.emissive.copy(c);
      refreshFace();
    }
  };

  renderer.domElement.addEventListener('pointerdown', onPointerDown);

  layoutAndAnimate();

  if (!reduced) {
    timer = createTimer({
      onUpdate: () => {
        if (focusMesh.visible) {
          // Keep face toward camera while parent mesh spins
          instanceWorldPosition(focusIndex, worldPos);
          focusMesh.position.copy(worldPos);
          focusMesh.quaternion.copy(camera.quaternion);
        }
        renderer.render(scene, camera);
      },
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
    },
    setSlide() {
      refreshFace();
    },
    setColor(hex) {
      const c = new THREE.Color(hex);
      material.color.copy(c);
      sideMat.color.copy(c);
      sideMat.emissive.copy(c);
    },
    destroy() {
      stopped = true;
      stopAnims();
      renderer.domElement.removeEventListener('pointerdown', onPointerDown);
      try {
        timer?.pause();
        timer?.cancel?.();
      } catch {
        /* ignore */
      }
      timer = null;
      ro?.disconnect();
      window.removeEventListener('resize', onResize);
      faceTexture.dispose();
      geometry.dispose();
      focusGeo.dispose();
      material.dispose();
      faceMat.dispose();
      sideMat.dispose();
      renderer.dispose();
      if (renderer.domElement.parentNode === container) {
        container.removeChild(renderer.domElement);
      }
    },
  };
}
