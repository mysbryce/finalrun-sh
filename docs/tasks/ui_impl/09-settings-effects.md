# ui_impl 09: settings take effect (graphics, camera, mouse, master volume, notification time)

Design source: `docs/ui-design/03-settings.md` section 4 tables "Graphics", "Controls" (Mouse group), "Others" (Audio, HUD rows). Card 08 added `ui/settings/SettingsService.gd` (`changed(values, changed_keys)` signal, `get_value`, `values()`), loaded in `Main._start_client`. Read `main/Main.gd`, `features/instance/Instance.gd` (each instance is a `SubViewport` with `own_world_3d`), `features/player/PlayerCamera.gd`, `ui/hud/Hud.gd` (`push_notification`, `HUD_NOTIFICATION_MS`), `lib/constants/GameConst.gd`.

## Decisions for this card (supervisor)
- One applier: `ui/settings/SettingsApplier.gd` (`class_name SettingsApplier extends RefCounted`), pure functions that take values and nodes, so they are testable without a window. Main calls it at startup (after `load()`), on every `changed`, and for each new instance viewport / local camera.
- Display keys (`display_mode`, `resolution`) are NOT applied at startup when the command line sets the window (`--resolution`, `--position`, `--windowed`, `-w`, `--fullscreen`, `-f` in `OS.get_cmdline_args()`; the smoke script uses these) or when the key is not present in the saved file (first run keeps the project's window). After an Apply they are applied directly; the 15 s keep/revert preview comes in a later card (`# ponytail:`).
- Mapping: `display_mode` windowed -> `WINDOW_MODE_WINDOWED`, borderless -> `WINDOW_MODE_FULLSCREEN`, fullscreen -> `WINDOW_MODE_EXCLUSIVE_FULLSCREEN`. `resolution` only in windowed (`native` -> screen size of the current screen; `WxH` -> `window_set_size`, then center the window). `vsync` -> `DisplayServer.window_set_vsync_mode`. `frame_cap` -> `Engine.max_fps` (`unlimited` -> 0).
- Per instance viewport: `render_scale` -> `scaling_3d_scale = v / 100.0`; `anti_aliasing` off/fxaa/msaa_2x/msaa_4x -> `screen_space_aa` (FXAA only for fxaa) and `msaa_3d` (2X/4X); `shadows` off -> every `DirectionalLight3D` in that instance `shadow_enabled = false`, low/medium/high -> enabled and `RenderingServer.directional_shadow_atlas_set_size(GameConst.SHADOW_ATLAS_SIZES[v], true)` with `SHADOW_ATLAS_SIZES = {"low": 1024, "medium": 2048, "high": 4096}`.
- Camera: `fov` -> `Camera3D.fov`; `view_distance` -> `Camera3D.far` from `GameConst.VIEW_DISTANCE_FAR = {"low": 150.0, "medium": 300.0, "high": 600.0}`; `mouse_sensitivity` and `invert_y` replace `GameConst.CAMERA_MOUSE_SENSITIVITY` in `PlayerCamera` (add `var sensitivity: float` and `var invert_y: bool` on the camera, defaults from GameConst, set by the applier).
- `gamma`: if the instance has a `WorldEnvironment` with an `Environment`, set `adjustment_enabled = true` and `adjustment_brightness = gamma`; otherwise nothing (`# ponytail:` real gamma curve later).
- Audio: `master_volume` -> `AudioServer.set_bus_volume_db(0, linear_to_db(v / 100.0))` (mute at 0). Music/SFX/UI buses do not exist yet: `# ponytail:` comment, no buses created.
- `notifications_duration` (seconds) -> Hud notification lifetime: add `var notification_ms: int = GameConst.HUD_NOTIFICATION_MS` on Hud and use it where the lifetime is computed (keep the static helpers testable: pass the lifetime in as an argument with the old constant as default).
- Not in this card (leave stored only, comment in the applier listing them): `textures` (needs restart path), `ui_scale`, `colorblind_mode`, `show_player_names`, `streamer_mode`, `minimap_rotate`, `show_compass`, `language`, sound buses, voice.

## Rules
- `ui/settings/` is client-only; never runs on the dedicated server (Main only creates it in `_start_client`). No magic numbers: new values in `GameConst.gd`. Tests extend `TestCase`, mirror the source tree; do not require a real window (call the per-node functions on nodes you build in the test).

## Files
- create: `ui/settings/SettingsApplier.gd`, `tests/ui/settings/test_settings_applier.gd`
- modify: `lib/constants/GameConst.gd`, `main/Main.gd`, `features/player/PlayerCamera.gd`, `ui/hud/Hud.gd`, `tests/ui/hud/test_hud.gd` (only if a helper signature changed)

## Steps
1. `GameConst.gd`: `SHADOW_ATLAS_SIZES`, `VIEW_DISTANCE_FAR`, `DISPLAY_CMDLINE_FLAGS: PackedStringArray = ["--resolution", "--position", "--windowed", "-w", "--fullscreen", "-f"]`.
2. `SettingsApplier.gd` static functions: `apply_window(values: Dictionary, keys: Array) -> void` (only the display keys in `keys`), `apply_engine(values) -> void` (vsync, frame cap, master volume), `apply_viewport(viewport: SubViewport, values) -> void` (render scale, AA, shadows, gamma for that instance), `apply_camera(camera: PlayerCamera, values) -> void` (fov, far, sensitivity, invert), `display_keys_allowed_at_startup(cmdline: PackedStringArray, saved_keys: Array) -> Array` (returns the display keys that may be applied at startup), `msaa_for(aa: String) -> int`, `screen_aa_for(aa: String) -> int`.
3. `SettingsService.gd`: `func saved_keys() -> Array` (keys present in the loaded file), if not already available.
4. `PlayerCamera.gd`: `sensitivity` and `invert_y` used in the mouse-look code (invert flips the pitch delta). Expose the `Camera3D` (`get_camera() -> Camera3D`) if it is not reachable.
5. `Main.gd`: after `_settings.load()`: `apply_engine`, `apply_window` with `display_keys_allowed_at_startup(...)`; on `_settings.changed`: `apply_engine`, `apply_window(values, changed_keys)`, every current instance viewport (`_client_view` children that are `SubViewport`s) and the local camera, and `_hud.notification_ms`; in `client_show_instance` apply the viewport values to the new instance; when the local player's camera appears (find where Main gets the local player; apply once per new camera instance, track it to avoid applying every frame).
6. `Hud.gd`: `notification_ms` as decided.
7. Tests `test_settings_applier.gd`: `display_keys_allowed_at_startup` (cmdline flag blocks both keys; key missing from saved keys is skipped; saved and no flag -> applied); `msaa_for`/`screen_aa_for` for all four options; `apply_viewport` on a `SubViewport` with a child `DirectionalLight3D`: render_scale 50 -> 0.5, `shadows: "off"` disables the light, `anti_aliasing: "msaa_4x"` sets `MSAA_4X`; `apply_camera` on a `PlayerCamera` built in the test (if its `_ready` needs a tree, add it to the test tree): fov 90, view distance high -> far 600, invert_y true flips the pitch sign (test via the sensitivity/invert fields or a small pure helper `pitch_delta(relative_y, sensitivity, invert)`).
8. Checks: `godot_console --headless --path . --import`; `godot_console --headless --path . -s res://tests/run_tests.gd`; smoke `pwsh tools/smoke_local.ps1 -Clients 2` (call it plainly, never redirect or pipe its output), wait 20 s, both clients connected + spawned, the client windows keep the smoke script's 960x540 size (the log should show no window resize; report how you checked), no `SCRIPT ERROR`, then `pwsh tools/smoke_local.ps1 -Stop`.

## Do not
- No web changes, no server changes, no display preview, no new audio buses. Do not edit `docs/ui-design/`. Do not run git.

## Done when
- Import clean (`.NET Sdk not found` + its C# stack lines, certificate, `user://`, `[Godot CEF]` are noise); `ALL TESTS PASSED`; smoke clean.
- Final answer: files created/changed, last 3 Godot test lines, smoke result, settings that still have no effect (list), anything you could not do and why.
