import { describe, expect, it } from 'vitest'
import { compassMarks } from './compass'

function findLabel(marks: ReturnType<typeof compassMarks>, label: string) {
  return marks.find((mark) => mark.label === label)
}

describe('compassMarks', () => {
  it('puts north at center for heading 0', () => {
    expect(compassMarks(0)).toContainEqual({ deg: 0, offset: 0, label: 'N', major: true })
  })

  it('puts east at center for heading 90', () => {
    const center = compassMarks(90).find((mark) => mark.offset === 0)
    expect(center?.label).toBe('E')
  })

  it('places the 15 degree mark at offset 60 for heading 0', () => {
    const mark = findLabel(compassMarks(0), '15')
    expect(mark?.offset).toBe(60)
  })

  it('wraps north for heading 350', () => {
    const mark = findLabel(compassMarks(350), 'N')
    expect(mark).toEqual({ deg: 0, offset: 40, label: 'N', major: true })
  })

  it('wraps below 0 for heading 10', () => {
    const mark = findLabel(compassMarks(10), '345')
    expect(mark?.deg).toBe(345)
  })
})
