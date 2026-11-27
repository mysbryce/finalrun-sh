import { fireEvent, render, screen, within } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { request } from '@/lib/ipc/bridge'
import type { LobbyView } from '@/lib/ipc/protocol'
import { DEMO_LOBBY } from './demoLobby'
import { LobbyScreen } from './LobbyScreen'
import { useLobbyStore } from './lobbyStore'

vi.mock('@/lib/ipc/bridge', () => ({ request: vi.fn(() => Promise.resolve({})) }))

const view = (patch: Partial<LobbyView>): LobbyView => ({ ...DEMO_LOBBY, ...patch })

describe('LobbyScreen', () => {
  beforeEach(() => {
    useLobbyStore.setState({ lobby: null })
    vi.mocked(request).mockClear()
  })

  it('renders nothing without lobby data', () => {
    const { container } = render(<LobbyScreen />)
    expect(container).toBeEmptyDOMElement()
  })

  it('Play sends lobby.join with the configured mode', () => {
    useLobbyStore.setState({ lobby: DEMO_LOBBY })
    render(<LobbyScreen />)
    fireEvent.click(screen.getByRole('button', { name: 'Play' }))
    expect(request).toHaveBeenCalledWith('lobby.join', { mode: 'configured' })
  })

  it('connecting disables Play and shows pending feedback', () => {
    useLobbyStore.setState({
      lobby: view({
        canPlay: false,
        connection: { status: 'connecting', serverId: null, pingMs: null, error: null },
      }),
    })
    render(<LobbyScreen />)
    expect(screen.getByRole('button', { name: 'Play' })).toBeDisabled()
    expect(screen.getAllByText('Connecting to server').length).toBeGreaterThan(0)
    expect(screen.getByRole('progressbar')).not.toHaveAttribute('aria-valuenow')
    expect(screen.getByText('Connecting')).toBeInTheDocument()
  })

  it('shows the disconnect reason and player fallback name', () => {
    useLobbyStore.setState({ lobby: DEMO_LOBBY })
    render(<LobbyScreen />)
    expect(screen.getByText('The server closed the connection.')).toBeInTheDocument()
    expect(screen.getByText('Disconnected')).toBeInTheDocument()
    expect(screen.getByText('Player')).toBeInTheDocument()
    expect(screen.getByText('Preview coming soon')).toBeInTheDocument()
    expect(screen.getByText('Body: Default')).toBeInTheDocument()
  })

  it('lists patch notes newest first as given', () => {
    useLobbyStore.setState({ lobby: DEMO_LOBBY })
    render(<LobbyScreen />)
    const items = within(screen.getByRole('list', { name: 'Patch notes list' })).getAllByRole('listitem')
    expect(items).toHaveLength(2)
    expect(items[0]).toHaveTextContent('New boot, lobby and character')
  })

  it('failed news shows Retry sending lobby.news_retry', () => {
    useLobbyStore.setState({ lobby: view({ news: { status: 'failed', entries: [] } }) })
    render(<LobbyScreen />)
    expect(screen.getByText('Patch notes could not load.')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: 'Retry' }))
    expect(request).toHaveBeenCalledWith('lobby.news_retry')
  })

  it('empty news shows the empty text', () => {
    useLobbyStore.setState({ lobby: view({ news: { status: 'ready', entries: [] } }) })
    render(<LobbyScreen />)
    expect(screen.getByText('No patch notes yet.')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Retry' })).toBeNull()
  })

  it('Quit opens a confirmation with Cancel focused, confirming sends app.quit', () => {
    useLobbyStore.setState({ lobby: DEMO_LOBBY })
    render(<LobbyScreen />)
    fireEvent.click(screen.getByRole('button', { name: 'Quit' }))
    const dialog = screen.getByRole('dialog', { name: 'Quit FinalRun?' })
    expect(within(dialog).getByRole('button', { name: 'Cancel' })).toHaveFocus()
    expect(request).not.toHaveBeenCalledWith('app.quit')
    fireEvent.click(within(dialog).getByRole('button', { name: 'Quit' }))
    expect(request).toHaveBeenCalledWith('app.quit')
  })

  it('Cancel closes the confirmation without quitting', () => {
    useLobbyStore.setState({ lobby: DEMO_LOBBY })
    render(<LobbyScreen />)
    fireEvent.click(screen.getByRole('button', { name: 'Quit' }))
    fireEvent.click(screen.getByRole('button', { name: 'Cancel' }))
    expect(screen.queryByRole('dialog')).toBeNull()
    expect(request).not.toHaveBeenCalled()
  })

  it('Settings is enabled and sends settings.open', () => {
    useLobbyStore.setState({ lobby: DEMO_LOBBY })
    render(<LobbyScreen />)
    const settings = screen.getByRole('button', { name: 'Settings' })
    expect(settings).toBeEnabled()
    expect(screen.queryByText('Coming later')).toBeNull()
    fireEvent.click(settings)
    expect(request).toHaveBeenCalledWith('settings.open')
  })
})
