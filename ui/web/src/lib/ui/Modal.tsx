import { useEffect, useId, useRef } from 'react'
import type { KeyboardEvent, ReactNode } from 'react'
import { Button } from './Button'

export interface ModalProps {
  title: string
  children?: ReactNode
  primary: { label: string; onPress: () => void; busy?: boolean }
  secondary?: { label: string; onPress: () => void }
  dismissible?: boolean
  onDismiss?: () => void
}

const FOCUSABLE = 'button:not([disabled]), [href], input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'

export function Modal({ title, children, primary, secondary, dismissible = false, onDismiss }: ModalProps) {
  const titleId = useId()
  const dialogRef = useRef<HTMLDivElement>(null)
  const actionsRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const opener = document.activeElement as HTMLElement | null
    // Actions render secondary first, primary last: focus the safest available.
    actionsRef.current?.querySelector('button')?.focus()
    return () => {
      opener?.focus?.()
    }
  }, [])

  function onKeyDown(e: KeyboardEvent<HTMLDivElement>) {
    if (e.key === 'Escape') {
      if (dismissible) {
        e.preventDefault()
        onDismiss?.()
      }
      return
    }
    if (e.key !== 'Tab' || !dialogRef.current) return
    const items = Array.from(dialogRef.current.querySelectorAll<HTMLElement>(FOCUSABLE))
    if (items.length === 0) {
      e.preventDefault()
      return
    }
    const first = items[0]
    const last = items[items.length - 1]
    const active = document.activeElement
    if (e.shiftKey && (active === first || !dialogRef.current.contains(active))) {
      e.preventDefault()
      last.focus()
    } else if (!e.shiftKey && (active === last || !dialogRef.current.contains(active))) {
      e.preventDefault()
      first.focus()
    }
  }

  return (
    <div className="fixed inset-0 z-60 bg-zinc-950/55">
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onKeyDown={onKeyDown}
        className="absolute top-[232px] left-[384px] flex h-[256px] w-[512px] flex-col rounded-lg bg-zinc-900 p-6 text-zinc-100 shadow-[0_0_12px_rgba(0,0,0,0.5)]"
      >
        <h2 id={titleId} className="m-0 text-lg leading-6 font-semibold">
          {title}
        </h2>
        <div className="mt-3 min-h-0 flex-1 text-sm leading-5">{children}</div>
        <div ref={actionsRef} className="flex justify-end gap-2">
          {secondary && <Button label={secondary.label} variant="secondary" onPress={secondary.onPress} />}
          <Button label={primary.label} variant="primary" loading={primary.busy} onPress={primary.onPress} />
        </div>
      </div>
    </div>
  )
}
