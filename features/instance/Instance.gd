class_name GameInstance
extends SubViewport
## Root of one map instance. Server and client both use this script; every
## instance owns a separate World3D (own_world_3d) so physics, raycasts and
## bullets can never leak between instances.
##
## Server tree:  /root/Main/Instances/<instance_id>       (render disabled)
## Client tree:  /root/Main/Instances/<instance_id>       (inside a
##               SubViewportContainer named "Instances", full rect + stretch)
##
## The node path is intentionally identical on both sides so RPCs and the
## MultiplayerSpawner/MultiplayerSynchronizer node paths resolve everywhere.

signal zone_entered(zone_name: String, player: Node3D)
signal zone_exited(zone_name: String, player: Node3D)

enum Kind {
	INSTANCED,
	SHARED,
}

const PLAYERS_NODE_NAME: String = "Players"
const SPAWNER_NODE_NAME: String = "Spawner"
const DROPS_NODE_NAME: String = "Drops"
const CLIENT_CAMERA_NAME: String = "ClientCamera"
const ZONE_NAMES: Array[String] = GameConst.ZONE_NAMES

const LootDropScript = preload("res://features/heist/LootDrop.gd")

var instance_id: String = ""
var map_name: String = ""
var kind: int = Kind.INSTANCED
var capacity: int = 0
var safezone: bool = false

## Peer ids currently inside this instance. Only the server mutates this.
var members: Array[int] = []
## Slots held by in-flight transfers (server only).
var reserved_slots: int = 0
## Seconds this instanced map has been empty; used for the 60 s cleanup.
var empty_seconds: float = 0.0
## Whether a police vehicle placeholder is currently visible.
var police_vehicle_active: bool = false

var is_server_side: bool = false
var map_root: Node3D = null
var players_root: Node3D = null
var drops_root: Node3D = null
var spawner: MultiplayerSpawner = null

var _drop_counter: int = 0


## Builds the instance content. Must be called after the viewport is in the
## tree so the separate World3D / physics space exists.
func setup(
	p_instance_id: String,
	p_map_name: String,
	p_kind: int,
	p_capacity: int,
	p_safezone: bool,
	p_map_scene: PackedScene,
	p_is_server: bool
) -> void:
	instance_id = p_instance_id
	map_name = p_map_name
	kind = p_kind
	capacity = p_capacity
	safezone = p_safezone
	is_server_side = p_is_server

	name = instance_id
	own_world_3d = true
	disable_3d = false
	if is_server_side:
		# Physics needs the World3D; only rendering is disabled on a dedicated server.
		render_target_update_mode = SubViewport.UPDATE_DISABLED
	else:
		# The client always wraps this viewport in a stretching SubViewportContainer,
		# which owns the render size.
		render_target_update_mode = SubViewport.UPDATE_ALWAYS

	map_root = p_map_scene.instantiate() as Node3D
	if map_root == null:
		push_error("Instance %s: map scene %s has no Node3D root" % [instance_id, map_name])
		return
	map_root.name = "Map"
	add_child(map_root)

	players_root = Node3D.new()
	players_root.name = PLAYERS_NODE_NAME
	add_child(players_root)

	drops_root = Node3D.new()
	drops_root.name = DROPS_NODE_NAME
	add_child(drops_root)

	spawner = MultiplayerSpawner.new()
	spawner.name = SPAWNER_NODE_NAME
	spawner.spawn_path = NodePath("../" + PLAYERS_NODE_NAME)
	spawner.spawn_limit = capacity
	add_child(spawner)

	if is_server_side:
		_connect_zones_server()
	else:
		_install_client_camera()


func is_shared() -> bool:
	return kind == Kind.SHARED


func member_count() -> int:
	return members.size()


func used_slots() -> int:
	return members.size() + reserved_slots


## Number of free slots including in-flight reservations.
func free_slots() -> int:
	return maxi(capacity - used_slots(), 0)


func has_member(peer_id: int) -> bool:
	return members.has(peer_id)


func add_member(peer_id: int) -> bool:
	if peer_id <= 0 or members.has(peer_id):
		return false
	members.append(peer_id)
	return true


func remove_member(peer_id: int) -> bool:
	if not members.has(peer_id):
		return false
	members.erase(peer_id)
	return true


func get_players() -> Array[Node]:
	var result: Array[Node] = []
	if players_root == null:
		return result
	for child: Node in players_root.get_children():
		result.append(child)
	return result


func get_player(peer_id: int) -> Node:
	if players_root == null:
		return null
	for child: Node in players_root.get_children():
		var child_peer: Variant = child.get("peer_id")
		if child_peer != null and int(child_peer) == peer_id:
			return child
	return null


## Marker children of Map/SpawnPoints. Falls back to a sane transform when a map
## has no markers.
func get_spawn_transform(peer_id: int) -> Transform3D:
	var markers: Array[Marker3D] = []
	var points := map_root.get_node_or_null("SpawnPoints") if map_root != null else null
	if points != null:
		for child: Node in points.get_children():
			if child is Marker3D:
				markers.append(child)
	if markers.is_empty():
		return Transform3D(Basis.IDENTITY, Vector3(0.0, 0.2, 0.0))
	var index: int = members.find(peer_id)
	if index < 0:
		index = posmod(peer_id, markers.size())
	return markers[index % markers.size()].global_transform


## Server-only zone lookup used for deferred extraction checks (a revive inside
## ExtractZone does not fire body_entered again).
func get_zone(zone_name: String) -> Area3D:
	if map_root == null:
		return null
	return map_root.get_node_or_null(zone_name) as Area3D


## Sends an RPC only to the given member peers of this instance.
##
## Thin wrapper over `NetUtil.rpc_to_members`; the instance owns the member list
## that decides who may receive the call.
func rpc_to_members(callable_name: StringName, args: Array, only_peers: Array = []) -> void:
	NetUtil.rpc_to_members(self, members, callable_name, args, only_peers)


## Like rpc_to_members but never falls back to "everyone" for an empty peer list.
func rpc_to_specific_members(callable_name: StringName, args: Array, peers: Array) -> void:
	NetUtil.rpc_to_specific_members(self, members, callable_name, args, peers)


## Grants synchronizer visibility to every member of this instance and revokes
## it from every other connected peer. Called on spawn, join, leave and transfer.
func refresh_visibility() -> void:
	if not is_server_side:
		return
	NetUtil.refresh_visibility(get_players(), members)


## Returns the member peer ids whose controller currently has one of `roles`.
func get_member_peers_with_roles(roles: Array) -> Array[int]:
	var result: Array[int] = []
	for peer: int in members:
		var player := get_player(peer)
		if player == null:
			continue
		var controller := player.get_node_or_null("PlayerRoleController")
		if controller == null:
			continue
		var role_value: Variant = controller.get("role")
		if role_value != null and roles.has(int(role_value)):
			result.append(peer)
	return result


## Creates a server-owned loot drop and mirrors a visual placeholder to every
## member of this instance.
func spawn_loot_drop(
	owner_peer: int,
	world_position: Vector3,
	loot_items: Array,
	gear_items: Array
) -> Node:
	if not is_server_side:
		return null
	_drop_counter += 1
	var drop_id := "drop_%d_%d" % [owner_peer, _drop_counter]
	var drop := LootDropScript.new() as Node3D
	drop.name = drop_id
	drop.set("drop_id", drop_id)
	drop.call("setup_server", owner_peer, ItemUtils.duplicate_items(loot_items), ItemUtils.duplicate_items(gear_items))
	drops_root.add_child(drop)
	drop.global_position = world_position
	# Clients receive only the placeholder position; contents stay server-side.
	rpc_to_members("client_add_loot_drop", [drop_id, world_position])
	return drop


## Sends the current world state of this instance (police vehicle, dropped loot)
## to a peer that just joined. Visibility is not enough to replay older events.
func sync_state_to_peer(peer_id: int) -> void:
	if not is_server_side or not members.has(peer_id):
		return
	var peers: Array = [peer_id]
	rpc_to_specific_members("client_set_police_vehicle", [police_vehicle_active], peers)
	if map_root != null:
		var lootables := map_root.get_node_or_null("Lootables")
		if lootables != null:
			for child: Node in lootables.get_children():
				var lootable := child as Lootable
				if lootable != null and lootable.looted:
					rpc_to_specific_members("client_lootable_looted", [String(child.name)], peers)
	if drops_root == null:
		return
	for drop: Node in drops_root.get_children():
		rpc_to_specific_members(
			"client_add_loot_drop",
			[String(drop.name), (drop as Node3D).global_position],
			peers
		)


## Updates the shared police vehicle placeholder (one per LootyBay instance).
func set_police_vehicle_active(active: bool) -> void:
	if police_vehicle_active == active:
		return
	police_vehicle_active = active
	_apply_police_vehicle_local(active)
	rpc_to_members("client_set_police_vehicle", [active])


# --- Client-bound RPCs -------------------------------------------------------

@rpc("authority", "call_remote", "reliable")
func client_set_police_vehicle(active: bool) -> void:
	police_vehicle_active = active
	_apply_police_vehicle_local(active)


@rpc("authority", "call_remote", "reliable")
func client_lootable_looted(lootable_name: String) -> void:
	var lootable := Lootable.find_in(map_root, lootable_name)
	if lootable != null:
		lootable.mark_looted()


@rpc("authority", "call_remote", "reliable")
func client_loot_alert(world_position: Vector3, loot_id: String, loud: bool) -> void:
	# Placeholder feedback: a real client would raise an alarm marker / sound.
	if loud:
		print("[LootyBay] Loud alert at %s (loot: %s)" % [world_position, loot_id])


@rpc("authority", "call_remote", "reliable")
func client_add_loot_drop(drop_id: String, world_position: Vector3) -> void:
	if drops_root == null or drops_root.has_node(drop_id):
		return
	var drop := LootDropScript.new() as Node3D
	drop.name = drop_id
	drop.call("setup_client", drop_id)
	drops_root.add_child(drop)
	drop.global_position = world_position


@rpc("authority", "call_remote", "reliable")
func client_remove_loot_drop(drop_id: String) -> void:
	var drop := drops_root.get_node_or_null(drop_id) if drops_root != null else null
	if drop != null:
		drop.queue_free()


# --- Internal ----------------------------------------------------------------

func _connect_zones_server() -> void:
	if map_root == null:
		return
	for zone_name: String in ZONE_NAMES:
		var zone := map_root.get_node_or_null(zone_name) as Area3D
		if zone == null:
			continue
		zone.body_entered.connect(_on_zone_body_entered.bind(zone_name))
		zone.body_exited.connect(_on_zone_body_exited.bind(zone_name))


func _on_zone_body_entered(body: Node3D, zone_name: String) -> void:
	if players_root == null or body == null or not players_root.is_ancestor_of(body):
		return
	zone_entered.emit(zone_name, body)


func _on_zone_body_exited(body: Node3D, zone_name: String) -> void:
	if players_root == null or body == null or not players_root.is_ancestor_of(body):
		return
	zone_exited.emit(zone_name, body)


func _install_client_camera() -> void:
	var camera := Camera3D.new()
	camera.name = CLIENT_CAMERA_NAME
	camera.position = Vector3(0.0, 14.0, 18.0)
	camera.rotation_degrees = Vector3(-32.0, 0.0, 0.0)
	camera.current = true
	add_child(camera)


func _apply_police_vehicle_local(active: bool) -> void:
	if map_root == null:
		return
	var vehicle := map_root.get_node_or_null("PoliceVehicle") as Node3D
	if vehicle != null:
		vehicle.visible = active
