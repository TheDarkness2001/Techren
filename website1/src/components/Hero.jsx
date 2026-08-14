import { useEffect, useRef } from 'react';
import InteractiveBadge from './InteractiveBadge';
import DownloadAppButton from './DownloadAppButton';
import { playHero } from '../animations/heroAnimations';

export default function Hero({ start }) {
  const ref = useRef(null);

  useEffect(() => {
    if (!start || !ref.current) return undefined;
    playHero(ref.current);
    return undefined;
  }, [start]);

  return (
    <section className="hero" id="home" ref={ref}>
      <div className="hero-bg" aria-hidden="true">
        <div className="hero-grid" />
        <div className="hero-orb" />
      </div>
      <InteractiveBadge start={start} />
      <div className="hero-inner">
        <div className="hero-copy">
          <p className="hero-brand">TechRen</p>
          <p className="hero-label">Programming · English · Technology</p>
          <h1 className="hero-title">
            <span className="hero-word">Learn.</span>
            <span className="hero-word">Build.</span>
            <span className="hero-word">Grow.</span>
          </h1>
          <p className="hero-desc">
            Practical programming and English education for students who want to build real skills.
          </p>
          <div className="hero-ctas">
            <DownloadAppButton className="btn btn-primary magnetic" label="Download App" />
            <a className="btn btn-ghost magnetic" href="#programming">
              Explore TechRen
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}
