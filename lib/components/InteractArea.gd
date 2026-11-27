class_name InteractArea
extends Node3D
## Marks its parent as interactable. Clients use `nearest()` to pick the
## prompt target; the server always re-checks range itself. A hidden
## InteractArea (or one under a hidden parent) is ignored.

const GROUP := &"interact_areas"

## Prompt text shown by the HUD, e.g. "E lockpick | V smash".
@export var prompt: String = "Interact"

## Card title shown above the prompt, e.g. "Loot crate".
@export var title: String = ""


func _enter_tree() -> void:
	add_to_group(GROUP)


## Index of the closest position within max_range (inclusive), or -1.
static func pick_nearest(from_pos: Vector3, positions: Array, max_range: float) -> int:
	var best_index := -1
	var best_distance := INF
	for i in positions.size():
		var p: Vector3 = positions[i]
		var distance: float = from_pos.distance_to(p)
		if distance <= max_range and distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index


## Closest visible InteractArea in the same World3D as `from`, or null.
static func nearest(from: Node3D, max_range: float) -> InteractArea:
	if from == null or not is_instance_valid(from) or not from.is_inside_tree():
		return null
	var areas: Array[InteractArea] = []
	var positions: Array = []
	for node in from.get_tree().get_nodes_in_group(GROUP):
		if not node is InteractArea:
			continue
		var area: InteractArea = node
		if not area.is_inside_tree():
			continue
		if not area.is_visible_in_tree():
			continue
		if area.get_world_3d() != from.get_world_3d():
			continue
		areas.append(area)
		positions.append(area.global_position)
	var index := pick_nearest(from.global_position, positions, max_range)
	if index == -1:
		return null
	return areas[index]
