import { useRef, useState } from 'react'
import type { CSSProperties, KeyboardEvent } from 'react'
import { request } from '@/lib/ipc/bridge'
import type { SettingsTab, SettingsView } from '@/lib/ipc/protocol'
import { Button } from '@/lib/ui/Button'
import { Modal } from '@/lib/ui/Modal'
import { TabBar } from '@/lib/ui/TabBar'
import { ALWAYS_AVAILABLE, SettingRow } from './SettingRow'
import { SETTINGS, TABS, entriesFor, entryFor } from './schema'
import { effectiveValue, useSettingsStore } from './settingsStore'

/** Absolute box in base px, relative to the parent (docs/ui-design/03-settings.md, Graphics layout A01-A29). */
const box = (left: number, top: number, width: number, height: number): CSSProperties => ({
  position: 'absolute',
  left,
  top,
  width,
  height,
})

const BTN = 'grid [&>button]:w-full'

const ERROR_TEXT: Record<string, string> = {
  stale_revision: 'Settings changed elsewhere. Your other changes were kept.',
  binding_conflict: 'Two actions use the same key.',
  save_failed: 'Could not save settings.',
}

function statusText(
  view: SettingsView | null,
  pending: boolean,
  error: string | null,
  changes: number,
): string {
  if (view === null) return 'Loading settings'
  let text: string
  if (pending) text = 'Applying'
  else if (error !== null) text = ERROR_TEXT[error] ?? 'Could not apply settings.'
  else if (changes > 0) text = changes === 1 ? '1 change' : `${changes} changes`
  else text = 'Saved'
  if (view.pendingRestart.length > 0) {
    const labels = view.pendingRestart.map((k) => entryFor(k)?.label ?? k)
    text += ` · Restart needed for: ${labels.join(', ')}`
  }
  return text
}

function prefersReducedMotion(): boolean {
  return typeof window.matchMedia === 'function' && window.matchMedia('(prefers-reduced-motion: reduce)').matches
}

type Confirm = 'back' | 'reset' | null

export function SettingsScreen({ tab }: { tab: SettingsTab }) {
  const view = useSettingsStore((s) => s.view)
  const draft = useSettingsStore((s) => s.draft)
  const conflicts = useSettingsStore((s) => s.conflicts)
  const pending = useSettingsStore((s) => s.pending)
  const error = useSettingsStore((s) => s.error)
  const { edit, discard, stageDefaults, apply } = useSettingsStore.getState()
  const [confirm, setConfirm] = useState<Confirm>(null)
  const listRef = useRef<HTMLDivElement>(null)

  const changes = Object.keys(draft).length
  const dirty = changes > 0
  const ready = view !== null
  const tabLabel = TABS.find((t) => t.id === tab)?.label ?? tab

  const availability = (key: string) => view?.capabilities[key] ?? ALWAYS_AVAILABLE
  const rows = entriesFor(tab).filter((e) => availability(e.key).visible)
  const groups: string[] = []
  for (const e of rows) if (!groups.includes(e.group)) groups.push(e.group)

  const close = () => {
    void request('settings.close').catch(() => undefined)
  }
  const back = () => {
    if (pending) return
    if (dirty) setConfirm('back')
    else close()
  }
  const selectTab = (id: string) => {
    if (pending || id === tab) return
    void request('settings.tab', { tab: id }).catch(() => undefined)
  }
  const scrollToGroup = (group: string) => {
    const list = listRef.current
    const first = rows.find((e) => e.group === group)
    const row = first ? list?.querySelector<HTMLElement>(`[data-setting="${first.key}"]`) : null
    if (!list || !row) return
    // The list is positioned, so the row's offsetTop is relative to it.
    list.scrollTo?.({ top: row.offsetTop, behavior: prefersReducedMotion() ? 'auto' : 'smooth' })
  }
  const onReset = (which: 'controls' | 'all') => {
    const keys = SETTINGS.filter((e) => e.type !== 'action' && (which === 'all' || e.tab === 'controls')).map((e) => e.key)
    stageDefaults(keys)
  }
  const resetTab = () => {
    stageDefaults(entriesFor(tab).filter((e) => e.type !== 'action').map((e) => e.key))
    setConfirm(null)
  }
  const onKeyDown = (e: KeyboardEvent<HTMLDivElement>) => {
    if (e.key === 'Escape' && !e.defaultPrevented && confirm === null) {
      e.preventDefault()
      back()
    }
  }

  const voiceLocked = effectiveValue(view, draft, 'voice_mode') !== 'open_mic'

  return (
    <div className="pointer-events-auto absolute inset-0 bg-zinc-950 text-zinc-100" onKeyDown={onKeyDown}>
      <header style={box(96, 32, 1088, 56)}>
        <div style={box(16, 8, 96, 40)} className={BTN}>
          <Button label="Back" variant="secondary" disabled={pending} onPress={back} />
        </div>
        <h1 style={box(128, 8, 584, 40)} tabIndex={-1} className="m-0 flex items-center text-2xl leading-8 font-bold">
          Settings
        </h1>
        <div style={box(880, 8, 192, 40)} className="flex items-center justify-end text-xs leading-4 text-zinc-300">
          Changes apply after Apply
        </div>
      </header>

      <div style={box(96, 100, 1088, 44)}>
        <TabBar
          label="Settings sections"
          tabs={TABS.map((t) => ({ id: t.id, label: t.label, disabled: pending }))}
          selectedId={tab}
          onSelect={selectTab}
        />
      </div>

      <section style={box(96, 156, 1088, 464)} aria-label={`${tabLabel} settings`} className="rounded-md bg-zinc-900">
        <nav style={box(16, 16, 184, 432)} aria-label="Setting groups" className="flex flex-col gap-1">
          {ready &&
            groups.map((g) => (
              <button
                key={g}
                type="button"
                onClick={() => scrollToGroup(g)}
                className="h-9 w-[184px] shrink-0 truncate rounded px-3 text-left text-sm leading-5 text-zinc-300 transition duration-[80ms] hover:bg-zinc-800 hover:text-zinc-100 focus-visible:focus-ring"
              >
                {g}
              </button>
            ))}
        </nav>
        <div
          ref={listRef}
          style={box(216, 16, 856, 432)}
          aria-busy={!ready}
          className="relative flex flex-col gap-1 overflow-y-auto pr-2"
        >
          {!ready &&
            Array.from({ length: 8 }, (_, i) => (
              <div key={i} data-skeleton className="flex h-12 shrink-0 items-center gap-4 rounded-sm bg-zinc-900 pl-4">
                <div className="h-4 w-[200px] rounded bg-zinc-800" />
                <div className="ml-[112px] h-9 w-[496px] rounded bg-zinc-800" />
              </div>
            ))}
          {ready &&
            rows.map((e) => (
              <SettingRow
                key={e.key}
                entry={e}
                value={effectiveValue(view, draft, e.key)}
                changed={e.key in draft}
                conflict={conflicts.includes(e.key)}
                availability={availability(e.key)}
                devices={view.devices}
                locked={pending || (e.key === 'voice_input_threshold' && voiceLocked)}
                onChange={(v) => edit(e.key, v)}
                onReset={onReset}
              />
            ))}
        </div>
      </section>

      <footer style={box(96, 632, 1088, 56)}>
        <div
          style={box(16, 8, 648, 40)}
          role="status"
          className={`flex items-center truncate text-sm leading-5 ${error !== null && !pending ? 'text-red-400' : 'text-zinc-300'}`}
        >
          {statusText(view, pending, error, changes)}
        </div>
        <div style={box(688, 8, 120, 40)} className={BTN}>
          <Button label="Reset" variant="secondary" disabled={!ready || pending} onPress={() => setConfirm('reset')} />
        </div>
        <div style={box(816, 8, 120, 40)} className={BTN}>
          <Button label="Discard" variant="secondary" disabled={!ready || pending || !dirty} onPress={discard} />
        </div>
        <div style={box(944, 8, 128, 40)} className={BTN}>
          <Button
            label="Apply"
            variant="primary"
            disabled={!ready || !dirty}
            loading={pending}
            onPress={() => void apply()}
          />
        </div>
      </footer>

      {confirm === 'back' && (
        <Modal
          title="Discard changes?"
          primary={{
            label: 'Discard',
            onPress: () => {
              setConfirm(null)
              discard()
              close()
            },
          }}
          secondary={{ label: 'Keep editing', onPress: () => setConfirm(null) }}
          dismissible
          onDismiss={() => setConfirm(null)}
        >
          {`${changes} unsaved ${changes === 1 ? 'change' : 'changes'} will be lost.`}
        </Modal>
      )}
      {confirm === 'reset' && (
        <Modal
          title={`Reset ${tabLabel} settings?`}
          primary={{ label: 'Reset', onPress: resetTab }}
          secondary={{ label: 'Cancel', onPress: () => setConfirm(null) }}
          dismissible
          onDismiss={() => setConfirm(null)}
        >
          Defaults are staged. Apply saves them.
        </Modal>
      )}
    </div>
  )
}
