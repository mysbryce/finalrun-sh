import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'
import { SETTINGS, defaultsFor, entriesFor, groupsFor } from './schema'

describe('settings schema', () => {
  it('every entry has a group', () => {
    expect(SETTINGS.length).toBeGreaterThan(0)
    for (const e of SETTINGS) expect(e.group, e.key).toBeTruthy()
  })

  it('has the four tabs', () => {
    for (const tab of ['graphics', 'controls', 'social', 'others'] as const) {
      expect(entriesFor(tab).length, tab).toBeGreaterThan(0)
    }
  })

  it('lists groups in order of first appearance', () => {
    expect(groupsFor('graphics')).toEqual(['Display', 'Quality', 'Accessibility'])
  })

  it('reads defaults', () => {
    expect(defaultsFor(['fov', 'vsync', 'bind_fire'])).toEqual({ fov: 75, vsync: true, bind_fire: 'MouseLeft' })
  })

  it('runtime copy equals the design copy', () => {
    // vitest runs with cwd = ui/web
    const runtime = JSON.parse(readFileSync(resolve(process.cwd(), 'public/settings-schema.json'), 'utf8'))
    const design = JSON.parse(
      readFileSync(resolve(process.cwd(), '../../docs/ui-design/settings-schema.json'), 'utf8'),
    )
    expect(runtime).toEqual(design)
  })
})
