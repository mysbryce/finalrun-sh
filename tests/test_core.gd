extends SceneTree
## Headless self-check for the core rules. Runs without a SceneTree main scene
## and without any network:   godot_console --headless -s res://tests/test_core.gd

const ServerManagerScript = preload("res://autoload/ServerManager.gd")
const PartyScript = preload("res://core/Party.gd")
const RoleControllerScript = preload("res://player/PlayerRoleController.gd")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_server_id()
	_test_party()
	_test_instance_pick()
	_test_attack_matrix()
	_test_surrender()
	_test_criminal_death()
	_test_citizen_death()

	if _failures.is_empty():
		print("ALL TESTS PASSED (%d assertions)" % _checks)
		quit(0)
	else:
		printerr("TESTS FAILED:")
		for failure: String in _failures:
			printerr("  - " + failure)
		quit(1)


func _test_server_id() -> void:
	var generated: String = ServerManagerScript.generate_server_id()
	_assert_true(
		ServerManagerScript.is_valid_server_id(generated),
		"server id matches SV-SPACE-XXXX (got %s)" % generated
	)
	_assert_eq(
		ServerManagerScript.format_server_id(7),
		"SV-SPACE-0007",
		"server id zero-pads to four digits"
	)
	_assert_eq(
		ServerManagerScript.format_server_id(42),
		"SV-SPACE-0042",
		"server id pads 42"
	)
	_assert_true(
		not ServerManagerScript.is_valid_server_id("SV-SPACE-123"),
		"three digit server id is rejected"
	)
	_assert_true(
		not ServerManagerScript.is_valid_server_id("SV-SPACE-12345"),
		"five digit server id is rejected"
	)
	_assert_true(
		not ServerManagerScript.is_valid_server_id("SV-SPACE-abcd"),
		"non numeric server id is rejected"
	)


func _test_party() -> void:
	var party = PartyScript.new(1, 100)
	_assert_eq(party.size(), 1, "party starts with the leader")
	_assert_true(party.is_leader(100), "creator is the leader")
	_assert_true(party.add_member(101), "party accepts second member")
	_assert_true(party.add_member(102), "party accepts third member")
	_assert_eq(party.size(), 3, "party reaches max size 3")
	_assert_true(party.is_full(), "party reports full at 3")
	_assert_true(not party.add_member(103), "party rejects fourth member")
	_assert_eq(party.size(), 3, "party stays at max size 3")
	_assert_true(not PartyScript.new(2, 200).add_member(200), "duplicate member is rejected")

	_assert_true(party.remove_member(100), "leader can leave")
	_assert_eq(party.leader_id, 101, "leadership transfers to the first remaining member")
	_assert_eq(party.size(), 2, "party shrinks after leave")
	_assert_true(not party.remove_member(999), "removing a non-member fails")


func _test_instance_pick() -> void:
	var candidates: Array = [
		{"id": "Motel-01", "capacity": 16, "used": 15},
		{"id": "Motel-02", "capacity": 16, "used": 12},
		{"id": "Motel-03", "capacity": 16, "used": 10},
	]
	var chosen: String = ServerManagerScript.select_instance(candidates, 3)
	_assert_eq(chosen, "Motel-02", "3-party goes to the fullest instance with >= 3 free slots")
	var chosen_entry: Dictionary = {}
	for candidate: Variant in candidates:
		if (candidate as Dictionary).get("id", "") == chosen:
			chosen_entry = candidate
	_assert_true(
		not chosen_entry.is_empty() and int(chosen_entry["capacity"]) - int(chosen_entry["used"]) >= 3,
		"chosen instance actually has >= 3 free slots"
	)
	_assert_eq(
		ServerManagerScript.select_instance(candidates, 5),
		"Motel-03",
		"5-party skips the 4-free instance"
	)
	_assert_eq(
		ServerManagerScript.select_instance(candidates, 7),
		"",
		"no fitting instance returns empty so the caller creates a new one"
	)
	_assert_eq(
		ServerManagerScript.format_instance_id("LootyBay", 3),
		"LootyBay-03",
		"instanced map ids are Name-NN"
	)
	_assert_eq(
		ServerManagerScript.format_instance_id("House", 3),
		"House",
		"shared map id is the map name"
	)


func _test_attack_matrix() -> void:
	var citizen: int = RoleControllerScript.Role.CITIZEN
	var criminal: int = RoleControllerScript.Role.CRIMINAL
	var cop: int = RoleControllerScript.Role.COP

	_assert_true(
		not RoleControllerScript.can_attack_roles(citizen, criminal, "LootyBay", false),
		"CITIZEN can never attack"
	)
	_assert_true(
		not RoleControllerScript.can_attack_roles(criminal, citizen, "LootyBay", false),
		"CRIMINAL cannot attack CITIZEN"
	)
	_assert_true(
		RoleControllerScript.can_attack_roles(criminal, criminal, "LootyBay", false),
		"CRIMINAL can attack CRIMINAL"
	)
	_assert_true(
		RoleControllerScript.can_attack_roles(criminal, cop, "LootyBay", false),
		"CRIMINAL can attack COP"
	)
	_assert_true(
		RoleControllerScript.can_attack_roles(cop, criminal, "LootyBay", false),
		"COP can attack CRIMINAL"
	)
	_assert_true(
		not RoleControllerScript.can_attack_roles(cop, cop, "LootyBay", false),
		"COP cannot attack COP"
	)
	_assert_true(
		not RoleControllerScript.can_attack_roles(cop, citizen, "LootyBay", false),
		"COP cannot attack CITIZEN"
	)
	_assert_true(
		not RoleControllerScript.can_attack_roles(criminal, criminal, "Motel", true),
		"no attacks in Motel safezone"
	)
	_assert_true(
		not RoleControllerScript.can_attack_roles(criminal, criminal, "House", false),
		"no attacks in House"
	)
	_assert_true(
		not RoleControllerScript.can_attack_roles(criminal, criminal, "Center", false),
		"no attacks in Center"
	)

	# Also exercise the instance method used at runtime (target is a controller).
	var attacker = RoleControllerScript.new()
	attacker.role = criminal
	attacker.map_name = "LootyBay"
	attacker.safezone = false
	var target = RoleControllerScript.new()
	target.role = cop
	_assert_true(attacker.can_attack(target), "instance can_attack: CRIMINAL -> COP")
	target.role = citizen
	_assert_true(not attacker.can_attack(target), "instance can_attack: CRIMINAL -> CITIZEN")
	attacker.safezone = true
	target.role = criminal
	_assert_true(not attacker.can_attack(target), "instance can_attack: safezone blocks everything")
	attacker.safezone = false
	attacker.role = cop
	target.role = criminal
	_assert_true(attacker.can_attack(target), "instance can_attack: COP -> CRIMINAL")
	target.role = cop
	_assert_true(not attacker.can_attack(target), "instance can_attack: COP -> COP")
	attacker.free()
	target.free()


func _test_surrender() -> void:
	var criminal = RoleControllerScript.new()
	criminal.role = RoleControllerScript.Role.CRIMINAL
	criminal.grant_loot("gold_watch", 1000)
	criminal.grant_gear("kevlar_vest", 700)
	var gear_id_before: String = String(criminal.equipped_gear[0]["id"])

	var cop = RoleControllerScript.new()
	cop.role = RoleControllerScript.Role.COP

	var result: Dictionary = criminal.server_apply_surrender(cop)
	_assert_true(bool(result.get("ok", false)), "surrender succeeds with a COP present")
	_assert_eq(criminal.role, RoleControllerScript.Role.CITIZEN, "surrender turns CRIMINAL into CITIZEN")
	_assert_eq(criminal.loot_bag.size(), 0, "surrender clears loot_bag")
	_assert_eq(criminal.equipped_gear.size(), 1, "surrender keeps equipped_gear")
	_assert_eq(
		String(criminal.equipped_gear[0]["id"]),
		gear_id_before,
		"surrender keeps the exact gear item"
	)
	_assert_eq(int(result.get("reward", 0)), 500, "COP receives 50% of loot value")
	_assert_eq(cop.cash, 500, "COP cash updated with surrender reward")
	_assert_eq(criminal.notoriety, 0.0, "surrender resets notoriety")

	var citizen = RoleControllerScript.new()
	citizen.role = RoleControllerScript.Role.CITIZEN
	citizen.grant_loot("cash", 100)
	var invalid: Dictionary = citizen.server_apply_surrender(cop)
	_assert_true(not bool(invalid.get("ok", false)), "CITIZEN cannot surrender")

	criminal.free()
	cop.free()
	citizen.free()


func _test_criminal_death() -> void:
	var criminal = RoleControllerScript.new()
	criminal.role = RoleControllerScript.Role.CRIMINAL
	criminal.grant_loot("diamond", 1500)
	criminal.grant_loot("cash_stack", 250)
	criminal.grant_gear("rifle", 2200)
	criminal.grant_gear("armor", 800)

	var result: Dictionary = criminal.server_apply_death()
	_assert_true(bool(result.get("drops", false)), "criminal death creates a loot drop")
	_assert_eq((result["loot"] as Array).size(), 2, "loot drop contains all loot bag items")
	_assert_eq((result["gear"] as Array).size(), 2, "loot drop contains all equipped gear")
	_assert_eq(criminal.loot_bag.size(), 0, "criminal death clears loot_bag")
	_assert_eq(criminal.equipped_gear.size(), 0, "criminal death clears equipped_gear")
	_assert_eq(criminal.notoriety, 0.0, "criminal death resets notoriety")
	criminal.free()


func _test_citizen_death() -> void:
	var citizen = RoleControllerScript.new()
	citizen.role = RoleControllerScript.Role.CITIZEN
	citizen.grant_loot("diamond", 1500)
	citizen.grant_gear("rifle", 2200)

	var result: Dictionary = citizen.server_apply_death()
	_assert_true(not bool(result.get("drops", false)), "citizen death drops nothing")
	_assert_eq((result["loot"] as Array).size(), 0, "citizen death loot drop is empty")
	_assert_eq((result["gear"] as Array).size(), 0, "citizen death gear drop is empty")
	_assert_eq(citizen.loot_bag.size(), 1, "citizen death keeps loot_bag")
	_assert_eq(citizen.equipped_gear.size(), 1, "citizen death keeps equipped_gear")
	citizen.free()


func _assert_true(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	_checks += 1
	var equal: bool = actual == expected
	if actual is float or expected is float:
		equal = is_equal_approx(float(actual), float(expected))
	if not equal:
		_failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])
