import { useEffect, useId, useRef, useState } from 'react'
import type { KeyboardEvent } from 'react'

export interface DropdownOption {
  value: string
  label: string
  disabled?: boolean
  reason?: string
}

export interface DropdownProps {
  label: string
  value: string
  options: DropdownOption[]
  onChange: (v: string) => void
  disabled?: boolean
  error?: string
  placeholder?: string
}

export function Dropdown({ label, value, options, onChange, disabled = false, error, placeholder }: DropdownProps) {
  const baseId = useId()
  const labelId = `${baseId}-label`
  const errorId = `${baseId}-error`
  const optionId = (i: number) => `${baseId}-opt-${i}`
  const [open, setOpen] = useState(false)
  const [active, setActive] = useState(-1)
  const rootRef = useRef<HTMLDivElement>(null)
  const triggerRef = useRef<HTMLButtonElement>(null)
  const listRef = useRef<HTMLDivElement>(null)

  const current = options.find((o) => o.value === value)

  useEffect(() => {
    if (!open) return
    listRef.current?.focus()
    const onDown = (e: MouseEvent) => {
      if (!rootRef.current?.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', onDown)
    return () => document.removeEventListener('mousedown', onDown)
  }, [open])

  useEffect(() => {
    if (open && active >= 0) document.getElementById(`${baseId}-opt-${active}`)?.scrollIntoView?.({ block: 'nearest' })
  }, [open, active, baseId])

  const openMenu = () => {
    if (disabled) return
    const idx = options.findIndex((o) => o.value === value)
    setActive(idx >= 0 ? idx : options.findIndex((o) => !o.disabled))
    setOpen(true)
  }

  const close = () => {
    setOpen(false)
    triggerRef.current?.focus()
  }

  const choose = (i: number) => {
    const opt = options[i]
    if (!opt || opt.disabled) return
    onChange(opt.value)
    close()
  }

  // Next enabled index from `from` in direction `dir` without wrapping; `from` if none.
  const move = (from: number, dir: 1 | -1) => {
    for (let j = from + dir; j >= 0 && j < options.length; j += dir) {
      if (!options[j].disabled) return j
    }
    return from
  }

  const onTriggerKey = (e: KeyboardEvent<HTMLButtonElement>) => {
    if (e.key === 'ArrowDown' || e.key === 'Enter' || e.key === ' ') {
      e.preventDefault()
      openMenu()
    }
  }

  const onListKey = (e: KeyboardEvent<HTMLDivElement>) => {
    if (e.key === 'ArrowDown') setActive((a) => move(a, 1))
    else if (e.key === 'ArrowUp') setActive((a) => move(a, -1))
    else if (e.key === 'Home') setActive(move(-1, 1))
    else if (e.key === 'End') setActive(move(options.length, -1))
    else if (e.key === 'Enter' || e.key === ' ') choose(active)
    else if (e.key === 'Escape') close()
    else if (e.key === 'Tab') setOpen(false)
    else if (e.key.length === 1 && /\S/.test(e.key)) {
      const ch = e.key.toLowerCase()
      const n = options.length
      for (let i = 1; i <= n; i++) {
        const j = (active + i + n) % n
        if (!options[j].disabled && options[j].label.toLowerCase().startsWith(ch)) {
          setActive(j)
          break
        }
      }
    } else return
    if (e.key !== 'Tab') e.preventDefault()
  }

  return (
    <div ref={rootRef} className="relative inline-flex flex-col gap-1">
      <span id={labelId} className="text-sm leading-5 text-zinc-100">
        {label}
      </span>
      <button
        ref={triggerRef}
        type="button"
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-labelledby={`${labelId} ${baseId}-value`}
        aria-describedby={error ? errorId : undefined}
        disabled={disabled}
        onClick={() => (open ? setOpen(false) : openMenu())}
        onKeyDown={onTriggerKey}
        className={`flex h-9 min-w-[160px] items-center justify-between gap-2 rounded border bg-zinc-800 px-3 text-sm leading-5 text-zinc-100 transition duration-[80ms] hover:bg-zinc-700 focus-visible:focus-ring disabled:cursor-not-allowed disabled:opacity-60 ${
          error ? 'border-red-400' : 'border-zinc-500'
        }`}
      >
        <span
          id={`${baseId}-value`}
          className={`truncate${current === undefined && placeholder !== undefined ? ' text-zinc-400' : ''}`}
        >
          {current?.label ?? placeholder ?? ''}
        </span>
        <span aria-hidden="true" className="text-zinc-300">
          ▾
        </span>
      </button>
      {error && (
        <span id={errorId} className="text-xs leading-4 text-red-400">
          {error}
        </span>
      )}
      {open && (
        <div
          ref={listRef}
          role="listbox"
          tabIndex={-1}
          aria-labelledby={labelId}
          aria-activedescendant={active >= 0 ? optionId(active) : undefined}
          onKeyDown={onListKey}
          className="absolute top-full left-0 z-40 mt-1 max-h-[224px] min-w-full overflow-y-auto rounded border border-zinc-600 bg-zinc-900 py-1 outline-none"
        >
          {options.map((opt, i) => {
            const selected = opt.value === value
            return (
              <div
                key={opt.value}
                id={optionId(i)}
                role="option"
                aria-selected={selected}
                aria-disabled={opt.disabled || undefined}
                onMouseDown={(e) => e.preventDefault()}
                onMouseEnter={() => {
                  if (!opt.disabled) setActive(i)
                }}
                onClick={() => choose(i)}
                className={`flex h-8 items-center justify-between gap-3 border-l-2 px-3 text-sm leading-5 whitespace-nowrap ${
                  i === active ? 'border-amber-400 bg-zinc-800' : 'border-transparent'
                } ${opt.disabled ? 'cursor-not-allowed text-zinc-500' : 'cursor-pointer text-zinc-100'} ${
                  selected ? 'font-semibold' : ''
                }`}
              >
                <span>{opt.label}</span>
                {opt.disabled && opt.reason && <span className="text-xs leading-4 text-zinc-400">{opt.reason}</span>}
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
