"use client";

import { useEffect, useState } from "react";
import { MagneticButton } from "./MagneticButton";

type StatusJson = {
  version?: string;
  androidUrl?: string;
  windowsUrl?: string;
  macosUrl?: string;
  iosUrl?: string;
};

const FALLBACK = {
  androidUrl: "https://github.com/TheDarkness2001/Techren/releases/latest/download/techren-edu.apk",
  windowsUrl: "https://github.com/TheDarkness2001/Techren/releases/latest/download/TechRenEDU-setup.exe",
  macosUrl: "https://github.com/TheDarkness2001/Techren/releases/latest/download/TechRenEDU-macos.zip",
  iosUrl: "https://github.com/TheDarkness2001/Techren/releases/latest",
};

export function DownloadPanel() {
  const [status, setStatus] = useState<StatusJson | null>(null);

  useEffect(() => {
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
  const items = [
    { title: "Android", href: status?.androidUrl || FALLBACK.androidUrl, note: "APK · Update in-app" },
    { title: "Windows", href: status?.windowsUrl || FALLBACK.windowsUrl, note: "Setup wizard" },
    { title: "Mac", href: status?.macosUrl || FALLBACK.macosUrl, note: "Zip · Applications" },
    { title: "iPhone", href: status?.iosUrl || FALLBACK.iosUrl, note: "TestFlight / release" },
  ];

  return (
    <div>
      <p className="mb-6 text-white/55">
        Version <span className="text-white">{version}</span> — install once, update in-app later.
      </p>
      <div className="grid gap-3 sm:grid-cols-2">
        {items.map((item) => (
          <a
            key={item.title}
            href={item.href}
            className="reveal-card glass cursor-grow group flex items-center justify-between rounded-2xl px-5 py-5 transition hover:border-white/30 hover:bg-white/10"
          >
            <div>
              <p className="font-display text-lg font-bold">{item.title}</p>
              <p className="mt-1 text-sm text-white/50">{item.note}</p>
            </div>
            <span className="text-secondary transition group-hover:translate-x-1">→</span>
          </a>
        ))}
      </div>
      <div className="mt-8">
        <MagneticButton href={items[0].href}>Download for Android</MagneticButton>
      </div>
    </div>
  );
}
