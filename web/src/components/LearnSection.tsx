"use client";

import { motion, useReducedMotion } from "framer-motion";

const tracks = [
  {
    no: "01",
    title: "Words",
    copy: "Build vocabulary with guided practice and live accuracy on the leaderboard.",
  },
  {
    no: "02",
    title: "Sentences",
    copy: "Train structure and meaning — attempts, correct answers, and clear percentages.",
  },
  {
    no: "03",
    title: "Listening",
    copy: "Hear real audio unlocked for your group, then climb by best accuracy.",
  },
];

export function LearnSection() {
  const reduce = useReducedMotion();

  return (
    <section id="learn" className="mx-auto w-full max-w-site px-5 py-24 sm:px-8 sm:py-32">
      <div className="flex flex-wrap items-end justify-between gap-6">
        <motion.div
          initial={reduce ? false : { opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="max-w-2xl"
        >
          <p className="font-display text-xs font-semibold uppercase tracking-[0.24em] text-ink-mute">( learn. )</p>
          <h2 className="mt-4 font-display text-4xl font-bold tracking-tight text-ink sm:text-5xl">
            Practice that feels like the classroom.
          </h2>
        </motion.div>
        <p className="font-display text-sm font-semibold text-brand">[ N.003 ]</p>
      </div>

      <ul className="mt-16">
        {tracks.map((track, index) => (
          <motion.li
            key={track.title}
            initial={reduce ? false : { opacity: 0, y: 18 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, amount: 0.45 }}
            transition={{ duration: 0.5, delay: index * 0.06 }}
            className="group grid gap-4 border-t border-line py-8 sm:grid-cols-[4.5rem_minmax(0,1fr)_auto] sm:items-baseline sm:gap-10"
          >
            <span className="font-display text-sm font-semibold text-ink-mute">{track.no}</span>
            <div>
              <h3 className="font-display text-3xl font-bold tracking-tight text-ink transition group-hover:text-brand sm:text-4xl">
                / {track.title.toLowerCase()}
              </h3>
              <p className="mt-3 max-w-2xl text-ink-mute">{track.copy}</p>
            </div>
            <span className="hidden font-display text-sm text-ink-mute sm:block">→</span>
          </motion.li>
        ))}
      </ul>
    </section>
  );
}
