extends Node
## Boot scene. `--server` starts an ENet dedicated server on port 7777 and binds
## the instance root. Without the flag the process becomes a client connecting
## to 127.0.0.1:7777.

const InstanceScript = preload("res://core/Instance.gd")

const MAP_SCENES := {
	"Motel": preload("res://maps/Motel.tscn"),
	"LootyBay": preload("res://maps/LootyBay.tscn"),
	"House": preload("res://maps/House.tscn"),
	"Center": preload("res://maps/Center.tscn"),
}

var _server_mode: bool = false
var _client_view: SubViewportContainer = null
var _peer: ENetMultiplayerPeer = null


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
	var error := peer.create_server(ServerManager.PORT, ServerManager.MAX_CLIENTS)
	if error != OK:
		push_error("Could not create server on port %d (error %d)" % [ServerManager.PORT, error])
		get_tree().quit(1)
		return
	_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.multiplayer_peer = peer
	ServerManager.setup_server($Instances)
	print("[Main] Dedicated server on port %d" % ServerManager.PORT)


func _start_client() -> void:
	_create_client_view_container()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client("127.0.0.1", ServerManager.PORT)
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
	print("[Main] Connecting to 127.0.0.1:%d" % ServerManager.PORT)
	print("[Main] Controls: 1 Motel | 2 LootyBay | 3 House | 4 Center | 5 sell loot | F mask | G cop duty | H surrender | P create party")


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
	if not MAP_SCENES.has(map_name):
		push_error("Main.client_show_instance: unknown map %s" % map_name)
		return
	var instance: GameInstance = InstanceScript.new()
	instance.name = instance_id
	_client_view.add_child(instance)
	var map_scene: PackedScene = MAP_SCENES[map_name]
	instance.setup(
		instance_id,
		map_name,
		GameInstance.Kind.SHARED if (map_name == "House" or map_name == "Center") else GameInstance.Kind.INSTANCED,
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
			ServerManager.request_join_map("Motel")
		KEY_2:
			ServerManager.request_join_map("LootyBay")
		KEY_3:
			ServerManager.request_join_map("House")
		KEY_4:
			ServerManager.request_join_map("Center")
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
		_:
			pass
