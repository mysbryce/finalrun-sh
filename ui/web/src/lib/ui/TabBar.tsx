import { useRef } from 'react'
import type { KeyboardEvent } from 'react'

export interface TabItem {
  id: string
  label: string
  disabled?: boolean
  error?: boolean
}

export interface TabBarProps {
  tabs: TabItem[]
  selectedId: string
  onSelect: (id: string) => void
  label: string
}

export function TabBar({ tabs, selectedId, onSelect, label }: TabBarProps) {
  const refs = useRef<(HTMLButtonElement | null)[]>([])

  const go = (index: number) => {
    const tab = tabs[index]
    if (!tab || tab.disabled) return
    refs.current[index]?.focus()
    onSelect(tab.id)
  }

  // Next enabled index from `from` in direction `dir`, wrapping; -1 if none.
  const step = (from: number, dir: 1 | -1) => {
    const n = tabs.length
    for (let i = 1; i <= n; i++) {
      const j = (((from + dir * i) % n) + n) % n
      if (!tabs[j].disabled) return j
    }
    return -1
  }

  const onKeyDown = (e: KeyboardEvent<HTMLButtonElement>, index: number) => {
    let target = -1
    if (e.key === 'ArrowRight') target = step(index, 1)
    else if (e.key === 'ArrowLeft') target = step(index, -1)
    else if (e.key === 'Home') target = step(-1, 1)
    else if (e.key === 'End') target = step(tabs.length, -1)
    else return
    e.preventDefault()
    if (target >= 0) go(target)
  }

  return (
    <div role="tablist" aria-label={label} className="flex h-11 border-b border-zinc-700">
      {tabs.map((tab, i) => {
        const selected = tab.id === selectedId
        return (
          <button
            key={tab.id}
            ref={(el) => {
              refs.current[i] = el
            }}
            type="button"
            role="tab"
            aria-selected={selected}
            aria-disabled={tab.disabled || undefined}
            tabIndex={selected ? 0 : -1}
            onClick={() => {
              if (!tab.disabled) onSelect(tab.id)
            }}
            onKeyDown={(e) => onKeyDown(e, i)}
            className={`flex-1 border-b-2 px-3 text-sm leading-5 font-semibold transition duration-[80ms] focus-visible:focus-ring ${
              selected ? 'border-amber-400 text-zinc-100' : 'border-transparent text-zinc-300'
            } ${tab.disabled ? 'cursor-not-allowed opacity-60' : selected ? '' : 'hover:bg-zinc-800'}`}
          >
            {tab.label}
            {tab.error && (
              <>
                <span aria-hidden="true"> !</span>
                <span className="sr-only"> (error)</span>
              </>
            )}
          </button>
        )
      })}
    </div>
  )
}
