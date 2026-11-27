class_name LootDrop
extends Node3D
## A bag/gear container dropped when a criminal dies. The server owns the real
## contents; clients only get a mirrored visual placeholder.

var drop_id: String = ""
var owner_peer_id: int = 0
var loot_items: Array[Dictionary] = []
var gear_items: Array[Dictionary] = []

var _visual_root: Node3D = null


func setup_server(owner_peer: int, loot: Array, gear: Array) -> void:
	owner_peer_id = owner_peer
	loot_items = ItemUtils.duplicate_items(loot)
	gear_items = ItemUtils.duplicate_items(gear)
	_build_visual(true)


func setup_client(p_drop_id: String, loot: Array, gear: Array) -> void:
	drop_id = p_drop_id
	loot_items = ItemUtils.duplicate_items(loot)
	gear_items = ItemUtils.duplicate_items(gear)
	_build_visual(true)


func total_value() -> int:
	var total: int = 0
	for item: Dictionary in loot_items:
		total += int(item.get("value", 0))
	return total


func contents() -> Dictionary:
	return {
		"loot": loot_items.duplicate(true),
		"gear": gear_items.duplicate(true),
	}


func _build_visual(visible_to_client: bool) -> void:
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

	var label := Label3D.new()
	label.name = "ValueLabel"
	label.text = "$%d" % total_value()
	label.position = Vector3(0.0, 0.9, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 32
	_visual_root.add_child(label)

	_visual_root.visible = visible_to_client
