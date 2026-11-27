extends TestCase
## Surrender, death and the pure outcome functions they delegate to.

const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")


func test_surrender() -> void:
	var criminal = RoleControllerScript.new()
	criminal.role = RoleControllerScript.Role.CRIMINAL
	criminal.grant_loot("gold_watch", 1000)
	criminal.grant_gear("kevlar_vest", 700)
	var gear_id_before: String = String(criminal.equipped_gear[0]["id"])

	var cop = RoleControllerScript.new()
	cop.role = RoleControllerScript.Role.COP

	var result: Dictionary = criminal.server_apply_surrender(cop)
	assert_true(bool(result.get("ok", false)), "surrender succeeds with a COP present")
	assert_eq(criminal.role, RoleControllerScript.Role.CITIZEN, "surrender turns CRIMINAL into CITIZEN")
	assert_eq(criminal.loot_bag.size(), 0, "surrender clears loot_bag")
	assert_eq(criminal.equipped_gear.size(), 1, "surrender keeps equipped_gear")
	assert_eq(
		String(criminal.equipped_gear[0]["id"]),
		gear_id_before,
		"surrender keeps the exact gear item"
	)
	assert_eq(int(result.get("reward", 0)), 500, "COP receives 50% of loot value")
	assert_eq(cop.cash, 500, "COP cash updated with surrender reward")
	assert_eq(criminal.notoriety, 0.0, "surrender resets notoriety")

	var citizen = RoleControllerScript.new()
	citizen.role = RoleControllerScript.Role.CITIZEN
	citizen.grant_loot("cash", 100)
	var invalid: Dictionary = citizen.server_apply_surrender(cop)
	assert_true(not bool(invalid.get("ok", false)), "CITIZEN cannot surrender")

	criminal.free()
	cop.free()
	citizen.free()


func test_surrender_outcome_is_pure() -> void:
	var criminal: int = RoleControllerScript.Role.CRIMINAL
	var cop: int = RoleControllerScript.Role.COP
	var citizen: int = RoleControllerScript.Role.CITIZEN

	var accepted: Dictionary = RoleControllerScript.surrender_outcome(criminal, cop, 1000)
	assert_true(bool(accepted.get("ok", false)), "pure surrender accepts CRIMINAL + COP")
	assert_eq(int(accepted.get("reward", 0)), 500, "pure surrender reward is the 50% ratio")
	assert_eq(int(accepted.get("loot_value", 0)), 1000, "pure surrender keeps the gross value")

	var rejected: Dictionary = RoleControllerScript.surrender_outcome(citizen, cop, 1000)
	assert_false(bool(rejected.get("ok", false)), "pure surrender rejects a CITIZEN")
	assert_eq(int(rejected.get("reward", 0)), 0, "rejected surrender pays nothing")


func test_criminal_death() -> void:
	var criminal = RoleControllerScript.new()
	criminal.role = RoleControllerScript.Role.CRIMINAL
	criminal.grant_loot("diamond", 1500)
	criminal.grant_loot("cash_stack", 250)
	criminal.grant_gear("rifle", 2200)
	criminal.grant_gear("armor", 800)

	var result: Dictionary = criminal.server_apply_death()
	assert_true(bool(result.get("drops", false)), "criminal death creates a loot drop")
	assert_eq((result["loot"] as Array).size(), 2, "loot drop contains all loot bag items")
	assert_eq((result["gear"] as Array).size(), 2, "loot drop contains all equipped gear")
	assert_eq(criminal.loot_bag.size(), 0, "criminal death clears loot_bag")
	assert_eq(criminal.equipped_gear.size(), 0, "criminal death clears equipped_gear")
	assert_eq(criminal.notoriety, 0.0, "criminal death resets notoriety")
	criminal.free()


func test_citizen_death() -> void:
	var citizen = RoleControllerScript.new()
	citizen.role = RoleControllerScript.Role.CITIZEN
	citizen.grant_loot("diamond", 1500)
	citizen.grant_gear("rifle", 2200)

	var result: Dictionary = citizen.server_apply_death()
	assert_true(not bool(result.get("drops", false)), "citizen death drops nothing")
	assert_eq((result["loot"] as Array).size(), 0, "citizen death loot drop is empty")
	assert_eq((result["gear"] as Array).size(), 0, "citizen death gear drop is empty")
	assert_eq(citizen.loot_bag.size(), 1, "citizen death keeps loot_bag")
	assert_eq(citizen.equipped_gear.size(), 1, "citizen death keeps equipped_gear")
	citizen.free()


func test_death_outcome_is_pure() -> void:
	var criminal: int = RoleControllerScript.Role.CRIMINAL
	var citizen: int = RoleControllerScript.Role.CITIZEN
	var loot: Array = [{"id": "diamond", "value": 1500}]
	var gear: Array = [{"id": "rifle", "value": 2200}]

	var criminal_result: Dictionary = RoleControllerScript.death_outcome(criminal, loot, gear)
	assert_true(bool(criminal_result.get("drops", false)), "pure criminal death drops")
	assert_eq((criminal_result["loot"] as Array).size(), 1, "pure criminal death copies loot")
	assert_eq((criminal_result["gear"] as Array).size(), 1, "pure criminal death copies gear")
	assert_eq(loot.size(), 1, "pure death outcome does not mutate the input loot")
	assert_eq(gear.size(), 1, "pure death outcome does not mutate the input gear")

	var citizen_result: Dictionary = RoleControllerScript.death_outcome(citizen, loot, gear)
	assert_false(bool(citizen_result.get("drops", false)), "pure citizen death drops nothing")
	assert_eq((citizen_result["loot"] as Array).size(), 0, "pure citizen death loot is empty")
	assert_eq(
		String(citizen_result.get("respawn_map", "")),
		"Motel",
		"death respawns at Motel"
	)


func test_cop_death_goes_off_duty() -> void:
	var cop = RoleControllerScript.new()
	cop.role = RoleControllerScript.Role.COP
	cop.cop_on_duty = true
	cop.grant_loot("diamond", 1500)
	cop.grant_gear("cop_pistol", 0)

	var result: Dictionary = cop.server_apply_death()
	assert_false(bool(result.get("drops", false)), "cop death drops nothing")
	assert_eq(cop.role, RoleControllerScript.Role.CITIZEN, "cop death returns to CITIZEN")
	assert_false(cop.cop_on_duty, "cop death goes off duty")
	assert_eq(cop.equipped_gear.size(), 0, "cop death clears free-issue gear")
	assert_eq(cop.loot_bag.size(), 1, "cop death keeps the loot bag")
	cop.free()
