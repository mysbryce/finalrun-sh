import { describe, expect, it } from 'vitest'
import { formatClock, formatMoney } from './format'

describe('formatMoney', () => {
  it('prefixes a dollar sign and groups thousands', () => {
    expect(formatMoney(0)).toBe('$0')
    expect(formatMoney(50)).toBe('$50')
    expect(formatMoney(79900)).toBe('$79,900')
  })
})

describe('formatClock', () => {
  it('formats seconds as m:ss', () => {
    expect(formatClock(2)).toBe('0:02')
    expect(formatClock(65)).toBe('1:05')
    expect(formatClock(720)).toBe('12:00')
  })

  it('treats negative seconds as 0', () => {
    expect(formatClock(-5)).toBe('0:00')
  })
})
