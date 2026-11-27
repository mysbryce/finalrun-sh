import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { NotificationStack } from './NotificationStack'

function rows(container: HTMLElement): string[] {
  return Array.from(container.querySelectorAll('[role="status"] > div')).map((el) => el.textContent ?? '')
}

describe('NotificationStack', () => {
  it('puts the heist toast on top and never shows more than four rows', () => {
    const { container } = render(
      <NotificationStack items={['one', 'two', 'three', 'four']} heistToast="Heist alert · Bank" />,
    )
    expect(rows(container)).toEqual(['Heist alert · Bank', 'two', 'three', 'four'])
  })

  it('shows up to four ordinary notifications without a toast', () => {
    const { container } = render(<NotificationStack items={['one', 'two', 'three', 'four']} />)
    expect(rows(container)).toEqual(['one', 'two', 'three', 'four'])
  })

  it('renders nothing for an empty tray', () => {
    render(<NotificationStack items={[]} heistToast={null} />)
    expect(screen.queryByRole('status')).toBeNull()
  })
})
