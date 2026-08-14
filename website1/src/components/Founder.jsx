import { useEffect, useRef } from 'react';
import founder from '../assets/founder.png';
import { playFounder } from '../animations/scrollAnimations';
import { isFinePointer, prefersReducedMotion } from '../animations/utils';

export default function Founder() {
  const ref = useRef(null);
  const frame = useRef(null);

  useEffect(() => {
    const cleanup = playFounder(ref.current);
    const node = frame.current;
    if (!node || !isFinePointer() || prefersReducedMotion()) return cleanup;

    const onMove = (e) => {
      const rect = node.getBoundingClientRect();
      const x = (e.clientX - rect.left) / rect.width - 0.5;
      const y = (e.clientY - rect.top) / rect.height - 0.5;
      node.style.transform = `translate3d(${x * 8}px, ${y * 6}px, 0)`;
    };
    const onLeave = () => {
      node.style.transform = '';
    };

    node.addEventListener('mousemove', onMove);
    node.addEventListener('mouseleave', onLeave);
    return () => {
      cleanup();
      node.removeEventListener('mousemove', onMove);
      node.removeEventListener('mouseleave', onLeave);
    };
  }, []);

  return (
    <section className="section" id="about" ref={ref} aria-labelledby="founder-title">
      <div className="container founder-layout">
        <div className="founder-frame" ref={frame}>
          <img
            src={founder}
            alt="Husanboy, founder of TechRen Academy, in a white shirt"
            width="800"
            height="1100"
            loading="lazy"
          />
        </div>
        <div className="founder-copy">
          <p className="section-kicker">Founder</p>
          <h2 id="founder-title">
            From programmer
            <br />
            to teacher
            <br />
            to founder.
          </h2>
          <p>
            TechRen was created from a simple idea: students should not only learn technology. They should learn how to
            use it, practice it, and build with it.
          </p>
          <p>
            The founder studied IT, taught it for about a year, and still works as a programmer remotely while building
            the academy.
          </p>
          <blockquote className="founder-quote">
            Your identity is more than a student number. It’s what you learn and what you build.
          </blockquote>
          <p className="founder-meta">Founder · Programmer · IT teacher</p>
        </div>
      </div>
    </section>
  );
}
