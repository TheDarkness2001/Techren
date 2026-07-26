"use client";

import { useRef } from "react";

type Props = {
  href?: string;
  children: React.ReactNode;
  className?: string;
  onClick?: () => void;
};

/** Magnetic CTA with glow + ripple on click. */
export function MagneticButton({ href, children, className = "", onClick }: Props) {
  const ref = useRef<HTMLAnchorElement | HTMLButtonElement>(null);

  const onMove = (e: React.MouseEvent) => {
    const el = ref.current;
    if (!el || window.matchMedia("(pointer: coarse)").matches) return;
    const rect = el.getBoundingClientRect();
    const dx = e.clientX - (rect.left + rect.width / 2);
    const dy = e.clientY - (rect.top + rect.height / 2);
    el.style.transform = `translate3d(${dx * 0.22}px, ${dy * 0.22}px, 0) scale(1.04)`;
  };

  const onLeave = () => {
    const el = ref.current;
    if (!el) return;
    el.style.transform = "translate3d(0,0,0) scale(1)";
  };

  const spawnRipple = (e: React.MouseEvent) => {
    const el = ref.current;
    if (!el) return;
    const rect = el.getBoundingClientRect();
    const ripple = document.createElement("span");
    ripple.className = "ripple";
    const size = Math.max(rect.width, rect.height);
    ripple.style.width = ripple.style.height = `${size}px`;
    ripple.style.left = `${e.clientX - rect.left - size / 2}px`;
    ripple.style.top = `${e.clientY - rect.top - size / 2}px`;
    el.appendChild(ripple);
    window.setTimeout(() => ripple.remove(), 700);
  };

  const classes = `btn-premium magnetic inline-flex items-center justify-center rounded-full px-7 py-3.5 text-sm font-semibold ${className}`;

  if (href) {
    return (
      <a
        ref={ref as React.RefObject<HTMLAnchorElement>}
        href={href}
        className={classes}
        onMouseMove={onMove}
        onMouseLeave={onLeave}
        onMouseDown={spawnRipple}
        onClick={onClick}
      >
        {children}
      </a>
    );
  }

  return (
    <button
      ref={ref as React.RefObject<HTMLButtonElement>}
      type="button"
      className={classes}
      onMouseMove={onMove}
      onMouseLeave={onLeave}
      onMouseDown={spawnRipple}
      onClick={onClick}
    >
      {children}
    </button>
  );
}
