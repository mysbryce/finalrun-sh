import { act, fireEvent, render, screen, within } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { request } from '@/lib/ipc/bridge'
import { PauseScreen } from './PauseScreen'

vi.mock('@/lib/ipc/bridge', () => ({ request: vi.fn(() => Promise.resolve({})) }))

describe('PauseScreen', () => {
  beforeEach(() => {
    vi.mocked(request).mockReset()
    vi.mocked(request).mockImplementation(() => Promise.resolve({}))
  })

  it('shows the title and context', () => {
    render(<PauseScreen />)
    expect(screen.getByRole('heading', { name: 'Paused' })).toBeInTheDocument()
    expect(screen.getByText('Session continues')).toBeInTheDocument()
  })

  it('Resume sends pause.resume', () => {
    render(<PauseScreen />)
    fireEvent.click(screen.getByRole('button', { name: 'Resume' }))
    expect(request).toHaveBeenCalledWith('pause.resume')
  })

  it('Leave to Lobby opens a confirmation with Cancel focused, Leave sends session.leave', () => {
    render(<PauseScreen />)
    fireEvent.click(screen.getByRole('button', { name: 'Leave to Lobby' }))
    const dialog = screen.getByRole('dialog', { name: 'Leave to lobby?' })
    expect(within(dialog).getByText(/You will disconnect from this server/)).toBeInTheDocument()
    expect(within(dialog).getByRole('button', { name: 'Cancel' })).toHaveFocus()
    expect(request).not.toHaveBeenCalled()
    fireEvent.click(within(dialog).getByRole('button', { name: 'Leave' }))
    expect(request).toHaveBeenCalledWith('session.leave')
  })

  it('Cancel closes the leave confirmation without a request', () => {
    render(<PauseScreen />)
    fireEvent.click(screen.getByRole('button', { name: 'Leave to Lobby' }))
    fireEvent.click(screen.getByRole('button', { name: 'Cancel' }))
    expect(screen.queryByRole('dialog')).toBeNull()
    expect(request).not.toHaveBeenCalled()
  })

  it('Quit opens a confirmation, Quit sends app.quit', () => {
    render(<PauseScreen />)
    fireEvent.click(screen.getByRole('button', { name: 'Quit' }))
    const dialog = screen.getByRole('dialog', { name: 'Quit FinalRun?' })
    expect(within(dialog).getByRole('button', { name: 'Cancel' })).toHaveFocus()
    fireEvent.click(within(dialog).getByRole('button', { name: 'Quit' }))
    expect(request).toHaveBeenCalledWith('app.quit')
  })

  it('Settings is enabled and sends settings.open', () => {
    render(<PauseScreen />)
    const settings = screen.getByRole('button', { name: 'Settings' })
    expect(settings).toBeEnabled()
    expect(screen.queryByText('Coming later')).toBeNull()
    fireEvent.click(settings)
    expect(request).toHaveBeenCalledWith('settings.open')
  })

  it('a rejected request shows feedback, cleared on the next action', async () => {
    vi.mocked(request).mockImplementation(() => Promise.reject(new Error('timeout')))
    render(<PauseScreen />)
    await act(async () => {
      fireEvent.click(screen.getByRole('button', { name: 'Resume' }))
    })
    expect(screen.getByRole('alert')).toHaveTextContent('Could not resume.')

    await act(async () => {
      fireEvent.click(screen.getByRole('button', { name: 'Leave to Lobby' }))
    })
    expect(screen.queryByText('Could not resume.')).toBeNull()
    await act(async () => {
      fireEvent.click(within(screen.getByRole('dialog')).getByRole('button', { name: 'Leave' }))
    })
    expect(screen.queryByRole('dialog')).toBeNull()
    expect(screen.getByRole('alert')).toHaveTextContent('Could not leave the session.')
  })
})
