extends Node
## Dedicated-server brain and client-side network facade.
##
## The autoload path and RPC method names are fixed. This node validates every
## sender and delegates to InstanceRegistry (instances/slots/spawning),
## PartyService, TransferService (routes/ack/timeout) and PlayerService
## (sessions/actions/zones). Client side it forwards requests to peer 1.
## Gameplay events are never broadcast.

signal notification_received(text: String)
signal party_invite_received(inviter_id: int)
signal party_changed_client(party_info: Dictionary)
signal search_contents_received(target_peer_id: int, items: Array)
signal search_closed_received(target_peer_id: int, reason: String)

const MAP_SCENES := {
	GameConst.MAP_MOTEL: preload("res://maps/motel/Motel.tscn"),
	GameConst.MAP_LOOTY_BAY: preload("res://maps/looty_bay/LootyBay.tscn"),
	GameConst.MAP_HOUSE: preload("res://maps/house/House.tscn"),
	GameConst.MAP_CENTER: preload("res://maps/center/Center.tscn"),
}

var server_id: String = ""
var instances_root: Node = null

var _running: bool = false
var _instances: InstanceRegistry = InstanceRegistry.new()
var _parties: PartyService = PartyService.new()
var _transfers: TransferService = TransferService.new()
var _players: PlayerService = PlayerService.new()
var _downed: DownedService = DownedService.new()
## Smoke-test hook state; only active with the `--smoke` cmdline flag.
var _smoke_enabled: bool = false
var _smoke_ready: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	_players.configure(self, _instances, _transfers, _parties)
	_players.set_downed_hooks(
		Callable(_downed, "on_life_state_changed"),
		Callable(_downed, "on_disconnect"),
		Callable(_downed, "on_player_leaving")
	)
	_downed.configure(self, _instances, _players, _parties)
	_parties.configure(
		Callable(self, "_notify"),
		Callable(self, "_send_client_rpc"),
		Callable(self, "is_peer_known")
	)
	_transfers.configure(
		self,
		_instances,
		Callable(_players, "prepare_transfer_leave"),
		Callable(_players, "disconnect_peer")
	)
	_instances.set_spawn_function(Callable(_players, "spawn_node"))


# --- Lifecycle ---------------------------------------------------------------

func setup_server(p_instances_root: Node) -> void:
	if _running:
		return
	if p_instances_root == null:
		push_error("ServerManager.setup_server: instances root is null")
		return
	instances_root = p_instances_root
	_instances.configure(
		p_instances_root,
		Callable(_players, "spawn_node"),
		Callable(_players, "on_zone_entered"),
		Callable(_players, "on_zone_exited")
	)
	_running = true
	_smoke_enabled = (
		OS.get_cmdline_args().has("--smoke")
		or OS.get_cmdline_user_args().has("--smoke")
	)
	server_id = generate_server_id()
	for map_name: String in GameConst.SHARED_MAPS:
		_instances.get_or_create_instance(map_name, 1, get_map_scene(map_name))
	print("[ServerManager] Server %s booted (port %d)" % [server_id, GameConst.PORT])


static func format_server_id(number: int) -> String:
	return "%s%04d" % [GameConst.SERVER_ID_PREFIX, posmod(number, GameConst.SERVER_ID_MODULO)]

static func generate_server_id() -> String:
	return format_server_id(randi_range(0, GameConst.MAX_SERVER_ID))


static func is_valid_server_id(candidate: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^" + GameConst.SERVER_ID_PREFIX + "[0-9]{4}$")
	return regex.search(candidate) != null


# --- Public API / service accessors ------------------------------------------

func is_server_running() -> bool: return _running
func get_server_id() -> String: return server_id
func is_peer_known(peer_id: int) -> bool: return _players.is_peer_known(peer_id)
func get_instance(instance_id: String) -> GameInstance: return _instances.get_instance(instance_id)
func get_instance_count() -> int: return _instances.get_instance_count()
func get_peer_instance_id(peer_id: int) -> String: return _instances.get_peer_instance_id(peer_id)
func get_party(peer_id: int) -> Party: return _parties.get_party(peer_id)
func get_all_instances() -> Array[GameInstance]: return _instances.get_all_instances()
func get_map_capacity(map_name: String) -> int:
	return int(GameConst.MAP_CAPACITY.get(map_name, GameConst.DEFAULT_MAP_CAPACITY))

func is_map_safezone(map_name: String) -> bool:
	return bool(GameConst.MAP_SAFEZONE.get(map_name, false))

func map_exists(map_name: String) -> bool: return MAP_SCENES.has(map_name)
func get_map_scene(map_name: String) -> PackedScene: return MAP_SCENES.get(map_name) as PackedScene
func leave_party(peer_id: int) -> void: _parties.leave_party(peer_id)
func kick_from_party(leader_id: int, target_id: int) -> bool: return _parties.kick_from_party(leader_id, target_id)


# --- Server request entry points (client -> server RPCs) ---------------------

@rpc("any_peer", "call_remote", "reliable")
func server_request_join_map(map_name: String) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if _can_accept_alive_request(sender):
		_transfers.handle_join_map(sender, map_name)


@rpc("any_peer", "call_remote", "reliable")
func server_request_party_create() -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if _can_accept_alive_request(sender):
		_parties.handle_create(sender)


@rpc("any_peer", "call_remote", "reliable")
func server_request_party_invite(target_peer_id: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _can_accept_alive_request(sender):
		return
	if not _parties.invite_to_party(sender, target_peer_id):
		_notify(sender, "Cannot invite that player")


@rpc("any_peer", "call_remote", "reliable")
func server_request_party_accept(inviter_peer_id: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _can_accept_alive_request(sender):
		return
	if not _parties.accept_party_invite(sender, inviter_peer_id):
		_notify(sender, "Invite is no longer valid")


@rpc("any_peer", "call_remote", "reliable")
func server_request_party_leave() -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _can_accept_request(sender):
		return
	_parties.leave_party(sender)
	_notify(sender, "You left the party")


@rpc("any_peer", "call_remote", "reliable")
func server_request_party_kick(target_peer_id: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _can_accept_request(sender):
		return
	if not _parties.kick_from_party(sender, target_peer_id):
		_notify(sender, "Cannot kick that player")


@rpc("any_peer", "call_remote", "reliable")
func server_request_sell_loot() -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if _can_accept_alive_request(sender):
		_players.sell_loot(sender)


@rpc("any_peer", "call_remote", "reliable")
func server_request_mask() -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if _can_accept_alive_request(sender):
		_players.mask(sender)


@rpc("any_peer", "call_remote", "reliable")
func server_request_cop_duty() -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if _can_accept_alive_request(sender):
		_players.cop_duty(sender)


@rpc("any_peer", "call_remote", "reliable")
func server_request_fire(aim: Vector3) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if _can_accept_alive_request(sender):
		_players.fire(sender, aim, _now_ms())


@rpc("any_peer", "call_remote", "reliable")
func server_request_surrender() -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if _can_accept_alive_request(sender):
		_players.surrender(sender)


# --- Downed actions (client -> server RPCs) ----------------------------------

@rpc("any_peer", "call_remote", "reliable")
func server_request_revive(target_peer_id: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if _can_accept_alive_request(sender):
		_downed.request_revive(sender, target_peer_id)


@rpc("any_peer", "call_remote", "reliable")
func server_request_finish(target_peer_id: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if _can_accept_alive_request(sender):
		_downed.request_finish(sender, target_peer_id)


@rpc("any_peer", "call_remote", "reliable")
func server_request_cuff(target_peer_id: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if _can_accept_alive_request(sender):
		_downed.request_cuff(sender, target_peer_id)


@rpc("any_peer", "call_remote", "reliable")
func server_request_search_open(target_peer_id: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if _can_accept_alive_request(sender):
		_downed.request_search_open(sender, target_peer_id)


@rpc("any_peer", "call_remote", "reliable")
func server_request_search_take(target_peer_id: int, item_uid: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if _can_accept_alive_request(sender):
		_downed.request_search_take(sender, target_peer_id, item_uid)


@rpc("any_peer", "call_remote", "reliable")
func server_request_search_close(target_peer_id: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if _can_accept_alive_request(sender):
		_downed.request_search_close(sender, target_peer_id)


@rpc("any_peer", "call_remote", "reliable")
func client_instance_ready(instance_id: String) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if not _running or not multiplayer.is_server() or sender <= 0:
		return
	_transfers.client_ready(sender, instance_id)


# --- Client-bound RPCs (server -> one client) --------------------------------

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


@rpc("authority", "call_remote", "reliable")
func client_search_contents(target_peer_id: int, items: Array) -> void:
	search_contents_received.emit(target_peer_id, items)


@rpc("authority", "call_remote", "reliable")
func client_search_closed(target_peer_id: int, reason: String) -> void:
	search_closed_received.emit(target_peer_id, reason)


# --- Client request facade (client only) -------------------------------------

func request_join_map(map_name: String) -> void: _send_client_request("server_request_join_map", [map_name])
func request_party_create() -> void: _send_client_request("server_request_party_create")
func request_party_invite(target_peer_id: int) -> void: _send_client_request("server_request_party_invite", [target_peer_id])
func request_party_accept(inviter_peer_id: int) -> void: _send_client_request("server_request_party_accept", [inviter_peer_id])
func request_party_leave() -> void: _send_client_request("server_request_party_leave")
func request_party_kick(target_peer_id: int) -> void: _send_client_request("server_request_party_kick", [target_peer_id])
func request_sell_loot() -> void: _send_client_request("server_request_sell_loot")
func request_mask() -> void: _send_client_request("server_request_mask")
func request_cop_duty() -> void: _send_client_request("server_request_cop_duty")
func request_surrender() -> void: _send_client_request("server_request_surrender")
func request_fire(aim: Vector3) -> void: _send_client_request("server_request_fire", [aim])
func request_revive(target_peer_id: int) -> void: _send_client_request("server_request_revive", [target_peer_id])
func request_finish(target_peer_id: int) -> void: _send_client_request("server_request_finish", [target_peer_id])
func request_cuff(target_peer_id: int) -> void: _send_client_request("server_request_cuff", [target_peer_id])
func request_search_open(target_peer_id: int) -> void: _send_client_request("server_request_search_open", [target_peer_id])
func request_search_take(target_peer_id: int, item_uid: int) -> void: _send_client_request("server_request_search_take", [target_peer_id, item_uid])
func request_search_close(target_peer_id: int) -> void: _send_client_request("server_request_search_close", [target_peer_id])

# --- Main/Player hooks -------------------------------------------------------

func handle_peer_joined(peer_id: int) -> void: _players.handle_peer_joined(peer_id)
func handle_peer_left(peer_id: int) -> void: _players.handle_peer_left(peer_id)

## Public hook used by Player.take_damage() and future combat code.
func handle_player_death(player: Node) -> void: _players.handle_player_death(player)

## Local server hook: damage cancels the victim's active channels.
func notify_player_damaged(player: Node) -> void:
	if _running and multiplayer.is_server():
		_downed.on_player_damaged(player)

## Assigns the custom spawn function to an instance spawner (server or client).
func configure_spawner(spawner: MultiplayerSpawner) -> void: _instances.configure_spawner(spawner)


# --- Per-tick services / internal helpers ------------------------------------

func _process(delta: float) -> void:
	if not _running:
		return
	_transfers.update()
	_instances.update(delta)
	_downed.tick(_now_ms())
	if _smoke_enabled:
		_tick_smoke()


func _can_accept_request(sender_id: int) -> bool:
	return _running and multiplayer.is_server() and NetUtil.is_valid_sender(sender_id) and is_peer_known(sender_id)


## Spec §7 gate: downed and dead players may only keep sending movement.
func _can_accept_alive_request(sender_id: int) -> bool:
	return _can_accept_request(sender_id) and _players.is_peer_alive(sender_id)


func _now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)


func _can_send_client_request() -> bool:
	return not _running and multiplayer.has_multiplayer_peer() and not multiplayer.is_server()


func _send_client_request(method: StringName, args: Array = []) -> void:
	if _can_send_client_request():
		NetUtil.rpc_to_server(self, method, args)


func _send_client_rpc(peer_id: int, method: StringName, args: Array = []) -> void:
	NetUtil.rpc_to_peer(self, peer_id, method, args)


func _notify(peer_id: int, text: String) -> void:
	print("[ServerManager] peer %d: %s" % [peer_id, text])
	NetUtil.rpc_to_peer(self, peer_id, "client_message", [text])


## Test hook, active only with `--smoke`. When two masked criminals stand in
## the same LootyBay instance it equips the victim and teleports the attacker
## next to them, then notifies both clients that the scripted run may start.
func _tick_smoke() -> void:
	if _smoke_ready:
		return
	for instance: GameInstance in _instances.get_all_instances():
		if instance.map_name != GameConst.MAP_LOOTY_BAY:
			continue
		var candidates: Array[Node] = []
		for player: Node in instance.get_players():
			if int(player.get("peer_id")) <= 0:
				continue
			var controller := _players.get_controller(int(player.get("peer_id")))
			if controller == null or controller.role != PlayerRoleController.Role.CRIMINAL:
				continue
			if not controller.is_alive():
				continue
			candidates.append(player)
		if candidates.size() < 2:
			continue
		# Instance child order is spawn order: the first client (victim) joined
		# first, the second client (attacker) joined last.
		var victim: Node = candidates[0]
		var attacker: Node = candidates[candidates.size() - 1]
		var victim_controller := victim.call("get_role_controller") as PlayerRoleController
		if victim_controller == null:
			return
		victim_controller.grant_loot("smoke_bag", 250)
		victim_controller.grant_gear("smoke_gear", 100)
		(attacker as Node3D).global_position = (
			(victim as Node3D).global_position + Vector3(1.0, 0.0, 0.0)
		)
		_smoke_ready = true
		_notify(int(victim.get("peer_id")), "SMOKE READY")
		_notify(int(attacker.get("peer_id")), "SMOKE READY")
		return
