class_name SettingsApplier
extends RefCounted
## Applies stored settings (SettingsService values) to the engine, the window,
## each instance SubViewport and the local PlayerCamera
## (docs/ui-design/03-settings.md section 4). Pure static functions over values
## and nodes; only keys present in `values` are applied. Client only.
##
## Stored but not applied (each with its reason):
## - textures: the restart path is not built.
## - show_player_names: no world nameplates yet.
## - language: English only.
## - voice_* (voice_chat, voice_mode, voice_input_threshold, voice_input_device,
##   voice_output_device, voice_receive_volume), voice_volume, muted_players:
##   the voice_chat capability is hidden.
## - chat_filter, show_damage_numbers: coming later (capabilities chat and
##   damage_numbers are off; the schema marks them coming_later, shown disabled).
## - telemetry, crash_reports: the backend capabilities are hidden.
## - ads_sensitivity, aim_mode, crouch_mode, sprint_mode: the features are not
##   built (capabilities aim, crouch, sprint are off; the schema marks them
##   coming_later, shown disabled).

const DISPLAY_KEYS: Array = ["display_mode", "resolution"]
const MODE_WINDOWED := "windowed"
const MODE_BORDERLESS := "borderless"
const MODE_FULLSCREEN := "fullscreen"
const RESOLUTION_NATIVE := "native"
const RESOLUTION_SEPARATOR := "x"
const FRAME_CAP_UNLIMITED := "unlimited"
const SHADOWS_OFF := "off"
const AA_FXAA := "fxaa"
const AA_MSAA_2X := "msaa_2x"
const AA_MSAA_4X := "msaa_4x"
const PERCENT := 100.0
const MASTER_BUS := 0


## Display keys in `keys` only. Resolution applies in windowed mode only.
## ponytail: the 15 s keep/revert display preview comes with a later card.
static func apply_window(values: Dictionary, keys: Array) -> void:
	var mode := String(values.get("display_mode", MODE_WINDOWED))
	if keys.has("display_mode") and values.has("display_mode"):
		DisplayServer.window_set_mode(window_mode_for(mode))
	var resize := keys.has("resolution") or (keys.has("display_mode") and mode == MODE_WINDOWED)
	if not resize or not values.has("resolution") or mode != MODE_WINDOWED:
		return
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		return
	var screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen)
	var size := resolution_size(String(values["resolution"]), screen_size)
	if size == Vector2i.ZERO:
		return
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(DisplayServer.screen_get_position(screen) + (screen_size - size) / 2)


## vsync, frame cap, master/music/sfx/ui volume.
static func apply_engine(values: Dictionary) -> void:
	if values.has("vsync"):
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if bool(values["vsync"]) else DisplayServer.VSYNC_DISABLED
		)
	if values.has("frame_cap"):
		Engine.max_fps = max_fps_for(String(values["frame_cap"]))
	if values.has("master_volume"):
		apply_bus_volume(MASTER_BUS, int(values["master_volume"]))
	ensure_audio_buses()
	for key: String in GameConst.AUDIO_BUSES:
		if values.has(key):
			apply_bus_volume(AudioServer.get_bus_index(String(GameConst.AUDIO_BUSES[key])), int(values[key]))


## Adds each missing GameConst.AUDIO_BUSES bus (sending to master). Idempotent.
## No sounds play yet; future players pick a bus by these names.
static func ensure_audio_buses() -> void:
	for key: String in GameConst.AUDIO_BUSES:
		var bus_name := String(GameConst.AUDIO_BUSES[key])
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, AudioServer.get_bus_name(MASTER_BUS))


## Volume 0..100 on one bus: muted at 0. Ignores a missing bus (index < 0).
static func apply_bus_volume(bus_index: int, volume: int) -> void:
	if bus_index < 0:
		return
	AudioServer.set_bus_mute(bus_index, volume <= 0)
	if volume > 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume / PERCENT))


## Render scale, anti-aliasing, shadows and gamma for one instance viewport.
static func apply_viewport(viewport: SubViewport, values: Dictionary) -> void:
	if viewport == null:
		return
	if values.has("render_scale"):
		viewport.scaling_3d_scale = float(values["render_scale"]) / PERCENT
	if values.has("anti_aliasing"):
		var aa := String(values["anti_aliasing"])
		viewport.screen_space_aa = screen_aa_for(aa) as Viewport.ScreenSpaceAA
		viewport.msaa_3d = msaa_for(aa) as Viewport.MSAA
	if values.has("shadows"):
		var shadows := String(values["shadows"])
		var enabled := shadows != SHADOWS_OFF
		for light: Node in viewport.find_children("*", "DirectionalLight3D", true, false):
			(light as DirectionalLight3D).shadow_enabled = enabled
		if enabled and GameConst.SHADOW_ATLAS_SIZES.has(shadows):
			RenderingServer.directional_shadow_atlas_set_size(int(GameConst.SHADOW_ATLAS_SIZES[shadows]), true)
	if values.has("gamma"):
		# ponytail: brightness adjustment stands in for a real gamma curve.
		for node: Node in viewport.find_children("*", "WorldEnvironment", true, false):
			var environment := (node as WorldEnvironment).environment
			if environment != null:
				environment.adjustment_enabled = true
				environment.adjustment_brightness = float(values["gamma"])


## FOV, view distance, mouse sensitivity and invert Y for the local camera.
static func apply_camera(camera: PlayerCamera, values: Dictionary) -> void:
	if camera == null:
		return
	if values.has("mouse_sensitivity"):
		camera.sensitivity = float(values["mouse_sensitivity"])
	if values.has("invert_y"):
		camera.invert_y = bool(values["invert_y"])
	var camera_3d := camera.get_camera()
	if camera_3d == null:
		return
	if values.has("fov"):
		camera_3d.fov = float(values["fov"])
	if values.has("view_distance") and GameConst.VIEW_DISTANCE_FAR.has(String(values["view_distance"])):
		camera_3d.far = float(GameConst.VIEW_DISTANCE_FAR[String(values["view_distance"])])


## Display keys that may be applied at startup: none when the command line sets
## the window, otherwise only those present in the saved file.
static func display_keys_allowed_at_startup(cmdline: PackedStringArray, saved_keys: Array) -> Array:
	for flag: String in GameConst.DISPLAY_CMDLINE_FLAGS:
		if cmdline.has(flag):
			return []
	var result: Array = []
	for key: String in DISPLAY_KEYS:
		if saved_keys.has(key):
			result.append(key)
	return result


static func window_mode_for(mode: String) -> DisplayServer.WindowMode:
	match mode:
		MODE_BORDERLESS:
			return DisplayServer.WINDOW_MODE_FULLSCREEN
		MODE_FULLSCREEN:
			return DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		_:
			return DisplayServer.WINDOW_MODE_WINDOWED


## `native` -> screen size, `WxH` -> that size, anything else -> ZERO.
static func resolution_size(resolution: String, screen_size: Vector2i) -> Vector2i:
	if resolution == RESOLUTION_NATIVE:
		return screen_size
	var parts := resolution.split(RESOLUTION_SEPARATOR)
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


static func max_fps_for(frame_cap: String) -> int:
	if frame_cap == FRAME_CAP_UNLIMITED or not frame_cap.is_valid_int():
		return 0
	return int(frame_cap)


static func msaa_for(aa: String) -> int:
	match aa:
		AA_MSAA_2X:
			return Viewport.MSAA_2X
		AA_MSAA_4X:
			return Viewport.MSAA_4X
		_:
			return Viewport.MSAA_DISABLED


static func screen_aa_for(aa: String) -> int:
	return Viewport.SCREEN_SPACE_AA_FXAA if aa == AA_FXAA else Viewport.SCREEN_SPACE_AA_DISABLED
