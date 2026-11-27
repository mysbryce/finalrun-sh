class_name TransferService
extends RefCounted
## Route validation, map transfers, the client instance-load ack, transfer
## timeouts and disconnect cleanup.
##
## ServerManager owns this service and supplies a small host interface:
## `_notify`, `_send_client_rpc`, `is_peer_known`, `get_party`, `get_map_scene`
## and `map_exists`. Network RPCs are sent from the host node so the client-side
## ServerManager path stays unchanged.

## LootyBay is a one-way exit: extraction, death or surrender only.
const ALLOWED_ROUTES := {
	GameConst.MAP_MOTEL: [GameConst.MAP_LOOTY_BAY, GameConst.MAP_HOUSE, GameConst.MAP_CENTER],
	GameConst.MAP_HOUSE: [GameConst.MAP_MOTEL, GameConst.MAP_CENTER],
	GameConst.MAP_CENTER: [GameConst.MAP_MOTEL, GameConst.MAP_HOUSE],
	GameConst.MAP_LOOTY_BAY: [],
}

var _host: Node = null
var _instances: InstanceRegistry = null
var _prepare_leave: Callable = Callable()
var _disconnect_peer: Callable = Callable()
var _transfers: Dictionary = {}


func configure(
	host: Node,
	instances: InstanceRegistry,
	prepare_leave: Callable,
	disconnect_peer: Callable
) -> void:
	_host = host
	_instances = instances
	_prepare_leave = prepare_leave
	_disconnect_peer = disconnect_peer


static func is_route_allowed(from_map: String, to_map: String) -> bool:
	if from_map == to_map:
		return false
	var routes: Array = ALLOWED_ROUTES.get(from_map, [])
	return routes.has(to_map)


func has_transfer(peer_id: int) -> bool:
	return _transfers.has(peer_id)


## Client `server_request_join_map` entry point. Validates the route and either
## moves one player or the leader's whole party.
func handle_join_map(peer_id: int, map_name: String) -> void:
	if not bool(_host.call("map_exists", map_name)):
		_notify(peer_id, "Unknown map: %s" % map_name)
		return
	if _transfers.has(peer_id):
		_notify(peer_id, "Transfer already in progress")
		return
	var current_instance := _instances.current_instance_for_peer(peer_id)
	if current_instance == null:
		_notify(peer_id, "You are not inside an instance")
		return
	if current_instance.map_name == map_name:
		_notify(peer_id, "Already in %s" % map_name)
		return
	if not is_route_allowed(current_instance.map_name, map_name):
		_notify(peer_id, "Route %s -> %s is not allowed" % [current_instance.map_name, map_name])
		return

	if map_name == GameConst.MAP_LOOTY_BAY:
		_handle_lootybay_entry(peer_id, current_instance)
		return

	var target := _get_or_create_instance(map_name, 1)
	if target == null:
		_notify(peer_id, "Could not create %s" % map_name)
		return
	if not begin_transfer(peer_id, target):
		_notify(peer_id, "Could not start transfer")


## Reserves a slot in the target, snapshots and despawns the player from the
## old instance, then asks the client to load the destination and waits for the
## ack.
func begin_transfer(
	peer_id: int, target: GameInstance, reason: String = GameConst.TRANSFER_REASON_TRAVEL
) -> bool:
	if target == null or _transfers.has(peer_id):
		return false
	if not target.is_shared() and target.free_slots() < 1:
		return false
	if not _host.multiplayer.has_multiplayer_peer() or not bool(_host.call("is_peer_known", peer_id)):
		return false

	_prepare_leave.call(peer_id)
	if not _instances.reserve_slot(target):
		return false
	_transfers[peer_id] = {
		"target_id": target.instance_id,
		"map_name": target.map_name,
		"deadline_ms": Time.get_ticks_msec() + int(GameConst.TRANSFER_TIMEOUT_SECONDS * 1000.0),
	}
	_host.call(
		"_send_client_rpc",
		peer_id,
		"client_load_instance",
		[target.instance_id, target.map_name, reason]
	)
	return true


## Client ack. Spawns the player only after the destination instance exists on
## the client, so the spawner and synchronizer resolve.
func client_ready(peer_id: int, instance_id: String) -> void:
	var transfer: Variant = _transfers.get(peer_id)
	if transfer == null:
		return
	var transfer_data: Dictionary = transfer
	if String(transfer_data.get("target_id", "")) != instance_id:
		return
	var target := _instances.get_instance(String(transfer_data.get("target_id", "")))
	_transfers.erase(peer_id)
	if target == null:
		return
	_instances.release_slot(target)
	if not target.is_shared() and target.free_slots() < 1 and not target.has_member(peer_id):
		_notify(peer_id, "Instance became full during transfer")
		return
	if not _host.multiplayer.has_multiplayer_peer() or not _host.multiplayer.get_peers().has(peer_id):
		return
	if not target.has_member(peer_id) and not target.add_member(peer_id):
		_notify(peer_id, "Could not join instance")
		return
	_instances.set_peer_instance(peer_id, target.instance_id)
	_instances.spawn_player(peer_id, target)
	target.refresh_visibility()
	target.sync_state_to_peer(peer_id)
	_notify(peer_id, "Entered %s" % target.instance_id)


## Releases the reservation for a transfer that will not be finalized.
func cleanup_transfer(peer_id: int) -> void:
	var transfer: Variant = _transfers.get(peer_id)
	if transfer == null:
		return
	var transfer_data: Dictionary = transfer
	var target := _instances.get_instance(String(transfer_data.get("target_id", "")))
	_instances.release_slot(target)
	_transfers.erase(peer_id)


## Fails transfers whose ack did not arrive in time and disconnects the peer.
func update() -> void:
	var now: int = Time.get_ticks_msec()
	var timed_out: Array[int] = []
	for key: Variant in _transfers.keys():
		var transfer_data: Dictionary = _transfers[key]
		if now >= int(transfer_data.get("deadline_ms", 0)):
			timed_out.append(int(key))
	for peer_id: int in timed_out:
		push_warning("Transfer ack timeout for peer %d" % peer_id)
		cleanup_transfer(peer_id)
		_disconnect_peer.call(peer_id)


## Shared path for extraction, death and surrender: create/select Motel and
## transfer the player there.
func transfer_to_motel(peer_id: int, reason: String) -> bool:
	var motel := _get_or_create_instance(GameConst.MAP_MOTEL, 1)
	if motel == null:
		return false
	return begin_transfer(peer_id, motel, reason)


func _handle_lootybay_entry(peer_id: int, current_instance: GameInstance) -> void:
	var party := _host.call("get_party", peer_id) as Party
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
			var member_instance := _instances.current_instance_for_peer(member)
			if member_instance == null:
				_notify(peer_id, "A party member is not inside an instance")
				return
			if member_instance.map_name != GameConst.MAP_MOTEL:
				_notify(peer_id, "The whole party must be in Motel to enter LootyBay")
				return

	if current_instance.map_name != GameConst.MAP_MOTEL:
		_notify(peer_id, "Enter LootyBay from Motel")
		return

	var target := _get_or_create_instance(GameConst.MAP_LOOTY_BAY, group.size())
	if target == null:
		_notify(peer_id, "Could not create LootyBay")
		return
	if not target.is_shared() and target.free_slots() < group.size():
		_notify(peer_id, "Not enough free slots in LootyBay")
		return
	for member: int in group:
		if not begin_transfer(member, target):
			_notify(member, "Could not enter LootyBay")


func _get_or_create_instance(map_name: String, party_size: int) -> GameInstance:
	var map_scene: PackedScene = _host.call("get_map_scene", map_name) as PackedScene
	return _instances.get_or_create_instance(map_name, party_size, map_scene)


func _notify(peer_id: int, text: String) -> void:
	_host.call("_notify", peer_id, text)
