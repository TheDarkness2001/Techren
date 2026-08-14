import { useCallback, useEffect, useRef, useState } from 'react';
import { aboutTopics } from '../data/content';
import { prefersReducedMotion } from '../animations/utils';

const CYCLE_MS = 5200;

function TopicIcon({ path, label }) {
  return (
    <li className="about-icon" title={label}>
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" aria-hidden="true">
        <path d={path} strokeLinecap="round" strokeLinejoin="round" />
      </svg>
      <span>{label}</span>
    </li>
  );
}

export default function Founder() {
  const sectionRef = useRef(null);
  const canvasRef = useRef(null);
  const sceneRef = useRef(null);
  const [index, setIndex] = useState(0);
  const [visible, setVisible] = useState(false);

  const topic = aboutTopics[index];

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
        setVisible(on);
        if (on) cancelBoot = bootScene();
      },
      { threshold: 0.2 },
    );
    io.observe(root);
    return () => {
      io.disconnect();
      cancelBoot?.();
      sceneRef.current?.destroy();
      sceneRef.current = null;
    };
  }, [bootScene]);

  useEffect(() => {
    if (!visible || prefersReducedMotion() || aboutTopics.length < 2) return undefined;
    const id = window.setInterval(() => {
      setIndex((i) => (i + 1) % aboutTopics.length);
    }, CYCLE_MS);
    return () => window.clearInterval(id);
  }, [visible]);

  const replay = () => {
    sceneRef.current?.replay();
  };

  const selectTopic = (i) => {
    setIndex(i);
    sceneRef.current?.replay();
  };

  return (
    <section className="section about-section" id="about" ref={sectionRef} aria-labelledby="about-title">
      <div className="container about-layout">
        <div className="about-stage">
          <div className="about-stage-chrome">
            <div className="about-stage-heading">
              <p className="about-topic" id="about-title" key={topic.id}>
                {topic.topic}
              </p>
              <span className="about-pill">{topic.badge}</span>
            </div>
            <div className="about-stage-actions">
              <button type="button" className="about-icon-btn" onClick={replay} aria-label="Replay animation">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" aria-hidden="true">
                  <path d="M4 12a8 8 0 0113.66-5.66M20 12a8 8 0 01-13.66 5.66" strokeLinecap="round" />
                  <path d="M18 4v4h-4M6 20v-4h4" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </button>
            </div>
          </div>
          <div className="about-canvas" ref={canvasRef} />
        </div>

        <div className="about-copy">
          <p className="section-kicker">About TechRen</p>
          <p className="about-intro" key={`intro-${topic.id}`}>
            {topic.intro}
          </p>
          <ul className="about-icons" key={`icons-${topic.id}`}>
            {topic.icons.map((icon) => (
              <TopicIcon key={icon.label} path={icon.path} label={icon.label} />
            ))}
          </ul>
          <p className="about-subject" key={`subject-${topic.id}`}>
            {topic.subject}
          </p>
          <div className="about-dots" role="tablist" aria-label="About topics">
            {aboutTopics.map((item, i) => (
              <button
                key={item.id}
                type="button"
                role="tab"
                aria-selected={i === index}
                className={i === index ? 'is-active' : undefined}
                onClick={() => selectTopic(i)}
              >
                <span className="sr-only">{item.topic}</span>
              </button>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
