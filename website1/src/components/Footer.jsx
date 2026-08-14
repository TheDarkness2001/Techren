import { footerColumns, socials } from '../data/content';
import BrandLogo from './BrandLogo';

export default function Footer() {
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-top">
          <div className="footer-brand">
            <BrandLogo size={40} withWord word="TechRen Academy" />
            <p>Programming and English education. Learn practical skills. Build real projects. Grow with technology.</p>
          </div>
          {footerColumns.map((col) => (
            <div key={col.title}>
              <h3>{col.title}</h3>
              <ul>
                {col.links.map((link) => (
                  <li key={link.label}>
                    <a href={link.href}>{link.label}</a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
          <div>
            <h3>Social</h3>
            <ul>
              {socials.map((item) => (
                <li key={item.name}>
                  <a href={item.href} aria-label={`${item.name} (placeholder link)`}>
                    {item.name}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </div>
        <div className="footer-bottom">
          <p>© {new Date().getFullYear()} TechRen Academy</p>
          <p>Programming · English · Practical skills</p>
        </div>
      </div>
    </footer>
  );
}
