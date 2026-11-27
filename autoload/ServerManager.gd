extends Node
## Dedicated-server brain and client-side network facade.
##
## Server responsibilities:
##  - server id + instance registry (create/destroy, shared maps, 60 s cleanup)
##  - party registry (max 3) and party-wide LootyBay entry
##  - validated map transfers with a client instance-load acknowledgement
##  - zone handling: extraction, police station, death and surrender
##
## Client responsibilities:
##  - build/free the local instance SubViewport on request
##  - forward player requests to peer 1
##
## Every gameplay request handler validates multiplayer.get_remote_sender_id().
## Gameplay events are never broadcast; instances use rpc_to_members().

signal notification_received(text: String)
signal party_invite_received(inviter_id: int)
signal party_changed_client(party_info: Dictionary)

const PartyScript = preload("res://core/Party.gd")
const InstanceScript = preload("res://core/Instance.gd")
const PlayerScene = preload("res://player/Player.tscn")
const RoleControllerScript = preload("res://player/PlayerRoleController.gd")

const MAP_SCENES := {
	"Motel": preload("res://maps/Motel.tscn"),
	"LootyBay": preload("res://maps/LootyBay.tscn"),
	"House": preload("res://maps/House.tscn"),
	"Center": preload("res://maps/Center.tscn"),
}

const PORT: int = 7777
const MAX_CLIENTS: int = 64
const EMPTY_INSTANCE_FREE_SECONDS: float = 60.0
const TRANSFER_TIMEOUT_SECONDS: float = 10.0
const SURRENDER_RANGE: float = 6.0
const ATTACK_RANGE: float = 40.0
const ATTACK_DAMAGE: int = 25

const MAP_CAPACITY := {
	"Motel": 16,
	"LootyBay": 12,
	"House": MAX_CLIENTS,
	"Center": MAX_CLIENTS,
}

const MAP_SAFEZONE := {
	"Motel": true,
	"LootyBay": false,
	"House": false,
	"Center": false,
}

const INSTANCED_MAPS: Array[String] = ["Motel", "LootyBay"]
const SHARED_MAPS: Array[String] = ["House", "Center"]

## Only these routes are allowed through the map request API. LootyBay is a
## one-way exit: extraction, death or surrender only.
const ALLOWED_ROUTES := {
	"Motel": ["LootyBay", "House", "Center"],
	"House": ["Motel", "Center"],
	"Center": ["Motel", "House"],
	"LootyBay": [],
}

var server_id: String = ""
var instances_root: Node = null

var _running: bool = false
var _instances: Dictionary = {}
var _instance_counters: Dictionary = {}
var _parties: Dictionary = {}
var _peer_party: Dictionary = {}
var _peer_instances: Dictionary = {}
var _player_states: Dictionary = {}
var _transfers: Dictionary = {}
var _pending_invites: Dictionary = {}
var _next_party_id: int = 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)


# ============================================================================
# Pure static helpers (unit-testable without a SceneTree or network)
# ============================================================================

static func format_server_id(number: int) -> String:
	return "SV-SPACE-%04d" % posmod(number, 10000)


static func generate_server_id() -> String:
	return format_server_id(randi_range(0, 9999))


static func is_valid_server_id(candidate: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^SV-SPACE-[0-9]{4}$")
	return regex.search(candidate) != null


static func is_shared_map(map_name: String) -> bool:
	return SHARED_MAPS.has(map_name)


static func map_exists(map_name: String) -> bool:
	return MAP_SCENES.has(map_name)


static func format_instance_id(map_name: String, index: int) -> String:
	if is_shared_map(map_name):
		return map_name
	return "%s-%02d" % [map_name, index]


static func is_route_allowed(from_map: String, to_map: String) -> bool:
	if from_map == to_map:
		return false
	var routes: Array = ALLOWED_ROUTES.get(from_map, [])
	return routes.has(to_map)


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


# ============================================================================
# Server lifecycle
# ============================================================================

func setup_server(p_instances_root: Node) -> void:
	if _running:
		return
	if p_instances_root == null:
		push_error("ServerManager.setup_server: instances root is null")
		return
	instances_root = p_instances_root
	_running = true
	server_id = generate_server_id()
	_create_instance("House")
	_create_instance("Center")
	print("[ServerManager] Server %s booted (port %d)" % [server_id, PORT])


func is_server_running() -> bool:
	return _running


func get_server_id() -> String:
	return server_id


func get_instance(instance_id: String) -> GameInstance:
	return _instances.get(instance_id) as GameInstance


func get_instance_count() -> int:
	return _instances.size()


func get_peer_instance_id(peer_id: int) -> String:
	var value: Variant = _peer_instances.get(peer_id)
	if value == null:
		return ""
	return String(value)


func get_party(peer_id: int) -> Party:
	var party_id: Variant = _peer_party.get(peer_id)
	if party_id == null:
		return null
	return _parties.get(int(party_id)) as Party


func get_all_instances() -> Array[GameInstance]:
	var result: Array[GameInstance] = []
	for value: Variant in _instances.values():
		if value is GameInstance:
			result.append(value)
	return result


func get_map_capacity(map_name: String) -> int:
	return int(MAP_CAPACITY.get(map_name, 16))


func is_map_safezone(map_name: String) -> bool:
	return bool(MAP_SAFEZONE.get(map_name, false))


# ============================================================================
# Server request entry points (client -> server RPCs)
# ============================================================================

@rpc("any_peer", "call_remote", "reliable")
func server_request_join_map(map_name: String) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _can_accept_request(sender):
		return
	_handle_join_map(sender, map_name)


@rpc("any_peer", "call_remote", "reliable")
func server_request_party_create() -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _can_accept_request(sender):
		return
	var party := _create_party(sender)
	if party == null:
		return
	_notify(sender, "Party created (leader)")
	_send_party_state(party)


@rpc("any_peer", "call_remote", "reliable")
func server_request_party_invite(target_peer_id: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _can_accept_request(sender):
		return
	if not _invite_to_party(sender, target_peer_id):
		_notify(sender, "Cannot invite that player")


@rpc("any_peer", "call_remote", "reliable")
func server_request_party_accept(inviter_peer_id: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _can_accept_request(sender):
		return
	if not _accept_party_invite(sender, inviter_peer_id):
		_notify(sender, "Invite is no longer valid")


@rpc("any_peer", "call_remote", "reliable")
func server_request_party_leave() -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _can_accept_request(sender):
		return
	leave_party(sender)
	_notify(sender, "You left the party")


@rpc("any_peer", "call_remote", "reliable")
func server_request_party_kick(target_peer_id: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _can_accept_request(sender):
		return
	if not kick_from_party(sender, target_peer_id):
		_notify(sender, "Cannot kick that player")


@rpc("any_peer", "call_remote", "reliable")
func server_request_sell_loot() -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _can_accept_request(sender):
		return
	var instance := _current_instance_for_peer(sender)
	if instance == null or instance.map_name != "Center":
		_notify(sender, "Sell loot at the Center market")
		return
	var player := _get_player(sender)
	if player == null:
		return
	var controller := player.get_role_controller()
	if controller == null:
		return
	var earned: int = controller.server_sell_loot()
	if earned <= 0:
		_notify(sender, "Loot bag is empty")
	else:
		_notify(sender, "Sold loot for $%d (notoriety reset)" % earned)


@rpc("any_peer", "call_remote", "reliable")
func server_request_mask() -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _can_accept_request(sender):
		return
	var player := _get_player(sender)
	if player == null:
		return
	var controller := player.get_role_controller()
	if controller == null:
		return
	if controller.server_try_mask():
		_notify(sender, "Masking... hold still for 3 seconds")
	else:
		_notify(sender, "Cannot mask here (need LootyBay + CITIZEN)")


@rpc("any_peer", "call_remote", "reliable")
func server_request_cop_duty() -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _can_accept_request(sender):
		return
	var player := _get_player(sender)
	if player == null:
		return
	var controller := player.get_role_controller()
	if controller == null:
		return
	var instance := _current_instance_for_peer(sender)
	if instance == null or instance.map_name != "LootyBay":
		_notify(sender, "Cop duty is only available in LootyBay")
		return
	if controller.role == RoleControllerScript.Role.COP:
		if controller.server_go_off_duty():
			_refresh_police_vehicle(instance)
			_notify(sender, "Off duty")
		else:
			_notify(sender, "Go off duty inside the Police Station")
		return
	if controller.server_go_on_duty():
		_refresh_police_vehicle(instance)
		_notify(sender, "On duty: cop loadout issued")
	else:
		_notify(sender, "Go on duty inside the Police Station as a CITIZEN")


## Server-authoritative hit detection. The target is resolved only inside the
## sender's own instance; the raycast runs in that instance's World3D.
@rpc("any_peer", "call_remote", "reliable")
func server_request_attack(target_peer_id: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _can_accept_request(sender) or _transfers.has(sender):
		return
	var instance := _current_instance_for_peer(sender)
	if instance == null or instance.map_name != "LootyBay":
		return
	var attacker := instance.get_player(sender) as PlayerCharacter
	var target := instance.get_player(target_peer_id) as PlayerCharacter
	if attacker == null or target == null or attacker == target:
		return
	if String(_peer_instances.get(target_peer_id, "")) != instance.instance_id:
		return
	var attacker_controller := attacker.get_role_controller()
	if attacker_controller == null or not attacker_controller.can_attack(target):
		return
	if attacker.global_position.distance_to(target.global_position) > ATTACK_RANGE:
		return
	if not _has_line_of_sight(instance, attacker, target):
		return
	target.take_damage(ATTACK_DAMAGE)


@rpc("any_peer", "call_remote", "reliable")
func server_request_surrender() -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _can_accept_request(sender):
		return
	if _transfers.has(sender):
		return
	var player := _get_player(sender)
	if player == null:
		return
	var instance := _current_instance_for_peer(sender)
	if instance == null or instance.map_name != "LootyBay":
		_notify(sender, "Only criminals inside LootyBay can surrender")
		return
	var controller := player.get_role_controller()
	if controller == null or controller.role != RoleControllerScript.Role.CRIMINAL:
		_notify(sender, "Only CRIMINAL players can surrender")
		return
	var cop := _find_surrender_cop(instance, player)
	if cop == null:
		_notify(sender, "No COP within %.0f m with line of sight" % SURRENDER_RANGE)
		return
	var cop_controller: PlayerRoleController = _controller_for(cop)
	var result: Dictionary = controller.server_apply_surrender(cop_controller)
	if not bool(result.get("ok", false)):
		_notify(sender, "Surrender failed")
		return
	var cop_peer: int = int(cop.get("peer_id"))
	_notify(cop_peer, "Surrender accepted: +$%d reward" % int(result.get("reward", 0)))
	_notify(sender, "Surrendered: bag handed over, gear kept")
	var motel := _get_or_create_instance("Motel", 1)
	if not _begin_transfer(sender, motel):
		_notify(sender, "Could not transfer to Motel")


@rpc("any_peer", "call_remote", "reliable")
func client_instance_ready(instance_id: String) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _running or not multiplayer.is_server() or sender <= 0:
		return
	var transfer: Variant = _transfers.get(sender)
	if transfer == null:
		return
	var transfer_data: Dictionary = transfer
	if String(transfer_data.get("target_id", "")) != instance_id:
		return
	_finalize_transfer(sender, instance_id)


# ============================================================================
# Client-bound RPCs (server -> one client)
# ============================================================================

@rpc("authority", "call_remote", "reliable")
func client_load_instance(instance_id: String, map_name: String) -> void:
	if multiplayer.is_server():
		return
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("client_show_instance"):
		scene.call("client_show_instance", instance_id, map_name)
	else:
		push_error("client_load_instance: current scene cannot show instances")
	rpc_id(1, "client_instance_ready", instance_id)


@rpc("authority", "call_remote", "reliable")
func client_message(text: String) -> void:
	print("[FinalRun] %s" % text)
	notification_received.emit(text)


@rpc("authority", "call_remote", "reliable")
func client_party_invite(inviter_id: int) -> void:
	party_invite_received.emit(inviter_id)


@rpc("authority", "call_remote", "reliable")
func client_party_left(reason: String) -> void:
	party_changed_client.emit({"active": false, "reason": reason})


@rpc("authority", "call_remote", "reliable")
func client_party_state(party_info: Dictionary) -> void:
	party_changed_client.emit(party_info)


# ============================================================================
# Client request wrapper (client only)
# ============================================================================

func request_join_map(map_name: String) -> void:
	if not _can_send_client_request():
		return
	rpc_id(1, "server_request_join_map", map_name)


func request_party_create() -> void:
	if not _can_send_client_request():
		return
	rpc_id(1, "server_request_party_create")


func request_party_invite(target_peer_id: int) -> void:
	if not _can_send_client_request():
		return
	rpc_id(1, "server_request_party_invite", target_peer_id)


func request_party_accept(inviter_peer_id: int) -> void:
	if not _can_send_client_request():
		return
	rpc_id(1, "server_request_party_accept", inviter_peer_id)


func request_party_leave() -> void:
	if not _can_send_client_request():
		return
	rpc_id(1, "server_request_party_leave")


func request_party_kick(target_peer_id: int) -> void:
	if not _can_send_client_request():
		return
	rpc_id(1, "server_request_party_kick", target_peer_id)


func request_sell_loot() -> void:
	if not _can_send_client_request():
		return
	rpc_id(1, "server_request_sell_loot")


func request_mask() -> void:
	if not _can_send_client_request():
		return
	rpc_id(1, "server_request_mask")


func request_cop_duty() -> void:
	if not _can_send_client_request():
		return
	rpc_id(1, "server_request_cop_duty")


func request_surrender() -> void:
	if not _can_send_client_request():
		return
	rpc_id(1, "server_request_surrender")


func request_attack(target_peer_id: int) -> void:
	if not _can_send_client_request():
		return
	rpc_id(1, "server_request_attack", target_peer_id)


# ============================================================================
# Player connection lifecycle
# ============================================================================

func handle_peer_joined(peer_id: int) -> void:
	if not _running or not multiplayer.is_server() or peer_id <= 0:
		return
	if _player_states.has(peer_id):
		return
	_player_states[peer_id] = _default_player_state()
	_notify(peer_id, "Connected to %s" % server_id)
	var motel := _get_or_create_instance("Motel", 1)
	if motel == null or not _begin_transfer(peer_id, motel):
		push_error("ServerManager: could not start initial transfer for peer %d" % peer_id)


func handle_peer_left(peer_id: int) -> void:
	if peer_id <= 0:
		return
	_cleanup_transfer(peer_id)
	var instance := _current_instance_for_peer(peer_id)
	if instance != null:
		var player := instance.get_player(peer_id)
		if player != null:
			_revoke_visibility(player, instance, peer_id)
			_despawn_player_node(instance, player)
		instance.remove_member(peer_id)
		instance.refresh_visibility()
		_refresh_police_vehicle(instance)
	_peer_instances.erase(peer_id)
	_player_states.erase(peer_id)
	_pending_invites.erase(peer_id)
	for target_value: Variant in _pending_invites.keys():
		var target_id: int = int(target_value)
		var invite: Variant = _pending_invites.get(target_id)
		if invite is Dictionary and int((invite as Dictionary).get("inviter", 0)) == peer_id:
			_pending_invites.erase(target_id)
	leave_party(peer_id)


# ============================================================================
# Map transfers
# ============================================================================

func _handle_join_map(peer_id: int, map_name: String) -> void:
	if not map_exists(map_name):
		_notify(peer_id, "Unknown map: %s" % map_name)
		return
	if _transfers.has(peer_id):
		_notify(peer_id, "Transfer already in progress")
		return
	var current_instance := _current_instance_for_peer(peer_id)
	if current_instance == null:
		_notify(peer_id, "You are not inside an instance")
		return
	if current_instance.map_name == map_name:
		_notify(peer_id, "Already in %s" % map_name)
		return
	if not is_route_allowed(current_instance.map_name, map_name):
		_notify(peer_id, "Route %s -> %s is not allowed" % [current_instance.map_name, map_name])
		return

	if map_name == "LootyBay":
		_handle_lootybay_entry(peer_id, current_instance)
		return

	var target := _get_or_create_instance(map_name, 1)
	if target == null:
		_notify(peer_id, "Could not create %s" % map_name)
		return
	if not _begin_transfer(peer_id, target):
		_notify(peer_id, "Could not start transfer")


func _handle_lootybay_entry(peer_id: int, current_instance: GameInstance) -> void:
	var party := get_party(peer_id)
	var group: Array[int] = [peer_id]
	if party != null:
		if not party.is_leader(peer_id):
			_notify(peer_id, "Only the party leader can enter LootyBay")
			return
		group.clear()
		for member: int in party.members:
			group.append(member)
		for member: int in group:
			if _transfers.has(member):
				_notify(peer_id, "A party member is already transferring")
				return
			var member_instance := _current_instance_for_peer(member)
			if member_instance == null:
				_notify(peer_id, "A party member is not inside an instance")
				return
			if member_instance.map_name != "Motel":
				_notify(peer_id, "The whole party must be in Motel to enter LootyBay")
				return

	if current_instance.map_name != "Motel":
		_notify(peer_id, "Enter LootyBay from Motel")
		return

	var target := _get_or_create_instance("LootyBay", group.size())
	if target == null:
		_notify(peer_id, "Could not create LootyBay")
		return
	if not target.is_shared() and target.free_slots() < group.size():
		_notify(peer_id, "Not enough free slots in LootyBay")
		return
	for member: int in group:
		if not _begin_transfer(member, target):
			_notify(member, "Could not enter LootyBay")


func _begin_transfer(peer_id: int, target: GameInstance) -> bool:
	if target == null or _transfers.has(peer_id):
		return false
	if not target.is_shared() and target.free_slots() < 1:
		return false
	if not multiplayer.has_multiplayer_peer() or not _player_states.has(peer_id):
		return false

	var old_instance := _current_instance_for_peer(peer_id)
	if old_instance != null:
		var old_player := old_instance.get_player(peer_id)
		if old_player != null:
			var controller: PlayerRoleController = _controller_for(old_player)
			if controller != null:
				controller.server_prepare_leave_instance()
				_player_states[peer_id] = controller.export_state()
			_revoke_visibility(old_player, old_instance, peer_id)
			_despawn_player_node(old_instance, old_player)
		old_instance.remove_member(peer_id)
		old_instance.refresh_visibility()
		_refresh_police_vehicle(old_instance)
	_peer_instances.erase(peer_id)

	target.reserved_slots += 1
	_transfers[peer_id] = {
		"target_id": target.instance_id,
		"map_name": target.map_name,
		"deadline_ms": Time.get_ticks_msec() + int(TRANSFER_TIMEOUT_SECONDS * 1000.0),
	}
	rpc_id(peer_id, "client_load_instance", target.instance_id, target.map_name)
	return true


func _finalize_transfer(peer_id: int, instance_id: String) -> void:
	var transfer: Variant = _transfers.get(peer_id)
	if transfer == null:
		return
	var transfer_data: Dictionary = transfer
	var target := get_instance(String(transfer_data.get("target_id", "")))
	_transfers.erase(peer_id)
	if target == null:
		return
	target.reserved_slots = maxi(target.reserved_slots - 1, 0)
	if not target.is_shared() and target.free_slots() < 1 and not target.has_member(peer_id):
		_notify(peer_id, "Instance became full during transfer")
		return
	if not multiplayer.has_multiplayer_peer() or not multiplayer.get_peers().has(peer_id):
		return
	if not target.has_member(peer_id) and not target.add_member(peer_id):
		_notify(peer_id, "Could not join instance")
		return
	_peer_instances[peer_id] = target.instance_id
	_spawn_player(peer_id, target)
	target.refresh_visibility()
	target.sync_state_to_peer(peer_id)
	_notify(peer_id, "Entered %s" % target.instance_id)


func _cleanup_transfer(peer_id: int) -> void:
	var transfer: Variant = _transfers.get(peer_id)
	if transfer == null:
		return
	var transfer_data: Dictionary = transfer
	var target := get_instance(String(transfer_data.get("target_id", "")))
	if target != null:
		target.reserved_slots = maxi(target.reserved_slots - 1, 0)
	_transfers.erase(peer_id)


func _update_transfers() -> void:
	var now: int = Time.get_ticks_msec()
	var timed_out: Array[int] = []
	for key: Variant in _transfers.keys():
		var transfer_data: Dictionary = _transfers[key]
		if now >= int(transfer_data.get("deadline_ms", 0)):
			timed_out.append(int(key))
	for peer_id: int in timed_out:
		push_warning("Transfer ack timeout for peer %d" % peer_id)
		_cleanup_transfer(peer_id)
		_disconnect_peer(peer_id)


func _disconnect_peer(peer_id: int) -> void:
	var peer := multiplayer.multiplayer_peer
	if peer != null and peer.has_method("disconnect_peer"):
		peer.call("disconnect_peer", peer_id)
	else:
		handle_peer_left(peer_id)


# ============================================================================
# Spawning / despawn / visibility
# ============================================================================

## Must be assigned as `spawn_function` on every instance spawner on both sides.
## Godot calls it on all peers that receive the custom spawn.
func _spawn_player_node(data: Variant) -> Node:
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
	if multiplayer.is_server():
		var instance := get_instance(instance_id)
		if instance == null:
			return null
		var state: Variant = _player_states.get(peer_id)
		if state == null:
			state = _default_player_state()
		player.call("setup_server", instance, state)
	else:
		var client_instance := _find_client_instance(instance_id)
		if client_instance != null:
			player.call("setup_client", client_instance)
		print("[ServerManager] Client spawned player %d in %s" % [peer_id, instance_id])
	return player


## Assigns the custom spawn function to an instance spawner (server or client).
func configure_spawner(spawner: MultiplayerSpawner) -> void:
	if spawner != null:
		spawner.spawn_function = _spawn_player_node


func _find_client_instance(instance_id: String) -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	var holder := scene.get_node_or_null("Instances")
	if holder == null:
		return null
	return holder.get_node_or_null(instance_id)


func _spawn_player(peer_id: int, instance: GameInstance) -> void:
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
		push_error("ServerManager: failed to spawn player %d in %s" % [peer_id, instance.instance_id])
		return
	instance.refresh_visibility()


func _despawn_player_node(instance: GameInstance, player: Node) -> void:
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
func _revoke_visibility(player: Node, instance: GameInstance, peer_id: int) -> void:
	var sync := player.get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
	if sync != null:
		for member: int in instance.members:
			sync.set_visibility_for(member, false)
		sync.set_visibility_for(peer_id, false)
	for other: Node in instance.get_players():
		if other == player:
			continue
		var other_sync := other.get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
		if other_sync != null:
			other_sync.set_visibility_for(peer_id, false)


# ============================================================================
# Instance registry / cleanup
# ============================================================================

func _get_or_create_instance(map_name: String, party_size: int) -> GameInstance:
	if not map_exists(map_name):
		return null
	if is_shared_map(map_name):
		var shared := _find_shared_instance(map_name)
		if shared != null:
			return shared
		return _create_instance(map_name)
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
	return _create_instance(map_name)


func _find_shared_instance(map_name: String) -> GameInstance:
	for instance: GameInstance in get_all_instances():
		if instance.map_name == map_name and instance.is_shared():
			return instance
	return null


func _create_instance(map_name: String) -> GameInstance:
	if not map_exists(map_name):
		return null
	if is_shared_map(map_name):
		var existing := _find_shared_instance(map_name)
		if existing != null:
			return existing
		return _instantiate_instance(map_name, GameInstance.Kind.SHARED)
	var counter: int = int(_instance_counters.get(map_name, 0))
	var instance_id: String = ""
	while true:
		counter += 1
		instance_id = format_instance_id(map_name, counter)
		if not _instances.has(instance_id):
			break
	_instance_counters[map_name] = counter
	return _instantiate_instance(instance_id, GameInstance.Kind.INSTANCED)


func _instantiate_instance(instance_id: String, instance_kind: int) -> GameInstance:
	if instances_root == null:
		push_error("ServerManager: instances root is not bound")
		return null
	var map_name := instance_id if is_shared_map(instance_id) else instance_id.get_slice("-", 0)
	if not map_exists(map_name):
		push_error("ServerManager: cannot derive map name from %s" % instance_id)
		return null
	var map_scene: PackedScene = MAP_SCENES[map_name]
	var instance: GameInstance = InstanceScript.new()
	instance.name = instance_id
	instances_root.add_child(instance)
	instance.setup(
		instance_id,
		map_name,
		instance_kind,
		int(MAP_CAPACITY.get(map_name, 16)),
		bool(MAP_SAFEZONE.get(map_name, false)),
		map_scene,
		true
	)
	configure_spawner(instance.spawner)
	instance.zone_entered.connect(_on_zone_entered.bind(instance))
	instance.zone_exited.connect(_on_zone_exited.bind(instance))
	_instances[instance_id] = instance
	print("[ServerManager] Created instance %s" % instance_id)
	return instance


func _destroy_instance(instance: GameInstance) -> void:
	if instance == null or instance.is_shared():
		return
	if instance.member_count() > 0 or instance.reserved_slots > 0:
		return
	_instances.erase(instance.instance_id)
	instance.queue_free()


func _process(delta: float) -> void:
	if not _running:
		return
	_update_transfers()
	var now_empty: Array[GameInstance] = []
	for instance: GameInstance in get_all_instances():
		if instance.is_shared():
			continue
		if instance.member_count() == 0 and instance.reserved_slots == 0:
			instance.empty_seconds += delta
			if instance.empty_seconds >= EMPTY_INSTANCE_FREE_SECONDS:
				now_empty.append(instance)
		else:
			instance.empty_seconds = 0.0
	for instance: GameInstance in now_empty:
		_destroy_instance(instance)


# ============================================================================
# Zone handling
# ============================================================================

func _on_zone_entered(zone_name: String, player: Node, instance: GameInstance) -> void:
	if not _running or player == null or not is_instance_valid(player):
		return
	var peer_id := int(player.get("peer_id"))
	if _transfers.has(peer_id):
		return
	if _current_instance_for_peer(peer_id) != instance:
		return
	match zone_name:
		"ExtractZone":
			# Zone signals fire while physics is flushing; defer the transfer so
			# the player node is not removed from the tree mid-step.
			call_deferred("_handle_extraction", player, instance)
		"PoliceStation":
			var controller := _controller_for(player)
			if controller != null:
				controller.set_in_police_station(true)
				_notify(peer_id, "Police Station: press G to go on/off duty")


func _on_zone_exited(zone_name: String, player: Node, instance: GameInstance) -> void:
	if not _running or player == null or not is_instance_valid(player):
		return
	if zone_name == "PoliceStation":
		var controller := _controller_for(player)
		if controller != null:
			controller.set_in_police_station(false)
			_notify(int(player.get("peer_id")), "You left the Police Station")


func _handle_extraction(player: Node, instance: GameInstance) -> void:
	if instance == null or instance.map_name != "LootyBay":
		return
	if player == null or not is_instance_valid(player):
		return
	var peer_id := int(player.get("peer_id"))
	if _transfers.has(peer_id):
		return
	if _current_instance_for_peer(peer_id) != instance:
		return
	var controller := _controller_for(player)
	if controller == null:
		return
	controller.server_on_extraction()
	_player_states[peer_id] = controller.export_state()
	_refresh_police_vehicle(instance)
	var motel := _get_or_create_instance("Motel", 1)
	if motel == null or not _begin_transfer(peer_id, motel):
		_notify(peer_id, "Extraction failed")
		return
	_notify(peer_id, "Extracted from LootyBay")


## Public hook used by Player.take_damage() and future combat code.
func handle_player_death(player: Node) -> void:
	if not _running or not multiplayer.is_server():
		return
	if player == null or not is_instance_valid(player):
		return
	var peer_id := int(player.get("peer_id"))
	if _transfers.has(peer_id):
		return
	var instance := _current_instance_for_peer(peer_id)
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
	_player_states[peer_id] = controller.export_state()
	_refresh_police_vehicle(instance)
	var motel := _get_or_create_instance("Motel", 1)
	if motel == null or not _begin_transfer(peer_id, motel):
		_notify(peer_id, "Respawn transfer failed")


func _find_surrender_cop(instance: GameInstance, criminal: Node) -> Node:
	var best: Node = null
	var best_distance: float = SURRENDER_RANGE + 1.0
	for player: Node in instance.get_players():
		if player == criminal:
			continue
		var controller := _controller_for(player)
		if controller == null or controller.role != RoleControllerScript.Role.COP:
			continue
		var distance: float = criminal.global_position.distance_to(player.global_position)
		if distance > SURRENDER_RANGE:
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
	var from: Vector3 = from_player.global_position + Vector3(0.0, 1.4, 0.0)
	var to: Vector3 = target_player.global_position + Vector3(0.0, 1.2, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to, 3)
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


# ============================================================================
# Party registry
# ============================================================================

func _create_party(peer_id: int) -> Party:
	var existing := get_party(peer_id)
	if existing != null:
		return existing
	var party := PartyScript.new(_next_party_id, peer_id) as Party
	_next_party_id += 1
	_parties[party.id] = party
	_peer_party[peer_id] = party.id
	return party


func _invite_to_party(inviter_id: int, target_id: int) -> bool:
	if inviter_id <= 0 or target_id <= 0 or inviter_id == target_id:
		return false
	if not _player_states.has(target_id):
		return false
	if get_party(target_id) != null:
		return false
	var party := get_party(inviter_id)
	if party == null:
		party = _create_party(inviter_id)
	if party == null or party.is_full():
		return false
	_pending_invites[target_id] = {
		"inviter": inviter_id,
		"party_id": party.id,
	}
	_notify(target_id, "Party invite from player %d" % inviter_id)
	if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().has(target_id):
		rpc_id(target_id, "client_party_invite", inviter_id)
	_notify(inviter_id, "Invite sent to player %d" % target_id)
	return true


func _accept_party_invite(target_id: int, inviter_id: int) -> bool:
	var invite: Variant = _pending_invites.get(target_id)
	if invite == null:
		return false
	var invite_data: Dictionary = invite
	if int(invite_data.get("inviter", 0)) != inviter_id:
		return false
	_pending_invites.erase(target_id)
	if get_party(target_id) != null:
		return false
	var party := get_party(inviter_id)
	if party == null or party.is_full():
		return false
	if party.id != int(invite_data.get("party_id", -1)):
		return false
	if not party.add_member(target_id):
		return false
	_peer_party[target_id] = party.id
	_notify(target_id, "Joined the party")
	_send_party_state(party)
	return true


func leave_party(peer_id: int) -> void:
	var party := get_party(peer_id)
	if party == null:
		return
	party.remove_member(peer_id)
	_peer_party.erase(peer_id)
	if party.is_empty():
		_parties.erase(party.id)
		return
	_send_party_state(party)
	_notify(party.leader_id, "Party leader is now player %d" % party.leader_id)


func kick_from_party(leader_id: int, target_id: int) -> bool:
	var party := get_party(leader_id)
	if party == null or not party.is_leader(leader_id):
		return false
	if target_id == leader_id or not party.has_member(target_id):
		return false
	party.remove_member(target_id)
	_peer_party.erase(target_id)
	_notify(target_id, "You were kicked from the party")
	if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().has(target_id):
		rpc_id(target_id, "client_party_left", "kicked")
	_send_party_state(party)
	return true


func _send_party_state(party: Party) -> void:
	if party == null:
		return
	var info := {
		"active": true,
		"party_id": party.id,
		"leader_id": party.leader_id,
		"members": party.members.duplicate(),
	}
	for member: int in party.members:
		_notify(member, "Party: leader %d, members %s" % [party.leader_id, str(party.members)])
		if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().has(member):
			rpc_id(member, "client_party_state", info)


# ============================================================================
# Small helpers
# ============================================================================

func _default_player_state() -> Dictionary:
	return {
		"role": RoleControllerScript.Role.CITIZEN,
		"loot_bag": [],
		"equipped_gear": [],
		"saved_civilian_gear": [],
		"notoriety": 0.0,
		"cash": 0,
		"cop_on_duty": false,
	}


func _current_instance_for_peer(peer_id: int) -> GameInstance:
	var instance_id: Variant = _peer_instances.get(peer_id)
	if instance_id == null:
		return null
	return get_instance(String(instance_id))


func _get_player(peer_id: int) -> PlayerCharacter:
	var instance := _current_instance_for_peer(peer_id)
	if instance == null:
		return null
	return instance.get_player(peer_id) as PlayerCharacter


func _controller_for(player: Node) -> PlayerRoleController:
	if player == null or not is_instance_valid(player):
		return null
	if player is PlayerCharacter:
		return (player as PlayerCharacter).get_role_controller()
	return player.get_node_or_null("PlayerRoleController") as PlayerRoleController


func _can_accept_request(sender_id: int) -> bool:
	if not _running or not multiplayer.is_server():
		return false
	if sender_id <= 0:
		return false
	if not _player_states.has(sender_id):
		return false
	return true


func _can_send_client_request() -> bool:
	if _running or not multiplayer.has_multiplayer_peer():
		return false
	return not multiplayer.is_server()


func _notify(peer_id: int, text: String) -> void:
	print("[ServerManager] peer %d: %s" % [peer_id, text])
	if multiplayer.has_multiplayer_peer() and multiplayer.get_peers().has(peer_id):
		rpc_id(peer_id, "client_message", text)
