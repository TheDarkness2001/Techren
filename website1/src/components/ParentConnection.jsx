import { useEffect, useRef } from 'react';
import { parentCards } from '../data/content';
import { playParents } from '../animations/scrollAnimations';

export default function ParentConnection() {
  const ref = useRef(null);

  useEffect(() => playParents(ref.current), []);

  return (
    <section className="section parents" ref={ref} aria-labelledby="parents-title">
      <div className="container">
        <div className="parent-intro">
          <header>
            <p className="section-kicker">For parents</p>
            <h2 className="section-heading" id="parents-title">
              Stay connected to their progress.
            </h2>
          </header>
          <div className="parent-questions">
            <p>Did they attend?</p>
            <p>Did they finish the homework?</p>
            <p>How are they progressing?</p>
            <p style={{ marginTop: '1rem' }}>
              Traditional education often leaves those questions hanging. TechRen is built so parents are not guessing.
            </p>
          </div>
        </div>
        <div className="parent-grid">
          {parentCards.map((card) => (
            <article className="parent-card" key={card.title}>
              <span className="check" aria-hidden="true">
                ✓
              </span>
              <h3>{card.title}</h3>
              <p>{card.text}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
