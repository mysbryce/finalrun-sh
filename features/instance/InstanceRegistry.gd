class_name InstanceRegistry
extends RefCounted
## Server-owned registry for every map instance, the peer -> instance mapping,
## slot reservations and the empty-instance cleanup timer.
##
## Creation needs the map scene and a spawn function, so ServerManager passes
## both in; this class never imports map scenes or player scenes itself.

const InstanceScript = preload("res://features/instance/Instance.gd")

var instances_root: Node = null

var _instances: Dictionary = {}
var _instance_counters: Dictionary = {}
var _peer_instances: Dictionary = {}
var _spawn_function: Callable = Callable()
var _on_zone_entered: Callable = Callable()
var _on_zone_exited: Callable = Callable()


func configure(
	p_instances_root: Node,
	spawn_function: Callable,
	on_zone_entered: Callable,
	on_zone_exited: Callable
) -> void:
	instances_root = p_instances_root
	set_spawn_function(spawn_function)
	_on_zone_entered = on_zone_entered
	_on_zone_exited = on_zone_exited


## The client configures its spawner without ever calling setup_server.
func set_spawn_function(spawn_function: Callable) -> void:
	_spawn_function = spawn_function


static func is_shared_map(map_name: String) -> bool:
	return GameConst.SHARED_MAPS.has(map_name)


## Shared maps use the map name as id; instanced maps use `Name-NN`.
static func format_instance_id(map_name: String, index: int) -> String:
	if is_shared_map(map_name):
		return map_name
	return "%s-%02d" % [map_name, index]


## Picks the fullest instanced candidate that still fits `party_size` players.
## Candidates are dictionaries: {"id": String, "capacity": int, "used": int}.
## Returns "" when no candidate fits (the caller must create a new instance).
static func select_instance(candidates: Array, party_size: int) -> String:
	if party_size <= 0:
		return ""
	var best_id: String = ""
	var best_used: int = -1
	for candidate: Variant in candidates:
		if not (candidate is Dictionary):
			continue
		var candidate_dict: Dictionary = candidate
		var capacity: int = int(candidate_dict.get("capacity", 0))
		var used: int = int(candidate_dict.get("used", 0))
		if capacity - used < party_size:
			continue
		var candidate_id: String = String(candidate_dict.get("id", ""))
		if candidate_id == "":
			continue
		if used > best_used:
			best_id = candidate_id
			best_used = used
		elif used == best_used and (best_id == "" or candidate_id < best_id):
			best_id = candidate_id
	return best_id


func get_instance(instance_id: String) -> GameInstance:
	return _instances.get(instance_id) as GameInstance


func get_instance_count() -> int:
	return _instances.size()


func get_all_instances() -> Array[GameInstance]:
	var result: Array[GameInstance] = []
	for value: Variant in _instances.values():
		if value is GameInstance:
			result.append(value)
	return result


func get_peer_instance_id(peer_id: int) -> String:
	var value: Variant = _peer_instances.get(peer_id)
	if value == null:
		return ""
	return String(value)


func current_instance_for_peer(peer_id: int) -> GameInstance:
	var instance_id := get_peer_instance_id(peer_id)
	if instance_id == "":
		return null
	return get_instance(instance_id)


func set_peer_instance(peer_id: int, instance_id: String) -> void:
	_peer_instances[peer_id] = instance_id


func clear_peer_instance(peer_id: int) -> void:
	_peer_instances.erase(peer_id)


## Returns the shared instance for a shared map, or an existing instanced
## instance with enough free slots, or a newly created one.
func get_or_create_instance(
	map_name: String,
	party_size: int,
	map_scene: PackedScene
) -> GameInstance:
	if map_scene == null:
		return null
	if is_shared_map(map_name):
		var shared := _find_shared_instance(map_name)
		if shared != null:
			return shared
		return create_instance(map_name, map_scene)
	var candidates: Array = []
	for instance: GameInstance in get_all_instances():
		if instance.map_name != map_name or instance.is_shared():
			continue
		candidates.append({
			"id": instance.instance_id,
			"capacity": instance.capacity,
			"used": instance.used_slots(),
		})
	var selected_id := select_instance(candidates, party_size)
	if selected_id != "":
		return get_instance(selected_id)
	return create_instance(map_name, map_scene)


func create_instance(map_name: String, map_scene: PackedScene) -> GameInstance:
	if map_scene == null:
		return null
	if is_shared_map(map_name):
		var existing := _find_shared_instance(map_name)
		if existing != null:
			return existing
		return _instantiate_instance(map_name, map_name, GameInstance.Kind.SHARED, map_scene)
	var counter: int = int(_instance_counters.get(map_name, 0))
	var instance_id: String = ""
	while true:
		counter += 1
		instance_id = format_instance_id(map_name, counter)
		if not _instances.has(instance_id):
			break
	_instance_counters[map_name] = counter
	return _instantiate_instance(map_name, instance_id, GameInstance.Kind.INSTANCED, map_scene)


func destroy_instance(instance: GameInstance) -> void:
	if instance == null or instance.is_shared():
		return
	if instance.member_count() > 0 or instance.reserved_slots > 0:
		return
	_instances.erase(instance.instance_id)
	instance.queue_free()


## Advances the empty-instance timer and frees instanced maps after the timeout.
func update(delta: float) -> void:
	var now_empty: Array[GameInstance] = []
	for instance: GameInstance in get_all_instances():
		if instance.is_shared():
			continue
		if instance.member_count() == 0 and instance.reserved_slots == 0:
			instance.empty_seconds += delta
			if instance.empty_seconds >= GameConst.EMPTY_INSTANCE_FREE_SECONDS:
				now_empty.append(instance)
		else:
			instance.empty_seconds = 0.0
	for instance: GameInstance in now_empty:
		destroy_instance(instance)


## Holds one slot for an in-flight transfer. Returns false when the instance is
## full; the transfer service then aborts before detaching the player.
func reserve_slot(instance: GameInstance) -> bool:
	if instance == null:
		return false
	if not instance.is_shared() and instance.free_slots() < 1:
		return false
	instance.reserved_slots += 1
	return true


func release_slot(instance: GameInstance) -> void:
	if instance != null:
		instance.reserved_slots = maxi(instance.reserved_slots - 1, 0)


## Assigns the custom spawn function to an instance's spawner.
func configure_spawner(spawner: MultiplayerSpawner) -> void:
	if spawner != null and _spawn_function.is_valid():
		spawner.spawn_function = _spawn_function


## Spawns the peer through the instance spawner, then refreshes visibility.
func spawn_player(peer_id: int, instance: GameInstance) -> void:
	if instance == null or instance.spawner == null:
		return
	# The custom spawn payload is replicated to visible peers, so only send the
	# routing ids. Private inventory state stays on the server.
	var data := {
		"peer_id": peer_id,
		"instance_id": instance.instance_id,
	}
	var spawned: Variant = instance.spawner.spawn(data)
	var player: Node = null
	if spawned is Node:
		player = spawned as Node
	else:
		player = instance.get_player(peer_id)
	if player == null:
		push_error("InstanceRegistry: failed to spawn player %d in %s" % [peer_id, instance.instance_id])
		return
	instance.refresh_visibility()


func despawn_player(instance: GameInstance, player: Node) -> void:
	if instance == null or player == null:
		return
	if instance.spawner != null and instance.spawner.has_method("despawn"):
		instance.spawner.despawn(player)
		return
	# Remove from the tree immediately so get_players()/duty counts and spawn
	# indices no longer include the departing node; visibility was revoked
	# before this call so remote peers already despawned their copy.
	var parent := player.get_parent()
	if parent != null:
		parent.remove_child(player)
	player.queue_free()


## Revokes synchronizer visibility in both directions before despawn.
func revoke_visibility(player: Node, instance: GameInstance, peer_id: int) -> void:
	if instance == null or player == null:
		return
	NetUtil.revoke_visibility(player, instance.members, instance.get_players(), peer_id)


## Removes a peer from its instance and the registry mapping. Returns the old
## instance so the caller can refresh role-dependent state such as the police
## vehicle.
func detach_peer(peer_id: int) -> GameInstance:
	var instance := current_instance_for_peer(peer_id)
	if instance == null:
		clear_peer_instance(peer_id)
		return null
	var player := instance.get_player(peer_id)
	if player != null:
		revoke_visibility(player, instance, peer_id)
		despawn_player(instance, player)
	instance.remove_member(peer_id)
	instance.refresh_visibility()
	clear_peer_instance(peer_id)
	return instance


func _find_shared_instance(map_name: String) -> GameInstance:
	for instance: GameInstance in get_all_instances():
		if instance.map_name == map_name and instance.is_shared():
			return instance
	return null


func _instantiate_instance(
	map_name: String,
	instance_id: String,
	instance_kind: int,
	map_scene: PackedScene
) -> GameInstance:
	if instances_root == null:
		push_error("InstanceRegistry: instances root is not bound")
		return null
	var instance: GameInstance = InstanceScript.new()
	instance.name = instance_id
	instances_root.add_child(instance)
	instance.setup(
		instance_id,
		map_name,
		instance_kind,
		int(GameConst.MAP_CAPACITY.get(map_name, GameConst.DEFAULT_MAP_CAPACITY)),
		bool(GameConst.MAP_SAFEZONE.get(map_name, false)),
		map_scene,
		true
	)
	configure_spawner(instance.spawner)
	if _on_zone_entered.is_valid():
		instance.zone_entered.connect(_on_zone_entered.bind(instance))
	if _on_zone_exited.is_valid():
		instance.zone_exited.connect(_on_zone_exited.bind(instance))
	_instances[instance_id] = instance
	print("[ServerManager] Created instance %s" % instance_id)
	return instance
