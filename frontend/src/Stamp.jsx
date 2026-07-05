/**
 * Tampon "VALIDÉ" texturé (feTurbulence), apposé sur un dossier validé.
 * `id` rend le filtre SVG unique par instance.
 */
export default function Stamp({ id, date }) {
  const filterId = `rough-${id}`;
  return (
    <div className="stamp-wrap show">
      <svg viewBox="0 0 100 100" width="62" height="62" role="img" aria-label="Tampon validé">
        <defs>
          <filter id={filterId}>
            <feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="2" result="noise" />
            <feDisplacementMap in="SourceGraphic" in2="noise" scale="3.5" />
          </filter>
        </defs>
        <g filter={`url(#${filterId})`}>
          <circle className="stamp-ring" cx="50" cy="50" r="38" strokeWidth="2.5" />
          <circle className="stamp-ring" cx="50" cy="50" r="30" strokeWidth="1.5" />
          <text className="stamp-text" x="50" y="47" fontSize="11" fontWeight="700">
            VALIDÉ
          </text>
          <text className="stamp-text" x="50" y="60" fontSize="7">
            {date}
          </text>
        </g>
      </svg>
    </div>
  );
}
