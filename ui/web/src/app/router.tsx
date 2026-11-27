import { createRootRoute, createRoute, createRouter, createMemoryHistory, Outlet } from '@tanstack/react-router'
import { HudScreen } from '@/features/hud/HudScreen'

const rootRoute = createRootRoute({ component: () => <Outlet /> })

const hudRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  component: HudScreen,
})

export const router = createRouter({
  routeTree: rootRoute.addChildren([hudRoute]),
  history: createMemoryHistory({ initialEntries: ['/'] }),
})

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
