class_name ItemUtils
extends RefCounted
## Static helpers for the `{id, value}` item dictionaries used by loot and gear.


## Returns deep copies of every dictionary entry, dropping non-dictionary values.
static func duplicate_items(items: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: Variant in items:
		if item is Dictionary:
			result.append((item as Dictionary).duplicate(true))
	return result
