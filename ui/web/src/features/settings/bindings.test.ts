import { describe, expect, it } from 'vitest'
import { canUnbind, findConflict } from './bindings'
import { SETTINGS, defaultsFor } from './schema'

const values = defaultsFor(SETTINGS.map((e) => e.key))
const enabled = { visible: true, enabled: true, reason: null }

describe('findConflict', () => {
  it('KeyW for Interact conflicts with Move forward', () => {
    expect(findConflict('bind_interact', 'KeyW', values)).toBe('bind_move_forward')
  })

  it('a game key does not conflict with a debug shortcut', () => {
    expect(findConflict('bind_hotbar_1', 'KeyY', values)).toBeNull()
  })

  it('debug shortcuts conflict with each other', () => {
    expect(findConflict('bind_join_house', 'Ctrl+Digit1', values)).toBe('bind_join_motel')
  })

  it('null never conflicts', () => {
    expect(findConflict('bind_interact', null, { ...values, bind_fire: null })).toBeNull()
  })

  it('ignores the key itself', () => {
    expect(findConflict('bind_interact', 'KeyE', values)).toBeNull()
  })
})

describe('canUnbind', () => {
  it('fixed keys cannot be unbound', () => {
    expect(canUnbind('bind_pause', enabled)).toBe(false)
  })

  it('not-enabled keys cannot be unbound', () => {
    expect(canUnbind('bind_reload', { visible: true, enabled: false, reason: 'coming_later' })).toBe(false)
  })

  it('enabled, non-fixed keys can be unbound', () => {
    expect(canUnbind('bind_fire', enabled)).toBe(true)
  })
})
