extends TestCase
## InputBindings: code <-> event conversion, validation and the active binding table.

const ALL_CODES := [
	"Space", "Tab", "Enter", "Escape", "Backspace", "CapsLock", "Insert", "Delete",
	"Home", "End", "PageUp", "PageDown", "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight",
	"Backquote", "Minus", "Equal", "BracketLeft", "BracketRight", "Backslash", "Semicolon",
	"Quote", "Comma", "Period", "Slash",
	"ShiftLeft", "ShiftRight", "ControlLeft", "ControlRight", "AltLeft", "AltRight",
	"MouseLeft", "MouseRight", "MouseMiddle", "MouseBack", "MouseForward",
]


func _all_codes() -> Array:
	var codes: Array = ALL_CODES.duplicate()
	for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
		codes.append("Key" + letter)
	for i in 10:
		codes.append("Digit%d" % i)
		codes.append("Numpad%d" % i)
	for i in range(1, 13):
		codes.append("F%d" % i)
	return codes


func _key(keycode: Key, pressed: bool = true) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = pressed
	return event


func _button(index: MouseButton, pressed: bool = true) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = index
	event.pressed = pressed
	return event


func test_every_code_round_trips() -> void:
	var codes := _all_codes()
	assert_eq(codes.size(), 38 + 26 + 20 + 12, "code list size")
	for code: String in codes:
		var event := InputBindings.event_from_code(code)
		assert_true(event != null, "%s builds an event" % code)
		if event != null:
			assert_eq(InputBindings.code_from_event(event), code, "%s round-trips" % code)


func test_range_ends() -> void:
	var expected := {
		"KeyA": KEY_A, "KeyZ": KEY_Z, "Digit0": KEY_0, "Digit9": KEY_9,
		"F1": KEY_F1, "F12": KEY_F12, "Numpad0": KEY_KP_0, "Numpad9": KEY_KP_9,
	}
	for code: String in expected:
		var event := InputBindings.event_from_code(code) as InputEventKey
		assert_eq(int(event.physical_keycode) if event != null else -1, expected[code], "%s physical keycode" % code)


func test_modifier_codes_round_trip() -> void:
	for code: String in ["Ctrl+Digit1", "Ctrl+Alt+Shift+KeyQ", "Shift+MouseRight"]:
		var event := InputBindings.event_from_code(code)
		assert_true(event != null, "%s builds an event" % code)
		if event != null:
			assert_eq(InputBindings.code_from_event(event), code, "%s round-trips" % code)


func test_bare_modifier_sides() -> void:
	var shift := _key(KEY_SHIFT)
	shift.shift_pressed = true
	assert_eq(InputBindings.code_from_event(shift), "ShiftLeft", "shift press reads ShiftLeft without prefix")
	shift.location = KEY_LOCATION_RIGHT
	assert_eq(InputBindings.code_from_event(shift), "ShiftRight", "right shift")
	var ctrl := _key(KEY_CTRL)
	ctrl.location = KEY_LOCATION_RIGHT
	assert_eq(InputBindings.code_from_event(ctrl), "ControlRight", "right ctrl")
	var alt := _key(KEY_ALT)
	alt.location = KEY_LOCATION_RIGHT
	assert_eq(InputBindings.code_from_event(alt), "AltRight", "right alt")


func test_unsupported_and_invalid() -> void:
	assert_eq(InputBindings.code_from_event(_key(KEY_KP_ENTER)), "Enter", "keypad enter reads Enter")
	assert_eq(InputBindings.code_from_event(_key(KEY_META)), "", "meta is unsupported")
	assert_eq(InputBindings.code_from_event(_button(MOUSE_BUTTON_WHEEL_UP)), "", "wheel is unsupported")
	for code: String in ["MouseMotion", "Ctrl+ShiftLeft", "Shift+MouseMotion", "KeyFoo"]:
		assert_eq(InputBindings.event_from_code(code), null, "%s has no event" % code)
	assert_true(InputBindings.is_valid_code("MouseMotion"), "MouseMotion is valid")
	assert_true(InputBindings.is_valid_code("Ctrl+Digit1"), "Ctrl+Digit1 is valid")
	assert_false(InputBindings.is_valid_code("KeyFoo"), "KeyFoo is invalid")


func test_bindings_lookup() -> void:
	InputBindings.clear()
	InputBindings.set_bindings({"bind_join_motel": "Ctrl+Digit1", "bind_hotbar_1": "Digit1", "bind_interact": "KeyE"})
	var ctrl_one := _key(KEY_1)
	ctrl_one.ctrl_pressed = true
	var shift_e := _key(KEY_E)
	shift_e.shift_pressed = true
	var echo := _key(KEY_E)
	echo.echo = true
	var results := [
		InputBindings.action_for_event(ctrl_one),
		InputBindings.action_for_event(_key(KEY_1)),
		InputBindings.action_for_event(shift_e),
		InputBindings.action_for_event(echo),
		InputBindings.action_for_event(_key(KEY_E, false)),
		InputBindings.action_for_event(_button(MOUSE_BUTTON_LEFT, false)),
		InputBindings.code_for("bind_interact"),
		InputBindings.is_held("bind_unbound"),
	]
	InputBindings.set_bindings({"bind_interact": "KeyE", "bind_sell_loot": "KeyE"})
	var first_wins := InputBindings.action_for_event(_key(KEY_E))
	assert_eq(results[0], "bind_join_motel", "Ctrl+1 exact match")
	assert_eq(results[1], "bind_hotbar_1", "1 bare match")
	assert_eq(results[2], "bind_interact", "Shift+E falls back to E")
	assert_eq(results[3], "", "echo is ignored")
	assert_eq(results[4], "", "key release is ignored")
	assert_eq(results[5], "", "mouse release is ignored")
	assert_eq(results[6], "KeyE", "code_for")
	assert_false(results[7], "unbound action is never held")
	assert_eq(first_wins, "bind_interact", "first action keeps a duplicate code")
	InputBindings.clear()
