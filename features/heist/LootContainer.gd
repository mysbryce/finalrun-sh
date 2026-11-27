class_name LootContainer
extends Node
## Searchable item list with viewers and take-by-uid.
##
## The owner supplies the authority: `can_access(actor_peer)` decides whether a
## take is currently allowed and `on_take(actor_peer, item)` performs the
## removal/grant and returns `{ok: bool, ...}`. The downed body and `LootDrop`
## share this node, so concurrent takes always go through one list.

signal contents_changed
signal emptied

## Callable(actor_peer: int) -> bool.
var can_access: Callable = Callable()
## Callable(actor_peer: int, item: Dictionary) -> Dictionary with "ok".
var on_take: Callable = Callable()

var _items: Array[Dictionary] = []
var _viewers: Array[int] = []


func set_items(items: Array) -> void:
	_items = ItemUtils.duplicate_items(items)


## Deep copy: viewers receive data, never a live reference to the server list.
func items() -> Array[Dictionary]:
	return ItemUtils.duplicate_items(_items)


func is_empty() -> bool:
	return _items.is_empty()


func add_viewer(peer_id: int) -> void:
	if peer_id > 0 and not _viewers.has(peer_id):
		_viewers.append(peer_id)


func remove_viewer(peer_id: int) -> void:
	_viewers.erase(peer_id)


func viewers() -> Array[int]:
	return _viewers.duplicate()


## Removes one item by uid through the injected take callback. A second take on
## the same uid fails because the item is gone.
func take(actor_peer: int, item_uid: int) -> Dictionary:
	if can_access.is_valid() and not bool(can_access.call(actor_peer)):
		return {"ok": false, "reason": "invalid_state"}
	var item: Dictionary = ItemUtils.find_by_uid(_items, item_uid)
	if item.is_empty():
		return {"ok": false, "reason": "invalid_state"}
	var result: Dictionary = {"ok": true, "item": item}
	if on_take.is_valid():
		result = on_take.call(actor_peer, item.duplicate(true))
	if not bool(result.get("ok", false)):
		return result
	ItemUtils.remove_by_uid(_items, item_uid)
	contents_changed.emit()
	if _items.is_empty():
		emptied.emit()
	return result
