extends TestCase
## HUD text helpers, notification trimming and the label build-out.


func test_role_and_life_text() -> void:
	assert_eq(Hud.role_text(PlayerRoleController.Role.CRIMINAL), "CRIMINAL", "criminal role text")
	assert_eq(Hud.role_text(99), "?", "unknown role text")
	assert_eq(Hud.life_text(PlayerRoleController.LifeState.DOWNED), "DOWNED", "downed life text")


func test_money_text() -> void:
	assert_eq(
		Hud.money_text({"cash": 50, "bag_value": 500, "notoriety": 500.0}),
		"Cash $50 | Bag $500 | Notoriety 500",
		"money line from a full state"
	)
	assert_eq(Hud.money_text({}), "Cash $0 | Bag $0 | Notoriety 0", "missing keys count as 0")


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


func test_hud_builds_labels() -> void:
	var hud := Hud.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(hud)
	hud.set_player(null)
	var count: int = hud.get_child_count()
	hud.free()
	assert_eq(count, 5, "the HUD builds five labels")
