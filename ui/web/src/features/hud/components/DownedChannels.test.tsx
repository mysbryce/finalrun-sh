import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { DownedChannels } from './DownedChannels'

describe('DownedChannels', () => {
  it('shows revive progress and seconds left', () => {
    render(<DownedChannels channels={{ revive: { secondsLeft: 3, durationSeconds: 5 }, finish: null }} />)
    expect(screen.getByText('Being revived')).toBeInTheDocument()
    expect(screen.getByText('3 s')).toBeInTheDocument()
    const bar = screen.getByRole('progressbar', { name: 'Revive progress' })
    expect(bar).toHaveAttribute('aria-valuenow', '2')
    expect(bar).toHaveAttribute('aria-valuemax', '5')
  })

  it('warns when a finish is in progress', () => {
    render(<DownedChannels channels={{ revive: null, finish: { secondsLeft: 1, durationSeconds: 2 } }} />)
    const warning = screen.getByText('Finish in progress')
    expect(warning.closest('[role="status"]')).toHaveAttribute('aria-live', 'polite')
    expect(warning.closest('[role="status"]')!.querySelector('svg')).not.toBeNull()
    expect(screen.queryByText('Being revived')).toBeNull()
  })

  it('shows the at-risk text when no finish is active', () => {
    render(<DownedChannels channels={{ revive: null, finish: null }} />)
    expect(screen.getByText('At risk of being finished')).toBeInTheDocument()
    expect(screen.queryByText('Finish in progress')).toBeNull()
  })

  it('shows a dash when channels are absent', () => {
    render(<DownedChannels channels={undefined} />)
    expect(screen.getByText('—')).toBeInTheDocument()
    expect(screen.queryByText('At risk of being finished')).toBeNull()
  })
})
