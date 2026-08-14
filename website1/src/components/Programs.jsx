import { useEffect, useRef } from 'react';
import { programmingPath } from '../data/content';
import { playGeneric } from '../animations/scrollAnimations';

export default function Programs() {
  const ref = useRef(null);

  useEffect(() => playGeneric(ref.current, '.program-panel, .program-step'), []);

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

        <ol className="program-path">
          {programmingPath.map((step, i) => (
            <li className="program-step" key={step.name}>
              <p className="program-step-index">{String(i + 1).padStart(2, '0')}</p>
              <div>
                <p className="program-step-level">{step.level}</p>
                <h3>{step.name}</h3>
                <p>{step.desc}</p>
                <p className="program-step-build">Build: {step.build}</p>
              </div>
            </li>
          ))}
        </ol>
      </div>
    </section>
  );
}
