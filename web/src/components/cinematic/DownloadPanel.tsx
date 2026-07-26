"use client";

import { useEffect, useMemo, useState } from "react";
import { MagneticButton } from "./MagneticButton";

type StatusJson = {
  version?: string;
  androidUrl?: string;
  windowsUrl?: string;
  macosUrl?: string;
  iosUrl?: string;
};

type PlatformId = "android" | "windows" | "macos" | "ios";

const FALLBACK = {
  androidUrl: "https://github.com/TheDarkness2001/Techren/releases/latest/download/techren-edu.apk",
  windowsUrl: "https://github.com/TheDarkness2001/Techren/releases/latest/download/TechRenEDU-setup.exe",
  macosUrl: "https://github.com/TheDarkness2001/Techren/releases/latest/download/TechRenEDU-macos.zip",
  iosUrl: "https://github.com/TheDarkness2001/Techren/releases/latest",
};

function detectPlatform(): PlatformId {
  if (typeof navigator === "undefined") return "android";
  const ua = navigator.userAgent || "";
  const platform = navigator.platform || "";
  if (/Windows/i.test(ua) || /Win/i.test(platform)) return "windows";
  if (/Android/i.test(ua)) return "android";
  if (/iPhone|iPad|iPod/i.test(ua)) return "ios";
  if (/Mac/i.test(ua) || /Mac/i.test(platform)) return "macos";
  return "android";
}

export function DownloadPanel() {
  const [status, setStatus] = useState<StatusJson | null>(null);
  const [platform, setPlatform] = useState<PlatformId>("android");

  useEffect(() => {
    setPlatform(detectPlatform());
    let cancelled = false;
    fetch("/downloads/status.json", { cache: "no-store" })
      .then((r) => (r.ok ? r.json() : null))
      .then((d) => {
        if (!cancelled && d) setStatus(d as StatusJson);
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, []);

  const version = status?.version ?? "1.0.6";
  const items = useMemo(
    () => [
      {
        id: "windows" as const,
        title: "Windows",
        href: status?.windowsUrl || FALLBACK.windowsUrl,
        note: "Setup.exe · Desktop + Start Menu",
      },
      {
        id: "android" as const,
        title: "Android",
        href: status?.androidUrl || FALLBACK.androidUrl,
        note: "APK · Update in-app",
      },
      {
        id: "macos" as const,
        title: "Mac",
        href: status?.macosUrl || FALLBACK.macosUrl,
        note: "Zip · Applications",
      },
      {
        id: "ios" as const,
        title: "iPhone",
        href: status?.iosUrl || FALLBACK.iosUrl,
        note: "TestFlight / release",
      },
    ],
    [status]
  );

  const primary = items.find((i) => i.id === platform) ?? items[0];
  const ordered = [...items].sort((a, b) => {
    if (a.id === platform) return -1;
    if (b.id === platform) return 1;
    return 0;
  });

  return (
    <div>
      <p className="mb-6 text-white/55">
        Version <span className="text-white">{version}</span> — install once, update in-app later.
      </p>

      <div className="mb-8">
        <MagneticButton href={primary.href}>Download for {primary.title}</MagneticButton>
        <p className="mt-3 text-sm text-white/45">Detected: {primary.title}. Pick another platform below if needed.</p>
      </div>

      <div className="grid gap-3 sm:grid-cols-2">
        {ordered.map((item) => {
          const isPrimary = item.id === platform;
          return (
            <a
              key={item.id}
              href={item.href}
              className={`download-card cursor-grow group flex items-center justify-between rounded-2xl px-5 py-5 transition ${
                isPrimary
                  ? "border border-secondary/40 bg-secondary/10 hover:bg-secondary/15"
                  : "glass hover:border-white/30 hover:bg-white/10"
              }`}
            >
              <div>
                <p className="font-display text-lg font-bold">
                  {item.title}
                  {isPrimary ? <span className="ml-2 text-xs font-semibold uppercase tracking-wider text-secondary">Recommended</span> : null}
                </p>
                <p className="mt-1 text-sm text-white/50">{item.note}</p>
              </div>
              <span className="text-secondary transition group-hover:translate-x-1">→</span>
            </a>
          );
        })}
      </div>
    </div>
  );
}
