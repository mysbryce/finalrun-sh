import type { SettingAvailability, SettingsValues, SettingsView } from '@/lib/ipc/protocol'
import { SETTINGS } from './schema'

function hiddenReason(capability: string): SettingAvailability['reason'] {
  if (capability === 'voice_chat') return 'requires_voice'
  if (capability === 'debug_shortcuts') return 'debug_only'
  if (capability.endsWith('_backend')) return 'requires_backend'
  return 'unsupported'
}

/** Schema capability decision rules with every feature gate absent. */
export function demoCapabilities(): SettingsView['capabilities'] {
  const out: SettingsView['capabilities'] = {}
  for (const e of SETTINGS) {
    if (e.capability === null) continue
    if (e.unavailable === 'coming_later') out[e.key] = { visible: true, enabled: false, reason: 'coming_later' }
    else if (e.unavailable === 'hidden') out[e.key] = { visible: false, enabled: false, reason: hiddenReason(e.capability) }
  }
  return out
}

const values: SettingsValues = Object.fromEntries(SETTINGS.filter((e) => e.type !== 'action').map((e) => [e.key, e.default]))

export const DEMO_SETTINGS: SettingsView = {
  values,
  revision: 1,
  capabilities: demoCapabilities(),
  devices: { input: [], output: [] },
  displayModes: ['windowed', 'borderless', 'fullscreen'],
  pendingRestart: [],
  preview: null,
  saveError: null,
}
