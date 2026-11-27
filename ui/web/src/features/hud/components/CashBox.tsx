import { formatMoney } from '@/lib/format'

export function CashBox({ cash }: { cash: number }) {
  return (
    <div className="absolute right-6 top-4 bg-zinc-950/60 rounded-md ring-1 ring-white/10 px-4 py-1.5 text-xl font-bold">
      {formatMoney(cash)}
    </div>
  )
}
