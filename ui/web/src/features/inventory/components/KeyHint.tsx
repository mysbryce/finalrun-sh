export function KeyHint({ k, label }: { k: string; label: string }) {
  return (
    <span className="flex items-center gap-2">
      <span className="grid h-4 min-w-4 place-items-center rounded-[2px] border border-white/70 px-1 text-[10px] font-bold leading-none">
        {k}
      </span>
      <span className="text-[11px] font-semibold uppercase tracking-wider">{label}</span>
    </span>
  )
}
