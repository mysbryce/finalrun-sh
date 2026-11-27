import { useState } from 'react'
import type { ReactNode } from 'react'
import type { SettingAvailability, SettingsView, SettingValue } from '@/lib/ipc/protocol'
import { Button } from '@/lib/ui/Button'
import { Dropdown } from '@/lib/ui/Dropdown'
import type { DropdownOption } from '@/lib/ui/Dropdown'
import { Modal } from '@/lib/ui/Modal'
import { Slider } from '@/lib/ui/Slider'
import { Toggle } from '@/lib/ui/Toggle'
import { bindingText, optionLabel, valueText } from './format'
import type { SettingEntry } from './schema'

export const ALWAYS_AVAILABLE: SettingAvailability = { visible: true, enabled: true, reason: null }

export interface SettingRowProps {
  entry: SettingEntry
  value: SettingValue
  changed: boolean
  conflict: boolean
  availability: SettingAvailability
  devices: SettingsView['devices']
  /** Extra lock (applying, or a dependency such as Open Mic). */
  locked: boolean
  onChange: (value: SettingValue) => void
  /** Stages defaults for the keys an action row resets. */
  onReset: (which: 'controls' | 'all') => void
}

// The lib controls render their own label; the row draws the visible label column, so theirs become sr-only.
const OWN_LABEL_SR = '[&>div>span:first-child]:sr-only [&>div>div:first-child]:sr-only'

function deviceOptions(devices: SettingsView['devices'], key: string): DropdownOption[] {
  const list = key === 'voice_input_device' ? devices.input : devices.output
  return [
    { value: 'system_default', label: 'System default' },
    ...list
      .filter((d) => d.id !== 'system_default')
      .map((d) => ({
        value: d.id,
        label: d.available ? d.label : `${d.label} (disconnected)`,
        disabled: !d.available,
        reason: d.available ? undefined : 'Not available',
      })),
  ]
}

type Confirm = 'reset_controls' | 'reset_all' | 'credits' | null

export function SettingRow({
  entry,
  value,
  changed,
  conflict,
  availability,
  devices,
  locked,
  onChange,
  onReset,
}: SettingRowProps) {
  const [confirm, setConfirm] = useState<Confirm>(null)
  if (!availability.visible) return null
  const disabled = !availability.enabled || locked
  const ownLabel = entry.type === 'boolean' || entry.type === 'enum' || entry.type === 'integer' || entry.type === 'number' || entry.type === 'device'

  let control: ReactNode = null
  switch (entry.type) {
    case 'boolean':
      control = <Toggle label={entry.label} checked={value === true} disabled={disabled} onChange={onChange} />
      break
    case 'enum':
      control = (
        <Dropdown
          label={entry.label}
          value={String(value)}
          options={entry.options.map((o) => ({ value: o, label: optionLabel(entry.key, o) }))}
          disabled={disabled}
          onChange={onChange}
        />
      )
      break
    case 'device':
      control = (
        <Dropdown
          label={entry.label}
          value={String(value ?? 'system_default')}
          options={deviceOptions(devices, entry.key)}
          disabled={disabled}
          onChange={onChange}
        />
      )
      break
    case 'integer':
    case 'number':
      control = (
        <Slider
          label={entry.label}
          value={Number(value)}
          min={entry.min ?? 0}
          max={entry.max ?? 100}
          step={entry.step ?? 1}
          disabled={disabled}
          format={(v) => valueText(entry, v)}
          onChange={onChange}
        />
      )
      break
    case 'integer_array': {
      const ids = Array.isArray(value) ? (value as number[]) : []
      control = (
        <span className="truncate text-sm leading-5 text-zinc-100">
          {ids.length === 0 ? 'No muted players' : ids.map((id) => `Player ${id}`).join(', ')}
        </span>
      )
      break
    }
    case 'binding':
      control = (
        <div className="flex items-center gap-3">
          <span className="grid h-7 min-w-10 place-items-center rounded-[2px] border border-white/70 px-2 text-xs leading-none font-bold text-zinc-100">
            {bindingText(typeof value === 'string' ? value : null)}
          </span>
          <span title="Rebinding comes in the next update">
            <Button label="Change" variant="secondary" size="compact" disabled />
          </span>
        </div>
      )
      break
    case 'action': {
      const label = entry.key === 'credits' ? 'Open credits' : entry.label
      control = (
        <Button
          label={label}
          variant="secondary"
          size="compact"
          disabled={disabled}
          onPress={() => setConfirm(entry.key as Confirm)}
        />
      )
      break
    }
  }

  const tag = !availability.enabled ? (availability.reason === 'coming_later' ? 'Coming later' : 'Not available') : null

  return (
    <div
      data-setting={entry.key}
      className={`flex h-12 shrink-0 items-center gap-4 rounded-sm border-l-2 pl-[14px] ${
        changed ? 'border-amber-400 bg-zinc-800/60' : 'border-transparent bg-zinc-900'
      }`}
    >
      <div className="flex w-[296px] shrink-0 flex-col justify-center">
        <span className="flex items-center gap-2 truncate text-sm leading-5 text-zinc-100">
          <span aria-hidden={ownLabel || undefined}>{entry.label}</span>
          {changed && (
            <>
              <span aria-hidden="true" className="h-1.5 w-1.5 rounded-full bg-amber-400" />
              <span className="sr-only">Changed</span>
            </>
          )}
        </span>
        {(tag || entry.restart || conflict) && (
          <span className="flex gap-2 text-[11px] leading-4 text-zinc-300">
            {tag && <span>{tag}</span>}
            {entry.restart && <span>Applies next launch</span>}
            {conflict && <span className="text-amber-300">Changed elsewhere</span>}
          </span>
        )}
      </div>
      <div className={`flex h-9 w-[496px] shrink-0 items-center [&>div]:w-full ${ownLabel ? OWN_LABEL_SR : ''}`}>
        {control}
      </div>

      {(confirm === 'reset_controls' || confirm === 'reset_all') && (
        <Modal
          title={confirm === 'reset_controls' ? 'Reset Controls?' : 'Reset all settings?'}
          primary={{
            label: 'Reset',
            onPress: () => {
              onReset(confirm === 'reset_controls' ? 'controls' : 'all')
              setConfirm(null)
            },
          }}
          secondary={{ label: 'Cancel', onPress: () => setConfirm(null) }}
          dismissible
          onDismiss={() => setConfirm(null)}
        >
          Defaults are staged. Apply saves them.
        </Modal>
      )}
      {confirm === 'credits' && (
        <Modal title="Credits" primary={{ label: 'Close', onPress: () => setConfirm(null) }} dismissible onDismiss={() => setConfirm(null)}>
          <ul className="m-0 list-none p-0">
            <li>FinalRun</li>
            <li>Kenney Mini Characters (CC0)</li>
          </ul>
          <p className="mt-2 mb-0 text-zinc-300">See assets/CREDITS.md for the full list</p>
        </Modal>
      )}
    </div>
  )
}
