import { useEffect, useRef } from 'react';
import { stats } from '../data/content';
import { playStats } from '../animations/scrollAnimations';

export default function Statistics() {
  const ref = useRef(null);

  useEffect(() => playStats(ref.current), []);

  return (
    <section className="section" ref={ref} aria-labelledby="stats-title">
      <div className="container">
        <header className="section-head">
          <p className="section-kicker">At a glance</p>
          <h2 className="section-heading" id="stats-title">
            The work, measured later.
          </h2>
          <p className="section-lead">
            Real figures belong here when they are ready. The structure is in place — nothing invented.
          </p>
        </header>
        <div className="stats-row">
          {stats.map((stat) => (
            <article className="stat" key={stat.key}>
              {stat.value == null ? (
                <p className="stat-value">{stat.placeholder}</p>
              ) : (
                <p className="stat-value" data-count={stat.value}>
                  0
                </p>
              )}
              <p className="stat-label">{stat.label}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
