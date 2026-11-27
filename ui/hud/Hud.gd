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
## The pause menu confirmed Leave to Lobby. Main closes the connection.
signal session_leave_requested
## The pause party panel asked for a party action (create, invite, accept,
## decline, leave, kick). peer_id is 0 for create and leave. Main forwards it.
signal party_action_requested(verb: String, peer_id: int)
## The lobby or pause menu asked to open Settings. Main replies with open_settings.
signal settings_open_requested
## The settings page pressed Back.
signal settings_close_requested
## The settings page asked to apply a patch. Main answers with send_reply(request_id, ...).
signal settings_apply_requested(request_id: int, revision: int, patch: Dictionary)
## The settings page asked to capture one input for binding `key`. Main replies with send_reply(request_id, ...).
signal settings_capture_requested(request_id: int, key: String)
## The settings page cancelled a running capture.
signal settings_capture_cancel_requested

const PARTY_VERBS_WITH_TARGET := {
	"party.invite": ["invite", "targetPeerId"],
	"party.kick": ["kick", "targetPeerId"],
	"party.accept": ["accept", "inviterPeerId"],
	"party.decline": ["decline", "inviterPeerId"],
}


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


static func push_notification(list: Array, text: String, now_ms: int, lifetime_ms: int = GameConst.HUD_NOTIFICATION_MS) -> Array:
	var result: Array = list.duplicate()
	result.append({"text": text, "expires_ms": now_ms + lifetime_ms})
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
	# ponytail: prompt keys come from the prompt strings ("E ..."); they follow
	# the bindings in the HUD refine card.
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


## PartyPeer for the pause party panel.
static func party_peer(peer_id: int, self_id: int, leader_id: int) -> Dictionary:
	return {
		"peerId": peer_id,
		"name": player_name(peer_id),
		"leader": peer_id == leader_id,
		"isSelf": peer_id == self_id,
		"presence": "in_session",
		"canKick": self_id == leader_id and peer_id != self_id,
	}


## PartyView for the pause menu. `invite` is {inviter, expires_ms} or empty;
## `pending` is the last requested verb or "".
static func party_view(
	self_id: int,
	members: Array,
	leader_id: int,
	roster: Array,
	invite: Dictionary,
	pending: String,
	now_ms: int
) -> Dictionary:
	var in_party := not members.is_empty()
	var member_ids: Array[int] = []
	if in_party:
		member_ids.append(self_id)
	for member: Variant in members:
		if not member_ids.has(int(member)):
			member_ids.append(int(member))
	var can_invite := member_ids.size() < GameConst.PARTY_MAX_MEMBERS
	var peers: Array = []
	for member_id: int in member_ids:
		peers.append(party_peer(member_id, self_id, leader_id))
	var players: Array = []
	for peer: Variant in roster:
		var peer_id := int(peer)
		if peer_id == self_id or member_ids.has(peer_id):
			continue
		players.append({"peerId": peer_id, "name": player_name(peer_id), "canInvite": can_invite})
	var incoming: Variant = null
	if not invite.is_empty() and int(invite.get("expires_ms", 0)) > now_ms:
		var inviter := int(invite.get("inviter", 0))
		incoming = {
			"inviterPeerId": inviter,
			"name": player_name(inviter),
			"expiresInSeconds": seconds_left(int(invite.get("expires_ms", 0)), now_ms),
			# ponytail: the server still checks role and life on accept and replies with notifications.
			"canAccept": not in_party,
		}
	return {
		"members": peers,
		"players": players,
		"incoming": incoming,
		"canCreate": not in_party,
		"canInvite": can_invite,
		"canLeave": in_party,
		"pending": null if pending == "" else pending,
		# ponytail: outcomes arrive as notifications; no issue projection yet.
		"issue": null,
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
		"activeSlot": int(ctx.get("active_slot", 0)),
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
	if method == "pause.resume":
		return _ok_reply(id, {}, ["pause_resume"])
	if method == "session.leave":
		# ponytail: the contract's busy / not_available errors are deferred.
		return _ok_reply(id, {}, ["session_leave"])
	if method == "party.create":
		return _ok_reply(id, {}, ["party", "create", 0])
	if method == "party.leave":
		return _ok_reply(id, {}, ["party", "leave", 0])
	if PARTY_VERBS_WITH_TARGET.has(method):
		var spec: Array = PARTY_VERBS_WITH_TARGET[method]
		var raw: Variant = params.get(spec[1])
		var peer_id := int(raw) if (raw is int or raw is float) else 0
		if peer_id <= 0:
			return _error_reply(id, "bad_params")
		return _ok_reply(id, {}, ["party", spec[0], peer_id])
	if method == "settings.open":
		return _ok_reply(id, {}, ["settings_open"])
	if method == "settings.tab":
		var tab: Variant = params.get("tab")
		if not tab is String or not GameConst.SETTINGS_TABS.has(tab):
			return _error_reply(id, "bad_params")
		return _ok_reply(id, {}, ["settings_tab", tab])
	if method == "settings.close":
		return _ok_reply(id, {}, ["settings_close"])
	if method == "settings.apply":
		var revision: Variant = params.get("revision")
		var patch: Variant = params.get("patch")
		var int_like: bool = revision is int or (revision is float and is_finite(revision) and revision == floorf(revision))
		if not int_like or not patch is Dictionary:
			return _error_reply(id, "bad_params")
		# Main computes the reply and sends it with send_reply.
		return {"reply": null, "action": ["settings_apply", id, int(revision), patch]}
	if method == "settings.capture":
		var key: Variant = params.get("key")
		if not key is String:
			return _error_reply(id, "bad_params")
		# Main captures the input and sends the reply with send_reply.
		return {"reply": null, "action": ["settings_capture", id, key]}
	if method == "settings.capture_cancel":
		return _ok_reply(id, {}, ["settings_capture_cancel"])
	if method in ["settings.display_confirm"]:
		# ponytail: display preview comes in a later card.
		return _error_reply(id, "not_available")
	return _error_reply(id, "unknown_method")


var _player: Node3D = null
var _money: Dictionary = {}
var _mask_end_ms: int = 0
var _notifications: Array = []
## Notification lifetime; set from the notifications_duration setting (Main).
var notification_ms: int = GameConst.HUD_NOTIFICATION_MS
var _instance: GameInstance = null
var _party_members: Array[int] = []
var _party_leader: int = 0
var _fps: int = 0
var _ping: int = 0
var _roster: Array[int] = []
## {inviter, expires_ms} in ticks ms; empty when there is no invite.
var _invite: Dictionary = {}
var _party_pending: String = ""
var _party_pending_ms: int = 0
var _last_party_json: String = ""
## Local active hotbar slot (0-based), shown as HudState.activeSlot.
var _active_slot: int = 0

var _browser: Control = null
var _page_ready: bool = false
var _last_hud_json: String = ""
var _minimap: Minimap = null
var _search_target: int = 0
var _search_items: Array = []
var _route: String = "/"
var _snapshots: Dictionary = {}
## Route Settings was opened from (/lobby or /pause); "" when closed.
var _settings_origin: String = ""


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
	_notifications = push_notification(_notifications, text, now_ms, notification_ms)


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
	_party_pending = ""


func set_roster(peers: Array) -> void:
	_roster = []
	for peer: Variant in peers:
		_roster.append(int(peer))
	_party_pending = ""


func set_invite(inviter_id: int, ttl_seconds: int, now_ms: int) -> void:
	_invite = {"inviter": inviter_id, "expires_ms": now_ms + ttl_seconds * 1000}
	_party_pending = ""


## Session over (left or disconnected): forget the whole party projection.
func clear_party_session() -> void:
	_party_members = []
	_party_leader = 0
	_roster = []
	_invite = {}
	_party_pending = ""


func set_net(fps: int, ping_ms: int) -> void:
	_fps = fps
	_ping = ping_ms


## Hotbar key: select the local active slot (0-based).
func select_hotbar(slot: int) -> void:
	# ponytail: the server validates the equipped item when items are Resources
	# (Phase 3); firing still uses the pistol.
	_active_slot = clampi(slot, 0, GameConst.HUD_HOTBAR_SLOTS - 1)


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
	ctx["active_slot"] = _active_slot
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
	if self_id > 0:
		_publish_party(self_id, Time.get_ticks_msec())


func _publish_party(self_id: int, ticks_ms: int) -> void:
	if _party_pending != "" and ticks_ms - _party_pending_ms >= GameConst.PARTY_PENDING_TIMEOUT_MS:
		_party_pending = ""
	if not _invite.is_empty() and int(_invite.get("expires_ms", 0)) <= ticks_ms:
		_invite = {}
	var view := party_view(self_id, _party_members, _party_leader, _roster, _invite, _party_pending, ticks_ms)
	var json := JSON.stringify(view)
	if json != _last_party_json:
		_last_party_json = json
		publish("party", view)


func _on_ipc_message(message: String) -> void:
	var parsed: Variant = JSON.parse_string(message)
	if not parsed is Dictionary:
		return
	var type := String((parsed as Dictionary).get("type", ""))
	if type == "ready":
		_page_ready = true
		_last_hud_json = ""
		_last_party_json = ""
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
		if routed["reply"] != null:
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
		elif action.size() == 1 and action[0] == "pause_resume":
			close_pause()
		elif action.size() == 1 and action[0] == "session_leave":
			session_leave_requested.emit()
		elif action.size() == 3 and action[0] == "party":
			var verb := String(action[1])
			_party_pending = verb
			_party_pending_ms = Time.get_ticks_msec()
			if verb == "decline":
				_invite = {}
			party_action_requested.emit(verb, int(action[2]))
		elif action.size() == 1 and action[0] == "settings_open":
			settings_open_requested.emit()
		elif action.size() == 2 and action[0] == "settings_tab":
			if is_settings_open():
				_navigate("/settings/%s" % String(action[1]))
		elif action.size() == 1 and action[0] == "settings_close":
			settings_close_requested.emit()
		elif action.size() == 4 and action[0] == "settings_apply":
			settings_apply_requested.emit(int(action[1]), int(action[2]), action[3] as Dictionary)
		elif action.size() == 3 and action[0] == "settings_capture":
			settings_capture_requested.emit(int(action[1]), String(action[2]))
		elif action.size() == 1 and action[0] == "settings_capture_cancel":
			settings_capture_cancel_requested.emit()


## Sends the reply envelope for a request answered later (deferred reply).
func send_reply(id: int, ok: bool, data: Variant, error: String) -> void:
	var reply: Dictionary = {"type": "reply", "id": id, "ok": ok}
	if ok:
		reply["data"] = data
	else:
		reply["error"] = error
		# Error details (e.g. binding_conflict keys) ride along in data.
		if data is Dictionary and not (data as Dictionary).is_empty():
			reply["data"] = data
	_send_json(JSON.stringify(reply))


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


## Shows the lobby route with the current LobbyView. Open search/inventory/pause
## panels are closed locally (no server request: the connection is gone).
func show_lobby(view: Dictionary) -> void:
	if is_search_open():
		close_search(_search_target)
	close_inventory()
	close_pause()
	_active_slot = 0
	# The lobby replaces an open Settings screen (e.g. disconnect while in Settings).
	_settings_origin = ""
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


func is_pause_open() -> bool:
	return _route == "/pause"


## Any route other than the plain HUD: the cursor is free and gameplay keys are off.
func is_panel_open() -> bool:
	return _route != "/"


## Esc from the plain HUD. Ignored over other panels.
func open_pause() -> void:
	if _route != "/":
		return
	_navigate("/pause")
	_set_panel_input(true)


func close_pause() -> void:
	if not is_pause_open():
		return
	_navigate("/")
	_set_panel_input(false)


## Opens Settings on the Graphics tab. Only from the lobby or the pause menu.
func open_settings(view: Dictionary) -> void:
	if _route != "/lobby" and _route != "/pause":
		return
	_settings_origin = _route
	publish("settings", view)
	_navigate("/settings/graphics")
	_set_panel_input(true)


## Back to the route Settings was opened from. Both origins keep panel input.
func close_settings() -> void:
	if not is_settings_open():
		return
	var origin := _settings_origin
	_settings_origin = ""
	_navigate(origin if origin != "" else "/")
	if origin == "":
		_set_panel_input(false)


func is_settings_open() -> bool:
	return _route.begins_with("/settings/")


func push_settings(view: Dictionary) -> void:
	publish("settings", view)


## Esc over an open body search: ask the server to close it (it replies with close).
func request_search_close() -> void:
	if is_search_open():
		search_close_requested.emit(_search_target)


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
