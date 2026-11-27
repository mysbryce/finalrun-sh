class_name Hud
extends CanvasLayer
## Client HUD built in code. Main feeds it the local player and ServerManager events;
## it never talks to the network.


static func role_text(role: int) -> String:
	match role:
		PlayerRoleController.Role.CITIZEN:
			return "CITIZEN"
		PlayerRoleController.Role.CRIMINAL:
			return "CRIMINAL"
		PlayerRoleController.Role.COP:
			return "COP"
		_:
			return "?"


static func life_text(life_state: int) -> String:
	match life_state:
		PlayerRoleController.LifeState.ALIVE:
			return "ALIVE"
		PlayerRoleController.LifeState.DOWNED:
			return "DOWNED"
		PlayerRoleController.LifeState.DEAD:
			return "DEAD"
		_:
			return "?"


static func money_text(state: Dictionary) -> String:
	return "Cash $%d | Bag $%d | Notoriety %d" % [
		int(state.get("cash", 0)),
		int(state.get("bag_value", 0)),
		int(state.get("notoriety", 0)),
	]


static func seconds_left(deadline_ms: int, now_ms: int) -> int:
	return maxi(0, ceili(float(deadline_ms - now_ms) / 1000.0))


static func push_notification(list: Array, text: String, now_ms: int) -> Array:
	var result: Array = list.duplicate()
	result.append({"text": text, "expires_ms": now_ms + GameConst.HUD_NOTIFICATION_MS})
	while result.size() > GameConst.HUD_MAX_NOTIFICATIONS:
		result.pop_front()
	return result


static func prune_notifications(list: Array, now_ms: int) -> Array:
	var result: Array = []
	for entry: Dictionary in list:
		if int(entry.get("expires_ms", 0)) > now_ms:
			result.append(entry)
	return result


var _player: Node3D = null
var _money: Dictionary = {}
var _mask_end_ms: int = 0
var _notifications: Array = []

var _status_label: Label = null
var _money_label: Label = null
var _timer_label: Label = null
var _notify_label: Label = null
var _prompt_label: Label = null


func _ready() -> void:
	_status_label = _make_label()
	_status_label.position = Vector2(GameConst.HUD_MARGIN, GameConst.HUD_MARGIN)
	add_child(_status_label)

	_money_label = _make_label()
	_money_label.position = Vector2(GameConst.HUD_MARGIN, GameConst.HUD_MARGIN + 28)
	add_child(_money_label)

	_timer_label = _make_label()
	_timer_label.position = Vector2(GameConst.HUD_MARGIN, GameConst.HUD_MARGIN + 56)
	add_child(_timer_label)

	_notify_label = _make_label()
	_notify_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_notify_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_notify_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_notify_label.offset_left = -GameConst.HUD_MARGIN
	_notify_label.offset_top = GameConst.HUD_MARGIN
	_notify_label.offset_right = -GameConst.HUD_MARGIN
	_notify_label.offset_bottom = GameConst.HUD_MARGIN
	add_child(_notify_label)

	_prompt_label = _make_label()
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_label.offset_left = 0.0
	_prompt_label.offset_top = -GameConst.HUD_MARGIN * 4
	_prompt_label.offset_right = 0.0
	_prompt_label.offset_bottom = -GameConst.HUD_MARGIN * 4
	add_child(_prompt_label)


func _make_label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", GameConst.HUD_FONT_SIZE)
	return label


func set_player(player: Node3D) -> void:
	_player = player


func set_money(state: Dictionary) -> void:
	_money = state.duplicate()


func set_mask_channel(seconds: float, now_ms: int) -> void:
	_mask_end_ms = now_ms + int(seconds * 1000.0) if seconds > 0.0 else 0


func add_notification(text: String, now_ms: int) -> void:
	_notifications = push_notification(_notifications, text, now_ms)


func _process(_delta: float) -> void:
	var now_ms := int(Time.get_unix_time_from_system() * 1000.0)
	if _player == null or not is_instance_valid(_player):
		_status_label.text = ""
		_timer_label.text = ""
		_prompt_label.text = ""
		_notifications = prune_notifications(_notifications, now_ms)
		_notify_label.text = _joined_notifications()
		return
	var role := int(_player.get("role"))
	var life := int(_player.get("life_state"))
	_status_label.text = "%s | %s" % [role_text(role), life_text(life)]
	_money_label.text = money_text(_money)
	if life == PlayerRoleController.LifeState.DOWNED:
		_timer_label.text = "Bleeding out: %d s" % seconds_left(int(_player.get("downed_deadline_ms")), now_ms)
	elif _mask_end_ms > now_ms:
		_timer_label.text = "Masking: %d s" % seconds_left(_mask_end_ms, now_ms)
	else:
		_timer_label.text = ""
	var area := InteractArea.nearest(_player, GameConst.INTERACT_RANGE)
	_prompt_label.text = area.prompt if area != null and life == PlayerRoleController.LifeState.ALIVE else ""
	_notifications = prune_notifications(_notifications, now_ms)
	_notify_label.text = _joined_notifications()


func _joined_notifications() -> String:
	var texts: Array[String] = []
	for entry: Dictionary in _notifications:
		texts.append(String(entry.get("text", "")))
	return "\n".join(texts)
