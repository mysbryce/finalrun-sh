import type { ReactNode } from 'react'

export interface HeaderBarProps {
  title: string
  subtitle?: string
  leading?: ReactNode
  trailing?: ReactNode
  compact?: boolean
}

export function HeaderBar({ title, subtitle, leading, trailing, compact = false }: HeaderBarProps) {
  return (
    <header className={`flex items-center gap-3 ${compact ? 'h-9' : 'h-14'}`}>
      {leading}
      <div className="flex min-w-0 flex-col">
        <h2 className="m-0 text-lg leading-6 font-semibold text-zinc-100">{title}</h2>
        {subtitle !== undefined && <p className="m-0 text-xs leading-4 text-zinc-300">{subtitle}</p>}
      </div>
      {trailing !== undefined && <div className="ml-auto flex items-center gap-3">{trailing}</div>}
    </header>
  )
}
