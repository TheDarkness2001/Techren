import { useEffect, useRef } from 'react';
import { startProgrammingJourney } from '../animations/programmingJourney';

function WindowFrame({ title, variant = 'app', children, className = '' }) {
  return (
    <div className={`jw-window jw-window-${variant} ${className}`}>
      <div className="jw-chrome">
        <span className="jw-dots" aria-hidden="true">
          <i />
          <i />
          <i />
        </span>
        <span className="jw-win-title">{title}</span>
      </div>
      <div className="jw-window-body">{children}</div>
    </div>
  );
}

export default function Programming() {
  const ref = useRef(null);

  useEffect(() => startProgrammingJourney(ref.current), []);

  return (
    <section
      className="programming-journey"
      id="programming"
      ref={ref}
      aria-labelledby="programming-title"
    >
      <div className="journey-sticky">
        <div className="journey-grid" aria-hidden="true" />
        <div className="journey-lines" aria-hidden="true">
          <span />
          <span />
          <span />
        </div>

        <div className="journey-world">
          <article className="journey-scene is-intro">
            <p className="jw-kicker" data-jw="intro-line">
              01 / PROGRAMMING
            </p>
            <h2 className="jw-display" id="programming-title" data-jw="intro-line">
              Learn to build.
            </h2>
            <p className="jw-lead" data-jw="intro-line">
              A path, not a pile of topics.
            </p>
            <ul className="jw-steps">
              <li data-jw="intro-line">Start with the fundamentals.</li>
              <li data-jw="intro-line">Build interfaces.</li>
              <li data-jw="intro-line">Learn logic.</li>
              <li data-jw="intro-line">Create real applications.</li>
            </ul>
          </article>

          <article className="journey-scene is-html">
            <div className="jw-copy">
              <p className="jw-kicker">01 / FOUNDATION</p>
              <h3 className="jw-name">HTML</h3>
              <p className="jw-role">Structure.</p>
            </div>
            <div className="jw-stage">
              <WindowFrame title="index.html" variant="code">
                <pre className="jw-code">
                  <span data-jw="html-line">&lt;!DOCTYPE html&gt;</span>
                  <span data-jw="html-line">&lt;html&gt;</span>
                  <span data-jw="html-line">  &lt;body&gt;</span>
                  <span data-jw="html-line">
                    {'    '}&lt;h1&gt;<b>TechRen</b>&lt;/h1&gt;
                  </span>
                  <span data-jw="html-line">
                    {'    '}&lt;p&gt;Learn to build.&lt;/p&gt;
                  </span>
                  <span data-jw="html-line">  &lt;/body&gt;</span>
                  <span data-jw="html-line">&lt;/html&gt;</span>
                </pre>
              </WindowFrame>
              <WindowFrame title="localhost:5173" className="jw-preview-wrap">
                <div className="jw-html-preview" data-jw="html-preview">
                  <h4>TechRen</h4>
                  <p>Learn to build.</p>
                </div>
              </WindowFrame>
            </div>
          </article>

          <article className="journey-scene is-css">
            <div className="jw-copy">
              <p className="jw-kicker">02 / FOUNDATION</p>
              <h3 className="jw-name">CSS</h3>
              <p className="jw-role">Appearance.</p>
            </div>
            <div className="jw-stage">
              <WindowFrame title="styles.css" variant="code">
                <pre className="jw-code">
                  <span data-jw="css-line">
                    .container {'{'}
                  </span>
                  <span data-jw="css-line">{'  '}display: grid;</span>
                  <span data-jw="css-line">{'  '}gap: 24px;</span>
                  <span data-jw="css-line">{'}'}</span>
                  <span data-jw="css-line">
                    .title {'{'}
                  </span>
                  <span data-jw="css-line">{'  '}font-size: 64px;</span>
                  <span data-jw="css-line">{'  '}font-weight: 700;</span>
                  <span data-jw="css-line">{'}'}</span>
                </pre>
              </WindowFrame>
              <WindowFrame title="preview">
                <div className="jw-css-preview" data-jw="css-preview">
                  <p className="jw-css-title">TechRen</p>
                  <p className="jw-css-sub">Learn to build.</p>
                  <div className="jw-css-grid">
                    <span />
                    <span />
                    <span />
                  </div>
                </div>
              </WindowFrame>
            </div>
          </article>

          <article className="journey-scene is-js">
            <div className="jw-copy">
              <p className="jw-kicker">03 / CORE</p>
              <h3 className="jw-name">JavaScript</h3>
              <p className="jw-role">Behavior.</p>
            </div>
            <div className="jw-stage jw-stage-js">
              <WindowFrame title="app.js" variant="code">
                <pre className="jw-code">
                  <span data-jw="js-line">button.addEventListener(</span>
                  <span data-jw="js-line">{'  '}&quot;click&quot;,</span>
                  <span data-jw="js-line">{'  '}() =&gt; {'{'}</span>
                  <span data-jw="js-line">{'    '}count += 1;</span>
                  <span data-jw="js-line">{'    '}render();</span>
                  <span data-jw="js-line">{'  }'}</span>
                  <span data-jw="js-line">);</span>
                </pre>
              </WindowFrame>
              <div className="jw-js-live">
                <p className="jw-js-note" data-jw="js-note">
                  Scroll is the click.
                </p>
                <button className="jw-js-btn" type="button" tabIndex={-1} data-jw="js-btn">
                  CLICK ME
                </button>
                <p className="jw-js-count">
                  <span data-jw="js-count">0</span>
                </p>
                <div className="jw-js-chips">
                  <span data-jw="js-chip">DOM</span>
                  <span data-jw="js-chip">events</span>
                  <span data-jw="js-chip">state</span>
                </div>
              </div>
            </div>
          </article>

          <article className="journey-scene is-python">
            <div className="jw-copy">
              <p className="jw-kicker">04 / CORE</p>
              <h3 className="jw-name">Python</h3>
              <p className="jw-role">Logic.</p>
            </div>
            <div className="jw-stage">
              <WindowFrame title="python — TechRen" variant="term">
                <pre className="jw-term">
                  <span data-jw="py-line">
                    &gt;&gt;&gt; print(&quot;Hello, TechRen&quot;)
                  </span>
                  <span data-jw="py-line">Hello, TechRen</span>
                  <span data-jw="py-line"> </span>
                  <span data-jw="py-line">
                    &gt;&gt;&gt; students = [&quot;HTML&quot;, &quot;CSS&quot;, &quot;JavaScript&quot;, &quot;Python&quot;]
                  </span>
                  <span data-jw="py-line">
                    &gt;&gt;&gt; for skill in students:
                  </span>
                  <span data-jw="py-line">{'        '}print(skill)</span>
                  <span data-jw="py-line">HTML</span>
                  <span data-jw="py-line">CSS</span>
                  <span data-jw="py-line">JavaScript</span>
                  <span data-jw="py-line">
                    Python<span className="jw-cursor" data-jw="py-cursor">█</span>
                  </span>
                </pre>
              </WindowFrame>
              <div className="jw-py-viz" aria-hidden="true">
                <span data-jw="py-bar" />
                <span data-jw="py-bar" />
                <span data-jw="py-bar" />
                <span data-jw="py-bar" />
              </div>
            </div>
          </article>

          <article className="journey-scene is-java">
            <div className="jw-copy">
              <p className="jw-kicker">05 / CORE</p>
              <h3 className="jw-name">Java</h3>
              <p className="jw-role">Structure. Objects. Logic.</p>
            </div>
            <div className="jw-stage">
              <WindowFrame title="Student.java" variant="code">
                <pre className="jw-code">
                  <span data-jw="java-line">public class Student {'{'}</span>
                  <span data-jw="java-line">{'    '}String name;</span>
                  <span data-jw="java-line"> </span>
                  <span data-jw="java-line">{'    '}void learn() {'{'}</span>
                  <span data-jw="java-line">{'        '}System.out.println(</span>
                  <span data-jw="java-line">{'            '}&quot;Learn. Build. Grow.&quot;</span>
                  <span data-jw="java-line">{'        '});</span>
                  <span data-jw="java-line">{'    }'}</span>
                  <span data-jw="java-line">{'}'}</span>
                </pre>
              </WindowFrame>
              <div className="jw-java-objs">
                <div className="jw-obj" data-jw="java-obj">
                  <span>class</span>
                  <b>Student</b>
                </div>
                <div className="jw-obj" data-jw="java-obj">
                  <span>field</span>
                  <b>name</b>
                </div>
                <div className="jw-obj" data-jw="java-obj">
                  <span>method</span>
                  <b>learn()</b>
                </div>
              </div>
            </div>
          </article>

          <article className="journey-scene is-react">
            <div className="jw-copy">
              <p className="jw-kicker">06 / APPLIED</p>
              <h3 className="jw-name">React</h3>
              <p className="jw-role">Applications.</p>
            </div>
            <div className="jw-stage jw-stage-react">
              <div className="jw-tree" data-jw="react-tree" aria-hidden="true">
                <div className="jw-node is-app">APP</div>
                <div className="jw-tree-row">
                  <div className="jw-node">HEADER</div>
                  <div className="jw-node">MAIN</div>
                </div>
                <div className="jw-tree-row is-leaf">
                  <div className="jw-node">COURSE</div>
                  <div className="jw-node">PROFILE</div>
                </div>
              </div>
              <div className="jw-miniapp" data-jw="react-app">
                <header className="jw-app-head" data-jw="react-part">
                  <span>TechRen</span>
                  <nav>
                    <i />
                    <i />
                    <i />
                  </nav>
                </header>
                <div className="jw-app-body">
                  <article className="jw-app-card" data-jw="react-part">
                    <p>Course</p>
                    <b>Learn to build</b>
                  </article>
                  <aside className="jw-app-profile" data-jw="react-part">
                    <span />
                    <p>Student</p>
                  </aside>
                </div>
              </div>
            </div>
          </article>

          <article className="journey-scene is-outro">
            <p className="jw-kicker" data-jw="outro-line">
              FROM CODE
            </p>
            <h3 className="jw-display" data-jw="outro-line">
              To product.
            </h3>
            <p className="jw-outro-text" data-jw="outro-line">
              Programming is not about memorizing syntax.
              <br />
              It’s about building things.
            </p>
          </article>
        </div>

        <div className="journey-hud" aria-hidden="true">
          <div className="jw-hud-meta">
            <p data-jw="hud-kicker">PROGRAMMING</p>
            <p data-jw="hud-code">01 / INTRO</p>
          </div>
          <div className="jw-hud-bar">
            <span>01 HTML</span>
            <div className="jw-track">
              <i data-jw="hud-fill" />
              <b data-jw="hud-dot" />
            </div>
            <span>REACT 06</span>
          </div>
        </div>
      </div>
    </section>
  );
}
