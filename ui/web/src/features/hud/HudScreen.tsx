import { useRouterState } from '@tanstack/react-router'
import { usePrefs } from '@/lib/prefs'
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
  const showCompass = usePrefs((s) => s.showCompass)
  const minimapRotate = usePrefs((s) => s.minimapRotate)
  const panelOpen = useRouterState({ select: (s) => s.location.pathname !== '/' })
  if (!hud) return null

  return (
    <div className="pointer-events-none fixed inset-0 text-white">
      <NetStats fps={hud.net.fps} ping={hud.net.ping} />
      {/* Rotating minimap: Godot turns the map, the arrow stays pointing up. */}
      <MinimapFrame heading={minimapRotate ? 0 : hud.heading} />
      <StatusColumn hud={hud} />
      {showCompass && <Compass heading={hud.heading} />}
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
      {hud.interact && !panelOpen && <InteractCard interact={hud.interact} />}
    </div>
  )
}
