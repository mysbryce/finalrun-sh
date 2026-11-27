import { fireEvent, render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { request } from '@/lib/ipc/bridge'
import { DEMO_RECEIPT_ARREST, DEMO_RECEIPT_DEATH } from './demoOverlay'
import { useOverlayStore } from './overlayStore'
import { ReceiptScreen } from './ReceiptScreen'

vi.mock('@/lib/ipc/bridge', () => ({ request: vi.fn(() => Promise.resolve({})) }))

describe('ReceiptScreen', () => {
  beforeEach(() => {
    vi.mocked(request).mockClear()
    useOverlayStore.setState({ overlay: null, transfer: null })
  })

  it('shows a death receipt', () => {
    useOverlayStore.setState({ overlay: DEMO_RECEIPT_DEATH })
    render(<ReceiptScreen />)
    expect(screen.getByText('You died')).toHaveAttribute('role', 'status')
    expect(screen.getByText('You bled out.')).toBeInTheDocument()
    expect(screen.getByText('Respawning at Motel.')).toBeInTheDocument()
  })

  it('shows an arrest receipt', () => {
    useOverlayStore.setState({ overlay: DEMO_RECEIPT_ARREST })
    render(<ReceiptScreen />)
    expect(screen.getByText('Arrested')).toBeInTheDocument()
    expect(screen.getByText('Bag forfeited · gear kept')).toBeInTheDocument()
  })

  it('dismisses once from the button', () => {
    useOverlayStore.setState({ overlay: DEMO_RECEIPT_DEATH })
    render(<ReceiptScreen />)
    fireEvent.click(screen.getByRole('button', { name: 'Dismiss' }))
    expect(request).toHaveBeenCalledTimes(1)
    expect(request).toHaveBeenCalledWith('overlay.dismiss', { receiptId: DEMO_RECEIPT_DEATH.receiptId })
  })

  it('dismisses once from the dim', () => {
    useOverlayStore.setState({ overlay: DEMO_RECEIPT_DEATH })
    render(<ReceiptScreen />)
    fireEvent.click(screen.getByTestId('overlay-dim'))
    expect(request).toHaveBeenCalledTimes(1)
    expect(request).toHaveBeenCalledWith('overlay.dismiss', { receiptId: DEMO_RECEIPT_DEATH.receiptId })
  })

  it('does not dismiss from a click on the title', () => {
    useOverlayStore.setState({ overlay: DEMO_RECEIPT_DEATH })
    render(<ReceiptScreen />)
    fireEvent.click(screen.getByText('You died'))
    expect(request).not.toHaveBeenCalled()
  })

  it('renders nothing without an overlay', () => {
    const { container } = render(<ReceiptScreen />)
    expect(container).toBeEmptyDOMElement()
  })
})
