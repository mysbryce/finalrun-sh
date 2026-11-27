class_name LobbyState
extends RefCounted
## Client lobby data shown after the server connection drops. Pure data:
## Main sets the fields and publishes `view()` (LobbyView in
## docs/ui-design/DATA_CONTRACTS.md) to the page.

## ConnectionStatus: disconnected, resolving, connecting, connected, failed.
var status: String = "disconnected"
## ConnectionError string or null.
var error: Variant = null
## Display name or null (the page shows "Player").
var player_name: Variant = null
## loading, ready or failed.
var news_status: String = "loading"
var news_entries: Array = []


## LobbyView for the page. Only the current capabilities: no discovery, no party staging.
func view() -> Dictionary:
	return {
		"playerName": player_name,
		"connection": {"status": status, "serverId": null, "pingMs": null, "error": error},
		"capabilities": {"joinById": false, "quickJoin": false, "partyStaging": false},
		"canPlay": status != "connecting" and status != "resolving",
		"party": null,
		"appearance": {"status": "placeholder", "bodyType": null, "slots": {}},
		"news": {"status": news_status, "entries": news_entries.duplicate(true)},
	}


## Parses a PatchNotesFile. Malformed entries are dropped; entries are sorted
## newest first by `publishedOn`, then `version`. Bad JSON or no `entries` -> failed.
static func parse_news(text: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(text) != OK:
		return {"status": "failed", "entries": []}
	var parsed: Variant = json.data
	if not parsed is Dictionary or not (parsed as Dictionary).get("entries") is Array:
		return {"status": "failed", "entries": []}
	var entries: Array = []
	for raw: Variant in (parsed as Dictionary)["entries"]:
		if not raw is Dictionary:
			continue
		var entry := raw as Dictionary
		var valid := true
		for key: String in ["version", "publishedOn", "title", "summary"]:
			if not entry.get(key) is String:
				valid = false
				break
		if valid:
			entries.append({
				"version": entry["version"],
				"publishedOn": entry["publishedOn"],
				"title": entry["title"],
				"summary": entry["summary"],
			})
	entries.sort_custom(_newer_first)
	return {"status": "ready", "entries": entries}


## Reads and parses the bundled patch notes file; a missing file -> failed.
static func load_news(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"status": "failed", "entries": []}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"status": "failed", "entries": []}
	var text := file.get_as_text()
	file.close()
	return parse_news(text)


static func _newer_first(a: Dictionary, b: Dictionary) -> bool:
	var a_date := String(a["publishedOn"])
	var b_date := String(b["publishedOn"])
	if a_date != b_date:
		return a_date > b_date
	return String(a["version"]) > String(b["version"])
