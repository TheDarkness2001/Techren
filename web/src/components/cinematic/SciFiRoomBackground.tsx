"use client";

import { Component, Suspense, useEffect, useRef, useState, type ReactNode } from "react";
import { Canvas, useFrame, useThree } from "@react-three/fiber";
import { Center, useGLTF } from "@react-three/drei";
import * as THREE from "three";

const MODEL_URL = "/models/sci-fi-computer-room.glb";

type TiltRef = { current: { x: number; y: number } };

function RoomModel({
  tiltRef,
  zoomed,
  reduceMotion,
}: {
  tiltRef: TiltRef;
  zoomed: boolean;
  reduceMotion: boolean;
}) {
  const group = useRef<THREE.Group>(null);
  const { scene } = useGLTF(MODEL_URL);
  const ready = useRef(false);

  useEffect(() => {
    scene.traverse((obj) => {
      const mesh = obj as THREE.Mesh;
      if (!mesh.isMesh) return;
      mesh.castShadow = false;
      mesh.receiveShadow = false;
      mesh.frustumCulled = false;
    });
    ready.current = true;
  }, [scene]);

  const smoothTilt = useRef({ x: 0, y: 0 });

  useFrame((_, delta) => {
    if (!group.current) return;
    const dt = Math.min(delta, 0.033);

    const wantX = reduceMotion ? 0 : tiltRef.current.y * 0.04;
    const wantY = reduceMotion ? 0 : tiltRef.current.x * 0.065;
    smoothTilt.current.x = THREE.MathUtils.damp(smoothTilt.current.x, wantX, 3.5, dt);
    smoothTilt.current.y = THREE.MathUtils.damp(smoothTilt.current.y, wantY, 3.5, dt);

    const wantZ = zoomed ? 0.85 : 0;
    const wantScale = zoomed ? 1.18 : 1;

    group.current.rotation.x = smoothTilt.current.x;
    group.current.rotation.y = smoothTilt.current.y;
    group.current.position.z = THREE.MathUtils.damp(group.current.position.z, wantZ, 4, dt);
    const s = THREE.MathUtils.damp(group.current.scale.x, wantScale, 4, dt);
    group.current.scale.setScalar(s);
  });

  return (
    <group ref={group}>
      <Center>
        <primitive object={scene} scale={1.2} />
      </Center>
    </group>
  );
}

function CameraRig({ zoomed }: { zoomed: boolean }) {
  const { camera } = useThree();
  useFrame((_, delta) => {
    const dt = Math.min(delta, 0.033);
    const want = zoomed ? new THREE.Vector3(0, 0.2, 2.0) : new THREE.Vector3(0, 0.35, 3.35);
    camera.position.x = THREE.MathUtils.damp(camera.position.x, want.x, 3.5, dt);
    camera.position.y = THREE.MathUtils.damp(camera.position.y, want.y, 3.5, dt);
    camera.position.z = THREE.MathUtils.damp(camera.position.z, want.z, 3.5, dt);
    camera.lookAt(0, 0, 0);
  });
  return null;
}

class CanvasErrorBoundary extends Component<
  { children: ReactNode; onRetry: () => void },
  { hasError: boolean; message: string }
> {
  state = { hasError: false, message: "" };

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, message: error?.message || "3D render error" };
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="absolute inset-0 grid place-items-center bg-[#050816] px-6 text-center">
          <div>
            <p className="text-sm text-white/65">Couldn’t show the room.</p>
            <p className="mt-2 text-xs text-white/35">{this.state.message}</p>
            <button
              type="button"
              className="mt-4 rounded-full border border-line px-4 py-2 text-sm text-white/80 hover:border-white/40"
              onClick={() => {
                this.setState({ hasError: false, message: "" });
                this.props.onRetry();
              }}
            >
              Try again
            </button>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}

type Props = {
  className?: string;
  zoomed: boolean;
  onToggleZoom: () => void;
};

export function SciFiRoomBackground({ className = "", zoomed, onToggleZoom }: Props) {
  const hostRef = useRef<HTMLDivElement>(null);
  const tiltRef = useRef({ x: 0, y: 0 });
  const [reduceMotion, setReduceMotion] = useState(false);
  const [canvasKey, setCanvasKey] = useState(0);

  useEffect(() => {
    setReduceMotion(window.matchMedia("(prefers-reduced-motion: reduce)").matches);
  }, []);

  useEffect(() => {
    const el = hostRef.current;
    if (!el) return;

    const onMove = (e: MouseEvent) => {
      const rect = el.getBoundingClientRect();
      if (!rect.width || !rect.height) return;
      const x = ((e.clientX - rect.left) / rect.width - 0.5) * 2;
      const y = ((e.clientY - rect.top) / rect.height - 0.5) * 2;
      tiltRef.current.x = THREE.MathUtils.clamp(x, -1, 1);
      tiltRef.current.y = THREE.MathUtils.clamp(y, -1, 1);
    };
    const onLeave = () => {
      tiltRef.current.x = 0;
      tiltRef.current.y = 0;
    };

    el.addEventListener("mousemove", onMove, { passive: true });
    el.addEventListener("mouseleave", onLeave);
    return () => {
      el.removeEventListener("mousemove", onMove);
      el.removeEventListener("mouseleave", onLeave);
    };
  }, []);

  return (
    <div
      ref={hostRef}
      className={`absolute inset-0 cursor-pointer ${className}`}
      onClick={onToggleZoom}
      role="presentation"
    >
      <CanvasErrorBoundary onRetry={() => setCanvasKey((k) => k + 1)}>
        <Canvas
          key={canvasKey}
          dpr={[1, 1.25]}
          camera={{ position: [0, 0.35, 3.35], fov: 42, near: 0.05, far: 100 }}
          gl={{
            antialias: true,
            alpha: false,
            powerPreference: "default",
            failIfMajorPerformanceCaveat: false,
          }}
          onCreated={({ gl }) => {
            gl.setClearColor("#050816", 1);
            gl.toneMapping = THREE.ACESFilmicToneMapping;
            gl.toneMappingExposure = 1.1;
          }}
          style={{ width: "100%", height: "100%", display: "block", cursor: "pointer" }}
        >
          <color attach="background" args={["#050816"]} />
          <hemisphereLight args={["#9ec9ff", "#1a1028", 0.6]} />
          <ambientLight intensity={0.9} />
          <directionalLight position={[4, 6, 3]} intensity={1.5} />
          <directionalLight position={[-4, 2, -2]} intensity={0.5} color="#6C63FF" />
          <Suspense fallback={null}>
            <RoomModel tiltRef={tiltRef} zoomed={zoomed} reduceMotion={reduceMotion} />
          </Suspense>
          <CameraRig zoomed={zoomed} />
        </Canvas>
      </CanvasErrorBoundary>
    </div>
  );
}
