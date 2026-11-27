extends TestCase
## Role combat matrix and the pure notoriety sale multiplier.

const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")


func test_attack_matrix() -> void:
	var citizen: int = RoleControllerScript.Role.CITIZEN
	var criminal: int = RoleControllerScript.Role.CRIMINAL
	var cop: int = RoleControllerScript.Role.COP

	assert_true(
		not RoleControllerScript.can_attack_roles(citizen, criminal, "LootyBay", false),
		"CITIZEN can never attack"
	)
	assert_true(
		not RoleControllerScript.can_attack_roles(criminal, citizen, "LootyBay", false),
		"CRIMINAL cannot attack CITIZEN"
	)
	assert_true(
		RoleControllerScript.can_attack_roles(criminal, criminal, "LootyBay", false),
		"CRIMINAL can attack CRIMINAL"
	)
	assert_true(
		RoleControllerScript.can_attack_roles(criminal, cop, "LootyBay", false),
		"CRIMINAL can attack COP"
	)
	assert_true(
		RoleControllerScript.can_attack_roles(cop, criminal, "LootyBay", false),
		"COP can attack CRIMINAL"
	)
	assert_true(
		not RoleControllerScript.can_attack_roles(cop, cop, "LootyBay", false),
		"COP cannot attack COP"
	)
	assert_true(
		not RoleControllerScript.can_attack_roles(cop, citizen, "LootyBay", false),
		"COP cannot attack CITIZEN"
	)
	assert_true(
		not RoleControllerScript.can_attack_roles(criminal, criminal, "Motel", true),
		"no attacks in Motel safezone"
	)
	assert_true(
		not RoleControllerScript.can_attack_roles(criminal, criminal, "House", false),
		"no attacks in House"
	)
	assert_true(
		not RoleControllerScript.can_attack_roles(criminal, criminal, "Center", false),
		"no attacks in Center"
	)


func test_instance_can_attack() -> void:
	var citizen: int = RoleControllerScript.Role.CITIZEN
	var criminal: int = RoleControllerScript.Role.CRIMINAL
	var cop: int = RoleControllerScript.Role.COP

	# Also exercise the instance method used at runtime (target is a controller).
	var attacker = RoleControllerScript.new()
	attacker.role = criminal
	attacker.map_name = "LootyBay"
	attacker.safezone = false
	var target = RoleControllerScript.new()
	target.role = cop
	assert_true(attacker.can_attack(target), "instance can_attack: CRIMINAL -> COP")
	target.role = citizen
	assert_true(not attacker.can_attack(target), "instance can_attack: CRIMINAL -> CITIZEN")
	attacker.safezone = true
	target.role = criminal
	assert_true(not attacker.can_attack(target), "instance can_attack: safezone blocks everything")
	attacker.safezone = false
	attacker.role = cop
	target.role = criminal
	assert_true(attacker.can_attack(target), "instance can_attack: COP -> CRIMINAL")
	target.role = cop
	assert_true(not attacker.can_attack(target), "instance can_attack: COP -> COP")
	attacker.free()
	target.free()


func test_sell_multiplier() -> void:
	assert_eq(RoleControllerScript.sell_multiplier(0.0), 1.0, "no notoriety means 1x")
	assert_eq(RoleControllerScript.sell_multiplier(5000.0), 1.5, "halfway to the cap is 1.5x")
	assert_eq(RoleControllerScript.sell_multiplier(10000.0), 2.0, "one notoriety unit adds 1x")
	assert_eq(RoleControllerScript.sell_multiplier(30000.0), 2.5, "multiplier caps at 2.5x")
