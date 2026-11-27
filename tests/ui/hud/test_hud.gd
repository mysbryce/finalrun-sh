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
	var state := Hud.snapshot({"role": CRIMINAL, "life": ALIVE, "money": {"cash": 50, "bag_value": 500, "notoriety": 500.0}}, 1000)
	assert_eq(state.get("role"), "CRIMINAL", "role text")
	assert_eq(state.get("life"), "ALIVE", "life text")
	assert_eq(state.get("cash"), 50, "cash")
	assert_eq(state.get("bag"), 500, "bag value")
	assert_eq(state.get("notoriety"), 500, "notoriety")
	assert_eq(state.get("timer"), null, "no timer")


func test_snapshot_bleed_out_timer() -> void:
	var state := Hud.snapshot({"role": CRIMINAL, "life": DOWNED, "downed_deadline_ms": 10000}, 7500)
	assert_eq(state.get("timer"), {"label": "Bleeding out", "seconds": 3}, "bleed-out timer")


func test_snapshot_mask_timer() -> void:
	var state := Hud.snapshot({"role": CRIMINAL, "life": ALIVE, "mask_end_ms": 5000}, 3500)
	assert_eq(state.get("timer"), {"label": "Masking", "seconds": 2}, "mask timer")


func test_snapshot_interact_only_when_alive() -> void:
	var ctx := {"role": CRIMINAL, "life": ALIVE, "interact_title": "Loot crate", "interact_prompt": "E lockpick"}
	var state := Hud.snapshot(ctx, 1000)
	assert_eq(
		state.get("interact"),
		{"title": "Loot crate", "actions": [{"key": "E", "label": "lockpick"}]},
		"interact card while alive"
	)
	ctx["life"] = DOWNED
	assert_eq(Hud.snapshot(ctx, 1000).get("interact"), null, "interact card hidden while downed")


func test_snapshot_notification_texts() -> void:
	var notifications: Array = [{"text": "a", "expires_ms": 9}, {"text": "b", "expires_ms": 9}]
	var state := Hud.snapshot({"role": CRIMINAL, "life": ALIVE, "notifications": notifications}, 1000)
	assert_eq(state.get("notifications"), ["a", "b"], "notification texts in order")


func test_heading_from_yaw() -> void:
	assert_eq(Hud.heading_from_yaw(0.0), 0, "facing -Z is north")
	assert_eq(Hud.heading_from_yaw(-PI / 2), 90, "facing +X is east")
	assert_eq(Hud.heading_from_yaw(PI), 180, "facing +Z is south")
	assert_eq(Hud.heading_from_yaw(PI / 2), 270, "facing -X is west")


func test_interact_of() -> void:
	assert_eq(Hud.interact_of("", ""), null, "empty prompt gives no card")
	var card: Dictionary = Hud.interact_of("Loot crate", "E lockpick | V smash")
	var actions: Array = card.get("actions")
	assert_eq(card.get("title"), "Loot crate", "card title")
	assert_eq(actions.size(), 2, "two actions")
	assert_eq(actions[0], {"key": "E", "label": "lockpick"}, "first action")
	assert_eq(actions[1], {"key": "V", "label": "smash"}, "second action")
	assert_eq(
		Hud.interact_of("", "Interact"),
		{"title": "", "actions": [{"key": "", "label": "Interact"}]},
		"single action without a key"
	)


func test_party_entry() -> void:
	var present := Hud.party_entry(3, 3, true, 75, ALIVE)
	assert_eq(present.get("name"), "Player 3", "member name")
	assert_eq(present.get("health"), 75, "member health")
	assert_eq(present.get("life"), "ALIVE", "member life text")
	assert_eq(present.get("leader"), true, "leader flag")
	assert_eq(present.get("away"), false, "present member is not away")
	var absent := Hud.party_entry(4, 3, false, -1, -1)
	assert_eq(absent.get("health"), -1, "absent member has no health")
	assert_eq(absent.get("life"), "?", "absent member has no life text")
	assert_eq(absent.get("leader"), false, "absent member is not leader")
	assert_eq(absent.get("away"), true, "absent member is away")


func test_snapshot_v2_fields() -> void:
	var state := Hud.snapshot({"health": 75, "heading": 312, "self_id": 2, "fps": 60, "ping": 40}, 0)
	assert_eq(state.get("health"), 75, "health")
	assert_eq(state.get("maxHealth"), GameConst.PLAYER_MAX_HEALTH, "max health")
	assert_eq(state.get("heading"), 312, "heading")
	assert_eq(state.get("self"), {"name": "Player 2"}, "self name")
	assert_eq(state.get("party"), [], "empty party")
	var slots: Array = state.get("hotbar")
	assert_eq(slots.size(), GameConst.HUD_HOTBAR_SLOTS, "hotbar slot count")
	assert_eq(slots[0], {"label": "Pistol"}, "slot 1 holds the pistol")
	assert_eq(slots[1], null, "empty slot")
	assert_eq(state.get("activeSlot"), 0, "active slot")
	assert_eq(state.get("net"), {"fps": 60, "ping": 40}, "net stats")


func test_player_replicates_health() -> void:
	var scene := load("res://features/player/Player.tscn") as PackedScene
	var player := scene.instantiate()
	var sync := player.get_node("MultiplayerSynchronizer") as MultiplayerSynchronizer
	var config := sync.replication_config
	var has := config.has_property(NodePath(".:health"))
	var mode := config.property_get_replication_mode(NodePath(".:health")) if has else -1
	player.free()
	assert_true(has, "health is replicated")
	assert_eq(mode, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE, "health replicates on change")


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
