import { useEffect, useRef, useState } from 'react';
import { testimonials } from '../data/content';
import { playGeneric } from '../animations/scrollAnimations';

export default function Testimonials() {
  const ref = useRef(null);
  const track = useRef(null);
  const [active, setActive] = useState(0);

  useEffect(() => playGeneric(ref.current, '.testimonial-card'), []);

  useEffect(() => {
    const el = track.current;
    if (!el) return undefined;
    let down = false;
    let startX = 0;
    let scroll = 0;

    const onDown = (e) => {
      down = true;
      startX = e.pageX;
      scroll = el.scrollLeft;
      el.style.cursor = 'grabbing';
    };
    const onUp = () => {
      down = false;
      el.style.cursor = 'grab';
    };
    const onMove = (e) => {
      if (!down) return;
      e.preventDefault();
      el.scrollLeft = scroll - (e.pageX - startX);
    };

    el.addEventListener('mousedown', onDown);
    window.addEventListener('mouseup', onUp);
    window.addEventListener('mousemove', onMove);
    return () => {
      el.removeEventListener('mousedown', onDown);
      window.removeEventListener('mouseup', onUp);
      window.removeEventListener('mousemove', onMove);
    };
  }, []);

  return (
    <section className="section" ref={ref} aria-labelledby="voices-title">
      <div className="container">
        <header className="section-head">
          <p className="section-kicker">Voices</p>
          <h2 className="section-heading" id="voices-title">
            Students and parents, in their words.
          </h2>
          <p className="section-lead quote-note">Placeholder quotes — replace with real testimonials.</p>
        </header>
        <div className="testimonial-track" ref={track}>
          {testimonials.map((item, i) => (
            <article
              className={`testimonial-card${active === i ? ' is-active' : ''}`}
              key={item.id}
              onMouseEnter={() => setActive(i)}
              onFocus={() => setActive(i)}
              tabIndex={0}
            >
              <q>{item.quote}</q>
              <footer>
                <strong>{item.name}</strong>
                <br />
                {item.role}
              </footer>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
