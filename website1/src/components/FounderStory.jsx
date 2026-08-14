import { useEffect, useRef } from 'react';
import founder from '../assets/founder.png';
import { playStory } from '../animations/scrollAnimations';

export default function FounderStory() {
  const ref = useRef(null);

  useEffect(() => playStory(ref.current), []);

  return (
    <section className="section" ref={ref} aria-labelledby="story-title">
      <div className="container">
        <header className="section-head">
          <p className="section-kicker">The path</p>
          <h2 className="section-heading" id="story-title">
            From programmer to teacher.
          </h2>
        </header>
        <div className="story-layout">
          <div className="story-portrait">
            <img
              src={founder}
              alt=""
              width="640"
              height="860"
              loading="lazy"
            />
          </div>
          <div>
            <article className="story-block">
              <h3>IT, practiced.</h3>
              <p>
                He studied information technology and learned the work the usual way: by writing programs, breaking them,
                and fixing them. That practical habit is still how TechRen teaches.
              </p>
            </article>
            <article className="story-block">
              <h3>Then the classroom.</h3>
              <p>
                Teaching showed a gap. Students could follow a lesson and still not know how to start a project of their
                own. Structured education needed a tighter link to making something real.
              </p>
            </article>
            <article className="story-block">
              <h3>Both at once.</h3>
              <p>
                Today he works as a programmer online and runs TechRen as a place where programming and English are taught
                as usable skills — with a digital platform so the work doesn’t disappear after class.
              </p>
            </article>
          </div>
        </div>
      </div>
    </section>
  );
}
