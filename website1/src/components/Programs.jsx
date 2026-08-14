import { useEffect, useRef } from 'react';
import { playGeneric } from '../animations/scrollAnimations';

export default function Programs() {
  const ref = useRef(null);

  useEffect(() => playGeneric(ref.current, '.program-panel'), []);

  return (
    <section className="section" id="programs" ref={ref} aria-labelledby="programs-title">
      <div className="container">
        <header className="section-head">
          <p className="section-kicker">Programs</p>
          <h2 className="section-heading" id="programs-title">
            Two paths. One standard: make something real.
          </h2>
          <p className="section-lead">
            Programming and English sit side by side. Both are taught as skills you use, not subjects you only pass.
          </p>
        </header>
        <div className="program-split">
          <a className="program-panel" href="#programming">
            <div>
              <p className="section-kicker">01</p>
              <h3>Programming</h3>
              <p>HTML to React, Python to hardware. Students learn by shipping projects.</p>
            </div>
            <span className="text-link">
              <span>See the path</span> →
            </span>
          </a>
          <a className="program-panel" href="#english">
            <div>
              <p className="section-kicker">02</p>
              <h3>English</h3>
              <p>Speaking, listening, reading, writing — language as a tool for work and study.</p>
            </div>
            <span className="text-link">
              <span>See the path</span> →
            </span>
          </a>
        </div>
      </div>
    </section>
  );
}
