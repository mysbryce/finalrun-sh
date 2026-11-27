import { describe, expect, it } from 'vitest'
import { bindingText } from './format'

describe('bindingText', () => {
  it.each([
    ['ShiftLeft', 'Left Shift'],
    ['ControlLeft', 'Left Ctrl'],
    ['AltLeft', 'Left Alt'],
    ['MouseBack', 'Mouse 4'],
    ['Numpad7', 'Num 7'],
    ['ArrowUp', '↑'],
    ['Ctrl+KeyB', 'Ctrl+B'],
    ['F5', 'F5'],
  ])('%s -> %s', (code, text) => {
    expect(bindingText(code)).toBe(text)
  })

  it('null -> Unbound', () => {
    expect(bindingText(null)).toBe('Unbound')
  })
})
