"use client";

import { useEffect } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import SplitType from "split-type";
import { DownloadPanel } from "./DownloadPanel";
import { MagneticButton } from "./MagneticButton";
import { ParallaxHeroBackground } from "./ParallaxHeroBackground";
import { SiteNav } from "./SiteNav";

gsap.registerPlugin(ScrollTrigger);

const features = [
  { title: "Words", copy: "Vocabulary practice with live accuracy and leaderboards." },
  { title: "Sentences", copy: "Structure drills with attempts, correct counts, and %." },
  { title: "Listening", copy: "Audio exercises unlocked by group — climb by best score." },
  { title: "Attendance", copy: "Mark class in the moment. Students get clear status updates." },
  { title: "Daily feedback", copy: "Homework, behavior, participation as short messages." },
  { title: "Progress", copy: "Teachers see groups and lessons. Payments stay visible." },
];

const stats = [
  { value: 98, suffix: "%", label: "Session clarity" },
  { value: 12, suffix: "k+", label: "Practice attempts" },
  { value: 4, suffix: "×", label: "Faster check-in" },
  { value: 24, suffix: "/7", label: "Always on" },
];

const courses = [
  { tag: "01", title: "Foundations", meta: "Words · A1–A2" },
  { tag: "02", title: "Fluency Path", meta: "Sentences · B1" },
  { tag: "03", title: "Ear Training", meta: "Listening labs" },
  { tag: "04", title: "Exam Ready", meta: "Progress gates" },
  { tag: "05", title: "Staff Ops", meta: "Attendance + feedback" },
];

const quotes = [
  {
    name: "Mukarram",
    role: "Student",
    text: "The leaderboard made practice feel alive — I always know where I stand.",
  },
  {
    name: "Sobirjon",
    role: "Teacher",
    text: "Attendance and feedback in one flow. Class time stays with the students.",
  },
  {
    name: "Mubina",
    role: "Student",
    text: "Listening unlocked for my group. Updates feel like Telegram — hard to miss.",
  },
];

const faqs = [
  {
    q: "Is this a website app or a real install?",
    a: "Native apps for Android, Windows, and Mac. Install once — later tap Update in-app.",
  },
  {
    q: "Who can use TechRen EDU?",
    a: "Students, teachers, and staff at TechRen education centers with school accounts.",
  },
  {
    q: "Does it work offline?",
    a: "You need a connection for sync, leaderboards, and updates. Core practice flows stay fast once loaded.",
  },
  {
    q: "How do payments reminders work?",
    a: "From the 1st–10th, unpaid students get polite reminders. They stop after the month is paid.",
  },
];

export function CinematicLanding() {
  useEffect(() => {
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    const mobile = window.matchMedia("(max-width: 768px)").matches;
    const ctx = gsap.context(() => {
      // Hero text reveal
      const heroTitle = document.querySelector(".hero-title");
      if (heroTitle) {
        const split = new SplitType(heroTitle as HTMLElement, { types: "chars,words" });
        gsap.from(split.chars, {
          yPercent: 120,
          opacity: 0,
          rotateX: -40,
          stagger: 0.02,
          duration: 1.05,
          ease: "power3.out",
          delay: 0.15,
        });
      }

      gsap.from(".hero-sub", {
        y: 28,
        opacity: 0,
        filter: "blur(10px)",
        duration: 1,
        delay: 0.45,
        ease: "power3.out",
      });
      gsap.from(".hero-cta", {
        y: 20,
        opacity: 0,
        duration: 0.8,
        delay: 0.7,
        stagger: 0.1,
        ease: "power2.out",
      });
      gsap.from(".hero-glass", {
        y: 40,
        opacity: 0,
        scale: 0.94,
        duration: 1,
        delay: 0.55,
        ease: "power3.out",
      });

      if (!reduce) {
        // Multi-layer scroll parallax in hero
        const speeds: Record<string, number> = {
          ".plx-cloud": 40,
          ".plx-far-mountains": 90,
          ".plx-near-mountains": 150,
          ".plx-trees": 230,
          ".plx-fog": 120,
          ".plx-foreground": 280,
        };
        Object.entries(speeds).forEach(([sel, y]) => {
          gsap.to(sel, {
            y,
            ease: "none",
            scrollTrigger: {
              trigger: "#hero",
              start: "top top",
              end: "bottom top",
              scrub: true,
            },
          });
        });

        gsap.to(".hero-content", {
          opacity: 0,
          y: -60,
          filter: "blur(8px)",
          ease: "none",
          scrollTrigger: {
            trigger: "#hero",
            start: "center top",
            end: "bottom top",
            scrub: true,
          },
        });
      }

      // Generic section fades
      gsap.utils.toArray<HTMLElement>(".fade-section").forEach((section) => {
        gsap.from(section.querySelectorAll(".fade-up"), {
          y: 48,
          opacity: 0,
          filter: "blur(8px)",
          duration: 0.9,
          stagger: 0.08,
          ease: "power3.out",
          scrollTrigger: {
            trigger: section,
            start: "top 75%",
          },
        });
      });

      // Feature cards stagger
      gsap.from(".feature-card", {
        y: 60,
        opacity: 0,
        scale: 0.92,
        rotate: 1.5,
        stagger: 0.1,
        duration: 0.85,
        ease: "power3.out",
        scrollTrigger: { trigger: "#features", start: "top 70%" },
      });

      // Stats count-up + pin
      const statSection = document.querySelector("#statistics");
      if (statSection) {
        ScrollTrigger.create({
          trigger: statSection,
          start: "top top",
          end: mobile ? "+=40%" : "+=80%",
          pin: !mobile,
          pinSpacing: true,
        });

        document.querySelectorAll<HTMLElement>(".stat-num").forEach((el) => {
          const target = Number(el.dataset.value || "0");
          const obj = { n: 0 };
          gsap.to(obj, {
            n: target,
            duration: 1.6,
            ease: "power2.out",
            scrollTrigger: { trigger: el, start: "top 80%" },
            onUpdate: () => {
              el.textContent = Math.floor(obj.n).toString();
            },
          });
        });
      }

      // Horizontal courses
      const track = document.querySelector<HTMLElement>(".horizontal-track");
      const hSection = document.querySelector("#courses");
      if (track && hSection && !mobile) {
        const total = track.scrollWidth - window.innerWidth + 80;
        gsap.to(track, {
          x: () => -Math.max(total, 0),
          ease: "none",
          scrollTrigger: {
            trigger: hSection,
            start: "top top",
            end: () => `+=${Math.max(total, 400)}`,
            scrub: 1,
            pin: true,
            anticipatePin: 1,
          },
        });
      } else if (track) {
        gsap.from(".course-card", {
          y: 40,
          opacity: 0,
          stagger: 0.1,
          scrollTrigger: { trigger: "#courses", start: "top 75%" },
        });
      }

      // Testimonials
      gsap.from(".quote-card", {
        y: 50,
        opacity: 0,
        rotateY: 8,
        stagger: 0.12,
        duration: 0.9,
        ease: "power3.out",
        scrollTrigger: { trigger: "#testimonials", start: "top 70%" },
      });

      // Gallery clip reveals
      gsap.utils.toArray<HTMLElement>(".gallery-tile").forEach((tile, i) => {
        gsap.fromTo(
          tile,
          { clipPath: "inset(100% 0 0 0)", scale: 1.08 },
          {
            clipPath: "inset(0% 0 0 0)",
            scale: 1,
            duration: 1.1,
            ease: "power3.out",
            delay: i * 0.05,
            scrollTrigger: { trigger: tile, start: "top 85%" },
          }
        );
      });

      // FAQ accordion-ish reveal
      gsap.from(".faq-item", {
        x: -30,
        opacity: 0,
        stagger: 0.1,
        duration: 0.7,
        scrollTrigger: { trigger: "#faq", start: "top 75%" },
      });

      // Download cards
      gsap.from(".reveal-card", {
        y: 40,
        opacity: 0,
        scale: 0.96,
        stagger: 0.08,
        duration: 0.75,
        scrollTrigger: { trigger: "#download", start: "top 75%" },
      });

      // Background color storytelling
      gsap.to("body", {
        backgroundColor: "#070b1c",
        scrollTrigger: {
          trigger: "#features",
          start: "top center",
          end: "bottom center",
          scrub: true,
        },
      });
      gsap.to("body", {
        backgroundColor: "#050816",
        scrollTrigger: {
          trigger: "#contact",
          start: "top center",
          scrub: true,
        },
      });
    });

    return () => ctx.revert();
  }, []);

  return (
    <>
      <SiteNav />
      <main>
        {/* HERO */}
        <section id="hero" className="relative min-h-[100svh] overflow-hidden">
          <ParallaxHeroBackground />
          <div className="hero-content relative z-10 mx-auto flex min-h-[100svh] max-w-site flex-col justify-end px-5 pb-16 pt-28 sm:px-8 sm:pb-20">
            <p className="section-label mb-4">Education center platform</p>
            <h1 className="hero-title font-display text-[clamp(3.2rem,11vw,7.2rem)] font-extrabold leading-[0.9] tracking-[-0.045em]">
              <span className="word-mask">TechRen</span>{" "}
              <span className="gradient-text">EDU</span>
            </h1>
            <p className="hero-sub mt-6 max-w-xl text-lg text-white/65 sm:text-xl">
              Cinematic learning for a modern school — practice, attendance, feedback, and progress in one native app.
            </p>
            <div className="mt-10 flex flex-wrap items-center gap-4">
              <div className="hero-cta">
                <MagneticButton href="#download">Download the app</MagneticButton>
              </div>
              <a
                href="#about"
                className="hero-cta cursor-grow rounded-full border border-line px-6 py-3.5 text-sm font-semibold text-white/80 transition hover:border-white/35 hover:text-white"
              >
                Explore the story
              </a>
            </div>

            <div className="hero-glass glass mt-12 max-w-md rounded-3xl p-5 sm:p-6">
              <p className="text-xs uppercase tracking-[0.22em] text-secondary">Live campus signal</p>
              <p className="mt-3 font-display text-xl font-bold">Words · Sentences · Listening</p>
              <p className="mt-2 text-sm text-white/55">
                Built for TechRen branches — not a generic LMS template.
              </p>
            </div>
          </div>
        </section>

        {/* ABOUT */}
        <section id="about" className="fade-section relative mx-auto max-w-site px-5 py-28 sm:px-8 sm:py-36">
          <p className="fade-up section-label">About</p>
          <h2 className="fade-up mt-4 max-w-4xl font-display text-4xl font-bold tracking-tight sm:text-6xl">
            In class and in code, we keep only what helps students grow.
          </h2>
          <p className="fade-up mt-8 max-w-2xl text-lg text-white/60">
            TechRen EDU is the operating system of our education center. Students practice. Teachers teach. Staff see
            the truth of the day — attendance, feedback, and dues — without noise.
          </p>
        </section>

        {/* FEATURES */}
        <section id="features" className="relative border-y border-line bg-white/[0.02] py-28 sm:py-36">
          <div className="mx-auto max-w-site px-5 sm:px-8">
            <p className="section-label">Features</p>
            <h2 className="mt-4 font-display text-4xl font-bold sm:text-5xl">Everything the campus needs.</h2>
            <div className="mt-14 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
              {features.map((f) => (
                <article
                  key={f.title}
                  className="feature-card glass cursor-grow rounded-3xl p-6 transition hover:-translate-y-1 hover:border-white/30 hover:shadow-glow"
                >
                  <div className="mb-4 h-10 w-10 rounded-2xl bg-gradient-to-br from-primary to-secondary opacity-90" />
                  <h3 className="font-display text-xl font-bold">{f.title}</h3>
                  <p className="mt-2 text-sm text-white/55">{f.copy}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        {/* STATISTICS */}
        <section id="statistics" className="pin-panel relative flex items-center py-24">
          <div className="mx-auto grid w-full max-w-site gap-10 px-5 sm:grid-cols-2 sm:px-8 lg:grid-cols-4">
            {stats.map((s) => (
              <div key={s.label} className="glass rounded-3xl p-6 text-center sm:text-left">
                <p className="font-display text-5xl font-extrabold tracking-tight">
                  <span className="stat-num gradient-text" data-value={s.value}>
                    0
                  </span>
                  <span className="text-secondary">{s.suffix}</span>
                </p>
                <p className="mt-3 text-sm uppercase tracking-[0.18em] text-white/45">{s.label}</p>
              </div>
            ))}
          </div>
        </section>

        {/* COURSES — horizontal */}
        <section id="courses" className="relative overflow-hidden py-24 sm:py-0">
          <div className="mb-10 px-5 sm:absolute sm:left-8 sm:top-16 sm:mb-0 sm:px-0">
            <p className="section-label">Courses</p>
            <h2 className="mt-3 font-display text-4xl font-bold">Learning paths that scroll like film.</h2>
          </div>
          <div className="horizontal-track px-5 pb-16 pt-8 sm:px-8 sm:pb-24 sm:pt-48">
            {courses.map((c) => (
              <article
                key={c.tag}
                className="course-card glass flex h-[22rem] w-[18rem] shrink-0 flex-col justify-between rounded-[2rem] p-7 sm:h-[26rem] sm:w-[22rem]"
              >
                <span className="font-display text-sm text-secondary">{c.tag}</span>
                <div>
                  <h3 className="font-display text-3xl font-bold">{c.title}</h3>
                  <p className="mt-3 text-white/55">{c.meta}</p>
                </div>
              </article>
            ))}
          </div>
        </section>

        {/* TESTIMONIALS */}
        <section id="testimonials" className="mx-auto max-w-site px-5 py-28 sm:px-8 sm:py-36">
          <p className="section-label">Testimonials</p>
          <h2 className="mt-4 font-display text-4xl font-bold sm:text-5xl">Voices from the center.</h2>
          <div className="mt-14 grid gap-5 lg:grid-cols-3">
            {quotes.map((q) => (
              <blockquote key={q.name} className="quote-card glass rounded-3xl p-6">
                <p className="text-lg leading-relaxed text-white/80">&ldquo;{q.text}&rdquo;</p>
                <footer className="mt-6 text-sm text-white/45">
                  <span className="font-semibold text-white">{q.name}</span> · {q.role}
                </footer>
              </blockquote>
            ))}
          </div>
        </section>

        {/* GALLERY */}
        <section id="gallery" className="border-y border-line py-28 sm:py-36">
          <div className="mx-auto max-w-site px-5 sm:px-8">
            <p className="section-label">Gallery</p>
            <h2 className="mt-4 font-display text-4xl font-bold">Moments of motion.</h2>
            <div className="mt-12 grid gap-4 md:grid-cols-3">
              {[
                "from-[#6C63FF] to-[#00D4FF]",
                "from-[#7C3AED] to-[#6C63FF]",
                "from-[#00D4FF] to-[#050816]",
                "from-[#1a1440] to-[#6C63FF]",
                "from-[#0b3a4a] to-[#00D4FF]",
                "from-[#2a1050] to-[#7C3AED]",
              ].map((g, i) => (
                <div
                  key={g}
                  className={`gallery-tile cursor-grow min-h-[14rem] rounded-[1.75rem] bg-gradient-to-br ${g} ${
                    i === 0 || i === 5 ? "md:col-span-2" : ""
                  }`}
                />
              ))}
            </div>
          </div>
        </section>

        {/* FAQ */}
        <section id="faq" className="mx-auto max-w-3xl px-5 py-28 sm:px-8 sm:py-36">
          <p className="section-label">FAQ</p>
          <h2 className="mt-4 font-display text-4xl font-bold">Answers, without the noise.</h2>
          <div className="mt-12 space-y-3">
            {faqs.map((item) => (
              <details key={item.q} className="faq-item glass group rounded-2xl px-5 py-4">
                <summary className="cursor-grow list-none font-display text-lg font-semibold marker:content-none">
                  {item.q}
                </summary>
                <p className="mt-3 text-sm leading-relaxed text-white/55">{item.a}</p>
              </details>
            ))}
          </div>
        </section>

        {/* DOWNLOAD */}
        <section id="download" className="border-y border-line bg-white/[0.02] py-28 sm:py-36">
          <div className="mx-auto max-w-site px-5 sm:px-8">
            <p className="section-label">Download</p>
            <h2 className="mt-4 font-display text-4xl font-bold sm:text-5xl">Get TechRen EDU</h2>
            <div className="mt-10">
              <DownloadPanel />
            </div>
          </div>
        </section>

        {/* CONTACT */}
        <section id="contact" className="fade-section mx-auto max-w-site px-5 py-28 sm:px-8 sm:py-36">
          <p className="fade-up section-label">Contact</p>
          <h2 className="fade-up mt-4 font-display text-4xl font-bold sm:text-5xl">Talk to your administrator.</h2>
          <p className="fade-up mt-6 max-w-xl text-white/60">
            Need an account, a branch invite, or install help? Reach your school admin — TechRen EDU is provisioned per
            center.
          </p>
          <div className="fade-up mt-10">
            <MagneticButton href="#download">Install now</MagneticButton>
          </div>
        </section>
      </main>

      <footer className="border-t border-line">
        <div className="mx-auto flex max-w-site flex-col gap-4 px-5 py-10 sm:flex-row sm:items-center sm:justify-between sm:px-8">
          <p className="font-display text-lg font-bold">TechRen EDU</p>
          <p className="text-sm text-white/40">Premium education platform · Built for the center.</p>
        </div>
      </footer>
    </>
  );
}
