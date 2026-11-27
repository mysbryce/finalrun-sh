import { fireEvent, render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { request } from '@/lib/ipc/bridge'
import { DEMO_INVENTORY } from './demoInventory'
import { InventoryScreen } from './InventoryScreen'
import { useInventoryStore } from './inventoryStore'

vi.mock('@/lib/ipc/bridge', () => ({ request: vi.fn(() => Promise.resolve({})) }))

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
    expect(screen.getAllByRole('button', { name: 'Empty slot' })).toHaveLength(28)
    expect(screen.queryByRole('button', { name: 'SECONDARY' })).toBeNull()
    expect(screen.getByRole('button', { name: 'BAG' })).toBeInTheDocument()
    expect(screen.getAllByRole('button', { name: 'POUCH' })).toHaveLength(4)
    expect(screen.getByText('Select an item')).toBeInTheDocument()
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
