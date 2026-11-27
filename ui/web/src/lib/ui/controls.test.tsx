import { useState } from 'react'
import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { Dropdown } from './Dropdown'
import type { DropdownOption } from './Dropdown'
import { Slider } from './Slider'
import { TabBar } from './TabBar'
import { ToastTray } from './ToastTray'
import { Toggle } from './Toggle'

describe('TabBar', () => {
  function Harness() {
    const [sel, setSel] = useState('a')
    return (
      <TabBar
        label="Sections"
        selectedId={sel}
        onSelect={setSel}
        tabs={[
          { id: 'a', label: 'Alpha' },
          { id: 'b', label: 'Beta', disabled: true },
          { id: 'c', label: 'Gamma' },
        ]}
      />
    )
  }

  it('ArrowRight skips a disabled tab and wraps', () => {
    render(<Harness />)
    const alpha = screen.getByRole('tab', { name: 'Alpha' })
    fireEvent.keyDown(alpha, { key: 'ArrowRight' })
    const gamma = screen.getByRole('tab', { name: 'Gamma' })
    expect(gamma).toHaveAttribute('aria-selected', 'true')
    expect(gamma).toHaveFocus()
    expect(gamma).toHaveAttribute('tabindex', '0')
    expect(alpha).toHaveAttribute('tabindex', '-1')
    fireEvent.keyDown(gamma, { key: 'ArrowRight' })
    expect(screen.getByRole('tab', { name: 'Alpha' })).toHaveAttribute('aria-selected', 'true')
  })
})

describe('Slider', () => {
  it('PageUp adds 5 steps, clamps at max, and shows the unit', () => {
    const onChange = vi.fn()
    const { rerender } = render(
      <Slider label="Volume" value={10} min={0} max={30} step={2} unit="%" onChange={onChange} />,
    )
    expect(screen.getByText('10%')).toBeInTheDocument()
    const input = screen.getByRole('slider', { name: 'Volume' })
    expect(input).toHaveAttribute('aria-valuetext', '10%')
    fireEvent.keyDown(input, { key: 'PageUp' })
    expect(onChange).toHaveBeenLastCalledWith(20)
    rerender(<Slider label="Volume" value={26} min={0} max={30} step={2} unit="%" onChange={onChange} />)
    fireEvent.keyDown(input, { key: 'PageUp' })
    expect(onChange).toHaveBeenLastCalledWith(30)
  })
})

describe('Toggle', () => {
  it('click calls onChange with the inverse and exposes aria-checked', () => {
    const onChange = vi.fn()
    render(<Toggle label="Subtitles" checked={false} onChange={onChange} description="Show captions" />)
    const sw = screen.getByRole('switch', { name: 'Subtitles' })
    expect(sw).toHaveAttribute('aria-checked', 'false')
    expect(sw).toHaveAccessibleDescription('Show captions')
    fireEvent.click(sw)
    expect(onChange).toHaveBeenCalledWith(true)
  })
})

describe('Dropdown', () => {
  const options: DropdownOption[] = [
    { value: 'low', label: 'Low' },
    { value: 'mid', label: 'Medium', disabled: true, reason: 'Needs GPU' },
    { value: 'high', label: 'High' },
    { value: 'ultra', label: 'Ultra' },
  ]

  function Harness({ onChange }: { onChange: (v: string) => void }) {
    const [v, setV] = useState('low')
    return (
      <Dropdown
        label="Quality"
        value={v}
        options={options}
        onChange={(next) => {
          setV(next)
          onChange(next)
        }}
      />
    )
  }

  it('opens with ArrowDown, ArrowDown+Enter selects the next enabled option', () => {
    const onChange = vi.fn()
    render(<Harness onChange={onChange} />)
    const trigger = screen.getByRole('button', { name: /Quality/ })
    fireEvent.keyDown(trigger, { key: 'ArrowDown' })
    expect(trigger).toHaveAttribute('aria-expanded', 'true')
    const list = screen.getByRole('listbox')
    expect(list).toHaveFocus()
    expect(list.getAttribute('aria-activedescendant')).toBe(screen.getByRole('option', { name: 'Low' }).id)
    fireEvent.keyDown(list, { key: 'ArrowDown' })
    fireEvent.keyDown(list, { key: 'Enter' })
    expect(onChange).toHaveBeenCalledWith('high')
    expect(screen.queryByRole('listbox')).not.toBeInTheDocument()
    expect(trigger).toHaveFocus()
  })

  it('Escape closes and focuses the trigger', () => {
    render(<Harness onChange={vi.fn()} />)
    const trigger = screen.getByRole('button', { name: /Quality/ })
    fireEvent.keyDown(trigger, { key: 'ArrowDown' })
    fireEvent.keyDown(screen.getByRole('listbox'), { key: 'Escape' })
    expect(screen.queryByRole('listbox')).not.toBeInTheDocument()
    expect(trigger).toHaveFocus()
  })

  it('a disabled option cannot be chosen', () => {
    const onChange = vi.fn()
    render(<Harness onChange={onChange} />)
    fireEvent.keyDown(screen.getByRole('button', { name: /Quality/ }), { key: 'ArrowDown' })
    expect(screen.getByText('Needs GPU')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('option', { name: /Medium/ }))
    expect(onChange).not.toHaveBeenCalled()
    expect(screen.getByRole('listbox')).toBeInTheDocument()
  })

  it('typing h jumps to the first option starting with h', () => {
    render(<Harness onChange={vi.fn()} />)
    fireEvent.keyDown(screen.getByRole('button', { name: /Quality/ }), { key: 'ArrowDown' })
    const list = screen.getByRole('listbox')
    fireEvent.keyDown(list, { key: 'h' })
    expect(list.getAttribute('aria-activedescendant')).toBe(screen.getByRole('option', { name: 'High' }).id)
  })
})

describe('ToastTray', () => {
  it('shows only the last 4 toasts', () => {
    const toasts = Array.from({ length: 6 }, (_, i) => ({ id: `t${i}`, text: `Toast ${i}` }))
    render(<ToastTray toasts={toasts} />)
    expect(screen.queryByText('Toast 0')).not.toBeInTheDocument()
    expect(screen.queryByText('Toast 1')).not.toBeInTheDocument()
    expect(screen.getByText('Toast 2')).toBeInTheDocument()
    expect(screen.getByText('Toast 5')).toBeInTheDocument()
    expect(screen.getByRole('status')).toHaveAttribute('aria-live', 'polite')
  })

  it('renders nothing when empty', () => {
    const { container } = render(<ToastTray toasts={[]} />)
    expect(container).toBeEmptyDOMElement()
  })
})
