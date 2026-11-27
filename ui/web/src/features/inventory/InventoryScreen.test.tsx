import type { ReactElement } from 'react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render as rtlRender, fireEvent, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { request } from '@/lib/ipc/bridge'
import { DEMO_INVENTORY } from './demoInventory'
import { InventoryScreen } from './InventoryScreen'
import { useInventoryStore } from './inventoryStore'

vi.mock('@/lib/ipc/bridge', () => ({ request: vi.fn(() => Promise.resolve({})) }))

const render = (ui: ReactElement) =>
  rtlRender(<QueryClientProvider client={new QueryClient()}>{ui}</QueryClientProvider>)

describe('InventoryScreen', () => {
  beforeEach(() => {
    useInventoryStore.setState({ inventory: null, selectedUid: null })
    vi.mocked(request).mockClear()
  })

  it('renders nothing without data', () => {
    const { container } = render(<InventoryScreen />)
    expect(container).toBeEmptyDOMElement()
  })

  it('shows the demo inventory', () => {
    useInventoryStore.setState({ inventory: DEMO_INVENTORY })
    render(<InventoryScreen />)
    expect(screen.getByText('INVENTORY')).toBeInTheDocument()
    expect(screen.getByText('$79,900')).toBeInTheDocument()
    expect(screen.getByText('$3,530')).toBeInTheDocument()
    expect(screen.getAllByRole('button', { name: 'Empty slot' })).toHaveLength(33)
    expect(screen.queryByRole('button', { name: 'SECONDARY' })).toBeNull()
    expect(screen.getByRole('button', { name: 'BAG' })).toBeInTheDocument()
    expect(screen.getAllByRole('button', { name: 'POUCH' })).toHaveLength(4)
    expect(screen.getByText('Select an item')).toBeInTheDocument()
  })

  it('bag items render at their slots', () => {
    useInventoryStore.setState({ inventory: DEMO_INVENTORY })
    render(<InventoryScreen />)
    expect(screen.getByRole('button', { name: 'Drill' }).parentElement).toHaveStyle({
      left: '255px',
      top: '51px',
      width: '50px',
      height: '152px',
    })
    expect(screen.getByRole('button', { name: 'Painting' }).parentElement).toHaveStyle({
      left: '102px',
      top: '102px',
      width: '101px',
      height: '152px',
    })
  })

  it('selecting an item shows details', () => {
    useInventoryStore.setState({ inventory: DEMO_INVENTORY })
    render(<InventoryScreen />)
    fireEvent.click(screen.getByRole('button', { name: 'Jewelry' }))
    expect(screen.getAllByText('Jewelry')).toHaveLength(2)
    expect(screen.getByRole('button', { name: 'Jewelry' })).toHaveClass('ring-amber-400')
  })

  it('Back requests close', () => {
    useInventoryStore.setState({ inventory: DEMO_INVENTORY })
    render(<InventoryScreen />)
    fireEvent.click(screen.getByRole('button', { name: /Back/ }))
    expect(request).toHaveBeenCalledWith('inventory.close', {})
  })
})
