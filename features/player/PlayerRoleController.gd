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
signal life_state_changed(old_state: int, new_state: int, cause: String)
signal mask_channel_started(duration_seconds: float)
signal mask_channel_cancelled(reason: String)
signal inventory_changed

enum Role {
	CITIZEN,
	CRIMINAL,
	COP,
}

enum LifeState {
	ALIVE,
	DOWNED,
	DEAD,
}

## Every state transition must name one of these causes; the signal carries it.
const LIFE_CAUSES: Array[String] = [
	"damage",
	"bleedout",
	"finish",
	"disconnect",
	"redown",
	"revive",
	"cuff",
	"respawn",
]

const COP_LOADOUT: Array[Dictionary] = [
	{"id": "cop_pistol", "value": 0, "issued": true},
	{"id": "cop_radio", "value": 0, "issued": true},
	{"id": "cop_vest", "value": 0, "issued": true},
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
var _standalone_life_state: int = LifeState.ALIVE
var _standalone_downed_deadline_ms: int = 0
var _last_revive_ms: int = 0
var _pending_life_cause: String = ""
var _saved_civilian_gear: Array[Dictionary] = []
var _instance_ref: Node = null
var _mask_channel: ChannelTimer = null
var _item_uid_allocator: Callable = Callable()
var _fallback_item_uid: int = 1


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


## Replicated life state. Same read/write-through pattern as `role`.
var life_state: int:
	get:
		if is_instance_valid(_player):
			var value: Variant = _player.get("life_state")
			if value != null:
				return int(value)
		return _standalone_life_state
	set(value):
		if is_instance_valid(_player):
			_player.set("life_state", value)
		else:
			var old_state: int = _standalone_life_state
			_standalone_life_state = value
			handle_replicated_life_state(old_state, value)


## Replicated bleed-out deadline in unix milliseconds (0 when not downed).
var downed_deadline_ms: int:
	get:
		if is_instance_valid(_player):
			var value: Variant = _player.get("downed_deadline_ms")
			if value != null:
				return int(value)
		return _standalone_downed_deadline_ms
	set(value):
		if is_instance_valid(_player):
			_player.set("downed_deadline_ms", value)
		else:
			_standalone_downed_deadline_ms = value


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


# --- Life state --------------------------------------------------------------

## Server-side callback fired by Player when the replicated `life_state`
## property changes. Replicated updates on clients have no authoritative cause;
## the server emits the signal from the writer below through this same callback.
func handle_replicated_life_state(old_state: int, new_state: int) -> void:
	if old_state == new_state:
		return
	if _pending_life_cause == "":
		return
	life_state_changed.emit(old_state, new_state, _pending_life_cause)


## The single writer for life state. Idempotent: writing the current state is a
## no-op. All gameplay code must go through here.
func server_set_life_state(new_state: int, cause: String, now_ms: int) -> void:
	if not LIFE_CAUSES.has(cause):
		push_error("PlayerRoleController: invalid life cause '%s'" % cause)
		return
	if not _is_server_authority():
		return
	if life_state == new_state:
		return
	var old_state: int = life_state
	_apply_life_state_side_effects(new_state, cause, now_ms)
	_pending_life_cause = cause
	life_state = new_state
	_pending_life_cause = ""


## A hit on an already-downed player shortens the bleed-out timer and may kill
## them. Returns true when the penalty caused death.
func server_apply_downed_damage(now_ms: int) -> bool:
	if not _is_server_authority() or life_state != LifeState.DOWNED:
		return false
	downed_deadline_ms -= int(GameConst.DOWNED_HIT_PENALTY_SECONDS * 1000.0)
	if downed_deadline_ms <= now_ms:
		server_set_life_state(LifeState.DEAD, "bleedout", now_ms)
		return true
	return false


## True when the last revive happened inside the re-down window.
func was_recently_revived(now_ms: int) -> bool:
	if _last_revive_ms <= 0:
		return false
	return now_ms - _last_revive_ms <= int(GameConst.REDOWN_WINDOW_SECONDS * 1000.0)


func is_alive() -> bool:
	return life_state == LifeState.ALIVE


func is_downed() -> bool:
	return life_state == LifeState.DOWNED


func is_dead() -> bool:
	return life_state == LifeState.DEAD


func is_in_heist_map() -> bool:
	return _active_map_name() == GameConst.MAP_LOOTY_BAY


func _apply_life_state_side_effects(new_state: int, cause: String, now_ms: int) -> void:
	cancel_mask("invalid_state")
	match new_state:
		LifeState.DOWNED:
			downed_deadline_ms = now_ms + int(GameConst.DOWNED_BLEEDOUT_SECONDS * 1000.0)
			_set_health(0)
		LifeState.ALIVE:
			downed_deadline_ms = 0
			if cause == "revive":
				_last_revive_ms = now_ms
				var revived_health: int = int(
					round(float(GameConst.PLAYER_MAX_HEALTH) * GameConst.REVIVE_HP_RATIO)
				)
				_set_health(maxi(revived_health, 1))
			else:
				_set_health(GameConst.PLAYER_MAX_HEALTH)
		LifeState.DEAD:
			downed_deadline_ms = 0
			_set_health(0)


func _set_health(value: int) -> void:
	if is_instance_valid(_player):
		_player.set("health", value)


func _is_server_authority() -> bool:
	# Standalone controllers are used by pure unit tests (no SceneTree); inside
	# a tree only the server may write authoritative state.
	if not is_inside_tree():
		return true
	return multiplayer.is_server()


# --- Combat rules ------------------------------------------------------------

## Attack permission matrix. Context is any instance that is not Motel's
## safezone and is not House/Center; PvP only exists in LootyBay. Party
## friendly fire is off by default (`same_party`).
static func can_attack_roles(
	attacker_role: int,
	target_role: int,
	p_map_name: String,
	p_safezone: bool,
	same_party: bool = false
) -> bool:
	if same_party:
		return false
	if GameInstance.weapons_locked_for(p_map_name, p_safezone):
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


func can_attack(target: Node, same_party: bool = false) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target == _player:
		return false
	var target_role: int = -1
	if target is PlayerRoleController:
		target_role = (target as PlayerRoleController).role
	elif target.get_node_or_null("PlayerRoleController") != null:
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
	return can_attack_roles(role, target_role, context_map, context_safezone, same_party)


# --- Mask channel ------------------------------------------------------------

## Starts the 3 s mask channel. Only in LootyBay, only for a live CITIZEN.
func server_try_mask() -> bool:
	if not _is_server_context():
		return false
	if role != Role.CITIZEN or is_mask_channel_active() or life_state != LifeState.ALIVE:
		return false
	if _active_map_name() != GameConst.MAP_LOOTY_BAY:
		return false
	if not is_instance_valid(_player):
		return false
	_mask_channel = ChannelTimer.new()
	_mask_channel.name = "MaskChannelTimer"
	_player.add_child(_mask_channel)
	_mask_channel.completed.connect(_on_mask_channel_completed)
	_mask_channel.cancelled.connect(_on_mask_channel_cancelled)
	_mask_channel.start(
		GameConst.MASK_CHANNEL_SECONDS,
		_player,
		GameConst.MASK_MOVE_CANCEL_DISTANCE,
		Callable(self, "_mask_cancel_check")
	)
	mask_channel_started.emit(GameConst.MASK_CHANNEL_SECONDS)
	return true


func cancel_mask(reason: String) -> void:
	if _mask_channel == null:
		return
	_mask_channel.cancel(reason)


func is_mask_channel_active() -> bool:
	return _mask_channel != null and _mask_channel.is_active()


func notify_damage() -> void:
	cancel_mask("damaged")


## Rules checked every tick by ChannelTimer; reason strings match its contract.
func _mask_cancel_check() -> String:
	if not _is_server_context() or not is_instance_valid(_player):
		return "invalid_state"
	if life_state != LifeState.ALIVE or role != Role.CITIZEN:
		return "invalid_state"
	if _active_map_name() != GameConst.MAP_LOOTY_BAY:
		return "left_instance"
	return ""


func _on_mask_channel_completed() -> void:
	var channel := _mask_channel
	_mask_channel = null
	if is_instance_valid(channel):
		channel.queue_free()
	# Re-check after the hold: the world may have changed while the last tick
	# was in flight (first finished timer wins, later timers fail here).
	if role != Role.CITIZEN or life_state != LifeState.ALIVE:
		mask_channel_cancelled.emit("invalid_state")
		return
	if _active_map_name() != GameConst.MAP_LOOTY_BAY:
		mask_channel_cancelled.emit("left_instance")
		return
	_change_role(Role.CRIMINAL)


func _on_mask_channel_cancelled(reason: String) -> void:
	var channel := _mask_channel
	_mask_channel = null
	if is_instance_valid(channel):
		channel.queue_free()
	# The mask publicly only ever reports its four documented reasons.
	var mask_reason: String = reason
	if mask_reason != "moved" and mask_reason != "damaged" and mask_reason != "left_instance":
		mask_reason = "invalid_state"
	mask_channel_cancelled.emit(mask_reason)


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
	for loadout_item: Dictionary in COP_LOADOUT:
		equipped_gear.append(
			ItemUtils.make_item(
				_allocate_item_uid(),
				String(loadout_item.get("id", "")),
				int(loadout_item.get("value", 0)),
				bool(loadout_item.get("issued", true))
			)
		)
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
## CRIMINAL -> CITIZEN here is the successful extraction; surrender, cuff and
## death also remove the mask. COP players are taken off duty.
func server_on_extraction() -> void:
	cancel_mask("invalid_state")
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
## CITIZEN: keeps everything. CRIMINAL: drops bag + gear and respawns as a
## CITIZEN. COP: issued gear is destroyed (never dropped), every non-issued item
## (bag and civilian gear) drops, and the player respawns as a CITIZEN off duty.
static func death_outcome(death_role: int, loot_bag_data: Array, gear_data: Array) -> Dictionary:
	var result: Dictionary = {
		"drops": false,
		"loot": [],
		"gear": [],
		"respawn_map": GameConst.MAP_MOTEL,
		"respawn_role": Role.CITIZEN,
	}
	match death_role:
		Role.CRIMINAL:
			result["drops"] = true
			result["loot"] = ItemUtils.duplicate_items(loot_bag_data)
			result["gear"] = ItemUtils.duplicate_items(gear_data)
		Role.COP:
			# Issued equipment is state property, not loot.
			var dropped_gear: Array[Dictionary] = []
			for item: Dictionary in ItemUtils.duplicate_items(gear_data):
				if not bool(item.get("issued", false)):
					dropped_gear.append(item)
			var dropped_loot: Array[Dictionary] = ItemUtils.duplicate_items(loot_bag_data)
			result["loot"] = dropped_loot
			result["gear"] = dropped_gear
			result["drops"] = not dropped_loot.is_empty() or not dropped_gear.is_empty()
		Role.CITIZEN:
			pass
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
	cancel_mask("invalid_state")
	_change_role(Role.CITIZEN)
	inventory_changed.emit()
	return result


## Applies the death mutations and returns what the world must drop.
func server_apply_death() -> Dictionary:
	var gear_for_outcome: Array = ItemUtils.duplicate_items(equipped_gear)
	if role == Role.COP:
		# Going off duty during death restores saved civilian gear, which then
		# drops like any other non-issued item.
		gear_for_outcome.append_array(ItemUtils.duplicate_items(_saved_civilian_gear))
	var result: Dictionary = death_outcome(role, loot_bag, gear_for_outcome)
	match role:
		Role.CRIMINAL:
			loot_bag.clear()
			equipped_gear.clear()
		Role.COP:
			cop_on_duty = false
			loot_bag.clear()
			equipped_gear.clear()
			_saved_civilian_gear.clear()
		Role.CITIZEN:
			pass
	_change_role(int(result.get("respawn_role", Role.CITIZEN)))
	notoriety = 0.0
	cancel_mask("invalid_state")
	inventory_changed.emit()
	return result


## Called by PlayerService before a transfer snapshot/despawn.
func server_prepare_leave_instance() -> void:
	cancel_mask("left_instance")
	in_police_station = false
	if cop_on_duty:
		server_go_off_duty(true)
	_instance_ref = null


# --- Inventory / notoriety ---------------------------------------------------

## Wires the uid counter owned by `PlayerService`. Standalone test controllers
## fall back to a local counter so the item rules stay unit-testable.
func set_item_uid_allocator(allocator: Callable) -> void:
	_item_uid_allocator = allocator


## Adds one new bag item. Kept as a convenience wrapper; callers that transfer
## an existing item use `receive_item()` so the uid survives the move.
func grant_loot(loot_id: String, value: int, issued: bool = false) -> Dictionary:
	var item := ItemUtils.make_item(_allocate_item_uid(), loot_id, value, issued)
	# -1 when the bag is full; callers check can_fit_bag() first.
	item["slot"] = find_fit(loot_bag, ItemUtils.size_of(loot_id))
	loot_bag.append(item)
	if not issued:
		notoriety += float(int(item["value"]))
	inventory_changed.emit()
	return item


## Adds one new equipped item (no notoriety; gear does not raise it).
func grant_gear(gear_id: String, value: int, issued: bool = false) -> Dictionary:
	var item := ItemUtils.make_item(_allocate_item_uid(), gear_id, value, issued)
	equipped_gear.append(item)
	inventory_changed.emit()
	return item


## Transfers an existing item from another inventory, keeping its uid.
## `source` is "bag" or "gear": bag items raise the new owner's notoriety.
func receive_item(item: Dictionary, source: String) -> Dictionary:
	if item.is_empty():
		return {}
	var received: Dictionary = item.duplicate(true)
	received.erase("source")
	if int(received.get("uid", 0)) <= 0:
		received["uid"] = _allocate_item_uid()
	if source == "gear":
		received.erase("slot")
		equipped_gear.append(received)
	else:
		# -1 when the bag is full; callers check can_fit_bag() first.
		received["slot"] = find_fit(loot_bag, ItemUtils.size_of(String(received.get("id", ""))))
		loot_bag.append(received)
		if not bool(received.get("issued", false)):
			notoriety += float(int(received.get("value", 0)))
	inventory_changed.emit()
	return received


## Grid cells covered by an item of `size` whose top-left cell is `slot`.
## Returns [] when the item would leave the grid.
static func footprint(slot: int, size: Vector2i) -> Array[int]:
	var cells: Array[int] = []
	var columns: int = GameConst.INVENTORY_BAG_COLUMNS
	var rows: int = GameConst.INVENTORY_BAG_SLOTS / GameConst.INVENTORY_BAG_COLUMNS
	if slot < 0:
		return cells
	var col: int = slot % columns
	var row: int = slot / columns
	if col + size.x > columns or row + size.y > rows:
		return cells
	for dy: int in range(size.y):
		for dx: int in range(size.x):
			cells.append((row + dy) * columns + (col + dx))
	return cells


## True when an item of `size` fits at `slot` without covering any item of
## `bag` (items whose uid is in `ignore_uids` do not count).
static func fits_at(bag: Array, slot: int, size: Vector2i, ignore_uids: Array) -> bool:
	var cells := footprint(slot, size)
	if cells.is_empty():
		return false
	for item: Dictionary in bag:
		if ignore_uids.has(int(item.get("uid", 0))):
			continue
		var covered := footprint(int(item.get("slot", -1)), ItemUtils.size_of(String(item.get("id", ""))))
		for cell: int in covered:
			if cells.has(cell):
				return false
	return true


## First slot where an item of `size` fits in `bag`, or -1 when none does.
static func find_fit(bag: Array, size: Vector2i) -> int:
	for slot: int in range(GameConst.INVENTORY_BAG_SLOTS):
		if fits_at(bag, slot, size, []):
			return slot
	return -1


## True when an item with that id still fits somewhere in the loot bag.
func can_fit_bag(item_id: String) -> bool:
	return find_fit(loot_bag, ItemUtils.size_of(item_id)) != -1


## Moves a bag item to a grid slot; swaps with the item already there.
## Returns false (no change) for an unknown uid or a slot outside the grid.
func move_bag_item(uid: int, slot: int) -> bool:
	if slot < 0 or slot >= GameConst.INVENTORY_BAG_SLOTS:
		return false
	var moving: Dictionary = {}
	for item: Dictionary in loot_bag:
		if int(item.get("uid", 0)) == uid:
			moving = item
			break
	if moving.is_empty():
		return false
	var old_slot: int = int(moving.get("slot", -1))
	if old_slot == slot:
		return true
	var size := ItemUtils.size_of(String(moving.get("id", "")))
	if fits_at(loot_bag, slot, size, [uid]):
		moving["slot"] = slot
		inventory_changed.emit()
		return true
	var a := footprint(slot, size)
	var overlapping: Array[Dictionary] = []
	for item: Dictionary in loot_bag:
		if is_same(item, moving):
			continue
		var covered := footprint(int(item.get("slot", -1)), ItemUtils.size_of(String(item.get("id", ""))))
		for cell: int in covered:
			if a.has(cell):
				overlapping.append(item)
				break
	if overlapping.size() != 1:
		return false
	var other: Dictionary = overlapping[0]
	var other_uid: int = int(other.get("uid", 0))
	var other_size := ItemUtils.size_of(String(other.get("id", "")))
	var b := footprint(old_slot, other_size)
	if a.is_empty() or b.is_empty():
		return false
	for cell: int in a:
		if b.has(cell):
			return false
	if not fits_at(loot_bag, slot, size, [uid, other_uid]):
		return false
	if not fits_at(loot_bag, old_slot, other_size, [uid, other_uid]):
		return false
	other["slot"] = old_slot
	moving["slot"] = slot
	inventory_changed.emit()
	return true


## The victim's notoriety falls by the value of a removed bag item (clamped at 0);
## gear removal leaves notoriety unchanged.
func remove_item_by_uid(uid: int) -> Dictionary:
	var removed: Dictionary = ItemUtils.remove_by_uid(loot_bag, uid)
	var from_bag := not removed.is_empty()
	if not from_bag:
		removed = ItemUtils.remove_by_uid(equipped_gear, uid)
	if removed.is_empty():
		return {}
	if from_bag:
		notoriety = maxf(notoriety - float(int(removed.get("value", 0))), 0.0)
	inventory_changed.emit()
	return removed


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
	loot_bag = _items_with_uids(ItemUtils.duplicate_items(state.get("loot_bag", [])))
	equipped_gear = _items_with_uids(ItemUtils.duplicate_items(state.get("equipped_gear", [])))
	_saved_civilian_gear = _items_with_uids(
		ItemUtils.duplicate_items(state.get("saved_civilian_gear", []))
	)
	notoriety = float(state.get("notoriety", 0.0))
	cash = int(state.get("cash", 0))
	cop_on_duty = bool(state.get("cop_on_duty", false))
	inventory_changed.emit()


# --- Internal ----------------------------------------------------------------

## Assigns uids to items that arrived without one (old transfer snapshots).
func _items_with_uids(items: Array[Dictionary]) -> Array[Dictionary]:
	for item: Dictionary in items:
		if int(item.get("uid", 0)) <= 0:
			item["uid"] = _allocate_item_uid()
	return items


func _allocate_item_uid() -> int:
	if _item_uid_allocator.is_valid():
		return int(_item_uid_allocator.call())
	var uid: int = _fallback_item_uid
	_fallback_item_uid += 1
	return uid


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
