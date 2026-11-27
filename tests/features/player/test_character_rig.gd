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
	var has_body: bool = rig.get_node_or_null("Model") is Node3D or rig.get_node_or_null("Body") is MeshInstance3D
	rig.free()
	assert_true(has_body, "rig has a body (Model or fallback Body)")
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


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _model_count(rig: CharacterRig) -> int:
	var count: int = 0
	for child: Node in rig.get_children():
		if child.name == "Model" or String(child.name).begins_with("Model"):
			count += 1
	return count


func _anim_player(rig: CharacterRig) -> AnimationPlayer:
	var model := rig.get_node_or_null("Model")
	if model == null:
		return null
	var players := model.find_children("*", "AnimationPlayer", true, false)
	return null if players.is_empty() else players[0] as AnimationPlayer


func test_model_loads_and_switches_with_body_type() -> void:
	var rig := CharacterRig.new()
	_tree().root.add_child(rig)
	var first := AppearanceData.default_for(1)
	var second := AppearanceData.default_for(2)
	rig.apply(first)
	var model_a := rig.get_node_or_null("Model")
	var path_a: String = model_a.scene_file_path if model_a != null else ""
	var anim := _anim_player(rig)
	var has_anims: bool = anim != null
	if anim != null:
		for anim_name: StringName in [&"idle", &"walk", &"sprint", &"die", &"sit"]:
			has_anims = has_anims and anim.has_animation(anim_name)
	rig.apply(second)
	var model_b := rig.get_node_or_null("Model")
	var path_b: String = model_b.scene_file_path if model_b != null else ""
	var models: int = _model_count(rig)
	_tree().root.remove_child(rig)
	rig.free()
	assert_true(first.body_type != second.body_type, "default_for(1) and (2) differ in body type")
	assert_eq(path_a, GameConst.BODY_MODELS[first.body_type], "first model matches body type")
	assert_true(has_anims, "AnimationPlayer has idle, walk, sprint, die, sit")
	assert_eq(path_b, GameConst.BODY_MODELS[second.body_type], "model changes with body type")
	assert_true(path_a != path_b, "model scene file changed")
	assert_eq(models, 1, "exactly one Model child")


func test_motion_and_life_state_animations() -> void:
	var rig := CharacterRig.new()
	_tree().root.add_child(rig)
	rig.apply(AppearanceData.default_for(2))
	rig.set_motion(0.0)
	var idle: StringName = rig.get_current_animation()
	rig.set_motion(GameConst.ANIM_SPRINT_SPEED)
	var sprint: StringName = rig.get_current_animation()
	rig.set_life_state(PlayerRoleController.LifeState.DEAD)
	var dead: StringName = rig.get_current_animation()
	rig.set_motion(0.0)
	var dead_after_motion: StringName = rig.get_current_animation()
	rig.set_life_state(PlayerRoleController.LifeState.ALIVE)
	rig.set_motion(0.0)
	var alive_idle: StringName = rig.get_current_animation()
	_tree().root.remove_child(rig)
	rig.free()
	assert_eq(idle, &"idle", "speed 0 plays idle")
	assert_eq(sprint, &"sprint", "sprint speed plays sprint")
	assert_eq(dead, &"die", "DEAD plays die")
	assert_eq(dead_after_motion, &"die", "motion is ignored while dead")
	assert_eq(alive_idle, &"idle", "ALIVE returns to idle")


func test_model_height_matches_character_height() -> void:
	var rig := CharacterRig.new()
	rig.apply(AppearanceData.default_for(1))
	var model := rig.get_node_or_null("Model") as Node3D
	var height: float = -1.0
	if model != null:
		height = CharacterRig.model_height(model) * model.scale.y
	rig.free()
	assert_true(absf(height - GameConst.CHARACTER_HEIGHT) <= 0.05,
		"model height %.3f is within 0.05 of CHARACTER_HEIGHT" % height)
