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
})
