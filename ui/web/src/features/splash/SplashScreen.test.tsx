import { fireEvent, render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { request } from '@/lib/ipc/bridge'
import type { BootView } from '@/lib/ipc/protocol'
import { DEMO_BOOT } from './demoBoot'
import { SplashScreen } from './SplashScreen'
import { stagesOf } from './bootCopy'
import { useSplashStore } from './splashStore'

vi.mock('@/lib/ipc/bridge', () => ({ request: vi.fn(() => Promise.resolve({})) }))

const view = (patch: Partial<BootView>): BootView => ({
  phase: 'title',
  buildId: '0.1.0',
  progress: null,
  canSkipTitle: false,
  error: null,
  canRetry: false,
  ...patch,
})

describe('SplashScreen', () => {
  beforeEach(() => {
    useSplashStore.setState({ boot: null })
    vi.mocked(request).mockClear()
  })

  it('renders nothing without boot data', () => {
    const { container } = render(<SplashScreen />)
    expect(container).toBeEmptyDOMElement()
  })

  it('shows connecting with an indeterminate progress bar', () => {
    useSplashStore.setState({ boot: view({ phase: 'connecting' }) })
    render(<SplashScreen />)
    expect(screen.getByText('Connecting to server')).toBeInTheDocument()
    const bar = screen.getByRole('progressbar')
    expect(bar).not.toHaveAttribute('aria-valuenow')
    expect(screen.queryByRole('button', { name: 'Retry' })).toBeNull()
  })

  it('failure shows the reason, Retry and Quit', () => {
    useSplashStore.setState({ boot: DEMO_BOOT })
    render(<SplashScreen />)
    expect(screen.getByText('Could not reach the server.')).toBeInTheDocument()
    const retry = screen.getByRole('button', { name: 'Retry' })
    expect(retry).toHaveFocus()
    fireEvent.click(retry)
    expect(request).toHaveBeenCalledWith('boot.retry')
    fireEvent.click(screen.getByRole('button', { name: 'Quit' }))
    expect(request).toHaveBeenCalledWith('app.quit')
  })

  it('Enter sends boot.skip only when skipping is allowed', () => {
    useSplashStore.setState({ boot: view({ canSkipTitle: false }) })
    const { rerender } = render(<SplashScreen />)
    fireEvent.keyDown(window, { key: 'Enter' })
    expect(request).not.toHaveBeenCalled()
    useSplashStore.setState({ boot: view({ canSkipTitle: true }) })
    rerender(<SplashScreen />)
    expect(screen.getByText('Skip')).toBeInTheDocument()
    fireEvent.keyDown(window, { key: 'Enter' })
    expect(request).toHaveBeenCalledWith('boot.skip')
  })

  it('shows the build id', () => {
    useSplashStore.setState({ boot: view({}) })
    render(<SplashScreen />)
    expect(screen.getByText('Build 0.1.0')).toBeInTheDocument()
  })

  it('stage rail marks the failing stage', () => {
    expect(stagesOf(view({ phase: 'cef' })).map((s) => s.state)).toEqual(['done', 'current', 'pending'])
    expect(stagesOf(view({ phase: 'failed', error: 'cef_timeout' })).map((s) => s.state)).toEqual([
      'done',
      'failed',
      'pending',
    ])
    expect(stagesOf(view({ phase: 'ready' })).map((s) => s.state)).toEqual(['done', 'done', 'done'])
  })
})
