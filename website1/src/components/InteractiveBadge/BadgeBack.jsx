import logo from '../../assets/logo.png';

const tracks = [
  {
    label: 'Programming',
    icon: (
      <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true">
        <path d="M8 8 3 12l5 4M16 8l5 4-5 4M13 6l-2 12" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    ),
  },
  {
    label: 'English',
    icon: (
      <svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true">
        <path d="M4 6.5A7 7 0 0 1 12 4a7 7 0 0 1 8 8c0 4-3.2 8-8 8H7l-3 3v-5.2A8.2 8.2 0 0 1 4 6.5Z" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinejoin="round" />
      </svg>
    ),
  },
];

const tools = [
  {
    label: 'Homework',
    icon: (
      <svg viewBox="0 0 24 24" width="14" height="14" aria-hidden="true">
        <path d="M6 4h9l4 4v12H6V4Z" fill="none" stroke="currentColor" strokeWidth="1.7" />
        <path d="M15 4v4h4M8 13h8M8 17h5" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
      </svg>
    ),
  },
  {
    label: 'Attendance',
    icon: (
      <svg viewBox="0 0 24 24" width="14" height="14" aria-hidden="true">
        <circle cx="12" cy="12" r="8" fill="none" stroke="currentColor" strokeWidth="1.7" />
        <path d="m8.5 12.5 2.3 2.3 4.7-5" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
      </svg>
    ),
  },
  {
    label: 'Messages',
    icon: (
      <svg viewBox="0 0 24 24" width="14" height="14" aria-hidden="true">
        <path d="M5 6h14v10H8l-3 3V6Z" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinejoin="round" />
      </svg>
    ),
  },
  {
    label: 'Feedback',
    icon: (
      <svg viewBox="0 0 24 24" width="14" height="14" aria-hidden="true">
        <path d="m12 4 2.2 5.4L20 10l-4.2 3.6L17 20l-5-3.2L7 20l1.2-6.4L4 10l5.8-.6L12 4Z" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinejoin="round" />
      </svg>
    ),
  },
  {
    label: 'Parents',
    icon: (
      <svg viewBox="0 0 24 24" width="14" height="14" aria-hidden="true">
        <circle cx="9" cy="8" r="2.3" fill="none" stroke="currentColor" strokeWidth="1.7" />
        <circle cx="16" cy="9" r="2" fill="none" stroke="currentColor" strokeWidth="1.7" />
        <path d="M4.5 18c.6-2.6 2.5-4 4.6-4s4 1.4 4.6 4M13 14.2c1.7-.3 3.4.7 4.2 2.8" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" />
      </svg>
    ),
  },
];

export default function BadgeBack() {
  return (
    <div className="id-face id-back">
      <div className="id-back-glow" aria-hidden="true" />
      <div className="id-back-inner">
        <div className="id-back-hero">
          <span className="id-logo-mark">
            <img src={logo} alt="" width="58" height="58" />
          </span>
          <div>
            <p className="id-back-name">TechRen</p>
            <p className="id-back-sub">Academy</p>
          </div>
        </div>
        <div className="id-chips">
          {tracks.map((track) => (
            <span className="id-chip" key={track.label}>
              {track.icon}
              {track.label}
            </span>
          ))}
        </div>
        <div className="id-holo" aria-hidden="true" />
        <p className="id-back-kicker">Student platform</p>
        <ul className="id-back-tools">
          {tools.map((tool) => (
            <li key={tool.label}>
              <span className="id-tool-icon">{tool.icon}</span>
              {tool.label}
            </li>
          ))}
        </ul>
        <div className="id-back-foot">
          <span>TR — CAMPUS</span>
          <span>Learn · Build</span>
        </div>
      </div>
    </div>
  );
}
