extends TestCase
## Pure instance selection and id formatting, no scene tree needed.


func test_instance_selection() -> void:
	var candidates: Array = [
		{"id": "Motel-01", "capacity": 16, "used": 15},
		{"id": "Motel-02", "capacity": 16, "used": 12},
		{"id": "Motel-03", "capacity": 16, "used": 10},
	]
	var chosen: String = InstanceRegistry.select_instance(candidates, 3)
	assert_eq(chosen, "Motel-02", "3-party goes to the fullest instance with >= 3 free slots")
	var chosen_entry: Dictionary = {}
	for candidate: Variant in candidates:
		if (candidate as Dictionary).get("id", "") == chosen:
			chosen_entry = candidate
	assert_true(
		not chosen_entry.is_empty() and int(chosen_entry["capacity"]) - int(chosen_entry["used"]) >= 3,
		"chosen instance actually has >= 3 free slots"
	)
	assert_eq(
		InstanceRegistry.select_instance(candidates, 5),
		"Motel-03",
		"5-party skips the 4-free instance"
	)
	assert_eq(
		InstanceRegistry.select_instance(candidates, 7),
		"",
		"no fitting instance returns empty so the caller creates a new one"
	)
	assert_eq(
		InstanceRegistry.format_instance_id("LootyBay", 3),
		"LootyBay-03",
		"instanced map ids are Name-NN"
	)
	assert_eq(
		InstanceRegistry.format_instance_id("House", 3),
		"House",
		"shared map id is the map name"
	)


func test_instance_id_and_shared_rules() -> void:
	assert_eq(InstanceRegistry.format_instance_id("Motel", 1), "Motel-01", "Motel ids are zero padded")
	assert_true(InstanceRegistry.is_shared_map("House"), "House is shared")
	assert_true(InstanceRegistry.is_shared_map("Center"), "Center is shared")
	assert_false(InstanceRegistry.is_shared_map("Motel"), "Motel is instanced")
	assert_eq(InstanceRegistry.select_instance([], 1), "", "empty candidate list has no match")
	assert_eq(InstanceRegistry.select_instance([], 0), "", "zero party size is invalid")
