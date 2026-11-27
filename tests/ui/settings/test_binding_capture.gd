extends TestCase
## BindingCapture: which events finish a capture, with what code, and which are consumed.

const START_MS := 1000


func _capture() -> BindingCapture:
	return BindingCapture.new(1, "bind_interact", START_MS)


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


func test_plain_key() -> void:
	var r := _capture().feed(_key(KEY_R))
	assert_true(r["done"], "key press finishes")
	assert_eq(r["binding"], "KeyR", "key code")
	assert_true(r["consume"], "key is consumed")


func test_modifier_then_key() -> void:
	var capture := _capture()
	var first := capture.feed(_key(KEY_CTRL))
	var digit := _key(KEY_1)
	digit.ctrl_pressed = true
	var r := capture.feed(digit)
	assert_false(first["done"], "modifier press waits")
	assert_true(first["consume"], "modifier press is consumed")
	assert_true(r["done"], "key finishes")
	assert_eq(r["binding"], "Ctrl+Digit1", "key with modifier")


func test_bare_modifier_release() -> void:
	var capture := _capture()
	capture.feed(_key(KEY_CTRL))
	var r := capture.feed(_key(KEY_CTRL, false))
	assert_true(r["done"], "modifier release finishes")
	assert_eq(r["binding"], "ControlLeft", "bare modifier code")


func test_altgr_latest_modifier_wins() -> void:
	var capture := _capture()
	capture.feed(_key(KEY_CTRL))
	var alt := _key(KEY_ALT)
	alt.location = KEY_LOCATION_RIGHT
	var pressed := capture.feed(alt)
	var release := _key(KEY_ALT, false)
	release.location = KEY_LOCATION_RIGHT
	var r := capture.feed(release)
	assert_false(pressed["done"], "second modifier press waits")
	assert_true(r["done"], "pending modifier release finishes")
	assert_eq(r["binding"], "AltRight", "latest modifier wins")


func test_left_click_keeps_pending_modifier() -> void:
	var capture := _capture()
	capture.feed(_key(KEY_CTRL))
	var click := capture.feed(_button(MOUSE_BUTTON_LEFT))
	var r := capture.feed(_key(KEY_CTRL, false))
	assert_false(click["done"], "left click is ignored")
	assert_true(r["done"], "modifier release still finishes")
	assert_eq(r["binding"], "ControlLeft", "pending modifier kept")


func test_escape_cancels() -> void:
	var r := _capture().feed(_key(KEY_ESCAPE))
	assert_true(r["done"], "escape finishes")
	assert_eq(r["binding"], null, "escape gives null")


func test_mouse_buttons() -> void:
	var left := _capture().feed(_button(MOUSE_BUTTON_LEFT))
	var right := _capture().feed(_button(MOUSE_BUTTON_RIGHT))
	var wheel := _capture().feed(_button(MOUSE_BUTTON_WHEEL_UP))
	var motion := _capture().feed(InputEventMouseMotion.new())
	assert_false(left["done"], "left click is not captured")
	assert_false(left["consume"], "left click is not consumed")
	assert_true(right["done"], "right click finishes")
	assert_eq(right["binding"], "MouseRight", "right click code")
	assert_true(right["consume"], "right click is consumed")
	assert_false(wheel["done"], "wheel is ignored")
	assert_true(wheel["consume"], "wheel is consumed")
	assert_false(motion["done"], "motion is ignored")
	assert_false(motion["consume"], "motion is not consumed")


func test_ignored_keys() -> void:
	var echo := _key(KEY_R)
	echo.echo = true
	var alt_tab := _key(KEY_TAB)
	alt_tab.alt_pressed = true
	var alt_f4 := _key(KEY_F4)
	alt_f4.alt_pressed = true
	var events := {"echo": echo, "meta": _key(KEY_META), "Alt+Tab": alt_tab, "Alt+F4": alt_f4, "release": _key(KEY_R, false)}
	for label: String in events:
		var r := _capture().feed(events[label])
		assert_false(r["done"], "%s is ignored" % label)


func test_timeout() -> void:
	var capture := _capture()
	assert_false(capture.timed_out(START_MS + GameConst.CAPTURE_TIMEOUT_MS - 1), "not timed out before the limit")
	assert_true(capture.timed_out(START_MS + GameConst.CAPTURE_TIMEOUT_MS), "timed out at the limit")
