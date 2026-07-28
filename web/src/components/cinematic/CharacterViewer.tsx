"use client";

import { Suspense, useEffect, useMemo, useRef, useState } from "react";
import { Canvas, ThreeEvent, useFrame, useThree } from "@react-three/fiber";
import { ContactShadows, Environment, Html, OrbitControls, useGLTF } from "@react-three/drei";
import * as THREE from "three";

const MODEL_URL = "/models/techren-character.glb";

type MoveTarget = { x: number; z: number; greet: boolean } | null;

function Ground({ onMove }: { onMove: (x: number, z: number) => void }) {
  return (
    <mesh
      rotation={[-Math.PI / 2, 0, 0]}
      position={[0, -1.05, 0]}
      receiveShadow
      onClick={(e: ThreeEvent<MouseEvent>) => {
        e.stopPropagation();
        onMove(e.point.x, e.point.z);
      }}
      onPointerDown={(e) => e.stopPropagation()}
    >
      <planeGeometry args={[14, 14]} />
      <meshStandardMaterial color="#0b1224" transparent opacity={0.35} metalness={0.2} roughness={0.85} />
    </mesh>
  );
}

function ClickMarker({ target }: { target: MoveTarget }) {
  const ref = useRef<THREE.Mesh>(null);
  useFrame((_, dt) => {
    if (!ref.current || !target) return;
    ref.current.rotation.y += dt * 2;
    const s = 0.85 + Math.sin(performance.now() / 200) * 0.08;
    ref.current.scale.setScalar(s);
  });
  if (!target) return null;
  return (
    <mesh ref={ref} position={[target.x, -1.02, target.z]} rotation={[-Math.PI / 2, 0, 0]}>
      <ringGeometry args={[0.22, 0.34, 48]} />
      <meshBasicMaterial color="#00D4FF" transparent opacity={0.85} />
    </mesh>
  );
}

function CharacterActor({
  target,
  onArrived,
  reduceMotion,
}: {
  target: MoveTarget;
  onArrived: (greet: boolean) => void;
  reduceMotion: boolean;
}) {
  const root = useRef<THREE.Group>(null);
  const model = useRef<THREE.Group>(null);
  const { scene } = useGLTF(MODEL_URL);
  const cloned = useMemo(() => scene.clone(true), [scene]);

  const pos = useRef(new THREE.Vector3(0, 0, 0));
  const dest = useRef(new THREE.Vector3(0, 0, 0));
  const moving = useRef(false);
  const greetPending = useRef(false);
  const faceYaw = useRef(0);
  const bob = useRef(0);
  const waveT = useRef(0);
  const [sayingHi, setSayingHi] = useState(false);

  useEffect(() => {
    if (!target || !root.current) return;
    dest.current.set(target.x, 0, target.z);
    greetPending.current = target.greet;
    const dist = pos.current.distanceTo(dest.current);
    if (dist < 0.05) {
      moving.current = false;
      if (target.greet) {
        waveT.current = 1.4;
        setSayingHi(true);
        window.setTimeout(() => setSayingHi(false), 1800);
        onArrived(true);
      }
      return;
    }
    moving.current = true;
    setSayingHi(false);
  }, [target, onArrived]);

  useFrame((_, delta) => {
    if (!root.current || !model.current) return;
    const dt = Math.min(delta, 0.05);

    if (moving.current) {
      const speed = 2.4;
      const to = dest.current.clone().sub(pos.current);
      const dist = to.length();
      if (dist < 0.04) {
        pos.current.copy(dest.current);
        moving.current = false;
        bob.current = 0;
        if (greetPending.current) {
          waveT.current = 1.6;
          setSayingHi(true);
          window.setTimeout(() => setSayingHi(false), 2000);
          onArrived(true);
          greetPending.current = false;
        } else {
          onArrived(false);
        }
      } else {
        to.normalize();
        pos.current.addScaledVector(to, Math.min(dist, speed * dt));
        faceYaw.current = Math.atan2(to.x, to.z);
        bob.current += dt * 10;
      }
    }

    root.current.position.set(pos.current.x, 0, pos.current.z);
    // Smooth facing
    const cur = root.current.rotation.y;
    let diff = faceYaw.current - cur;
    while (diff > Math.PI) diff -= Math.PI * 2;
    while (diff < -Math.PI) diff += Math.PI * 2;
    root.current.rotation.y = cur + diff * Math.min(1, dt * 8);

    // Fake walk bob (no skeleton in this GLB)
    if (!reduceMotion && moving.current) {
      const hop = Math.abs(Math.sin(bob.current)) * 0.08;
      const lean = Math.sin(bob.current) * 0.06;
      model.current.position.y = hop - 0.15;
      model.current.rotation.z = lean;
      model.current.rotation.x = Math.abs(lean) * 0.35;
    } else if (waveT.current > 0 && !reduceMotion) {
      waveT.current = Math.max(0, waveT.current - dt);
      const w = Math.sin(waveT.current * 14) * 0.22 * Math.min(1, waveT.current);
      model.current.rotation.z = w;
      model.current.rotation.y = Math.sin(waveT.current * 10) * 0.12;
      model.current.position.y = -0.15;
    } else {
      model.current.position.y = THREE.MathUtils.damp(model.current.position.y, -0.15, 8, dt);
      model.current.rotation.z = THREE.MathUtils.damp(model.current.rotation.z, 0, 8, dt);
      model.current.rotation.x = THREE.MathUtils.damp(model.current.rotation.x, 0, 8, dt);
      model.current.rotation.y = THREE.MathUtils.damp(model.current.rotation.y, 0, 8, dt);
    }
  });

  return (
    <group ref={root}>
      <group
        ref={model}
        scale={1.05}
        onClick={(e) => {
          e.stopPropagation();
          waveT.current = 1.6;
          setSayingHi(true);
          window.setTimeout(() => setSayingHi(false), 2000);
        }}
      >
        <primitive object={cloned} />
      </group>
      {sayingHi && (
        <Html position={[0, 1.35, 0]} center distanceFactor={8} zIndexRange={[40, 0]}>
          <div className="rounded-2xl border border-white/20 bg-[#0b1224]/92 px-3 py-2 text-sm font-semibold text-white shadow-[0_8px_30px_rgba(108,99,255,0.35)] backdrop-blur">
            Hi! 👋
          </div>
        </Html>
      )}
    </group>
  );
}

function SceneContent({ reduceMotion }: { reduceMotion: boolean }) {
  const [target, setTarget] = useState<MoveTarget>(null);
  const { gl } = useThree();

  useEffect(() => {
    gl.domElement.style.cursor = "pointer";
  }, [gl]);

  return (
    <>
      <ambientLight intensity={0.55} />
      <directionalLight position={[4, 6, 2]} intensity={1.35} castShadow />
      <directionalLight position={[-3, 2, -2]} intensity={0.5} color="#00D4FF" />
      <Ground
        onMove={(x, z) => {
          const clampedX = THREE.MathUtils.clamp(x, -5.5, 5.5);
          const clampedZ = THREE.MathUtils.clamp(z, -5.5, 5.5);
          setTarget({ x: clampedX, z: clampedZ, greet: true });
        }}
      />
      <ClickMarker target={target} />
      <Suspense fallback={null}>
        <CharacterActor
          target={target}
          reduceMotion={reduceMotion}
          onArrived={() => undefined}
        />
        <Environment preset="city" />
        <ContactShadows position={[0, -1.05, 0]} opacity={0.4} scale={12} blur={2.5} far={3} />
      </Suspense>
      <OrbitControls enablePan={false} minDistance={2.2} maxDistance={7} maxPolarAngle={Math.PI / 2.05} />
    </>
  );
}

useGLTF.preload(MODEL_URL);

type Props = { className?: string };

export function CharacterViewer({ className = "" }: Props) {
  const [reduceMotion, setReduceMotion] = useState(false);

  useEffect(() => {
    setReduceMotion(window.matchMedia("(prefers-reduced-motion: reduce)").matches);
  }, []);

  return (
    <div className={`relative overflow-hidden rounded-[2rem] ${className}`}>
      <div className="pointer-events-none absolute inset-0 z-10 bg-[radial-gradient(ellipse_at_center,rgba(108,99,255,0.16),transparent_65%)]" />
      <Canvas
        shadows
        dpr={[1, 1.75]}
        camera={{ position: [2.4, 1.6, 3.4], fov: 40, near: 0.1, far: 60 }}
        gl={{ antialias: true, alpha: true, powerPreference: "high-performance" }}
        style={{ width: "100%", height: "100%" }}
        onPointerMissed={() => undefined}
      >
        <color attach="background" args={["#050816"]} />
        <SceneContent reduceMotion={reduceMotion} />
      </Canvas>
      <div className="pointer-events-none absolute bottom-4 left-4 right-4 z-20 flex flex-wrap items-end justify-between gap-2">
        <p className="text-[11px] uppercase tracking-[0.18em] text-white/45">
          Click the floor to move · Click the character to wave
        </p>
        <p className="text-[10px] text-white/30">Static GLB — walk/wave are procedural (no skeleton)</p>
      </div>
    </div>
  );
}
