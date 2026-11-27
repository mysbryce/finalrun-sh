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
import { SearchScreen } from '@/features/search/SearchScreen'

function RootLayout() {
  const pathname = useRouterState({ select: (s) => s.location.pathname })
  return (
    <>
      {pathname !== '/inventory' && <HudScreen />}
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

export const router = createRouter({
  routeTree: rootRoute.addChildren([hudRoute, searchRoute, inventoryRoute]),
  history: createMemoryHistory({ initialEntries: ['/'] }),
})

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
