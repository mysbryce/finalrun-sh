extends TestCase
## PlayerService.surrender_block outcomes and their check order.

const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")
const ALIVE := RoleControllerScript.LifeState.ALIVE
const DOWNED := RoleControllerScript.LifeState.DOWNED
const CRIMINAL := RoleControllerScript.Role.CRIMINAL
const CITIZEN := RoleControllerScript.Role.CITIZEN
const BAY := GameConst.MAP_LOOTY_BAY
const MOTEL := GameConst.MAP_MOTEL


func test_all_pass() -> void:
	assert_eq(PlayerService.surrender_block(false, true, BAY, CRIMINAL, ALIVE, true), "", "all checks pass")


func test_each_outcome() -> void:
	assert_eq(PlayerService.surrender_block(true, true, BAY, CRIMINAL, ALIVE, true), "silent", "in transfer")
	assert_eq(PlayerService.surrender_block(false, false, BAY, CRIMINAL, ALIVE, true), "silent", "no player")
	assert_eq(PlayerService.surrender_block(false, true, BAY, CRIMINAL, DOWNED, true), "silent", "not alive")
	assert_eq(PlayerService.surrender_block(false, true, MOTEL, CRIMINAL, ALIVE, true), "map", "not LootyBay")
	assert_eq(PlayerService.surrender_block(false, true, BAY, CITIZEN, ALIVE, true), "role", "not criminal")
	assert_eq(PlayerService.surrender_block(false, true, BAY, CRIMINAL, ALIVE, false), "no_cop", "no cop")


func test_order() -> void:
	assert_eq(PlayerService.surrender_block(true, true, MOTEL, CITIZEN, ALIVE, false), "silent", "transfer beats map")
	assert_eq(PlayerService.surrender_block(false, true, MOTEL, CITIZEN, ALIVE, false), "map", "map beats role")
	assert_eq(PlayerService.surrender_block(false, true, BAY, CITIZEN, ALIVE, false), "role", "role beats no_cop")
