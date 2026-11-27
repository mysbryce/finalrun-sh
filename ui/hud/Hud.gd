class_name Hud
extends CanvasLayer
## Client HUD. Main feeds it the local player and ServerManager events;
## it never talks to the network. Draws the web UI (docs/design/WEB_UI.md)
## in a CefTexture.


static func role_text(role: int) -> String:
	match role:
		PlayerRoleController.Role.CITIZEN:
			return "CITIZEN"
		PlayerRoleController.Role.CRIMINAL:
			return "CRIMINAL"
		PlayerRoleController.Role.COP:
			return "COP"
		_:
			return "?"


static func life_text(life_state: int) -> String:
	match life_state:
		PlayerRoleController.LifeState.ALIVE:
			return "ALIVE"
		PlayerRoleController.LifeState.DOWNED:
			return "DOWNED"
		PlayerRoleController.LifeState.DEAD:
			return "DEAD"
		_:
			return "?"


static func seconds_left(deadline_ms: int, now_ms: int) -> int:
	return maxi(0, ceili(float(deadline_ms - now_ms) / 1000.0))


static func push_notification(list: Array, text: String, now_ms: int) -> Array:
	var result: Array = list.duplicate()
	result.append({"text": text, "expires_ms": now_ms + GameConst.HUD_NOTIFICATION_MS})
	while result.size() > GameConst.HUD_MAX_NOTIFICATIONS:
		result.pop_front()
	return result


static func prune_notifications(list: Array, now_ms: int) -> Array:
	var result: Array = []
	for entry: Dictionary in list:
		if int(entry.get("expires_ms", 0)) > now_ms:
			result.append(entry)
	return result


## True only on a client with a real display and the CEF addon loaded.
static func can_use_browser() -> bool:
	return DisplayServer.get_name() != "headless" and ClassDB.class_exists("CefTexture")


## Built page, or the Vite dev server when the client got `-- --ui-dev`.
static func page_url(user_args: PackedStringArray) -> String:
	return GameConst.UI_DEV_URL if user_args.has(GameConst.UI_DEV_FLAG) else GameConst.UI_PAGE_URL


## HudState for the page. `prompt` shows only while ALIVE.
static func snapshot(role: int, life: int, downed_deadline_ms: int, mask_end_ms: int,
		money: Dictionary, prompt: String, notifications: Array, now_ms: int) -> Dictionary:
	var timer: Variant = null
	if life == PlayerRoleController.LifeState.DOWNED:
		timer = {"label": "Bleeding out", "seconds": seconds_left(downed_deadline_ms, now_ms)}
	elif mask_end_ms > now_ms:
		timer = {"label": "Masking", "seconds": seconds_left(mask_end_ms, now_ms)}
	var texts: Array = []
	for entry: Dictionary in notifications:
		texts.append(String(entry.get("text", "")))
	return {
		"role": role_text(role),
		"life": life_text(life),
		"cash": int(money.get("cash", 0)),
		"bag": int(money.get("bag_value", 0)),
		"notoriety": int(money.get("notoriety", 0)),
		"timer": timer,
		"prompt": prompt if life == PlayerRoleController.LifeState.ALIVE else "",
		"notifications": texts,
	}


## Reply to one page request.
static func reply_for(request: Dictionary) -> Dictionary:
	var id := int(request.get("id", 0))
	if String(request.get("method", "")) == "ping":
		return {"type": "reply", "id": id, "ok": true, "data": {"pong": true}}
	return {"type": "reply", "id": id, "ok": false, "error": "unknown_method"}


var _player: Node3D = null
var _money: Dictionary = {}
var _mask_end_ms: int = 0
var _notifications: Array = []

var _browser: Control = null
var _page_ready: bool = false
var _last_hud_json: String = ""


func _ready() -> void:
	if not can_use_browser():
		return
	_browser = ClassDB.instantiate("CefTexture") as Control
	_browser.name = "Browser"
	_browser.set("url", page_url(OS.get_cmdline_user_args()))
	_browser.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_browser.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_browser.focus_mode = Control.FOCUS_NONE
	_browser.connect("ipc_message", _on_ipc_message)
	add_child(_browser)


func set_player(player: Node3D) -> void:
	_player = player


func set_money(state: Dictionary) -> void:
	_money = state.duplicate()


func set_mask_channel(seconds: float, now_ms: int) -> void:
	_mask_end_ms = now_ms + int(seconds * 1000.0) if seconds > 0.0 else 0


func add_notification(text: String, now_ms: int) -> void:
	_notifications = push_notification(_notifications, text, now_ms)


func _process(_delta: float) -> void:
	var now_ms := int(Time.get_unix_time_from_system() * 1000.0)
	_notifications = prune_notifications(_notifications, now_ms)
	if not _page_ready:
		return
	var role := -1
	var life := -1
	var downed_deadline_ms := 0
	var prompt := ""
	if _player != null and is_instance_valid(_player):
		role = int(_player.get("role"))
		life = int(_player.get("life_state"))
		downed_deadline_ms = int(_player.get("downed_deadline_ms"))
		var area := InteractArea.nearest(_player, GameConst.INTERACT_RANGE)
		prompt = area.prompt if area != null else ""
	var json := JSON.stringify({
		"type": "hud",
		"data": snapshot(role, life, downed_deadline_ms, _mask_end_ms, _money, prompt,
				_notifications, now_ms),
	})
	if json != _last_hud_json:
		_last_hud_json = json
		_send_json(json)


func _on_ipc_message(message: String) -> void:
	var parsed: Variant = JSON.parse_string(message)
	if not parsed is Dictionary:
		return
	var type := String((parsed as Dictionary).get("type", ""))
	if type == "ready":
		_page_ready = true
		_last_hud_json = ""
		_send_json(JSON.stringify({"type": "route", "to": "/"}))
	elif type == "request":
		_send_json(JSON.stringify(reply_for(parsed)))


func _send_json(json: String) -> void:
	if _browser != null and is_instance_valid(_browser):
		_browser.call("send_ipc_message", json)
