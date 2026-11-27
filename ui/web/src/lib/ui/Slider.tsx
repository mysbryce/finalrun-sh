import { useId } from 'react'
import type { KeyboardEvent } from 'react'

export interface SliderProps {
  label: string
  value: number
  min: number
  max: number
  step: number
  unit?: string
  disabled?: boolean
  onChange: (v: number) => void
  format?: (v: number) => string
}

function snapToStep(v: number, min: number, max: number, step: number): number {
  const snapped = step > 0 ? min + Math.round((v - min) / step) * step : v
  return Math.min(max, Math.max(min, snapped))
}

const THUMB =
  '[&::-webkit-slider-thumb]:h-3.5 [&::-webkit-slider-thumb]:w-3.5 [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-zinc-100 [&::-moz-range-thumb]:h-3.5 [&::-moz-range-thumb]:w-3.5 [&::-moz-range-thumb]:rounded-full [&::-moz-range-thumb]:border-0 [&::-moz-range-thumb]:bg-zinc-100 active:[&::-webkit-slider-thumb]:bg-amber-400'

export function Slider({ label, value, min, max, step, unit, disabled = false, onChange, format }: SliderProps) {
  const labelId = useId()
  const readout = format ? format(value) : `${value}${unit ?? ''}`
  const ratio = max > min ? (Math.min(max, Math.max(min, value)) - min) / (max - min) : 0

  const onKeyDown = (e: KeyboardEvent<HTMLInputElement>) => {
    if (disabled || (e.key !== 'PageUp' && e.key !== 'PageDown')) return
    e.preventDefault()
    const next = snapToStep(value + (e.key === 'PageUp' ? 5 : -5) * step, min, max, step)
    if (next !== value) onChange(next)
  }

  return (
    <div className="flex h-9 items-center gap-3">
      <span id={labelId} className="min-w-0 flex-1 truncate text-sm leading-5 text-zinc-100">{label}</span>
      <input
        type="range"
        min={min}
        max={max}
        step={step}
        value={value}
        disabled={disabled}
        aria-labelledby={labelId}
        aria-valuetext={readout}
        onKeyDown={onKeyDown}
        onChange={(e) => {
          if (!disabled) onChange(snapToStep(Number(e.target.value), min, max, step))
        }}
        style={{
          background: `linear-gradient(to right, var(--color-amber-400) ${ratio * 100}%, var(--color-zinc-700) ${ratio * 100}%)`,
        }}
        className={`h-1 flex-1 cursor-pointer appearance-none rounded-sm transition duration-[80ms] hover:brightness-125 focus-visible:focus-ring disabled:cursor-not-allowed disabled:opacity-60 ${THUMB}`}
      />
      <span className="tabular w-16 text-right text-sm leading-5 text-zinc-100">{readout}</span>
    </div>
  )
}
