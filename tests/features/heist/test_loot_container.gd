extends TestCase
## Shared search container: viewers, take-by-uid and concurrent takes.


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _make_container(allow: bool = true, deny_after_first: bool = false) -> LootContainer:
	var container := LootContainer.new()
	_tree().root.add_child(container)
	container.set_items([
		ItemUtils.make_item(10, "diamond", 500),
		ItemUtils.make_item(11, "rifle", 900),
	])
	var takes: Array = []
	container.can_access = func(_actor: int) -> bool: return allow
	container.on_take = func(actor: int, item: Dictionary) -> Dictionary:
		takes.append([actor, int(item.get("uid", 0))])
		if deny_after_first and takes.size() > 1:
			return {"ok": false, "reason": "invalid_state"}
		return {"ok": true, "item": item}
	return container


func _drop(container: LootContainer) -> void:
	_tree().root.remove_child(container)
	container.free()


func test_take_by_uid_and_viewers() -> void:
	var container := _make_container()
	container.add_viewer(100)
	container.add_viewer(101)
	assert_eq(container.viewers().size(), 2, "both viewers are tracked")
	container.remove_viewer(100)
	assert_eq(container.viewers(), [101] as Array[int], "viewers can be removed")
	var result: Dictionary = container.take(101, 10)
	assert_true(bool(result.get("ok", false)), "take succeeds")
	assert_eq(String((result["item"] as Dictionary).get("id", "")), "diamond", "the taken item is returned")
	assert_eq(container.items().size(), 1, "the container shrinks")
	assert_eq(int(container.items()[0]["uid"]), 11, "the other uid remains")
	_drop(container)


func test_second_take_on_same_uid_fails() -> void:
	var container := _make_container()
	var first: Dictionary = container.take(100, 10)
	var second: Dictionary = container.take(100, 10)
	assert_true(bool(first.get("ok", false)), "first take wins")
	assert_false(bool(second.get("ok", false)), "second take on the same uid fails")
	assert_eq(container.items().size(), 1, "only one item was removed")
	_drop(container)


func test_access_denial_leaves_items() -> void:
	var container := _make_container(false)
	var result: Dictionary = container.take(100, 10)
	assert_false(bool(result.get("ok", false)), "can_access rejects the take")
	assert_eq(String(result.get("reason", "")), "invalid_state", "denial carries a reason")
	assert_eq(container.items().size(), 2, "denied takes do not remove items")
	_drop(container)


func test_emptied_signal() -> void:
	var container := _make_container()
	var emptied: Array[bool] = []
	container.emptied.connect(func() -> void: emptied.append(true))
	container.take(100, 10)
	assert_eq(emptied.size(), 0, "not empty after the first take")
	container.take(100, 11)
	assert_eq(emptied.size(), 1, "emptied fires when the last item leaves")
	_drop(container)


func test_failed_on_take_keeps_item() -> void:
	var container := _make_container(true, true)
	container.take(100, 10)
	var second: Dictionary = container.take(100, 11)
	assert_false(bool(second.get("ok", false)), "a failing on_take callback cancels the take")
	assert_eq(container.items().size(), 1, "the item stays when on_take fails")
	_drop(container)
