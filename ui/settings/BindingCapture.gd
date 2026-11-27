class_name BindingCapture
extends RefCounted
## One settings.capture request: feeds raw input events and decides when a
## binding code (or null) is captured. Pure: Main owns the instance, consumes
## events and sends the reply. Timestamps come from Time.get_ticks_msec().

const _MODIFIER_KEYS := [KEY_SHIFT, KEY_CTRL, KEY_ALT]
const _WHEEL_BUTTONS := [
	MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT,
]

var request_id: int
var key: String

var _started_ms: int
## Bare code of the last pressed modifier key ("" = none).
var _pending_modifier: String = ""


func _init(id: int, setting_key: String, now_ms: int) -> void:
	request_id = id
	key = setting_key
	_started_ms = now_ms


## {done, binding (code or null), consume} for one event.
func feed(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return _feed_key(event as InputEventKey)
	if event is InputEventMouseButton:
		return _feed_button(event as InputEventMouseButton)
	return _result(false, null, false)


func timed_out(now_ms: int) -> bool:
	return now_ms - _started_ms >= GameConst.CAPTURE_TIMEOUT_MS


func _feed_key(event: InputEventKey) -> Dictionary:
	var keycode := int(event.physical_keycode)
	if event.echo or keycode == KEY_META:
		return _result(false, null, true)
	var is_modifier := _MODIFIER_KEYS.has(keycode)
	if not event.pressed:
		if is_modifier and InputBindings.code_from_event(event) == _pending_modifier:
			return _result(true, _pending_modifier, true)
		return _result(false, null, true)
	if keycode == KEY_ESCAPE:
		return _result(true, null, true)
	if is_modifier:
		# The latest press replaces an earlier one (AltGr sends a fake left Ctrl first).
		_pending_modifier = InputBindings.code_from_event(event)
		return _result(false, null, true)
	if event.alt_pressed and (keycode == KEY_TAB or keycode == KEY_F4):
		return _result(false, null, true)
	var code := InputBindings.code_from_event(event)
	if code == "":
		return _result(false, null, true)
	return _result(true, code, true)


func _feed_button(event: InputEventMouseButton) -> Dictionary:
	# Left click stays the UI pointer (the page's Cancel button needs it).
	if event.button_index == MOUSE_BUTTON_LEFT:
		return _result(false, null, false)
	if not event.pressed or _WHEEL_BUTTONS.has(event.button_index):
		return _result(false, null, true)
	var code := InputBindings.code_from_event(event)
	if code == "":
		return _result(false, null, true)
	return _result(true, code, true)


func _result(done: bool, binding: Variant, consume: bool) -> Dictionary:
	return {"done": done, "binding": binding, "consume": consume}
