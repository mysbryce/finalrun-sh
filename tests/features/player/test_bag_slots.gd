extends TestCase
## Bag grid slots: assignment on add, move and swap rules.

const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")


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


func test_footprint() -> void:
	assert_eq(RoleControllerScript.footprint(0, Vector2i(2, 3)), [0, 1, 6, 7, 12, 13], "2x3 at 0")
	assert_eq(RoleControllerScript.footprint(5, Vector2i(2, 1)), [], "past the right edge")
	assert_eq(RoleControllerScript.footprint(48, Vector2i(1, 2)), [], "past the bottom")
	assert_eq(RoleControllerScript.footprint(-1, Vector2i(1, 1)), [], "negative slot")


func test_grant_finds_fit() -> void:
	var player = RoleControllerScript.new()
	var box: Dictionary = player.grant_loot("cash_box", 100)
	var tech: Dictionary = player.grant_loot("electronics", 100)
	var gem: Dictionary = player.grant_loot("jewelry", 100)
	var slots := [int(box["slot"]), int(tech["slot"]), int(gem["slot"])]
	player.free()
	assert_eq(slots, [0, 2, 4], "grant_loot finds the first fit for each size")


func test_move_multi_cell() -> void:
	var player = RoleControllerScript.new()
	var box: Dictionary = player.grant_loot("cash_box", 100)
	var moved: bool = player.move_bag_item(int(box["uid"]), 7)
	var slot_after_move := int(box["slot"])
	var edge: bool = player.move_bag_item(int(box["uid"]), 5)
	var slot_after_edge := int(box["slot"])
	player.free()
	assert_true(moved, "move overlapping its own old cells succeeds")
	assert_eq(slot_after_move, 7, "cash box moved to 7")
	assert_false(edge, "move past the right edge is rejected")
	assert_eq(slot_after_edge, 7, "cash box stays at 7")


func test_move_swap_rules() -> void:
	var p1 = RoleControllerScript.new()
	var a: Dictionary = p1.grant_loot("jewelry", 100)
	var b: Dictionary = p1.grant_loot("jewelry", 100)
	var swap1: bool = p1.move_bag_item(int(a["uid"]), 1)
	var a_slot := int(a["slot"])
	var b_slot := int(b["slot"])
	p1.free()

	var p2 = RoleControllerScript.new()
	var c: Dictionary = p2.grant_loot("cash_box", 100)
	var e: Dictionary = p2.grant_loot("electronics", 100)
	var swap2: bool = p2.move_bag_item(int(e["uid"]), 0)
	var e_slot := int(e["slot"])
	var c_slot := int(c["slot"])
	p2.free()

	var p3 = RoleControllerScript.new()
	var j1: Dictionary = p3.grant_loot("jewelry", 100)
	var j2: Dictionary = p3.grant_loot("jewelry", 100)
	var e3: Dictionary = p3.grant_loot("electronics", 100)
	var swap3: bool = p3.move_bag_item(int(e3["uid"]), 0)
	var j1_slot := int(j1["slot"])
	var j2_slot := int(j2["slot"])
	var e3_slot := int(e3["slot"])
	p3.free()

	assert_true(swap1, "1x1 swap succeeds")
	assert_eq(a_slot, 1, "A moved to 1")
	assert_eq(b_slot, 0, "B swapped to 0")
	assert_true(swap2, "disjoint multi-cell swap succeeds")
	assert_eq(e_slot, 0, "electronics moved to 0")
	assert_eq(c_slot, 2, "cash box swapped to 2")
	assert_false(swap3, "footprint covering two items is rejected")
	assert_eq(j1_slot, 0, "J1 unchanged")
	assert_eq(j2_slot, 1, "J2 unchanged")
	assert_eq(e3_slot, 2, "electronics unchanged")


func test_bag_full() -> void:
	var player = RoleControllerScript.new()
	var all_placed := true
	for i: int in range(9):
		var painting: Dictionary = player.grant_loot("painting", 100)
		if int(painting["slot"]) < 0:
			all_placed = false
	var can_fit: bool = player.can_fit_bag("jewelry")
	var extra: Dictionary = player.grant_loot("jewelry", 1)
	var extra_slot := int(extra["slot"])
	player.free()
	assert_true(all_placed, "nine paintings fill the bag")
	assert_false(can_fit, "no room for a 1x1 item")
	assert_eq(extra_slot, -1, "grant into a full bag gets slot -1")
