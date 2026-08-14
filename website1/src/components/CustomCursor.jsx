import { useEffect, useRef } from 'react';
import { isFinePointer } from '../animations/utils';

export default function CustomCursor() {
  const dot = useRef(null);
  const ring = useRef(null);

  useEffect(() => {
    if (!isFinePointer()) return undefined;

    const dotEl = dot.current;
    const ringEl = ring.current;
    let x = window.innerWidth / 2;
    let y = window.innerHeight / 2;
    let rx = x;
    let ry = y;
    let frame = 0;
    let hovering = false;

    document.documentElement.classList.add('has-custom-cursor');
    dotEl.classList.add('is-on');
    ringEl.classList.add('is-on');

    const onMove = (event) => {
      x = event.clientX;
      y = event.clientY;
      dotEl.style.transform = `translate3d(${x}px, ${y}px, 0)${hovering ? ' scale(2.4)' : ''}`;
      if (!frame) frame = requestAnimationFrame(tick);
    };

    const tick = () => {
      rx += (x - rx) * 0.18;
      ry += (y - ry) * 0.18;
      ringEl.style.transform = `translate3d(${rx}px, ${ry}px, 0)`;
      if (Math.abs(x - rx) > 0.1 || Math.abs(y - ry) > 0.1) {
        frame = requestAnimationFrame(tick);
      } else {
        frame = 0;
      }
    };

    const onOver = (event) => {
      const interactive = event.target.closest('a, button, input, textarea, .field-badge, .project-card, .id-badge');
      hovering = Boolean(interactive);
      dotEl.classList.toggle('is-hover', hovering);
    };

    window.addEventListener('mousemove', onMove, { passive: true });
    document.addEventListener('mouseover', onOver);

    return () => {
      document.documentElement.classList.remove('has-custom-cursor');
      window.removeEventListener('mousemove', onMove);
      document.removeEventListener('mouseover', onOver);
      if (frame) cancelAnimationFrame(frame);
    };
  }, []);

  return (
    <>
      <div className="cursor" ref={dot} aria-hidden="true" />
      <div className="cursor-ring" ref={ring} aria-hidden="true" />
    </>
  );
}
