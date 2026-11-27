import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { PartyPanel } from './PartyPanel'

describe('PartyPanel', () => {
  it('shows members, self and one AWAY', () => {
    render(
      <PartyPanel
        party={[
          { name: 'Player 3', health: 100, maxHealth: 100, life: 'ALIVE', leader: true, away: false },
          { name: 'Player 4', health: -1, maxHealth: 100, life: '?', leader: false, away: true },
        ]}
        self={{ name: 'Player 2' }}
        health={75}
        maxHealth={100}
      />,
    )
    expect(screen.getByText('Player 3')).toBeInTheDocument()
    expect(screen.getByText('Player 4')).toBeInTheDocument()
    expect(screen.getByText('Player 2')).toBeInTheDocument()
    expect(screen.getAllByText('AWAY')).toHaveLength(1)
  })
})
