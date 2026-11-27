export interface ProgressBarProps {
  label: string
  value?: number
  max: number
  size?: 'default' | 'compact'
  showValue?: boolean
}

const STRIPES = {
  backgroundImage:
    'repeating-linear-gradient(135deg, var(--color-zinc-700) 0 4px, var(--color-zinc-800) 4px 8px)',
}

export function ProgressBar({ label, value, max, size = 'default', showValue = false }: ProgressBarProps) {
  const determinate = value !== undefined
  const ratio = determinate && max > 0 ? Math.min(1, Math.max(0, value / max)) : 0
  return (
    <div className="flex items-center gap-2">
      <div
        role="progressbar"
        aria-label={label}
        aria-valuemin={0}
        aria-valuemax={max}
        aria-valuenow={determinate ? value : undefined}
        className={`relative flex-1 overflow-hidden rounded-sm bg-zinc-800 ${size === 'compact' ? 'h-1' : 'h-3'}`}
        style={determinate ? undefined : STRIPES}
      >
        {determinate && <div className="h-full bg-amber-400" style={{ width: `${ratio * 100}%` }} />}
      </div>
      {!determinate && <span className="text-xs leading-4 text-zinc-300">Working</span>}
      {determinate && showValue && (
        <span className="tabular text-xs leading-4 text-zinc-100">
          {max > 0 ? Math.round((100 * value) / max) : 0}%
        </span>
      )}
    </div>
  )
}
