class_name LootDrop
extends Node3D
## A bag/gear container dropped when a player dies. The server owns the real
## contents through a `LootContainer`; clients only get a visual placeholder,
## never the item list.

var drop_id: String = ""
var owner_peer_id: int = 0
var loot_items: Array[Dictionary] = []
var gear_items: Array[Dictionary] = []
var container: LootContainer = null

var _visual_root: Node3D = null


func setup_server(owner_peer: int, loot: Array, gear: Array) -> void:
	owner_peer_id = owner_peer
	loot_items = ItemUtils.duplicate_items(loot)
	gear_items = ItemUtils.duplicate_items(gear)
	_build_visual()
	_create_container(loot_items, gear_items)


## The client only knows the placeholder id; contents stay on the server.
func setup_client(p_drop_id: String) -> void:
	drop_id = p_drop_id
	_build_visual()


func total_value() -> int:
	var total: int = 0
	for item: Dictionary in loot_items:
		total += int(item.get("value", 0))
	return total


func contents() -> Dictionary:
	return {
		"loot": ItemUtils.duplicate_items(loot_items),
		"gear": ItemUtils.duplicate_items(gear_items),
	}


func _create_container(loot: Array, gear: Array) -> void:
	container = LootContainer.new()
	container.name = "LootContainer"
	add_child(container)
	var tagged: Array[Dictionary] = []
	for item: Dictionary in ItemUtils.duplicate_items(loot):
		item["source"] = "bag"
		tagged.append(item)
	for item: Dictionary in ItemUtils.duplicate_items(gear):
		item["source"] = "gear"
		tagged.append(item)
	container.set_items(tagged)
	container.can_access = Callable(self, "_can_access")
	container.on_take = Callable(self, "_on_take")
	container.contents_changed.connect(_sync_item_arrays)
	container.emptied.connect(_on_emptied)


func _can_access(actor_peer: int) -> bool:
	var instance := _find_instance()
	if instance == null:
		return false
	var player := instance.get_player(actor_peer)
	if player == null:
		return false
	var controller := player.get_node_or_null("PlayerRoleController")
	if controller == null:
		return false
	var alive: Variant = controller.get("life_state")
	return alive != null and int(alive) == PlayerRoleController.LifeState.ALIVE


func _on_take(actor_peer: int, item: Dictionary) -> Dictionary:
	var instance := _find_instance()
	if instance == null:
		return {"ok": false, "reason": "invalid_state"}
	var player := instance.get_player(actor_peer)
	if player == null:
		return {"ok": false, "reason": "invalid_state"}
	var controller := player.get_node_or_null("PlayerRoleController") as PlayerRoleController
	if controller == null:
		return {"ok": false, "reason": "invalid_state"}
	controller.receive_item(item, String(item.get("source", "bag")))
	return {"ok": true, "item": item}


func _sync_item_arrays() -> void:
	loot_items.clear()
	gear_items.clear()
	if container == null:
		return
	for item: Dictionary in container.items():
		var stored: Dictionary = item.duplicate(true)
		var source := String(stored.get("source", "bag"))
		stored.erase("source")
		if source == "gear":
			gear_items.append(stored)
		else:
			loot_items.append(stored)


func _on_emptied() -> void:
	var instance := _find_instance()
	if instance != null:
		instance.rpc_to_members("client_remove_loot_drop", [drop_id])
	queue_free()


func _find_instance() -> GameInstance:
	var node: Node = self
	while node != null:
		if node is GameInstance:
			return node as GameInstance
		node = node.get_parent()
	return null


func _build_visual() -> void:
	if _visual_root != null:
		return
	_visual_root = Node3D.new()
	_visual_root.name = "Visual"
	add_child(_visual_root)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Bag"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.7, 0.45, 0.5)
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3(0.0, 0.25, 0.0)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.55, 0.38, 0.16, 1.0)
	mesh_instance.material_override = material
	_visual_root.add_child(mesh_instance)

	# No value label: the exact contents are server-only (privacy rule).
	var label := Label3D.new()
	label.name = "ValueLabel"
	label.text = "Loot"
	label.position = Vector3(0.0, 0.9, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	_visual_root.add_child(label)
