import * as THREE from 'three';
import { animate, createTimer, stagger, utils } from 'animejs4';
import { getInstances } from 'animejs4/adapters/three';

const EXPAND_MS = 2200;
const CLOSE_MS = 2000;
const ZOOM_MS = 1200;
const HOLD_MS = 10000;
const GAP_MS = 500;

const PALETTE = ['#0f9f7e', '#5ce1b8', '#38bdf8', '#a78bfa', '#f59e0b', '#f472b6', '#34d399', '#60a5fa'];

function wrapLines(ctx, text, maxWidth, maxLines = 6) {
  const words = String(text || '')
    .trim()
    .split(/\s+/)
    .filter(Boolean);
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
  return lines.slice(0, maxLines);
}

/** Light face card — dark type on white for the zoomed cube. */
function createFaceTexture(slide, accentHex) {
  const canvas = document.createElement('canvas');
  canvas.width = 1024;
  canvas.height = 1024;
  const ctx = canvas.getContext('2d');

  ctx.fillStyle = '#ffffff';
  ctx.fillRect(0, 0, 1024, 1024);

  ctx.fillStyle = '#f4f4f1';
  ctx.fillRect(36, 36, 952, 952);

  ctx.strokeStyle = accentHex;
  ctx.lineWidth = 14;
  ctx.strokeRect(56, 56, 912, 912);

  ctx.fillStyle = accentHex;
  ctx.font = '700 42px "Space Grotesk", system-ui, sans-serif';
  ctx.fillText(String(slide?.kicker || 'TechRen').toUpperCase().slice(0, 24), 110, 160);

  ctx.fillStyle = '#111113';
  ctx.font = '700 72px "Space Grotesk", system-ui, sans-serif';
  let y = 280;
  wrapLines(ctx, slide?.title || '', 800, 3).forEach((ln) => {
    ctx.fillText(ln, 110, y);
    y += 86;
  });

  ctx.fillStyle = '#5c5c56';
  ctx.font = '500 36px "Manrope", system-ui, sans-serif';
  const body = slide?.lead || (Array.isArray(slide?.points) ? slide.points[0] : '') || '';
  wrapLines(ctx, body, 800, 5).forEach((ln) => {
    ctx.fillText(ln, 110, y + 24);
    y += 48;
  });

  if (Array.isArray(slide?.topics) && slide.topics.length) {
    ctx.fillStyle = accentHex;
    ctx.font = '600 28px "Space Grotesk", system-ui, sans-serif';
    ctx.fillText(slide.topics.slice(0, 5).join(' · '), 110, 930);
  }

  const tex = new THREE.CanvasTexture(canvas);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.anisotropy = 8;
  tex.needsUpdate = true;
  return tex;
}

function randomColor() {
  return new THREE.Color(PALETTE[Math.floor(Math.random() * PALETTE.length)]);
}

/**
 * White-background cube field:
 * expand → pause → zoom a random cube with info on its face → zoom out → contract → next.
 * Click a cube to recolor it.
 */
export function createAboutCubeScene(container, options = {}) {
  if (!container) return { destroy() {}, replay() {}, setSlide() {} };

  const colorHex = options.color || '#0f9f7e';
  const reduced = options.reducedMotion === true;
  const onPhase = typeof options.onPhase === 'function' ? options.onPhase : () => {};
  const getSlide =
    typeof options.getSlide === 'function'
      ? options.getSlide
      : () => ({
          kicker: 'TechRen',
          title: 'Learn. Build. Grow.',
          lead: 'Programming and English as skills you can use.',
        });

  const w = Math.max(container.clientWidth, 320);
  const h = Math.max(container.clientHeight, 280);

  const renderer = new THREE.WebGLRenderer({
    antialias: true,
    alpha: false,
    powerPreference: 'high-performance',
  });
  renderer.setClearColor(0xffffff, 1);
  renderer.setSize(w, h);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.domElement.className = 'about-webgl';
  renderer.domElement.style.cursor = 'pointer';
  container.appendChild(renderer.domElement);

  const scene = new THREE.Scene();
  scene.background = new THREE.Color(0xffffff);

  const camera = new THREE.PerspectiveCamera(42, w / h, 0.1, 100);
  const camHome = new THREE.Vector3(0, 0.2, 7.2);
  camera.position.copy(camHome);
  camera.lookAt(0, 0, 0);

  scene.add(new THREE.AmbientLight(0xffffff, 0.85));
  const key = new THREE.DirectionalLight(0xffffff, 1.15);
  key.position.set(3, 5, 6);
  scene.add(key);
  const fill = new THREE.DirectionalLight(0xffffff, 0.45);
  fill.position.set(-4, 2, 2);
  scene.add(fill);

  const gridSize = 4;
  const cellSize = 2 / gridSize;
  const spread = ((gridSize - 1) / 2) * cellSize;
  const count = gridSize ** 3;
  const expand = 4.2;

  const geometry = new THREE.BoxGeometry(cellSize * 0.88, cellSize * 0.88, cellSize * 0.88);
  const material = new THREE.MeshStandardMaterial({
    color: new THREE.Color(colorHex),
    roughness: 0.35,
    metalness: 0.05,
  });
  const mesh = new THREE.InstancedMesh(geometry, material, count);
  mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);

  const colorAttr = new Float32Array(count * 3);
  const seed = new THREE.Color(colorHex);
  for (let i = 0; i < count; i += 1) {
    // Slight variation so the field isn’t flat
    const c = seed.clone().offsetHSL((i % 7) * 0.01, 0, ((i % 5) - 2) * 0.02);
    c.toArray(colorAttr, i * 3);
  }
  mesh.instanceColor = new THREE.InstancedBufferAttribute(colorAttr, 3);
  scene.add(mesh);

  const focusSize = cellSize * 1.05;
  const focusGeo = new THREE.BoxGeometry(focusSize, focusSize, focusSize);
  let faceTexture = createFaceTexture(getSlide(), colorHex);
  const faceMat = new THREE.MeshStandardMaterial({
    map: faceTexture,
    roughness: 0.55,
    metalness: 0.02,
  });
  const sideMat = new THREE.MeshStandardMaterial({
    color: new THREE.Color(colorHex),
    roughness: 0.4,
    metalness: 0.08,
  });
  // +Z face is the “front” we keep toward the camera
  const focusMats = [sideMat, sideMat, sideMat, sideMat, faceMat, sideMat];
  const focusMesh = new THREE.Mesh(focusGeo, focusMats);
  focusMesh.visible = false;
  scene.add(focusMesh);

  const tmpLocal = new THREE.Matrix4();
  const tmpWorld = new THREE.Matrix4();
  const worldPos = new THREE.Vector3();
  const camTarget = new THREE.Vector3();
  const lookTarget = new THREE.Vector3();
  const raycaster = new THREE.Raycaster();
  const pointer = new THREE.Vector2();

  const animations = [];
  const timeouts = [];
  let timer = null;
  let instances = null;
  let bases = [];
  let stopped = false;
  let focusing = false;
  let holding = false;
  let focusIndex = 0;
  let spinAnim = null;
  let hiddenPos = null;

  const trackTimeout = (fn, ms) => {
    const id = window.setTimeout(fn, ms);
    timeouts.push(id);
    return id;
  };

  const clearTimeouts = () => {
    while (timeouts.length) window.clearTimeout(timeouts.pop());
  };

  const stopTrackedAnims = () => {
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
    stagger([0, 360], { grid: true, from: 'center', reversed: true, ease: 'in(2)' });

  const refreshFace = () => {
    const slide = getSlide();
    const accent = `#${sideMat.color.getHexString()}`;
    const next = createFaceTexture(slide, accent);
    faceTexture.dispose();
    faceTexture = next;
    faceMat.map = faceTexture;
    faceMat.needsUpdate = true;
  };

  const pauseSpin = () => {
    try {
      spinAnim?.pause();
    } catch {
      /* ignore */
    }
  };

  const resumeSpin = () => {
    try {
      spinAnim?.play();
    } catch {
      /* ignore */
    }
  };

  const readInstanceWorldPos = (index, out = worldPos) => {
    mesh.updateMatrixWorld(true);
    mesh.getMatrixAt(index, tmpLocal);
    tmpWorld.multiplyMatrices(mesh.matrixWorld, tmpLocal);
    out.setFromMatrixPosition(tmpWorld);
    return out;
  };

  const faceCamera = () => {
    focusMesh.quaternion.copy(camera.quaternion);
  };

  const playZoomIn = () => {
    if (stopped || !instances) return;
    focusing = true;
    pauseSpin();
    mesh.updateMatrixWorld(true);

    let next = Math.floor(Math.random() * count);
    if (count > 1) {
      let guard = 0;
      while (next === focusIndex && guard < 12) {
        next = Math.floor(Math.random() * count);
        guard += 1;
      }
    }
    focusIndex = next;

    refreshFace();
    onPhase('open');

    // Park the chosen instance out of the way
    const inst = instances[focusIndex];
    hiddenPos = { x: inst.x, y: inst.y, z: inst.z };
    utils.set(inst, { x: 80, y: 80, z: 80 });

    // Start from that cube’s world spot, then move it to screen center
    const start = new THREE.Vector3(hiddenPos.x, hiddenPos.y, hiddenPos.z).applyMatrix4(mesh.matrixWorld);
    focusMesh.position.copy(start);
    focusMesh.scale.setScalar(0.55);
    focusMesh.visible = true;
    faceCamera();

    // Hold dead-center in front of the camera
    const center = new THREE.Vector3(0, 0, 0);
    camTarget.set(0, 0, 3.4);
    lookTarget.copy(center);

    animations.push(
      animate(focusMesh.position, {
        x: center.x,
        y: center.y,
        z: center.z,
        duration: ZOOM_MS,
        ease: 'inOutCubic',
      }),
    );

    animations.push(
      animate(focusMesh.scale, {
        x: 2.6,
        y: 2.6,
        z: 2.6,
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
        onUpdate: () => {
          camera.lookAt(lookTarget);
          faceCamera();
        },
        onComplete: () => {
          if (stopped) return;
          // Lock in center for the full hold
          holding = true;
          focusMesh.position.set(0, 0, 0);
          camera.position.copy(camTarget);
          camera.lookAt(lookTarget);
          faceCamera();
          trackTimeout(playZoomOut, HOLD_MS);
        },
      }),
    );
  };

  const playZoomOut = () => {
    if (stopped || !instances) return;
    holding = false;
    onPhase('close');

    const returnPos = hiddenPos
      ? new THREE.Vector3(hiddenPos.x, hiddenPos.y, hiddenPos.z).applyMatrix4(mesh.matrixWorld)
      : new THREE.Vector3(0, 0, 0);

    animations.push(
      animate(focusMesh.position, {
        x: returnPos.x,
        y: returnPos.y,
        z: returnPos.z,
        duration: ZOOM_MS,
        ease: 'inOutCubic',
      }),
    );

    animations.push(
      animate(focusMesh.scale, {
        x: 0.7,
        y: 0.7,
        z: 0.7,
        duration: ZOOM_MS,
        ease: 'inOutCubic',
      }),
    );

    animations.push(
      animate(camera.position, {
        x: camHome.x,
        y: camHome.y,
        z: camHome.z,
        duration: ZOOM_MS,
        ease: 'inOutCubic',
        onUpdate: () => {
          camera.lookAt(0, 0, 0);
          if (focusMesh.visible) faceCamera();
        },
        onComplete: () => {
          if (stopped) return;
          focusMesh.visible = false;
          focusing = false;
          holding = false;
          if (hiddenPos) {
            utils.set(instances[focusIndex], {
              x: hiddenPos.x,
              y: hiddenPos.y,
              z: hiddenPos.z,
            });
            hiddenPos = null;
          }
          resumeSpin();
          trackTimeout(() => {
            if (!stopped) onPhase('advance');
            playContract();
          }, 180);
        },
      }),
    );
  };

  const playExpand = () => {
    if (stopped || !instances) return;
    const a = animate(instances, {
      x: (_, i) => bases[i].x * expand,
      y: (_, i) => bases[i].y * expand,
      z: (_, i) => bases[i].z * expand,
      duration: EXPAND_MS,
      delay: staggerDelay(),
      ease: 'inOutCubic',
      onComplete: () => {
        if (stopped) return;
        trackTimeout(playZoomIn, 220);
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
      ease: 'inOutCubic',
      onComplete: () => {
        if (stopped) return;
        trackTimeout(playExpand, GAP_MS);
      },
    });
    animations.push(a);
  };

  const layoutAndAnimate = () => {
    stopped = false;
    focusing = false;
    holding = false;
    stopTrackedAnims();
    focusMesh.visible = false;
    camera.position.copy(camHome);
    camera.lookAt(0, 0, 0);

    instances = getInstances(mesh);
    utils.set(instances, {
      x: stagger([-spread, spread], { grid: [gridSize, gridSize, gridSize], axis: 'x' }),
      y: stagger([-spread, spread], { grid: [gridSize, gridSize, gridSize], axis: 'y' }),
      z: stagger([-spread, spread], { grid: [gridSize, gridSize, gridSize], axis: 'z' }),
    });
    bases = instances.map((inst) => ({ x: inst.x, y: inst.y, z: inst.z }));

    if (reduced) {
      refreshFace();
      focusMesh.position.set(0, 0, 0);
      focusMesh.scale.setScalar(2.2);
      focusMesh.visible = true;
      faceCamera();
      onPhase('open');
      renderer.render(scene, camera);
      return;
    }

    spinAnim = animate(mesh, {
      rotateY: { to: 360, duration: 28000 },
      loop: true,
      ease: 'linear',
    });
    animations.push(spinAnim);

    playExpand();
  };

  const onPointerDown = (event) => {
    if (stopped) return;
    const rect = renderer.domElement.getBoundingClientRect();
    pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
    pointer.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
    raycaster.setFromCamera(pointer, camera);

    if (focusMesh.visible) {
      const focusHits = raycaster.intersectObject(focusMesh, false);
      if (focusHits.length) {
        const c = randomColor();
        sideMat.color.copy(c);
        mesh.setColorAt(focusIndex, c);
        mesh.instanceColor.needsUpdate = true;
        refreshFace();
        return;
      }
    }

    const hits = raycaster.intersectObject(mesh, false);
    if (!hits.length || hits[0].instanceId == null) return;
    const id = hits[0].instanceId;
    const c = randomColor();
    mesh.setColorAt(id, c);
    mesh.instanceColor.needsUpdate = true;
  };

  renderer.domElement.addEventListener('pointerdown', onPointerDown);
  layoutAndAnimate();

  if (!reduced) {
    timer = createTimer({
      onUpdate: () => {
        if (holding && focusMesh.visible) {
          // Keep the featured cube locked in the center while held
          focusMesh.position.set(0, 0, 0);
          faceCamera();
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
    },
    destroy() {
      stopped = true;
      focusing = false;
      stopTrackedAnims();
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
