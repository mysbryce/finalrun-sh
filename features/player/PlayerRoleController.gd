class_name PlayerRoleController
extends Node
## Server-authoritative role, mask channel, inventory, notoriety, cop duty and
## death/surrender rules.
##
## The replicated role value lives on the Player root (`Player.role`) so the root
## MultiplayerSynchronizer can replicate it directly. This controller reads and
## writes through that property when it is bound to a player, and falls back to
## a local value when used standalone (handy for headless unit tests).

signal role_changed(old_role: int, new_role: int)
signal mask_channel_started(duration_seconds: float)
signal mask_channel_cancelled(reason: String)
signal inventory_changed

enum Role {
	CITIZEN,
	CRIMINAL,
	COP,
}

const COP_LOADOUT: Array[Dictionary] = [
	{"id": "cop_pistol", "value": 0},
	{"id": "cop_radio", "value": 0},
	{"id": "cop_vest", "value": 0},
]

var map_name: String = ""
var safezone: bool = false
var in_police_station: bool = false
var cop_on_duty: bool = false
var notoriety: float = 0.0
var cash: int = 0
var loot_bag: Array[Dictionary] = []
var equipped_gear: Array[Dictionary] = []

var _player: Node = null
var _standalone_role: int = Role.CITIZEN
var _saved_civilian_gear: Array[Dictionary] = []
var _instance_ref: Node = null
var _mask_timer: Timer = null
var _mask_active: bool = false
var _mask_start_position: Vector3 = Vector3.ZERO


## Replicated role. Reads/writes the Player root property when bound.
var role: int:
	get:
		if is_instance_valid(_player):
			var value: Variant = _player.get("role")
			if value != null:
				return int(value)
		return _standalone_role
	set(value):
		if is_instance_valid(_player):
			_player.set("role", value)
		else:
			var old_role: int = _standalone_role
			_standalone_role = value
			if old_role != value:
				role_changed.emit(old_role, value)


## Default persisted role state for a newly connected peer.
static func default_player_state() -> Dictionary:
	return {
		"role": Role.CITIZEN,
		"loot_bag": [],
		"equipped_gear": [],
		"saved_civilian_gear": [],
		"notoriety": 0.0,
		"cash": 0,
		"cop_on_duty": false,
	}


## Called by Player._ready.
func bind_player(player: Node) -> void:
	_player = player


## Server-side spawn/transfer restore.
func configure_context(instance_node: Node, p_map_name: String, p_safezone: bool) -> void:
	_instance_ref = instance_node
	map_name = p_map_name
	safezone = p_safezone
	in_police_station = false


func get_player_node() -> Node:
	return _player


func set_in_police_station(inside: bool) -> void:
	in_police_station = inside


## Callback fired by Player when the replicated `role` property changes.
func handle_replicated_role(old_role: int, new_role: int) -> void:
	if old_role == new_role:
		return
	if new_role != Role.COP:
		cop_on_duty = false
	role_changed.emit(old_role, new_role)


# --- Combat rules ------------------------------------------------------------

## Attack permission matrix. Context is any instance that is not Motel's
## safezone and is not House/Center; PvP only exists in LootyBay.
static func can_attack_roles(
	attacker_role: int,
	target_role: int,
	p_map_name: String,
	p_safezone: bool
) -> bool:
	if p_safezone or p_map_name != GameConst.MAP_LOOTY_BAY:
		return false
	match attacker_role:
		Role.CITIZEN:
			return false
		Role.CRIMINAL:
			return target_role == Role.CRIMINAL or target_role == Role.COP
		Role.COP:
			return target_role == Role.CRIMINAL
		_:
			return false


func can_attack(target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target == _player:
		return false
	var target_role: int = -1
	if target is PlayerRoleController:
		target_role = (target as PlayerRoleController).role
	elif target.has_node_or_null("PlayerRoleController") != null:
		var target_controller := target.get_node_or_null("PlayerRoleController")
		var value: Variant = target_controller.get("role")
		if value != null:
			target_role = int(value)
	if target_role < 0:
		return false
	var context_map: String = map_name
	var context_safezone: bool = safezone
	if is_instance_valid(_instance_ref):
		var ref_map: Variant = _instance_ref.get("map_name")
		var ref_safezone: Variant = _instance_ref.get("safezone")
		if ref_map != null:
			context_map = String(ref_map)
		if ref_safezone != null:
			context_safezone = bool(ref_safezone)
	return can_attack_roles(role, target_role, context_map, context_safezone)


# --- Mask channel ------------------------------------------------------------

## Starts the 3 s mask channel. Only in LootyBay, only for a CITIZEN.
func server_try_mask() -> bool:
	if not _is_server_context():
		return false
	if role != Role.CITIZEN or _mask_active:
		return false
	if _active_map_name() != GameConst.MAP_LOOTY_BAY:
		return false
	if not is_instance_valid(_player):
		return false
	_mask_active = true
	_mask_start_position = _player.global_position
	_ensure_mask_timer()
	_mask_timer.start(GameConst.MASK_CHANNEL_SECONDS)
	mask_channel_started.emit(GameConst.MASK_CHANNEL_SECONDS)
	return true


func cancel_mask(reason: String) -> void:
	if not _mask_active:
		return
	_mask_active = false
	if _mask_timer != null:
		_mask_timer.stop()
	mask_channel_cancelled.emit(reason)


func is_mask_channel_active() -> bool:
	return _mask_active


func notify_damage() -> void:
	cancel_mask("damage")


func _process(_delta: float) -> void:
	if not _mask_active or not is_instance_valid(_player) or not _is_server_context():
		return
	if _player.global_position.distance_to(_mask_start_position) > GameConst.MASK_MOVE_CANCEL_DISTANCE:
		cancel_mask("moved")
	elif _active_map_name() != GameConst.MAP_LOOTY_BAY:
		cancel_mask("left_instance")


func _ensure_mask_timer() -> void:
	if _mask_timer != null:
		return
	_mask_timer = Timer.new()
	_mask_timer.name = "MaskChannelTimer"
	_mask_timer.one_shot = true
	add_child(_mask_timer)
	_mask_timer.timeout.connect(_on_mask_timer_timeout)


func _on_mask_timer_timeout() -> void:
	if not _mask_active:
		return
	_mask_active = false
	if role != Role.CITIZEN or _active_map_name() != GameConst.MAP_LOOTY_BAY:
		mask_channel_cancelled.emit("invalid_state")
		return
	if is_instance_valid(_player) and _player.global_position.distance_to(_mask_start_position) > GameConst.MASK_MOVE_CANCEL_DISTANCE:
		mask_channel_cancelled.emit("moved")
		return
	_change_role(Role.CRIMINAL)


# --- Cop duty ----------------------------------------------------------------

func server_go_on_duty() -> bool:
	if not _is_server_context():
		return false
	if role != Role.CITIZEN or cop_on_duty:
		return false
	if _active_map_name() != GameConst.MAP_LOOTY_BAY or not in_police_station:
		return false
	_saved_civilian_gear = ItemUtils.duplicate_items(equipped_gear)
	equipped_gear.clear()
	for item: Dictionary in COP_LOADOUT:
		equipped_gear.append(item.duplicate(true))
	cop_on_duty = true
	_change_role(Role.COP)
	inventory_changed.emit()
	return true


func server_go_off_duty(force: bool = false) -> bool:
	if not _is_server_context():
		return false
	if not cop_on_duty and role != Role.COP:
		return false
	if not force:
		if _active_map_name() != GameConst.MAP_LOOTY_BAY or not in_police_station:
			return false
	cop_on_duty = false
	equipped_gear.clear()
	for item: Dictionary in _saved_civilian_gear:
		equipped_gear.append(item.duplicate(true))
	_saved_civilian_gear.clear()
	if role == Role.COP:
		_change_role(Role.CITIZEN)
	inventory_changed.emit()
	return true


# --- Extraction / surrender / death -----------------------------------------

## Called by PlayerService when the player exits LootyBay through ExtractZone.
## CRIMINAL -> CITIZEN is one of the only two ways to lose the mask (the other
## being surrender). COP players are taken off duty.
func server_on_extraction() -> void:
	cancel_mask("extraction")
	if role == Role.COP:
		server_go_off_duty(true)
	if role == Role.CRIMINAL:
		_change_role(Role.CITIZEN)


## Pure surrender outcome for the given roles and gross loot value.
## Returns {"ok", "reward", "loot_value"} without mutating either player.
static func surrender_outcome(criminal_role: int, cop_role: int, gross_value: int) -> Dictionary:
	var result: Dictionary = {"ok": false, "reward": 0, "loot_value": 0}
	if criminal_role != Role.CRIMINAL or cop_role != Role.COP:
		return result
	result["ok"] = true
	result["loot_value"] = gross_value
	result["reward"] = int(round(float(gross_value) * GameConst.SURRENDER_COP_REWARD_RATIO))
	return result


## Pure death outcome: what should drop and where the player respawns.
## CITIZEN: keeps everything. CRIMINAL: drops bag + gear, keeps the role (the
## mask can only be removed by extraction or surrender). COP: drops nothing,
## loses free-issue gear and goes off duty.
static func death_outcome(death_role: int, loot_bag_data: Array, gear_data: Array) -> Dictionary:
	var result: Dictionary = {
		"drops": false,
		"loot": [],
		"gear": [],
		"respawn_map": GameConst.MAP_MOTEL,
	}
	if death_role == Role.CRIMINAL:
		result["drops"] = true
		result["loot"] = ItemUtils.duplicate_items(loot_bag_data)
		result["gear"] = ItemUtils.duplicate_items(gear_data)
	return result


## Validates and applies a surrender reward. The proximity / line-of-sight
## check is done by PlayerService; this method owns the inventory and role rules.
## Returns {"ok", "reward", "loot_value"}.
func server_apply_surrender(cop: PlayerRoleController) -> Dictionary:
	if cop == null or not is_instance_valid(cop):
		return {"ok": false, "reward": 0, "loot_value": 0}
	var result: Dictionary = surrender_outcome(role, cop.role, loot_value())
	if not bool(result.get("ok", false)):
		return result
	cop.cash += int(result.get("reward", 0))
	loot_bag.clear()
	notoriety = 0.0
	cancel_mask("surrender")
	_change_role(Role.CITIZEN)
	inventory_changed.emit()
	return result


## Applies the death mutations and returns what the world must drop.
func server_apply_death() -> Dictionary:
	var result: Dictionary = death_outcome(role, loot_bag, equipped_gear)
	match role:
		Role.CRIMINAL:
			loot_bag.clear()
			equipped_gear.clear()
		Role.COP:
			cop_on_duty = false
			equipped_gear.clear()
			_saved_civilian_gear.clear()
			_change_role(Role.CITIZEN)
		Role.CITIZEN:
			pass
	notoriety = 0.0
	cancel_mask("death")
	inventory_changed.emit()
	return result


## Called by PlayerService before a transfer snapshot/despawn.
func server_prepare_leave_instance() -> void:
	cancel_mask("leave_instance")
	in_police_station = false
	if cop_on_duty:
		server_go_off_duty(true)
	_instance_ref = null


# --- Inventory / notoriety ---------------------------------------------------

func grant_loot(loot_id: String, value: int) -> void:
	if value < 0:
		value = 0
	loot_bag.append({"id": loot_id, "value": value})
	notoriety += float(value)
	inventory_changed.emit()


func grant_gear(gear_id: String, value: int) -> void:
	if value < 0:
		value = 0
	equipped_gear.append({"id": gear_id, "value": value})
	inventory_changed.emit()


func loot_value() -> int:
	var total: int = 0
	for item: Dictionary in loot_bag:
		total += int(item.get("value", 0))
	return total


func gear_value() -> int:
	var total: int = 0
	for item: Dictionary in equipped_gear:
		total += int(item.get("value", 0))
	return total


## Pure sale multiplier for a notoriety amount (max 2.5x at the cap).
static func sell_multiplier(notoriety_value: float) -> float:
	return 1.0 + minf(notoriety_value / GameConst.NOTORIETY_DIVISOR, GameConst.NOTORIETY_MAX_BONUS)


## Sells the whole bag. Notoriety resets on a completed sale (documented rule).
func server_sell_loot() -> int:
	if loot_bag.is_empty():
		notoriety = 0.0
		return 0
	var earned: int = int(round(float(loot_value()) * sell_multiplier(notoriety)))
	cash += earned
	loot_bag.clear()
	notoriety = 0.0
	inventory_changed.emit()
	return earned


func export_state() -> Dictionary:
	return {
		"role": role,
		"loot_bag": ItemUtils.duplicate_items(loot_bag),
		"equipped_gear": ItemUtils.duplicate_items(equipped_gear),
		"saved_civilian_gear": ItemUtils.duplicate_items(_saved_civilian_gear),
		"notoriety": notoriety,
		"cash": cash,
		"cop_on_duty": cop_on_duty,
	}


func apply_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	if state.has("role"):
		_change_role(int(state["role"]))
	loot_bag = ItemUtils.duplicate_items(state.get("loot_bag", []))
	equipped_gear = ItemUtils.duplicate_items(state.get("equipped_gear", []))
	_saved_civilian_gear = ItemUtils.duplicate_items(state.get("saved_civilian_gear", []))
	notoriety = float(state.get("notoriety", 0.0))
	cash = int(state.get("cash", 0))
	cop_on_duty = bool(state.get("cop_on_duty", false))
	inventory_changed.emit()


# --- Internal ----------------------------------------------------------------

func _change_role(new_role: int) -> void:
	if role == new_role:
		return
	role = new_role


func _is_server_context() -> bool:
	if not is_inside_tree():
		return false
	return multiplayer.is_server()


func _active_map_name() -> String:
	if is_instance_valid(_instance_ref):
		var value: Variant = _instance_ref.get("map_name")
		if value != null:
			return String(value)
	return map_name
