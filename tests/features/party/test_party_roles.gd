extends TestCase
## Party role rules: COP and CRIMINAL may not share a party.

const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")


func test_cop_and_criminal_conflict() -> void:
	assert_true(
		PlayerService.parties_role_conflict(
			[RoleControllerScript.Role.COP],
			[RoleControllerScript.Role.CRIMINAL]
		),
		"COP and CRIMINAL conflict"
	)


func test_criminal_and_cop_conflict() -> void:
	assert_true(
		PlayerService.parties_role_conflict(
			[RoleControllerScript.Role.CITIZEN, RoleControllerScript.Role.CRIMINAL],
			[RoleControllerScript.Role.COP]
		),
		"CRIMINAL and COP conflict"
	)


func test_citizens_join_either_side() -> void:
	assert_true(
		not PlayerService.parties_role_conflict(
			[RoleControllerScript.Role.CITIZEN, RoleControllerScript.Role.COP],
			[RoleControllerScript.Role.CITIZEN]
		),
		"CITIZEN joins a COP side"
	)


func test_same_side_no_conflict() -> void:
	assert_true(
		not PlayerService.parties_role_conflict(
			[RoleControllerScript.Role.CRIMINAL],
			[RoleControllerScript.Role.CRIMINAL, RoleControllerScript.Role.CITIZEN]
		),
		"same side does not conflict"
	)


func test_empty_roles_no_conflict() -> void:
	assert_true(
		not PlayerService.parties_role_conflict([], [RoleControllerScript.Role.COP]),
		"empty roles do not conflict"
	)
