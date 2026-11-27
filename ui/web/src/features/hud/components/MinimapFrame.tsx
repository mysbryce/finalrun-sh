import { MINIMAP } from '../layout'

export function MinimapFrame({ heading }: { heading: number }) {
  return (
    <div
      className="absolute rounded-md ring-2 ring-white/25"
      style={{
        left: MINIMAP.left,
        top: MINIMAP.top,
        width: MINIMAP.width,
        height: MINIMAP.height,
      }}
    >
      <svg
        width={18}
        height={18}
        viewBox="0 0 18 18"
        className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 fill-amber-400 stroke-white"
        style={{ transform: `rotate(${heading}deg)` }}
        aria-hidden="true"
      >
        <polygon points="9,1 16,16 9,12 2,16" strokeWidth={1.5} strokeLinejoin="round" />
      </svg>
    </div>
  )
}
