import { fireEvent, render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { request } from '@/lib/ipc/bridge'
import { DEMO_TRANSFER, DEMO_TRANSFER_FAILED } from './demoOverlay'
import { useOverlayStore } from './overlayStore'
import { TransferScreen } from './TransferScreen'

vi.mock('@/lib/ipc/bridge', () => ({ request: vi.fn(() => Promise.resolve({})) }))

describe('TransferScreen', () => {
  beforeEach(() => {
    vi.mocked(request).mockClear()
    vi.mocked(request).mockImplementation(() => Promise.resolve({}))
    useOverlayStore.setState({ overlay: null, transfer: null })
  })

  it('shows a join while loading', () => {
    useOverlayStore.setState({ transfer: DEMO_TRANSFER })
    render(<TransferScreen />)
    expect(screen.getByText('Joining Motel')).toBeInTheDocument()
    expect(screen.getByText('Loading map…')).toHaveAttribute('role', 'status')
    expect(screen.getByText('Load map').closest('li')).toHaveTextContent('In progress')
  })

  it('shows the waiting stage', () => {
    useOverlayStore.setState({ transfer: { ...DEMO_TRANSFER, stage: 'waiting_for_spawn' } })
    render(<TransferScreen />)
    expect(screen.getByText('Waiting for the server…')).toBeInTheDocument()
  })

  it('carries the death outcome in the summary', () => {
    useOverlayStore.setState({ transfer: { ...DEMO_TRANSFER, reason: 'death' } })
    render(<TransferScreen />)
    expect(screen.getByText('You died. Respawning at Motel.')).toBeInTheDocument()
  })

  it('offers a focused return to the lobby when failed', () => {
    useOverlayStore.setState({ transfer: DEMO_TRANSFER_FAILED })
    render(<TransferScreen />)
    expect(screen.getByText('Transfer failed')).toBeInTheDocument()
    expect(screen.getByText('The server did not confirm the transfer in time.')).toHaveAttribute('role', 'alert')
    const button = screen.getByRole('button', { name: 'Return to Lobby' })
    expect(document.activeElement).toBe(button)
    fireEvent.click(button)
    expect(request).toHaveBeenCalledTimes(1)
    expect(request).toHaveBeenCalledWith('transfer.return_to_lobby', {})
  })

  it('shows an error when the return request is rejected', async () => {
    vi.mocked(request).mockImplementation(() => Promise.reject(new Error('nope')))
    useOverlayStore.setState({ transfer: DEMO_TRANSFER_FAILED })
    render(<TransferScreen />)
    fireEvent.click(screen.getByRole('button', { name: 'Return to Lobby' }))
    expect(await screen.findByText('Could not return to the lobby.')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Return to Lobby' })).toBeEnabled()
  })

  it('renders nothing without a transfer', () => {
    const { container } = render(<TransferScreen />)
    expect(container).toBeEmptyDOMElement()
  })
})
