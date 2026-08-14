import logo from '../assets/logo.png';

export default function BrandLogo({ size = 28, withWord = false, word = 'TechRen' }) {
  return (
    <span className={`brand-logo${withWord ? ' has-word' : ''}`}>
      <img src={logo} alt={withWord ? '' : 'TechRen'} width={size} height={size} />
      {withWord ? <span className="brand-word">{word}</span> : null}
    </span>
  );
}
