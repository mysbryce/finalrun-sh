import type { CSSProperties, ReactNode } from 'react'

export interface PanelProps {
  title?: string
  children?: ReactNode
  inset?: number
  busy?: boolean
  className?: string
  style?: CSSProperties
}

export function Panel({ title, children, inset = 16, busy = false, className = '', style }: PanelProps) {
  return (
    <section
      aria-label={title}
      aria-busy={busy}
      className={`rounded-md bg-zinc-900 ${className}`}
      style={{ padding: inset, ...style }}
    >
      {busy ? <div className="opacity-60">{children}</div> : children}
    </section>
  )
}
