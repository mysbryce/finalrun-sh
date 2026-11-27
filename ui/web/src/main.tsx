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
import { App } from '@/app/App'

applyUiScale()
window.addEventListener('resize', applyUiScale)

installBridge({
  setHud: (h) => useHudStore.getState().setHud(h),
  navigate: (to) => {
    void router.navigate({ to })
  },
  setSearch: (v) => useSearchStore.getState().setSearch(v),
})

if (import.meta.env.DEV && !window.sendIpcMessage) {
  useHudStore.getState().setHud(DEMO_HUD)
  if (window.location.hash === '#search') {
    useSearchStore.getState().setSearch(DEMO_SEARCH)
    void router.navigate({ to: '/search' })
  }
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
