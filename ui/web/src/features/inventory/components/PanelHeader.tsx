export function PanelHeader({ title, right }: { title: string; right?: string }) {
  return (
    <div className="flex h-[33px] items-center justify-between bg-zinc-800/90 px-3">
      <span className="text-lg font-bold uppercase tracking-wide">{title}</span>
      {right !== undefined && <span className="text-sm font-semibold text-white/80">{right}</span>}
    </div>
  )
}
