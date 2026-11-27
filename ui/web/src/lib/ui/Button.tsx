export type ButtonVariant = 'primary' | 'secondary' | 'quiet' | 'destructive'

export interface ButtonProps {
  label: string
  variant?: ButtonVariant
  size?: 'default' | 'compact'
  disabled?: boolean
  loading?: boolean
  onPress?: () => void
  describedBy?: string
  type?: 'button' | 'submit'
}

const VARIANT: Record<ButtonVariant, string> = {
  primary: 'bg-amber-400 text-zinc-900 hover:brightness-110',
  secondary: 'bg-zinc-800 border border-zinc-500 text-zinc-100 hover:bg-zinc-700',
  quiet: 'text-zinc-300 hover:bg-zinc-800',
  destructive: 'bg-zinc-800 border border-zinc-500 text-zinc-100 hover:bg-zinc-700',
}

export function Button({
  label,
  variant = 'secondary',
  size = 'default',
  disabled = false,
  loading = false,
  onPress,
  describedBy,
  type = 'button',
}: ButtonProps) {
  const inert = disabled || loading
  return (
    <button
      type={type}
      disabled={inert}
      aria-busy={loading ? 'true' : undefined}
      aria-describedby={describedBy}
      onClick={() => {
        if (!inert) onPress?.()
      }}
      className={`${size === 'compact' ? 'h-9' : 'h-10'} min-w-[88px] rounded px-4 text-sm leading-5 font-semibold transition duration-[80ms] active:translate-y-px focus-visible:focus-ring disabled:opacity-60 ${VARIANT[variant]}`}
    >
      {label}
    </button>
  )
}
