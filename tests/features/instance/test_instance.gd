extends TestCase
## GameInstance shared weapons-lock rule.


func test_weapons_locked_for() -> void:
	assert_true(GameInstance.weapons_locked_for(GameConst.MAP_MOTEL, true), "Motel safezone is locked")
	assert_true(GameInstance.weapons_locked_for(GameConst.MAP_HOUSE, false), "House is locked")
	assert_true(GameInstance.weapons_locked_for(GameConst.MAP_CENTER, false), "Center is locked")
	assert_false(GameInstance.weapons_locked_for(GameConst.MAP_LOOTY_BAY, false), "LootyBay is unlocked")
