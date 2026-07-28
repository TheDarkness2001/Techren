"use client";

import { Suspense, useEffect, useRef } from "react";
import { Canvas, useFrame, useThree } from "@react-three/fiber";
import { useAnimations, useGLTF } from "@react-three/drei";
import * as THREE from "three";
import type { MutableRefObject } from "react";

const MODEL_URL = "/models/robot-no1.glb";

function RobotActor({
  progressRef,
  courseIndex,
  accent,
  reduceMotion,
}: {
  progressRef: MutableRefObject<number>;
  courseIndex: number;
  accent: string;
  reduceMotion: boolean;
}) {
  const root = useRef<THREE.Group>(null);
  const { scene, animations } = useGLTF(MODEL_URL);
  const { camera } = useThree();
  const fitted = useRef(false);
  const { actions } = useAnimations(animations, root);
  const gesture = useRef(0);
  const lastIndex = useRef(courseIndex);
  const accentLight = useRef<THREE.PointLight>(null);

  useEffect(() => {
    scene.traverse((obj) => {
      const mesh = obj as THREE.Mesh;
      if (mesh.isMesh) {
        mesh.frustumCulled = false;
        mesh.castShadow = false;
        mesh.receiveShadow = false;
      }
    });
  }, [scene]);

  // Fit oversized Sketchfab model into the camera once meshes exist
  useFrame(() => {
    if (fitted.current || !root.current) return;
    const box = new THREE.Box3().setFromObject(root.current);
    if (box.isEmpty()) return;
    const size = box.getSize(new THREE.Vector3());
    const center = box.getCenter(new THREE.Vector3());
    const maxDim = Math.max(size.x, size.y, size.z, 0.001);
    const scale = 2.2 / maxDim;
    root.current.scale.setScalar(scale);
    root.current.position.set(-center.x * scale, -center.y * scale + 0.08, -center.z * scale);
    camera.position.set(0, 0.2, 3.5);
    camera.near = 0.05;
    camera.far = 200;
    camera.updateProjectionMatrix();
    camera.lookAt(0, 0.15, 0);
    fitted.current = true;
  });

  useEffect(() => {
    const action = actions.Scene ?? Object.values(actions)[0];
    if (!action) return;
    action.reset();
    action.setLoop(THREE.LoopRepeat, Infinity);
    action.clampWhenFinished = false;
    action.enabled = true;
    if (reduceMotion) {
      action.paused = true;
      action.time = 0.4;
    } else {
      action.paused = false;
      action.timeScale = 0.85;
      action.play();
    }
    return () => {
      action.stop();
    };
  }, [actions, reduceMotion]);

  useEffect(() => {
    if (lastIndex.current !== courseIndex) {
      gesture.current = 1;
      lastIndex.current = courseIndex;
      const action = actions.Scene ?? Object.values(actions)[0];
      if (action && !reduceMotion) {
        action.timeScale = 1.35;
        window.setTimeout(() => {
          if (action) action.timeScale = 0.85;
        }, 700);
      }
    }
  }, [actions, courseIndex, reduceMotion]);

  useEffect(() => {
    if (accentLight.current) accentLight.current.color.set(accent);
  }, [accent]);

  useFrame((_, delta) => {
    const dt = Math.min(delta, 0.033);
    if (!root.current || !fitted.current) return;

    gesture.current = THREE.MathUtils.damp(gesture.current, 0, 3.2, dt);
    const p = progressRef.current;
    const yaw = Math.sin(courseIndex * 0.55) * 0.28 + gesture.current * 0.45 + p * 0.15;
    const tilt = Math.sin(performance.now() / 700) * 0.03 + gesture.current * 0.08;

    root.current.rotation.y = THREE.MathUtils.damp(root.current.rotation.y, yaw, 4, dt);
    root.current.rotation.x = THREE.MathUtils.damp(root.current.rotation.x, tilt * 0.2, 4, dt);
  });

  return (
    <group>
      <pointLight ref={accentLight} position={[0.6, 1.2, 1.4]} intensity={1.1} distance={8} color={accent} />
      <group ref={root}>
        <primitive object={scene} />
      </group>
    </group>
  );
}

type Props = {
  progressRef: MutableRefObject<number>;
  courseIndex: number;
  accent: string;
  reduceMotion?: boolean;
  className?: string;
};

export function RobotGuide({
  progressRef,
  courseIndex,
  accent,
  reduceMotion = false,
  className = "",
}: Props) {
  return (
    <div className={`relative h-full w-full ${className}`}>
      <Canvas
        dpr={[1, 1.35]}
        camera={{ position: [0, 0.2, 3.4], fov: 38, near: 0.05, far: 200 }}
        gl={{
          antialias: true,
          alpha: false,
          powerPreference: "default",
          failIfMajorPerformanceCaveat: false,
        }}
        onCreated={({ gl }) => {
          gl.setClearColor("#070b1c", 1);
          gl.toneMapping = THREE.ACESFilmicToneMapping;
          gl.toneMappingExposure = 1.25;
        }}
        style={{ width: "100%", height: "100%", display: "block" }}
      >
        <color attach="background" args={["#070b1c"]} />
        <hemisphereLight args={["#dbeafe", "#0f172a", 0.75]} />
        <ambientLight intensity={1.05} />
        <directionalLight position={[4, 6, 3]} intensity={1.8} />
        <directionalLight position={[-3, 2, -2]} intensity={0.55} color="#a5b4fc" />
        <Suspense fallback={null}>
          <RobotActor
            progressRef={progressRef}
            courseIndex={courseIndex}
            accent={accent}
            reduceMotion={reduceMotion}
          />
        </Suspense>
      </Canvas>
    </div>
  );
}
