import { useEffect, useState } from 'react'
import { request } from '@/lib/ipc/bridge'
import { Modal } from '@/lib/ui/Modal'

export interface DisplayPreviewDialogProps {
  preview: { token: string; secondsLeft: number }
  /** Error code of a failed `settings.display_confirm` (not called for `preview_expired`). */
  onError: (code: string) => void
}

/**
 * Keep / revert dialog for a display preview (docs/ui-design/03-settings.md, "Display preview").
 * The host snapshot closes it (`preview === null`); the parent keys it by token to reset the countdown.
 */
export function DisplayPreviewDialog({ preview, onError }: DisplayPreviewDialogProps) {
  const [left, setLeft] = useState(preview.secondsLeft)
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    // The host reverts on its own timer; the local countdown only stops at 0.
    if (left <= 0) return
    const t = setTimeout(() => setLeft((n) => n - 1), 1000)
    return () => clearTimeout(t)
  }, [left])

  const confirm = (keep: boolean) => {
    // Modal's secondary button has no disabled state, so a second press is ignored here.
    if (busy) return
    setBusy(true)
    request('settings.display_confirm', { token: preview.token, keep })
      .catch((e: unknown) => {
        const code = e instanceof Error ? e.message : 'apply_failed'
        if (code !== 'preview_expired') onError(code)
      })
      .finally(() => setBusy(false))
  }

  const announce =
    preview.secondsLeft > 5 && left <= 5
      ? '5 seconds left.'
      : `Display preview. Keep these settings within ${preview.secondsLeft} seconds.`

  return (
    <Modal
      title="Keep display settings?"
      primary={{ label: 'Keep', onPress: () => confirm(true), busy }}
      secondary={{ label: 'Revert', onPress: () => confirm(false) }}
      dismissible
      onDismiss={() => confirm(false)}
    >
      <p aria-hidden="true" className="m-0">
        Reverting in {left} s.
      </p>
      <div aria-live="polite" className="sr-only">
        {announce}
      </div>
    </Modal>
  )
}
