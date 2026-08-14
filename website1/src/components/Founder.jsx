import { useCallback, useEffect, useRef, useState } from 'react';
import { aboutAcademy, aboutCourses } from '../data/content';
import { prefersReducedMotion } from '../animations/utils';

export default function Founder() {
  const sectionRef = useRef(null);
  const canvasRef = useRef(null);
  const sceneRef = useRef(null);
  const [open, setOpen] = useState(false);

  const bootScene = useCallback(() => {
    if (!canvasRef.current || sceneRef.current) return;
    const accent =
      getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#5ce1b8';
    let cancelled = false;
    import('../animations/aboutCubeScene').then(({ createAboutCubeScene }) => {
      if (cancelled || !canvasRef.current || sceneRef.current) return;
      sceneRef.current = createAboutCubeScene(canvasRef.current, {
        color: accent,
        reducedMotion: prefersReducedMotion(),
      });
    });
    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    const root = sectionRef.current;
    if (!root) return undefined;

    let cancelBoot;
    const io = new IntersectionObserver(
      ([entry]) => {
        const on = entry?.isIntersecting === true;
        setOpen(on);
        if (on) cancelBoot = bootScene();
      },
      { threshold: 0.28 },
    );
    io.observe(root);
    return () => {
      io.disconnect();
      cancelBoot?.();
      sceneRef.current?.destroy();
      sceneRef.current = null;
    };
  }, [bootScene]);

  return (
    <section
      className={`section about-section${open ? ' is-open' : ''}`}
      id="about"
      ref={sectionRef}
      aria-labelledby="about-title"
    >
      <div className="about-bg" aria-hidden="true">
        <div className="about-canvas" ref={canvasRef} />
        <div className="about-bg-veil" />
      </div>

      <div className="container about-foreground">
        <div className="about-panel">
          <p className="section-kicker">{aboutAcademy.kicker}</p>
          <h2 id="about-title">{aboutAcademy.title}</h2>
          <p className="about-lead">{aboutAcademy.lead}</p>
          <ul className="about-points">
            {aboutAcademy.points.map((point) => (
              <li key={point}>{point}</li>
            ))}
          </ul>
        </div>

        <div className="about-courses" aria-label="Courses">
          {aboutCourses.map((course) => (
            <a className="about-course" href={course.href} key={course.id}>
              <p className="about-course-kicker">Course</p>
              <h3>{course.title}</h3>
              <p>{course.summary}</p>
              <p className="about-course-topics">{course.topics.join(' · ')}</p>
            </a>
          ))}
        </div>
      </div>
    </section>
  );
}
