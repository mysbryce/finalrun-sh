extends TestCase
## Lootable rules and the LootyBay crate placement.

const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")


func test_criminal_alive_may_loot() -> void:
	assert_true(
		Lootable.role_may_loot(RoleControllerScript.Role.CRIMINAL, RoleControllerScript.LifeState.ALIVE),
		"an ALIVE CRIMINAL may loot"
	)


func test_citizen_and_cop_may_not_loot() -> void:
	assert_false(
		Lootable.role_may_loot(RoleControllerScript.Role.CITIZEN, RoleControllerScript.LifeState.ALIVE),
		"a CITIZEN may not loot"
	)
	assert_false(
		Lootable.role_may_loot(RoleControllerScript.Role.COP, RoleControllerScript.LifeState.ALIVE),
		"a COP may not loot"
	)


func test_downed_criminal_may_not_loot() -> void:
	assert_false(
		Lootable.role_may_loot(RoleControllerScript.Role.CRIMINAL, RoleControllerScript.LifeState.DOWNED),
		"a DOWNED CRIMINAL may not loot"
	)


func test_lootable_name_validation() -> void:
	assert_true(Lootable.is_valid_lootable_name("Crate01"), "a plain node name is valid")
	assert_false(Lootable.is_valid_lootable_name(""), "an empty name is invalid")
	assert_false(Lootable.is_valid_lootable_name("../Map"), "path parts are invalid")
	assert_false(Lootable.is_valid_lootable_name("Lootables/Crate01"), "a slash is invalid")


func test_looty_bay_has_crates() -> void:
	var root := (load("res://maps/looty_bay/LootyBay.tscn") as PackedScene).instantiate()
	var crate := Lootable.find_in(root, "Crate01")
	var has_crate := crate != null
	var crate_value := crate.value if has_crate else -1
	var has_area := has_crate and crate.get_node_or_null("InteractArea") is InteractArea
	var bad_lookup_null := Lootable.find_in(root, "../LootyBay") == null
	root.free()
	assert_true(has_crate, "LootyBay has Crate01")
	assert_eq(crate_value, 300, "Crate01 is worth 300")
	assert_true(has_area, "Crate01 has an InteractArea")
	assert_true(bad_lookup_null, "a path-shaped name finds nothing")
