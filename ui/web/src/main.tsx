import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import '@/styles/index.css'
import { installBridge } from '@/lib/ipc/bridge'
import { router } from '@/app/router'
import { applyPrefs, applyUiScale } from '@/app/uiScale'
import { prefsFromValues, usePrefs } from '@/lib/prefs'
import type { SettingsView } from '@/lib/ipc/protocol'
import { useHudStore } from '@/features/hud/hudStore'
import { DEMO_HUD } from '@/features/hud/demoHud'
import { useOverlayStore } from '@/features/hud/overlayStore'
import {
  DEMO_RECEIPT_ARREST,
  DEMO_RECEIPT_DEATH,
  DEMO_TRANSFER,
  DEMO_TRANSFER_FAILED,
} from '@/features/hud/demoOverlay'
import { useSearchStore } from '@/features/search/searchStore'
import { DEMO_SEARCH } from '@/features/search/demoSearch'
import { useInventoryStore } from '@/features/inventory/inventoryStore'
import { DEMO_INVENTORY } from '@/features/inventory/demoInventory'
import { useSplashStore } from '@/features/splash/splashStore'
import { DEMO_BOOT } from '@/features/splash/demoBoot'
import { useLobbyStore } from '@/features/lobby/lobbyStore'
import { DEMO_LOBBY } from '@/features/lobby/demoLobby'
import { usePartyStore } from '@/features/pause/partyStore'
import { DEMO_PARTY } from '@/features/pause/demoParty'
import { useSettingsStore } from '@/features/settings/settingsStore'
import { DEMO_SETTINGS } from '@/features/settings/demoSettings'
import { App } from '@/app/App'

applyUiScale()
window.addEventListener('resize', applyUiScale)
applyPrefs(usePrefs.getState())
usePrefs.subscribe(applyPrefs)

function onSettings(view: SettingsView): void {
  useSettingsStore.getState().setView(view)
  usePrefs.setState(prefsFromValues(view.values))
}

installBridge({
  setHud: (h) => useHudStore.getState().setHud(h),
  navigate: (to) => {
    void router.navigate({ to })
  },
  setSearch: (v) => useSearchStore.getState().setSearch(v),
  setInventory: (v) => useInventoryStore.getState().setInventory(v),
  setBoot: (v) => useSplashStore.getState().setBoot(v),
  setLobby: (v) => useLobbyStore.getState().setLobby(v),
  setParty: (v) => usePartyStore.getState().setParty(v),
  setSettings: onSettings,
  setTransfer: (v) => useOverlayStore.getState().setTransfer(v),
  setGameOverlay: (v) => useOverlayStore.getState().setOverlay(v),
})

if (import.meta.env.DEV && !window.sendIpcMessage) {
  useHudStore.getState().setHud(DEMO_HUD)
  if (window.location.hash === '#search') {
    useSearchStore.getState().setSearch(DEMO_SEARCH)
    useInventoryStore.getState().setInventory(DEMO_INVENTORY)
    void router.navigate({ to: '/search' })
  }
  if (window.location.hash === '#inventory') {
    useInventoryStore.getState().setInventory(DEMO_INVENTORY)
    void router.navigate({ to: '/inventory' })
  }
  if (window.location.hash === '#splash') {
    useSplashStore.getState().setBoot(DEMO_BOOT)
    void router.navigate({ to: '/splash' })
  }
  if (window.location.hash === '#lobby') {
    useLobbyStore.getState().setLobby(DEMO_LOBBY)
    void router.navigate({ to: '/lobby' })
  }
  if (window.location.hash === '#pause') {
    usePartyStore.getState().setParty(DEMO_PARTY)
    void router.navigate({ to: '/pause' })
  }
  if (window.location.hash === '#settings') {
    onSettings(DEMO_SETTINGS)
    void router.navigate({ to: '/settings/graphics' })
  }
  if (window.location.hash === '#death') {
    useOverlayStore.getState().setOverlay(DEMO_RECEIPT_DEATH)
    void router.navigate({ to: '/death' })
  }
  if (window.location.hash === '#arrest') {
    useOverlayStore.getState().setOverlay(DEMO_RECEIPT_ARREST)
    void router.navigate({ to: '/arrest' })
  }
  if (window.location.hash === '#receipt') {
    useOverlayStore.getState().setOverlay(DEMO_RECEIPT_DEATH)
  }
  if (window.location.hash === '#transfer') {
    useOverlayStore.getState().setTransfer(DEMO_TRANSFER)
    void router.navigate({ to: '/transfer' })
  }
  if (window.location.hash === '#transfer-failed') {
    useOverlayStore.getState().setTransfer(DEMO_TRANSFER_FAILED)
    void router.navigate({ to: '/transfer' })
  }
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
