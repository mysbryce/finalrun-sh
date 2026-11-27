const HIDDEN = new Set(['/inventory', '/search', '/splash', '/lobby', '/death', '/arrest', '/transfer'])

/** True when the HUD layer is drawn under the route's screen. */
export function showsHud(pathname: string): boolean {
  return !HIDDEN.has(pathname) && !pathname.startsWith('/settings')
}
