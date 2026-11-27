export interface Toast {
  id: string
  text: string
  priority?: 'normal' | 'high'
}

export interface ToastTrayProps {
  toasts: Toast[]
}

const MAX_SHOWN = 4

// ponytail: presentational only; the caller owns durations and removal, so no timers here.
export function ToastTray({ toasts }: ToastTrayProps) {
  if (toasts.length === 0) return null
  return (
    <div role="status" aria-live="polite" className="flex w-[368px] flex-col gap-1">
      {toasts.slice(-MAX_SHOWN).map((t) => (
        <div
          key={t.id}
          className={`h-6 truncate rounded-sm bg-zinc-900/90 px-2 text-sm leading-6 ${
            t.priority === 'high' ? 'border-l-2 border-amber-400 text-zinc-100' : 'text-zinc-100'
          }`}
        >
          {t.text}
        </div>
      ))}
    </div>
  )
}
