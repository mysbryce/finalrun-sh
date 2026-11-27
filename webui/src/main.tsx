import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClientProvider } from '@tanstack/react-query'
import { RouterProvider } from '@tanstack/react-router'
import './index.css'
import { installBridge } from './bridge'
import { queryClient } from './queryClient'
import { router } from './router'
import { useHudStore } from './store'

installBridge({
  setHud: (h) => useHudStore.getState().setHud(h),
  navigate: (to) => {
    void router.navigate({ to })
  },
})

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>
  </StrictMode>,
)
