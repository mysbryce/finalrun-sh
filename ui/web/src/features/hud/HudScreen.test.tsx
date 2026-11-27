import { render, screen } from '@testing-library/react'
import {
  RouterProvider,
  createMemoryHistory,
  createRootRoute,
  createRouter,
} from '@tanstack/react-router'
import { afterEach, beforeEach, describe, expect, it } from 'vitest'
import { formatMoney } from '@/lib/format'
import { DEFAULT_PREFS, usePrefs } from '@/lib/prefs'
import type { HudState } from '@/lib/ipc/protocol'
import { DEMO_HUD } from './demoHud'
import { HudScreen } from './HudScreen'
import { useHudStore } from './hudStore'

function renderHud() {
  const router = createRouter({
    routeTree: createRootRoute({ component: HudScreen }),
    history: createMemoryHistory({ initialEntries: ['/'] }),
  })
  return render(<RouterProvider router={router} />)
}

describe('HudScreen', () => {
  beforeEach(() => {
    useHudStore.setState({ hud: null })
  })

  afterEach(() => {
    usePrefs.setState(DEFAULT_PREFS)
  })

  it('renders nothing without hud state', async () => {
    const { container } = renderHud()
    await Promise.resolve()
    expect(container).toBeEmptyDOMElement()
  })

  it('renders the hud', async () => {
    useHudStore.setState({ hud: DEMO_HUD })
    renderHud()
    expect(await screen.findByText(formatMoney(DEMO_HUD.cash))).toBeInTheDocument()
    expect(screen.getByText('Player 2')).toBeInTheDocument()
    expect(screen.getByText(DEMO_HUD.interact!.title)).toBeInTheDocument()
  })

  it('shows the compass by default', async () => {
    useHudStore.setState({ hud: { ...DEMO_HUD, heading: 90 } })
    renderHud()
    expect(await screen.findByText('SE')).toBeInTheDocument()
  })

  it('hides the compass when show_compass is off', async () => {
    usePrefs.setState({ ...DEFAULT_PREFS, showCompass: false })
    useHudStore.setState({ hud: { ...DEMO_HUD, heading: 90 } })
    renderHud()
    await screen.findByText(formatMoney(DEMO_HUD.cash))
    expect(screen.queryByText('SE')).toBeNull()
  })

  it('rotates the minimap arrow by heading', async () => {
    useHudStore.setState({ hud: { ...DEMO_HUD, heading: 90 } })
    const { container } = renderHud()
    await screen.findByText(formatMoney(DEMO_HUD.cash))
    expect(container.querySelector('polygon')!.parentElement!.style.transform).toBe('rotate(90deg)')
  })

  it('keeps the minimap arrow up when the minimap rotates', async () => {
    usePrefs.setState({ ...DEFAULT_PREFS, minimapRotate: true })
    useHudStore.setState({ hud: { ...DEMO_HUD, heading: 90 } })
    const { container } = renderHud()
    await screen.findByText(formatMoney(DEMO_HUD.cash))
    expect(container.querySelector('polygon')!.parentElement!.style.transform).toBe('rotate(0deg)')
  })

  it('shows the safety line only when weapons are locked', async () => {
    useHudStore.setState({ hud: { ...DEMO_HUD, weaponsLocked: true } })
    const { unmount } = renderHud()
    expect(await screen.findByText('SAFE ZONE - weapons locked')).toBeInTheDocument()
    unmount()
    useHudStore.setState({ hud: { ...DEMO_HUD, weaponsLocked: false } })
    renderHud()
    await screen.findByText(formatMoney(DEMO_HUD.cash))
    expect(screen.queryByText('SAFE ZONE - weapons locked')).toBeNull()
  })

  it('shows the heist alert line with and without a location', async () => {
    const alert = { id: 'a1', label: 'Heist alert', location: 'Bank', active: true, toastSecondsLeft: 0 }
    useHudStore.setState({ hud: { ...DEMO_HUD, heistAlert: alert } })
    const { unmount } = renderHud()
    expect(await screen.findByText('Heist alert · Bank')).toBeInTheDocument()
    unmount()
    useHudStore.setState({ hud: { ...DEMO_HUD, heistAlert: { ...alert, id: 'a2', location: null } } })
    renderHud()
    const line = await screen.findByText('Heist alert')
    expect(line.closest('[role="status"]')).toHaveAttribute('aria-live', 'polite')
  })

  it('hides the heist alert line when inactive', async () => {
    const alert = { id: 'a3', label: 'Heist alert', location: 'Bank', active: false, toastSecondsLeft: 0 }
    useHudStore.setState({ hud: { ...DEMO_HUD, heistAlert: alert } })
    renderHud()
    await screen.findByText(formatMoney(DEMO_HUD.cash))
    expect(screen.queryByText('Heist alert · Bank')).toBeNull()
  })

  it('shows the surrender hint with the default and the bound key', async () => {
    useHudStore.setState({ hud: { ...DEMO_HUD, surrenderAvailable: true, surrenderKey: undefined } })
    const { unmount } = renderHud()
    const label = await screen.findByText('Surrender')
    expect(label.previousElementSibling).toHaveTextContent('H')
    unmount()
    useHudStore.setState({ hud: { ...DEMO_HUD, surrenderAvailable: true, surrenderKey: 'F' } })
    renderHud()
    expect((await screen.findByText('Surrender')).previousElementSibling).toHaveTextContent('F')
  })

  it('hides the surrender hint when not available', async () => {
    useHudStore.setState({ hud: { ...DEMO_HUD, surrenderAvailable: false } })
    renderHud()
    await screen.findByText(formatMoney(DEMO_HUD.cash))
    expect(screen.queryByText('Surrender')).toBeNull()
  })

  it('shows downed channels only while downed', async () => {
    useHudStore.setState({
      hud: {
        ...DEMO_HUD,
        life: 'DOWNED',
        channels: { revive: { secondsLeft: 3, durationSeconds: 5 }, finish: null },
      },
    })
    const { unmount } = renderHud()
    expect(await screen.findByText('Being revived')).toBeInTheDocument()
    expect(screen.getByText('3 s')).toBeInTheDocument()
    expect(screen.getByText('At risk of being finished')).toBeInTheDocument()
    unmount()
    useHudStore.setState({ hud: { ...DEMO_HUD, life: 'ALIVE' } })
    renderHud()
    await screen.findByText(formatMoney(DEMO_HUD.cash))
    expect(screen.queryByRole('progressbar', { name: 'Bleed-out' })).toBeNull()
    expect(screen.queryByText('Being revived')).toBeNull()
    expect(screen.queryByText('At risk of being finished')).toBeNull()
  })

  it('renders an old snapshot without the new fields', async () => {
    const old: HudState = { ...DEMO_HUD }
    delete old.weaponsLocked
    delete old.heistAlert
    delete old.surrenderAvailable
    delete old.surrenderKey
    delete old.channels
    useHudStore.setState({ hud: old })
    renderHud()
    expect(await screen.findByText(formatMoney(DEMO_HUD.cash))).toBeInTheDocument()
    expect(screen.queryByText('SAFE ZONE - weapons locked')).toBeNull()
    expect(screen.queryByText('Surrender')).toBeNull()
    expect(screen.queryByText(/Heist alert/)).toBeNull()
    expect(screen.getByText(DEMO_HUD.notifications[0])).toBeInTheDocument()
  })

  it('renders the downed panel while downed', async () => {
    useHudStore.setState({ hud: { ...DEMO_HUD, life: 'DOWNED', timer: { label: 'Bleed-out', seconds: 42 } } })
    renderHud()
    expect(await screen.findByText('42 s')).toBeInTheDocument()
    expect(screen.getByRole('progressbar', { name: 'Bleed-out' })).toHaveAttribute('aria-valuenow', '42')
    expect(screen.getByText('Crawl to cover · wait for a revive')).toBeInTheDocument()
  })

  it('shows a dash for a downed old snapshot without channels', async () => {
    const old: HudState = { ...DEMO_HUD, life: 'DOWNED' }
    delete old.channels
    useHudStore.setState({ hud: old })
    renderHud()
    expect(await screen.findByText('—')).toBeInTheDocument()
    expect(screen.queryByText('At risk of being finished')).toBeNull()
  })
})
