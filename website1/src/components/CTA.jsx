import { useEffect, useRef, useState } from 'react';
import { playCTA } from '../animations/scrollAnimations';
import DownloadAppButton from './DownloadAppButton';

export default function CTA() {
  const ref = useRef(null);
  const [note, setNote] = useState('');

  useEffect(() => playCTA(ref.current), []);

  const onSubmit = (event) => {
    event.preventDefault();
    setNote('This form is a placeholder. Connect it to your contact channel when ready.');
  };

  return (
    <section className="section cta" id="contact" ref={ref} aria-labelledby="cta-title">
      <div className="container">
        <div className="cta-panel">
          <h2 className="cta-title" id="cta-title">
            Your future starts with what you build.
          </h2>
          <p className="cta-lead">Learn practical skills. Build real projects. Grow with TechRen.</p>
          <div className="cta-actions">
            <DownloadAppButton className="btn btn-primary magnetic" label="Download App" />
            <a className="btn btn-ghost magnetic" href="mailto:hello@techrenacademy.com">
              Contact TechRen
            </a>
          </div>
          <form className="contact-form" id="contact-form" onSubmit={onSubmit}>
            <label>
              Name
              <input name="name" type="text" autoComplete="name" required />
            </label>
            <label>
              Email
              <input name="email" type="email" autoComplete="email" required />
            </label>
            <label className="full">
              Message
              <textarea name="message" required placeholder="What do you want to learn?" />
            </label>
            <div className="full">
              <button className="btn btn-primary" type="submit">
                Send message
              </button>
            </div>
            {note ? (
              <p className="form-note" role="status">
                {note}
              </p>
            ) : (
              <p className="form-note">Placeholder form — wire this to email, Telegram, or your CRM later.</p>
            )}
          </form>
        </div>
      </div>
    </section>
  );
}
