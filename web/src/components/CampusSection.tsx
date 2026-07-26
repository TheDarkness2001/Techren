"use client";

import { motion, useReducedMotion } from "framer-motion";

const pillars = [
  {
    title: "Attendance",
    copy: "Teachers mark class in the moment. Students see present, late, or absent clearly.",
  },
  {
    title: "Daily feedback",
    copy: "Homework, behavior, and participation arrive as short messages students notice.",
  },
  {
    title: "Progress & payments",
    copy: "Groups and lessons stay visible. Monthly dues reminders stay polite — and stop after payment.",
  },
];

export function CampusSection() {
  const reduce = useReducedMotion();

  return (
    <section id="campus" className="border-y border-line bg-ink text-paper">
      <div className="mx-auto w-full max-w-site px-5 py-24 sm:px-8 sm:py-32">
        <div className="grid gap-10 lg:grid-cols-[1fr_0.85fr] lg:items-end">
          <motion.div
            initial={reduce ? false : { opacity: 0, y: 22 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.65 }}
          >
            <p className="font-display text-xs font-semibold uppercase tracking-[0.24em] text-white/45">( campus. )</p>
            <h2 className="mt-4 font-display text-4xl font-bold tracking-tight sm:text-5xl">
              One system for teachers, staff, and families.
            </h2>
          </motion.div>
          <motion.p
            initial={reduce ? false : { opacity: 0, y: 18 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.08 }}
            className="text-lg text-white/60"
          >
            Built for TechRen branches — roles, classroom timing, and branch isolation stay in the workflow.
            <span className="mt-3 block font-display text-sm font-semibold text-brand-soft">[ N.004 ]</span>
          </motion.p>
        </div>

        <div className="mt-16 grid gap-0 border-t border-white/10 md:grid-cols-3">
          {pillars.map((pillar, index) => (
            <motion.article
              key={pillar.title}
              initial={reduce ? false : { opacity: 0, y: 16 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.08 }}
              className="border-b border-white/10 py-8 md:border-b-0 md:border-r md:px-8 md:py-10 md:first:pl-0 md:last:border-r-0 md:last:pr-0"
            >
              <h3 className="font-display text-xl font-bold">{pillar.title}</h3>
              <p className="mt-3 text-sm leading-relaxed text-white/55">{pillar.copy}</p>
            </motion.article>
          ))}
        </div>
      </div>
    </section>
  );
}
