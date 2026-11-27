import type { SettingEntry } from './schema'

const OPTION_WORDS: Record<string, string> = {
  fxaa: 'FXAA',
  native: 'Native',
  unlimited: 'Unlimited',
  en: 'English',
  push_to_talk: 'Push to talk',
}

/** Human label for an enum option (`msaa_4x` -> `MSAA 4×`, `1920x1080` -> `1920 × 1080`). */
export function optionLabel(key: string, option: string): string {
  if (OPTION_WORDS[option]) return OPTION_WORDS[option]
  const msaa = /^msaa_(\d+)x$/.exec(option)
  if (msaa) return `MSAA ${msaa[1]}×`
  const res = /^(\d+)x(\d+)$/.exec(option)
  if (res) return `${res[1]} × ${res[2]}`
  if (key === 'frame_cap' && /^\d+$/.test(option)) return `${option} FPS`
  const words = option.split('_').join(' ')
  return words.charAt(0).toUpperCase() + words.slice(1)
}

/** Slider readout for a numeric setting. */
export function valueText(entry: SettingEntry, v: number): string {
  const key = entry.key
  if (key === 'render_scale' || key === 'ui_scale' || key.endsWith('_volume')) return `${v}%`
  if (key === 'fov') return `${v}°`
  if (key === 'notifications_duration') return `${v} s`
  if (key === 'voice_input_threshold') return `${v} dBFS`
  if (key === 'gamma') return v.toFixed(2)
  if (key === 'mouse_sensitivity') return v.toFixed(4)
  return String(v)
}

const NAMED: Record<string, string> = {
  MouseLeft: 'LMB',
  MouseRight: 'RMB',
  MouseMiddle: 'MMB',
  MouseBack: 'Mouse 4',
  MouseForward: 'Mouse 5',
  MouseMotion: 'Mouse',
  ShiftLeft: 'Left Shift',
  ShiftRight: 'Right Shift',
  ControlLeft: 'Left Ctrl',
  ControlRight: 'Right Ctrl',
  AltLeft: 'Left Alt',
  AltRight: 'Right Alt',
  Escape: 'Esc',
  Backquote: '`',
  Minus: '-',
  Equal: '=',
  BracketLeft: '[',
  BracketRight: ']',
  Backslash: '\\',
  Semicolon: ';',
  Quote: "'",
  Comma: ',',
  Period: '.',
  Slash: '/',
  ArrowUp: '↑',
  ArrowDown: '↓',
  ArrowLeft: '←',
  ArrowRight: '→',
  PageUp: 'Page Up',
  PageDown: 'Page Down',
  CapsLock: 'Caps Lock',
}

function codeText(code: string): string {
  if (NAMED[code]) return NAMED[code]
  const key = /^Key([A-Z])$/.exec(code)
  if (key) return key[1]
  const digit = /^Digit(\d)$/.exec(code)
  if (digit) return digit[1]
  const numpad = /^Numpad(\d)$/.exec(code)
  if (numpad) return `Num ${numpad[1]}`
  return code
}

/** Readable physical binding (`Ctrl+KeyB` -> `Ctrl+B`, `MouseLeft` -> `LMB`, null -> `Unbound`). */
export function bindingText(code: string | null): string {
  if (code === null || code === '') return 'Unbound'
  const parts = code.split('+')
  const main = parts.pop() as string
  return [...parts, codeText(main)].join('+')
}
