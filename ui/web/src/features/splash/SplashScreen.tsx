import { useEffect, useRef, useState } from 'react'
import type { CSSProperties } from 'react'
import { request } from '@/lib/ipc/bridge'
import { Button } from '@/lib/ui/Button'
import { KeyHint } from '@/lib/ui/KeyHint'
import { ProgressBar } from '@/lib/ui/ProgressBar'
import { StageRail } from '@/lib/ui/StageRail'
import { errorText, stageLabel, stagesOf } from './bootCopy'
import { useSplashStore } from './splashStore'

/** Absolute box in base px (docs/ui-design/01-splash.md layout table). */
const box = (left: number, top: number, width: number, height: number): CSSProperties => ({
  position: 'absolute',
  left,
  top,
  width,
  height,
})

export function SplashScreen() {
  const boot = useSplashStore((s) => s.boot)
  const [retrying, setRetrying] = useState(false)
  const retryRef = useRef<HTMLDivElement>(null)
  const failed = boot?.phase === 'failed'
  const canSkip = boot?.canSkipTitle ?? false

  useEffect(() => {
    if (failed) retryRef.current?.querySelector('button')?.focus()
  }, [failed])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Enter' && canSkip) void request('boot.skip')
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [canSkip])

  if (!boot) return null

  const retry = () => {
    setRetrying(true)
    void request('boot.retry')
      .catch(() => undefined)
      .finally(() => setRetrying(false))
  }
  const quit = () => {
    void request('app.quit')
  }

  const busy = boot.progress === null && boot.phase !== 'ready' && !failed
  return (
    <div className="pointer-events-auto absolute inset-0 bg-zinc-950 text-zinc-100">
      <div style={box(400, 208, 480, 128)}>
        <div style={box(32, 16, 416, 24)} className="text-xs leading-6 font-semibold uppercase tracking-wider text-zinc-300">
          FinalRun
        </div>
        <h1 style={box(32, 50, 416, 56)} className="text-[48px] leading-[56px] font-bold">
          FinalRun
        </h1>
      </div>

      <div style={box(400, 368, 480, 120)}>
        <div style={box(16, 12, 448, 24)} className="text-base leading-6 font-semibold" aria-live="polite">
          {stageLabel(boot)}
        </div>
        <div style={box(16, 44, 448, 12)}>
          {busy && <ProgressBar label={stageLabel(boot)} max={1} />}
          {boot.progress !== null && !failed && (
            <ProgressBar label={stageLabel(boot)} value={boot.progress.done} max={boot.progress.total} />
          )}
        </div>
        <div style={box(16, 72, 448, 32)} className="text-sm leading-5 text-zinc-300" role={failed ? 'alert' : undefined}>
          {failed && boot.error ? errorText(boot.error) : ''}
        </div>
      </div>

      {failed && (
        <>
          <div ref={retryRef} style={box(416, 504, 216, 40)} className="grid [&>button]:w-full">
            <Button label="Retry" variant="primary" loading={retrying} onPress={retry} />
          </div>
          <div style={box(648, 504, 216, 40)} className="grid [&>button]:w-full">
            <Button label="Quit" variant="secondary" onPress={quit} />
          </div>
        </>
      )}

      <div style={box(416, 556, 448, 40)}>
        <StageRail stages={stagesOf(boot)} />
      </div>

      {canSkip && (
        <div style={box(24, 664, 248, 32)} className="flex items-center text-zinc-300">
          <KeyHint k="Enter" label="Skip" />
        </div>
      )}

      <div style={box(1008, 664, 248, 32)} className="flex items-center justify-end text-[11px] leading-4 text-zinc-300">
        {`Build ${boot.buildId}`}
      </div>
    </div>
  )
}
