import { ToastTray, type Toast } from '@/lib/ui/ToastTray'
import { NOTIFICATIONS } from '../layout'

const MAX_ROWS = 4

// The heist toast takes the top row; ordinary notifications (newest kept) fill the rest.
export function NotificationStack({ items, heistToast }: { items: string[]; heistToast?: string | null }) {
  const toasts: Toast[] = []
  if (heistToast) toasts.push({ id: 'heist', text: heistToast, priority: 'high' })
  const room = MAX_ROWS - toasts.length
  items.slice(-room).forEach((text, index) => toasts.push({ id: `n${index}`, text }))
  return (
    <div className="absolute left-1/2 -translate-x-1/2" style={{ top: NOTIFICATIONS.top, width: NOTIFICATIONS.width }}>
      <ToastTray toasts={toasts} />
    </div>
  )
}
