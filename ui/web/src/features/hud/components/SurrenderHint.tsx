import { KeyHint } from '@/lib/ui/KeyHint'
import { SURRENDER_HINT } from '../layout'

export function SurrenderHint({ keyLabel }: { keyLabel?: string }) {
  return (
    <div
      className="absolute left-1/2 flex -translate-x-1/2 items-center justify-center rounded-md bg-zinc-950/60 ring-1 ring-white/10"
      style={{ top: SURRENDER_HINT.top, width: SURRENDER_HINT.width, height: SURRENDER_HINT.height }}
    >
      <KeyHint k={keyLabel ?? 'H'} label="Surrender" />
    </div>
  )
}
