import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { Hotbar } from './Hotbar'

describe('Hotbar', () => {
  it('renders slots, keys and bag', () => {
    render(
      <Hotbar
        slots={[{ label: 'Pistol' }, null, null, null, null, null]}
        active={0}
        bag={500}
      />,
    )
    expect(screen.getByText('Pistol')).toBeInTheDocument()
    for (const k of ['1', '2', '3', '4', '5', '6', 'TAB']) {
      expect(screen.getByText(k)).toBeInTheDocument()
    }
    expect(screen.getByText('$500')).toBeInTheDocument()
    expect(screen.getByText('Pistol').parentElement).toHaveClass('ring-amber-400')
    expect(screen.getAllByText('×')).toHaveLength(5)
  })
})
