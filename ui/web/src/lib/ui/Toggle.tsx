import { useId } from 'react'

export interface ToggleProps {
  label: string
  checked: boolean
  onChange: (v: boolean) => void
  disabled?: boolean
  description?: string
}

export function Toggle({ label, checked, onChange, disabled = false, description }: ToggleProps) {
  const labelId = useId()
  const descId = useId()
  return (
    <div className="flex items-center gap-3">
      <div className="min-w-0 flex-1">
        <span id={labelId} className="block text-sm leading-5 text-zinc-100">
          {label}
        </span>
        {description && (
          <span id={descId} className="block text-xs leading-4 text-zinc-300">
            {description}
          </span>
        )}
      </div>
      <button
        type="button"
        role="switch"
        aria-checked={checked}
        aria-labelledby={labelId}
        aria-describedby={description ? descId : undefined}
        disabled={disabled}
        onClick={() => {
          if (!disabled) onChange(!checked)
        }}
        className="group flex h-9 items-center gap-2 rounded px-1 transition duration-[80ms] focus-visible:focus-ring disabled:cursor-not-allowed disabled:opacity-60"
      >
        <span
          className={`relative h-6 w-12 rounded-full border transition duration-[80ms] group-hover:border-zinc-500 group-active:inset-shadow-sm ${
            checked ? 'border-zinc-600 bg-zinc-800' : 'border-zinc-700 bg-zinc-700'
          }`}
        >
          <span
            className={`absolute top-[2px] left-[2px] h-[18px] w-[18px] rounded-full transition duration-[80ms] ${
              checked ? 'translate-x-6 bg-amber-400' : 'translate-x-0 bg-zinc-300'
            }`}
          />
        </span>
        <span aria-hidden="true" className="w-7 text-left text-sm leading-5 text-zinc-100">
          {checked ? 'On' : 'Off'}
        </span>
      </button>
    </div>
  )
}
