import { useEffect, useRef } from 'react';
import { dayTimeline } from '../data/content';
import { playTimeline } from '../animations/scrollAnimations';

export default function Timeline() {
  const ref = useRef(null);

  useEffect(() => playTimeline(ref.current), []);

  return (
    <section className="section" ref={ref} aria-labelledby="day-title">
      <div className="container day-layout">
        <header>
          <p className="section-kicker">Rhythm</p>
          <h2 className="section-heading" id="day-title">
            A day at TechRen.
          </h2>
          <p className="section-lead">
            Learning, practice, projects, feedback — then homework and progress that stay visible.
          </p>
        </header>
        <div className="day-track">
          <div className="day-line" aria-hidden="true">
            <div className="day-line-fill" />
          </div>
          {dayTimeline.map((item) => (
            <article className="day-item" key={item.title}>
              <p className="day-time">{item.time}</p>
              <h3>{item.title}</h3>
              <p>{item.text}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
