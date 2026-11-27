extends TestCase
## AppearanceData sanitizing, round trip and deterministic defaults.


func test_round_trip() -> void:
	var source := AppearanceData.new()
	source.body_type = "female"
	source.slots = {"hair": "hair_long", "hat": "hat_cap"}
	var copy := AppearanceData.from_dict(source.to_dict())
	assert_eq(copy.body_type, "female", "round trip keeps body type")
	assert_eq(copy.slots, {"hair": "hair_long", "hat": "hat_cap"}, "round trip keeps slots")


func test_non_dictionary_gives_default() -> void:
	var from_null := AppearanceData.from_dict(null)
	assert_eq(from_null.body_type, "male", "null gives male")
	assert_true(from_null.slots.is_empty(), "null gives empty slots")
	var from_string := AppearanceData.from_dict("x")
	assert_eq(from_string.body_type, "male", "string gives male")
	assert_true(from_string.slots.is_empty(), "string gives empty slots")


func test_unknown_body_type_falls_back() -> void:
	var data := AppearanceData.from_dict({"body_type": "robot", "slots": {}})
	assert_eq(data.body_type, "male", "unknown body type gives male")


func test_unknown_slot_dropped() -> void:
	var data := AppearanceData.from_dict({"slots": {"wings": "wings_big", "hair": "hair_short"}})
	assert_eq(data.slots, {"hair": "hair_short"}, "unknown slot key is dropped")


func test_bad_ids_dropped() -> void:
	var data := AppearanceData.from_dict({"slots": {
		"hair": 5,
		"top": "",
		"mask": "a".repeat(65),
		"hat": "a".repeat(64),
	}})
	assert_eq(data.slots, {"hat": "a".repeat(64)}, "non-string, empty and 65-char ids are dropped")


func test_default_for_variety() -> void:
	assert_true(
		AppearanceData.default_for(1).body_type != AppearanceData.default_for(2).body_type,
		"default_for(1) and default_for(2) differ in body type"
	)
	assert_eq(
		AppearanceData.default_for(3).to_dict(),
		AppearanceData.default_for(3).to_dict(),
		"default_for is deterministic"
	)
	assert_eq(
		AppearanceData.default_for(-3).to_dict(),
		AppearanceData.default_for(3).to_dict(),
		"negative ids work"
	)


func test_default_ids_have_cosmetics() -> void:
	for peer_id: int in range(0, 8):
		var data := AppearanceData.default_for(peer_id)
		for slot: Variant in data.slots.keys():
			var path: String = GameConst.COSMETICS_DIR + String(data.slots[slot]) + ".tres"
			assert_true(ResourceLoader.exists(path), "cosmetic exists: %s" % path)
