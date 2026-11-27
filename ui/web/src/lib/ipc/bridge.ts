import type { HudState, PageToGodot } from './protocol'

declare global {
  interface Window {
    onIpcMessage?: (text: string) => void
    sendIpcMessage?: (text: string) => void
  }
}

export function send(msg: PageToGodot): void {
  if (window.sendIpcMessage) {
    window.sendIpcMessage(JSON.stringify(msg))
  } else {
    console.debug('[bridge] no host', msg)
  }
}

let nextId = 1
const pending = new Map<
  number,
  { resolve: (v: unknown) => void; reject: (e: Error) => void; timer: ReturnType<typeof setTimeout> }
>()

export function request<T>(
  method: string,
  params: Record<string, unknown> = {},
  timeoutMs = 5000,
): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    const id = nextId++
    const timer = setTimeout(() => {
      pending.delete(id)
      reject(new Error('timeout'))
    }, timeoutMs)
    pending.set(id, { resolve: resolve as (v: unknown) => void, reject, timer })
    send({ type: 'request', id, method, params })
  })
}

export type BridgeDeps = {
  setHud: (hud: HudState) => void
  navigate: (to: string) => void
}

export function handleMessage(text: string, deps: BridgeDeps): void {
  let msg: unknown
  try {
    msg = JSON.parse(text)
  } catch {
    console.warn('[bridge] bad json', text)
    return
  }
  if (typeof msg !== 'object' || msg === null) return
  const message = msg as { type?: unknown; [key: string]: unknown }
  switch (message.type) {
    case 'hud':
      deps.setHud(message.data as HudState)
      break
    case 'route':
      deps.navigate(message.to as string)
      break
    case 'reply': {
      const id = message.id as number
      const entry = pending.get(id)
      if (!entry) break
      clearTimeout(entry.timer)
      pending.delete(id)
      if (message.ok) {
        entry.resolve(message.data)
      } else {
        entry.reject(new Error((message.error as string | undefined) ?? 'request_failed'))
      }
      break
    }
    default:
      break
  }
}

export function installBridge(deps: BridgeDeps): void {
  window.onIpcMessage = (text) => handleMessage(text, deps)
  send({ type: 'ready' })
}
