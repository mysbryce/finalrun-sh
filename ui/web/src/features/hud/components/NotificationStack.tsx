export function NotificationStack({ items }: { items: string[] }) {
  return (
    <div className="absolute left-1/2 top-14 -translate-x-1/2 flex flex-col items-center gap-1">
      {items.map((notification, index) => (
        <div
          key={index}
          className="bg-zinc-950/60 rounded-md ring-1 ring-white/10 px-3 py-1 text-sm"
        >
          {notification}
        </div>
      ))}
    </div>
  )
}
