import { useEffect, useRef } from 'react';
import { projects } from '../data/content';
import { playProjects } from '../animations/scrollAnimations';
import { bindProjectHovers } from '../animations/hoverAnimations';

export default function Projects() {
  const ref = useRef(null);

  useEffect(() => {
    const a = playProjects(ref.current);
    const b = bindProjectHovers(ref.current);
    return () => {
      a();
      b();
    };
  }, []);

  return (
    <section className="section" id="projects" ref={ref} aria-labelledby="projects-title">
      <div className="container">
        <header className="section-head">
          <p className="section-kicker">Work</p>
          <h2 className="section-heading" id="projects-title">
            Don’t just learn. Build.
          </h2>
          <p className="section-lead">
            Students don’t only watch lessons. They leave with things that run — on a page, a phone, a board, a server.
          </p>
        </header>
        <div className="project-grid">
          {projects.map((project) => (
            <article className="project-card" key={project.id}>
              <div className="project-visual" data-kind={project.id} aria-hidden="true" />
              <div className="project-body">
                <p className="project-tag">{project.tag}</p>
                <h3 className="project-title">{project.title}</h3>
                <p>{project.text}</p>
                <span className="project-arrow" aria-hidden="true">
                  →
                </span>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
