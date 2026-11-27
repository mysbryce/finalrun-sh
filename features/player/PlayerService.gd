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
## DownedService hooks, injected as callables so the two services do not form a
## RefCounted reference cycle.
var _life_changed_hook: Callable = Callable()
var _disconnect_hook: Callable = Callable()
var _leaving_hook: Callable = Callable()
var _states: Dictionary = {}
var _death_pending: Dictionary = {}
## Stateful item id counter. `ItemUtils` must stay stateless, so allocation is
## owned here and injected into each spawned role controller.
var _next_item_uid: int = 1
## peer_id -> unix ms of the last accepted shot
var _last_fire_ms: Dictionary = {}


## Allocates a server-wide unique item uid.
func allocate_item_uid() -> int:
	var uid: int = _next_item_uid
	_next_item_uid += 1
	return uid


## Wires the downed service behaviour without holding the service object.
func set_downed_hooks(
	life_changed: Callable,
	disconnected: Callable,
	leaving: Callable
) -> void:
	_life_changed_hook = life_changed
	_disconnect_hook = disconnected
	_leaving_hook = leaving


func now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)


func get_player(peer_id: int) -> PlayerCharacter:
	return _get_player(peer_id)


func get_controller(peer_id: int) -> PlayerRoleController:
	return _controller_for(_get_player(peer_id))


## Party rule for invite/accept: the two sides may not mix COP and CRIMINAL.
func can_party_together(peer_a: int, peer_b: int) -> bool:
	return not parties_role_conflict(_party_roles(peer_a), _party_roles(peer_b))


func current_instance(peer_id: int) -> GameInstance:
	return _instances.current_instance_for_peer(peer_id)


func is_peer_alive(peer_id: int) -> bool:
	var controller := get_controller(peer_id)
	return controller != null and controller.is_alive()


func transfer_to_motel(peer_id: int) -> bool:
	return _transfers.transfer_to_motel(peer_id)


func refresh_police_vehicle(instance: GameInstance) -> void:
	_refresh_police_vehicle(instance)


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
	# Cancel channels and search sessions first so live viewers get the
	# "disconnected" reason before the body or player nodes disappear.
	if _disconnect_hook.is_valid():
		_disconnect_hook.call(peer_id)
	var instance := _instances.current_instance_for_peer(peer_id)
	if instance != null:
		var player := instance.get_player(peer_id)
		var controller := _controller_for(player)
		# A downed body must still drop its remaining loot before despawn.
		if controller != null and controller.is_downed():
			controller.server_set_life_state(
				RoleControllerScript.LifeState.DEAD,
				"disconnect",
				now_ms()
			)
			_resolve_death(player, instance)
	_transfers.cleanup_transfer(peer_id)
	_death_pending.erase(peer_id)
	var detached := _instances.detach_peer(peer_id)
	if detached != null:
		_refresh_police_vehicle(detached)
	_states.erase(peer_id)
	_parties.remove_peer(peer_id)
	_last_fire_ms.erase(peer_id)


## TransferService callback: snapshot the role state, then despawn and detach
## the player from the old instance before the destination is reserved.
func prepare_transfer_leave(peer_id: int) -> void:
	var old_instance := _instances.current_instance_for_peer(peer_id)
	if old_instance == null:
		_instances.clear_peer_instance(peer_id)
		return
	if _leaving_hook.is_valid():
		_leaving_hook.call(peer_id)
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
	var controller := player.get_node_or_null("PlayerRoleController") as PlayerRoleController
	if _host.multiplayer.is_server() and controller != null:
		controller.set_item_uid_allocator(Callable(self, "allocate_item_uid"))
	if _host.multiplayer.is_server():
		var instance := _instances.get_instance(instance_id)
		if instance == null:
			return null
		var state: Variant = _states.get(peer_id)
		if state == null:
			state = RoleControllerScript.default_player_state()
		player.call("setup_server", instance, state)
		if controller != null:
			controller.life_state_changed.connect(_on_player_life_state_changed.bind(player))
			controller.inventory_changed.connect(_on_hud_inventory_changed.bind(peer_id, controller))
			controller.role_changed.connect(_on_hud_role_changed.bind(peer_id, controller))
			controller.mask_channel_started.connect(_on_hud_mask_started.bind(peer_id))
			controller.mask_channel_cancelled.connect(_on_hud_mask_cancelled.bind(peer_id))
			_send_hud_state(peer_id, controller)
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


func move_bag_item(peer_id: int, item_uid: int, slot: int) -> void:
	var player := _get_player(peer_id)
	if player == null:
		return
	var controller := player.get_role_controller()
	if controller == null:
		return
	if not controller.move_bag_item(item_uid, slot):
		_notify(peer_id, "Cannot move that item")


func mask(peer_id: int) -> void:
	var player := _get_player(peer_id)
	if player == null:
		return
	var controller := player.get_role_controller()
	if controller == null:
		return
	if party_role_conflict(_party_roles(peer_id), RoleControllerScript.Role.CRIMINAL):
		_notify(peer_id, "A party cannot mix COP and CRIMINAL (mask rejected)")
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
	if party_role_conflict(_party_roles(peer_id), RoleControllerScript.Role.COP):
		_notify(peer_id, "A party cannot mix COP and CRIMINAL (duty rejected)")
		return
	if controller.server_go_on_duty():
		_refresh_police_vehicle(instance)
		_notify(peer_id, "On duty: cop loadout issued")
	else:
		_notify(peer_id, "Go on duty inside the Police Station as a CITIZEN")


## Server-authoritative hitscan fire. The ray runs in the attacker's own
## World3D and the target must belong to the attacker's instance.
func fire(peer_id: int, aim: Vector3, now_ms: int) -> void:
	if _transfers.has_transfer(peer_id):
		return
	var instance := _instances.current_instance_for_peer(peer_id)
	if instance == null:
		return
	var attacker := instance.get_player(peer_id) as PlayerCharacter
	if attacker == null:
		return
	if not fire_allowed(now_ms, int(_last_fire_ms.get(peer_id, 0)), GameConst.FIRE_INTERVAL_MS):
		return
	_last_fire_ms[peer_id] = now_ms
	if instance.safezone or instance.map_name != GameConst.MAP_LOOTY_BAY:
		_notify(peer_id, "Weapons are locked here")
		return
	var dir := sanitize_aim(aim)
	if dir == Vector3.ZERO:
		return
	var world: World3D = attacker.get_world_3d()
	var space := world.direct_space_state
	var from: Vector3 = attacker.global_position + Vector3(0.0, GameConst.LINE_OF_SIGHT_EYE_HEIGHT, 0.0)
	var to: Vector3 = from + dir * GameConst.ATTACK_RANGE
	var query := PhysicsRayQueryParameters3D.create(
		from,
		to,
		GameConst.RAYCAST_COLLISION_MASK
	)
	var exclude: Array[RID] = [attacker.get_rid()]
	query.exclude = exclude
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return
	var target := hit.get("collider") as PlayerCharacter
	if target == null or instance.get_player(int(target.peer_id)) != target:
		return
	var same_party: bool = false
	var party := _parties.get_party(peer_id)
	if party != null and party.has_member(int(target.peer_id)):
		same_party = true
	var attacker_controller := attacker.get_role_controller()
	if attacker_controller == null:
		return
	if not attacker_controller.can_attack(target, same_party):
		return
	target.take_damage(GameConst.ATTACK_DAMAGE)


## Server-validated loot action on a map Lootable. smash=false is the silent
## lockpick, smash=true is loud and alerts COP and CRIMINAL members.
func loot(peer_id: int, lootable_name: String, smash: bool) -> void:
	if _transfers.has_transfer(peer_id):
		return
	var instance := _instances.current_instance_for_peer(peer_id)
	if instance == null:
		return
	var player := instance.get_player(peer_id) as PlayerCharacter
	if player == null:
		return
	var lootable := Lootable.find_in(instance.map_root, lootable_name)
	if lootable == null:
		return
	if lootable.looted:
		_notify(peer_id, "Already looted")
		return
	if player.global_position.distance_to(lootable.global_position) > GameConst.INTERACT_RANGE:
		_notify(peer_id, "Too far away")
		return
	var controller := player.get_role_controller()
	if controller != null and not controller.can_fit_bag(lootable.loot_id):
		_notify(peer_id, "Bag full")
		return
	var value: int = lootable.value
	var ok: bool = lootable.server_smash(player) if smash else lootable.server_lockpick(player)
	if ok:
		_notify(peer_id, "Looted $%d (%s)" % [value, "loud" if smash else "silent"])
	else:
		_notify(peer_id, "Only an ALIVE CRIMINAL can loot (mask first)")


## True when enough time has passed since the last accepted shot.
static func fire_allowed(now_ms: int, last_fire_ms: int, interval_ms: int) -> bool:
	return now_ms - last_fire_ms >= interval_ms


## Normalized aim, or Vector3.ZERO when the client sent garbage.
static func sanitize_aim(aim: Vector3) -> Vector3:
	if not aim.is_finite() or aim.length_squared() < 0.0001:
		return Vector3.ZERO
	return aim.normalized()


## HUD numbers the owning client may see.
static func hud_state_of(controller: PlayerRoleController) -> Dictionary:
	return {
		"cash": controller.cash,
		"bag_value": controller.loot_value(),
		"notoriety": controller.notoriety,
		"bag_items": controller.loot_bag.duplicate(true),
		"gear": controller.equipped_gear.duplicate(true),
	}


## Pure party role rule: COP and CRIMINAL may not share a party. CITIZEN is
## compatible with either side.
static func party_role_conflict(member_roles: Array, requested_role: int) -> bool:
	if requested_role == RoleControllerScript.Role.CRIMINAL:
		return member_roles.has(RoleControllerScript.Role.COP)
	if requested_role == RoleControllerScript.Role.COP:
		return member_roles.has(RoleControllerScript.Role.CRIMINAL)
	return false


## True when joining two role sets would put a COP and a CRIMINAL together.
static func parties_role_conflict(roles_a: Array, roles_b: Array) -> bool:
	var cop := RoleControllerScript.Role.COP
	var criminal := RoleControllerScript.Role.CRIMINAL
	return (roles_a.has(cop) and roles_b.has(criminal)) or (roles_a.has(criminal) and roles_b.has(cop))


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


## Applies the death outcome and spawns the LootDrop at the body position. No
## transfer: disconnect cleanup resolves the death and then detaches the peer.
func _resolve_death(player: Node, instance: GameInstance) -> void:
	if player == null or not is_instance_valid(player) or instance == null:
		return
	var peer_id := int(player.get("peer_id"))
	var controller := _controller_for(player)
	if controller == null:
		return
	if _death_pending.has(peer_id):
		return
	_death_pending[peer_id] = true
	var result: Dictionary = controller.server_apply_death()
	var loot: Array = result.get("loot", [])
	var gear: Array = result.get("gear", [])
	# A body whose items were all taken while downed produces no empty drop.
	if bool(result.get("drops", false)) and (not loot.is_empty() or not gear.is_empty()):
		instance.spawn_loot_drop(peer_id, player.global_position, loot, gear)
	_states[peer_id] = controller.export_state()
	_refresh_police_vehicle(instance)


func handle_player_death(player: Node) -> void:
	if not bool(_host.call("is_server_running")) or not _host.multiplayer.is_server():
		return
	if player == null or not is_instance_valid(player):
		return
	var peer_id := int(player.get("peer_id"))
	if _transfers.has_transfer(peer_id) or _death_pending.has(peer_id):
		return
	var instance := _instances.current_instance_for_peer(peer_id)
	if instance == null or instance.get_player(peer_id) != player:
		return
	var controller := _controller_for(player)
	if controller == null or not controller.is_dead():
		return
	# Despawn happens in the deferred transfer, never inside the life-state
	# signal handler that led here.
	_resolve_death(player, instance)
	Callable(self, "_transfer_after_death").call_deferred(peer_id)


func _transfer_after_death(peer_id: int) -> void:
	_death_pending.erase(peer_id)
	if not _transfers.transfer_to_motel(peer_id):
		_notify(peer_id, "Respawn transfer failed")


## Called by DownedService after a successful revive. Area overlap does not fire
## a new body_entered when the player was already standing inside the zone.
func run_extraction_if_overlapping(player: Node, instance: GameInstance) -> void:
	if player == null or not is_instance_valid(player) or instance == null:
		return
	var zone := instance.get_zone(GameConst.ZONE_EXTRACT)
	if zone == null:
		return
	if not zone.get_overlapping_bodies().has(player):
		return
	# Keep the normal deferred extraction path so a revive never despawns the
	# player inside the channel/life-state call stack.
	Callable(self, "_handle_extraction").call_deferred(player, instance)


## Life-state signal bridge: the downed service owns channel and search
## cancellation. Death resolution is explicit in the caller so it never runs
## inside this handler.
func _on_player_life_state_changed(
	old_state: int,
	new_state: int,
	cause: String,
	player: Node
) -> void:
	if _life_changed_hook.is_valid():
		_life_changed_hook.call(player, old_state, new_state, cause)


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
	if controller == null or not controller.is_alive():
		# Downed or dead bodies never extract; a revive inside the zone is
		# re-checked by DownedService after the state change.
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
		if not controller.is_alive():
			continue
		var distance: float = criminal.global_position.distance_to(player.global_position)
		if distance > GameConst.SURRENDER_RANGE:
			continue
		if not has_line_of_sight(instance, player, criminal):
			continue
		if distance < best_distance:
			best_distance = distance
			best = player
	return best


## Public static raycast helper shared by combat, surrender and downed actions.
## The ray runs in the shooter's own instance World3D; instances never share a
## physics space, so a ray can never cross into another sub-session.
static func has_line_of_sight(
	instance: GameInstance,
	from_player: Node3D,
	target_player: Node3D
) -> bool:
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


## A CITIZEN holding the mask channel counts as CRIMINAL for party rules.
func _effective_role(controller: PlayerRoleController) -> int:
	if controller.is_mask_channel_active():
		return RoleControllerScript.Role.CRIMINAL
	return controller.role


## Current roles of every party member (including the requester). Members that
## are between instances fall back to their persisted state snapshot.
func _party_roles(peer_id: int) -> Array:
	var party := _parties.get_party(peer_id)
	if party == null:
		var own_controller := get_controller(peer_id)
		if own_controller == null:
			return []
		return [_effective_role(own_controller)]
	var roles: Array = []
	for member: int in party.members:
		var controller := get_controller(member)
		if controller != null:
			roles.append(_effective_role(controller))
			continue
		var state: Variant = _states.get(member)
		if state is Dictionary:
			roles.append(int((state as Dictionary).get("role", RoleControllerScript.Role.CITIZEN)))
	return roles


func _notify(peer_id: int, text: String) -> void:
	_host.call("_notify", peer_id, text)


func _send_hud_state(peer_id: int, controller: PlayerRoleController) -> void:
	if is_instance_valid(controller):
		_host.call("_send_client_rpc", peer_id, "client_hud_state", [hud_state_of(controller)])


func _send_mask_channel(peer_id: int, seconds: float) -> void:
	_host.call("_send_client_rpc", peer_id, "client_mask_channel", [seconds])


func _on_hud_inventory_changed(peer_id: int, controller: PlayerRoleController) -> void:
	_send_hud_state(peer_id, controller)


func _on_hud_role_changed(_old_role: int, _new_role: int, peer_id: int, controller: PlayerRoleController) -> void:
	_send_mask_channel(peer_id, 0.0)
	_send_hud_state(peer_id, controller)


func _on_hud_mask_started(duration_seconds: float, peer_id: int) -> void:
	_send_mask_channel(peer_id, duration_seconds)


func _on_hud_mask_cancelled(_reason: String, peer_id: int) -> void:
	_send_mask_channel(peer_id, 0.0)
