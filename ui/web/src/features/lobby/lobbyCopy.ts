import type { ConnectionError, ConnectionStatus } from '@/lib/ipc/protocol'

export function connectionLabel(status: ConnectionStatus): string {
  switch (status) {
    case 'disconnected':
      return 'Disconnected'
    case 'resolving':
      return 'Resolving'
    case 'connecting':
      return 'Connecting'
    case 'connected':
      return 'Connected'
    case 'failed':
      return 'Connection failed'
  }
}

export function connectionErrorText(error: ConnectionError): string {
  switch (error) {
    case 'invalid_endpoint':
      return 'The server address is invalid.'
    case 'invalid_server_id':
      return 'The server ID is invalid.'
    case 'server_not_found':
      return 'The server could not be found.'
    case 'server_full':
      return 'The server is full.'
    case 'version_mismatch':
      return 'The server runs a different game version.'
    case 'connection_failed':
      return 'Could not reach the server.'
    case 'connection_timeout':
      return 'The server did not answer in time.'
    case 'disconnected':
      return 'The server closed the connection.'
    case 'discovery_unavailable':
      return 'Server discovery is not available.'
  }
}
