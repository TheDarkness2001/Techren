export default function Lanyard({ svgRef, strapRef, shineRef, reelRef, width, height }) {
  const w = Math.max(width, 1);
  const h = Math.max(height, 1);

  return (
    <svg
      className="lanyard"
      ref={svgRef}
      aria-hidden="true"
      width={w}
      height={h}
      viewBox={`0 0 ${w} ${h}`}
      preserveAspectRatio="none"
    >
      <defs>
        <linearGradient id="strap-grad" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#141416" />
          <stop offset="40%" stopColor="#2c2c32" />
          <stop offset="52%" stopColor="#4a4a52" />
          <stop offset="100%" stopColor="#141416" />
        </linearGradient>
      </defs>
      <path ref={strapRef} className="lanyard-strap" />
      <path ref={shineRef} className="lanyard-shine" />
      <g ref={reelRef} className="lanyard-reel">
        <rect x="-13" y="0" width="26" height="11" rx="2" />
        <circle r="3.4" cy="5.5" />
      </g>
    </svg>
  );
}
