class_name Hud
extends CanvasLayer
## Client HUD. Main feeds it the local player and ServerManager events;
## it never talks to the network. Draws the web UI (docs/design/WEB_UI.md)
## in a CefTexture.

## The page asked to take an item from the open body search. Main forwards it to the server.
signal search_take_requested(target_peer_id: int, item_uid: int)
## The page asked to close the open body search.
signal search_close_requested(target_peer_id: int)
## The page dragged a bag item to a slot. Main forwards it to the server.
signal inventory_move_requested(item_uid: int, slot: int)
## The page asked to skip the boot title dwell.
signal boot_skip_requested
## The page asked to retry the failed boot stage.
signal boot_retry_requested
## The page asked to quit the game.
signal quit_requested
## The page sent `ready` (every page load, also after boot).
signal page_ready
## The lobby asked to join the configured server.
signal lobby_join_requested
## The lobby asked to reload the bundled patch notes.
signal lobby_news_retry_requested


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


## Compass heading in whole degrees 0..359: 0 = north = -Z, 90 = east = +X.
static func heading_from_yaw(yaw_rad: float) -> int:
	return posmod(int(round(-rad_to_deg(yaw_rad))), 360)


## Interact card from an InteractArea; null when prompt is empty.
## "E lockpick | V smash" -> actions [{key E, label lockpick}, {key V, label smash}].
static func interact_of(title: String, prompt: String) -> Variant:
	if prompt.strip_edges() == "":
		return null
	var actions: Array = []
	for raw_part: String in prompt.split("|"):
		var part := raw_part.strip_edges()
		if part == "":
			continue
		var space := part.find(" ")
		if space < 0:
			actions.append({"key": "", "label": part})
		else:
			actions.append({"key": part.left(space), "label": part.substr(space + 1).strip_edges()})
	return {"title": title, "actions": actions}


## Display name for a peer; "Player %d" until a name system exists.
static func player_name(peer_id: int) -> String:
	return "Player %d" % peer_id


## One other party member. present = their player node is in our instance.
static func party_entry(peer_id: int, leader_id: int, present: bool, health: int, life: int) -> Dictionary:
	return {
		"name": player_name(peer_id),
		"health": health if present else -1,
		"maxHealth": GameConst.PLAYER_MAX_HEALTH,
		"life": life_text(life) if present else "?",
		"leader": peer_id == leader_id,
		"away": not present,
	}


## Hotbar slots. ponytail: one weapon exists today, so slot 1 is fixed; build from
## equipped items once items are Resources (Phase 3).
static func hotbar() -> Array:
	var slots: Array = []
	for i in GameConst.HUD_HOTBAR_SLOTS:
		slots.append({"label": "Pistol"} if i == 0 else null)
	return slots


## HudState for the page. The interact card shows only while ALIVE.
static func snapshot(ctx: Dictionary, now_ms: int) -> Dictionary:
	var role := int(ctx.get("role", -1))
	var life := int(ctx.get("life", -1))
	var health := int(ctx.get("health", 0))
	var downed_deadline_ms := int(ctx.get("downed_deadline_ms", 0))
	var mask_end_ms := int(ctx.get("mask_end_ms", 0))
	var money: Dictionary = ctx.get("money", {})
	var interact_title := String(ctx.get("interact_title", ""))
	var interact_prompt := String(ctx.get("interact_prompt", ""))
	var notifications: Array = ctx.get("notifications", [])
	var heading := int(ctx.get("heading", 0))
	var self_id := int(ctx.get("self_id", 0))
	var party: Array = ctx.get("party", [])
	var fps := int(ctx.get("fps", 0))
	var ping := int(ctx.get("ping", 0))
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
		"health": health,
		"maxHealth": GameConst.PLAYER_MAX_HEALTH,
		"cash": int(money.get("cash", 0)),
		"bag": int(money.get("bag_value", 0)),
		"notoriety": int(money.get("notoriety", 0)),
		"heading": heading,
		"timer": timer,
		"interact": interact_of(interact_title, interact_prompt) if life == PlayerRoleController.LifeState.ALIVE else null,
		"notifications": texts,
		"self": {"name": player_name(self_id)},
		"party": party,
		"hotbar": hotbar(),
		"activeSlot": 0,
		"net": {"fps": fps, "ping": ping},
	}


## "cop_pistol" -> "Cop pistol".
static func item_label(item_id: String) -> String:
	if item_id == "":
		return ""
	var text := item_id.replace("_", " ")
	return text.substr(0, 1).to_upper() + text.substr(1)


## Search panel data for the page.
static func search_view(target_peer_id: int, items: Array) -> Dictionary:
	var list: Array = []
	for item: Dictionary in items:
		list.append(item_view(item, "bag"))
	return {"target": target_peer_id, "title": "Body of %s" % player_name(target_peer_id), "items": list}


static func item_view(item: Dictionary, default_source: String) -> Dictionary:
	var size := ItemUtils.size_of(String(item.get("id", "")))
	return {
		"uid": int(item.get("uid", 0)),
		"id": String(item.get("id", "")),
		"label": item_label(String(item.get("id", ""))),
		"value": int(item.get("value", 0)),
		"source": String(item.get("source", default_source)),
		"slot": int(item.get("slot", -1)),
		"w": size.x,
		"h": size.y,
	}


## Inventory panel data for the page.
static func inventory_view(money: Dictionary) -> Dictionary:
	var bag: Array = []
	for item: Dictionary in money.get("bag_items", []):
		bag.append(item_view(item, "bag"))
	var gear: Array = []
	for item: Dictionary in money.get("gear", []):
		gear.append(item_view(item, "gear"))
	return {
		"cash": int(money.get("cash", 0)),
		"bagValue": int(money.get("bag_value", 0)),
		"bagSlots": GameConst.INVENTORY_BAG_SLOTS,
		"bag": bag,
		"gear": gear,
	}


static func _error_reply(id: int, text: String) -> Dictionary:
	return {"reply": {"type": "reply", "id": id, "ok": false, "error": text}, "action": []}


static func _ok_reply(id: int, data: Dictionary, action: Array) -> Dictionary:
	return {"reply": {"type": "reply", "id": id, "ok": true, "data": data}, "action": action}


## Reply and optional action for one page request.
## ponytail: boot.skip / boot.retry / app.quit always reply ok; the contract's
## not_available / busy errors are deferred (Main ignores requests that do not apply).
static func route_request(request: Dictionary, open_target: int) -> Dictionary:
	var id := int(request.get("id", 0))
	var method := String(request.get("method", ""))
	var params: Dictionary = request.get("params", {}) if request.get("params", {}) is Dictionary else {}
	if method == "ping":
		return _ok_reply(id, {"pong": true}, [])
	if method == "search.take":
		var target := int(params.get("target", 0))
		var uid := int(params.get("uid", 0))
		if open_target == 0 or target != open_target:
			return _error_reply(id, "no_search")
		if uid <= 0:
			return _error_reply(id, "bad_params")
		return _ok_reply(id, {}, ["take", target, uid])
	if method == "search.close":
		var target := int(params.get("target", 0))
		if target != open_target or open_target == 0:
			return _error_reply(id, "no_search")
		return _ok_reply(id, {}, ["close", target])
	if method == "inventory.close":
		return _ok_reply(id, {}, ["inventory_close"])
	if method == "inventory.move":
		var uid := int(params.get("uid", 0))
		var slot := int(params.get("slot", -1))
		if uid <= 0 or slot < 0 or slot >= GameConst.INVENTORY_BAG_SLOTS:
			return _error_reply(id, "bad_params")
		return _ok_reply(id, {}, ["move", uid, slot])
	if method == "boot.skip":
		return _ok_reply(id, {}, ["boot_skip"])
	if method == "boot.retry":
		return _ok_reply(id, {}, ["boot_retry"])
	if method == "app.quit":
		return _ok_reply(id, {}, ["quit"])
	if method == "lobby.join":
		var mode: Variant = params.get("mode")
		if not mode is String or not ["configured", "by_id", "quick"].has(mode):
			return _error_reply(id, "bad_params")
		if mode != "configured":
			return _error_reply(id, "discovery_unavailable")
		return _ok_reply(id, {}, ["lobby_join"])
	if method == "lobby.news_retry":
		return _ok_reply(id, {}, ["news_retry"])
	if method == "settings.open":
		# ponytail: not_available until the settings card.
		return _error_reply(id, "not_available")
	return _error_reply(id, "unknown_method")


var _player: Node3D = null
var _money: Dictionary = {}
var _mask_end_ms: int = 0
var _notifications: Array = []
var _instance: GameInstance = null
var _party_members: Array[int] = []
var _party_leader: int = 0
var _fps: int = 0
var _ping: int = 0

var _browser: Control = null
var _page_ready: bool = false
var _last_hud_json: String = ""
var _minimap: Minimap = null
var _search_target: int = 0
var _search_items: Array = []
var _route: String = "/"
var _snapshots: Dictionary = {}


func _ready() -> void:
	if not can_use_browser():
		return
	_minimap = Minimap.new()
	_minimap.name = "Minimap"
	add_child(_minimap)
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
	if _minimap != null:
		_minimap.follow(player)


func set_money(state: Dictionary) -> void:
	_money = state.duplicate()
	if is_inventory_open() or is_search_open():
		_send_inventory()


func set_mask_channel(seconds: float, now_ms: int) -> void:
	_mask_end_ms = now_ms + int(seconds * 1000.0) if seconds > 0.0 else 0


func add_notification(text: String, now_ms: int) -> void:
	_notifications = push_notification(_notifications, text, now_ms)


func set_instance(instance: GameInstance) -> void:
	_instance = instance


func set_party(info: Dictionary) -> void:
	if bool(info.get("active", false)):
		_party_leader = int(info.get("leader_id", 0))
		_party_members = []
		for member: int in info.get("members", []):
			_party_members.append(int(member))
	else:
		_party_members = []
		_party_leader = 0


func set_net(fps: int, ping_ms: int) -> void:
	_fps = fps
	_ping = ping_ms


func _process(_delta: float) -> void:
	var now_ms := int(Time.get_unix_time_from_system() * 1000.0)
	_notifications = prune_notifications(_notifications, now_ms)
	if not _page_ready:
		return
	var ctx: Dictionary = {
		"money": _money,
		"mask_end_ms": _mask_end_ms,
		"notifications": _notifications,
		"fps": _fps,
		"ping": _ping,
	}
	var self_id := 0
	if _player != null and is_instance_valid(_player):
		ctx["role"] = int(_player.get("role"))
		ctx["life"] = int(_player.get("life_state"))
		ctx["health"] = int(_player.get("health"))
		ctx["downed_deadline_ms"] = int(_player.get("downed_deadline_ms"))
		self_id = int(_player.get("peer_id"))
		ctx["self_id"] = self_id
		var area := InteractArea.nearest(_player, GameConst.INTERACT_RANGE)
		if area != null:
			ctx["interact_title"] = area.title
			ctx["interact_prompt"] = area.prompt
		var camera := _player.get_viewport().get_camera_3d()
		if camera != null:
			ctx["heading"] = heading_from_yaw(camera.global_rotation.y)
	var party: Array = []
	for member: int in _party_members:
		if member == self_id:
			continue
		var node: Node = _instance.get_player(member) if _instance != null and is_instance_valid(_instance) else null
		var present := node != null
		party.append(party_entry(
			member,
			_party_leader,
			present,
			int(node.get("health")) if present else -1,
			int(node.get("life_state")) if present else -1
		))
	ctx["party"] = party
	var json := JSON.stringify({"type": "hud", "data": snapshot(ctx, now_ms)})
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
		_send_json(JSON.stringify({"type": "route", "to": _route}))
		for snapshot_json: String in _snapshots.values():
			_send_json(snapshot_json)
		if _search_target != 0:
			_send_json(JSON.stringify({"type": "search", "data": search_view(_search_target, _search_items)}))
		if is_inventory_open() or is_search_open():
			_send_inventory()
		page_ready.emit()
	elif type == "request":
		var routed := route_request(parsed, _search_target)
		_send_json(JSON.stringify(routed["reply"]))
		var action: Array = routed["action"]
		if action.size() == 3 and action[0] == "take":
			search_take_requested.emit(int(action[1]), int(action[2]))
		elif action.size() == 3 and action[0] == "move":
			inventory_move_requested.emit(int(action[1]), int(action[2]))
		elif action.size() == 2 and action[0] == "close":
			search_close_requested.emit(int(action[1]))
		elif action.size() == 1 and action[0] == "inventory_close":
			close_inventory()
		elif action.size() == 1 and action[0] == "boot_skip":
			boot_skip_requested.emit()
		elif action.size() == 1 and action[0] == "boot_retry":
			boot_retry_requested.emit()
		elif action.size() == 1 and action[0] == "quit":
			quit_requested.emit()
		elif action.size() == 1 and action[0] == "lobby_join":
			lobby_join_requested.emit()
		elif action.size() == 1 and action[0] == "news_retry":
			lobby_news_retry_requested.emit()


## Sends a snapshot message for `boot`, `lobby`, `party`, `settings`, `transfer`
## or `game_overlay` and caches it; cached snapshots are replayed on page `ready`.
## A null `data` is sent and clears the cache entry.
func publish(type: String, data: Variant) -> void:
	var json := JSON.stringify({"type": type, "data": data})
	_send_json(json)
	if data == null:
		_snapshots.erase(type)
	else:
		_snapshots[type] = json


## Shows the splash route with the current BootView.
func show_boot(view: Dictionary) -> void:
	publish("boot", view)
	if _route != "/splash":
		_navigate("/splash")
		_set_panel_input(true)


## Boot is over: clear the boot snapshot and return to the HUD.
func end_boot() -> void:
	_snapshots.erase("boot")
	_navigate("/")
	_set_panel_input(false)


## Shows the lobby route with the current LobbyView. Open search/inventory
## panels are closed locally (no server request: the connection is gone).
func show_lobby(view: Dictionary) -> void:
	if is_search_open():
		close_search(_search_target)
	close_inventory()
	publish("lobby", view)
	if _route != "/lobby":
		_navigate("/lobby")
	_set_panel_input(true)


## Lobby is over (connected again): clear the lobby snapshot and return to the HUD.
func end_lobby() -> void:
	_snapshots.erase("lobby")
	_navigate("/")
	_set_panel_input(false)


## Loads the page again (boot retry after a CEF timeout). Waits for a new `ready`.
func reload_page() -> void:
	_page_ready = false
	if _browser == null or not is_instance_valid(_browser):
		return
	if _browser.has_method("reload"):
		_browser.call("reload")
	else:
		_browser.set("url", page_url(OS.get_cmdline_user_args()))


## Body search contents arrived (first open or a change).
func open_search(target_peer_id: int, items: Array) -> void:
	_search_target = target_peer_id
	_search_items = items.duplicate(true)
	_send_json(JSON.stringify({"type": "search", "data": search_view(_search_target, _search_items)}))
	_send_inventory()
	if _route != "/search":
		_navigate("/search")
		_set_panel_input(true)


## The server closed the search (or the player walked away).
func close_search(target_peer_id: int) -> void:
	if target_peer_id != _search_target:
		return
	_search_target = 0
	_search_items = []
	_send_json(JSON.stringify({"type": "search", "data": null}))
	_navigate("/")
	_set_panel_input(false)


func is_search_open() -> bool:
	return _search_target != 0


func is_inventory_open() -> bool:
	return _route == "/inventory"


## TAB: open from the plain HUD, close when open. Ignored over other panels.
func toggle_inventory() -> void:
	if is_inventory_open():
		close_inventory()
	elif _route == "/":
		_send_inventory()
		_navigate("/inventory")
		_set_panel_input(true)


func close_inventory() -> void:
	if not is_inventory_open():
		return
	_navigate("/")
	_set_panel_input(false)


func _send_inventory() -> void:
	_send_json(JSON.stringify({"type": "inventory", "data": inventory_view(_money)}))


func _navigate(to: String) -> void:
	_route = to
	_send_json(JSON.stringify({"type": "route", "to": to}))


## Panels take the mouse: the page gets clicks and the cursor is free.
func _set_panel_input(open: bool) -> void:
	if _browser == null or not is_instance_valid(_browser):
		return
	_browser.mouse_filter = Control.MOUSE_FILTER_STOP if open else Control.MOUSE_FILTER_IGNORE
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED


## Messages before the page's `ready` are dropped: snapshots, route and panels
## are replayed on `ready`.
func _send_json(json: String) -> void:
	if not _page_ready:
		return
	if _browser != null and is_instance_valid(_browser):
		_browser.call("send_ipc_message", json)
