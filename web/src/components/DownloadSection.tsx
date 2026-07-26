"use client";

import { useEffect, useState } from "react";
import { motion, useReducedMotion } from "framer-motion";

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

export function DownloadSection() {
  const reduce = useReducedMotion();
  const [status, setStatus] = useState<StatusJson | null>(null);

  useEffect(() => {
    let cancelled = false;
    fetch("/downloads/status.json", { cache: "no-store" })
      .then((res) => (res.ok ? res.json() : null))
      .then((data) => {
        if (!cancelled && data) setStatus(data as StatusJson);
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, []);

  const version = status?.version ?? "latest";
  const platforms = [
    {
      title: "Android",
      href: status?.androidUrl || FALLBACK.androidUrl,
      note: "APK · Update in-app later",
      primary: true,
    },
    {
      title: "Windows",
      href: status?.windowsUrl || FALLBACK.windowsUrl,
      note: "Setup · Desktop + Start Menu",
      primary: false,
    },
    {
      title: "Mac",
      href: status?.macosUrl || FALLBACK.macosUrl,
      note: "Zip · Applications folder",
      primary: false,
    },
    {
      title: "iPhone",
      href: status?.iosUrl || FALLBACK.iosUrl,
      note: "TestFlight / release page",
      primary: false,
    },
  ];

  return (
    <section id="download" className="mx-auto w-full max-w-site px-5 py-24 sm:px-8 sm:py-32">
      <div className="flex flex-wrap items-end justify-between gap-6">
        <motion.div
          initial={reduce ? false : { opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
        >
          <p className="font-display text-xs font-semibold uppercase tracking-[0.24em] text-ink-mute">( download. )</p>
          <h2 className="mt-4 font-display text-4xl font-bold tracking-tight text-ink sm:text-5xl">
            Get TechRen EDU
          </h2>
          <p className="mt-4 max-w-xl text-ink-mute">
            Native apps for students and staff. Version <span className="font-semibold text-ink">{version}</span> —
            later updates install over the same app.
          </p>
        </motion.div>
        <p className="font-display text-sm font-semibold text-brand">[ N.005 ]</p>
      </div>

      <div className="mt-14 grid gap-3 sm:grid-cols-2">
        {platforms.map((platform, index) => (
          <motion.a
            key={platform.title}
            href={platform.href}
            initial={reduce ? false : { opacity: 0, y: 14 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.45, delay: index * 0.05 }}
            className={
              platform.primary
                ? "group flex items-center justify-between rounded-2xl bg-ink px-6 py-6 text-paper transition hover:bg-brand"
                : "group flex items-center justify-between rounded-2xl border border-line bg-white px-6 py-6 text-ink transition hover:border-ink/25"
            }
          >
            <div>
              <p className="font-display text-xl font-bold">{platform.title}</p>
              <p className={`mt-1 text-sm ${platform.primary ? "text-white/65" : "text-ink-mute"}`}>{platform.note}</p>
            </div>
            <span className="font-display text-lg transition group-hover:translate-x-1" aria-hidden>
              →
            </span>
          </motion.a>
        ))}
      </div>
    </section>
  );
}
