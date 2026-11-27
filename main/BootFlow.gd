class_name BootFlow
extends RefCounted
## Client boot coordinator (docs/ui-design/01-splash.md). Pure logic: no nodes,
## every call gets `now_ms` from Main. Main runs the actions `tick` returns.
## ponytail: no asset preload exists, so the Assets stage is complete at start and
## `progress` stays null; add real preload progress and the 30 s asset watchdog
## when there is something to preload.

const CEF_ERRORS: Array[String] = ["cef_timeout", "cef_unavailable"]
const CONNECTION_ERRORS: Array[String] = ["connection_failed", "connection_timeout", "invalid_endpoint"]

## "title", "cef", "connecting", "ready" or "failed".
var phase: String = "title"
## null or a BootError string.
var error: Variant = null
var title_done: bool = false
var page_ready: bool = false

var _build_id: String = ""
var _start_ms: int = 0
var _cef_start_ms: int = 0
var _connect_start_ms: int = 0
var _last_now_ms: int = 0


func start(now_ms: int, id: String) -> void:
	_build_id = id
	phase = "title"
	error = null
	title_done = false
	page_ready = false
	_start_ms = now_ms
	_cef_start_ms = now_ms
	_last_now_ms = now_ms


## Ends the title dwell early. Returns whether it took effect.
func skip(now_ms: int) -> bool:
	_last_now_ms = now_ms
	if not _can_skip(now_ms):
		return false
	title_done = true
	return true


func on_page_ready(now_ms: int) -> void:
	_last_now_ms = now_ms
	page_ready = true
	if phase == "failed" and error == "cef_timeout":
		phase = "cef"
		error = null


## Advances timers. Returns "connect", "fail_cef", "abort_connect" or "".
func tick(now_ms: int) -> String:
	_last_now_ms = now_ms
	if not title_done and now_ms - _start_ms >= GameConst.BOOT_TITLE_DWELL_MS:
		title_done = true
	if phase == "title" or phase == "cef":
		if title_done and page_ready:
			phase = "connecting"
			_connect_start_ms = now_ms
			return "connect"
		if not page_ready and now_ms - _cef_start_ms >= GameConst.BOOT_CEF_TIMEOUT_MS:
			phase = "failed"
			error = "cef_timeout"
			return "fail_cef"
		if phase == "title" and title_done:
			phase = "cef"
		return ""
	if phase == "connecting" and now_ms - _connect_start_ms >= GameConst.BOOT_CONNECT_TIMEOUT_MS:
		phase = "failed"
		error = "connection_timeout"
		return "abort_connect"
	return ""


func on_connected() -> void:
	phase = "ready"
	error = null


func on_connection_failed(reason: String) -> void:
	if phase != "connecting":
		return
	phase = "failed"
	error = reason


## Restarts the failed stage. Returns "reload", "connect" or "".
func retry(now_ms: int) -> String:
	_last_now_ms = now_ms
	if phase != "failed":
		return ""
	var reason := String(error) if error is String else ""
	if CEF_ERRORS.has(reason):
		phase = "cef"
		error = null
		page_ready = false
		_cef_start_ms = now_ms
		return "reload"
	if CONNECTION_ERRORS.has(reason):
		phase = "connecting"
		error = null
		_connect_start_ms = now_ms
		return "connect"
	return ""


## BootView for the page.
func view() -> Dictionary:
	return {
		"phase": phase,
		"buildId": _build_id,
		"progress": null,
		"canSkipTitle": _can_skip(_last_now_ms),
		"error": error,
		"canRetry": phase == "failed",
	}


func _can_skip(now_ms: int) -> bool:
	if phase != "title" and phase != "cef":
		return false
	if title_done:
		return false
	var elapsed := now_ms - _start_ms
	return elapsed >= GameConst.BOOT_SKIP_AFTER_MS and elapsed < GameConst.BOOT_TITLE_DWELL_MS


## Server endpoint from user args: `--connect host:port` or `--connect=host:port`.
## Returns {"host", "port", "ok"}; a bad override gives ok false with the defaults.
static func parse_endpoint(user_args: PackedStringArray) -> Dictionary:
	var fallback := {"host": GameConst.DEFAULT_SERVER_HOST, "port": GameConst.PORT, "ok": true}
	var bad := {"host": GameConst.DEFAULT_SERVER_HOST, "port": GameConst.PORT, "ok": false}
	for i in user_args.size():
		var arg := user_args[i]
		var value := ""
		if arg == "--connect":
			if i + 1 >= user_args.size() or user_args[i + 1].begins_with("--"):
				return bad
			value = user_args[i + 1]
		elif arg.begins_with("--connect="):
			value = arg.substr("--connect=".length())
		else:
			continue
		var colon := value.rfind(":")
		if colon < 0:
			return bad
		var host := value.left(colon)
		var port_text := value.substr(colon + 1)
		if host == "" or not port_text.is_valid_int():
			return bad
		var port := port_text.to_int()
		if port < 1 or port > 65535:
			return bad
		return {"host": host, "port": port, "ok": true}
	return fallback


static func build_id() -> String:
	var version := String(ProjectSettings.get_setting("application/config/version", ""))
	return "dev" if version == "" else version
