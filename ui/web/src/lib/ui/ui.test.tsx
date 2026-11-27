import { useState } from 'react'
import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { Button } from './Button'
import { KeyHint } from './KeyHint'
import { Modal } from './Modal'
import { ProgressBar } from './ProgressBar'

describe('Button', () => {
  it('calls onPress', () => {
    const onPress = vi.fn()
    render(<Button label="Go" onPress={onPress} />)
    fireEvent.click(screen.getByRole('button', { name: 'Go' }))
    expect(onPress).toHaveBeenCalledTimes(1)
  })

  it('does not call onPress when disabled', () => {
    const onPress = vi.fn()
    render(<Button label="Go" disabled onPress={onPress} />)
    const btn = screen.getByRole('button', { name: 'Go' })
    expect(btn).toBeDisabled()
    fireEvent.click(btn)
    expect(onPress).not.toHaveBeenCalled()
  })

  it('is busy and ignores presses when loading', () => {
    const onPress = vi.fn()
    render(<Button label="Go" loading onPress={onPress} />)
    const btn = screen.getByRole('button', { name: 'Go' })
    expect(btn).toHaveAttribute('aria-busy', 'true')
    fireEvent.click(btn)
    expect(onPress).not.toHaveBeenCalled()
  })
})

describe('KeyHint', () => {
  it('renders Unbound for a null binding', () => {
    render(<KeyHint k="E" label="Use" binding={null} />)
    expect(screen.getByText('Unbound')).toBeInTheDocument()
    expect(screen.queryByText('E')).not.toBeInTheDocument()
  })
})

describe('ProgressBar', () => {
  it('sets aria-valuenow when determinate', () => {
    render(<ProgressBar label="Load" value={30} max={100} showValue />)
    const bar = screen.getByRole('progressbar', { name: 'Load' })
    expect(bar).toHaveAttribute('aria-valuenow', '30')
    expect(screen.getByText('30%')).toBeInTheDocument()
  })

  it('omits aria-valuenow and shows Working when indeterminate', () => {
    render(<ProgressBar label="Load" max={100} />)
    const bar = screen.getByRole('progressbar', { name: 'Load' })
    expect(bar).not.toHaveAttribute('aria-valuenow')
    expect(screen.getByText('Working')).toBeInTheDocument()
  })
})

function Harness({ dismissible, onDismiss }: { dismissible: boolean; onDismiss: () => void }) {
  const [open, setOpen] = useState(false)
  return (
    <>
      <button type="button" onClick={() => setOpen(true)}>
        Opener
      </button>
      {open && (
        <Modal
          title="Leave party?"
          primary={{ label: 'Leave', onPress: () => setOpen(false) }}
          secondary={{ label: 'Stay', onPress: () => setOpen(false) }}
          dismissible={dismissible}
          onDismiss={onDismiss}
        >
          Body
        </Modal>
      )}
    </>
  )
}

function openModal(dismissible: boolean) {
  const onDismiss = vi.fn()
  render(<Harness dismissible={dismissible} onDismiss={onDismiss} />)
  const opener = screen.getByRole('button', { name: 'Opener' })
  opener.focus()
  fireEvent.click(opener)
  return { onDismiss, opener }
}

describe('Modal', () => {
  it('focuses the secondary action on open', () => {
    openModal(false)
    expect(screen.getByRole('dialog', { name: 'Leave party?' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Stay' })).toHaveFocus()
  })

  it('Escape calls onDismiss only when dismissible', () => {
    const a = openModal(false)
    fireEvent.keyDown(screen.getByRole('dialog'), { key: 'Escape' })
    expect(a.onDismiss).not.toHaveBeenCalled()
  })

  it('Escape calls onDismiss when dismissible', () => {
    const b = openModal(true)
    fireEvent.keyDown(screen.getByRole('dialog'), { key: 'Escape' })
    expect(b.onDismiss).toHaveBeenCalledTimes(1)
  })

  it('Tab from the last button wraps to the first', () => {
    openModal(false)
    const leave = screen.getByRole('button', { name: 'Leave' })
    leave.focus()
    fireEvent.keyDown(leave, { key: 'Tab' })
    expect(screen.getByRole('button', { name: 'Stay' })).toHaveFocus()
    fireEvent.keyDown(screen.getByRole('button', { name: 'Stay' }), { key: 'Tab', shiftKey: true })
    expect(leave).toHaveFocus()
  })

  it('returns focus to the opener after unmount', () => {
    const { opener } = openModal(false)
    fireEvent.click(screen.getByRole('button', { name: 'Stay' }))
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument()
    expect(opener).toHaveFocus()
  })
})
