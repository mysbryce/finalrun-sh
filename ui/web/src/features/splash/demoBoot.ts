import type { BootView } from '@/lib/ipc/protocol'

export const DEMO_BOOT: BootView = {
  phase: 'failed',
  buildId: '0.1.0',
  progress: null,
  canSkipTitle: false,
  error: 'connection_failed',
  canRetry: true,
}
