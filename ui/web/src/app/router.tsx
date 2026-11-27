import {
  createRootRoute,
  createRoute,
  createRouter,
  createMemoryHistory,
  Outlet,
  useRouterState,
} from '@tanstack/react-router'
import { HudScreen } from '@/features/hud/HudScreen'
import { InventoryScreen } from '@/features/inventory/InventoryScreen'
import { LobbyScreen } from '@/features/lobby/LobbyScreen'
import { SearchScreen } from '@/features/search/SearchScreen'
import { SplashScreen } from '@/features/splash/SplashScreen'

function RootLayout() {
  const pathname = useRouterState({ select: (s) => s.location.pathname })
  return (
    <>
      {pathname !== '/inventory' && pathname !== '/splash' && pathname !== '/lobby' && <HudScreen />}
      <Outlet />
    </>
  )
}

const rootRoute = createRootRoute({ component: RootLayout })

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

const inventoryRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/inventory',
  component: InventoryScreen,
})

const splashRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/splash',
  component: SplashScreen,
})

const lobbyRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/lobby',
  component: LobbyScreen,
})

export const router = createRouter({
  routeTree: rootRoute.addChildren([hudRoute, searchRoute, inventoryRoute, splashRoute, lobbyRoute]),
  history: createMemoryHistory({ initialEntries: ['/'] }),
})

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
