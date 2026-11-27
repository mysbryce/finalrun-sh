import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { DownedPanel } from './DownedPanel'

describe('DownedPanel', () => {
  it('shows the seconds and a determinate bleed-out bar', () => {
    render(<DownedPanel seconds={42} />)
    expect(screen.getByRole('status')).toHaveTextContent('Downed')
    expect(screen.getByText('42 s')).toBeInTheDocument()
    expect(screen.getByRole('progressbar', { name: 'Bleed-out' })).toHaveAttribute('aria-valuenow', '42')
    expect(screen.getByText('Crawl to cover · wait for a revive')).toBeInTheDocument()
  })

  it('shows a dash and an indeterminate bar without seconds', () => {
    render(<DownedPanel seconds={null} />)
    expect(screen.getByText('—')).toBeInTheDocument()
    expect(screen.getByRole('progressbar', { name: 'Bleed-out' })).not.toHaveAttribute('aria-valuenow')
    expect(screen.getByText('Crawl to cover · wait for a revive')).toBeInTheDocument()
  })
})
