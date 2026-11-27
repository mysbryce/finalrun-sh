extends TestCase


func test_view_keys_and_defaults() -> void:
	var view := LobbyState.new().view()
	var keys := view.keys()
	keys.sort()
	assert_eq(
		keys,
		["appearance", "canPlay", "capabilities", "connection", "news", "party", "playerName"],
		"exactly the LobbyView keys"
	)
	assert_eq(view["playerName"], null, "no display name yet")
	assert_eq(
		view["connection"],
		{"status": "disconnected", "serverId": null, "pingMs": null, "error": null},
		"disconnected without ping or server id"
	)
	assert_eq(
		view["capabilities"],
		{"joinById": false, "quickJoin": false, "partyStaging": false},
		"current capabilities are all false"
	)
	assert_true(bool(view["canPlay"]), "Play enabled while disconnected")
	assert_eq(view["party"], null, "no party panel")
	assert_eq(
		view["appearance"],
		{"status": "placeholder", "bodyType": null, "slots": {}},
		"placeholder preview"
	)
	assert_eq(view["news"], {"status": "loading", "entries": []}, "news starts loading")


func test_can_play_false_while_connecting() -> void:
	var lobby := LobbyState.new()
	lobby.status = "connecting"
	var connecting := bool(lobby.view()["canPlay"])
	lobby.status = "resolving"
	var resolving := bool(lobby.view()["canPlay"])
	lobby.status = "failed"
	lobby.error = "connection_failed"
	var failed_view := lobby.view()
	assert_false(connecting, "Play locked while connecting")
	assert_false(resolving, "Play locked while resolving")
	assert_true(bool(failed_view["canPlay"]), "Play available again after a failure")
	assert_eq(failed_view["connection"]["error"], "connection_failed", "error is passed through")


func test_parse_news_sorted_and_malformed_dropped() -> void:
	var text := JSON.stringify({"entries": [
		{"version": "0.1.0", "publishedOn": "2026-10-01", "title": "Old", "summary": "a"},
		{"version": "0.2.0", "publishedOn": "2026-11-27", "title": "New", "summary": "b"},
		{"version": "0.1.5", "publishedOn": "2026-11-27", "title": "Same day", "summary": "c"},
		{"version": "0.3.0", "publishedOn": "2026-12-01", "title": "Broken"},
		"not an entry",
	]})
	var news := LobbyState.parse_news(text)
	var titles: Array = []
	for entry: Dictionary in news["entries"]:
		titles.append(entry["title"])
	assert_eq(news["status"], "ready", "valid file is ready")
	assert_eq(titles, ["New", "Same day", "Old"], "newest first, malformed dropped")


func test_parse_news_failures() -> void:
	assert_eq(LobbyState.parse_news("not json {"), {"status": "failed", "entries": []}, "bad JSON fails")
	assert_eq(LobbyState.parse_news("{\"items\": []}"), {"status": "failed", "entries": []}, "no entries array fails")
	assert_eq(LobbyState.parse_news("{\"entries\": []}"), {"status": "ready", "entries": []}, "empty list is ready")
	assert_eq(LobbyState.load_news("res://does_not_exist.json")["status"], "failed", "missing file fails")
