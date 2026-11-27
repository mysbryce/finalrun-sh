import { useEffect, useRef, useState } from 'react'
import type { HeistAlertView } from '@/lib/ipc/protocol'
import { heistText } from './components/HeistAlert'

type HeistToast = { text: string; endsAt: number }

// Starts the heist toast once per alert id, for the snapshot's toastSecondsLeft,
// and counts it down locally. Later snapshots with the same id never restart it.
export function useHeistToast(alert: HeistAlertView | null | undefined): string | null {
  const [toast, setToast] = useState<HeistToast | null>(null)
  const seenId = useRef<string | null>(null)
  const id = alert?.id ?? null
  const seconds = alert?.toastSecondsLeft ?? 0
  const text = alert ? heistText(alert) : ''

  useEffect(() => {
    if (id === null || id === seenId.current) return
    seenId.current = id
    setToast(seconds > 0 ? { text, endsAt: Date.now() + seconds * 1000 } : null)
  }, [id, seconds, text])

  useEffect(() => {
    if (!toast) return
    const timer = setTimeout(() => setToast(null), Math.max(0, toast.endsAt - Date.now()))
    return () => clearTimeout(timer)
  }, [toast])

  return toast?.text ?? null
}
