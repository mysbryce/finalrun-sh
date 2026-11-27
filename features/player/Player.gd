class_name PlayerCharacter
extends CharacterBody3D
## Minimal server-authoritative player.
##
## The client reads WASD and sends movement requests to the server; the server
## simulates CharacterBody3D movement and the root MultiplayerSynchronizer
## replicates position/rotation/role back. Clients never move themselves.

const SPEED: float = GameConst.PLAYER_SPEED
const GRAVITY: float = GameConst.PLAYER_GRAVITY
const INPUT_SEND_INTERVAL: float = GameConst.PLAYER_INPUT_SEND_INTERVAL
const MAX_HEALTH: int = GameConst.PLAYER_MAX_HEALTH

@export var peer_id: int = 0:
	set(value):
		peer_id = value
		_update_control_state()

@export var role: int = 0:
	set(value):
		var old_role: int = role
		role = value
		if _role_controller != null and is_instance_valid(_role_controller):
			_role_controller.handle_replicated_role(old_role, role)

@export var life_state: int = 0:
	set(value):
		var old_state: int = life_state
		life_state = value
		if _role_controller != null and is_instance_valid(_role_controller):
			_role_controller.handle_replicated_life_state(old_state, life_state)

@export var downed_deadline_ms: int = 0

## Server-written snapshot of the authoritative transform. Clients smooth toward it.
@export var sync_position: Vector3 = Vector3.ZERO
@export var sync_yaw: float = 0.0

var instance_id: String = ""
var map_name: String = ""
var health: int = MAX_HEALTH

var _role_controller: PlayerRoleController = null
var _input_dir: Vector2 = Vector2.ZERO
var _movement_sent: bool = false
var _send_accumulator: float = 0.0
var _input_enabled: bool = false
var _camera: PlayerCamera = null
var _has_snapshot: bool = false
var _last_fire_local_ms: int = 0


func _ready() -> void:
	_role_controller = get_node_or_null("PlayerRoleController") as PlayerRoleController
	if _role_controller != null:
		_role_controller.bind_player(self)
	var sync := get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
	if sync != null:
		sync.public_visibility = false
		sync.replication_interval = GameConst.PLAYER_SYNC_INTERVAL
	_update_control_state()


## Server-side spawn setup. Called by the MultiplayerSpawner custom spawn
## function before the node enters the tree.
func setup_server(instance_node: Node, state: Dictionary) -> void:
	if instance_node == null:
		return
	instance_id = String(instance_node.get("instance_id"))
	map_name = String(instance_node.get("map_name"))
	health = MAX_HEALTH
	var controller := get_node_or_null("PlayerRoleController") as PlayerRoleController
	if controller != null:
		controller.bind_player(self)
		controller.configure_context(
			instance_node,
			map_name,
			bool(instance_node.get("safezone"))
		)
	role = int(state.get("role", PlayerRoleController.Role.CITIZEN))
	if controller != null:
		controller.apply_state(state)
		# A transfer respawns the player. The node is fresh, so this is usually
		# an idempotent no-op, but it also restores full HP explicitly.
		controller.server_set_life_state(
			PlayerRoleController.LifeState.ALIVE,
			"respawn",
			_now_ms()
		)
	var spawn_transform: Variant = instance_node.call("get_spawn_transform", peer_id)
	if spawn_transform is Transform3D:
		position = (spawn_transform as Transform3D).origin
	sync_position = position
	sync_yaw = rotation.y


## Client-side spawn setup. Called by the client's MultiplayerSpawner custom
## spawn function before the node enters the tree. Role/inventory/position are
## applied by the synchronizer spawn state; the client only needs context.
func setup_client(instance_node: Node) -> void:
	if instance_node == null:
		return
	instance_id = String(instance_node.get("instance_id"))
	map_name = String(instance_node.get("map_name"))
	var controller := get_node_or_null("PlayerRoleController") as PlayerRoleController
	if controller != null:
		controller.bind_player(self)
		controller.configure_context(
			instance_node,
			map_name,
			bool(instance_node.get("safezone"))
		)


func get_role_controller() -> PlayerRoleController:
	return _role_controller


## Server-only damage hook. Death resolution is owned by PlayerService.
func take_damage(amount: int) -> void:
	if not multiplayer.is_server() or amount <= 0:
		return
	if _role_controller == null:
		return
	if _role_controller.life_state == PlayerRoleController.LifeState.DEAD:
		return
	var now_ms: int = _now_ms()
	_role_controller.notify_damage()
	var server_manager := get_node_or_null("/root/ServerManager")
	if server_manager != null and server_manager.has_method("notify_player_damaged"):
		server_manager.notify_player_damaged(self)

	if _role_controller.life_state == PlayerRoleController.LifeState.DOWNED:
		# A downed body stays at 0 HP; extra hits only shorten the bleed-out.
		health = 0
		if _role_controller.server_apply_downed_damage(now_ms):
			_request_death_resolution()
		return

	health -= amount
	if health > 0:
		return
	health = 0
	if not _role_controller.is_in_heist_map():
		# Outside LootyBay 0 HP goes straight to the death path.
		_role_controller.server_set_life_state(
			PlayerRoleController.LifeState.DEAD,
			"damage",
			now_ms
		)
		_request_death_resolution()
		return
	if _role_controller.was_recently_revived(now_ms):
		_role_controller.server_set_life_state(
			PlayerRoleController.LifeState.DEAD,
			"redown",
			now_ms
		)
		_request_death_resolution()
		return
	_role_controller.server_set_life_state(
		PlayerRoleController.LifeState.DOWNED,
		"damage",
		now_ms
	)


func _request_death_resolution() -> void:
	# PlayerService owns the death outcome, LootDrop, and deferred respawn
	# transfer; the life-state handler itself only cancels channels.
	var server_manager := get_node_or_null("/root/ServerManager")
	if server_manager != null and server_manager.has_method("handle_player_death"):
		server_manager.handle_player_death(self)


@rpc("any_peer", "call_remote", "unreliable")
func server_request_move(input: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var sender: int = multiplayer.get_remote_sender_id()
	if sender <= 0 or sender != peer_id:
		return
	_input_dir = input.limit_length(1.0)


func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		_server_physics(delta)
	elif _input_enabled:
		_client_input_tick(delta)


func _process(delta: float) -> void:
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		return
	if not _has_snapshot:
		position = sync_position
		rotation.y = sync_yaw
		_has_snapshot = true
		return
	position = smoothed_position(position, sync_position, delta)
	rotation.y = lerp_angle(rotation.y, sync_yaw, interp_weight(delta))


func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled:
		return
	if not (event is InputEventMouseButton):
		return
	var button := event as InputEventMouseButton
	if not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if _camera == null or not is_instance_valid(_camera):
		return
	var now_ms: int = Time.get_ticks_msec()
	if not can_fire_locally(now_ms, _last_fire_local_ms):
		return
	_last_fire_local_ms = now_ms
	var aim := _camera.get_aim_direction()
	if aim == Vector3.ZERO:
		return
	var server_manager := get_node_or_null("/root/ServerManager")
	if server_manager != null and server_manager.has_method("request_fire"):
		server_manager.request_fire(aim)


func _server_physics(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	var speed: float = SPEED
	if _role_controller != null:
		match _role_controller.life_state:
			PlayerRoleController.LifeState.DOWNED:
				speed = GameConst.DOWNED_CRAWL_SPEED
			PlayerRoleController.LifeState.DEAD:
				speed = 0.0
	var direction := Vector3(_input_dir.x, 0.0, _input_dir.y)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	if speed > 0.0 and direction.length_squared() > 0.0001:
		rotation.y = turn_toward(rotation.y, facing_yaw(direction), delta)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()
	sync_position = position
	sync_yaw = rotation.y


func _client_input_tick(delta: float) -> void:
	_send_accumulator += delta
	if _send_accumulator < INPUT_SEND_INTERVAL:
		return
	_send_accumulator = 0.0
	var input := _read_input()
	if input.is_zero_approx():
		# The movement RPC is unreliable, so one final zero packet stops the
		# server from repeating the last input forever after the keys release.
		if _movement_sent:
			_movement_sent = false
			rpc_id(1, "server_request_move", Vector2.ZERO)
		return
	# Resend every interval even when unchanged: a dropped unreliable packet
	# must not freeze the server-side simulation.
	_movement_sent = true
	rpc_id(1, "server_request_move", input)


func _read_input() -> Vector2:
	if not multiplayer.has_multiplayer_peer():
		return Vector2.ZERO
	var x: float = 0.0
	var z: float = 0.0
	if Input.is_physical_key_pressed(KEY_D):
		x += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		x -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		z += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		z -= 1.0
	var raw := Vector2(x, z)
	if _camera != null and is_instance_valid(_camera):
		return camera_relative_input(raw, _camera.get_yaw())
	return raw.limit_length(1.0)


func _update_control_state() -> void:
	if not is_inside_tree() or not multiplayer.has_multiplayer_peer():
		_input_enabled = false
	else:
		_input_enabled = not multiplayer.is_server() and peer_id == multiplayer.get_unique_id()
	_sync_camera()


func _sync_camera() -> void:
	if _input_enabled and _camera == null:
		_camera = PlayerCamera.new()
		_camera.name = "PlayerCamera"
		_camera.target = self
		add_child.call_deferred(_camera)
	elif not _input_enabled and _camera != null:
		_camera.queue_free()
		_camera = null


## Client-side fire gate; the server enforces the same interval again.
static func can_fire_locally(now_ms: int, last_fire_ms: int) -> bool:
	return now_ms - last_fire_ms >= GameConst.FIRE_INTERVAL_MS


## Turns raw WASD (x = right, y = back) into a world XZ direction for a camera yaw.
static func camera_relative_input(raw: Vector2, yaw: float) -> Vector2:
	return raw.limit_length(1.0).rotated(-yaw)


## Body yaw that faces a world-space move direction (Godot forward is -Z).
static func facing_yaw(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)


static func turn_toward(current_yaw: float, target_yaw: float, delta: float) -> float:
	return lerp_angle(current_yaw, target_yaw, clampf(GameConst.PLAYER_TURN_SPEED * delta, 0.0, 1.0))


static func interp_weight(delta: float) -> float:
	return 1.0 - exp(-GameConst.PLAYER_INTERP_RATE * delta)


## Next client position: snap when far (spawn, teleport), otherwise slide.
static func smoothed_position(current: Vector3, target: Vector3, delta: float) -> Vector3:
	if current.distance_to(target) > GameConst.PLAYER_SNAP_DISTANCE:
		return target
	return current.lerp(target, interp_weight(delta))


func _now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)
