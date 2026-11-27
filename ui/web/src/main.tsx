import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import '@/styles/index.css'
import { installBridge } from '@/lib/ipc/bridge'
import { router } from '@/app/router'
import { applyUiScale } from '@/app/uiScale'
import { useHudStore } from '@/features/hud/hudStore'
import { DEMO_HUD } from '@/features/hud/demoHud'
import { App } from '@/app/App'

applyUiScale()
window.addEventListener('resize', applyUiScale)

installBridge({
  setHud: (h) => useHudStore.getState().setHud(h),
  navigate: (to) => {
    void router.navigate({ to })
  },
})

if (import.meta.env.DEV && !window.sendIpcMessage) useHudStore.getState().setHud(DEMO_HUD)

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
