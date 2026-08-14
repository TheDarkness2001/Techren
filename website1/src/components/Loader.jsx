import { useEffect, useRef } from 'react';
import { playLoader } from '../animations/pageAnimations';
import BrandLogo from './BrandLogo';

export default function Loader({ onComplete }) {
  const ref = useRef(null);

  useEffect(() => {
    let cancelled = false;
    playLoader(ref.current, () => {
      if (!cancelled) onComplete();
    });
    return () => {
      cancelled = true;
    };
  }, [onComplete]);

  return (
    <div className="loader" ref={ref} role="status" aria-live="polite" aria-label="Loading TechRen">
      <div className="loader-inner">
        <div className="loader-mark">
          <BrandLogo size={64} />
        </div>
        <div className="loader-word" aria-hidden="true">
          {'TECHREN'.split('').map((letter, i) => (
            <span className="loader-letter" key={`${letter}-${i}`}>
              {letter}
            </span>
          ))}
        </div>
        <div className="loader-line" />
      </div>
    </div>
  );
}
