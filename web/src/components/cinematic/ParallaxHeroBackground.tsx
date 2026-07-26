"use client";

import { useEffect, useRef } from "react";
import gsap from "gsap";

/** Six independent parallax landscape layers + floating particles. */
export function ParallaxHeroBackground() {
  const rootRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const root = rootRef.current;
    if (!root) return;

    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const mobile = window.matchMedia("(max-width: 768px)").matches;
    if (reduce) return;

    const layers = {
      clouds: root.querySelector<HTMLElement>(".plx-cloud"),
      far: root.querySelector<HTMLElement>(".plx-far-mountains"),
      near: root.querySelector<HTMLElement>(".plx-near-mountains"),
      trees: root.querySelector<HTMLElement>(".plx-trees"),
      fog: root.querySelector<HTMLElement>(".plx-fog"),
      fore: root.querySelector<HTMLElement>(".plx-foreground"),
    };

    const onMove = (e: MouseEvent) => {
      if (mobile) return;
      const cx = (e.clientX / window.innerWidth - 0.5) * 2;
      const cy = (e.clientY / window.innerHeight - 0.5) * 2;
      gsap.to(layers.clouds, { x: cx * 12, y: cy * 6, duration: 1.2, ease: "power2.out", overwrite: true });
      gsap.to(layers.far, { x: cx * 18, y: cy * 8, duration: 1.1, ease: "power2.out", overwrite: true });
      gsap.to(layers.near, { x: cx * 28, y: cy * 12, duration: 1, ease: "power2.out", overwrite: true });
      gsap.to(layers.trees, { x: cx * 40, y: cy * 16, duration: 0.9, ease: "power2.out", overwrite: true });
    };

    window.addEventListener("mousemove", onMove);

    const particles = root.querySelectorAll<HTMLElement>(".particle");
    particles.forEach((p, i) => {
      gsap.to(p, {
        y: `-=${40 + (i % 5) * 12}`,
        x: `+=${((i % 3) - 1) * 18}`,
        opacity: 0.15 + (i % 4) * 0.15,
        duration: 3.5 + (i % 6) * 0.5,
        repeat: -1,
        yoyo: true,
        ease: "sine.inOut",
        delay: i * 0.12,
      });
    });

    gsap.to(layers.fog, {
      x: 40,
      duration: 12,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
    });

    return () => window.removeEventListener("mousemove", onMove);
  }, []);

  return (
    <div ref={rootRef} className="parallax-stage" aria-hidden>
      <div className="plx-layer plx-sky" data-speed="0" />
      <div className="light-rays" />
      <div className="plx-layer plx-cloud" data-speed="0.15" />
      <div className="plx-layer plx-far-mountains" data-speed="0.3" />
      <div className="plx-layer plx-near-mountains" data-speed="0.5" />
      <div className="plx-layer plx-trees" data-speed="0.75" />
      <div className="plx-layer plx-fog" data-speed="0.55" />
      <div className="plx-layer plx-foreground" data-speed="1" />
      {Array.from({ length: 18 }).map((_, i) => (
        <span
          key={i}
          className="particle"
          style={{
            left: `${6 + ((i * 17) % 88)}%`,
            top: `${12 + ((i * 23) % 60)}%`,
            opacity: 0.35,
          }}
        />
      ))}
    </div>
  );
}
