"use client";

import { motion, useReducedMotion } from "framer-motion";

export function AboutSection() {
  const reduce = useReducedMotion();

  return (
    <section id="about" className="border-y border-line bg-white">
      <div className="mx-auto grid w-full max-w-site gap-10 px-5 py-24 sm:px-8 lg:grid-cols-[0.9fr_1.1fr] lg:gap-16 lg:py-32">
        <motion.div
          initial={reduce ? false : { opacity: 0, y: 24 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, amount: 0.4 }}
          transition={{ duration: 0.6 }}
        >
          <p className="font-display text-xs font-semibold uppercase tracking-[0.24em] text-ink-mute">( about. )</p>
          <p className="mt-4 font-display text-sm font-semibold text-brand">[ N.002 ]</p>
        </motion.div>

        <motion.div
          initial={reduce ? false : { opacity: 0, y: 28 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, amount: 0.35 }}
          transition={{ duration: 0.7 }}
        >
          <h2 className="font-display text-4xl font-bold leading-[1.05] tracking-tight text-ink sm:text-5xl lg:text-6xl">
            In class and in code,
            <span className="text-ink-mute"> we keep only what helps students grow.</span>
          </h2>
          <p className="mt-8 max-w-2xl text-lg leading-relaxed text-ink-mute">
            TechRen EDU is built for our education center — not a generic LMS. Students practice words, sentences, and
            listening. Teachers mark attendance and send daily feedback. Staff see progress and monthly payments stay
            clear.
          </p>
        </motion.div>
      </div>

      <div className="overflow-hidden border-t border-line bg-ink text-paper">
        <div className="flex w-max animate-marquee gap-12 whitespace-nowrap py-5 font-display text-sm font-semibold uppercase tracking-[0.2em]">
          {Array.from({ length: 2 }).map((_, i) => (
            <div key={i} className="flex gap-12 px-6">
              <span>Words</span>
              <span className="text-brand-soft">•</span>
              <span>Sentences</span>
              <span className="text-brand-soft">•</span>
              <span>Listening</span>
              <span className="text-brand-soft">•</span>
              <span>Attendance</span>
              <span className="text-brand-soft">•</span>
              <span>Feedback</span>
              <span className="text-brand-soft">•</span>
              <span>Progress</span>
              <span className="text-brand-soft">•</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
