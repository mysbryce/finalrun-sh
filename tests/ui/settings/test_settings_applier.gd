extends TestCase
## SettingsApplier: startup display-key gate, AA mapping, per-viewport and
## per-camera effects on nodes built here (no real window needed).


func test_display_keys_blocked_by_cmdline_flag() -> void:
	var saved: Array = ["display_mode", "resolution"]
	for flag: String in GameConst.DISPLAY_CMDLINE_FLAGS:
		var cmdline: PackedStringArray = ["res://main/Main.tscn", flag, "960x540"]
		assert_eq(SettingsApplier.display_keys_allowed_at_startup(cmdline, saved), [], "flag %s blocks both display keys" % flag)


func test_display_keys_missing_from_saved_file_skipped() -> void:
	var cmdline: PackedStringArray = []
	assert_eq(SettingsApplier.display_keys_allowed_at_startup(cmdline, []), [], "no saved file: nothing applied")
	assert_eq(
		SettingsApplier.display_keys_allowed_at_startup(cmdline, ["resolution", "fov"]),
		["resolution"],
		"only saved display keys are applied"
	)


func test_display_keys_saved_and_no_flag_applied() -> void:
	var cmdline: PackedStringArray = ["--verbose"]
	assert_eq(
		SettingsApplier.display_keys_allowed_at_startup(cmdline, ["display_mode", "resolution"]),
		["display_mode", "resolution"],
		"saved display keys apply without a window flag"
	)


func test_aa_mapping() -> void:
	assert_eq(SettingsApplier.msaa_for("off"), Viewport.MSAA_DISABLED, "off: no MSAA")
	assert_eq(SettingsApplier.screen_aa_for("off"), Viewport.SCREEN_SPACE_AA_DISABLED, "off: no FXAA")
	assert_eq(SettingsApplier.msaa_for("fxaa"), Viewport.MSAA_DISABLED, "fxaa: no MSAA")
	assert_eq(SettingsApplier.screen_aa_for("fxaa"), Viewport.SCREEN_SPACE_AA_FXAA, "fxaa: FXAA")
	assert_eq(SettingsApplier.msaa_for("msaa_2x"), Viewport.MSAA_2X, "msaa_2x: MSAA 2X")
	assert_eq(SettingsApplier.screen_aa_for("msaa_2x"), Viewport.SCREEN_SPACE_AA_DISABLED, "msaa_2x: no FXAA")
	assert_eq(SettingsApplier.msaa_for("msaa_4x"), Viewport.MSAA_4X, "msaa_4x: MSAA 4X")
	assert_eq(SettingsApplier.screen_aa_for("msaa_4x"), Viewport.SCREEN_SPACE_AA_DISABLED, "msaa_4x: no FXAA")


func test_apply_viewport() -> void:
	var viewport := SubViewport.new()
	var light := DirectionalLight3D.new()
	light.shadow_enabled = true
	viewport.add_child(light)
	SettingsApplier.apply_viewport(viewport, {"render_scale": 50, "shadows": "off", "anti_aliasing": "msaa_4x"})
	var scale := viewport.scaling_3d_scale
	var shadow := light.shadow_enabled
	var msaa := viewport.msaa_3d
	var screen_aa := viewport.screen_space_aa
	viewport.free()
	assert_eq(scale, 0.5, "render_scale 50 -> scaling_3d_scale 0.5")
	assert_false(shadow, "shadows off disables the directional light shadow")
	assert_eq(msaa, Viewport.MSAA_4X, "msaa_4x sets MSAA_4X")
	assert_eq(screen_aa, Viewport.SCREEN_SPACE_AA_DISABLED, "msaa_4x turns FXAA off")


func test_apply_camera() -> void:
	var camera := PlayerCamera.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(camera)
	SettingsApplier.apply_camera(camera, {"fov": 90, "view_distance": "high", "invert_y": true, "mouse_sensitivity": 0.005})
	var camera_3d := camera.get_camera()
	var fov := camera_3d.fov if camera_3d != null else 0.0
	var far := camera_3d.far if camera_3d != null else 0.0
	var invert := camera.invert_y
	var sensitivity := camera.sensitivity
	camera.free()
	assert_eq(fov, 90.0, "fov 90")
	assert_eq(far, 600.0, "view distance high -> far 600")
	assert_true(invert, "invert_y set on the camera")
	assert_eq(sensitivity, 0.005, "mouse sensitivity set on the camera")


func test_ensure_audio_buses_idempotent() -> void:
	SettingsApplier.ensure_audio_buses()
	SettingsApplier.ensure_audio_buses()
	for bus_name: String in ["Music", "SFX", "UI"]:
		var count := 0
		for i in range(AudioServer.bus_count):
			if AudioServer.get_bus_name(i) == bus_name:
				count += 1
		assert_eq(count, 1, "exactly one %s bus" % bus_name)


func test_apply_engine_bus_volumes() -> void:
	SettingsApplier.apply_engine({"music_volume": 50})
	var music := AudioServer.get_bus_index("Music")
	assert_true(is_equal_approx(AudioServer.get_bus_volume_db(music), linear_to_db(0.5)), "music 50 -> linear_to_db(0.5)")
	assert_false(AudioServer.is_bus_mute(music), "music 50 is unmuted")
	SettingsApplier.apply_engine({"sfx_volume": 0})
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "sfx 0 mutes SFX")


func test_pitch_delta_invert_flips_sign() -> void:
	var normal := PlayerCamera.pitch_delta(10.0, 0.01, false)
	var inverted := PlayerCamera.pitch_delta(10.0, 0.01, true)
	assert_eq(normal, -0.1, "moving the mouse down lowers the pitch")
	assert_eq(inverted, 0.1, "invert_y flips the pitch sign")
