import { useHudStore } from './hudStore'
import { StatusPanel } from './components/StatusPanel'
import { TimerBanner } from './components/TimerBanner'
import { NotificationStack } from './components/NotificationStack'
import { InteractPrompt } from './components/InteractPrompt'

export function HudScreen() {
  const hud = useHudStore((s) => s.hud)
  if (!hud) return null

  return (
    <div className="pointer-events-none fixed inset-0">
      <StatusPanel hud={hud} />
      {hud.timer !== null && <TimerBanner timer={hud.timer} />}
      <NotificationStack items={hud.notifications} />
      {hud.prompt !== '' && <InteractPrompt text={hud.prompt} />}
    </div>
  )
}
