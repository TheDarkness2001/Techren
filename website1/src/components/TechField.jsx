import { useEffect, useRef } from 'react';
import { techBadges } from '../data/content';
import { bindTechField } from '../animations/hoverAnimations';
import { playGeneric } from '../animations/scrollAnimations';

export default function TechField() {
  const section = useRef(null);
  const field = useRef(null);

  useEffect(() => {
    const cleanReveal = playGeneric(section.current);
    const cleanField = bindTechField(field.current);
    return () => {
      cleanReveal();
      cleanField();
    };
  }, []);

  return (
    <section className="section tech-field" ref={section} aria-labelledby="field-title">
      <div className="container">
        <header className="section-head">
          <p className="section-kicker">The stack</p>
          <h2 className="section-heading" id="field-title">
            A living technology field.
          </h2>
          <p className="section-lead">
            The tools students actually use — not a logo wall. Move through them. They respond.
          </p>
        </header>
      </div>
      <div className="container-wide">
        <div className="field-stage" ref={field}>
          {techBadges.map((tech) => (
            <span
              className="field-badge"
              key={tech.id}
              style={{ '--x': `${tech.x}%`, '--y': `${tech.y}%` }}
              data-x={tech.x}
              data-y={tech.y}
            >
              {tech.name}
            </span>
          ))}
        </div>
      </div>
    </section>
  );
}
