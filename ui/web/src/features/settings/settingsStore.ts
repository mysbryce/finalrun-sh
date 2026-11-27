import { create } from 'zustand'
import { request } from '@/lib/ipc/bridge'
import type { SettingsValues, SettingsView, SettingValue } from '@/lib/ipc/protocol'
import { applyPreset, withManualChange } from './presets'
import { SETTINGS, defaultsFor, entryFor } from './schema'

type Values = Record<string, SettingValue>

type SettingsStore = {
  view: SettingsView | null
  /** Only keys whose staged value differs from the persisted value. */
  draft: Values
  /** Revision the draft was edited against. */
  baseRevision: number | null
  /** Draft keys dropped by a rebase because their persisted value changed elsewhere. */
  conflicts: string[]
  pending: boolean
  /** Error code of the last failed apply (`stale_revision`, `binding_conflict`, ...). */
  error: string | null
  setView: (view: SettingsView) => void
  edit: (key: string, value: SettingValue) => void
  discard: () => void
  stageDefaults: (keys: string[]) => void
  changedKeys: () => string[]
  patch: () => SettingsValues
  apply: () => Promise<void>
}

function same(a: SettingValue | undefined, b: SettingValue | undefined): boolean {
  return JSON.stringify(a) === JSON.stringify(b)
}

/** Persisted value of `key`: the view value, else the schema default. */
export function persistedValue(view: SettingsView | null, key: string): SettingValue {
  const v = view?.values[key]
  return v !== undefined ? v : (entryFor(key)?.default ?? null)
}

function persistedAll(view: SettingsView | null): Values {
  const out: Values = {}
  for (const e of SETTINGS) out[e.key] = persistedValue(view, e.key)
  return out
}

/** Keeps only the entries of `next` that differ from the persisted values. */
function diff(next: Values, view: SettingsView | null): Values {
  const out: Values = {}
  for (const [key, value] of Object.entries(next)) {
    if (!same(value, persistedValue(view, key))) out[key] = value
  }
  return out
}

/** Current value shown for `key`: draft first, then persisted. */
export function effectiveValue(view: SettingsView | null, draft: Values, key: string): SettingValue {
  return key in draft ? draft[key] : persistedValue(view, key)
}

export const useSettingsStore = create<SettingsStore>((set, get) => ({
  view: null,
  draft: {},
  baseRevision: null,
  conflicts: [],
  pending: false,
  error: null,
  setView: (view) => {
    const { view: prev, draft, baseRevision, conflicts } = get()
    if (prev === null || baseRevision === null || view.revision === baseRevision) {
      set({ view, baseRevision: view.revision, draft: diff(draft, view) })
      return
    }
    // Rebase: keep draft values only where the persisted value did not change.
    const kept: Values = {}
    const dropped: string[] = []
    for (const [key, value] of Object.entries(draft)) {
      const before = persistedValue(prev, key)
      const after = persistedValue(view, key)
      if (same(before, after)) kept[key] = value
      else if (!same(value, after)) dropped.push(key)
    }
    set({
      view,
      baseRevision: view.revision,
      draft: diff(kept, view),
      conflicts: dropped.length > 0 ? dropped : conflicts,
    })
  },
  edit: (key, value) => {
    const { view, draft } = get()
    const current = { ...persistedAll(view), ...draft }
    const next = key === 'quality_preset' ? applyPreset(current, String(value)) : withManualChange(current, key, value)
    set({ draft: diff(next, view), error: null })
  },
  discard: () => set({ draft: {}, conflicts: [], error: null }),
  stageDefaults: (keys) => {
    const { view, draft } = get()
    set({ draft: diff({ ...draft, ...defaultsFor(keys) }, view), error: null })
  },
  changedKeys: () => Object.keys(get().draft),
  patch: () => ({ ...get().draft }),
  apply: async () => {
    const { view, pending, baseRevision } = get()
    if (view === null || pending || get().changedKeys().length === 0) return
    set({ pending: true, error: null })
    try {
      await request('settings.apply', { revision: baseRevision ?? view.revision, patch: get().patch() })
      set({ pending: false })
    } catch (e) {
      set({ pending: false, error: e instanceof Error ? e.message : 'apply_failed' })
    }
  },
}))
