class_name AppearanceData
extends Resource
## Public character appearance: body type plus slot -> cosmetic id.
##
## Server-owned and sent in the spawn payload, so it must stay public data.

const MAX_ID_LENGTH: int = 64

@export var body_type: String = "male"
## slot name (GameConst.APPEARANCE_SLOTS) -> cosmetic id
@export var slots: Dictionary = {}


func to_dict() -> Dictionary:
	return {"body_type": body_type, "slots": slots.duplicate()}


## Builds a sanitized appearance from untrusted data. Never fails: anything
## invalid falls back to the defaults or is dropped.
static func from_dict(data: Variant) -> AppearanceData:
	var result := AppearanceData.new()
	if not (data is Dictionary):
		return result
	var dict: Dictionary = data
	var body: Variant = dict.get("body_type", "")
	if body is String and GameConst.BODY_TYPES.has(body):
		result.body_type = body
	var raw_slots: Variant = dict.get("slots", {})
	if raw_slots is Dictionary:
		for key: Variant in (raw_slots as Dictionary).keys():
			if not (key is String) or not GameConst.APPEARANCE_SLOTS.has(key):
				continue
			var value: Variant = (raw_slots as Dictionary)[key]
			if not (value is String):
				continue
			var item_id: String = value
			if item_id.is_empty() or item_id.length() > MAX_ID_LENGTH:
				continue
			result.slots[key] = item_id
	return result


## Deterministic variety for tests and smoke runs.
static func default_for(peer_id: int) -> AppearanceData:
	var n: int = absi(peer_id)
	var result := AppearanceData.new()
	result.body_type = GameConst.BODY_TYPES[n % 2]
	result.slots = {
		"hair": ["hair_short", "hair_long"][n % 2],
		"top": ["top_tee", "top_jacket"][floori(n / 2.0) % 2],
		"mask": "mask_basic",
	}
	return result
