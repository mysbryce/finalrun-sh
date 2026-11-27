import { HEADER_HEIGHT } from '../layout'

export function PanelHeader({ title, right, width }: { title: string; right?: string; width?: number }) {
  return (
    <div className="flex items-center justify-between bg-black/25 px-2.5" style={{ height: HEADER_HEIGHT, width }}>
      <span className="text-lg font-bold uppercase tracking-wide">{title}</span>
      {right !== undefined && <span className="text-sm font-semibold text-white/80">{right}</span>}
    </div>
  )
}
