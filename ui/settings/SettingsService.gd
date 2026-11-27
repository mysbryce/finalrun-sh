class_name SettingsService
extends RefCounted
## Client settings: schema (ui/web/public/settings-schema.json), validation,
## ConfigFile storage and the SettingsView snapshot for the page
## (docs/ui-design/03-settings.md, DATA_CONTRACTS.md). Values are only stored,
## validated and published here; engine effects live elsewhere.

## Emitted after a successful apply or a session reset.
signal changed(values: Dictionary, changed_keys: Array)

const STORAGE_CONFIG_FILE := "config_file"
const STORAGE_SESSION := "session"
const TYPE_ACTION := "action"
const TYPE_BINDING := "binding"
const UNAVAILABLE_HIDDEN := "hidden"
const UNAVAILABLE_COMING_LATER := "coming_later"
const DEBUG_CAPABILITY := "debug_shortcuts"
const VOICE_CAPABILITY := "voice_chat"
const BACKEND_SUFFIX := "_backend"
## ConfigFile.set_value(null) erases the key, so an unbound binding is stored as "".
const UNBOUND_STORED := ""
const NUMBER_GRID_EPSILON := 1e-6
const TMP_SUFFIX := ".tmp"
const SYSTEM_DEFAULT_DEVICE := {"id": "system_default", "label": "System default", "available": true}
const DISPLAY_MODES: Array = ["windowed", "borderless", "fullscreen"]

var save_error: Variant = null

var _config_path: String
var _schema_path: String
var _schema: Array = []
var _by_key: Dictionary = {}
var _values: Dictionary = {}
var _launch_values: Dictionary = {}
var _saved_keys: Array = []
var _capabilities: Dictionary = {}
var _revision: int = 0
## Running display preview {token, merged, started_ms}; {} when none.
var _preview: Dictionary = {}
var _next_token: int = 0
var _key_pattern: RegEx = RegEx.create_from_string("^[A-Za-z0-9]+$")


func _init(config_path: String = GameConst.SETTINGS_PATH, schema_path: String = GameConst.SETTINGS_SCHEMA_PATH) -> void:
	_config_path = config_path
	_schema_path = schema_path


## Reads the schema and the ConfigFile. Missing file = all defaults; invalid
## stored values fall back to the default.
func load() -> void:
	_schema = []
	_by_key = {}
	_values = {}
	_saved_keys = []
	_preview = {}
	save_error = null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_schema_path))
	if parsed is Array:
		for raw: Variant in parsed:
			if raw is Dictionary and String((raw as Dictionary).get("key", "")) != "":
				_schema.append(raw)
				_by_key[String(raw["key"])] = raw
	else:
		push_error("SettingsService: could not parse schema %s" % _schema_path)
	_capabilities = {}
	for e: Dictionary in _schema:
		var capability: Variant = e.get("capability")
		if capability is String and not _capabilities.has(capability):
			_capabilities[capability] = false
	_capabilities[DEBUG_CAPABILITY] = OS.is_debug_build()
	var config := ConfigFile.new()
	var has_file := false
	if FileAccess.file_exists(_config_path):
		if config.load(_config_path) == OK:
			has_file = true
		else:
			save_error = "load_failed"
	for e: Dictionary in _schema:
		if String(e.get("type", "")) == TYPE_ACTION:
			continue
		var key := String(e["key"])
		var value: Variant = _default_of(e)
		if has_file and String(e.get("storage", "")) == STORAGE_CONFIG_FILE:
			var tab := String(e.get("tab", ""))
			if config.has_section_key(tab, key):
				_saved_keys.append(key)
				var stored: Variant = config.get_value(tab, key)
				if String(e.get("type", "")) == TYPE_BINDING and stored is String and stored == UNBOUND_STORED:
					stored = null
				# Fixed bindings always use the schema default.
				if is_valid(e, stored) and not GameConst.FIXED_BINDINGS.has(key):
					value = _normalize(e, stored)
		_values[key] = value
	_launch_values = _values.duplicate(true)


func entry(key: String) -> Dictionary:
	return _by_key.get(key, {})


## Every non-action key -> current value.
func values() -> Dictionary:
	return _values.duplicate(true)


## Keys present in the loaded settings file ([] when there was no file).
func saved_keys() -> Array:
	return _saved_keys.duplicate()


func get_value(key: String) -> Variant:
	return _values.get(key)


func is_valid(e: Dictionary, value: Variant) -> bool:
	match String(e.get("type", "")):
		"boolean":
			return value is bool
		"enum":
			return value is String and (e.get("options", []) as Array).has(value)
		"integer":
			return _is_valid_integer(e, value)
		"number":
			return _is_valid_number(e, value)
		TYPE_BINDING:
			if value == null:
				return true
			if not value is String or not _is_valid_binding(value) or not InputBindings.is_valid_code(value):
				return false
			return value != GameConst.LOOK_BINDING_CODE or String(e.get("key", "")) == "bind_look"
		"device":
			return value is String and value != ""
		"integer_array":
			return _is_valid_integer_array(value)
		_:
			return false


## key -> SettingAvailability for every schema entry.
func capabilities() -> Dictionary:
	var result: Dictionary = {}
	for e: Dictionary in _schema:
		result[String(e["key"])] = _availability(e)
	return result


func set_capability(capability_name: String, on: bool) -> void:
	_capabilities[capability_name] = on


## Bindings to dispatch, action -> code, in schema order: no unbound (null)
## values, no fixed bindings, no keys whose capability is not enabled.
func active_bindings() -> Dictionary:
	var result: Dictionary = {}
	for e: Dictionary in _schema:
		if String(e.get("type", "")) != TYPE_BINDING:
			continue
		var key := String(e["key"])
		var value: Variant = _values.get(key)
		if value == null or GameConst.FIXED_BINDINGS.has(key):
			continue
		if not bool(_availability(e)["enabled"]):
			continue
		result[key] = value
	return result


## settings.capture error for `key`: bad_params (unknown, not a binding, fixed),
## not_available (capability not enabled) or "".
func capture_error(key: String) -> String:
	if not _by_key.has(key):
		return "bad_params"
	var e: Dictionary = _by_key[key]
	if String(e.get("type", "")) != TYPE_BINDING or GameConst.FIXED_BINDINGS.has(key):
		return "bad_params"
	if not bool(_availability(e)["enabled"]):
		return "not_available"
	return ""


## Validates and commits a full patch. Returns {ok, error, data}. A patch that
## changes a display key starts a preview instead (nothing saved, data.previewToken
## set); confirm_preview keeps or drops it.
func apply_patch(revision: int, patch: Dictionary, now_ms: int = Time.get_ticks_msec()) -> Dictionary:
	if preview_active():
		return _fail("busy")
	if revision != _revision:
		return _fail("stale_revision")
	for raw_key: Variant in patch.keys():
		var key := String(raw_key)
		if not raw_key is String or not _by_key.has(key):
			return _fail("bad_params")
		var e: Dictionary = _by_key[key]
		if String(e.get("type", "")) == TYPE_ACTION:
			return _fail("bad_params")
		if not is_valid(e, patch[raw_key]):
			return _fail("bad_params")
	for raw_key: Variant in patch.keys():
		var key := String(raw_key)
		if GameConst.FIXED_BINDINGS.has(key) and not _same(_values.get(key), _normalize(_by_key[key], patch[raw_key])):
			return _fail("unsupported")
	for raw_key: Variant in patch.keys():
		if not bool(_availability(_by_key[String(raw_key)])["enabled"]):
			return _fail("unsupported")
	var merged := _values.duplicate(true)
	for raw_key: Variant in patch.keys():
		var key := String(raw_key)
		merged[key] = _normalize(_by_key[key], patch[raw_key])
	var conflict := _binding_conflict(merged)
	if not conflict.is_empty():
		return {"ok": false, "error": "binding_conflict", "data": {"conflict": conflict}}
	for key: String in SettingsApplier.DISPLAY_KEYS:
		if not _same(_values.get(key), merged.get(key)):
			_next_token += 1
			var token := "p%d" % _next_token
			_preview = {"token": token, "merged": merged, "started_ms": now_ms}
			return {"ok": true, "error": "", "data": {"previewToken": token}}
	if not _commit(merged):
		return _fail("save_failed")
	return {"ok": true, "error": "", "data": {"previewToken": null}}


func preview_active() -> bool:
	return not _preview.is_empty()


## Token of the running preview, "" when none.
func preview_token() -> String:
	return String(_preview.get("token", ""))


## Merged values of the running preview, {} when none.
func preview_values() -> Dictionary:
	if _preview.is_empty():
		return {}
	return (_preview["merged"] as Dictionary).duplicate(true)


func preview_expired(now_ms: int) -> bool:
	return preview_active() and now_ms - int(_preview["started_ms"]) >= GameConst.DISPLAY_PREVIEW_MS


## The preview must revert on its own: timed out or Settings no longer open.
func auto_revert_due(now_ms: int, settings_open: bool) -> bool:
	return preview_active() and (preview_expired(now_ms) or not settings_open)


## settings.display_confirm. Returns {ok, error}. Keep saves the previewed patch
## like a normal apply; revert drops it.
func confirm_preview(token: String, keep: bool, now_ms: int = Time.get_ticks_msec()) -> Dictionary:
	if not preview_active() or token != preview_token():
		return {"ok": false, "error": "preview_expired"}
	if preview_expired(now_ms):
		revert_preview()
		return {"ok": false, "error": "preview_expired"}
	var merged: Dictionary = _preview["merged"]
	_preview = {}
	if not keep:
		save_error = null
		return {"ok": true, "error": ""}
	if not _commit(merged):
		return {"ok": false, "error": "save_failed"}
	return {"ok": true, "error": ""}


## Automatic revert (timer, focus loss, Settings closed, page reload). No-op without a preview.
func revert_preview() -> void:
	if not preview_active():
		return
	_preview = {}
	save_error = "preview_reverted"


## Saves `merged` and makes it the current values (revision + 1, changed emitted).
## On failure sets save_error = "save_failed" and changes nothing else.
func _commit(merged: Dictionary) -> bool:
	if not _save(merged):
		save_error = "save_failed"
		return false
	save_error = null
	var changed_keys: Array = []
	for key: String in merged.keys():
		if not _same(_values.get(key), merged[key]):
			changed_keys.append(key)
	_values = merged
	_revision += 1
	changed.emit(values(), changed_keys)
	return true


## Session keys back to their defaults (new connection or disconnect).
func clear_session() -> void:
	var changed_keys: Array = []
	for e: Dictionary in _schema:
		if String(e.get("storage", "")) != STORAGE_SESSION:
			continue
		var key := String(e["key"])
		var value: Variant = _default_of(e)
		if not _same(_values.get(key), value):
			_values[key] = value
			changed_keys.append(key)
	if not changed_keys.is_empty():
		changed.emit(values(), changed_keys)


## Keys that need a restart and differ from the values at launch.
func pending_restart() -> Array:
	var result: Array = []
	for e: Dictionary in _schema:
		if not bool(e.get("restart", false)):
			continue
		var key := String(e["key"])
		if _values.has(key) and not _same(_values[key], _launch_values.get(key)):
			result.append(key)
	return result


## SettingsView for the page.
func view(now_ms: int = Time.get_ticks_msec()) -> Dictionary:
	var preview: Variant = null
	if preview_active():
		var left_ms := GameConst.DISPLAY_PREVIEW_MS - (now_ms - int(_preview["started_ms"]))
		preview = {"token": preview_token(), "secondsLeft": maxi(0, ceili(left_ms / 1000.0))}
	return {
		"values": values(),
		"revision": _revision,
		"capabilities": capabilities(),
		"devices": {
			"input": [SYSTEM_DEFAULT_DEVICE.duplicate()],
			"output": [SYSTEM_DEFAULT_DEVICE.duplicate()],
		},
		"displayModes": DISPLAY_MODES.duplicate(),
		"pendingRestart": pending_restart(),
		"preview": preview,
		"saveError": save_error,
	}


func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error, "data": {}}


func _default_of(e: Dictionary) -> Variant:
	var value: Variant = e.get("default")
	return _normalize(e, value) if is_valid(e, value) else value


## JSON numbers arrive as float: store integers as int and numbers as float.
func _normalize(e: Dictionary, value: Variant) -> Variant:
	match String(e.get("type", "")):
		"integer":
			return int(value)
		"number":
			return float(value)
		"integer_array":
			var result: Array = []
			for item: Variant in value:
				result.append(int(item))
			return result
		_:
			return value


func _same(a: Variant, b: Variant) -> bool:
	return typeof(a) == typeof(b) and a == b


func _is_int_like(value: Variant) -> bool:
	return value is int or (value is float and is_finite(value) and value == floorf(value))


func _is_valid_integer(e: Dictionary, value: Variant) -> bool:
	if not _is_int_like(value):
		return false
	var number := int(value)
	var low: Variant = e.get("min")
	var high: Variant = e.get("max")
	var step: Variant = e.get("step")
	if low != null and number < int(low):
		return false
	if high != null and number > int(high):
		return false
	if step != null and int(step) > 0:
		var base := int(low) if low != null else 0
		if (number - base) % int(step) != 0:
			return false
	return true


func _is_valid_number(e: Dictionary, value: Variant) -> bool:
	if not (value is int or value is float):
		return false
	var number := float(value)
	if not is_finite(number):
		return false
	var low: Variant = e.get("min")
	var high: Variant = e.get("max")
	var step: Variant = e.get("step")
	if low != null and number < float(low):
		return false
	if high != null and number > float(high):
		return false
	if step != null and float(step) > 0.0:
		var base := float(low) if low != null else 0.0
		var offset := number - base
		if absf(offset - roundf(offset / float(step)) * float(step)) > NUMBER_GRID_EPSILON:
			return false
	return true


## Ctrl+, Alt+, Shift+ in that order (no duplicates), then one key code.
func _is_valid_binding(text: String) -> bool:
	var parts := text.split(GameConst.BINDING_SEPARATOR)
	if not _key_pattern.search(parts[parts.size() - 1]):
		return false
	var last_modifier := -1
	for i in parts.size() - 1:
		var index := GameConst.BINDING_MODIFIERS.find(parts[i])
		if index <= last_modifier:
			return false
		last_modifier = index
	return true


func _is_valid_integer_array(value: Variant) -> bool:
	if not value is Array:
		return false
	var seen: Dictionary = {}
	for item: Variant in value:
		if not _is_int_like(item) or int(item) <= 0 or seen.has(int(item)):
			return false
		seen[int(item)] = true
	return true


func _availability(e: Dictionary) -> Dictionary:
	var capability: Variant = e.get("capability")
	if not capability is String or bool(_capabilities.get(capability, false)):
		return {"visible": true, "enabled": true, "reason": null}
	if e.get("unavailable") == UNAVAILABLE_COMING_LATER:
		return {"visible": true, "enabled": false, "reason": "coming_later"}
	var reason := "unsupported"
	if capability == DEBUG_CAPABILITY:
		reason = "debug_only"
	elif String(capability).ends_with(BACKEND_SUFFIX):
		reason = "requires_backend"
	elif capability == VOICE_CAPABILITY:
		reason = "requires_voice"
	return {"visible": false, "enabled": false, "reason": reason}


## Two bindings with the same non-null value in one context, or [].
## Debug-shortcut bindings form their own context.
func _binding_conflict(merged: Dictionary) -> Array:
	var seen: Dictionary = {}
	for e: Dictionary in _schema:
		if String(e.get("type", "")) != TYPE_BINDING:
			continue
		var key := String(e["key"])
		var value: Variant = merged.get(key)
		if value == null:
			continue
		var context := DEBUG_CAPABILITY if e.get("capability") == DEBUG_CAPABILITY else ""
		var slot := "%s|%s" % [context, value]
		if seen.has(slot):
			return [seen[slot], key]
		seen[slot] = key
	return []


## Writes every config_file value to a temp file, then renames it over the real one.
func _save(merged: Dictionary) -> bool:
	var config := ConfigFile.new()
	for e: Dictionary in _schema:
		if String(e.get("storage", "")) != STORAGE_CONFIG_FILE or String(e.get("type", "")) == TYPE_ACTION:
			continue
		var key := String(e["key"])
		var value: Variant = merged.get(key)
		if value == null and String(e.get("type", "")) == TYPE_BINDING:
			value = UNBOUND_STORED
		config.set_value(String(e.get("tab", "")), key, value)
	var tmp_path := _config_path + TMP_SUFFIX
	if config.save(tmp_path) != OK:
		return false
	var from := ProjectSettings.globalize_path(tmp_path)
	var to := ProjectSettings.globalize_path(_config_path)
	if DirAccess.rename_absolute(from, to) != OK:
		DirAccess.remove_absolute(from)
		return false
	return true
