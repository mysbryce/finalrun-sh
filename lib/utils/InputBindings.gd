class_name InputBindings
extends RefCounted
## Exception: unlike the rest of lib/utils this class keeps state. The active
## binding table lives in static vars because Main and Player (features/, which
## may not import ui/) both need it. Its only writers are set_bindings and clear.
##
## Binding codes are physical codes (layout independent, same names as the web
## KeyboardEvent.code), optionally prefixed Ctrl+, Alt+, Shift+ in that order.
## Keys match on InputEventKey.physical_keycode, never keycode. No InputMap.

const _KEY_CODES := {
	"Space": KEY_SPACE, "Tab": KEY_TAB, "Enter": KEY_ENTER, "Escape": KEY_ESCAPE,
	"Backspace": KEY_BACKSPACE, "CapsLock": KEY_CAPSLOCK, "Insert": KEY_INSERT,
	"Delete": KEY_DELETE, "Home": KEY_HOME, "End": KEY_END, "PageUp": KEY_PAGEUP,
	"PageDown": KEY_PAGEDOWN, "ArrowUp": KEY_UP, "ArrowDown": KEY_DOWN,
	"ArrowLeft": KEY_LEFT, "ArrowRight": KEY_RIGHT,
	"Backquote": KEY_QUOTELEFT, "Minus": KEY_MINUS, "Equal": KEY_EQUAL,
	"BracketLeft": KEY_BRACKETLEFT, "BracketRight": KEY_BRACKETRIGHT,
	"Backslash": KEY_BACKSLASH, "Semicolon": KEY_SEMICOLON, "Quote": KEY_APOSTROPHE,
	"Comma": KEY_COMMA, "Period": KEY_PERIOD, "Slash": KEY_SLASH,
}
## Bare modifier key -> code stem; the side comes from InputEventKey.location.
const _MODIFIER_STEMS := {KEY_SHIFT: "Shift", KEY_CTRL: "Control", KEY_ALT: "Alt"}
const _LEFT := "Left"
const _RIGHT := "Right"
const _MOUSE_CODES := {
	"MouseLeft": MOUSE_BUTTON_LEFT,
	"MouseRight": MOUSE_BUTTON_RIGHT,
	"MouseMiddle": MOUSE_BUTTON_MIDDLE,
	"MouseBack": MOUSE_BUTTON_XBUTTON1,
	"MouseForward": MOUSE_BUTTON_XBUTTON2,
}
const _WHEEL_BUTTONS := [
	MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT,
]
## Readable names; copied from NAMED in ui/web/src/features/settings/format.ts.
const _LABELS := {
	"MouseLeft": "LMB",
	"MouseRight": "RMB",
	"MouseMiddle": "MMB",
	"MouseBack": "Mouse 4",
	"MouseForward": "Mouse 5",
	"MouseMotion": "Mouse",
	"ShiftLeft": "Left Shift",
	"ShiftRight": "Right Shift",
	"ControlLeft": "Left Ctrl",
	"ControlRight": "Right Ctrl",
	"AltLeft": "Left Alt",
	"AltRight": "Right Alt",
	"Escape": "Esc",
	"Backquote": "`",
	"Minus": "-",
	"Equal": "=",
	"BracketLeft": "[",
	"BracketRight": "]",
	"Backslash": "\\",
	"Semicolon": ";",
	"Quote": "'",
	"Comma": ",",
	"Period": ".",
	"Slash": "/",
	"ArrowUp": "↑",
	"ArrowDown": "↓",
	"ArrowLeft": "←",
	"ArrowRight": "→",
	"PageUp": "Page Up",
	"PageDown": "Page Down",
	"CapsLock": "Caps Lock",
}
const _LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const _DIGIT_CHARS := "0123456789"
const _DIGITS := 10
const _FUNCTION_KEYS := 12

## Lookup tables, filled on first use.
static var _code_to_key: Dictionary = {}
static var _key_to_code: Dictionary = {}
static var _code_to_button: Dictionary = {}
static var _button_to_code: Dictionary = {}
static var _bare_modifiers: Dictionary = {}  # "ShiftLeft" -> [KEY_SHIFT, KEY_LOCATION_LEFT]

## Active bindings (only writers: set_bindings, clear).
static var _code_to_action: Dictionary = {}
static var _action_to_code: Dictionary = {}


static func _ensure_tables() -> void:
	if not _code_to_key.is_empty():
		return
	for i in _LETTERS.length():
		_code_to_key["Key" + _LETTERS[i]] = KEY_A + i
	for i in _DIGITS:
		_code_to_key["Digit%d" % i] = KEY_0 + i
		_code_to_key["Numpad%d" % i] = KEY_KP_0 + i
	for i in _FUNCTION_KEYS:
		_code_to_key["F%d" % (i + 1)] = KEY_F1 + i
	for code: String in _KEY_CODES:
		_code_to_key[code] = _KEY_CODES[code]
	for code: String in _code_to_key:
		_key_to_code[_code_to_key[code]] = code
	for code: String in _MOUSE_CODES:
		_code_to_button[code] = _MOUSE_CODES[code]
		_button_to_code[_MOUSE_CODES[code]] = code
	for keycode: int in _MODIFIER_STEMS:
		var stem: String = _MODIFIER_STEMS[keycode]
		_bare_modifiers[stem + _LEFT] = [keycode, KEY_LOCATION_LEFT]
		_bare_modifiers[stem + _RIGHT] = [keycode, KEY_LOCATION_RIGHT]


## Binding code for a key or mouse button event; "" when unsupported.
static func code_from_event(event: InputEvent) -> String:
	_ensure_tables()
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var keycode := int(key_event.physical_keycode)
		if _MODIFIER_STEMS.has(keycode):
			var side := _RIGHT if key_event.location == KEY_LOCATION_RIGHT else _LEFT
			return String(_MODIFIER_STEMS[keycode]) + side
		if keycode == KEY_KP_ENTER:
			keycode = KEY_ENTER
		if not _key_to_code.has(keycode):
			return ""
		return _prefix(key_event) + String(_key_to_code[keycode])
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if not _button_to_code.has(int(button.button_index)):
			return ""
		return _prefix(button) + String(_button_to_code[int(button.button_index)])
	return ""


## A new event for `code`; null for MouseMotion, "", unknown codes, a prefixed
## bare modifier or a prefixed MouseMotion.
static func event_from_code(code: String) -> InputEvent:
	_ensure_tables()
	if code == "":
		return null
	var parts := code.split(GameConst.BINDING_SEPARATOR)
	var base := parts[parts.size() - 1]
	var flags := [false, false, false]  # ctrl, alt, shift
	var last_modifier := -1
	for i in parts.size() - 1:
		var index := GameConst.BINDING_MODIFIERS.find(parts[i])
		if index <= last_modifier:
			return null
		last_modifier = index
		flags[index] = true
	var prefixed := parts.size() > 1
	if _bare_modifiers.has(base):
		if prefixed:
			return null
		var spec: Array = _bare_modifiers[base]
		var modifier := InputEventKey.new()
		modifier.physical_keycode = spec[0] as Key
		modifier.location = spec[1] as KeyLocation
		return modifier
	var event: InputEventWithModifiers = null
	if _code_to_key.has(base):
		var key_event := InputEventKey.new()
		key_event.physical_keycode = _code_to_key[base] as Key
		event = key_event
	elif _code_to_button.has(base):
		var button := InputEventMouseButton.new()
		button.button_index = _code_to_button[base] as MouseButton
		event = button
	else:
		return null
	event.ctrl_pressed = flags[0]
	event.alt_pressed = flags[1]
	event.shift_pressed = flags[2]
	return event


static func is_valid_code(code: String) -> bool:
	return code == GameConst.LOOK_BINDING_CODE or event_from_code(code) != null


## Replaces the active table (action -> code). Walks in order and keeps the
## first action for each code.
static func set_bindings(bindings: Dictionary) -> void:
	# ponytail: a duplicate code is normally only possible across the debug
	# context; a hand-edited cfg can also collide.
	clear()
	for action: Variant in bindings:
		var code: Variant = bindings[action]
		if not code is String or code == "" or _code_to_action.has(code):
			continue
		_code_to_action[code] = String(action)
		_action_to_code[String(action)] = code


static func clear() -> void:
	_code_to_action = {}
	_action_to_code = {}


## Action bound to a pressed, non-echo key or a pressed non-wheel mouse button:
## the exact code with modifiers first, then the bare code; "" otherwise.
static func action_for_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return ""
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if not button.pressed or _WHEEL_BUTTONS.has(button.button_index):
			return ""
	else:
		return ""
	var code := code_from_event(event)
	if code == "":
		return ""
	if _code_to_action.has(code):
		return String(_code_to_action[code])
	var parts := code.split(GameConst.BINDING_SEPARATOR)
	return String(_code_to_action.get(parts[parts.size() - 1], ""))


## True while the base key or button of `action` is held; false when unbound.
static func is_held(action: String) -> bool:
	# ponytail: checks only the base key/button (no modifiers) and cannot tell
	# left from right modifier keys.
	var code := code_for(action)
	if code == "":
		return false
	var parts := code.split(GameConst.BINDING_SEPARATOR)
	var event := event_from_code(parts[parts.size() - 1])
	if event is InputEventKey:
		return Input.is_physical_key_pressed((event as InputEventKey).physical_keycode)
	if event is InputEventMouseButton:
		return Input.is_mouse_button_pressed((event as InputEventMouseButton).button_index)
	return false


static func code_for(action: String) -> String:
	return String(_action_to_code.get(action, ""))


## Readable key label for a binding code (`Ctrl+KeyB` -> `Ctrl+B`, `MouseRight`
## -> `RMB`). Same rules as the web bindingText, except "" gives
## GameConst.UNBOUND_KEY_LABEL.
static func label_for(code: String) -> String:
	if code == "":
		return GameConst.UNBOUND_KEY_LABEL
	var parts := code.split(GameConst.BINDING_SEPARATOR)
	var last := parts.size() - 1
	parts[last] = _code_label(parts[last])
	return GameConst.BINDING_SEPARATOR.join(parts)


static func _code_label(code: String) -> String:
	if _LABELS.has(code):
		return String(_LABELS[code])
	if code.length() == 4 and code.begins_with("Key") and _LETTERS.contains(code.right(1)):
		return code.right(1)
	if code.length() == 6 and code.begins_with("Digit") and _DIGIT_CHARS.contains(code.right(1)):
		return code.right(1)
	if code.length() == 7 and code.begins_with("Numpad") and _DIGIT_CHARS.contains(code.right(1)):
		return "Num " + code.right(1)
	return code


static func _prefix(event: InputEventWithModifiers) -> String:
	var text := ""
	if event.ctrl_pressed:
		text += GameConst.BINDING_MODIFIERS[0] + GameConst.BINDING_SEPARATOR
	if event.alt_pressed:
		text += GameConst.BINDING_MODIFIERS[1] + GameConst.BINDING_SEPARATOR
	if event.shift_pressed:
		text += GameConst.BINDING_MODIFIERS[2] + GameConst.BINDING_SEPARATOR
	return text
