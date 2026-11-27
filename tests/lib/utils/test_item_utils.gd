extends TestCase
## Stateless item helpers used by inventories, bodies and drops.


func test_make_item_format() -> void:
	var item: Dictionary = ItemUtils.make_item(7, "diamond", 500)
	assert_eq(int(item.get("uid", 0)), 7, "make_item keeps the uid")
	assert_eq(String(item.get("id", "")), "diamond", "make_item keeps the id")
	assert_eq(int(item.get("value", 0)), 500, "make_item keeps the value")
	assert_false(bool(item.get("issued", true)), "make_item defaults to non-issued")
	var issued: Dictionary = ItemUtils.make_item(8, "cop_vest", 0, true)
	assert_true(bool(issued.get("issued", false)), "make_item accepts the issued flag")
	assert_eq(int(ItemUtils.make_item(9, "negative", -10).get("value", 1)), 0, "value is clamped at 0")


func test_find_and_remove_by_uid() -> void:
	var items: Array = [
		ItemUtils.make_item(1, "a", 10),
		ItemUtils.make_item(2, "b", 20),
	]
	var found: Dictionary = ItemUtils.find_by_uid(items, 2)
	assert_eq(String(found.get("id", "")), "b", "find_by_uid returns the matching item")
	assert_true(ItemUtils.find_by_uid(items, 99).is_empty(), "unknown uid returns empty")
	found["id"] = "mutated"
	assert_eq(String(items[1]["id"]), "b", "find_by_uid returns a copy")
	var removed: Dictionary = ItemUtils.remove_by_uid(items, 1)
	assert_eq(String(removed.get("id", "")), "a", "remove_by_uid returns the removed item")
	assert_eq(items.size(), 1, "remove_by_uid shrinks the array")
	assert_eq(int(items[0]["uid"]), 2, "the other item is untouched")
	assert_true(ItemUtils.remove_by_uid(items, 1).is_empty(), "removing twice fails")


func test_lootable_only_drops_issued() -> void:
	var items: Array = [
		ItemUtils.make_item(1, "diamond", 500),
		ItemUtils.make_item(2, "cop_pistol", 0, true),
		ItemUtils.make_item(3, "vest", 300, false),
	]
	var lootable: Array[Dictionary] = ItemUtils.lootable_only(items)
	assert_eq(lootable.size(), 2, "issued items are not lootable")
	assert_eq(String(lootable[0]["id"]), "diamond", "bag item stays lootable")
	assert_eq(String(lootable[1]["id"]), "vest", "non-issued gear stays lootable")
	lootable[0]["id"] = "changed"
	assert_eq(String(items[0]["id"]), "diamond", "lootable_only returns copies")


func test_item_sizes() -> void:
	assert_eq(ItemUtils.size_of("painting"), Vector2i(2, 3), "painting is 2x3")
	assert_eq(ItemUtils.size_of("unknown_thing"), Vector2i(1, 1), "unknown ids are 1x1")
