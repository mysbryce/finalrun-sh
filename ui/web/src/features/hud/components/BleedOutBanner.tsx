export function BleedOutBanner({ seconds }: { seconds: number }) {
  return (
    <div className="absolute left-1/2 top-28 -translate-x-1/2 rounded-md bg-amber-600/90 px-6 py-2 text-3xl font-bold tracking-wider">
      BLEEDING OUT {seconds}
    </div>
  )
}
