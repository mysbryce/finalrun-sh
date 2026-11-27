extends TestCase
## HUD snapshot helpers, JSON replies and the headless browser guard.


const ALIVE := PlayerRoleController.LifeState.ALIVE
const DOWNED := PlayerRoleController.LifeState.DOWNED
const CRIMINAL := PlayerRoleController.Role.CRIMINAL


func test_shows_hud_routes() -> void:
	assert_true(Hud.shows_hud("/"), "plain HUD shows the HUD")
	assert_true(Hud.shows_hud("/pause"), "pause shows the HUD")
	for route: String in ["/inventory", "/search", "/splash", "/lobby", "/death", "/arrest", "/transfer", "/settings/controls"]:
		assert_false(Hud.shows_hud(route), "%s hides the HUD" % route)


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
	InputBindings.set_bindings({"bind_interact": "KeyE", "bind_smash": "KeyV"})
	var ctx := {"role": CRIMINAL, "life": ALIVE, "interact_title": "Loot crate", "interact_prompt": "E lockpick"}
	var state := Hud.snapshot(ctx, 1000)
	ctx["life"] = DOWNED
	var downed_interact: Variant = Hud.snapshot(ctx, 1000).get("interact")
	InputBindings.clear()
	assert_eq(
		state.get("interact"),
		{"title": "Loot crate", "actions": [{"key": "E", "label": "lockpick"}]},
		"interact card while alive"
	)
	assert_eq(downed_interact, null, "interact card hidden while downed")


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
	InputBindings.set_bindings({"bind_interact": "KeyE", "bind_smash": "KeyV"})
	var empty: Variant = Hud.interact_of("", "")
	var card: Dictionary = Hud.interact_of("Loot crate", "E lockpick | V smash")
	var single: Variant = Hud.interact_of("", "Interact")
	var unknown_letter: Dictionary = Hud.interact_of("", "Z wave")
	InputBindings.clear()
	var actions: Array = card.get("actions")
	assert_eq(empty, null, "empty prompt gives no card")
	assert_eq(card.get("title"), "Loot crate", "card title")
	assert_eq(actions.size(), 2, "two actions")
	assert_eq(actions[0], {"key": "E", "label": "lockpick"}, "first action")
	assert_eq(actions[1], {"key": "V", "label": "smash"}, "second action")
	assert_eq(
		single,
		{"title": "", "actions": [{"key": "", "label": "Interact"}]},
		"single action without a key"
	)
	assert_eq(unknown_letter.get("actions")[0].get("key"), "Z", "unmapped letter stays as written")


func test_interact_of_follows_bindings() -> void:
	InputBindings.clear()
	var unbound: Dictionary = Hud.interact_of("Loot crate", "E lockpick")
	InputBindings.set_bindings({"bind_interact": "KeyF", "bind_smash": "MouseRight"})
	var rebound: Dictionary = Hud.interact_of("Loot crate", "E lockpick | V smash")
	InputBindings.clear()
	assert_eq(unbound.get("actions")[0].get("key"), "—", "unbound action shows the unbound label")
	assert_eq(rebound.get("actions")[0].get("key"), "F", "E follows its binding")
	assert_eq(rebound.get("actions")[1].get("key"), "RMB", "V follows its binding")


func test_heist_alert_view() -> void:
	var heist := {"id": "jewelry", "location": "Jewelry", "started_ms": 1000}
	var at_start: Variant = Hud.heist_alert_view(heist, 1000)
	var after_toast: Variant = Hud.heist_alert_view(heist, 1000 + GameConst.HEIST_TOAST_MS)
	var expired: Variant = Hud.heist_alert_view(heist, 1000 + GameConst.HEIST_ALERT_ACTIVE_MS)
	assert_eq(Hud.heist_alert_view({}, 1000), null, "no alert gives null")
	assert_eq(
		at_start,
		{"id": "jewelry", "label": "Heist alert", "location": "Jewelry", "active": true, "toastSecondsLeft": 8},
		"toast 8 at start"
	)
	assert_true(after_toast != null, "alert still active after the toast")
	assert_eq((after_toast as Dictionary).get("toastSecondsLeft"), 0, "toast over after 8 s")
	assert_eq(expired, null, "alert gone after 90 s")


func test_add_heist_alert_dedupe() -> void:
	var hud := Hud.new()
	hud.add_heist_alert("jewelry", 1000)
	hud.add_heist_alert("jewelry", 5000)
	var same_id: Dictionary = hud._heist.duplicate()
	hud.add_heist_alert("electronics", 6000)
	var new_id: Dictionary = hud._heist.duplicate()
	hud.free()
	assert_eq(same_id.get("started_ms"), 1000, "same id within the window keeps the first start")
	assert_eq(new_id.get("id"), "electronics", "a new id replaces the alert")
	assert_eq(new_id.get("started_ms"), 6000, "a new id restarts the toast")
	assert_eq(new_id.get("location"), "Electronics", "location is the item label")


func test_channels_view() -> void:
	var channels := {"revive": {"end_ms": 6000, "duration_ms": 5000}}
	assert_eq(Hud.channels_view(channels, ALIVE, 1000), null, "null while alive")
	assert_eq(
		Hud.channels_view(channels, DOWNED, 1000),
		{"revive": {"secondsLeft": 5, "durationSeconds": 5.0}, "finish": null},
		"revive entry while downed"
	)


func test_snapshot_weapons_and_surrender() -> void:
	assert_true(Hud.snapshot({"weapons_locked": true}, 0)["weaponsLocked"], "weapons locked from ctx")
	assert_false(Hud.snapshot({}, 0)["weaponsLocked"], "weapons unlocked when the key is missing")
	var cop_ctx := {"role": PlayerRoleController.Role.COP, "life": ALIVE, "surrender_available": true}
	assert_false(Hud.snapshot(cop_ctx, 0)["surrenderAvailable"], "a COP never sees surrender")
	var criminal_ctx := {"role": CRIMINAL, "life": ALIVE, "surrender_available": true}
	assert_true(Hud.snapshot(criminal_ctx, 0)["surrenderAvailable"], "an alive CRIMINAL sees surrender")


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


func test_route_lobby_join() -> void:
	var configured := Hud.route_request({"id": 1, "method": "lobby.join", "params": {"mode": "configured"}}, 0)
	var by_id := Hud.route_request({"id": 2, "method": "lobby.join", "params": {"mode": "by_id", "serverId": "SV-SPACE-0001"}}, 0)
	var missing := Hud.route_request({"id": 3, "method": "lobby.join", "params": {}}, 0)
	var invalid := Hud.route_request({"id": 4, "method": "lobby.join", "params": {"mode": 5}}, 0)
	assert_true(configured["reply"]["ok"], "configured join is ok")
	assert_eq(configured["action"], ["lobby_join"], "configured join action")
	assert_eq(by_id["reply"].get("error"), "discovery_unavailable", "by_id has no discovery")
	assert_eq(by_id["action"], [], "by_id has no action")
	assert_eq(missing["reply"].get("error"), "bad_params", "missing mode is bad_params")
	assert_eq(invalid["reply"].get("error"), "bad_params", "non-string mode is bad_params")


func test_route_lobby_news_retry_and_settings() -> void:
	var retry := Hud.route_request({"id": 5, "method": "lobby.news_retry"}, 0)
	var settings := Hud.route_request({"id": 6, "method": "settings.open"}, 0)
	assert_true(retry["reply"]["ok"], "news retry is ok")
	assert_eq(retry["action"], ["news_retry"], "news retry action")
	assert_true(settings["reply"]["ok"], "settings.open is ok")
	assert_eq(settings["action"], ["settings_open"], "settings.open action")


func test_route_settings_tab_and_close() -> void:
	var good := Hud.route_request({"id": 7, "method": "settings.tab", "params": {"tab": "controls"}}, 0)
	var bad := Hud.route_request({"id": 8, "method": "settings.tab", "params": {"tab": "audio"}}, 0)
	var missing := Hud.route_request({"id": 9, "method": "settings.tab"}, 0)
	var close := Hud.route_request({"id": 10, "method": "settings.close"}, 0)
	assert_true(good["reply"]["ok"], "known tab is ok")
	assert_eq(good["action"], ["settings_tab", "controls"], "tab action")
	assert_eq(bad["reply"].get("error"), "bad_params", "unknown tab is bad_params")
	assert_eq(bad["action"], [], "unknown tab has no action")
	assert_eq(missing["reply"].get("error"), "bad_params", "missing tab is bad_params")
	assert_true(close["reply"]["ok"], "settings.close is ok")
	assert_eq(close["action"], ["settings_close"], "close action")


func test_route_settings_apply_defers_reply() -> void:
	var patch := {"fov": 90.0}
	var apply := Hud.route_request({"id": 11, "method": "settings.apply", "params": {"revision": 3.0, "patch": patch}}, 0)
	var fractional := Hud.route_request({"id": 12, "method": "settings.apply", "params": {"revision": 1.5, "patch": patch}}, 0)
	var no_patch := Hud.route_request({"id": 13, "method": "settings.apply", "params": {"revision": 0}}, 0)
	var bad_patch := Hud.route_request({"id": 14, "method": "settings.apply", "params": {"revision": 0, "patch": []}}, 0)
	assert_eq(apply["reply"], null, "apply reply is deferred")
	assert_eq(apply["action"], ["settings_apply", 11, 3, patch], "apply action carries id, revision and patch")
	assert_true(apply["action"][2] is int, "revision is converted to int")
	assert_eq(fractional["reply"].get("error"), "bad_params", "fractional revision is bad_params")
	assert_eq(no_patch["reply"].get("error"), "bad_params", "missing patch is bad_params")
	assert_eq(bad_patch["reply"].get("error"), "bad_params", "non-dictionary patch is bad_params")


func test_route_settings_display_confirm() -> void:
	var confirm := Hud.route_request({"id": 15, "method": "settings.display_confirm", "params": {"token": "p1", "keep": true}}, 0)
	var empty := Hud.route_request({"id": 19, "method": "settings.display_confirm", "params": {}}, 0)
	var bad_keep := Hud.route_request({"id": 20, "method": "settings.display_confirm", "params": {"token": "p1", "keep": "yes"}}, 0)
	var bad_token := Hud.route_request({"id": 21, "method": "settings.display_confirm", "params": {"token": 1, "keep": true}}, 0)
	assert_eq(confirm["reply"], null, "display_confirm reply is deferred")
	assert_eq(confirm["action"], ["settings_display_confirm", 15, "p1", true], "display_confirm action carries id, token and keep")
	assert_eq(empty["reply"].get("error"), "bad_params", "missing params are bad_params")
	assert_eq(empty["action"], [], "bad params have no action")
	assert_eq(bad_keep["reply"].get("error"), "bad_params", "non-bool keep is bad_params")
	assert_eq(bad_token["reply"].get("error"), "bad_params", "non-string token is bad_params")


func test_route_settings_capture() -> void:
	var capture := Hud.route_request({"id": 16, "method": "settings.capture", "params": {"key": "bind_interact"}}, 0)
	var no_key := Hud.route_request({"id": 17, "method": "settings.capture", "params": {}}, 0)
	var cancel := Hud.route_request({"id": 18, "method": "settings.capture_cancel"}, 0)
	assert_eq(capture["reply"], null, "capture reply is deferred")
	assert_eq(capture["action"], ["settings_capture", 16, "bind_interact"], "capture action carries id and key")
	assert_eq(no_key["reply"].get("error"), "bad_params", "missing key is bad_params")
	assert_eq(no_key["action"], [], "missing key has no action")
	assert_true(cancel["reply"]["ok"], "capture_cancel is ok")
	assert_eq(cancel["reply"]["data"], {}, "capture_cancel replies {}")
	assert_eq(cancel["action"], ["settings_capture_cancel"], "capture_cancel action")


func test_snapshot_active_slot() -> void:
	assert_eq(Hud.snapshot({"active_slot": 2}, 0).get("activeSlot"), 2, "active slot from ctx")


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
	var target_open := hud.search_target()
	hud.close_search(8)
	var still_open := hud.is_search_open()
	hud.close_search(7)
	var closed := not hud.is_search_open()
	var target_closed := hud.search_target()
	hud.free()
	assert_true(opened, "search opens")
	assert_eq(target_open, 7, "search target after open")
	assert_true(still_open, "other target does not close it")
	assert_true(closed, "search closes")
	assert_eq(target_closed, 0, "search target after close")


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


func test_route_boot_and_quit() -> void:
	var skip := Hud.route_request({"id": 9, "method": "boot.skip", "params": {}}, 0)
	var retry := Hud.route_request({"id": 10, "method": "boot.retry", "params": {}}, 0)
	var quit := Hud.route_request({"id": 11, "method": "app.quit", "params": {}}, 0)
	assert_eq(skip["reply"], {"type": "reply", "id": 9, "ok": true, "data": {}}, "boot.skip ok reply")
	assert_eq(skip["action"], ["boot_skip"], "boot.skip action")
	assert_eq(retry["reply"]["ok"], true, "boot.retry ok")
	assert_eq(retry["action"], ["boot_retry"], "boot.retry action")
	assert_eq(quit["reply"]["ok"], true, "app.quit ok")
	assert_eq(quit["action"], ["quit"], "app.quit action")


func test_route_pause_resume_and_session_leave() -> void:
	var resume := Hud.route_request({"id": 12, "method": "pause.resume", "params": {}}, 0)
	var leave := Hud.route_request({"id": 13, "method": "session.leave", "params": {}}, 0)
	assert_eq(resume["reply"], {"type": "reply", "id": 12, "ok": true, "data": {}}, "pause.resume ok reply")
	assert_eq(resume["action"], ["pause_resume"], "pause.resume action")
	assert_eq(leave["reply"], {"type": "reply", "id": 13, "ok": true, "data": {}}, "session.leave ok reply")
	assert_eq(leave["action"], ["session_leave"], "session.leave action")


func test_pause_open_close_headless() -> void:
	var hud := Hud.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(hud)
	var start_closed := not hud.is_panel_open() and not hud.is_pause_open()
	hud.open_pause()
	var opened := hud.is_pause_open() and hud.is_panel_open() and hud._route == "/pause"
	hud.close_pause()
	var closed := not hud.is_pause_open() and not hud.is_panel_open() and hud._route == "/"
	hud.toggle_inventory()
	hud.open_pause()
	var ignored := not hud.is_pause_open() and hud.is_inventory_open()
	hud.close_inventory()
	hud.open_pause()
	hud.show_lobby({})
	var lobby_closed := not hud.is_pause_open() and hud._route == "/lobby"
	hud.free()
	assert_true(start_closed, "starts on the plain HUD")
	assert_true(opened, "open_pause from / goes to /pause")
	assert_true(closed, "close_pause returns to /")
	assert_true(ignored, "open_pause does nothing while /inventory")
	assert_true(lobby_closed, "show_lobby clears the pause route")


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


func test_publish_snapshot_cache() -> void:
	var hud := Hud.new()
	hud.publish("lobby", {"canPlay": true})
	var lobby_json := String(hud._snapshots.get("lobby", ""))
	hud.publish("lobby", null)
	var lobby_cleared := not hud._snapshots.has("lobby")
	hud.publish("boot", {"phase": "title"})
	hud.publish("transfer", {"mapName": "Motel"})
	var count := hud._snapshots.size()
	hud.free()
	assert_true(lobby_json.contains("\"type\":\"lobby\""), "lobby snapshot is cached as JSON")
	assert_true(lobby_cleared, "null data clears the cached snapshot")
	assert_eq(count, 2, "boot and transfer keep two entries")


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


func test_player_name_streamer_mode() -> void:
	Hud.streamer_mode = false
	var off := Hud.player_name(12345)
	Hud.streamer_mode = true
	var on := Hud.player_name(12345)
	Hud.streamer_mode = false
	assert_eq(off, "Player 12345", "streamer off: full peer ID")
	assert_eq(on, "Player ••45", "streamer on: last two digits")


func test_redact_streamer_mode() -> void:
	Hud.streamer_mode = false
	var off := Hud.redact("Invite sent to player 678")
	Hud.streamer_mode = true
	var on := Hud.redact("Invite sent to player 678")
	var two := Hud.redact("Player 5 and Player 1234")
	var server := Hud.redact("Connected to SV-SPACE-0042")
	var state := Hud.snapshot({"notifications": [{"text": "Joined by Player 901", "expires_ms": 9999}]}, 0)
	Hud.streamer_mode = false
	assert_eq(off, "Invite sent to player 678", "streamer off: unchanged")
	assert_eq(on, "Invite sent to player ••78", "streamer on: player ID masked")
	assert_eq(two, "Player ••05 and Player ••34", "every player ID masked, two digits kept")
	assert_eq(server, "Connected to SV-SPACE-••••", "server ID masked")
	assert_eq(state["notifications"], ["Joined by Player ••01"], "snapshot notifications are redacted")


func test_set_minimap_rotate_headless() -> void:
	var hud := Hud.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(hud)
	hud.set_minimap_rotate(true)
	hud.free()
	assert_true(true, "set_minimap_rotate without a browser raises no error")


func test_party_view_no_party() -> void:
	var view := Hud.party_view(10, [], 0, [10, 11, 12], {}, "", 0)
	assert_true(view["canCreate"], "no party can create")
	assert_false(view["canLeave"], "no party cannot leave")
	assert_eq(view["members"], [], "no party has no members")
	assert_eq(view["players"].size(), 2, "roster minus self")
	assert_eq(view["players"][0]["peerId"], 11, "first roster player")
	assert_eq(view["players"][0]["name"], "Player 11", "roster player name")
	assert_true(view["players"][0]["canInvite"], "roster player invitable")
	assert_eq(view["incoming"], null, "no invite")
	assert_eq(view["pending"], null, "no pending")
	assert_eq(view["issue"], null, "no issue")


func test_party_view_leader_two_members() -> void:
	var view := Hud.party_view(10, [10, 11], 10, [10, 11, 12], {}, "invite", 0)
	var members: Array = view["members"]
	assert_eq(members.size(), 2, "two members")
	assert_eq(members[0]["peerId"], 10, "self listed")
	assert_true(members[0]["isSelf"], "self flagged")
	assert_true(members[0]["leader"], "self is leader")
	assert_false(members[0]["canKick"], "cannot kick self")
	assert_true(members[1]["canKick"], "can kick the other member")
	assert_eq(members[1]["presence"], "in_session", "presence in session")
	assert_eq(view["players"].size(), 1, "members removed from players")
	assert_eq(view["players"][0]["peerId"], 12, "only non-member left")
	assert_false(view["canCreate"], "in party cannot create")
	assert_true(view["canLeave"], "in party can leave")
	assert_true(view["canInvite"], "two members can invite")
	assert_eq(view["pending"], "invite", "pending verb")


func test_party_view_member_cannot_kick() -> void:
	var view := Hud.party_view(11, [10, 11], 10, [], {}, "", 0)
	for member: Dictionary in view["members"]:
		assert_false(member["canKick"], "non-leader cannot kick")


func test_party_view_full_party() -> void:
	var view := Hud.party_view(10, [10, 11, 12], 10, [10, 11, 12, 13], {}, "", 0)
	assert_false(view["canInvite"], "full party cannot invite")
	assert_eq(view["players"].size(), 1, "one outsider")
	assert_false(view["players"][0]["canInvite"], "outsider not invitable when full")


func test_party_view_invite_countdown() -> void:
	var now := 100000
	var invite := {"inviter": 12, "expires_ms": now + 12200}
	var view := Hud.party_view(10, [], 0, [], invite, "", now)
	var incoming: Dictionary = view["incoming"]
	assert_eq(incoming["inviterPeerId"], 12, "inviter id")
	assert_eq(incoming["name"], "Player 12", "inviter name")
	assert_eq(incoming["expiresInSeconds"], 13, "remaining seconds round up")
	assert_true(incoming["canAccept"], "not in a party can accept")
	var expired := Hud.party_view(10, [], 0, [], {"inviter": 12, "expires_ms": now}, "", now)
	assert_eq(expired["incoming"], null, "expired invite hidden")
	var in_party := Hud.party_view(10, [10, 11], 10, [], invite, "", now)
	assert_false(in_party["incoming"]["canAccept"], "in a party cannot accept")


func test_route_party_methods() -> void:
	var create := Hud.route_request({"id": 1, "method": "party.create", "params": {}}, 0)
	var leave := Hud.route_request({"id": 2, "method": "party.leave", "params": {}}, 0)
	var invite := Hud.route_request({"id": 3, "method": "party.invite", "params": {"targetPeerId": 5}}, 0)
	var kick := Hud.route_request({"id": 4, "method": "party.kick", "params": {"targetPeerId": 6.0}}, 0)
	var accept := Hud.route_request({"id": 5, "method": "party.accept", "params": {"inviterPeerId": 7}}, 0)
	var decline := Hud.route_request({"id": 6, "method": "party.decline", "params": {"inviterPeerId": 8}}, 0)
	var missing := Hud.route_request({"id": 7, "method": "party.invite", "params": {}}, 0)
	var negative := Hud.route_request({"id": 8, "method": "party.kick", "params": {"targetPeerId": -1}}, 0)
	var wrong_key := Hud.route_request({"id": 9, "method": "party.accept", "params": {"targetPeerId": 7}}, 0)
	assert_eq(create["action"], ["party", "create", 0], "create action")
	assert_eq(leave["action"], ["party", "leave", 0], "leave action")
	assert_eq(invite["action"], ["party", "invite", 5], "invite action")
	assert_eq(kick["action"], ["party", "kick", 6], "kick action from a JSON float")
	assert_eq(accept["action"], ["party", "accept", 7], "accept action")
	assert_eq(decline["action"], ["party", "decline", 8], "decline action")
	assert_true(invite["reply"]["ok"], "invite replies ok")
	assert_eq(missing["reply"].get("error"), "bad_params", "missing id is bad_params")
	assert_eq(negative["reply"].get("error"), "bad_params", "negative id is bad_params")
	assert_eq(wrong_key["reply"].get("error"), "bad_params", "accept needs inviterPeerId")
	assert_eq(missing["action"], [], "bad_params has no action")


func test_base_route() -> void:
	assert_eq(Hud.base_route(true, "death", false), "/transfer", "transfer wins")
	assert_eq(Hud.base_route(false, "death", false), "/death", "death receipt route")
	assert_eq(Hud.base_route(false, "arrest", false), "/arrest", "arrest receipt route")
	assert_eq(Hud.base_route(false, "death", true), "/", "a new spawn hides the receipt route")
	assert_eq(Hud.base_route(false, "", false), "/", "plain HUD")


func test_receipt_view() -> void:
	var death := {"receiptId": "r1", "kind": "death", "cause": "bleed_out", "started_ms": 1000, "player": 0}
	var arrest := {"receiptId": "r2", "kind": "arrest", "cause": "cuffed", "started_ms": 1000, "player": 0}
	assert_eq(Hud.receipt_view({}, 1300), null, "no receipt")
	var view: Dictionary = Hud.receipt_view(death, 1300)
	assert_eq(view["receiptId"], "r1", "receipt id")
	assert_eq(view["remainingMs"], 600, "remaining ms")
	assert_eq(view["kind"], "death", "kind")
	assert_eq(view["cause"], "bleed_out", "cause")
	assert_eq(view["destination"], GameConst.MAP_MOTEL, "destination")
	assert_false(view.has("bagForfeited"), "death has no bag flag")
	var arrest_view: Dictionary = Hud.receipt_view(arrest, 1300)
	assert_true(arrest_view["bagForfeited"], "arrest forfeits the bag")
	assert_true(arrest_view["gearKept"], "arrest keeps the gear")
	assert_eq(Hud.receipt_view(death, 1900), null, "expired receipt")


func test_transfer_timing() -> void:
	assert_eq(Hud.transfer_disconnect_error(1000, 9999), "disconnected", "early disconnect")
	assert_eq(Hud.transfer_disconnect_error(1000, 10000), "transfer_timeout", "disconnect near the deadline")
	assert_false(Hud.transfer_expired(1000, 11999), "not expired yet")
	assert_true(Hud.transfer_expired(1000, 12000), "expired")


func test_route_overlay_and_transfer_requests() -> void:
	var dismiss := Hud.route_request({"id": 1, "method": "overlay.dismiss", "params": {"receiptId": "r1"}}, 0)
	var bad := Hud.route_request({"id": 2, "method": "overlay.dismiss", "params": {"receiptId": 1}}, 0)
	var back := Hud.route_request({"id": 3, "method": "transfer.return_to_lobby", "params": {}}, 0)
	assert_true(dismiss["reply"]["ok"], "dismiss replies ok")
	assert_eq(dismiss["action"], ["overlay_dismiss", "r1"], "dismiss action")
	assert_eq(bad["reply"].get("error"), "bad_params", "non-string receipt id")
	assert_eq(back["reply"], null, "return to lobby replies later")
	assert_eq(back["action"], ["transfer_return_to_lobby", 3], "return to lobby action")


func test_receipt_and_transfer_state() -> void:
	var hud := Hud.new()
	hud.show_receipt("death", "bleed_out", 1000)
	var death_route: String = hud.get("_route")
	var first_id := String((hud.get("_receipt") as Dictionary).get("receiptId", ""))
	var click := hud.dismiss_receipt_by_click()
	hud.dismiss_receipt("nope")
	var kept := not (hud.get("_receipt") as Dictionary).is_empty()
	hud.show_receipt("death", "bleed_out", 1100)
	var second_id := String((hud.get("_receipt") as Dictionary).get("receiptId", ""))
	hud.begin_transfer("Motel", "Motel-01", "death", 1000)
	var transfer_route: String = hud.get("_route")
	var transferring := hud.is_transferring()
	var by_key := hud.dismiss_receipt_by_key()
	var route_after_key: String = hud.get("_route")
	hud.transfer_loaded()
	var loaded_stage := String((hud.get("_transfer") as Dictionary).get("stage", ""))
	hud.fail_transfer("map_load_failed")
	var on_disconnect := hud.fail_transfer_on_disconnect(20000)
	var error := String((hud.get("_transfer") as Dictionary).get("error", ""))
	var failed := hud.is_transfer_failed()
	hud.clear_transfer()
	var cleared_transferring := hud.is_transferring()
	var cleared_failed := hud.is_transfer_failed()
	var cleared_route: String = hud.get("_route")
	hud.free()
	assert_eq(death_route, "/death", "receipt shows the death route")
	assert_false(click, "click does not dismiss over the death route")
	assert_true(kept, "a wrong receipt id keeps the receipt")
	assert_true(first_id != second_id, "a newer receipt gets a new id")
	assert_eq(transfer_route, "/transfer", "transfer route")
	assert_true(transferring, "transferring")
	assert_true(by_key, "key dismisses the receipt over the transfer")
	assert_eq(route_after_key, "/transfer", "route stays on the transfer")
	assert_eq(loaded_stage, "waiting_for_spawn", "loaded waits for the spawn")
	assert_true(on_disconnect, "disconnect during a transfer is handled")
	assert_eq(error, "map_load_failed", "the earlier error is kept")
	assert_true(failed, "transfer failed")
	assert_false(cleared_transferring, "cleared: not transferring")
	assert_false(cleared_failed, "cleared: not failed")
	assert_eq(cleared_route, "/", "cleared: plain HUD")


func test_show_lobby_clears_transfer_and_receipt() -> void:
	var hud := Hud.new()
	hud.show_receipt("arrest", "cuffed", 1000)
	hud.begin_transfer("Motel", "Motel-01", "arrest", 1000)
	hud.show_lobby({})
	var transfer: Dictionary = hud.get("_transfer")
	var receipt: Dictionary = hud.get("_receipt")
	var route: String = hud.get("_route")
	hud.free()
	assert_true(transfer.is_empty(), "lobby clears the transfer")
	assert_true(receipt.is_empty(), "lobby clears the receipt")
	assert_eq(route, "/lobby", "lobby route")


func test_transfer_keeps_settings_open() -> void:
	var hud := Hud.new()
	hud.set("_route", "/settings/graphics")
	hud.begin_transfer("Motel", "Motel-01", "join", 1000)
	var route: String = hud.get("_route")
	hud.free()
	assert_eq(route, "/settings/graphics", "Settings stays open over a transfer")
