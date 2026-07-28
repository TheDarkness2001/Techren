"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";

const links = [
  { href: "#about", label: "About" },
  { href: "#courses", label: "Courses" },
  { href: "#download", label: "Download" },
  { href: "#contact", label: "Contact" },
];

export function SiteNav() {
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 24);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header
      className={`fixed inset-x-0 top-0 z-50 transition-all duration-500 ${
        scrolled || open ? "border-b border-line bg-[#050816]/80 backdrop-blur-xl" : "bg-transparent"
      }`}
    >
      <div className="mx-auto flex max-w-site items-center justify-between px-5 py-4 sm:px-8">
        <Link href="/" className="magnetic cursor-grow inline-flex items-center gap-3">
          <span className="grid h-9 w-9 place-items-center overflow-hidden rounded-xl bg-white/95">
            <Image src="/logo.png" alt="" width={28} height={28} priority />
          </span>
          <span className="font-display text-base font-bold tracking-tight">TechRen EDU</span>
        </Link>

        <nav className="hidden items-center gap-8 md:flex" aria-label="Primary">
          {links.map((l) => (
            <a
              key={l.href}
              href={l.href}
              className="cursor-grow text-sm font-medium text-white/65 transition hover:text-white"
            >
              {l.label}
            </a>
          ))}
        </nav>

        <a
          href="#download"
          className="btn-premium magnetic hidden rounded-full px-4 py-2 text-sm font-semibold md:inline-flex"
        >
          Download
        </a>

        <button
          type="button"
          className="magnetic grid h-10 w-10 place-items-center rounded-full border border-line md:hidden"
          aria-label="Menu"
          onClick={() => setOpen((v) => !v)}
        >
          <span className="flex w-4 flex-col gap-1.5">
            <span className={`h-px bg-white transition ${open ? "translate-y-[3.5px] rotate-45" : ""}`} />
            <span className={`h-px bg-white transition ${open ? "-translate-y-[3.5px] -rotate-45" : ""}`} />
          </span>
        </button>
      </div>

      {open && (
        <div className="border-t border-line bg-[#050816]/95 px-5 py-6 backdrop-blur-xl md:hidden">
          <div className="flex flex-col gap-4">
            {links.map((l) => (
              <a
                key={l.href}
                href={l.href}
                className="font-display text-2xl font-bold"
                onClick={() => setOpen(false)}
              >
                {l.label}
              </a>
            ))}
          </div>
        </div>
      )}
    </header>
  );
}
