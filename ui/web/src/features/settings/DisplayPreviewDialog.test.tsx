import { act, fireEvent, render, screen } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { request } from '@/lib/ipc/bridge'
import { DisplayPreviewDialog } from './DisplayPreviewDialog'

vi.mock('@/lib/ipc/bridge', () => ({ request: vi.fn(() => Promise.resolve({})) }))

const PREVIEW = { token: 't1', secondsLeft: 15 }
const live = () => document.querySelector('[aria-live="polite"]') as HTMLElement

describe('DisplayPreviewDialog', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    vi.mocked(request).mockReset()
    vi.mocked(request).mockImplementation(() => Promise.resolve({}))
  })
  afterEach(() => {
    vi.useRealTimers()
  })

  it('counts down once per second', () => {
    render(<DisplayPreviewDialog preview={PREVIEW} onError={() => undefined} />)
    expect(screen.getByRole('dialog', { name: 'Keep display settings?' })).toBeInTheDocument()
    expect(screen.getByText('Reverting in 15 s.')).toBeInTheDocument()
    act(() => vi.advanceTimersByTime(1000))
    expect(screen.getByText('Reverting in 14 s.')).toBeInTheDocument()
  })

  it('Keep sends display_confirm with keep true', () => {
    render(<DisplayPreviewDialog preview={PREVIEW} onError={() => undefined} />)
    fireEvent.click(screen.getByRole('button', { name: 'Keep' }))
    expect(request).toHaveBeenCalledWith('settings.display_confirm', { token: 't1', keep: true })
  })

  it('Revert sends display_confirm with keep false', () => {
    render(<DisplayPreviewDialog preview={PREVIEW} onError={() => undefined} />)
    fireEvent.click(screen.getByRole('button', { name: 'Revert' }))
    expect(request).toHaveBeenCalledWith('settings.display_confirm', { token: 't1', keep: false })
  })

  it('Escape sends display_confirm with keep false', () => {
    render(<DisplayPreviewDialog preview={PREVIEW} onError={() => undefined} />)
    fireEvent.keyDown(screen.getByRole('dialog'), { key: 'Escape' })
    expect(request).toHaveBeenCalledWith('settings.display_confirm', { token: 't1', keep: false })
  })

  it('announces the open text and five seconds left', () => {
    render(<DisplayPreviewDialog preview={PREVIEW} onError={() => undefined} />)
    expect(live()).toHaveTextContent('Display preview. Keep these settings within 15 seconds.')
    for (let i = 0; i < 10; i++) act(() => vi.advanceTimersByTime(1000))
    expect(screen.getByText('Reverting in 5 s.')).toBeInTheDocument()
    expect(live()).toHaveTextContent('5 seconds left.')
  })

  it('a save_failed rejection calls onError', async () => {
    vi.mocked(request).mockImplementation(() => Promise.reject(new Error('save_failed')))
    const onError = vi.fn()
    render(<DisplayPreviewDialog preview={PREVIEW} onError={onError} />)
    fireEvent.click(screen.getByRole('button', { name: 'Keep' }))
    await act(async () => {})
    expect(onError).toHaveBeenCalledWith('save_failed')
  })

  it('a preview_expired rejection shows nothing', async () => {
    vi.mocked(request).mockImplementation(() => Promise.reject(new Error('preview_expired')))
    const onError = vi.fn()
    render(<DisplayPreviewDialog preview={PREVIEW} onError={onError} />)
    fireEvent.click(screen.getByRole('button', { name: 'Revert' }))
    await act(async () => {})
    expect(onError).not.toHaveBeenCalled()
  })
})
