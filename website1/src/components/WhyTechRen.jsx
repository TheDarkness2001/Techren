import { useEffect, useRef } from 'react';
import { principles } from '../data/content';
import { playWhy } from '../animations/scrollAnimations';

export default function WhyTechRen() {
  const ref = useRef(null);

  useEffect(() => playWhy(ref.current), []);

  return (
    <section className="section" id="why" ref={ref} aria-labelledby="why-title">
      <div className="container">
        <header className="section-head">
          <p className="section-kicker">Why TechRen</p>
          <h2 className="section-heading" id="why-title">
            Education should lead to creation.
          </h2>
          <p className="section-lead">
            Lessons matter. What you can make with them matters more. That is the spine of TechRen.
          </p>
        </header>
        <div className="why-grid">
          {principles.map((item, i) => (
            <article className="why-card" key={item.id}>
              <div className="why-icon" aria-hidden="true">
                <span>0{i + 1}</span>
              </div>
              <h3>{item.title}</h3>
              <p>{item.text}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
