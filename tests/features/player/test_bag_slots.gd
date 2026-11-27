extends TestCase
## Bag grid slots: assignment on add, move and swap rules.

const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")


func test_first_free_slot() -> void:
	assert_eq(RoleControllerScript.first_free_slot([]), 0, "empty bag starts at 0")
	assert_eq(RoleControllerScript.first_free_slot([{"slot": 0}, {"slot": 2}]), 1, "fills the gap")
	assert_eq(RoleControllerScript.first_free_slot([{"slot": 0}, {"slot": 1}]), 2, "next after full run")


func test_grant_assigns_slots() -> void:
	var player = RoleControllerScript.new()
	var a: Dictionary = player.grant_loot("jewelry", 100)
	var b: Dictionary = player.grant_loot("jewelry", 100)
	var c: Dictionary = player.grant_loot("jewelry", 100)
	var slots := [int(a["slot"]), int(b["slot"]), int(c["slot"])]
	player.free()
	assert_eq(slots, [0, 1, 2], "grant_loot assigns sequential slots")


func test_move_to_empty_slot() -> void:
	var player = RoleControllerScript.new()
	var a: Dictionary = player.grant_loot("jewelry", 100)
	var b: Dictionary = player.grant_loot("jewelry", 100)
	var moved: bool = player.move_bag_item(int(b["uid"]), 5)
	var a_slot := int(a["slot"])
	var b_slot := int(b["slot"])
	player.free()
	assert_true(moved, "move to an empty slot succeeds")
	assert_eq(b_slot, 5, "B moved to slot 5")
	assert_eq(a_slot, 0, "A stays in slot 0")


func test_move_swaps() -> void:
	var player = RoleControllerScript.new()
	var a: Dictionary = player.grant_loot("jewelry", 100)
	var b: Dictionary = player.grant_loot("jewelry", 100)
	var moved: bool = player.move_bag_item(int(a["uid"]), 1)
	var a_slot := int(a["slot"])
	var b_slot := int(b["slot"])
	player.free()
	assert_true(moved, "move onto an occupied slot succeeds")
	assert_eq(a_slot, 1, "A moved to slot 1")
	assert_eq(b_slot, 0, "B swapped to slot 0")


func test_move_rejects() -> void:
	var player = RoleControllerScript.new()
	var a: Dictionary = player.grant_loot("jewelry", 100)
	var b: Dictionary = player.grant_loot("jewelry", 100)
	var unknown: bool = player.move_bag_item(9999, 3)
	var negative: bool = player.move_bag_item(int(a["uid"]), -1)
	var too_big: bool = player.move_bag_item(int(a["uid"]), GameConst.INVENTORY_BAG_SLOTS)
	var a_slot := int(a["slot"])
	var b_slot := int(b["slot"])
	player.free()
	assert_false(unknown, "unknown uid is rejected")
	assert_false(negative, "slot -1 is rejected")
	assert_false(too_big, "slot past the grid is rejected")
	assert_eq(a_slot, 0, "A slot unchanged")
	assert_eq(b_slot, 1, "B slot unchanged")


func test_receive_reassigns_slot() -> void:
	var player = RoleControllerScript.new()
	player.grant_loot("jewelry", 100)
	var bag_item: Dictionary = player.receive_item({"uid": 99, "id": "jewelry", "value": 300, "slot": 7}, "bag")
	var gear_item: Dictionary = player.receive_item({"uid": 98, "id": "cop_radio", "value": 0, "slot": 3}, "gear")
	var bag_slot := int(bag_item.get("slot", -1))
	var gear_has_slot := gear_item.has("slot")
	player.free()
	assert_eq(bag_slot, 1, "received bag item gets the first free slot")
	assert_false(gear_has_slot, "gear items carry no slot")
