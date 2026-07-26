"use client";

import { motion, useReducedMotion } from "framer-motion";

export function Hero() {
  const reduce = useReducedMotion();

  return (
    <section className="hero-wash relative isolate min-h-[100svh] overflow-hidden pt-24">
      <div className="relative mx-auto flex min-h-[calc(100svh-6rem)] w-full max-w-site flex-col justify-between px-5 pb-10 sm:px-8 sm:pb-14">
        <div className="flex items-start justify-between gap-6 pt-6 sm:pt-10">
          <motion.p
            initial={reduce ? false : { opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.55 }}
            className="font-display text-xs font-semibold uppercase tracking-[0.28em] text-ink-mute"
          >
            Education center · edition_2.0
          </motion.p>
          <motion.p
            initial={reduce ? false : { opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.3 }}
            className="hidden font-display text-xs font-semibold text-ink-mute sm:block"
          >
            [ N.001 ]
          </motion.p>
        </div>

        <div className="py-10 sm:py-6">
          <motion.h1
            initial={reduce ? false : { opacity: 0, y: 36 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.85, ease: [0.22, 1, 0.36, 1] }}
            className="font-display text-[clamp(3.4rem,14vw,8.75rem)] font-extrabold leading-[0.86] tracking-[-0.05em] text-ink"
          >
            TechRen
            <span className="block text-brand">EDU</span>
          </motion.h1>

          <motion.p
            initial={reduce ? false : { opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.18 }}
            className="mt-8 max-w-xl font-display text-2xl font-semibold leading-snug tracking-tight text-ink-soft sm:text-3xl"
          >
            Learning is not noise —
            <span className="text-ink-mute"> it&apos;s clarity.</span>
          </motion.p>

          <motion.p
            initial={reduce ? false : { opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.65, delay: 0.32 }}
            className="mt-5 max-w-lg text-base text-ink-mute sm:text-lg"
          >
            The native app for our language school: practice, attendance, daily feedback, and progress — in one place.
          </motion.p>

          <motion.div
            initial={reduce ? false : { opacity: 0, y: 14 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.55, delay: 0.42 }}
            className="mt-10 flex flex-wrap gap-3"
          >
            <a
              href="#download"
              className="inline-flex items-center rounded-full bg-ink px-6 py-3.5 text-sm font-semibold text-paper transition hover:bg-brand"
            >
              Download the app
            </a>
            <a
              href="#about"
              className="inline-flex items-center rounded-full border border-line bg-white/50 px-6 py-3.5 text-sm font-semibold text-ink transition hover:border-ink/30"
            >
              About the center
            </a>
          </motion.div>
        </div>

        <motion.div
          initial={reduce ? false : { opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.55 }}
          className="flex items-end justify-between border-t border-line pt-5 text-xs font-medium uppercase tracking-[0.18em] text-ink-mute"
        >
          <span>Scroll</span>
          <span>dev• school platform</span>
        </motion.div>
      </div>
    </section>
  );
}
