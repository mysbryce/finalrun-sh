export function KeyHint({ k, label, binding }: { k: string; label: string; binding?: string | null }) {
  const chip = binding === null ? 'Unbound' : (binding ?? k)
  return (
    <span className="flex items-center gap-2">
      <span className="grid h-5 min-w-5 place-items-center rounded-[2px] border border-white/70 px-1 text-[11px] font-bold leading-none">
        {chip}
      </span>
      <span className="text-[11px] font-semibold uppercase tracking-wider">{label}</span>
    </span>
  )
}
