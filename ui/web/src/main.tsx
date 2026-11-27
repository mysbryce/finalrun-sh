import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import '@/styles/index.css'
import { installBridge } from '@/lib/ipc/bridge'
import { router } from '@/app/router'
import { useHudStore } from '@/features/hud/hudStore'
import { App } from '@/app/App'

installBridge({
  setHud: (h) => useHudStore.getState().setHud(h),
  navigate: (to) => {
    void router.navigate({ to })
  },
})

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
