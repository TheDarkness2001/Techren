import { useEffect, useRef } from 'react';
import { appFeatures } from '../data/content';
import { playApp } from '../animations/scrollAnimations';
import DownloadAppButton from './DownloadAppButton';

export default function TechRenApp() {
  const ref = useRef(null);

  useEffect(() => playApp(ref.current), []);

  return (
    <section className="section" id="app" ref={ref} aria-labelledby="app-title">
      <div className="container app-layout">
        <div className="device-stage" aria-hidden="true">
          <article className="float-card float-1">
            <b>Homework</b>
            Complete and submit from the app.
          </article>
          <article className="float-card float-2">
            <b>Attendance</b>
            Present. Recorded. Visible.
          </article>
          <article className="float-card float-3">
            <b>Feedback</b>
            A note after the lesson — not months later.
          </article>
          <div className="device-wrap device-wrap-a">
            <div className="device device-a">
              <div className="device-screen">
                <div className="device-notch" />
                <p className="ui-row accent" />
                <p className="ui-row" style={{ width: '70%' }} />
                <div className="ui-card">
                  <p className="ui-row accent" style={{ width: '38%' }} />
                  <p className="ui-row" />
                  <p className="ui-row" style={{ width: '80%' }} />
                  <div className="ui-stat">
                    <span>Today</span>
                    <span>Homework · 2</span>
                  </div>
                </div>
                <div className="ui-card">
                  <p className="ui-row" style={{ width: '50%' }} />
                  <p className="ui-row" />
                  <div className="ui-stat">
                    <span>Attendance</span>
                    <span>Present</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div className="device-wrap device-wrap-b">
            <div className="device device-b">
              <div className="device-screen">
                <div className="device-notch" />
                <p className="ui-row accent" style={{ width: '54%' }} />
                <p className="ui-row" />
                <div className="ui-card">
                  <p className="ui-row" style={{ width: '40%' }} />
                  <div className="ui-stat">
                    <span>Messages</span>
                    <span>Academy</span>
                  </div>
                </div>
                <div className="ui-card">
                  <p className="ui-row accent" style={{ width: '30%' }} />
                  <p className="ui-row" />
                  <p className="ui-row" style={{ width: '62%' }} />
                </div>
              </div>
            </div>
          </div>
        </div>
        <div>
          <header className="section-head">
            <p className="section-kicker">TechRen App</p>
            <h2 className="section-heading" id="app-title">
              Learning doesn’t stop after class.
            </h2>
            <p className="section-lead">
              TechRen has its own student platform. Homework, attendance, messages, and daily feedback live in one place —
              for students, and for parents.
            </p>
          </header>
          <div className="app-features">
            {appFeatures.map((item) => (
              <article key={item.title}>
                <h3>{item.title}</h3>
                <p>{item.text}</p>
              </article>
            ))}
          </div>
          <div style={{ marginTop: '1.5rem' }}>
            <DownloadAppButton className="btn btn-primary magnetic" label="Download App" />
          </div>
        </div>
      </div>
    </section>
  );
}
