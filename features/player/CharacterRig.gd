class_name CharacterRig
extends Node3D
## Slot-based character rig. A placeholder capsule body plus one Node3D per
## appearance slot; each slot holds the mesh of its CosmeticData.
##
## `apply` can run before the node enters the tree (spawn_node calls it right
## after instantiation), so the child nodes are built on first use.

const BODY_RADIUS: float = 0.4
const BODY_HEIGHT: float = 1.8
const BODY_CENTER_Y: float = 0.9
const BODY_COLORS := {
	"male": Color(0.25, 0.68, 0.95),
	"female": Color(0.95, 0.45, 0.6),
}

var _appearance: AppearanceData = null
var _body: MeshInstance3D = null
var _body_material: StandardMaterial3D = null
var _slot_nodes: Dictionary = {}


func _ready() -> void:
	_ensure_built()


func apply(appearance: AppearanceData) -> void:
	_ensure_built()
	if appearance == null:
		appearance = AppearanceData.new()
	_appearance = appearance
	_body_material.albedo_color = BODY_COLORS.get(appearance.body_type, BODY_COLORS["male"])
	for slot: String in GameConst.APPEARANCE_SLOTS:
		var slot_node: Node3D = _slot_nodes[slot]
		for child: Node in slot_node.get_children():
			slot_node.remove_child(child)
			child.free()
		var item_id: Variant = appearance.slots.get(slot, "")
		if not (item_id is String) or (item_id as String).is_empty():
			continue
		var path: String = GameConst.COSMETICS_DIR + String(item_id) + ".tres"
		if not ResourceLoader.exists(path):
			push_warning("CharacterRig: missing cosmetic %s" % path)
			continue
		var cosmetic := load(path) as CosmeticData
		if cosmetic == null or cosmetic.slot != slot:
			push_warning("CharacterRig: cosmetic %s does not fit slot %s" % [item_id, slot])
			continue
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = cosmetic.mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = cosmetic.color
		mesh_instance.material_override = material
		mesh_instance.position = cosmetic.offset
		slot_node.add_child(mesh_instance)


func set_masked(masked: bool) -> void:
	_ensure_built()
	(_slot_nodes["mask"] as Node3D).visible = masked


func _ensure_built() -> void:
	if _body != null:
		return
	_body = MeshInstance3D.new()
	_body.name = "Body"
	var capsule := CapsuleMesh.new()
	capsule.radius = BODY_RADIUS
	capsule.height = BODY_HEIGHT
	_body.mesh = capsule
	_body_material = StandardMaterial3D.new()
	_body_material.albedo_color = BODY_COLORS["male"]
	_body.material_override = _body_material
	_body.position = Vector3(0.0, BODY_CENTER_Y, 0.0)
	add_child(_body)
	for slot: String in GameConst.APPEARANCE_SLOTS:
		var slot_node := Node3D.new()
		slot_node.name = slot
		add_child(slot_node)
		_slot_nodes[slot] = slot_node
