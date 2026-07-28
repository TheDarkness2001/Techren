"use client";

import { useEffect, useRef, useState, type ComponentType, type MutableRefObject } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { academyCourses } from "./academyCourses";

gsap.registerPlugin(ScrollTrigger);

type RobotProps = {
  progressRef: MutableRefObject<number>;
  courseIndex: number;
  accent: string;
  reduceMotion?: boolean;
};

export function CoursesShowcase() {
  const sectionRef = useRef<HTMLElement>(null);
  const progressRef = useRef(0);
  const [index, setIndex] = useState(0);
  const [reduceMotion, setReduceMotion] = useState(false);
  const [Robot, setRobot] = useState<ComponentType<RobotProps> | null>(null);
  const [robotReady, setRobotReady] = useState(false);
  const course = academyCourses[index] ?? academyCourses[0];

  useEffect(() => {
    setReduceMotion(window.matchMedia("(prefers-reduced-motion: reduce)").matches);
  }, []);

  // Only load the robot WebGL canvas when Courses is near the viewport
  // (avoids killing the About room canvas with two heavy contexts at once)
  useEffect(() => {
    const section = sectionRef.current;
    if (!section) return;

    const io = new IntersectionObserver(
      ([entry]) => {
        if (entry?.isIntersecting) setRobotReady(true);
      },
      { rootMargin: "200px 0px", threshold: 0.05 }
    );
    io.observe(section);
    return () => io.disconnect();
  }, []);

  useEffect(() => {
    if (!robotReady) return;
    let alive = true;
    void import("./RobotGuide").then((m) => {
      if (alive) setRobot(() => m.RobotGuide);
    });
    return () => {
      alive = false;
    };
  }, [robotReady]);

  useEffect(() => {
    const section = sectionRef.current;
    if (!section) return;

    const mobile = window.matchMedia("(max-width: 768px)").matches;
    const perCourse = mobile ? window.innerHeight * 0.38 : window.innerHeight * 0.42;
    const endDistance = Math.max(academyCourses.length * perCourse, window.innerHeight * 1.2);

    let lastIndex = -1;
    const st = ScrollTrigger.create({
      trigger: section,
      start: "top top",
      end: `+=${endDistance}`,
      pin: true,
      scrub: 0.35,
      anticipatePin: 1,
      fastScrollEnd: true,
      onUpdate: (self) => {
        progressRef.current = self.progress;
        const next = Math.min(
          academyCourses.length - 1,
          Math.floor(self.progress * academyCourses.length)
        );
        if (next !== lastIndex) {
          lastIndex = next;
          setIndex(next);
        }
      },
    });

    const refresh = () => ScrollTrigger.refresh();
    requestAnimationFrame(refresh);
    const t = window.setTimeout(refresh, 500);

    return () => {
      window.clearTimeout(t);
      st.kill();
    };
  }, []);

  return (
    <section
      ref={sectionRef}
      id="courses"
      className="relative z-10 border-y border-line bg-[#050816]"
    >
      <div className="mx-auto grid h-[100svh] min-h-[640px] max-w-site grid-rows-[minmax(280px,42vh)_1fr] gap-4 px-5 py-16 sm:px-8 lg:grid-cols-[minmax(280px,1fr)_minmax(280px,1.05fr)] lg:grid-rows-1 lg:items-center lg:gap-12 lg:py-12">
        <div
          className="relative h-full min-h-[280px] overflow-hidden rounded-[2rem] border border-line transition-[box-shadow,border-color] duration-500 lg:min-h-[min(70vh,620px)]"
          style={{
            borderColor: `${course.color}55`,
            boxShadow: `0 0 0 1px ${course.color}22, 0 20px 60px ${course.soft}`,
          }}
        >
          {Robot ? (
            <Robot
              progressRef={progressRef}
              courseIndex={index}
              accent={course.color}
              reduceMotion={reduceMotion}
            />
          ) : (
            <div className="grid h-full min-h-[280px] place-items-center bg-[#070b1c]">
              <p className="text-sm text-white/45">Loading robot…</p>
            </div>
          )}
          <div className="pointer-events-none absolute inset-x-0 bottom-0 bg-gradient-to-t from-[#050816] via-[#050816]/40 to-transparent px-5 pb-4 pt-12">
            <p className="text-xs uppercase tracking-[0.2em]" style={{ color: course.color }}>
              Scroll to explore
            </p>
          </div>
        </div>

        <div className="flex flex-col justify-center">
          <p className="section-label">TechRen Academy</p>
          <h2 className="mt-3 font-display text-3xl font-bold sm:text-4xl lg:text-5xl">What we teach.</h2>

          <div
            key={course.id}
            className="course-reveal mt-6 rounded-3xl border p-5 sm:p-6"
            style={{
              borderColor: `${course.color}40`,
              background: `linear-gradient(145deg, ${course.soft}, transparent 70%)`,
            }}
          >
            <div className="flex flex-wrap items-center gap-3">
              <span className="font-display text-sm font-bold" style={{ color: course.color }}>
                {String(index + 1).padStart(2, "0")} / {String(academyCourses.length).padStart(2, "0")}
              </span>
              <span
                className="rounded-full px-3 py-1 text-xs font-medium"
                style={{ background: course.soft, color: course.color, border: `1px solid ${course.color}55` }}
              >
                {course.level}
              </span>
            </div>
            <h3
              className="mt-4 font-display text-[clamp(2rem,5vw,3.1rem)] font-extrabold tracking-tight"
              style={{ color: course.color }}
            >
              {course.title}
            </h3>
            <p className="mt-3 text-base leading-relaxed text-white/75 sm:text-lg">{course.blurb}</p>
          </div>

          <div className="mt-6 flex flex-wrap gap-1.5" aria-hidden>
            {academyCourses.map((c, i) => (
              <span
                key={c.id}
                className="h-2 rounded-full transition-all duration-300"
                style={{
                  width: i === index ? 28 : 10,
                  background: i === index ? c.color : i < index ? `${c.color}88` : "rgba(255,255,255,0.12)",
                }}
              />
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
