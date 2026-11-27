extends Node
## Boot scene. `--server` starts an ENet dedicated server on port 7777 and binds
## the instance root. Without the flag the process becomes a client connecting
## to 127.0.0.1:7777.

const InstanceScript = preload("res://features/instance/Instance.gd")

var _server_mode: bool = false
var _client_view: SubViewportContainer = null
var _peer: ENetMultiplayerPeer = null
var _search_items: Dictionary = {}
var _last_life_state: int = -1
var _last_bleedout_seconds: int = -1


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
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client("127.0.0.1", GameConst.PORT)
	if error != OK:
		push_error("Could not create client (error %d)" % error)
		get_tree().quit(1)
		return
	_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.multiplayer_peer = peer
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	ServerManager.search_contents_received.connect(_on_search_contents)
	ServerManager.search_closed_received.connect(_on_search_closed)
	print("[Main] Connecting to 127.0.0.1:%d" % GameConst.PORT)
	print(
		"[Main] Controls: 1 Motel | 2 LootyBay | 3 House | 4 Center | 5 sell loot | "
		+ "F mask | G cop duty | H surrender | P create party | R revive | X finish | "
		+ "C cuff | E search | T take | Q close | K attack"
	)


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


func _on_connection_failed() -> void:
	push_error("[Main] Connection failed")
	multiplayer.multiplayer_peer = null


func _on_server_disconnected() -> void:
	print("[Main] Server disconnected")
	multiplayer.multiplayer_peer = null


func _on_viewport_size_changed() -> void:
	if _client_view != null and is_instance_valid(_client_view):
		_client_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# --- Client-side state feedback / action targeting ---------------------------

func _process(_delta: float) -> void:
	if _server_mode:
		return
	var player := _local_player()
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


func _on_search_closed(target_peer_id: int, reason: String) -> void:
	_search_items.erase(target_peer_id)
	print("[Main] Body %d search closed (%s)" % [target_peer_id, reason])


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


func _unhandled_input(event: InputEvent) -> void:
	if _server_mode:
		return
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
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
			var search_target := _target_peer_id()
			if search_target > 0:
				ServerManager.request_search_open(search_target)
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
		KEY_K:
			var attack_target := _target_peer_id()
			if attack_target > 0:
				ServerManager.request_attack(attack_target)
		_:
			pass
