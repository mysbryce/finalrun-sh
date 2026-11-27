extends Node
## Boot scene. `--server` starts an ENet dedicated server on port 7777 and binds
## the instance root. Without the flag the process becomes a client connecting
## to GameConst.DEFAULT_SERVER_HOST:GameConst.PORT (127.0.0.1:7777), or to the
## user arg `--connect host:port` / `--connect=host:port`. With CEF the client
## first runs the splash boot flow (BootFlow) and connects once the page is ready
## and the title dwell is over; without CEF it connects immediately.
## When the server connection drops after boot, the client shows the lobby
## (LobbyState): Play reconnects to the same endpoint, news, Quit.

const InstanceScript = preload("res://features/instance/Instance.gd")

var _server_mode: bool = false
var _client_view: SubViewportContainer = null
var _peer: ENetMultiplayerPeer = null
var _search_items: Dictionary = {}
var _hud: Hud = null
var _last_life_state: int = -1
var _last_bleedout_seconds: int = -1
var _next_net_ms: int = 0
var _endpoint: Dictionary = {}
var _boot: BootFlow = null
var _last_boot_json: String = ""
var _last_boot_phase: String = ""
var _fallback: CanvasLayer = null
var _lobby: LobbyState = null
var _lobby_connect_ms: int = 0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_args()
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	_server_mode = args.has("--server") or user_args.has("--server")
	if _server_mode:
		_start_server()
	else:
		_start_client()


func is_server_mode() -> bool:
	return _server_mode


func _start_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(GameConst.PORT, GameConst.MAX_CLIENTS)
	if error != OK:
		push_error("Could not create server on port %d (error %d)" % [GameConst.PORT, error])
		get_tree().quit(1)
		return
	_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.multiplayer_peer = peer
	ServerManager.setup_server($Instances)
	print("[Main] Dedicated server on port %d" % GameConst.PORT)


func _start_client() -> void:
	_create_client_view_container()
	_hud = Hud.new()
	_hud.name = "Hud"
	add_child(_hud)
	_hud.search_take_requested.connect(ServerManager.request_search_take)
	_hud.search_close_requested.connect(ServerManager.request_search_close)
	_hud.inventory_move_requested.connect(ServerManager.request_move_bag_item)
	_hud.boot_skip_requested.connect(_on_boot_skip)
	_hud.boot_retry_requested.connect(_on_boot_retry)
	_hud.quit_requested.connect(_on_quit)
	_hud.page_ready.connect(_on_page_ready)
	_hud.lobby_join_requested.connect(_on_lobby_join)
	_hud.lobby_news_retry_requested.connect(_on_lobby_news_retry)
	_hud.session_leave_requested.connect(_leave_session)
	_endpoint = BootFlow.parse_endpoint(OS.get_cmdline_user_args())
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	ServerManager.search_contents_received.connect(_on_search_contents)
	ServerManager.search_closed_received.connect(_on_search_closed)
	ServerManager.notification_received.connect(_on_hud_notification)
	ServerManager.hud_state_received.connect(_on_hud_state)
	ServerManager.mask_channel_received.connect(_on_hud_mask_channel)
	ServerManager.party_changed_client.connect(_on_hud_party)
	if not Hud.can_use_browser():
		_connect_to_server()
	else:
		_boot = BootFlow.new()
		_boot.start(Time.get_ticks_msec(), BootFlow.build_id())
		_hud.show_boot(_boot.view())
	print(
		"[Main] Controls: 1 Motel | 2 LootyBay | 3 House | 4 Center | 5 sell loot | "
		+ "F mask | G cop duty | H surrender | P create party | R revive | X finish | "
		+ "C cuff | E lockpick/search | V smash | T take | Q close | LMB fire | Esc pause menu"
	)


## Starts the ENet client for `_endpoint`. During boot a failure goes to BootFlow,
## in the lobby to LobbyState; otherwise it quits as before.
func _connect_to_server() -> void:
	if not bool(_endpoint.get("ok", false)):
		if _boot != null:
			_boot.on_connection_failed("invalid_endpoint")
			return
		if _lobby != null:
			_lobby_failed("invalid_endpoint")
			return
		push_error("Invalid --connect endpoint")
		get_tree().quit(1)
		return
	var host := String(_endpoint.get("host", GameConst.DEFAULT_SERVER_HOST))
	var port := int(_endpoint.get("port", GameConst.PORT))
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(host, port)
	if error != OK:
		if _boot != null:
			_boot.on_connection_failed("connection_failed")
			return
		if _lobby != null:
			_lobby_failed("connection_failed")
			return
		push_error("Could not create client (error %d)" % error)
		get_tree().quit(1)
		return
	_peer = peer
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.multiplayer_peer = peer
	print("[Main] Connecting to %s:%d" % [host, port])


func _on_boot_skip() -> void:
	if _boot == null:
		return
	_boot.skip(Time.get_ticks_msec())


func _on_boot_retry() -> void:
	if _boot == null:
		return
	match _boot.retry(Time.get_ticks_msec()):
		"connect":
			_connect_to_server()
		"reload":
			_hide_native_fallback()
			if _hud != null:
				_hud.reload_page()


## Shows the lobby after the connection dropped. `error` is a ConnectionError or null.
func _show_lobby(error: Variant) -> void:
	if _lobby == null:
		_lobby = LobbyState.new()
		_apply_news(LobbyState.load_news(GameConst.NEWS_PATH))
	_lobby.status = "disconnected" if error == null or error == "disconnected" else "failed"
	_lobby.error = error
	_create_client_view_container()
	_search_items.clear()
	# ponytail: 3D preview viewport when the semi-realistic characters land.
	_hud.show_lobby(_lobby.view())
	print("[Main] Lobby shown")


func _apply_news(news: Dictionary) -> void:
	_lobby.news_status = String(news.get("status", "failed"))
	_lobby.news_entries = news.get("entries", [])


func _publish_lobby() -> void:
	if _lobby != null and _hud != null:
		_hud.show_lobby(_lobby.view())


func _lobby_failed(error: String) -> void:
	_lobby.status = "failed"
	_lobby.error = error
	_publish_lobby()


func _on_lobby_join() -> void:
	if _lobby == null or _lobby.status == "connecting":
		return
	_lobby.status = "connecting"
	_lobby.error = null
	_lobby_connect_ms = Time.get_ticks_msec()
	_publish_lobby()
	_connect_to_server()


func _on_lobby_news_retry() -> void:
	if _lobby == null:
		return
	_apply_news(LobbyState.load_news(GameConst.NEWS_PATH))
	_publish_lobby()


## Lobby connect timeout: give up after BOOT_CONNECT_TIMEOUT_MS.
func _process_lobby() -> void:
	if _lobby.status != "connecting":
		return
	if Time.get_ticks_msec() - _lobby_connect_ms < GameConst.BOOT_CONNECT_TIMEOUT_MS:
		return
	_abort_connect()
	_lobby_failed("connection_timeout")


## Pause -> Leave to Lobby: drop the connection ourselves (the server sees a
## normal disconnect) and show the lobby without an error.
func _leave_session() -> void:
	if _peer == null:
		return
	_peer.close()
	_peer = null
	multiplayer.multiplayer_peer = null
	_search_items.clear()
	_show_lobby(null)


func _on_quit() -> void:
	get_tree().quit()


func _on_page_ready() -> void:
	if _boot == null:
		return
	_boot.on_page_ready(Time.get_ticks_msec())
	_hide_native_fallback()


## Runs BootFlow actions and pushes the BootView to the page when it changed.
func _process_boot() -> void:
	var now := Time.get_ticks_msec()
	match _boot.tick(now):
		"connect":
			_connect_to_server()
		"fail_cef":
			_show_native_fallback()
		"abort_connect":
			_abort_connect()
	if _boot == null:
		return
	if _boot.phase != _last_boot_phase:
		_last_boot_phase = _boot.phase
		if _boot.phase == "failed":
			print("[Main] Boot failed: %s" % String(_boot.error))
	var view := _boot.view()
	var json := JSON.stringify(view)
	if json != _last_boot_json:
		_last_boot_json = json
		_hud.show_boot(view)


func _abort_connect() -> void:
	if _peer != null:
		_peer.close()
	multiplayer.multiplayer_peer = null


## Plain Godot recovery UI shown when the page never sent `ready`.
func _show_native_fallback() -> void:
	if _fallback == null:
		_fallback = CanvasLayer.new()
		_fallback.name = "BootFallback"
		_fallback.layer = GameConst.BOOT_FALLBACK_LAYER
		var background := ColorRect.new()
		background.color = Color.BLACK
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_fallback.add_child(background)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		background.add_child(center)
		var column := VBoxContainer.new()
		center.add_child(column)
		var label := Label.new()
		label.text = "The interface could not load."
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(label)
		var buttons := HBoxContainer.new()
		buttons.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_child(buttons)
		var retry := Button.new()
		retry.text = "Retry"
		retry.pressed.connect(_on_boot_retry)
		buttons.add_child(retry)
		var quit := Button.new()
		quit.text = "Quit"
		quit.pressed.connect(_on_quit)
		buttons.add_child(quit)
		add_child(_fallback)
	_fallback.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _hide_native_fallback() -> void:
	if _fallback != null:
		_fallback.visible = false


func _create_client_view_container() -> void:
	var old_holder := get_node_or_null("Instances")
	if old_holder != null:
		remove_child(old_holder)
		old_holder.queue_free()
	var container := SubViewportContainer.new()
	container.name = "Instances"
	container.stretch = true
	add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_client_view = container


## Called by ServerManager.client_load_instance on this client. Rebuilds the
## local instance at /root/Main/Instances/<instance_id>, then acks the server.
func client_show_instance(instance_id: String, map_name: String) -> void:
	if _server_mode:
		return
	if _client_view == null or not is_instance_valid(_client_view):
		_create_client_view_container()
	for child: Node in _client_view.get_children():
		_client_view.remove_child(child)
		child.queue_free()
	var map_scene: PackedScene = ServerManager.get_map_scene(map_name)
	if map_scene == null:
		push_error("Main.client_show_instance: unknown map %s" % map_name)
		return
	var instance: GameInstance = InstanceScript.new()
	instance.name = instance_id
	_client_view.add_child(instance)
	instance.setup(
		instance_id,
		map_name,
		GameInstance.Kind.SHARED if GameConst.SHARED_MAPS.has(map_name) else GameInstance.Kind.INSTANCED,
		ServerManager.get_map_capacity(map_name),
		ServerManager.is_map_safezone(map_name),
		map_scene,
		false
	)
	ServerManager.configure_spawner(instance.spawner)
	print("[Main] Client loaded instance %s (%s)" % [instance_id, map_name])


func _on_peer_connected(peer_id: int) -> void:
	print("[Main] Peer connected: %d" % peer_id)
	ServerManager.handle_peer_joined(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("[Main] Peer disconnected: %d" % peer_id)
	ServerManager.handle_peer_left(peer_id)


func _on_connected_to_server() -> void:
	print("[Main] Connected to server as peer %d" % multiplayer.get_unique_id())
	if _boot != null:
		_boot.on_connected()
		_hud.end_boot()
		_boot = null
	if _lobby != null:
		_hud.end_lobby()
		_lobby = null


func _on_connection_failed() -> void:
	push_error("[Main] Connection failed")
	multiplayer.multiplayer_peer = null
	if _boot != null:
		_boot.on_connection_failed("connection_failed")
	elif _lobby != null:
		_lobby_failed("connection_failed")


func _on_server_disconnected() -> void:
	print("[Main] Server disconnected")
	multiplayer.multiplayer_peer = null
	# _lobby is already set when the player left on purpose (_leave_session).
	if _boot == null and _hud != null and _lobby == null:
		_show_lobby("disconnected")


func _on_viewport_size_changed() -> void:
	if _client_view != null and is_instance_valid(_client_view):
		_client_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# --- Client-side state feedback / action targeting ---------------------------

func _process(_delta: float) -> void:
	if _server_mode:
		return
	if _boot != null:
		_process_boot()
	if _lobby != null:
		_process_lobby()
	var player := _local_player()
	if _hud != null:
		_hud.set_player(player)
		_hud.set_instance(_current_instance())
		var ticks := Time.get_ticks_msec()
		if ticks >= _next_net_ms:
			_next_net_ms = ticks + 1000
			_hud.set_net(int(Engine.get_frames_per_second()), _client_ping_ms())
	if player == null:
		return
	var state: int = int(player.get("life_state"))
	if state != _last_life_state:
		_last_life_state = state
		print("[Main] Life state: %s" % _life_state_name(state))
	if state == PlayerRoleController.LifeState.DOWNED:
		var client_now: int = int(Time.get_unix_time_from_system() * 1000.0)
		var remaining_ms: int = maxi(0, int(player.get("downed_deadline_ms")) - client_now)
		var seconds: int = int(remaining_ms / 1000)
		if seconds != _last_bleedout_seconds:
			_last_bleedout_seconds = seconds
			print("[Main] Bleed-out: %d s" % seconds)
	else:
		_last_bleedout_seconds = -1


func _on_search_contents(target_peer_id: int, items: Array) -> void:
	_search_items[target_peer_id] = items.duplicate(true)
	print("[Main] Body %d items: %s" % [target_peer_id, str(items)])
	if _hud != null:
		_hud.open_search(target_peer_id, items)


func _on_search_closed(target_peer_id: int, reason: String) -> void:
	_search_items.erase(target_peer_id)
	print("[Main] Body %d search closed (%s)" % [target_peer_id, reason])
	if _hud != null:
		_hud.close_search(target_peer_id)


func _on_hud_notification(text: String) -> void:
	if _hud != null:
		_hud.add_notification(text, _client_now_ms())


func _on_hud_state(state: Dictionary) -> void:
	if _hud != null:
		_hud.set_money(state)


func _on_hud_mask_channel(seconds: float) -> void:
	if _hud != null:
		_hud.set_mask_channel(seconds, _client_now_ms())


func _on_hud_party(info: Dictionary) -> void:
	if _hud != null:
		_hud.set_party(info)


## Round-trip time to the server in ms, 0 when unknown.
func _client_ping_ms() -> int:
	var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if enet == null:
		return 0
	var server := enet.get_peer(1)
	if server == null:
		return 0
	return int(server.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME))


func _client_now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)


func _current_instance() -> GameInstance:
	if _client_view == null or not is_instance_valid(_client_view):
		return null
	for child: Node in _client_view.get_children():
		if child is GameInstance:
			return child as GameInstance
	return null


func _local_player() -> PlayerCharacter:
	var instance := _current_instance()
	if instance == null:
		return null
	return instance.get_player(multiplayer.get_unique_id()) as PlayerCharacter


## Lootable under the nearest InteractArea in reach, or null.
func _nearest_lootable() -> Lootable:
	var area := InteractArea.nearest(_local_player(), GameConst.INTERACT_RANGE)
	if area == null:
		return null
	return area.get_parent() as Lootable


## Every action key targets the nearest other player in the current instance.
func _nearest_other_player() -> PlayerCharacter:
	var instance := _current_instance()
	var local := _local_player()
	if instance == null or local == null:
		return null
	var best: PlayerCharacter = null
	var best_distance: float = INF
	for node: Node in instance.get_players():
		var other := node as PlayerCharacter
		if other == null or other == local:
			continue
		var distance: float = local.global_position.distance_to(other.global_position)
		if distance < best_distance:
			best_distance = distance
			best = other
	return best


func _target_peer_id() -> int:
	var target := _nearest_other_player()
	if target == null:
		print("[Main] No target player in this instance")
		return 0
	return int(target.get("peer_id"))


func _life_state_name(state: int) -> String:
	match state:
		PlayerRoleController.LifeState.DOWNED:
			return "DOWNED"
		PlayerRoleController.LifeState.DEAD:
			return "DEAD"
		_:
			return "ALIVE"


## Esc, first match wins: close inventory, close search (server closes it),
## resume from pause, open pause from the plain HUD in a live session.
func _on_escape() -> void:
	if _hud == null:
		return
	if _hud.is_inventory_open():
		_hud.close_inventory()
	elif _hud.is_search_open():
		_hud.request_search_close()
	elif _hud.is_pause_open():
		_hud.close_pause()
	elif not _hud.is_panel_open() and _is_connected() and _local_player() != null:
		_hud.open_pause()


func _is_connected() -> bool:
	var peer := multiplayer.multiplayer_peer
	return (
		peer != null
		and not peer is OfflineMultiplayerPeer
		and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
	)


func _unhandled_input(event: InputEvent) -> void:
	if _server_mode:
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if _boot != null and (key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER):
		_boot.skip(Time.get_ticks_msec())
		get_viewport().set_input_as_handled()
		return
	if _boot != null or _lobby != null:
		return
	if key_event.physical_keycode == KEY_ESCAPE:
		_on_escape()
		get_viewport().set_input_as_handled()
		return
	if key_event.physical_keycode == KEY_TAB:
		if _hud != null:
			_hud.toggle_inventory()
		return
	# Any open panel (pause, inventory, search) owns the cursor: no gameplay or debug keys.
	if _hud != null and _hud.is_panel_open():
		return
	match key_event.physical_keycode:
		KEY_1:
			ServerManager.request_join_map(GameConst.MAP_MOTEL)
		KEY_2:
			ServerManager.request_join_map(GameConst.MAP_LOOTY_BAY)
		KEY_3:
			ServerManager.request_join_map(GameConst.MAP_HOUSE)
		KEY_4:
			ServerManager.request_join_map(GameConst.MAP_CENTER)
		KEY_5:
			ServerManager.request_sell_loot()
		KEY_F:
			ServerManager.request_mask()
		KEY_G:
			ServerManager.request_cop_duty()
		KEY_H:
			ServerManager.request_surrender()
		KEY_P:
			ServerManager.request_party_create()
		KEY_R:
			var revive_target := _target_peer_id()
			if revive_target > 0:
				ServerManager.request_revive(revive_target)
		KEY_X:
			var finish_target := _target_peer_id()
			if finish_target > 0:
				ServerManager.request_finish(finish_target)
		KEY_C:
			var cuff_target := _target_peer_id()
			if cuff_target > 0:
				ServerManager.request_cuff(cuff_target)
		KEY_E:
			var lootable := _nearest_lootable()
			if lootable != null:
				ServerManager.request_loot(String(lootable.name), false)
			else:
				var search_target := _target_peer_id()
				if search_target > 0:
					ServerManager.request_search_open(search_target)
		KEY_V:
			var smash_target := _nearest_lootable()
			if smash_target != null:
				ServerManager.request_loot(String(smash_target.name), true)
			else:
				print("[Main] Nothing to smash")
		KEY_T:
			var take_target := _target_peer_id()
			if take_target <= 0:
				return
			var items: Array = _search_items.get(take_target, [])
			if items.is_empty():
				print("[Main] No items in the open search")
				return
			var first: Dictionary = items[0]
			ServerManager.request_search_take(take_target, int(first.get("uid", 0)))
		KEY_Q:
			var close_target := _target_peer_id()
			if close_target > 0:
				ServerManager.request_search_close(close_target)
		_:
			pass
