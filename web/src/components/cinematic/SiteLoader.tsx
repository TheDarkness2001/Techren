"use client";

import { useEffect, useState, type ReactNode } from "react";

type Props = {
  children: ReactNode;
};

const PRELOAD_URLS = [
  "/loaders/paper-plane.svg",
  "/loaders/loading-bar.svg",
  "/logo.png",
];

function preloadUrl(url: string) {
  return new Promise<void>((resolve) => {
    if (url.endsWith(".glb")) {
      fetch(url, { method: "GET", cache: "force-cache" })
        .then(() => resolve())
        .catch(() => resolve());
      return;
    }
    const img = new Image();
    img.onload = () => resolve();
    img.onerror = () => resolve();
    img.src = url;
  });
}

export function SiteLoader({ children }: Props) {
  const [visible, setVisible] = useState(true);
  const [leaving, setLeaving] = useState(false);

  useEffect(() => {
    let cancelled = false;
    const minMs = 1600;

    document.documentElement.classList.add("site-loading");

    const finish = () => {
      if (cancelled) return;
      setLeaving(true);
      window.setTimeout(() => {
        if (cancelled) return;
        setVisible(false);
        document.documentElement.classList.remove("site-loading");
      }, 520);
    };

    Promise.all([
      ...PRELOAD_URLS.map(preloadUrl),
      new Promise<void>((r) => {
        if (document.readyState === "complete") r();
        else window.addEventListener("load", () => r(), { once: true });
      }),
      new Promise<void>((r) => window.setTimeout(r, minMs)),
    ]).then(finish);

    const failSafe = window.setTimeout(finish, 12000);

    return () => {
      cancelled = true;
      window.clearTimeout(failSafe);
      document.documentElement.classList.remove("site-loading");
    };
  }, []);

  return (
    <>
      {visible && (
        <div
          className={`site-loader fixed inset-0 z-[100] flex flex-col items-center justify-center bg-black transition-opacity duration-500 ${
            leaving ? "pointer-events-none opacity-0" : "opacity-100"
          }`}
          role="status"
          aria-live="polite"
          aria-label="Loading TechRen EDU"
        >
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/loaders/paper-plane.svg"
            alt=""
            className="h-[min(42vw,220px)] w-[min(56vw,300px)] object-contain"
            draggable={false}
          />
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/loaders/loading-bar.svg"
            alt="Loading"
            className="mt-2 h-auto w-[min(72vw,320px)] object-contain"
            draggable={false}
          />
          <p className="mt-6 font-display text-xs uppercase tracking-[0.28em] text-white/45">
            TechRen Academy
          </p>
        </div>
      )}
      <div
        className={
          visible
            ? "pointer-events-none opacity-0"
            : "opacity-100 transition-opacity duration-500"
        }
        aria-hidden={visible}
      >
        {children}
      </div>
    </>
  );
}
