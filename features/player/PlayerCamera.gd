class_name PlayerCamera
extends Node3D
## Client-only third-person camera for the local player.
##
## The pivot follows the target's world position; mouse motion turns the yaw
## (this node) and pitch (the `Pitch` child). The body itself never rotates
## with the camera, so movement stays camera-relative.

var target: Node3D = null
var _pitch: Node3D
var _arm: SpringArm3D
var _camera: Camera3D


func _ready() -> void:
	# Yaw must not follow the body rotation.
	top_level = true
	_pitch = Node3D.new()
	_pitch.name = "Pitch"
	add_child(_pitch)
	_arm = SpringArm3D.new()
	_arm.name = "Arm"
	_arm.spring_length = GameConst.CAMERA_DISTANCE
	_arm.collision_mask = 1
	_arm.margin = 0.2
	_pitch.add_child(_arm)
	_camera = Camera3D.new()
	_camera.name = "Camera"
	_arm.add_child(_camera)
	_camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_delta: float) -> void:
	if target != null and is_instance_valid(target):
		global_position = target.global_position + Vector3(0.0, GameConst.CAMERA_PIVOT_HEIGHT, 0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		rotation.y -= motion.relative.x * GameConst.CAMERA_MOUSE_SENSITIVITY
		_pitch.rotation.x = clampf(
			_pitch.rotation.x - motion.relative.y * GameConst.CAMERA_MOUSE_SENSITIVITY,
			GameConst.CAMERA_PITCH_MIN,
			GameConst.CAMERA_PITCH_MAX
		)
	elif event is InputEventMouseButton:
		# Recaptures the cursor after alt-tab. Esc belongs to the pause menu (Main).
		# While a HUD panel is open the browser (MOUSE_FILTER_STOP, CanvasLayer above
		# the Instances SubViewportContainer) consumes the click, so it never reaches
		# this SubViewport and the freed cursor stays free.
		var button := event as InputEventMouseButton
		if (
			button.pressed
			and button.button_index == MOUSE_BUTTON_LEFT
			and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
		):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()


func get_yaw() -> float:
	return rotation.y


func get_aim_direction() -> Vector3:
	if _camera == null or not is_instance_valid(_camera):
		return Vector3.ZERO
	return -_camera.global_transform.basis.z


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
