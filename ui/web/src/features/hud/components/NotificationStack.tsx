export function NotificationStack({ items }: { items: string[] }) {
  return (
    <div className="absolute right-4 top-4 flex flex-col items-end gap-1">
      {items.map((notification, index) => (
        <div
          key={index}
          className="rounded-lg bg-black/60 px-3 py-1 text-sm text-white"
        >
          {notification}
        </div>
      ))}
    </div>
  )
}
