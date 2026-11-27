import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import type { HudState } from '@/lib/ipc/protocol'
import { DEMO_HUD } from '../demoHud'
import { StatusColumn } from './StatusColumn'

function make(over: Partial<HudState>): HudState {
  return { ...DEMO_HUD, ...over }
}

describe('StatusColumn', () => {
  it('shows timer, role and notoriety when alive', () => {
    render(
      <StatusColumn
        hud={make({ timer: { label: 'Masking', seconds: 65 }, role: 'CRIMINAL', life: 'ALIVE' })}
      />,
    )
    expect(screen.getByText('MASKING 1:05')).toBeInTheDocument()
    expect(screen.getByText('CRIMINAL')).toBeInTheDocument()
    expect(screen.getByText('NOTORIETY 500')).toBeInTheDocument()
  })

  it('hides the timer when downed', () => {
    render(
      <StatusColumn hud={make({ timer: { label: 'Masking', seconds: 65 }, life: 'DOWNED' })} />,
    )
    expect(screen.queryByText('MASKING 1:05')).not.toBeInTheDocument()
  })

  it('hides notoriety for an alive Citizen', () => {
    render(<StatusColumn hud={make({ role: 'CITIZEN', life: 'ALIVE' })} />)
    expect(screen.queryByText(/NOTORIETY/)).not.toBeInTheDocument()
  })

  it('hides notoriety for a downed Criminal', () => {
    render(<StatusColumn hud={make({ role: 'CRIMINAL', life: 'DOWNED' })} />)
    expect(screen.queryByText(/NOTORIETY/)).not.toBeInTheDocument()
  })
})
