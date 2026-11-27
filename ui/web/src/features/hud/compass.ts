import { COMPASS_PX_PER_DEG } from './layout'

export type CompassMark = { deg: number; offset: number; label: string; major: boolean }

const LABELS = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']

export function compassMarks(
  heading: number,
  halfSpan = 70,
  step = 15,
  pxPerDeg = COMPASS_PX_PER_DEG,
): CompassMark[] {
  const marks: CompassMark[] = []
  const start = Math.ceil((heading - halfSpan) / step) * step
  for (let d = start; d <= heading + halfSpan; d += step) {
    const deg = ((d % 360) + 360) % 360
    const major = deg % 45 === 0
    marks.push({
      deg,
      offset: (d - heading) * pxPerDeg,
      label: major ? LABELS[deg / 45] : String(deg),
      major,
    })
  }
  return marks
}
