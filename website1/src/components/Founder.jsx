import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { aboutAcademy, aboutCourses } from '../data/content';
import { prefersReducedMotion } from '../animations/utils';

export default function Founder() {
  const sectionRef = useRef(null);
  const canvasRef = useRef(null);
  const sceneRef = useRef(null);
  const indexRef = useRef(0);
  const slidesLenRef = useRef(4);

  const [inView, setInView] = useState(false);
  const [panelOpen, setPanelOpen] = useState(false);
  const [slideIndex, setSlideIndex] = useState(0);

  const slides = useMemo(
    () => [
      {
        id: 'academy',
        kind: 'academy',
        kicker: aboutAcademy.kicker,
        title: aboutAcademy.title,
        lead: aboutAcademy.lead,
        points: aboutAcademy.points,
      },
      ...aboutCourses.map((course) => ({
        id: course.id,
        kind: 'course',
        kicker: 'Course',
        title: course.title,
        lead: course.summary,
        topics: course.topics,
        href: course.href,
      })),
    ],
    [],
  );

  slidesLenRef.current = slides.length;
  const slide = slides[slideIndex] ?? slides[0];

  const onPhaseRef = useRef(() => {});
  onPhaseRef.current = (phase) => {
    if (phase === 'open') {
      setPanelOpen(true);
      return;
    }
    if (phase === 'close') {
      setPanelOpen(false);
      return;
    }
    if (phase === 'advance') {
      indexRef.current = (indexRef.current + 1) % slidesLenRef.current;
      setSlideIndex(indexRef.current);
    }
  };

  const bootScene = useCallback(() => {
    if (!canvasRef.current || sceneRef.current) return undefined;
    const accent =
      getComputedStyle(document.documentElement).getPropertyValue('--accent').trim() || '#5ce1b8';
    let cancelled = false;
    import('../animations/aboutCubeScene').then(({ createAboutCubeScene }) => {
      if (cancelled || !canvasRef.current || sceneRef.current) return;
      sceneRef.current = createAboutCubeScene(canvasRef.current, {
        color: accent,
        reducedMotion: prefersReducedMotion(),
        onPhase: (phase) => onPhaseRef.current(phase),
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
        setInView(on);
        if (on) {
          cancelBoot = bootScene();
        } else {
          setPanelOpen(false);
        }
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
      className={`section about-section${inView ? ' is-inview' : ''}${panelOpen ? ' is-open' : ''}`}
      id="about"
      ref={sectionRef}
      aria-labelledby="about-title"
    >
      <div className="about-bg" aria-hidden="true">
        <div className="about-canvas" ref={canvasRef} />
        <div className="about-bg-veil" />
      </div>

      <div className="container about-foreground" aria-hidden={!panelOpen}>
        <div className="about-panel" key={slide.id}>
          <p className="section-kicker">{slide.kicker}</p>
          <h2 id="about-title">{slide.title}</h2>
          <p className="about-lead">{slide.lead}</p>

          {slide.kind === 'academy' ? (
            <ul className="about-points">
              {slide.points.map((point) => (
                <li key={point}>{point}</li>
              ))}
            </ul>
          ) : (
            <>
              <p className="about-course-topics">{slide.topics.join(' · ')}</p>
              <a className="about-course-link" href={slide.href}>
                Explore {slide.title}
              </a>
            </>
          )}
        </div>

        <div className="about-slide-dots" role="tablist" aria-label="About slides">
          {slides.map((item, i) => (
            <button
              key={item.id}
              type="button"
              role="tab"
              aria-selected={i === slideIndex}
              className={i === slideIndex ? 'is-active' : undefined}
              onClick={() => {
                indexRef.current = i;
                setSlideIndex(i);
                setPanelOpen(true);
              }}
            >
              <span className="sr-only">{item.title}</span>
            </button>
          ))}
        </div>
      </div>
    </section>
  );
}
