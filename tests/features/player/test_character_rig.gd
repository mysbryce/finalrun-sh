extends TestCase
## CharacterRig slot building from AppearanceData.


func _mesh_count(rig: CharacterRig, slot: String) -> int:
	var count: int = 0
	for child: Node in rig.get_node(slot).get_children():
		if child is MeshInstance3D:
			count += 1
	return count


func test_apply_default_fills_slots() -> void:
	var rig := CharacterRig.new()
	rig.apply(AppearanceData.default_for(1))
	var hair: int = _mesh_count(rig, "hair")
	var top: int = _mesh_count(rig, "top")
	var mask: int = _mesh_count(rig, "mask")
	var hat: int = _mesh_count(rig, "hat")
	var has_body: bool = rig.get_node_or_null("Body") is MeshInstance3D
	rig.free()
	assert_true(has_body, "rig has a Body mesh")
	assert_eq(hair, 1, "hair has one mesh")
	assert_eq(top, 1, "top has one mesh")
	assert_eq(mask, 1, "mask has one mesh")
	assert_eq(hat, 0, "hat is empty")


func test_set_masked_hides_mask() -> void:
	var rig := CharacterRig.new()
	rig.apply(AppearanceData.default_for(1))
	rig.set_masked(false)
	var hidden: bool = not (rig.get_node("mask") as Node3D).visible
	rig.set_masked(true)
	var shown: bool = (rig.get_node("mask") as Node3D).visible
	rig.free()
	assert_true(hidden, "set_masked(false) hides mask")
	assert_true(shown, "set_masked(true) shows mask")


func test_reapply_clears_removed_slot() -> void:
	var rig := CharacterRig.new()
	rig.apply(AppearanceData.default_for(1))
	var next := AppearanceData.new()
	next.slots = {"hair": "hair_short"}
	rig.apply(next)
	var top: int = _mesh_count(rig, "top")
	var hair: int = _mesh_count(rig, "hair")
	rig.free()
	assert_eq(top, 0, "top is cleared when the new appearance has none")
	assert_eq(hair, 1, "hair is replaced, not duplicated")


func test_unknown_id_leaves_slot_empty() -> void:
	var rig := CharacterRig.new()
	var data := AppearanceData.new()
	data.slots = {"hat": "hat_does_not_exist", "top": "hair_short"}
	rig.apply(data)
	var hat: int = _mesh_count(rig, "hat")
	var top: int = _mesh_count(rig, "top")
	rig.free()
	assert_eq(hat, 0, "unknown id leaves the slot empty")
	assert_eq(top, 0, "slot mismatch leaves the slot empty")
