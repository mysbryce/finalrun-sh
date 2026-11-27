extends TestCase
## HUD snapshot helpers, JSON replies and the headless browser guard.


const ALIVE := PlayerRoleController.LifeState.ALIVE
const DOWNED := PlayerRoleController.LifeState.DOWNED
const CRIMINAL := PlayerRoleController.Role.CRIMINAL


func test_role_and_life_text() -> void:
	assert_eq(Hud.role_text(PlayerRoleController.Role.CRIMINAL), "CRIMINAL", "criminal role text")
	assert_eq(Hud.role_text(99), "?", "unknown role text")
	assert_eq(Hud.life_text(PlayerRoleController.LifeState.DOWNED), "DOWNED", "downed life text")


func test_seconds_left() -> void:
	assert_eq(Hud.seconds_left(10000, 7500), 3, "rounds up")
	assert_eq(Hud.seconds_left(10000, 9000), 1, "rounds up to one")
	assert_eq(Hud.seconds_left(10000, 10000), 0, "deadline reached")
	assert_eq(Hud.seconds_left(10000, 12000), 0, "never below zero")


func test_notifications_trim_and_expire() -> void:
	var list: Array = []
	for text: String in ["a", "b", "c", "d", "e"]:
		list = Hud.push_notification(list, text, 0)
	assert_eq(list.size(), GameConst.HUD_MAX_NOTIFICATIONS, "trimmed to the cap")
	assert_eq(String((list[0] as Dictionary).get("text", "")), "b", "oldest dropped")
	assert_eq(
		Hud.prune_notifications(list, GameConst.HUD_NOTIFICATION_MS).size(),
		0,
		"entries expire at the deadline"
	)
	assert_eq(
		Hud.prune_notifications(list, GameConst.HUD_NOTIFICATION_MS - 1).size(),
		4,
		"entries survive just before the deadline"
	)


func test_snapshot_money_and_role() -> void:
	var state := Hud.snapshot(CRIMINAL, ALIVE, 0, 0, {"cash": 50, "bag_value": 500, "notoriety": 500.0}, "", [], 1000)
	assert_eq(state.get("role"), "CRIMINAL", "role text")
	assert_eq(state.get("life"), "ALIVE", "life text")
	assert_eq(state.get("cash"), 50, "cash")
	assert_eq(state.get("bag"), 500, "bag value")
	assert_eq(state.get("notoriety"), 500, "notoriety")
	assert_eq(state.get("timer"), null, "no timer")


func test_snapshot_bleed_out_timer() -> void:
	var state := Hud.snapshot(CRIMINAL, DOWNED, 10000, 0, {}, "", [], 7500)
	assert_eq(state.get("timer"), {"label": "Bleeding out", "seconds": 3}, "bleed-out timer")


func test_snapshot_mask_timer() -> void:
	var state := Hud.snapshot(CRIMINAL, ALIVE, 0, 5000, {}, "", [], 3500)
	assert_eq(state.get("timer"), {"label": "Masking", "seconds": 2}, "mask timer")


func test_snapshot_prompt_only_when_alive() -> void:
	assert_eq(
		Hud.snapshot(CRIMINAL, ALIVE, 0, 0, {}, "E lockpick", [], 1000).get("prompt"),
		"E lockpick",
		"prompt shown while alive"
	)
	assert_eq(
		Hud.snapshot(CRIMINAL, DOWNED, 0, 0, {}, "E lockpick", [], 1000).get("prompt"),
		"",
		"prompt hidden while downed"
	)


func test_snapshot_notification_texts() -> void:
	var notifications: Array = [{"text": "a", "expires_ms": 9}, {"text": "b", "expires_ms": 9}]
	var state := Hud.snapshot(CRIMINAL, ALIVE, 0, 0, {}, "", notifications, 1000)
	assert_eq(state.get("notifications"), ["a", "b"], "notification texts in order")


func test_reply_ping() -> void:
	assert_eq(
		Hud.reply_for({"type": "request", "id": 7, "method": "ping"}),
		{"type": "reply", "id": 7, "ok": true, "data": {"pong": true}},
		"ping reply"
	)


func test_reply_unknown_method() -> void:
	var reply := Hud.reply_for({"type": "request", "id": 8, "method": "nope"})
	assert_false(reply.get("ok"), "unknown method is not ok")
	assert_eq(reply.get("error"), "unknown_method", "error text")
	assert_eq(reply.get("id"), 8, "echoes the id")


func test_page_url() -> void:
	assert_eq(Hud.page_url(PackedStringArray()), GameConst.UI_PAGE_URL, "built page by default")
	assert_eq(
		Hud.page_url(PackedStringArray(["--ui-dev"])),
		GameConst.UI_DEV_URL,
		"dev server with --ui-dev"
	)


func test_headless_has_no_browser() -> void:
	var hud := Hud.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(hud)
	var count := hud.get_child_count()
	hud.free()
	assert_eq(count, 0, "headless HUD creates no browser")
	assert_false(Hud.can_use_browser(), "no browser available in headless tests")
