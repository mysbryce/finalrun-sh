import { useHudStore } from './hudStore'
import { NetStats } from './components/NetStats'
import { MinimapFrame } from './components/MinimapFrame'
import { StatusColumn } from './components/StatusColumn'
import { Compass } from './components/Compass'
import { NotificationStack } from './components/NotificationStack'
import { BleedOutBanner } from './components/BleedOutBanner'
import { CashBox } from './components/CashBox'
import { PartyPanel } from './components/PartyPanel'
import { Hotbar } from './components/Hotbar'
import { InteractCard } from './components/InteractCard'

export function HudScreen() {
  const hud = useHudStore((s) => s.hud)
  if (!hud) return null

  return (
    <div className="pointer-events-none fixed inset-0 text-white">
      <NetStats fps={hud.net.fps} ping={hud.net.ping} />
      <MinimapFrame heading={hud.heading} />
      <StatusColumn hud={hud} />
      <Compass heading={hud.heading} />
      <NotificationStack items={hud.notifications} />
      {hud.life === 'DOWNED' && hud.timer && <BleedOutBanner seconds={hud.timer.seconds} />}
      <CashBox cash={hud.cash} />
      <PartyPanel
        party={hud.party}
        self={hud.self}
        health={hud.health}
        maxHealth={hud.maxHealth}
      />
      <Hotbar slots={hud.hotbar} active={hud.activeSlot} bag={hud.bag} />
      {hud.interact && <InteractCard interact={hud.interact} />}
    </div>
  )
}
