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
	var routed := Hud.route_request({"type": "request", "id": 7, "method": "ping"}, 0)
	assert_eq(routed["reply"], {"type": "reply", "id": 7, "ok": true, "data": {"pong": true}}, "ping reply")
	assert_eq(routed["action"], [], "ping has no action")


func test_reply_unknown_method() -> void:
	var routed := Hud.route_request({"type": "request", "id": 8, "method": "nope"}, 0)
	var reply: Dictionary = routed["reply"]
	assert_false(reply.get("ok"), "unknown method is not ok")
	assert_eq(reply.get("error"), "unknown_method", "error text")
	assert_eq(reply.get("id"), 8, "echoes the id")
	assert_eq(routed["action"], [], "unknown method has no action")


func test_item_label() -> void:
	assert_eq(Hud.item_label("cop_pistol"), "Cop pistol", "underscore to space")
	assert_eq(Hud.item_label("jewelry"), "Jewelry", "capitalised")
	assert_eq(Hud.item_label(""), "", "empty stays empty")


func test_search_view() -> void:
	var view := Hud.search_view(7, [
		{"uid": 12, "id": "cop_pistol", "value": 0, "source": "gear"},
		{"uid": 13, "id": "jewelry", "value": 300},
	])
	var items: Array = view.get("items")
	assert_eq(view.get("target"), 7, "target")
	assert_eq(view.get("title"), "Body of Player 7", "title")
	assert_eq(items.size(), 2, "two items")
	assert_eq(items[0], {"uid": 12, "id": "cop_pistol", "label": "Cop pistol", "value": 0, "source": "gear", "slot": -1, "w": 1, "h": 1}, "first item")
	assert_eq((items[1] as Dictionary).get("source"), "bag", "missing source is bag")


func test_route_search_take() -> void:
	var req := {"id": 1, "method": "search.take", "params": {"target": 7, "uid": 12}}
	var ok := Hud.route_request(req, 7)
	assert_true((ok["reply"] as Dictionary).get("ok"), "take ok")
	assert_eq(ok["action"], ["take", 7, 12], "take action")
	var wrong := Hud.route_request({"id": 1, "method": "search.take", "params": {"target": 8, "uid": 12}}, 7)
	assert_false((wrong["reply"] as Dictionary).get("ok"), "wrong target not ok")
	assert_eq((wrong["reply"] as Dictionary).get("error"), "no_search", "wrong target error")
	assert_eq(wrong["action"], [], "wrong target no action")
	var bad := Hud.route_request({"id": 1, "method": "search.take", "params": {"target": 7, "uid": 0}}, 7)
	assert_eq((bad["reply"] as Dictionary).get("error"), "bad_params", "uid 0 is bad params")
	var none := Hud.route_request(req, 0)
	assert_eq((none["reply"] as Dictionary).get("error"), "no_search", "no open search")


func test_route_search_close() -> void:
	var req := {"id": 2, "method": "search.close", "params": {"target": 7}}
	var ok := Hud.route_request(req, 7)
	assert_true((ok["reply"] as Dictionary).get("ok"), "close ok")
	assert_eq(ok["action"], ["close", 7], "close action")
	var none := Hud.route_request(req, 0)
	assert_eq((none["reply"] as Dictionary).get("error"), "no_search", "no open search")


func test_open_and_close_search_headless() -> void:
	var hud := Hud.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(hud)
	hud.open_search(7, [{"uid": 1, "id": "jewelry", "value": 300}])
	var opened := hud.is_search_open()
	hud.close_search(8)
	var still_open := hud.is_search_open()
	hud.close_search(7)
	var closed := not hud.is_search_open()
	hud.free()
	assert_true(opened, "search opens")
	assert_true(still_open, "other target does not close it")
	assert_true(closed, "search closes")


func test_item_view_default_source() -> void:
	var view := Hud.item_view({"uid": 1, "id": "cop_pistol", "value": 0}, "gear")
	assert_eq(view, {"uid": 1, "id": "cop_pistol", "label": "Cop pistol", "value": 0, "source": "gear", "slot": -1, "w": 1, "h": 1}, "item view uses the default source")


func test_inventory_view() -> void:
	var view := Hud.inventory_view({
		"cash": 50,
		"bag_value": 300,
		"bag_items": [{"uid": 3, "id": "jewelry", "value": 300}],
		"gear": [{"uid": 1, "id": "cop_pistol", "value": 0}],
	})
	var empty := Hud.inventory_view({})
	assert_eq(view["cash"], 50, "cash")
	assert_eq(view["bagValue"], 300, "bag value")
	assert_eq(view["bagSlots"], GameConst.INVENTORY_BAG_SLOTS, "bag slots")
	assert_eq(view["bag"][0]["label"], "Jewelry", "bag label")
	assert_eq(view["bag"][0]["source"], "bag", "bag source")
	assert_eq(view["gear"][0]["source"], "gear", "gear source")
	assert_eq(empty["bag"], [], "empty bag")
	assert_eq(empty["gear"], [], "empty gear")


func test_route_inventory_close() -> void:
	var routed := Hud.route_request({"id": 4, "method": "inventory.close", "params": {}}, 0)
	assert_eq(routed["reply"]["ok"], true, "inventory.close is ok")
	assert_eq(routed["action"], ["inventory_close"], "inventory.close action")


func test_route_inventory_move() -> void:
	var ok := Hud.route_request({"id": 5, "method": "inventory.move", "params": {"uid": 3, "slot": 4}}, 0)
	var bad_slot := Hud.route_request({"id": 5, "method": "inventory.move", "params": {"uid": 3, "slot": 54}}, 0)
	var slot_36 := Hud.route_request({"id": 5, "method": "inventory.move", "params": {"uid": 3, "slot": 36}}, 0)
	var bad_uid := Hud.route_request({"id": 5, "method": "inventory.move", "params": {"uid": 0, "slot": 4}}, 0)
	assert_eq(ok["reply"]["ok"], true, "inventory.move is ok")
	assert_eq(ok["action"], ["move", 3, 4], "inventory.move action")
	assert_eq(bad_slot["reply"]["error"], "bad_params", "slot 54 is bad params")
	assert_eq(slot_36["reply"]["ok"], true, "slot 36 is now valid")
	assert_eq(bad_uid["reply"]["error"], "bad_params", "uid 0 is bad params")


func test_toggle_inventory_headless() -> void:
	var hud := Hud.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(hud)
	hud.toggle_inventory()
	var opened := hud.is_inventory_open()
	hud.toggle_inventory()
	var closed := not hud.is_inventory_open()
	hud.toggle_inventory()
	hud.open_search(7, [])
	var search_won := hud.is_search_open() and not hud.is_inventory_open()
	hud.toggle_inventory()
	var ignored := not hud.is_inventory_open()
	hud.free()
	assert_true(opened, "TAB opens the inventory")
	assert_true(closed, "TAB closes it again")
	assert_true(search_won, "search wins over the inventory")
	assert_true(ignored, "TAB is ignored over search")


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
