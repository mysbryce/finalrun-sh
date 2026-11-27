import { compassMarks } from '../compass'
import { COMPASS_WIDTH } from '../layout'

export function Compass({ heading }: { heading: number }) {
  return (
    <div
      className="absolute left-1/2 top-2 -translate-x-1/2 h-9 overflow-hidden"
      style={{
        width: COMPASS_WIDTH,
        maskImage: 'linear-gradient(to right, transparent, black 15%, black 85%, transparent)',
      }}
    >
      {compassMarks(heading).map((mark) => (
        <div
          key={`${mark.deg}-${mark.offset}`}
          className={`absolute -translate-x-1/2 top-3 ${
            mark.major ? 'text-sm font-bold text-white' : 'text-[11px] text-white/60'
          }`}
          style={{ left: COMPASS_WIDTH / 2 + mark.offset }}
        >
          {mark.label}
        </div>
      ))}
      <div className="absolute left-1/2 top-0 h-2.5 w-0.5 -translate-x-1/2 bg-amber-400" />
    </div>
  )
}
