import { useEffect, useState } from 'react';
import { navLinks } from '../data/content';
import { useTheme } from '../hooks/theme.jsx';
import BrandLogo from './BrandLogo';
import DownloadAppButton from './DownloadAppButton';

export default function Navbar() {
  const { theme, toggleTheme } = useTheme();
  const [solid, setSolid] = useState(false);
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState('#home');

  useEffect(() => {
    const onScroll = () => {
      setSolid(window.scrollY > 24);
      const ids = navLinks.map((l) => l.href.slice(1));
      let current = '#home';
      ids.forEach((id) => {
        const el = document.getElementById(id);
        if (!el) return;
        if (el.getBoundingClientRect().top < 120) current = `#${id}`;
      });
      setActive(current);
    };

    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useEffect(() => {
    document.body.style.overflow = open ? 'hidden' : '';
    return () => {
      document.body.style.overflow = '';
    };
  }, [open]);

  const close = () => setOpen(false);

  return (
    <header className={`nav${solid ? ' is-solid' : ''}${open ? ' is-open' : ''}`}>
      <div className="nav-inner">
        <a className="logo" href="#home" onClick={close}>
          <BrandLogo size={28} withWord />
        </a>
        <nav className="nav-links" aria-label="Primary">
          {navLinks.map((link) => (
            <a key={link.href} href={link.href} aria-current={active === link.href ? 'true' : undefined}>
              {link.label}
            </a>
          ))}
        </nav>
        <div className="nav-end">
          <button
            className="theme-toggle"
            type="button"
            aria-label={theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
            onClick={(e) => toggleTheme(e.currentTarget)}
          >
            {theme === 'dark' ? (
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                <circle cx="12" cy="12" r="4" stroke="currentColor" strokeWidth="1.6" />
                <path
                  d="M12 3v2M12 19v2M3 12h2M19 12h2M5.6 5.6l1.4 1.4M17 17l1.4 1.4M18.4 5.6 17 7M7 17l-1.4 1.4"
                  stroke="currentColor"
                  strokeWidth="1.6"
                />
              </svg>
            ) : (
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                <path d="M18 13a7 7 0 1 1-8-9 7 7 0 0 0 8 9Z" stroke="currentColor" strokeWidth="1.6" />
              </svg>
            )}
          </button>
          <DownloadAppButton
            className="btn btn-primary nav-cta magnetic"
            label="Download"
            showPlatformHint={false}
          />
          <button
            className="nav-toggle"
            type="button"
            aria-label={open ? 'Close menu' : 'Open menu'}
            aria-expanded={open}
            onClick={() => setOpen((v) => !v)}
          >
            <span />
          </button>
        </div>
      </div>
      <div className="mobile-menu" hidden={!open}>
        {navLinks.map((link) => (
          <a key={link.href} href={link.href} onClick={close}>
            {link.label}
          </a>
        ))}
        <div onClick={close}>
          <DownloadAppButton className="btn btn-primary" label="Download App" />
        </div>
      </div>
    </header>
  );
}
