import type { BootError, BootPhase, BootView } from '@/lib/ipc/protocol'
import type { Stage, StageState } from '@/lib/ui/StageRail'

function phaseLabel(phase: BootPhase): string {
  switch (phase) {
    case 'assets':
      return 'Loading game files'
    case 'title':
    case 'cef':
      return 'Loading interface'
    case 'connecting':
      return 'Connecting to server'
    case 'ready':
      return 'Ready'
    case 'failed':
      return 'Failed'
  }
}

export function stageLabel(view: BootView): string {
  return phaseLabel(view.phase)
}

export function errorText(error: BootError): string {
  switch (error) {
    case 'asset_load_failed':
      return 'Game files failed to load.'
    case 'cef_unavailable':
      return 'The interface could not start.'
    case 'cef_timeout':
      return 'The interface took too long to load.'
    case 'invalid_endpoint':
      return 'The server address is invalid.'
    case 'connection_failed':
      return 'Could not reach the server.'
    case 'connection_timeout':
      return 'The server did not answer in time.'
  }
}

type StageKey = 'assets' | 'interface' | 'connection'

const ORDER: StageKey[] = ['assets', 'interface', 'connection']

const LABEL: Record<StageKey, string> = {
  assets: 'Assets',
  interface: 'Interface',
  connection: 'Connection',
}

/** Stage that is in progress for a non-failed phase. */
function currentOf(phase: Exclude<BootPhase, 'failed'>): StageKey | null {
  switch (phase) {
    case 'assets':
      return 'assets'
    case 'title':
    case 'cef':
      return 'interface'
    case 'connecting':
      return 'connection'
    case 'ready':
      return null
  }
}

function failedOf(error: BootError): StageKey {
  switch (error) {
    case 'asset_load_failed':
      return 'assets'
    case 'cef_unavailable':
    case 'cef_timeout':
      return 'interface'
    case 'invalid_endpoint':
    case 'connection_failed':
    case 'connection_timeout':
      return 'connection'
  }
}

function railStates(active: StageKey | null, activeState: StageState): Stage[] {
  const activeIndex = active === null ? ORDER.length : ORDER.indexOf(active)
  return ORDER.map((key, i) => ({
    label: LABEL[key],
    state: i < activeIndex ? 'done' : i === activeIndex ? activeState : 'pending',
  }))
}

/** The three rail stages in Assets -> Interface -> Connection order. */
export function stagesOf(view: BootView): Stage[] {
  if (view.phase === 'failed') {
    return railStates(view.error ? failedOf(view.error) : 'connection', 'failed')
  }
  return railStates(currentOf(view.phase), 'current')
}
