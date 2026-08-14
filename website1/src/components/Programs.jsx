import { useEffect, useRef } from 'react';
import { programmingPath } from '../data/content';
import { playGeneric } from '../animations/scrollAnimations';
import { startProgramLayout } from '../animations/programLayout';

export default function Programs() {
  const ref = useRef(null);

  useEffect(() => {
    const cleanReveal = playGeneric(ref.current, '.program-panel, .program-layout');
    const cleanLayout = startProgramLayout(ref.current);
    return () => {
      cleanReveal();
      cleanLayout();
    };
  }, []);

  return (
    <section className="section" id="programming" ref={ref} aria-labelledby="programming-title">
      <div className="container">
        <header className="section-head">
          <p className="section-kicker">01 / Programming</p>
          <h2 className="section-heading" id="programming-title">
            Learn to build.
          </h2>
          <p className="section-lead">A path, not a pile of topics — fundamentals to real applications.</p>
        </header>

        <div className="program-split">
          <a className="program-panel" href="#english">
            <div>
              <p className="section-kicker">Also</p>
              <h3>English</h3>
              <p>Speaking, listening, reading, writing — language as a tool for work and study.</p>
            </div>
            <span className="text-link">
              <span>See English</span> →
            </span>
          </a>
          <a className="program-panel" href="#about">
            <div>
              <p className="section-kicker">Academy</p>
              <h3>About TechRen</h3>
              <p>How the academy works, and what students actually learn.</p>
            </div>
            <span className="text-link">
              <span>About</span> →
            </span>
          </a>
        </div>

        <div className="program-layout" data-program-layout data-grid="1">
          <div className="program-layout-chrome">
            <p className="program-layout-title">Layout</p>
            <button type="button" className="program-layout-replay" data-layout-replay aria-label="Replay layout animation">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" aria-hidden="true">
                <path d="M4 12a8 8 0 0113.66-5.66M20 12a8 8 0 01-13.66 5.66" strokeLinecap="round" />
                <path d="M18 4v4h-4M6 20v-4h4" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </button>
          </div>

          <ol className="program-layout-grid">
            {programmingPath.map((step, i) => (
              <li
                className="program-layout-item"
                key={step.name}
                data-layout-id={step.name.toLowerCase()}
                style={{ '--i': i }}
              >
                <p className="program-step-meta">
                  <span>{String(i + 1).padStart(2, '0')}</span>
                  <span>{step.level}</span>
                </p>
                <h3>{step.name}</h3>
                <p className="program-step-desc">{step.desc}</p>
                <p className="program-step-build">Build: {step.build}</p>
              </li>
            ))}
          </ol>
        </div>
      </div>
    </section>
  );
}
