class_name Minimap
extends TextureRect
## North-up (or heading-up with minimap_rotate) top-down view of the followed node's world, drawn in HUD_MINIMAP_RECT
## under the web page (which draws the frame and arrow).


static func camera_position(target: Vector3) -> Vector3:
	return Vector3(target.x, target.y + GameConst.HUD_MINIMAP_HEIGHT, target.z)


## Top-down camera rotation. Euler order YXZ applies the yaw first, then the
## -90 degree pitch, so screen-up is the camera's facing when `rotate` is on.
static func camera_rotation(yaw: float, rotate: bool) -> Vector3:
	return Vector3(-PI / 2.0, yaw if rotate else 0.0, 0.0)


## minimap_rotate setting (Hud.set_minimap_rotate).
var rotate_with_heading: bool = false
## Camera yaw in radians, fed by the Hud every frame.
var heading_yaw: float = 0.0
var _viewport: SubViewport = null
var _camera: Camera3D = null
var _target: Node3D = null


func _ready() -> void:
	position = GameConst.HUD_MINIMAP_RECT.position
	size = GameConst.HUD_MINIMAP_RECT.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(GameConst.HUD_MINIMAP_RECT.size)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = GameConst.HUD_MINIMAP_WORLD_SIZE
	_camera.near = 1.0
	_camera.far = GameConst.HUD_MINIMAP_HEIGHT + 50.0
	_camera.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_viewport.add_child(_camera)
	add_child(_viewport)
	texture = _viewport.get_texture()
	visible = false


func follow(target: Node3D) -> void:
	_target = target


func _process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target) or not _target.is_inside_tree():
		visible = false
		return
	var world := _target.get_world_3d()
	if _viewport.world_3d != world:
		_viewport.world_3d = world
	_camera.current = true
	_camera.global_position = camera_position(_target.global_position)
	_camera.rotation = camera_rotation(heading_yaw, rotate_with_heading)
	visible = true
