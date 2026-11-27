import { useEffect, useRef, useState } from 'react'
import { request } from '@/lib/ipc/bridge'
import type { SettingsView, SettingValue } from '@/lib/ipc/protocol'
import { Button } from '@/lib/ui/Button'
import { Modal } from '@/lib/ui/Modal'
import { MOVEMENT_AND_FIRE, canUnbind, findConflict } from './bindings'
import { bindingText } from './format'
import { ALWAYS_AVAILABLE, BINDING_CHIP } from './SettingRow'
import { entryFor } from './schema'
import type { SettingEntry } from './schema'

export interface CaptureDialogProps {
  entry: SettingEntry
  /** Draft merged over persisted values. */
  values: Record<string, SettingValue>
  capabilities: SettingsView['capabilities']
  onStage: (patch: Record<string, SettingValue>) => void
  onClose: () => void
}

type View = 'capture' | 'conflict' | 'confirm' | 'error'

/** Host cancels the capture after this many seconds (docs/ui-design/DATA_CONTRACTS.md `settings.capture`). */
const HOST_SECONDS = 15
const REQUEST_TIMEOUT_MS = 20000

const ERROR_TEXT: Record<string, string> = {
  busy: 'Another rebind is in progress.',
  not_available: 'Rebinding is not available right now.',
}

export function CaptureDialog({ entry, values, capabilities, onStage, onClose }: CaptureDialogProps) {
  const [view, setView] = useState<View>('capture')
  const [seconds, setSeconds] = useState(HOST_SECONDS)
  const [conflict, setConflict] = useState<{ code: string; other: string } | null>(null)
  const [error, setError] = useState<string | null>(null)
  const pendingRef = useRef(false)

  const key = entry.key
  const current = typeof values[key] === 'string' ? (values[key] as string) : null

  const cancelCapture = () => {
    if (!pendingRef.current) return
    pendingRef.current = false
    void request('settings.capture_cancel').catch(() => undefined)
  }

  const handleCode = (code: string | null) => {
    if (code === null || code === current) {
      onClose()
      return
    }
    const other = findConflict(key, code, values)
    if (other !== null) {
      setConflict({ code, other })
      setView('conflict')
      return
    }
    onStage({ [key]: code })
    onClose()
  }
  // The capture reply arrives later; it must act on the latest props.
  const handleRef = useRef(handleCode)
  handleRef.current = handleCode

  useEffect(() => {
    let live = true
    pendingRef.current = true
    request<{ binding?: unknown }>('settings.capture', { key }, REQUEST_TIMEOUT_MS)
      .then((reply) => {
        if (!live || !pendingRef.current) return
        pendingRef.current = false
        handleRef.current(typeof reply?.binding === 'string' ? reply.binding : null)
      })
      .catch((e: unknown) => {
        if (!live || !pendingRef.current) return
        pendingRef.current = false
        setError(e instanceof Error ? e.message : 'capture_failed')
        setView('error')
      })
    return () => {
      live = false
      cancelCapture()
    }
  }, [key])

  useEffect(() => {
    if (view !== 'capture') return
    const id = setInterval(() => setSeconds((s) => (s > 0 ? s - 1 : 0)), 1000)
    return () => clearInterval(id)
  }, [view])

  const cancel = () => {
    cancelCapture()
    onClose()
  }
  const useLeftClick = () => {
    cancelCapture()
    handleCode('MouseLeft')
  }
  const clear = () => {
    cancelCapture()
    if (current === null) {
      onClose()
      return
    }
    if (!MOVEMENT_AND_FIRE.includes(key)) {
      onStage({ [key]: null })
      onClose()
      return
    }
    setView('confirm')
  }

  if (view === 'conflict' && conflict) {
    const otherLabel = entryFor(conflict.other)?.label ?? conflict.other
    const replaceable = canUnbind(conflict.other, capabilities[conflict.other] ?? ALWAYS_AVAILABLE)
    return (
      <Modal
        key={view}
        title="Key already in use"
        primary={{
          label: 'Replace',
          disabled: !replaceable,
          onPress: () => {
            onStage({ [key]: conflict.code, [conflict.other]: null })
            onClose()
          },
        }}
        secondary={{ label: 'Cancel', onPress: onClose }}
        dismissible
        onDismiss={onClose}
      >
        <p className="m-0">{`${bindingText(conflict.code)} is used by ${otherLabel}.`}</p>
        {!replaceable && <p className="mt-2 mb-0 text-zinc-300">That action cannot be unbound.</p>}
      </Modal>
    )
  }

  if (view === 'confirm') {
    return (
      <Modal
        key={view}
        title={`Leave ${entry.label} unbound?`}
        primary={{
          label: 'Unbind',
          onPress: () => {
            onStage({ [key]: null })
            onClose()
          },
        }}
        secondary={{ label: 'Keep', onPress: onClose }}
        dismissible
        onDismiss={onClose}
      >
        {`${entry.label} will have no input until you bind it again.`}
      </Modal>
    )
  }

  if (view === 'error') {
    return (
      <Modal key={view} title={`Rebind ${entry.label}`} primary={{ label: 'Close', onPress: onClose }} dismissible onDismiss={onClose}>
        {(error !== null && ERROR_TEXT[error]) || 'Could not capture input.'}
      </Modal>
    )
  }

  return (
    <Modal key={view} title={`Rebind ${entry.label}`} primary={{ label: 'Cancel', onPress: cancel }} dismissible onDismiss={cancel}>
      <div className="flex flex-col gap-2">
        <p className="m-0">Press a key or mouse button. Esc cancels.</p>
        <div className="flex h-7 items-center gap-2">
          <span className="text-zinc-300">Current:</span>
          <span className={BINDING_CHIP}>{bindingText(current)}</span>
          <span aria-live="polite" className="ml-auto text-zinc-300 tabular-nums">
            {`${seconds} s`}
          </span>
        </div>
        <div className="flex gap-2">
          <Button label="Use left click" variant="secondary" size="compact" onPress={useLeftClick} />
          <Button label="Clear" variant="secondary" size="compact" onPress={clear} />
        </div>
      </div>
    </Modal>
  )
}
