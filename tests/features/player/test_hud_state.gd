extends TestCase
## Owner-only HUD state: the numbers sent to the owning client.

const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")


func test_hud_state_empty() -> void:
	var controller: PlayerRoleController = RoleControllerScript.new()
	var state := PlayerService.hud_state_of(controller)
	controller.free()
	assert_eq(state["cash"], 0, "a new controller has no cash")
	assert_eq(state["bag_value"], 0, "a new controller has an empty bag")
	assert_eq(state["notoriety"], 0.0, "a new controller has no notoriety")


func test_hud_state_counts_bag_and_cash() -> void:
	var controller: PlayerRoleController = RoleControllerScript.new()
	controller.grant_loot("jewelry", 300)
	controller.grant_loot("cash_box", 200)
	controller.cash = 50
	var state := PlayerService.hud_state_of(controller)
	controller.free()
	assert_eq(state["cash"], 50, "HUD state reports cash")
	assert_eq(state["bag_value"], 500, "HUD state sums the loot bag")
	assert_eq(state["notoriety"], 500.0, "HUD state reports notoriety")


func test_hud_state_has_only_owner_fields() -> void:
	var controller: PlayerRoleController = RoleControllerScript.new()
	var state := PlayerService.hud_state_of(controller)
	controller.free()
	var keys: Array = state.keys()
	keys.sort()
	assert_eq(keys, ["bag_value", "cash", "notoriety"], "HUD state exposes only owner fields")
