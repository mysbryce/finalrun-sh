import { useState } from 'react'
import type { CSSProperties } from 'react'
import { request } from '@/lib/ipc/bridge'
import type { LobbyView } from '@/lib/ipc/protocol'
import { Button } from '@/lib/ui/Button'
import { Modal } from '@/lib/ui/Modal'
import { Panel } from '@/lib/ui/Panel'
import { ProgressBar } from '@/lib/ui/ProgressBar'
import { connectionErrorText, connectionLabel } from './lobbyCopy'
import { useLobbyStore } from './lobbyStore'

/** Absolute box in base px (docs/ui-design/02-lobby.md layout table, current capabilities). */
const box = (left: number, top: number, width: number, height: number): CSSProperties => ({
  position: 'absolute',
  left,
  top,
  width,
  height,
})

const TITLE = 'm-0 flex items-center text-base leading-6 font-semibold text-zinc-100'

function previewText(status: LobbyView['appearance']['status']): string {
  switch (status) {
    case 'placeholder':
      return 'Preview coming soon'
    case 'loading':
      return 'Loading preview'
    case 'failed':
      return 'Preview unavailable'
    case 'ready':
      return ''
  }
}

function Silhouette() {
  return (
    <svg aria-hidden="true" width="200" height="240" viewBox="0 0 200 240" className="text-zinc-700">
      <circle cx="100" cy="72" r="48" fill="currentColor" />
      <path d="M12 240 C12 170 52 136 100 136 C148 136 188 170 188 240 Z" fill="currentColor" />
    </svg>
  )
}

function NewsBody({ news }: { news: LobbyView['news'] }) {
  if (news.status === 'loading') {
    return <p className="m-0 text-sm leading-5 text-zinc-300">Loading patch notes</p>
  }
  if (news.status === 'failed') {
    return <p className="m-0 text-sm leading-5 text-zinc-300">Patch notes could not load.</p>
  }
  if (news.entries.length === 0) {
    return <p className="m-0 text-sm leading-5 text-zinc-300">No patch notes yet.</p>
  }
  return (
    <ul
      className="m-0 flex h-full list-none flex-col gap-3 overflow-y-auto p-0 pr-1"
      tabIndex={0}
      aria-label="Patch notes list"
    >
      {news.entries.map((entry) => (
        <li key={`${entry.version}-${entry.publishedOn}`}>
          <div className="text-[11px] leading-4 text-zinc-300">{`${entry.version} · ${entry.publishedOn}`}</div>
          <div className="text-sm leading-5 font-semibold text-zinc-100">{entry.title}</div>
          <p className="m-0 text-xs leading-4 text-zinc-300">{entry.summary}</p>
        </li>
      ))}
    </ul>
  )
}

export function LobbyScreen() {
  const lobby = useLobbyStore((s) => s.lobby)
  const [confirmQuit, setConfirmQuit] = useState(false)
  const [quitting, setQuitting] = useState(false)

  if (!lobby) return null

  const { connection, news, appearance } = lobby
  const connecting = connection.status === 'connecting' || connection.status === 'resolving'

  const play = () => {
    void request('lobby.join', { mode: 'configured' }).catch(() => undefined)
  }
  const retryNews = () => {
    void request('lobby.news_retry').catch(() => undefined)
  }
  const quit = () => {
    setQuitting(true)
    void request('app.quit').catch(() => setQuitting(false))
  }

  return (
    <div className="pointer-events-auto absolute inset-0 bg-zinc-950 text-zinc-100">
      <header style={box(48, 32, 1184, 56)}>
        <h1 style={box(16, 8, 352, 40)} className="m-0 flex items-center text-2xl leading-8 font-bold">
          FinalRun
        </h1>
        <div style={box(576, 8, 280, 40)} className="flex items-center truncate text-sm leading-5 text-zinc-100">
          {lobby.playerName ?? 'Player'}
        </div>
        <div
          style={box(872, 8, 296, 40)}
          className="flex items-center justify-end gap-2 text-sm leading-5 text-zinc-300"
          aria-live="polite"
        >
          <span>{connectionLabel(connection.status)}</span>
          {typeof connection.pingMs === 'number' && <span className="tabular">{`${connection.pingMs} ms`}</span>}
        </div>
      </header>

      <Panel title="Play" inset={0} style={box(48, 112, 352, 264)}>
        <h2 style={box(16, 16, 320, 28)} className={TITLE}>
          Play
        </h2>
        <div style={box(16, 52, 320, 40)} className="grid [&>button]:w-full">
          <Button label="Play" variant="primary" disabled={!lobby.canPlay} loading={!lobby.canPlay} onPress={play} />
        </div>
        <div style={box(16, 104, 320, 140)} className="flex flex-col gap-2 text-sm leading-5 text-zinc-300">
          {connection.error !== null && <p className="m-0" role="alert">{connectionErrorText(connection.error)}</p>}
          {connecting && (
            <>
              <p className="m-0">Connecting to server</p>
              <ProgressBar label="Connecting to server" max={1} />
            </>
          )}
        </div>
      </Panel>

      <Panel title="Patch notes" inset={0} style={box(48, 392, 352, 248)}>
        <h2 style={box(16, 16, 320, 28)} className={TITLE}>
          Patch notes
        </h2>
        <div style={box(16, 56, 320, 144)}>
          <NewsBody news={news} />
        </div>
        {news.status === 'failed' && (
          <div style={box(16, 208, 320, 28)} className="flex items-center">
            <Button label="Retry" variant="quiet" size="compact" onPress={retryNews} />
          </div>
        )}
      </Panel>

      <Panel title="Character" inset={0} style={box(416, 112, 816, 528)}>
        <h2 style={box(16, 16, 784, 28)} className={TITLE}>
          Character
        </h2>
        <div style={box(16, 56, 784, 368)} className="flex flex-col items-center justify-center gap-4 rounded bg-zinc-950/60">
          <Silhouette />
          <p className="m-0 text-sm leading-5 text-zinc-300">{previewText(appearance.status)}</p>
        </div>
        <div style={box(16, 440, 784, 72)} className="flex items-center text-sm leading-5 text-zinc-300">
          {`Body: ${appearance.bodyType ?? 'Default'}`}
        </div>
      </Panel>

      <footer style={box(48, 652, 1184, 44)}>
        <div style={box(776, 2, 112, 40)} className="flex items-center justify-end text-[11px] leading-4 text-zinc-300">
          Coming later
        </div>
        <div style={box(896, 2, 128, 40)} title="Coming later" className="grid [&>button]:w-full">
          <Button label="Settings" variant="secondary" disabled />
        </div>
        <div style={box(1040, 2, 128, 40)} className="grid [&>button]:w-full">
          <Button label="Quit" variant="secondary" onPress={() => setConfirmQuit(true)} />
        </div>
      </footer>

      {confirmQuit && (
        <Modal
          title="Quit FinalRun?"
          primary={{ label: 'Quit', onPress: quit, busy: quitting }}
          secondary={{ label: 'Cancel', onPress: () => setConfirmQuit(false) }}
          dismissible
          onDismiss={() => setConfirmQuit(false)}
        />
      )}
    </div>
  )
}
