class_name DownedService
extends RefCounted
## Server-side downed rules: bleed-out, revive, finish, cuff and body search.
##
## Owns no Nodes. Channels are `ChannelTimer` nodes parented under the acting
## player; `ServerManager` ticks `tick(now_ms)` for bleed-out. Every request and
## take re-checks instance, range, line of sight and permission; the first
## finished channel wins because later completions re-check target state.

const RoleController = preload("res://features/player/PlayerRoleController.gd")

const KIND_REVIVE: String = "revive"
const KIND_FINISH: String = "finish"
const KIND_CUFF: String = "cuff"
const KIND_SEARCH: String = "search"

const BODY_CONTAINER_NAME: String = "BodyLootContainer"
const SEARCH_CLOSED_REASON: String = "closed"

## Runtime dependency on PlayerService. It is configured after construction
## because the two services reference each other.
var _players: PlayerService = null
var _instances: InstanceRegistry = null
var _parties: PartyService = null
var _host: Node = null

## Active channel records: {kind, actor, target, timer}.
var _channels: Array[Dictionary] = []
## Open search sessions: viewer peer -> {target, instance_id}.
var _sessions: Dictionary = {}


func configure(
	host: Node,
	instances: InstanceRegistry,
	players: PlayerService,
	parties: PartyService
) -> void:
	_host = host
	_instances = instances
	_players = players
	_parties = parties


# --- Pure rules --------------------------------------------------------------

static func can_revive(
	actor_role: int,
	actor_life: int,
	target_role: int,
	target_life: int,
	same_party: bool,
	has_active_reviver: bool
) -> bool:
	return (
		actor_life == RoleController.LifeState.ALIVE
		and target_life == RoleController.LifeState.DOWNED
		and same_party
		and actor_role == target_role
		and not has_active_reviver
	)


static func can_finish(attack_allowed: bool, actor_life: int, target_life: int) -> bool:
	return (
		attack_allowed
		and actor_life == RoleController.LifeState.ALIVE
		and target_life == RoleController.LifeState.DOWNED
	)


static func can_cuff(
	actor_role: int,
	actor_life: int,
	target_role: int,
	target_life: int
) -> bool:
	return (
		actor_role == RoleController.Role.COP
		and actor_life == RoleController.LifeState.ALIVE
		and target_role == RoleController.Role.CRIMINAL
		and target_life == RoleController.LifeState.DOWNED
	)


static func can_search(
	actor_role: int,
	actor_life: int,
	target_role: int,
	target_life: int
) -> bool:
	if actor_life != RoleController.LifeState.ALIVE or target_life != RoleController.LifeState.DOWNED:
		return false
	match actor_role:
		RoleController.Role.CRIMINAL:
			return true
		RoleController.Role.COP:
			return target_role == RoleController.Role.CRIMINAL
		_:
			return false


## Cops are paid a fraction of seized bag value; gear pays nothing.
static func seizure_reward(item: Dictionary, source: String) -> int:
	if source != "bag":
		return 0
	return floori(float(int(item.get("value", 0))) * GameConst.SEIZURE_COP_REWARD_RATIO)


# --- Requests ----------------------------------------------------------------

func request_revive(actor_peer: int, target_peer: int) -> void:
	if _actor_is_busy(actor_peer):
		_notify(actor_peer, "You are already channelling")
		return
	var reason := _check_revive(actor_peer, target_peer)
	if reason != "":
		_notify(actor_peer, "Cannot revive (%s)" % reason)
		return
	_start_channel(actor_peer, target_peer, KIND_REVIVE, GameConst.REVIVE_SECONDS)


func request_finish(actor_peer: int, target_peer: int) -> void:
	if _actor_is_busy(actor_peer):
		_notify(actor_peer, "You are already channelling")
		return
	var reason := _check_finish(actor_peer, target_peer)
	if reason != "":
		_notify(actor_peer, "Cannot finish (%s)" % reason)
		return
	_start_channel(actor_peer, target_peer, KIND_FINISH, GameConst.FINISH_SECONDS)


func request_cuff(actor_peer: int, target_peer: int) -> void:
	if _actor_is_busy(actor_peer):
		_notify(actor_peer, "You are already channelling")
		return
	var reason := _check_cuff(actor_peer, target_peer)
	if reason != "":
		_notify(actor_peer, "Cannot cuff (%s)" % reason)
		return
	_start_channel(actor_peer, target_peer, KIND_CUFF, GameConst.CUFF_SECONDS)


func request_search_open(actor_peer: int, target_peer: int) -> void:
	if _actor_is_busy(actor_peer):
		_notify(actor_peer, "You are already channelling")
		return
	var reason := _check_search(actor_peer, target_peer)
	if reason != "":
		_notify(actor_peer, "Cannot search (%s)" % reason)
		return
	_start_channel(actor_peer, target_peer, KIND_SEARCH, GameConst.SEARCH_OPEN_SECONDS)


func request_search_take(actor_peer: int, target_peer: int, item_uid: int) -> void:
	var session: Variant = _sessions.get(actor_peer)
	if session == null or int((session as Dictionary).get("target", 0)) != target_peer:
		_notify(actor_peer, "No open search for that body")
		return
	var reason := _check_search(actor_peer, target_peer)
	if reason != "":
		_close_session(actor_peer, reason)
		return
	var target := _players.get_player(target_peer)
	var container := _body_container_for(target)
	if container == null:
		_close_session(actor_peer, "target_state")
		return
	var result: Dictionary = container.take(actor_peer, item_uid)
	if not bool(result.get("ok", false)):
		if String(result.get("reason", "")) == "bag_full":
			_notify(actor_peer, "Bag full")
		else:
			_notify(actor_peer, "That item is no longer there")
		return
	var taken: Dictionary = result.get("item", {})
	_notify(actor_peer, "Took %s" % String(taken.get("id", "item")))


func request_search_close(actor_peer: int, target_peer: int) -> void:
	var session: Variant = _sessions.get(actor_peer)
	if session == null or int((session as Dictionary).get("target", 0)) != target_peer:
		return
	_close_session(actor_peer, SEARCH_CLOSED_REASON)


# --- Tick / lifecycle --------------------------------------------------------

## Bleed-out check plus search-session validation. Called by ServerManager with
## the injected server clock.
func tick(now_ms: int) -> void:
	# Sessions do not tick a channel, so re-check range/LOS/permission here and
	# close the moment any of them stops being true.
	for viewer_value: Variant in _sessions.keys().duplicate():
		var viewer := int(viewer_value)
		var session: Dictionary = _sessions.get(viewer)
		var reason := _check_search(viewer, int(session.get("target", 0)))
		if reason != "":
			_close_session(viewer, reason)
	for instance: GameInstance in _instances.get_all_instances():
		for player: Node in instance.get_players():
			var controller := _controller_for(player)
			if controller == null or not controller.is_downed():
				continue
			if controller.downed_deadline_ms <= 0:
				continue
			if now_ms < controller.downed_deadline_ms:
				continue
			controller.server_set_life_state(
				RoleController.LifeState.DEAD,
				"bleedout",
				now_ms
			)
			_players.handle_player_death(player)


## Any life-state change cancels every channel the player is actor or target of
## and closes every search session on their body or with them as viewer.
func on_life_state_changed(
	player: Node,
	_old_state: int,
	new_state: int,
	_cause: String
) -> void:
	var peer := int(player.get("peer_id")) if player != null else 0
	if peer <= 0:
		return
	_cancel_channels(peer, "actor_state", "target_state")
	_close_sessions(peer, "actor_state", "target_state")
	if new_state != RoleController.LifeState.DOWNED:
		_drop_body_container(player)


## Damage only cancels channels the damaged player is the actor of.
func on_player_damaged(player: Node) -> void:
	if player == null:
		return
	_cancel_actor_channels(int(player.get("peer_id")), "damaged")


func on_disconnect(peer_id: int) -> void:
	_cancel_channels(peer_id, "disconnected", "disconnected")
	_close_sessions(peer_id, "disconnected", "disconnected")
	var player := _players.get_player(peer_id)
	if player != null:
		_drop_body_container(player)


## A transfer or normal despawn takes the player out of the instance.
func on_player_leaving(peer_id: int) -> void:
	_cancel_channels(peer_id, "left_instance", "left_instance")
	_close_sessions(peer_id, "left_instance", "left_instance")
	var player := _players.get_player(peer_id)
	if player != null:
		_drop_body_container(player)


# --- Channel plumbing --------------------------------------------------------

func _actor_is_busy(actor_peer: int) -> bool:
	for record: Dictionary in _channels:
		if int(record.get("actor", 0)) == actor_peer:
			return true
	var controller := _players.get_controller(actor_peer)
	return controller != null and controller.is_mask_channel_active()


func _start_channel(
	actor_peer: int,
	target_peer: int,
	kind: String,
	duration: float
) -> void:
	var actor := _players.get_player(actor_peer)
	if actor == null:
		return
	var timer := ChannelTimer.new()
	timer.name = "%sChannelTimer" % kind.capitalize()
	actor.add_child(timer)
	var record: Dictionary = {
		"kind": kind,
		"actor": actor_peer,
		"target": target_peer,
		"timer": timer,
	}
	_channels.append(record)
	timer.completed.connect(_on_channel_completed.bind(record))
	timer.cancelled.connect(_on_channel_cancelled.bind(record))
	timer.start(
		duration,
		actor,
		GameConst.DOWNED_CHANNEL_MAX_MOVE,
		Callable(self, "_channel_cancel_reason").bind(kind, actor_peer, target_peer)
	)


func _channel_cancel_reason(kind: String, actor_peer: int, target_peer: int) -> String:
	match kind:
		KIND_REVIVE:
			return _check_revive(actor_peer, target_peer)
		KIND_FINISH:
			return _check_finish(actor_peer, target_peer)
		KIND_CUFF:
			return _check_cuff(actor_peer, target_peer)
		KIND_SEARCH:
			return _check_search(actor_peer, target_peer)
		_:
			return "invalid_state"


func _on_channel_completed(record: Dictionary) -> void:
	if not _channels.has(record):
		return
	_channels.erase(record)
	_free_timer(record)
	var kind := String(record.get("kind", ""))
	var actor_peer := int(record.get("actor", 0))
	var target_peer := int(record.get("target", 0))
	# First finished timer wins: re-check permission and target state before
	# applying anything.
	var reason := _channel_cancel_reason(kind, actor_peer, target_peer)
	if reason != "":
		_notify(actor_peer, "Action cancelled (%s)" % reason)
		return
	match kind:
		KIND_REVIVE:
			_apply_revive(actor_peer, target_peer)
		KIND_FINISH:
			_apply_finish(target_peer)
		KIND_CUFF:
			_apply_cuff(actor_peer, target_peer)
		KIND_SEARCH:
			_open_search(actor_peer, target_peer)


func _on_channel_cancelled(record: Dictionary, reason: String) -> void:
	if _channels.has(record):
		_channels.erase(record)
	_free_timer(record)
	_notify(int(record.get("actor", 0)), "Action cancelled (%s)" % reason)


func _free_timer(record: Dictionary) -> void:
	var timer: Variant = record.get("timer")
	if timer is ChannelTimer and is_instance_valid(timer):
		(timer as ChannelTimer).queue_free()


func _cancel_channels(peer_id: int, actor_reason: String, target_reason: String) -> void:
	for record: Dictionary in _channels.duplicate():
		if int(record.get("actor", 0)) == peer_id:
			_cancel_record(record, actor_reason)
		elif int(record.get("target", 0)) == peer_id:
			_cancel_record(record, target_reason)


func _cancel_actor_channels(peer_id: int, reason: String) -> void:
	for record: Dictionary in _channels.duplicate():
		if int(record.get("actor", 0)) == peer_id:
			_cancel_record(record, reason)


func _cancel_record(record: Dictionary, reason: String) -> void:
	var timer: Variant = record.get("timer")
	if timer is ChannelTimer and is_instance_valid(timer) and (timer as ChannelTimer).is_active():
		(timer as ChannelTimer).cancel(reason)
		return
	# The channel node is already gone; drop the stale bookkeeping.
	if _channels.has(record):
		_channels.erase(record)


func _has_active_reviver(target_peer: int, exclude_actor: int = -1) -> bool:
	for record: Dictionary in _channels:
		if String(record.get("kind", "")) != KIND_REVIVE:
			continue
		if int(record.get("target", 0)) != target_peer:
			continue
		if int(record.get("actor", 0)) == exclude_actor:
			continue
		return true
	return false


# --- Checks ------------------------------------------------------------------

## Shared proximity/state check. Returns "" or one of the ChannelTimer reasons.
func _validate_interaction(actor_peer: int, target_peer: int) -> String:
	if actor_peer <= 0 or target_peer <= 0 or actor_peer == target_peer:
		return "invalid_state"
	var actor := _players.get_player(actor_peer)
	var target := _players.get_player(target_peer)
	if actor == null:
		return "actor_state"
	if target == null:
		return "target_state"
	var actor_instance := _players.current_instance(actor_peer)
	var target_instance := _players.current_instance(target_peer)
	if actor_instance == null or target_instance == null or actor_instance != target_instance:
		return "left_instance"
	var actor_controller := _controller_for(actor)
	var target_controller := _controller_for(target)
	if actor_controller == null or not actor_controller.is_alive():
		return "actor_state"
	if target_controller == null or not target_controller.is_downed():
		return "target_state"
	if actor.global_position.distance_to(target.global_position) > GameConst.INTERACT_RANGE:
		return "out_of_range"
	if not PlayerService.has_line_of_sight(actor_instance, actor, target):
		return "no_los"
	return ""


func _check_revive(actor_peer: int, target_peer: int) -> String:
	var reason := _validate_interaction(actor_peer, target_peer)
	if reason != "":
		return reason
	var actor_controller := _players.get_controller(actor_peer)
	var target_controller := _players.get_controller(target_peer)
	if actor_controller == null or target_controller == null:
		return "invalid_state"
	var same_party := _is_same_party(actor_peer, target_peer)
	if not can_revive(
		actor_controller.role,
		actor_controller.life_state,
		target_controller.role,
		target_controller.life_state,
		same_party,
		_has_active_reviver(target_peer, actor_peer)
	):
		return "invalid_state"
	return ""


func _check_finish(actor_peer: int, target_peer: int) -> String:
	var reason := _validate_interaction(actor_peer, target_peer)
	if reason != "":
		return reason
	var actor_controller := _players.get_controller(actor_peer)
	var target := _players.get_player(target_peer)
	var target_controller := _players.get_controller(target_peer)
	if actor_controller == null or target == null or target_controller == null:
		return "invalid_state"
	var attack_allowed := actor_controller.can_attack(
		target,
		_is_same_party(actor_peer, target_peer)
	)
	if not can_finish(attack_allowed, actor_controller.life_state, target_controller.life_state):
		return "invalid_state"
	return ""


func _check_cuff(actor_peer: int, target_peer: int) -> String:
	var reason := _validate_interaction(actor_peer, target_peer)
	if reason != "":
		return reason
	var actor_controller := _players.get_controller(actor_peer)
	var target_controller := _players.get_controller(target_peer)
	if actor_controller == null or target_controller == null:
		return "invalid_state"
	if not can_cuff(
		actor_controller.role,
		actor_controller.life_state,
		target_controller.role,
		target_controller.life_state
	):
		return "invalid_state"
	return ""


func _check_search(actor_peer: int, target_peer: int) -> String:
	var reason := _validate_interaction(actor_peer, target_peer)
	if reason != "":
		return reason
	var actor_controller := _players.get_controller(actor_peer)
	var target_controller := _players.get_controller(target_peer)
	if actor_controller == null or target_controller == null:
		return "invalid_state"
	if not can_search(
		actor_controller.role,
		actor_controller.life_state,
		target_controller.role,
		target_controller.life_state
	):
		return "invalid_state"
	return ""


func _is_same_party(actor_peer: int, target_peer: int) -> bool:
	var party := _parties.get_party(actor_peer)
	return party != null and party.has_member(target_peer)


# --- Applying the finished channels -----------------------------------------

func _apply_revive(actor_peer: int, target_peer: int) -> void:
	var target := _players.get_player(target_peer)
	var controller := _controller_for(target)
	if controller == null or not controller.is_downed():
		return
	controller.server_set_life_state(
		RoleController.LifeState.ALIVE,
		"revive",
		_now_ms()
	)
	_notify(target_peer, "You were revived")
	_notify(actor_peer, "Revived a teammate")
	var instance := _players.current_instance(target_peer)
	_players.run_extraction_if_overlapping(target, instance)


func _apply_finish(target_peer: int) -> void:
	var target := _players.get_player(target_peer)
	var controller := _controller_for(target)
	if controller == null or not controller.is_downed():
		return
	controller.server_set_life_state(
		RoleController.LifeState.DEAD,
		"finish",
		_now_ms()
	)
	_players.handle_player_death(target)


func _apply_cuff(actor_peer: int, target_peer: int) -> void:
	var cop := _players.get_player(actor_peer)
	var criminal := _players.get_player(target_peer)
	var cop_controller := _controller_for(cop)
	var criminal_controller := _controller_for(criminal)
	if cop_controller == null or criminal_controller == null:
		return
	if not can_cuff(
		cop_controller.role,
		cop_controller.life_state,
		criminal_controller.role,
		criminal_controller.life_state
	):
		return
	var result: Dictionary = criminal_controller.server_apply_surrender(cop_controller)
	if not bool(result.get("ok", false)):
		return
	# Cuffing is an arrest, never a death: stand the criminal up (the respawn
	# transfer then restores the Motel state), pay nothing to the cop here.
	criminal_controller.server_set_life_state(
		RoleController.LifeState.ALIVE,
		"cuff",
		_now_ms()
	)
	_notify(actor_peer, "Arrested a criminal (+$%d)" % int(result.get("reward", 0)))
	_notify(target_peer, "You were cuffed and sent to Motel")
	var instance := _players.current_instance(target_peer)
	var transferred: bool = _players.transfer_to_motel(target_peer)
	_players.refresh_police_vehicle(instance)
	if not transferred:
		_notify(target_peer, "Could not transfer to Motel")


func _open_search(actor_peer: int, target_peer: int) -> void:
	var reason := _check_search(actor_peer, target_peer)
	if reason != "":
		_notify(actor_peer, "Cannot search (%s)" % reason)
		return
	var target := _players.get_player(target_peer)
	var container := _body_container_for(target)
	if container == null:
		return
	if _sessions.has(actor_peer):
		_close_session(actor_peer, "invalid_state")
	container.add_viewer(actor_peer)
	_sessions[actor_peer] = {
		"target": target_peer,
		"instance_id": _instances.get_peer_instance_id(actor_peer),
	}
	_broadcast_contents(target_peer)
	_notify(actor_peer, "Searching body")


# --- Body containers / search sessions --------------------------------------

func _body_container_for(target: Node) -> LootContainer:
	if target == null or not is_instance_valid(target):
		return null
	var controller := _controller_for(target)
	if controller == null or not controller.is_downed():
		return null
	var target_peer := int(target.get("peer_id"))
	var existing := target.get_node_or_null(BODY_CONTAINER_NAME) as LootContainer
	if existing != null:
		existing.set_items(_body_items(controller))
		return existing
	var container := LootContainer.new()
	container.name = BODY_CONTAINER_NAME
	target.add_child(container)
	container.can_access = Callable(self, "_body_can_access").bind(target)
	container.on_take = Callable(self, "_body_on_take").bind(target)
	container.contents_changed.connect(_on_body_contents_changed.bind(target_peer))
	container.set_items(_body_items(controller))
	return container


## Search list: lootable bag items tagged "bag" then gear tagged "gear".
func _body_items(controller: PlayerRoleController) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: Dictionary in ItemUtils.lootable_only(controller.loot_bag):
		item["source"] = "bag"
		result.append(item)
	for item: Dictionary in ItemUtils.lootable_only(controller.equipped_gear):
		item["source"] = "gear"
		result.append(item)
	return result


func _body_can_access(actor_peer: int, body: Node) -> bool:
	if body == null or not is_instance_valid(body):
		return false
	return _check_search(actor_peer, int(body.get("peer_id"))) == ""


func _body_on_take(actor_peer: int, item: Dictionary, body: Node) -> Dictionary:
	if body == null or not is_instance_valid(body):
		return {"ok": false, "reason": "target_state"}
	var target_peer := int(body.get("peer_id"))
	if _check_search(actor_peer, target_peer) != "":
		return {"ok": false, "reason": "invalid_state"}
	var victim_controller := _controller_for(body)
	var taker_controller := _players.get_controller(actor_peer)
	if victim_controller == null or taker_controller == null:
		return {"ok": false, "reason": "invalid_state"}
	if (
		taker_controller.role != RoleController.Role.CRIMINAL
		and taker_controller.role != RoleController.Role.COP
	):
		return {"ok": false, "reason": "invalid_state"}
	var source := String(item.get("source", "bag"))
	if (
		taker_controller.role == RoleController.Role.CRIMINAL
		and source != "gear"
		and not taker_controller.can_fit_bag(String(item.get("id", "")))
	):
		return {"ok": false, "reason": "bag_full"}
	var removed: Dictionary = victim_controller.remove_item_by_uid(int(item.get("uid", 0)))
	if removed.is_empty():
		return {"ok": false, "reason": "invalid_state"}
	if taker_controller.role == RoleController.Role.CRIMINAL:
		taker_controller.receive_item(removed, source)
	else:
		# Seizure destroys the item; the cop is paid a fraction of bag value.
		taker_controller.cash += seizure_reward(removed, source)
	return {"ok": true, "item": removed}


func _on_body_contents_changed(target_peer: int) -> void:
	_broadcast_contents(target_peer)


func _broadcast_contents(target_peer: int) -> void:
	var target := _players.get_player(target_peer)
	if target == null:
		return
	var container := target.get_node_or_null(BODY_CONTAINER_NAME) as LootContainer
	if container == null:
		return
	var contents: Array[Dictionary] = container.items()
	for viewer: int in container.viewers():
		_send_client(viewer, "client_search_contents", [target_peer, contents])


func _close_sessions(peer_id: int, viewer_reason: String, body_reason: String) -> void:
	for viewer_value: Variant in _sessions.keys().duplicate():
		var viewer := int(viewer_value)
		var session: Dictionary = _sessions.get(viewer)
		if viewer == peer_id:
			_close_session(viewer, viewer_reason)
		elif int(session.get("target", 0)) == peer_id:
			_close_session(viewer, body_reason)


func _close_session(viewer_peer: int, reason: String) -> void:
	var session: Variant = _sessions.get(viewer_peer)
	if session == null:
		return
	var target_peer := int((session as Dictionary).get("target", 0))
	_sessions.erase(viewer_peer)
	var target := _players.get_player(target_peer)
	if target != null:
		var container := target.get_node_or_null(BODY_CONTAINER_NAME) as LootContainer
		if container != null:
			container.remove_viewer(viewer_peer)
	_send_client(viewer_peer, "client_search_closed", [target_peer, reason])


func _drop_body_container(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	var container := player.get_node_or_null(BODY_CONTAINER_NAME)
	if container != null:
		container.queue_free()


# --- Helpers -----------------------------------------------------------------

func _controller_for(player: Node) -> PlayerRoleController:
	if player == null or not is_instance_valid(player):
		return null
	if player is PlayerRoleController:
		return player as PlayerRoleController
	if player.has_method("get_role_controller"):
		return player.call("get_role_controller") as PlayerRoleController
	return player.get_node_or_null("PlayerRoleController") as PlayerRoleController


func _send_client(peer_id: int, method: StringName, args: Array) -> void:
	if _host != null:
		_host.call("_send_client_rpc", peer_id, method, args)


func _notify(peer_id: int, text: String) -> void:
	if _host != null:
		_host.call("_notify", peer_id, text)


func _now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)
