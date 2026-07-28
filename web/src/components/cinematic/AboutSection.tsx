"use client";

import { useEffect, useState, type ComponentType } from "react";

type RoomProps = {
  zoomed: boolean;
  onToggleZoom: () => void;
};

export function AboutSection() {
  const [zoomed, setZoomed] = useState(false);
  const [Room, setRoom] = useState<ComponentType<RoomProps> | null>(null);

  useEffect(() => {
    let alive = true;
    void import("./SciFiRoomBackground").then((m) => {
      if (alive) setRoom(() => m.SciFiRoomBackground);
    });
    return () => {
      alive = false;
    };
  }, []);

  return (
    <section
      id="about"
      className="relative h-[100svh] min-h-[560px] overflow-hidden border-y border-line bg-[#050816]"
    >
      {Room ? (
        <Room zoomed={zoomed} onToggleZoom={() => setZoomed((v) => !v)} />
      ) : (
        <div className="absolute inset-0 grid place-items-center bg-[#050816]">
          <p className="font-display text-sm text-white/55">Loading room…</p>
        </div>
      )}

      <div className="pointer-events-none absolute inset-x-0 bottom-0 z-20 flex justify-center bg-gradient-to-t from-[#050816]/90 via-[#050816]/35 to-transparent px-5 pb-10 pt-24 sm:pb-14">
        <p
          className="programmer-cta font-display text-center text-[clamp(1.35rem,4.5vw,2.75rem)] font-bold tracking-tight"
          aria-label="Do you want to be a programmer?"
        >
          Do you want to be a programmer?
        </p>
      </div>
    </section>
  );
}
