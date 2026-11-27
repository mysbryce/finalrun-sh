class_name PlayerService
extends RefCounted
## Server-side player lifecycle and action rules: connection state, spawning,
## transfers, zones, combat, surrender, death and extraction.
##
## ServerManager validates the RPC sender and calls this service; the service
## owns the player state map and the instance-side role checks. The host node
## supplies `_notify`, `is_server_running` and its `multiplayer` API.

const PlayerScene = preload("res://features/player/Player.tscn")
const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")

var _host: Node = null
var _instances: InstanceRegistry = null
var _transfers: TransferService = null
var _parties: PartyService = null
var _states: Dictionary = {}


func configure(
	host: Node,
	instances: InstanceRegistry,
	transfers: TransferService,
	parties: PartyService
) -> void:
	_host = host
	_instances = instances
	_transfers = transfers
	_parties = parties


func is_peer_known(peer_id: int) -> bool:
	return _states.has(peer_id)


# --- Connection lifecycle ----------------------------------------------------

func handle_peer_joined(peer_id: int) -> void:
	if not bool(_host.call("is_server_running")) or not _host.multiplayer.is_server():
		return
	if peer_id <= 0 or _states.has(peer_id):
		return
	_states[peer_id] = RoleControllerScript.default_player_state()
	_notify(peer_id, "Connected to %s" % String(_host.get("server_id")))
	if not _transfers.transfer_to_motel(peer_id):
		push_error("ServerManager: could not start initial transfer for peer %d" % peer_id)


func handle_peer_left(peer_id: int) -> void:
	if peer_id <= 0:
		return
	_transfers.cleanup_transfer(peer_id)
	var instance := _instances.detach_peer(peer_id)
	if instance != null:
		_refresh_police_vehicle(instance)
	_states.erase(peer_id)
	_parties.remove_peer(peer_id)


## TransferService callback: snapshot the role state, then despawn and detach
## the player from the old instance before the destination is reserved.
func prepare_transfer_leave(peer_id: int) -> void:
	var old_instance := _instances.current_instance_for_peer(peer_id)
	if old_instance == null:
		_instances.clear_peer_instance(peer_id)
		return
	var old_player := old_instance.get_player(peer_id)
	if old_player != null:
		var controller := _controller_for(old_player)
		if controller != null:
			controller.server_prepare_leave_instance()
			_states[peer_id] = controller.export_state()
	_instances.detach_peer(peer_id)
	_refresh_police_vehicle(old_instance)


func disconnect_peer(peer_id: int) -> void:
	var peer := _host.multiplayer.multiplayer_peer
	if peer != null and peer.has_method("disconnect_peer"):
		peer.call("disconnect_peer", peer_id)
	else:
		handle_peer_left(peer_id)


# --- Spawning ----------------------------------------------------------------

## Assigned as `spawn_function` on every instance spawner on both sides. Godot
## calls it on all peers that receive the custom spawn.
func spawn_node(data: Variant) -> Node:
	if not (data is Dictionary):
		return null
	var spawn_data: Dictionary = data
	var instance_id := String(spawn_data.get("instance_id", ""))
	var peer_id: int = int(spawn_data.get("peer_id", 0))
	if peer_id <= 0:
		return null
	var player := PlayerScene.instantiate()
	player.name = str(peer_id)
	player.set("peer_id", peer_id)
	if _host.multiplayer.is_server():
		var instance := _instances.get_instance(instance_id)
		if instance == null:
			return null
		var state: Variant = _states.get(peer_id)
		if state == null:
			state = RoleControllerScript.default_player_state()
		player.call("setup_server", instance, state)
	else:
		var client_instance := _find_client_instance(instance_id)
		if client_instance != null:
			player.call("setup_client", client_instance)
		print("[ServerManager] Client spawned player %d in %s" % [peer_id, instance_id])
	return player


func _find_client_instance(instance_id: String) -> Node:
	var scene := _host.get_tree().current_scene
	if scene == null:
		return null
	var holder := scene.get_node_or_null("Instances")
	if holder == null:
		return null
	return holder.get_node_or_null(instance_id)


# --- Actions -----------------------------------------------------------------

func sell_loot(peer_id: int) -> void:
	var instance := _instances.current_instance_for_peer(peer_id)
	if instance == null or instance.map_name != GameConst.MAP_CENTER:
		_notify(peer_id, "Sell loot at the Center market")
		return
	var player := _get_player(peer_id)
	if player == null:
		return
	var controller := player.get_role_controller()
	if controller == null:
		return
	var earned: int = controller.server_sell_loot()
	if earned <= 0:
		_notify(peer_id, "Loot bag is empty")
	else:
		_notify(peer_id, "Sold loot for $%d (notoriety reset)" % earned)


func mask(peer_id: int) -> void:
	var player := _get_player(peer_id)
	if player == null:
		return
	var controller := player.get_role_controller()
	if controller == null:
		return
	if controller.server_try_mask():
		_notify(peer_id, "Masking... hold still for 3 seconds")
	else:
		_notify(peer_id, "Cannot mask here (need LootyBay + CITIZEN)")


func cop_duty(peer_id: int) -> void:
	var player := _get_player(peer_id)
	if player == null:
		return
	var controller := player.get_role_controller()
	if controller == null:
		return
	var instance := _instances.current_instance_for_peer(peer_id)
	if instance == null or instance.map_name != GameConst.MAP_LOOTY_BAY:
		_notify(peer_id, "Cop duty is only available in LootyBay")
		return
	if controller.role == RoleControllerScript.Role.COP:
		if controller.server_go_off_duty():
			_refresh_police_vehicle(instance)
			_notify(peer_id, "Off duty")
		else:
			_notify(peer_id, "Go off duty inside the Police Station")
		return
	if controller.server_go_on_duty():
		_refresh_police_vehicle(instance)
		_notify(peer_id, "On duty: cop loadout issued")
	else:
		_notify(peer_id, "Go on duty inside the Police Station as a CITIZEN")


## Server-authoritative hit detection. The target is resolved only inside the
## sender's own instance; the raycast runs in that instance's World3D.
func attack(peer_id: int, target_peer_id: int) -> void:
	if _transfers.has_transfer(peer_id):
		return
	var instance := _instances.current_instance_for_peer(peer_id)
	if instance == null or instance.map_name != GameConst.MAP_LOOTY_BAY:
		return
	var attacker := instance.get_player(peer_id) as PlayerCharacter
	var target := instance.get_player(target_peer_id) as PlayerCharacter
	if attacker == null or target == null or attacker == target:
		return
	if _instances.get_peer_instance_id(target_peer_id) != instance.instance_id:
		return
	var attacker_controller := attacker.get_role_controller()
	if attacker_controller == null or not attacker_controller.can_attack(target):
		return
	if attacker.global_position.distance_to(target.global_position) > GameConst.ATTACK_RANGE:
		return
	if not _has_line_of_sight(instance, attacker, target):
		return
	target.take_damage(GameConst.ATTACK_DAMAGE)


func surrender(peer_id: int) -> void:
	if _transfers.has_transfer(peer_id):
		return
	var player := _get_player(peer_id)
	if player == null:
		return
	var instance := _instances.current_instance_for_peer(peer_id)
	if instance == null or instance.map_name != GameConst.MAP_LOOTY_BAY:
		_notify(peer_id, "Only criminals inside LootyBay can surrender")
		return
	var controller := player.get_role_controller()
	if controller == null or controller.role != RoleControllerScript.Role.CRIMINAL:
		_notify(peer_id, "Only CRIMINAL players can surrender")
		return
	var cop := _find_surrender_cop(instance, player)
	if cop == null:
		_notify(peer_id, "No COP within %.0f m with line of sight" % GameConst.SURRENDER_RANGE)
		return
	var cop_controller: PlayerRoleController = _controller_for(cop)
	var result: Dictionary = controller.server_apply_surrender(cop_controller)
	if not bool(result.get("ok", false)):
		_notify(peer_id, "Surrender failed")
		return
	_notify(int(cop.get("peer_id")), "Surrender accepted: +$%d reward" % int(result.get("reward", 0)))
	_notify(peer_id, "Surrendered: bag handed over, gear kept")
	if not _transfers.transfer_to_motel(peer_id):
		_notify(peer_id, "Could not transfer to Motel")


func handle_player_death(player: Node) -> void:
	if not bool(_host.call("is_server_running")) or not _host.multiplayer.is_server():
		return
	if player == null or not is_instance_valid(player):
		return
	var peer_id := int(player.get("peer_id"))
	if _transfers.has_transfer(peer_id):
		return
	var instance := _instances.current_instance_for_peer(peer_id)
	if instance == null or instance.get_player(peer_id) != player:
		return
	var controller := _controller_for(player)
	if controller == null:
		return
	var result: Dictionary = controller.server_apply_death()
	if bool(result.get("drops", false)):
		instance.spawn_loot_drop(
			peer_id,
			player.global_position,
			result.get("loot", []),
			result.get("gear", [])
		)
	_states[peer_id] = controller.export_state()
	_refresh_police_vehicle(instance)
	if not _transfers.transfer_to_motel(peer_id):
		_notify(peer_id, "Respawn transfer failed")


# --- Zones -------------------------------------------------------------------

func on_zone_entered(zone_name: String, player: Node, instance: GameInstance) -> void:
	if not bool(_host.call("is_server_running")) or player == null or not is_instance_valid(player):
		return
	var peer_id := int(player.get("peer_id"))
	if _transfers.has_transfer(peer_id):
		return
	if _instances.current_instance_for_peer(peer_id) != instance:
		return
	match zone_name:
		GameConst.ZONE_EXTRACT:
			# Zone signals fire while physics is flushing; defer the transfer so
			# the player node is not removed from the tree mid-step.
			Callable(self, "_handle_extraction").call_deferred(player, instance)
		GameConst.ZONE_POLICE_STATION:
			var controller := _controller_for(player)
			if controller != null:
				controller.set_in_police_station(true)
				_notify(peer_id, "Police Station: press G to go on/off duty")


func on_zone_exited(zone_name: String, player: Node, instance: GameInstance) -> void:
	if not bool(_host.call("is_server_running")) or player == null or not is_instance_valid(player):
		return
	if zone_name == GameConst.ZONE_POLICE_STATION:
		var controller := _controller_for(player)
		if controller != null:
			controller.set_in_police_station(false)
			_notify(int(player.get("peer_id")), "You left the Police Station")


func _handle_extraction(player: Node, instance: GameInstance) -> void:
	if instance == null or instance.map_name != GameConst.MAP_LOOTY_BAY:
		return
	if player == null or not is_instance_valid(player):
		return
	var peer_id := int(player.get("peer_id"))
	if _transfers.has_transfer(peer_id):
		return
	if _instances.current_instance_for_peer(peer_id) != instance:
		return
	var controller := _controller_for(player)
	if controller == null:
		return
	controller.server_on_extraction()
	_states[peer_id] = controller.export_state()
	_refresh_police_vehicle(instance)
	if not _transfers.transfer_to_motel(peer_id):
		_notify(peer_id, "Extraction failed")
		return
	_notify(peer_id, "Extracted from LootyBay")


# --- Helpers -----------------------------------------------------------------

func _get_player(peer_id: int) -> PlayerCharacter:
	var instance := _instances.current_instance_for_peer(peer_id)
	if instance == null:
		return null
	return instance.get_player(peer_id) as PlayerCharacter


func _controller_for(player: Node) -> PlayerRoleController:
	if player == null or not is_instance_valid(player):
		return null
	if player is PlayerCharacter:
		return (player as PlayerCharacter).get_role_controller()
	return player.get_node_or_null("PlayerRoleController") as PlayerRoleController


func _find_surrender_cop(instance: GameInstance, criminal: Node) -> Node:
	var best: Node = null
	var best_distance: float = INF
	for player: Node in instance.get_players():
		if player == criminal:
			continue
		var controller := _controller_for(player)
		if controller == null or controller.role != RoleControllerScript.Role.COP:
			continue
		var distance: float = criminal.global_position.distance_to(player.global_position)
		if distance > GameConst.SURRENDER_RANGE:
			continue
		if not _has_line_of_sight(instance, player, criminal):
			continue
		if distance < best_distance:
			best_distance = distance
			best = player
	return best


func _has_line_of_sight(instance: GameInstance, from_player: Node3D, target_player: Node3D) -> bool:
	# Raycast in the shooter's own instance World3D; instances never share a
	# physics space, so a ray can never cross into another sub-session.
	var world: World3D = from_player.get_world_3d()
	if world == null:
		world = instance.get_world_3d()
	if world == null:
		return false
	var space := world.direct_space_state
	var from: Vector3 = from_player.global_position + Vector3(0.0, GameConst.LINE_OF_SIGHT_EYE_HEIGHT, 0.0)
	var to: Vector3 = target_player.global_position + Vector3(0.0, GameConst.LINE_OF_SIGHT_TARGET_HEIGHT, 0.0)
	var query := PhysicsRayQueryParameters3D.create(
		from,
		to,
		GameConst.RAYCAST_COLLISION_MASK
	)
	var exclude: Array[RID] = [from_player.get_rid()]
	query.exclude = exclude
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return false
	return hit.get("collider") == target_player


func _refresh_police_vehicle(instance: GameInstance) -> void:
	if instance == null:
		return
	var on_duty_count: int = 0
	for player: Node in instance.get_players():
		var controller := _controller_for(player)
		if controller != null and controller.cop_on_duty:
			on_duty_count += 1
	instance.set_police_vehicle_active(on_duty_count > 0)


func _notify(peer_id: int, text: String) -> void:
	_host.call("_notify", peer_id, text)
