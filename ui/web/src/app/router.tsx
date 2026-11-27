import { createRootRoute, createRoute, createRouter, createMemoryHistory, Outlet } from '@tanstack/react-router'
import { HudScreen } from '@/features/hud/HudScreen'
import { SearchScreen } from '@/features/search/SearchScreen'

const rootRoute = createRootRoute({
  component: () => (
    <>
      <HudScreen />
      <Outlet />
    </>
  ),
})

const hudRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  component: () => null,
})

const searchRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/search',
  component: SearchScreen,
})

export const router = createRouter({
  routeTree: rootRoute.addChildren([hudRoute, searchRoute]),
  history: createMemoryHistory({ initialEntries: ['/'] }),
})

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
