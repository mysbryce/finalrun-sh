import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import '@/styles/index.css'
import { installBridge } from '@/lib/ipc/bridge'
import { router } from '@/app/router'
import { applyUiScale } from '@/app/uiScale'
import { useHudStore } from '@/features/hud/hudStore'
import { DEMO_HUD } from '@/features/hud/demoHud'
import { useSearchStore } from '@/features/search/searchStore'
import { DEMO_SEARCH } from '@/features/search/demoSearch'
import { useInventoryStore } from '@/features/inventory/inventoryStore'
import { DEMO_INVENTORY } from '@/features/inventory/demoInventory'
import { useSplashStore } from '@/features/splash/splashStore'
import { DEMO_BOOT } from '@/features/splash/demoBoot'
import { App } from '@/app/App'

applyUiScale()
window.addEventListener('resize', applyUiScale)

installBridge({
  setHud: (h) => useHudStore.getState().setHud(h),
  navigate: (to) => {
    void router.navigate({ to })
  },
  setSearch: (v) => useSearchStore.getState().setSearch(v),
  setInventory: (v) => useInventoryStore.getState().setInventory(v),
  setBoot: (v) => useSplashStore.getState().setBoot(v),
})

if (import.meta.env.DEV && !window.sendIpcMessage) {
  useHudStore.getState().setHud(DEMO_HUD)
  if (window.location.hash === '#search') {
    useSearchStore.getState().setSearch(DEMO_SEARCH)
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
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
