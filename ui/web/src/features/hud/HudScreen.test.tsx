import { render, screen } from '@testing-library/react'
import {
  RouterProvider,
  createMemoryHistory,
  createRootRoute,
  createRouter,
} from '@tanstack/react-router'
import { beforeEach, describe, expect, it } from 'vitest'
import { formatMoney } from '@/lib/format'
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
})
