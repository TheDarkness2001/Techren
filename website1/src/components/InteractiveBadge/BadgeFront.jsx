import portrait from '../../assets/badge-portrait.png';
import logo from '../../assets/logo.png';

export default function BadgeFront() {
  return (
    <div className="id-face id-front">
      <div className="id-front-inner">
        <div className="id-card-head">
          <span className="id-head-brand">
            <img src={logo} alt="" width="22" height="22" />
            TECHREN
          </span>
          <span>FOUNDER</span>
        </div>
        <div className="id-photo-lg">
          <img src={portrait} alt="" />
        </div>
        <div className="id-front-meta">
          <p className="id-name-lg">Husanboy</p>
          <p className="id-role">Founder &amp; IT Teacher</p>
          <p className="id-track">Programmer · IT Education</p>
        </div>
        <div className="id-card-foot">
          <span>TR — ID</span>
          <span>Learn · Build</span>
        </div>
      </div>
    </div>
  );
}
