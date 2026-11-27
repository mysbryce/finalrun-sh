import type { SettingAvailability, SettingValue } from '@/lib/ipc/protocol'
import { FIXED_BINDINGS, SETTINGS } from './schema'
import type { SettingEntry } from './schema'

/** Bindings whose Clear asks for confirmation first. */
export const MOVEMENT_AND_FIRE = ['bind_move_forward', 'bind_move_left', 'bind_move_back', 'bind_move_right', 'bind_fire']

/** Debug shortcuts form their own conflict context (same rule as Godot's `binding_conflict`). */
export function bindingContext(entry: SettingEntry): 'debug' | 'game' {
  return entry.capability === 'debug_shortcuts' ? 'debug' : 'game'
}

const BINDINGS = SETTINGS.filter((e) => e.type === 'binding')

/** The other binding key in the same context holding `code` (schema order), or null. `values` = draft merged over persisted. */
export function findConflict(key: string, code: string | null, values: Record<string, SettingValue>): string | null {
  if (code === null) return null
  const entry = BINDINGS.find((e) => e.key === key)
  if (!entry) return null
  const context = bindingContext(entry)
  for (const other of BINDINGS) {
    if (other.key === key || bindingContext(other) !== context) continue
    if (values[other.key] === code) return other.key
  }
  return null
}

/** False for fixed keys and keys the host would reject as unsupported. */
export function canUnbind(key: string, availability: SettingAvailability): boolean {
  return !FIXED_BINDINGS.includes(key) && availability.enabled
}
