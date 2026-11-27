import {
  createRootRoute,
  createRoute,
  createRouter,
  createMemoryHistory,
  Outlet,
  useRouterState,
} from '@tanstack/react-router'
import { HudScreen } from '@/features/hud/HudScreen'
import { ReceiptCard } from '@/features/hud/ReceiptCard'
import { ReceiptScreen } from '@/features/hud/ReceiptScreen'
import { TransferScreen } from '@/features/hud/TransferScreen'
import { InventoryScreen } from '@/features/inventory/InventoryScreen'
import { LobbyScreen } from '@/features/lobby/LobbyScreen'
import { PauseScreen } from '@/features/pause/PauseScreen'
import { SearchScreen } from '@/features/search/SearchScreen'
import { SettingsScreen } from '@/features/settings/SettingsScreen'
import { SplashScreen } from '@/features/splash/SplashScreen'
import type { SettingsTab } from '@/lib/ipc/protocol'
import { showsHud } from './showsHud'

function RootLayout() {
  const pathname = useRouterState({ select: (s) => s.location.pathname })
  return (
    <>
      {showsHud(pathname) && <HudScreen />}
      <Outlet />
    </>
  )
}

const rootRoute = createRootRoute({ component: RootLayout })

const hudRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  component: ReceiptCard,
})

const deathRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/death',
  component: ReceiptScreen,
})

const arrestRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/arrest',
  component: ReceiptScreen,
})

const transferRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/transfer',
  component: TransferScreen,
})

const searchRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/search',
  component: () => (
    <>
      <SearchScreen />
      <InventoryScreen embedded />
    </>
  ),
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
    deathRoute,
    arrestRoute,
    transferRoute,
    ...settingsRoutes,
  ]),
  history: createMemoryHistory({ initialEntries: ['/'] }),
})

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
