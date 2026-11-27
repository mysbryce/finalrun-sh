extends TestCase
## SettingsService: schema defaults, ConfigFile load/save, validation, apply_patch,
## session keys, capabilities and the SettingsView shape. Uses a temp user:// path.

const SCHEMA_ENTRIES := 87
const ACTION_ENTRIES := 3
const VIEW_KEYS := ["values", "revision", "capabilities", "devices", "displayModes", "pendingRestart", "preview", "saveError"]


func _temp_path() -> String:
	return "user://test_settings_%d_%d.cfg" % [Time.get_ticks_usec(), randi()]


func _remove(path: String) -> void:
	for file: String in [path, path + SettingsService.TMP_SUFFIX]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func _service(path: String) -> SettingsService:
	var service := SettingsService.new(path)
	service.load()
	return service


func test_defaults_when_no_file() -> void:
	var path := _temp_path()
	var service := _service(path)
	_remove(path)
	assert_eq(service.values().size(), SCHEMA_ENTRIES - ACTION_ENTRIES, "every non-action key has a value")
	assert_eq(service.get_value("fov"), 75, "fov default")
	assert_true(service.get_value("fov") is int, "integer default is int")
	assert_eq(service.get_value("bind_fire"), "MouseLeft", "binding default")
	assert_eq(service.get_value("party_invites"), "everyone", "session default")
	assert_false(service.values().has("reset_all"), "action keys are not values")
	assert_eq(service.save_error, null, "a missing file is not an error")


func test_load_stored_and_invalid_values() -> void:
	var path := _temp_path()
	var config := ConfigFile.new()
	config.set_value("graphics", "fov", 90)
	config.set_value("graphics", "render_scale", 53)
	config.set_value("controls", "bind_fire", "")
	config.set_value("social", "party_invites", "nobody")
	config.save(path)
	var service := _service(path)
	_remove(path)
	assert_eq(service.get_value("fov"), 90, "valid stored value is loaded")
	assert_eq(service.get_value("render_scale"), 100, "off-step stored value falls back to default")
	assert_eq(service.get_value("bind_fire"), null, "stored empty binding loads as unbound")
	assert_eq(service.get_value("party_invites"), "everyone", "legacy session value is ignored")


func test_unparsable_file_is_load_failed() -> void:
	var path := _temp_path()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("[graphics\nfov = = =\n")
	file.close()
	var service := _service(path)
	_remove(path)
	assert_eq(service.save_error, "load_failed", "broken file sets load_failed")
	assert_eq(service.get_value("fov"), 75, "broken file uses defaults")


func test_is_valid_by_type() -> void:
	var path := _temp_path()
	var service := _service(path)
	_remove(path)
	var render_scale := service.entry("render_scale")
	assert_true(service.is_valid(render_scale, 55), "integer on step")
	assert_true(service.is_valid(render_scale, 55.0), "JSON float integer accepted")
	assert_false(service.is_valid(render_scale, 53), "integer off step")
	assert_false(service.is_valid(render_scale, 55.5), "fractional integer")
	assert_false(service.is_valid(render_scale, 45), "integer below min")
	assert_false(service.is_valid(render_scale, "55"), "string integer")
	var gamma := service.entry("gamma")
	assert_true(service.is_valid(gamma, 1.05), "number on grid")
	assert_true(service.is_valid(gamma, 1), "int number")
	assert_false(service.is_valid(gamma, 1.07), "number off grid")
	assert_false(service.is_valid(gamma, 1.6), "number above max")
	assert_true(service.is_valid(service.entry("mouse_sensitivity"), 0.0031), "small step grid")
	var bind := service.entry("bind_fire")
	assert_true(service.is_valid(bind, "Ctrl+KeyB"), "modifier binding")
	assert_true(service.is_valid(bind, "Ctrl+Alt+Shift+KeyB"), "all modifiers in order")
	assert_false(service.is_valid(bind, "Shift+Ctrl+KeyB"), "modifiers out of order")
	assert_false(service.is_valid(bind, "Ctrl+Ctrl+KeyB"), "duplicate modifier")
	assert_false(service.is_valid(bind, "Ctrl+"), "missing key")
	assert_true(service.is_valid(bind, null), "unbound binding")
	assert_true(service.is_valid(service.entry("show_damage_numbers"), true), "boolean")
	assert_false(service.is_valid(service.entry("show_damage_numbers"), 1), "int is not boolean")
	assert_true(service.is_valid(service.entry("display_mode"), "fullscreen"), "enum option")
	assert_false(service.is_valid(service.entry("display_mode"), "exclusive"), "enum non-option")
	assert_true(service.is_valid(service.entry("voice_input_device"), "mic_1"), "device id")
	assert_false(service.is_valid(service.entry("voice_input_device"), ""), "empty device")
	var muted := service.entry("muted_players")
	assert_true(service.is_valid(muted, [2, 3.0]), "integer array")
	assert_false(service.is_valid(muted, [2, 2]), "duplicate peers")
	assert_false(service.is_valid(muted, [0]), "non-positive peer")
	assert_false(service.is_valid(service.entry("reset_all"), null), "action is never a value")


func test_apply_patch_rejections() -> void:
	var path := _temp_path()
	var service := _service(path)
	assert_eq(service.apply_patch(5, {"fov": 90})["error"], "stale_revision", "stale revision")
	assert_eq(service.apply_patch(0, {"nope": 1})["error"], "bad_params", "unknown key")
	assert_eq(service.apply_patch(0, {"reset_all": null})["error"], "bad_params", "action key")
	assert_eq(service.apply_patch(0, {"fov": 101})["error"], "bad_params", "invalid value")
	assert_eq(service.apply_patch(0, {"bind_sprint": "KeyZ"})["error"], "unsupported", "coming_later key")
	assert_eq(service.apply_patch(0, {"telemetry": true})["error"], "unsupported", "hidden key")
	assert_false(FileAccess.file_exists(path), "rejected patches write nothing")
	_remove(path)
	assert_eq(service.view()["revision"], 0, "rejections keep the revision")


func test_apply_patch_binding_conflict() -> void:
	var path := _temp_path()
	var service := _service(path)
	service.set_capability("reload", true)
	var result := service.apply_patch(0, {"bind_reload": "KeyW"})
	var debug_ok := service.apply_patch(0, {"bind_party_create": "Ctrl+Digit1"})
	_remove(path)
	assert_eq(result["error"], "binding_conflict", "same key in one context")
	assert_eq(result["data"].get("conflict"), ["bind_move_forward", "bind_reload"], "both keys reported")
	assert_eq(service.get_value("bind_reload"), "KeyB", "conflict changes nothing")
	assert_true(debug_ok["ok"], "debug shortcuts are their own context")


func test_apply_patch_success_saves_and_emits() -> void:
	var path := _temp_path()
	var service := _service(path)
	var emitted: Array = []
	service.changed.connect(func(values: Dictionary, keys: Array) -> void: emitted.append([values, keys]))
	var result := service.apply_patch(0, {"fov": 90.0, "gamma": 1.2})
	var reloaded := _service(path)
	_remove(path)
	assert_true(result["ok"], "valid patch applies")
	assert_eq(result["data"], {"previewToken": null}, "no display preview")
	assert_eq(service.view()["revision"], 1, "revision increments")
	assert_eq(service.get_value("fov"), 90, "value in memory")
	assert_true(service.get_value("fov") is int, "JSON float stored as int")
	assert_eq(reloaded.get_value("fov"), 90, "new service sees the saved value")
	assert_eq(reloaded.get_value("gamma"), 1.2, "number saved")
	assert_eq(emitted.size(), 1, "changed emitted once")
	if emitted.size() == 1:
		var keys: Array = emitted[0][1]
		keys.sort()
		assert_eq(keys, ["fov", "gamma"], "changed keys")


func test_unbound_binding_round_trip() -> void:
	var path := _temp_path()
	var service := _service(path)
	var result := service.apply_patch(0, {"bind_party_create": null})
	var reloaded := _service(path)
	_remove(path)
	assert_true(result["ok"], "unbinding applies")
	assert_eq(reloaded.get_value("bind_party_create"), null, "unbound survives a reload")


func test_session_key_not_saved_and_cleared() -> void:
	var path := _temp_path()
	var service := _service(path)
	var result := service.apply_patch(0, {"party_invites": "nobody"})
	var config := ConfigFile.new()
	config.load(path)
	var reloaded := _service(path)
	_remove(path)
	assert_true(result["ok"], "session patch applies")
	assert_eq(service.get_value("party_invites"), "nobody", "session value in memory")
	assert_false(config.has_section_key("social", "party_invites"), "session key not in the file")
	assert_eq(reloaded.get_value("party_invites"), "everyone", "new service uses the default")
	var emitted: Array = []
	service.changed.connect(func(_values: Dictionary, keys: Array) -> void: emitted.append(keys))
	service.clear_session()
	assert_eq(service.get_value("party_invites"), "everyone", "clear_session resets")
	assert_eq(emitted, [["party_invites"]], "clear_session emits the changed key")
	service.clear_session()
	assert_eq(emitted.size(), 1, "nothing to clear emits nothing")


func test_capabilities() -> void:
	var path := _temp_path()
	var service := _service(path)
	_remove(path)
	var caps := service.capabilities()
	assert_eq(caps["fov"], {"visible": true, "enabled": true, "reason": null}, "no gate")
	assert_eq(caps["bind_sprint"], {"visible": true, "enabled": false, "reason": "coming_later"}, "coming later")
	assert_eq(caps["voice_chat"], {"visible": false, "enabled": false, "reason": "requires_voice"}, "voice hidden")
	assert_eq(caps["telemetry"], {"visible": false, "enabled": false, "reason": "requires_backend"}, "backend hidden")
	var debug_enabled := OS.is_debug_build()
	assert_eq(caps["bind_join_motel"]["enabled"], debug_enabled, "debug shortcuts follow the build")
	service.set_capability(SettingsService.DEBUG_CAPABILITY, false)
	assert_eq(service.capabilities()["bind_join_motel"], {"visible": false, "enabled": false, "reason": "debug_only"}, "debug only")
	service.set_capability("sprint", true)
	assert_true(service.capabilities()["bind_sprint"]["enabled"], "capability flip enables the key")


func test_view_shape_and_pending_restart() -> void:
	var path := _temp_path()
	var service := _service(path)
	var view := service.view()
	var keys: Array = view.keys()
	keys.sort()
	var expected: Array = VIEW_KEYS.duplicate()
	expected.sort()
	assert_eq(keys, expected, "exactly the SettingsView keys")
	assert_eq((view["capabilities"] as Dictionary).size(), SCHEMA_ENTRIES, "one availability per entry")
	assert_eq(view["preview"], null, "no preview")
	assert_eq(view["saveError"], null, "no save error")
	assert_eq(view["displayModes"], ["windowed", "borderless", "fullscreen"], "display modes")
	assert_eq(view["devices"]["input"][0]["id"], "system_default", "input device")
	assert_eq(view["pendingRestart"], [], "nothing pending at launch")
	service.apply_patch(0, {"textures": "high"})
	var pending := service.pending_restart()
	service.apply_patch(1, {"textures": "medium"})
	var back := service.pending_restart()
	_remove(path)
	assert_eq(pending, ["textures"], "textures needs a restart after change")
	assert_eq(back, [], "back to the launch value clears it")


func test_active_bindings() -> void:
	var path := _temp_path()
	var service := _service(path)
	var active := service.active_bindings()
	service.set_capability(SettingsService.DEBUG_CAPABILITY, false)
	var release := service.active_bindings()
	service.set_capability(SettingsService.DEBUG_CAPABILITY, true)
	var debug := service.active_bindings()
	var result := service.apply_patch(service.view()["revision"], {"bind_party_create": null})
	var unbound := service.active_bindings()
	_remove(path)
	assert_eq(active.get("bind_interact"), "KeyE", "enabled binding is active")
	for key: String in ["bind_look", "bind_pause", "bind_reload"]:
		assert_false(active.has(key), "%s is not active" % key)
	for key: String in ["bind_join_motel", "bind_join_lootybay", "bind_join_house", "bind_join_center", "bind_sell_loot", "bind_search_take"]:
		assert_false(release.has(key), "%s is dropped without debug shortcuts" % key)
		assert_true(debug.has(key), "%s is active with debug shortcuts" % key)
	assert_true(result["ok"], "unbinding applies")
	assert_false(unbound.has("bind_party_create"), "unbound binding is not active")


func test_fixed_and_invalid_bindings() -> void:
	var path := _temp_path()
	var service := _service(path)
	var look_change := service.apply_patch(service.view()["revision"], {"bind_look": "KeyL"})
	var look_same := service.apply_patch(service.view()["revision"], {"bind_look": "MouseMotion"})
	var bad_code := service.apply_patch(service.view()["revision"], {"bind_interact": "KeyFoo"})
	var bad_motion := service.apply_patch(service.view()["revision"], {"bind_sell_loot": "MouseMotion"})
	_remove(path)
	assert_eq(look_change["error"], "unsupported", "fixed binding cannot change")
	assert_true(look_same["ok"], "fixed binding with its current value passes")
	assert_eq(bad_code["error"], "bad_params", "unknown code")
	assert_eq(bad_motion["error"], "bad_params", "MouseMotion only for bind_look")


func test_stored_fixed_binding_ignored() -> void:
	var path := _temp_path()
	var config := ConfigFile.new()
	config.set_value("controls", "bind_look", "KeyL")
	config.save(path)
	var service := _service(path)
	_remove(path)
	assert_eq(service.get_value("bind_look"), "MouseMotion", "fixed binding loads the default")


func test_capture_error() -> void:
	var path := _temp_path()
	var service := _service(path)
	_remove(path)
	assert_eq(service.capture_error("nope"), "bad_params", "unknown key")
	assert_eq(service.capture_error("fov"), "bad_params", "not a binding")
	assert_eq(service.capture_error("bind_pause"), "bad_params", "fixed binding")
	assert_eq(service.capture_error("bind_reload"), "not_available", "coming later binding")
	assert_eq(service.capture_error("bind_interact"), "", "capturable binding")


func test_preview_start() -> void:
	var path := _temp_path()
	var service := _service(path)
	var result := service.apply_patch(0, {"display_mode": "windowed"}, 1000)
	var file_written := FileAccess.file_exists(path)
	_remove(path)
	var token: Variant = result["data"].get("previewToken")
	assert_true(result["ok"], "display patch is accepted")
	assert_true(token is String, "display patch returns a preview token")
	assert_eq(service.view(1000)["revision"], 0, "preview keeps the revision")
	assert_false(file_written, "preview saves nothing")
	assert_eq(service.view(1000)["preview"]["token"], token, "view carries the token")
	assert_eq(service.view(1000)["preview"]["secondsLeft"], 15, "15 s at the start")
	assert_eq(service.view(15001)["preview"]["secondsLeft"], 1, "rounds up to 1 s")
	assert_false(service.preview_expired(15999), "not expired before 15 s")
	assert_true(service.preview_expired(16000), "expired at 15 s")


func test_auto_revert_due() -> void:
	var path := _temp_path()
	var service := _service(path)
	var none_open := service.auto_revert_due(1000, true)
	var none_closed := service.auto_revert_due(1000, false)
	service.apply_patch(0, {"display_mode": "windowed"}, 1000)
	_remove(path)
	assert_false(none_open, "no preview, settings open")
	assert_false(none_closed, "no preview, settings closed")
	assert_true(service.auto_revert_due(1000, false), "settings closed reverts")
	assert_false(service.auto_revert_due(1000, true), "running preview with settings open")
	assert_true(service.auto_revert_due(16000, true), "timed out preview reverts")


func test_preview_not_started_and_busy() -> void:
	var path := _temp_path()
	var service := _service(path)
	var plain := service.apply_patch(0, {"fov": 90})
	var preview := service.apply_patch(1, {"display_mode": "windowed"}, 1000)
	var busy := service.apply_patch(1, {"fov": 80}, 1000)
	_remove(path)
	assert_eq(plain["data"], {"previewToken": null}, "no display key, no preview")
	assert_true(preview["data"].get("previewToken") is String, "display key starts a preview")
	assert_eq(busy["error"], "busy", "apply during a preview is busy")


func test_confirm_wrong_token() -> void:
	var path := _temp_path()
	var service := _service(path)
	service.apply_patch(0, {"display_mode": "windowed"}, 1000)
	var r := service.confirm_preview("wrong", true, 2000)
	_remove(path)
	assert_eq(r, {"ok": false, "error": "preview_expired"}, "wrong token is preview_expired")
	assert_true(service.preview_active(), "the running preview is untouched")


func test_confirm_keep() -> void:
	var path := _temp_path()
	var service := _service(path)
	var emitted: Array = []
	service.changed.connect(func(_values: Dictionary, keys: Array) -> void: emitted.append(keys))
	var token := String(service.apply_patch(0, {"display_mode": "windowed"}, 1000)["data"]["previewToken"])
	var r := service.confirm_preview(token, true, 2000)
	var reloaded := _service(path)
	_remove(path)
	assert_eq(r, {"ok": true, "error": ""}, "keep is ok")
	assert_eq(service.view()["revision"], 1, "keep increments the revision")
	assert_eq(reloaded.get_value("display_mode"), "windowed", "keep saves the value")
	assert_eq(emitted, [["display_mode"]], "keep emits changed")
	assert_eq(service.view()["preview"], null, "no preview after keep")


func test_confirm_revert() -> void:
	var path := _temp_path()
	var service := _service(path)
	var token := String(service.apply_patch(0, {"display_mode": "windowed"}, 1000)["data"]["previewToken"])
	var r := service.confirm_preview(token, false, 2000)
	var file_written := FileAccess.file_exists(path)
	_remove(path)
	assert_eq(r, {"ok": true, "error": ""}, "revert is ok")
	assert_false(file_written, "revert saves nothing")
	assert_eq(service.get_value("display_mode"), "borderless", "revert keeps the old value")
	assert_eq(service.view()["saveError"], null, "revert has no save error")
	assert_false(service.preview_active(), "no preview after revert")


func test_confirm_keep_expired() -> void:
	var path := _temp_path()
	var service := _service(path)
	var token := String(service.apply_patch(0, {"display_mode": "windowed"}, 1000)["data"]["previewToken"])
	var r := service.confirm_preview(token, true, 16000)
	_remove(path)
	assert_eq(r, {"ok": false, "error": "preview_expired"}, "late keep is preview_expired")
	assert_false(service.preview_active(), "late keep drops the preview")
	assert_eq(service.view()["saveError"], "preview_reverted", "late keep reports preview_reverted")


func test_revert_preview_then_apply_clears_error() -> void:
	var path := _temp_path()
	var service := _service(path)
	service.apply_patch(0, {"display_mode": "windowed"}, 1000)
	service.revert_preview()
	var reverted_error: Variant = service.view()["saveError"]
	var applied := service.apply_patch(0, {"fov": 90})
	_remove(path)
	assert_eq(reverted_error, "preview_reverted", "automatic revert reports preview_reverted")
	assert_true(applied["ok"], "apply after a revert works")
	assert_eq(service.view()["saveError"], null, "successful apply clears the error")


func test_keep_save_failure() -> void:
	var path := "user://missing_dir_%d_%d/settings.cfg" % [Time.get_ticks_usec(), randi()]
	var service := _service(path)
	var token := String(service.apply_patch(0, {"display_mode": "windowed"}, 1000)["data"]["previewToken"])
	var r := service.confirm_preview(token, true, 2000)
	assert_eq(r, {"ok": false, "error": "save_failed"}, "keep with a failing save")
	assert_false(service.preview_active(), "failed keep drops the preview")
	assert_eq(service.save_error, "save_failed", "failed keep sets save_failed")
	assert_eq(service.get_value("display_mode"), "borderless", "failed keep keeps the old value")
	assert_eq(service.view()["revision"], 0, "failed keep keeps the revision")
	assert_eq(service.view()["preview"], null, "no preview after a failed keep")
