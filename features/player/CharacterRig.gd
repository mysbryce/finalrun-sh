class_name CharacterRig
extends Node3D
## Slot-based character rig. A body model (GameConst.BODY_MODELS) plus one
## Node3D per appearance slot; each slot holds the mesh of its CosmeticData.
## Visual only: it reads replicated state and never changes gameplay state.
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
const DEFAULT_BODY_TYPE: String = "male"
const ANIM_IDLE: StringName = &"idle"
const ANIM_WALK: StringName = &"walk"
const ANIM_SPRINT: StringName = &"sprint"
const ANIM_DOWNED: StringName = &"sit"
const ANIM_DEAD: StringName = &"die"
const LOOPED_ANIMS: Array[StringName] = [ANIM_IDLE, ANIM_WALK, ANIM_SPRINT]

var _appearance: AppearanceData = null
## Fallback capsule, only built when the body model cannot load.
var _body: MeshInstance3D = null
var _body_material: StandardMaterial3D = null
var _model: Node3D = null
var _body_type: String = ""
var _anim: AnimationPlayer = null
var _life_state: int = PlayerRoleController.LifeState.ALIVE
var _motion_anim: StringName = ANIM_IDLE
var _slot_nodes: Dictionary = {}
var _built: bool = false


func _ready() -> void:
	_ensure_built()


func apply(appearance: AppearanceData) -> void:
	_ensure_built()
	if appearance == null:
		appearance = AppearanceData.new()
	_appearance = appearance
	_set_body_type(appearance.body_type)
	# ponytail: slot cosmetics stay primitive meshes at fixed offsets; bone
	# attachment (BoneAttachment3D on the model skeleton) comes with real cosmetics.
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


## Picks idle/walk/sprint from the visual horizontal speed (m/s).
## Ignored while a life pose (downed/dead) is active.
func set_motion(speed: float) -> void:
	_ensure_built()
	if speed < GameConst.ANIM_WALK_SPEED:
		_motion_anim = ANIM_IDLE
	elif speed < GameConst.ANIM_SPRINT_SPEED:
		_motion_anim = ANIM_WALK
	else:
		_motion_anim = ANIM_SPRINT
	if _life_state != PlayerRoleController.LifeState.ALIVE:
		return
	_play(_motion_anim)


## DOWNED and DEAD hold a pose (last frame); ALIVE returns to motion animations.
func set_life_state(state: int) -> void:
	_ensure_built()
	_life_state = state
	match state:
		PlayerRoleController.LifeState.DOWNED:
			_play(ANIM_DOWNED)
		PlayerRoleController.LifeState.DEAD:
			_play(ANIM_DEAD)
		_:
			_play(_motion_anim)


## Name of the animation the rig last asked for ("" when there is no model).
func get_current_animation() -> StringName:
	if _anim == null:
		return &""
	return StringName(_anim.assigned_animation)


func _play(anim_name: StringName) -> void:
	if _anim == null or not _anim.has_animation(anim_name):
		return
	if StringName(_anim.assigned_animation) == anim_name:
		return
	_anim.play(anim_name, GameConst.ANIM_BLEND_TIME)


func _set_body_type(body_type: String) -> void:
	if not GameConst.BODY_MODELS.has(body_type):
		body_type = DEFAULT_BODY_TYPE
	if body_type == _body_type and (_model != null or _body != null):
		return
	_body_type = body_type
	if _model != null:
		remove_child(_model)
		_model.free()
		_model = null
		_anim = null
	var path: String = String(GameConst.BODY_MODELS[body_type])
	var scene: PackedScene = null
	if ResourceLoader.exists(path):
		scene = load(path) as PackedScene
	if scene == null:
		push_warning("CharacterRig: cannot load body model %s, using capsule" % path)
		_show_capsule(body_type)
		return
	_hide_capsule()
	_model = scene.instantiate() as Node3D
	_model.name = "Model"
	var height: float = model_height(_model)
	if height > 0.0:
		_model.scale = Vector3.ONE * (GameConst.CHARACTER_HEIGHT / height)
	# Kenney models face +Z; the player forward is -Z.
	_model.rotation.y = PI
	add_child(_model)
	move_child(_model, 0)
	var players := _model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim = players[0] as AnimationPlayer
		for anim_name: StringName in LOOPED_ANIMS:
			if _anim.has_animation(anim_name):
				_anim.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
		for anim_name: StringName in [ANIM_DOWNED, ANIM_DEAD]:
			if _anim.has_animation(anim_name):
				_anim.get_animation(anim_name).loop_mode = Animation.LOOP_NONE
		set_life_state(_life_state)


func _show_capsule(body_type: String) -> void:
	if _body == null:
		_body = MeshInstance3D.new()
		_body.name = "Body"
		var capsule := CapsuleMesh.new()
		capsule.radius = BODY_RADIUS
		capsule.height = BODY_HEIGHT
		_body.mesh = capsule
		_body_material = StandardMaterial3D.new()
		_body.material_override = _body_material
		_body.position = Vector3(0.0, BODY_CENTER_Y, 0.0)
		add_child(_body)
		move_child(_body, 0)
	_body_material.albedo_color = BODY_COLORS.get(body_type, BODY_COLORS[DEFAULT_BODY_TYPE])


func _hide_capsule() -> void:
	if _body == null:
		return
	remove_child(_body)
	_body.free()
	_body = null
	_body_material = null


func _ensure_built() -> void:
	if _built:
		return
	_built = true
	for slot: String in GameConst.APPEARANCE_SLOTS:
		var slot_node := Node3D.new()
		slot_node.name = slot
		add_child(slot_node)
		_slot_nodes[slot] = slot_node
	_set_body_type(DEFAULT_BODY_TYPE)


## Merged AABB height of every MeshInstance3D under `root`, in `root`'s local
## space (`root`'s own scale is not included). Rest pose, from the mesh AABBs.
static func model_height(root: Node3D) -> float:
	var merged := AABB()
	var first: bool = true
	for node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		var xf: Transform3D = Transform3D.IDENTITY
		var walker: Node = mesh_instance
		while walker != null and walker != root:
			if walker is Node3D:
				xf = (walker as Node3D).transform * xf
			walker = walker.get_parent()
		var box: AABB = xf * mesh_instance.get_aabb()
		if first:
			merged = box
			first = false
		else:
			merged = merged.merge(box)
	return merged.size.y
