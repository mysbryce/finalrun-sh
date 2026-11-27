import { render } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { HealthBar } from './HealthBar'

function widths(container: HTMLElement): string[] {
  return Array.from(container.querySelectorAll<HTMLElement>('[style*="width"]')).map(
    (el) => el.style.width,
  )
}

describe('HealthBar', () => {
  it('fills segments by ratio', () => {
    const { container } = render(<HealthBar health={50} maxHealth={100} away={false} />)
    expect(widths(container)).toEqual(['100%', '100%', '0%', '0%'])
  })

  it('turns red when low', () => {
    const { container } = render(<HealthBar health={20} maxHealth={100} away={false} />)
    expect(container.querySelector<HTMLElement>('[style*="width"]')).toHaveClass('bg-red-500')
  })

  it('is empty when away', () => {
    const { container } = render(<HealthBar health={50} maxHealth={100} away={true} />)
    expect(widths(container)).toEqual(['0%', '0%', '0%', '0%'])
  })
})
