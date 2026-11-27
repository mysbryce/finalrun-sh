import type { SettingsTab, SettingValue } from '@/lib/ipc/protocol'
import schemaJson from '../../../public/settings-schema.json'

export type SettingType =
  | 'boolean'
  | 'enum'
  | 'integer'
  | 'number'
  | 'device'
  | 'integer_array'
  | 'binding'
  | 'action'

/** One entry of public/settings-schema.json (copy of docs/ui-design/settings-schema.json). */
export type SettingEntry = {
  key: string
  tab: SettingsTab
  group: string
  type: SettingType
  default: SettingValue
  min: number | null
  max: number | null
  step: number | null
  options: string[]
  restart: boolean
  label: string
  storage: 'config_file' | 'session' | 'none'
  capability: string | null
  unavailable: 'hidden' | 'coming_later' | null
}

export const SETTINGS: SettingEntry[] = schemaJson as SettingEntry[]

export const TABS: { id: SettingsTab; label: string }[] = [
  { id: 'graphics', label: 'Graphics' },
  { id: 'controls', label: 'Controls' },
  { id: 'social', label: 'Social' },
  { id: 'others', label: 'Others' },
]

/** Binding keys that cannot be rebound or unbound. */
export const FIXED_BINDINGS = ['bind_look', 'bind_pause']

const BY_KEY = new Map(SETTINGS.map((e) => [e.key, e]))

export function entryFor(key: string): SettingEntry | undefined {
  return BY_KEY.get(key)
}

export function entriesFor(tab: SettingsTab): SettingEntry[] {
  return SETTINGS.filter((e) => e.tab === tab)
}

/** Group labels of a tab, in order of first appearance. */
export function groupsFor(tab: SettingsTab): string[] {
  const groups: string[] = []
  for (const e of entriesFor(tab)) {
    if (!groups.includes(e.group)) groups.push(e.group)
  }
  return groups
}

export function defaultsFor(keys: string[]): Record<string, SettingValue> {
  const out: Record<string, SettingValue> = {}
  for (const key of keys) {
    const e = BY_KEY.get(key)
    if (e) out[key] = e.default
  }
  return out
}
