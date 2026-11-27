export function KeyHint({ k, label }: { k: string; label: string }) {
  return (
    <span className="flex items-center gap-2">
      <span className="grid h-6 min-w-6 place-items-center rounded-sm bg-white/90 px-1 text-[11px] font-bold text-zinc-900">
        {k}
      </span>
      <span className="text-xs font-semibold uppercase tracking-wider">{label}</span>
    </span>
  )
}
