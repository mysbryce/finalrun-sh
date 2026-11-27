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
import { PauseScreen } from '@/features/pause/PauseScreen'
import { SearchScreen } from '@/features/search/SearchScreen'
import { SettingsScreen } from '@/features/settings/SettingsScreen'
import { SplashScreen } from '@/features/splash/SplashScreen'
import type { SettingsTab } from '@/lib/ipc/protocol'

function RootLayout() {
  const pathname = useRouterState({ select: (s) => s.location.pathname })
  return (
    <>
      {pathname !== '/inventory' && pathname !== '/splash' && pathname !== '/lobby' && !pathname.startsWith('/settings') && (
        <HudScreen />
      )}
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

// The HUD stays visible under the pause menu (RootLayout does not hide it on /pause).
const pauseRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/pause',
  component: PauseScreen,
})

const SETTINGS_TABS: SettingsTab[] = ['graphics', 'controls', 'social', 'others']

// One static route per tab: Godot navigates between them after `settings.tab`.
const settingsRoutes = SETTINGS_TABS.map((tab) =>
  createRoute({
    getParentRoute: () => rootRoute,
    path: `/settings/${tab}`,
    component: () => <SettingsScreen tab={tab} />,
  }),
)

export const router = createRouter({
  routeTree: rootRoute.addChildren([
    hudRoute,
    searchRoute,
    inventoryRoute,
    splashRoute,
    lobbyRoute,
    pauseRoute,
    ...settingsRoutes,
  ]),
  history: createMemoryHistory({ initialEntries: ['/'] }),
})

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
