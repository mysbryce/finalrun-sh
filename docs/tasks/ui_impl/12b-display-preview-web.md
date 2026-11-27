# ui_impl 12b: display preview dialog on the settings page (keep / revert within 15 s)

Design source: `docs/ui-design/03-settings.md` section 4 "Display preview" state ("Show 15 s confirmation. Revert on timer, Escape, focus loss or host error. Keep commits full patch. Failed save reverts display and leaves draft editable"), the `display_mode`/`resolution` rows ("Preview, then Keep"; resolution: "Disable in borderless"), section 8 ("Announce preview once and at five seconds remaining"); `docs/ui-design/DATA_CONTRACTS.md` `SettingsView.preview: { token: string; secondsLeft: number } | null`, `saveError: ... | 'preview_reverted' | null`, rows `settings.apply` (`{previewToken}`) and `settings.display_confirm` (`{token: string, keep: boolean}` -> `{}`, errors `bad_params`, `preview_expired`, `save_failed`). Web only; card 12 builds the Godot transaction later against the same contract. Read first: `ui/web/src/features/settings/SettingsScreen.tsx` (`statusText`, `ERROR_TEXT`, footer, row `locked`), `settingsStore.ts` (`setView` rebase, `apply`), `SettingsScreen.test.tsx`, `demoSettings.ts`, `ui/web/src/lib/ui/Modal.tsx`, `ui/web/src/lib/ipc/bridge.ts`.

## Decisions for this card (supervisor)
- The host snapshot drives the dialog: it is shown while `view.preview !== null`, and closes when a snapshot arrives with `preview === null` (host kept, reverted, or timed out). Godot always publishes the `settings` snapshot before sending the matching reply, so no race. The `previewToken` in the `settings.apply` reply is not used by the page (the token comes from `view.preview.token`).
- Keep: `request('settings.display_confirm', { token: view.preview.token, keep: true })`. Revert (and Escape / dismiss): same with `keep: false`. Both buttons show busy/disabled while the request runs. Error replies: `preview_expired` -> nothing to show (the host already reverted; the next snapshot closes the dialog); `save_failed` -> the footer shows the existing `Could not save settings.` text via the store `error`; others -> `Could not apply settings.`.
- After Keep the revision changes and the existing `setView` rebase drops the applied keys from the draft. After a revert the revision is unchanged and the draft stays editable (no store change needed; verify with a test).
- Countdown: starts from `view.preview.secondsLeft` when the dialog mounts (or when the token changes), ticks down once per second locally, stops at 0 (the host reverts on its own timer). The visible number is `aria-hidden`; a separate sr-only `aria-live="polite"` region says `Display preview. Keep these settings within <n> seconds.` once on open and `5 seconds left.` when the countdown reaches 5.
- Dialog (shared `Modal`, `dismissible`, `onDismiss` = Revert): title `Keep display settings?`; body `Reverting in <n> s.`; secondary `Revert` (safe focus, goes first), primary `Keep`.
- Footer status order: `Applying` (pending) -> store error text -> `saveError === 'preview_reverted'`: `Display change reverted.` plus ` · <n> changes` when the draft is not empty -> `<n> changes` -> `Saved`; the restart suffix stays as today. While the preview is active, `Back`, tabs, `Reset`, `Discard`, `Apply` and capture `Change` buttons are disabled (rows `locked`).
- Resolution row: `locked` unless the effective (draft-merged) `display_mode` is `windowed` (resolution only applies in windowed mode on the host). `# ponytail:` comment: filtering resolutions larger than the screen needs host data that `SettingsView` does not carry yet.

## Rules
- `ui/web/src/`: `app/ -> features/ -> lib/`; features never import each other; `lib/` never imports `features/`; `import type`; no new packages. Reuse `Modal`.
- Host notes: run npm from PowerShell in `d:\FinalRun\ui\web` (Git Bash's `D:/` path breaks vitest); npm needs `--cache C:\Users\ADMINI~1\AppData\Local\Temp\claude\1e04975e126e5a06\90489328-ac55-443d-990d-80e89d0b28bb\npm-cache`; do not start a Vite dev server; `ui/dist/assets` is not readable for you. Do not edit Godot files (another worker edits them in parallel).

## Files
- create: `ui/web/src/features/settings/DisplayPreviewDialog.tsx`, `ui/web/src/features/settings/DisplayPreviewDialog.test.tsx`
- modify: `ui/web/src/features/settings/SettingsScreen.tsx`, `ui/web/src/features/settings/SettingsScreen.test.tsx`, `ui/web/src/features/settings/settingsStore.ts` (only if the error from `display_confirm` is stored there; a `setError(code)` action is fine)

## Steps
1. `DisplayPreviewDialog.tsx`, props `preview: { token: string; secondsLeft: number }`, `onError(code: string)`: the dialog, countdown, live region and the two requests as decided (`key={preview.token}` on the component from the parent resets the countdown per preview).
2. `SettingsScreen.tsx`: `const previewing = view?.preview != null`; render `<DisplayPreviewDialog key={view.preview.token} ... />` while previewing; disable/lock as decided; `statusText` gets the `preview_reverted` text; resolution row lock.
3. Tests `DisplayPreviewDialog.test.tsx` (fake timers; mock `request`): shows `Reverting in 15 s.` for `secondsLeft: 15` and `Reverting in 14 s.` after 1 s; Keep sends `settings.display_confirm` with `{ token: 't1', keep: true }`; Revert sends `keep: false`; Escape sends `keep: false`; the live region says the open text and `5 seconds left.` after 10 s; a `save_failed` rejection calls `onError('save_failed')`.
4. `SettingsScreen.test.tsx`: a view with `preview: { token: 't1', secondsLeft: 15 }` shows the dialog and disables Apply and the tabs; a next view with `preview: null` closes it; after a revert-style view (same revision, `preview: null`, `saveError: 'preview_reverted'`) the draft is still there and the footer says `Display change reverted. · 1 change` (draft with one key) or `Display change reverted.` (empty draft); the Resolution row is locked when `display_mode` is `borderless` and enabled after staging `windowed`.
5. Checks: `npm run test`, `npm run build` (in `ui/web/`, from PowerShell).

## Do not
- No Godot files. No changes to the capture dialog beyond disabling `Change` while previewing. Do not edit `docs/ui-design/`. Do not run git.

## Done when
- `npm run test` and `npm run build` pass.
- Final answer: files created/changed, web test summary line, build output list, anything you could not do and why.
