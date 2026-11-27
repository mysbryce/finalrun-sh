import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { InteractCard } from './InteractCard'

describe('InteractCard', () => {
  const interact = {
    title: 'Loot crate',
    actions: [
      { key: 'E', label: 'lockpick' },
      { key: 'V', label: 'smash' },
    ],
  }

  it('shows title and actions', () => {
    render(<InteractCard interact={interact} />)
    for (const t of ['Loot crate', 'E', 'lockpick', 'V', 'smash']) {
      expect(screen.getByText(t)).toBeInTheDocument()
    }
  })

  it('hides an empty title', () => {
    const { container } = render(<InteractCard interact={{ ...interact, title: '' }} />)
    expect(screen.queryByText('Loot crate')).not.toBeInTheDocument()
    expect(container.querySelector('.text-lg')).toBeNull()
  })

  it('renders no key chip for an empty key', () => {
    const { container } = render(
      <InteractCard interact={{ title: 'X', actions: [{ key: '', label: 'wait' }] }} />,
    )
    expect(screen.getByText('wait')).toBeInTheDocument()
    expect(container.querySelector('.bg-white')).toBeNull()
  })
})
