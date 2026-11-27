class_name ItemUtils
extends RefCounted
## Stateless helpers for the item dictionaries used by loot, gear and bodies.
##
## Item format: `{uid: int, id: String, value: int, issued: bool}`. The
## `source` tag ("bag" / "gear") is added only when items are listed for a
## search; it is never stored in an inventory. Uid allocation is stateful and
## therefore lives in `PlayerService`, not here.


## Builds one item. `uid` must come from `PlayerService.allocate_item_uid()`.
static func make_item(uid: int, item_id: String, value: int, issued: bool = false) -> Dictionary:
	return {
		"uid": uid,
		"id": item_id,
		"value": maxi(value, 0),
		"issued": issued,
	}


## Returns a deep copy of the item with that uid, or an empty dictionary.
static func find_by_uid(items: Array, uid: int) -> Dictionary:
	for item: Variant in items:
		if item is Dictionary and int((item as Dictionary).get("uid", 0)) == uid:
			return (item as Dictionary).duplicate(true)
	return {}


## Removes the item with that uid in place and returns a deep copy of it.
static func remove_by_uid(items: Array, uid: int) -> Dictionary:
	for index: int in range(items.size()):
		var item: Variant = items[index]
		if item is Dictionary and int((item as Dictionary).get("uid", 0)) == uid:
			items.remove_at(index)
			return (item as Dictionary).duplicate(true)
	return {}


## Returns deep copies of every item that may be looted (issued gear never is).
static func lootable_only(items: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: Dictionary in duplicate_items(items):
		if not bool(item.get("issued", false)):
			result.append(item)
	return result


## Returns deep copies of every dictionary entry, dropping non-dictionary values.
static func duplicate_items(items: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: Variant in items:
		if item is Dictionary:
			result.append((item as Dictionary).duplicate(true))
	return result
