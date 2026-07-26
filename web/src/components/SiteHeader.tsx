"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import { motion, useReducedMotion } from "framer-motion";

const links = [
  { href: "#about", label: "About" },
  { href: "#learn", label: "Learn" },
  { href: "#campus", label: "Campus" },
  { href: "#download", label: "Download" },
];

function NavItem({ href, label }: { href: string; label: string }) {
  return (
    <a href={href} className="nav-link font-display text-[0.95rem] font-semibold tracking-tight text-ink">
      <span>
        {label}
        <br aria-hidden />
        {label}
      </span>
    </a>
  );
}

export function SiteHeader() {
  const reduce = useReducedMotion();
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <motion.header
      initial={reduce ? false : { opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.55, ease: [0.22, 1, 0.36, 1] }}
      className={`fixed inset-x-0 top-0 z-40 transition-colors duration-300 ${
        scrolled || open ? "border-b border-line bg-paper/90 backdrop-blur-md" : "bg-transparent"
      }`}
    >
      <div className="mx-auto flex w-full max-w-site items-center justify-between px-5 py-4 sm:px-8">
        <Link href="/" className="inline-flex items-center gap-3 text-ink no-underline">
          <span className="relative grid h-9 w-9 place-items-center overflow-hidden rounded-lg bg-white shadow-[0_0_0_1px_rgba(11,18,32,0.08)]">
            <Image src="/logo.png" alt="" width={28} height={28} className="object-contain" priority />
          </span>
          <span className="font-display text-base font-bold tracking-tight sm:text-lg">TechRen EDU</span>
        </Link>

        <nav className="hidden items-center gap-8 md:flex" aria-label="Primary">
          {links.map((link) => (
            <NavItem key={link.href} href={link.href} label={link.label} />
          ))}
        </nav>

        <a
          href="#download"
          className="hidden rounded-full bg-ink px-4 py-2 text-sm font-semibold text-paper transition hover:bg-brand md:inline-flex"
        >
          Download
        </a>

        <button
          type="button"
          className="inline-flex h-10 w-10 items-center justify-center rounded-full border border-line md:hidden"
          aria-expanded={open}
          aria-label="Menu"
          onClick={() => setOpen((v) => !v)}
        >
          <span className="sr-only">Menu</span>
          <span className="flex w-4 flex-col gap-1.5">
            <span className={`h-px w-full bg-ink transition ${open ? "translate-y-[3.5px] rotate-45" : ""}`} />
            <span className={`h-px w-full bg-ink transition ${open ? "-translate-y-[3.5px] -rotate-45" : ""}`} />
          </span>
        </button>
      </div>

      {open && (
        <div className="border-t border-line bg-paper px-5 py-6 md:hidden">
          <nav className="flex flex-col gap-4" aria-label="Mobile">
            {links.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className="font-display text-2xl font-bold text-ink"
                onClick={() => setOpen(false)}
              >
                {link.label}
              </a>
            ))}
          </nav>
        </div>
      )}
    </motion.header>
  );
}
