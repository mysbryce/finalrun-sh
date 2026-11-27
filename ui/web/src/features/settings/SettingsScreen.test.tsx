import { fireEvent, render, screen, within } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { request } from '@/lib/ipc/bridge'
import { DEMO_SETTINGS } from './demoSettings'
import { SettingsScreen } from './SettingsScreen'
import { useSettingsStore } from './settingsStore'

vi.mock('@/lib/ipc/bridge', () => ({ request: vi.fn(() => Promise.resolve({})) }))

function reset(withView = true) {
  useSettingsStore.setState({ view: null, draft: {}, baseRevision: null, conflicts: [], pending: false, error: null })
  if (withView) useSettingsStore.getState().setView(DEMO_SETTINGS)
}

const row = (key: string) => document.querySelector(`[data-setting="${key}"]`) as HTMLElement

function chooseOption(label: string, option: string) {
  fireEvent.click(screen.getByRole('button', { name: new RegExp(`^${label}`) }))
  fireEvent.click(screen.getByRole('option', { name: option }))
}

describe('SettingsScreen', () => {
  beforeEach(() => {
    vi.mocked(request).mockReset()
    vi.mocked(request).mockImplementation(() => Promise.resolve({}))
    reset()
  })

  it('shows skeleton rows and locked footer before the first snapshot', () => {
    reset(false)
    render(<SettingsScreen tab="graphics" />)
    expect(screen.getByText('Loading settings')).toBeInTheDocument()
    expect(document.querySelectorAll('[data-skeleton]')).toHaveLength(8)
    expect(screen.getByRole('button', { name: 'Apply' })).toBeDisabled()
    expect(screen.getByRole('button', { name: 'Reset' })).toBeDisabled()
    expect(screen.getByRole('button', { name: 'Discard' })).toBeDisabled()
  })

  it('renders Graphics rows from the schema', () => {
    render(<SettingsScreen tab="graphics" />)
    expect(row('display_mode')).toHaveTextContent('Display mode')
    expect(screen.getByRole('button', { name: /^Display mode Borderless/ })).toBeInTheDocument()
    expect(screen.getByRole('slider', { name: 'Field of view' })).toHaveAttribute('aria-valuetext', '75°')
    expect(screen.getByRole('button', { name: 'Display' })).toBeInTheDocument()
    expect(screen.getByText('Saved')).toBeInTheDocument()
  })

  it('changing FOV marks the row changed and Apply sends the patch', () => {
    render(<SettingsScreen tab="graphics" />)
    const apply = screen.getByRole('button', { name: 'Apply' })
    expect(apply).toBeDisabled()
    fireEvent.change(screen.getByRole('slider', { name: 'Field of view' }), { target: { value: '90' } })
    expect(within(row('fov')).getByText('Changed')).toBeInTheDocument()
    expect(screen.getByText('1 change')).toBeInTheDocument()
    expect(apply).toBeEnabled()
    fireEvent.click(apply)
    expect(request).toHaveBeenCalledWith('settings.apply', { revision: 1, patch: { fov: 90 } })
  })

  it('quality preset low stages the five preset values', () => {
    render(<SettingsScreen tab="graphics" />)
    chooseOption('Quality preset', 'Low')
    expect(useSettingsStore.getState().draft).toEqual({
      quality_preset: 'low',
      render_scale: 75,
      shadows: 'low',
      textures: 'low',
      anti_aliasing: 'off',
      view_distance: 'low',
    })
  })

  it('changing shadows after a preset switches the preset to Custom', () => {
    render(<SettingsScreen tab="graphics" />)
    chooseOption('Quality preset', 'High')
    chooseOption('Shadows', 'Low')
    expect(screen.getByRole('button', { name: /^Quality preset Custom/ })).toBeInTheDocument()
    expect(useSettingsStore.getState().draft.quality_preset).toBe('custom')
  })

  it('a coming_later row is disabled with the tag and a hidden row is absent', () => {
    render(<SettingsScreen tab="controls" />)
    expect(screen.getByRole('slider', { name: 'ADS sensitivity' })).toBeDisabled()
    expect(within(row('ads_sensitivity')).getByText('Coming later')).toBeInTheDocument()
    expect(row('bind_sell_loot')).toBeNull()
    expect(screen.queryByText('Sell loot')).toBeNull()
    expect(within(row('bind_fire')).getByText('LMB')).toBeInTheDocument()
    expect(within(row('bind_fire')).getByRole('button', { name: 'Change' })).toBeEnabled()
    expect(within(row('bind_jump')).getByText('Coming later')).toBeInTheDocument()
    expect(within(row('bind_jump')).getByRole('button', { name: 'Change' })).toBeDisabled()
  })

  it('Change on Interact opens the rebind dialog', () => {
    vi.mocked(request).mockImplementation((m) => (m === 'settings.capture' ? new Promise(() => {}) : Promise.resolve({})))
    render(<SettingsScreen tab="controls" />)
    fireEvent.click(within(row('bind_interact')).getByRole('button', { name: 'Change' }))
    expect(screen.getByRole('dialog', { name: 'Rebind Interact / lockpick / search' })).toBeInTheDocument()
    expect(request).toHaveBeenCalledWith('settings.capture', { key: 'bind_interact' }, 20000)
    expect(screen.getByRole('button', { name: 'Back' })).toBeDisabled()
    expect(screen.getByRole('button', { name: 'Reset' })).toBeDisabled()
  })

  it('Look and Pause / back are fixed', () => {
    render(<SettingsScreen tab="controls" />)
    for (const key of ['bind_look', 'bind_pause']) {
      expect(within(row(key)).getByText('Fixed')).toBeInTheDocument()
      expect(within(row(key)).queryByRole('button', { name: 'Change' })).toBeNull()
    }
  })

  it('Discard clears the draft', () => {
    render(<SettingsScreen tab="graphics" />)
    fireEvent.click(screen.getByRole('switch', { name: 'VSync' }))
    expect(useSettingsStore.getState().draft).toEqual({ vsync: false })
    fireEvent.click(screen.getByRole('button', { name: 'Discard' }))
    expect(useSettingsStore.getState().draft).toEqual({})
    expect(screen.getByText('Saved')).toBeInTheDocument()
  })

  it('Back with a dirty draft asks first', () => {
    render(<SettingsScreen tab="graphics" />)
    fireEvent.click(screen.getByRole('switch', { name: 'VSync' }))
    fireEvent.click(screen.getByRole('button', { name: 'Back' }))
    const dialog = screen.getByRole('dialog', { name: 'Discard changes?' })
    expect(request).not.toHaveBeenCalledWith('settings.close')
    fireEvent.click(within(dialog).getByRole('button', { name: 'Keep editing' }))
    expect(screen.queryByRole('dialog')).toBeNull()
    expect(useSettingsStore.getState().draft).toEqual({ vsync: false })
    fireEvent.click(screen.getByRole('button', { name: 'Back' }))
    fireEvent.click(within(screen.getByRole('dialog')).getByRole('button', { name: 'Discard' }))
    expect(request).toHaveBeenCalledWith('settings.close')
    expect(useSettingsStore.getState().draft).toEqual({})
  })

  it('Back with a clean draft closes directly', () => {
    render(<SettingsScreen tab="graphics" />)
    fireEvent.click(screen.getByRole('button', { name: 'Back' }))
    expect(screen.queryByRole('dialog')).toBeNull()
    expect(request).toHaveBeenCalledWith('settings.close')
  })

  it('tab click sends settings.tab', () => {
    render(<SettingsScreen tab="graphics" />)
    fireEvent.click(screen.getByRole('tab', { name: 'Controls' }))
    expect(request).toHaveBeenCalledWith('settings.tab', { tab: 'controls' })
  })

  it('a new revision keeps unchanged draft keys and marks conflicts', () => {
    render(<SettingsScreen tab="graphics" />)
    fireEvent.click(screen.getByRole('switch', { name: 'VSync' }))
    fireEvent.change(screen.getByRole('slider', { name: 'Field of view' }), { target: { value: '90' } })
    const store = useSettingsStore.getState()
    store.setView({ ...DEMO_SETTINGS, revision: 2, values: { ...DEMO_SETTINGS.values, fov: 80 } })
    expect(useSettingsStore.getState().draft).toEqual({ vsync: false })
    expect(useSettingsStore.getState().conflicts).toEqual(['fov'])
  })

  it('shows apply errors and pending restart in the status', async () => {
    vi.mocked(request).mockImplementationOnce(() => Promise.reject(new Error('stale_revision')))
    useSettingsStore.getState().setView({ ...DEMO_SETTINGS, pendingRestart: ['textures'] })
    render(<SettingsScreen tab="graphics" />)
    fireEvent.click(screen.getByRole('switch', { name: 'VSync' }))
    fireEvent.click(screen.getByRole('button', { name: 'Apply' }))
    expect(
      await screen.findByText('Settings changed elsewhere. Your other changes were kept. · Restart needed for: Textures'),
    ).toBeInTheDocument()
  })
})
