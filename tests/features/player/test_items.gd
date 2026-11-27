extends TestCase
## Item uid ownership, transfer rules and notoriety bookkeeping.

const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")


func test_grant_items_get_unique_uids_and_issued_flag() -> void:
	var player = RoleControllerScript.new()
	var loot: Dictionary = player.grant_loot("diamond", 500)
	var gear: Dictionary = player.grant_gear("cop_pistol", 0, true)
	assert_true(int(loot.get("uid", 0)) > 0, "loot receives a positive uid")
	assert_true(int(gear.get("uid", 0)) > 0, "gear receives a positive uid")
	assert_true(int(loot["uid"]) != int(gear["uid"]), "uids are unique within a controller")
	assert_false(bool(loot.get("issued", false)), "loot is not issued")
	assert_true(bool(gear.get("issued", false)), "issued gear keeps its flag")
	assert_eq(player.notoriety, 500.0, "loot raises notoriety by its value")
	player.free()


func test_item_uid_kept_on_transfer() -> void:
	var victim = RoleControllerScript.new()
	var bag_item: Dictionary = victim.grant_loot("diamond", 500)
	var uid: int = int(bag_item["uid"])
	var snapshot: Dictionary = victim.export_state()
	var receiver = RoleControllerScript.new()
	receiver.apply_state(snapshot)
	assert_eq(receiver.loot_bag.size(), 1, "snapshot restores the item")
	assert_eq(int(receiver.loot_bag[0]["uid"]), uid, "transfer snapshot keeps the uid")
	var received: Dictionary = receiver.receive_item(receiver.loot_bag[0], "bag")
	assert_eq(int(received["uid"]), uid, "receive_item keeps the uid")
	assert_false(received.has("source"), "source tags are not stored in an inventory")
	victim.free()
	receiver.free()


func test_apply_state_assigns_missing_uids() -> void:
	var player = RoleControllerScript.new()
	player.apply_state({
		"loot_bag": [{"id": "old_loot", "value": 100}],
		"equipped_gear": [{"id": "old_gear", "value": 50}],
	})
	assert_true(int(player.loot_bag[0].get("uid", 0)) > 0, "missing bag uid is assigned")
	assert_true(int(player.equipped_gear[0].get("uid", 0)) > 0, "missing gear uid is assigned")
	assert_true(
		int(player.loot_bag[0]["uid"]) != int(player.equipped_gear[0]["uid"]),
		"assigned uids are unique"
	)
	player.free()


func test_remove_item_lowers_victim_notoriety() -> void:
	var victim = RoleControllerScript.new()
	var first: Dictionary = victim.grant_loot("diamond", 800)
	victim.grant_loot("cash", 400)
	assert_eq(victim.notoriety, 1200.0, "both loot items raised notoriety")
	var removed: Dictionary = victim.remove_item_by_uid(int(first["uid"]))
	assert_eq(String(removed.get("id", "")), "diamond", "remove returns the matching item")
	assert_eq(victim.notoriety, 400.0, "victim notoriety falls by the item value")
	assert_eq(victim.loot_bag.size(), 1, "only the removed item leaves the bag")
	var gear: Dictionary = victim.grant_gear("rifle", 900)
	victim.remove_item_by_uid(int(gear["uid"]))
	assert_eq(victim.notoriety, 400.0, "removing gear leaves notoriety unchanged")
	victim.free()


func test_receive_bag_item_raises_taker_notoriety() -> void:
	var victim = RoleControllerScript.new()
	var item: Dictionary = victim.grant_loot("diamond", 700)
	var taker = RoleControllerScript.new()
	taker.receive_item(item, "bag")
	assert_eq(taker.notoriety, 700.0, "taker gains notoriety for a taken bag item")
	taker.receive_item(ItemUtils.make_item(999, "vest", 400, false), "gear")
	assert_eq(taker.notoriety, 700.0, "taken gear does not raise notoriety")
	assert_eq(taker.equipped_gear.size(), 1, "gear lands in equipped_gear")
	victim.free()
	taker.free()
