# ui_impl 08: SettingsService (schema, ConfigFile, validation, apply) and settings routes in Godot

Design source: `docs/ui-design/03-settings.md` (sections 1, 4 "States" and "Availability and storage", 6, 7), `docs/ui-design/settings-schema.json` (87 entries; fields `key, tab, group, type, default, min, max, step, options, restart, label, storage, capability, unavailable`), `docs/ui-design/DATA_CONTRACTS.md` (`SettingsView`, `SettingAvailability`, `settings.open`, `settings.tab`, `settings.close`, `settings.apply`). This card is Godot only; card 08b builds the page in parallel against the same contract. Effects of the values (window mode, FOV, audio...) come in later cards: here values are only stored, validated and published.

## Decisions for this card (supervisor)
- Runtime schema: copy `docs/ui-design/settings-schema.json` byte-for-byte to `ui/web/public/settings-schema.json` (Vite copies it to `ui/dist/settings-schema.json`; card 08b adds a web test that the two stay identical). Godot reads `GameConst.SETTINGS_SCHEMA_PATH = "res://ui/dist/settings-schema.json"`. If `ui/dist/settings-schema.json` is not there yet, copy the same file there too (card 08b's web build, running in parallel, regenerates `ui/dist/`; do not run `npm run build` yourself).
- `GameConst.SETTINGS_PATH = "user://settings.cfg"`, section = tab, key = setting key, for `storage: "config_file"` only. `session` keys live in memory and reset with `clear_session()`; `none` (type `action`) keys are never values.
- Capabilities: all named capabilities are false today except `debug_shortcuts`, which is `OS.is_debug_build()`. (`# ponytail:` features flip their capability when they ship.)
- `settings.apply` needs a reply computed by Main, so the Hud gets a deferred-reply path (below). `display_confirm`, `capture`, `capture_cancel` are not in this card (reply `not_available` for now).
- Esc while a settings route is open is ignored in Godot (the page's Back button closes; keys do not reach the page). `# ponytail:` comment in the Esc handler.
- Display preview: not in this card. `apply` returns `previewToken: null` always and `preview` stays null.

## Rules
- `ui/` never references `ServerManager`; `Hud` emits signals and `Main` wires them. `ui/settings/` is client-only and may be used by `Main`. No magic numbers. Tests extend `TestCase`, mirror the source tree, and must not write to the real `user://settings.cfg` (inject the path).
- Host notes: npm needs `--cache C:\Users\ADMINI~1\AppData\Local\Temp\claude\1e04975e126e5a06\90489328-ac55-443d-990d-80e89d0b28bb\npm-cache`. Do not touch `ui/web/src/` (card 08b owns it) except nothing; you only add `ui/web/public/settings-schema.json`.

## Files
- create: `ui/settings/SettingsService.gd`, `tests/ui/settings/test_settings_service.gd`, `ui/web/public/settings-schema.json`
- modify: `lib/constants/GameConst.gd`, `ui/hud/Hud.gd`, `tests/ui/hud/test_hud.gd`, `main/Main.gd`

## Steps
1. `GameConst.gd` `# Settings`: `SETTINGS_PATH`, `SETTINGS_SCHEMA_PATH`, `SETTINGS_TABS: PackedStringArray = ["graphics", "controls", "social", "others"]`.
2. `ui/settings/SettingsService.gd`, `class_name SettingsService extends RefCounted`:
   - `signal changed(values: Dictionary, changed_keys: Array)`.
   - `func _init(config_path: String = GameConst.SETTINGS_PATH, schema_path: String = GameConst.SETTINGS_SCHEMA_PATH)`; `func load() -> void`: parse the schema (array; on failure `push_error` and keep an empty schema), then read the ConfigFile (missing file = all defaults; `save_error = "load_failed"` only when the file exists but cannot be parsed). Each `config_file` key: stored value if `is_valid(entry, value)`, else the default. Session keys = defaults. Remember the values at load as `_launch_values` (for `pendingRestart`).
   - `func entry(key: String) -> Dictionary`, `func values() -> Dictionary` (every non-action key -> current value), `func get_value(key: String) -> Variant`.
   - `func is_valid(entry: Dictionary, value: Variant) -> bool` by `type`: `boolean` -> bool; `enum` -> String in `options`; `integer` -> int, or float with no fraction (JSON numbers arrive as float), within `min`/`max`, `(value - min) % step == 0` when step is set; `number` -> int/float within range, on the step grid within 1e-6; `binding` -> null or a String matching `^((Ctrl|Alt|Shift)\+)*[A-Za-z0-9]+$` (modifiers in that order, no duplicates); `device` -> non-empty String; `integer_array` -> Array of positive integers (no duplicates); `action` -> never valid as a value.
   - `func capabilities() -> Dictionary` key -> `{visible, enabled, reason}` for every entry: capability null -> visible, enabled, reason null; capability set and true -> same; false with `unavailable == "hidden"` -> `{visible: false, enabled: false, reason: <best fit: "requires_backend" for *_backend, "requires_voice" for voice_chat, else "unsupported">}`; false with `"coming_later"` -> `{visible: true, enabled: false, reason: "coming_later"}`. `debug_only` reason when the capability is `debug_shortcuts` and false. `func set_capability(name: String, on: bool) -> void`.
   - `func apply_patch(revision: int, patch: Dictionary) -> Dictionary` returning `{"ok": bool, "error": String, "data": Dictionary}`:
     - `revision != _revision` -> `stale_revision`; any unknown key or `action` key -> `bad_params`; any invalid value -> `bad_params`; a key whose capability makes it not enabled -> `unsupported`.
     - Binding conflict: after merging the patch into the current values, two `binding` keys with the same non-null value inside the same "context" -> `binding_conflict` (context = all bindings except `debug_shortcuts`-capability ones, which form their own context; report the two keys in `data.conflict`).
     - Success: write all `config_file` values to a fresh `ConfigFile` and save atomically (`save` to `<path>.tmp`, then `DirAccess.rename_absolute(tmp, path)` after converting both with `ProjectSettings.globalize_path`); on save failure -> error `save_failed`, nothing changes in memory. Then update memory (incl. session keys), `_revision += 1`, emit `changed` with the changed keys, return `data = {"previewToken": null}`.
   - `func clear_session() -> void` (session keys back to defaults, emit `changed` when any changed).
   - `func pending_restart() -> Array` (keys with `restart == true` whose value differs from `_launch_values`).
   - `func view() -> Dictionary`: exactly the `SettingsView` keys: `values`, `revision`, `capabilities`, `devices` (`{"input": [{"id": "system_default", "label": "System default", "available": true}], "output": [same]}`), `displayModes` (`["windowed", "borderless", "fullscreen"]`), `pendingRestart`, `preview: null`, `saveError` (null or `load_failed`/`save_failed`).
3. `Hud.gd`:
   - Deferred replies: `route_request` may return `"reply": null`; `_on_ipc_message` only sends a non-null reply. `func send_reply(id: int, ok: bool, data: Variant, error: String) -> void` sends the `reply` envelope.
   - Signals `settings_open_requested`, `settings_close_requested`, `settings_apply_requested(request_id: int, revision: int, patch: Dictionary)`.
   - `route_request`: `settings.open` -> action `["settings_open"]` (ok, replaces the current `not_available`); `settings.tab` with `tab` in `SETTINGS_TABS` -> `["settings_tab", tab]` else `bad_params`; `settings.close` -> `["settings_close"]`; `settings.apply` with int-like `revision` and Dictionary `patch` -> `{"reply": null, "action": ["settings_apply", id, revision, patch]}` else `bad_params`; `settings.display_confirm`, `settings.capture`, `settings.capture_cancel` -> `not_available` (`# ponytail:` later cards).
   - `func open_settings(view: Dictionary) -> void`: only from `/lobby` or `/pause`; store `_settings_origin = _route`; `publish("settings", view)`; navigate `/settings/graphics`; `_set_panel_input(true)`. `settings_tab` action -> navigate `/settings/<tab>` (only while a settings route is open). `func close_settings() -> void`: navigate back to `_settings_origin` (keep the panel input as the origin needs it: both origins use panel input). `func is_settings_open() -> bool` (`_route.begins_with("/settings/")`). `func push_settings(view: Dictionary) -> void` = `publish("settings", view)`.
   - Make sure `is_panel_open()` stays true on settings routes, and `show_lobby` from a settings route works (e.g. disconnect while in settings: the lobby replaces it, origin cleared).
4. `Main.gd`:
   - Create `_settings = SettingsService.new()` and `load()` in `_start_client` (before the boot flow). Print `[Main] Settings loaded (<n> keys)`.
   - `settings_open_requested` -> `_hud.open_settings(_settings.view())`; `settings_close_requested` -> `_hud.close_settings()`; `settings_apply_requested(id, rev, patch)` -> `var r := _settings.apply_patch(rev, patch)`; `_hud.send_reply(id, r.ok, r.data, r.error)`; on ok `_hud.push_settings(_settings.view())`.
   - `_leave_session()` and `_show_lobby()` call `_settings.clear_session()` (and push the view if settings are open).
   - Esc handler: when `_hud.is_settings_open()`, ignore Esc (comment as decided).
5. Tests:
   - `tests/ui/settings/test_settings_service.gd` (use `user://test_settings_<random>.cfg`, delete it in teardown; the real schema path): defaults when no file; a stored valid value is loaded and an invalid one falls back to the default; `is_valid` cases for each type (integer step, float JSON integer, number grid, binding with `Ctrl+KeyB` ok / `Shift+Ctrl+KeyB` bad / null ok, integer_array duplicates bad); `apply_patch` stale revision, unknown key, action key, invalid value, binding conflict (set `bind_reload` to `KeyW`), success increments revision, writes the file (a new service loading the same path sees the value) and emits `changed`; a `coming_later` key (e.g. `bind_sprint` if its capability is `sprint`; read the schema) -> `unsupported`; session key (`party_invites`) is not written to the file and `clear_session` resets it; `view()` has exactly the `SettingsView` keys and 87 capability entries; `pending_restart` lists `textures` after changing it.
   - `test_hud.gd`: `route_request` for `settings.open`, `settings.tab` (good/bad tab), `settings.close`, `settings.apply` (reply null + action; bad params), `settings.capture` -> `not_available`.
6. Checks: `godot_console --headless --path . --import`; `godot_console --headless --path . -s res://tests/run_tests.gd`; smoke `pwsh tools/smoke_local.ps1 -Clients 1`, wait 15 s, confirm `[Main] Settings loaded (87 keys)` minus action keys (report the number), connect + spawn, no `SCRIPT ERROR`, then `pwsh tools/smoke_local.ps1 -Stop` (never pipe the script's output).

## Do not
- No effects on the engine (window, camera, audio, input map). No web source changes. No server changes. Do not edit `docs/ui-design/`. Do not run git.

## Done when
- Godot import clean (`.NET Sdk not found` + its C# stack lines, certificate, `user://`, `[Godot CEF]` are noise); `ALL TESTS PASSED`; smoke clean.
- Final answer: files created/changed, the loaded key count, last 3 Godot test lines, smoke result, anything you could not do and why.
