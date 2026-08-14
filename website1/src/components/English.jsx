import { useEffect, useRef } from 'react';
import { englishSkills, englishExtras } from '../data/content';
import { playEnglish } from '../animations/scrollAnimations';

export default function English() {
  const ref = useRef(null);

  useEffect(() => playEnglish(ref.current), []);

  return (
    <section className="section english" id="english" ref={ref} aria-labelledby="english-title">
      <div className="container">
        <header className="section-head">
          <p className="section-kicker">English</p>
          <h2 className="section-heading" id="english-title">
            Communication is a skill too.
          </h2>
          <p className="section-lead">
            Language is a second major path at TechRen — taught with the same practical standard as code.
          </p>
        </header>
        <div className="english-skills">
          {englishSkills.map((skill) => (
            <article className="english-skill" key={skill.name}>
              <h3>{skill.name}</h3>
              <p>{skill.text}</p>
            </article>
          ))}
        </div>
        <div className="english-extras">
          {englishExtras.map((item) => (
            <article className="english-extra" key={item.name}>
              <h4>{item.name}</h4>
              <p>{item.text}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
