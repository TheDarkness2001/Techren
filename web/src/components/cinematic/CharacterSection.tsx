"use client";

import dynamic from "next/dynamic";
import { MagneticButton } from "./MagneticButton";

const CharacterViewer = dynamic(
  () => import("./CharacterViewer").then((m) => m.CharacterViewer),
  {
    ssr: false,
    loading: () => (
      <div className="grid h-full min-h-[22rem] place-items-center rounded-[2rem] border border-line bg-white/[0.03]">
        <p className="text-sm text-white/45">Loading 3D character…</p>
      </div>
    ),
  }
);

export function CharacterSection() {
  return (
    <section id="character" className="fade-section relative border-y border-line py-28 sm:py-36">
      <div className="mx-auto grid max-w-site gap-10 px-5 sm:px-8 lg:grid-cols-[1.05fr_0.95fr] lg:items-center">
        <div>
          <p className="fade-up section-label">3D character</p>
          <h2 className="fade-up mt-4 font-display text-4xl font-bold tracking-tight sm:text-5xl">
            Meet the TechRen avatar.
          </h2>
          <p className="fade-up mt-6 max-w-xl text-lg text-white/60">
            Click anywhere on the floor and the avatar walks over, then says{" "}
            <span className="text-white">Hi!</span> Click the character to wave. This model is a static{" "}
            <span className="text-white">.glb</span> (no bones), so walk/wave are motion effects — real limb animation
            needs an animated GLB (e.g. Mixamo).
          </p>
          <div className="fade-up mt-8 flex flex-wrap gap-3">
            <MagneticButton href="#download">Get the app</MagneticButton>
            <a
              href="#features"
              className="cursor-grow rounded-full border border-line px-6 py-3.5 text-sm font-semibold text-white/75 transition hover:border-white/35 hover:text-white"
            >
              See features
            </a>
          </div>
        </div>

        <div className="fade-up h-[min(70vh,34rem)] w-full">
          <CharacterViewer className="h-full w-full border border-line bg-[#050816]" />
        </div>
      </div>
    </section>
  );
}
