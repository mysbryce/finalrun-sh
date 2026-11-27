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

var instance_id: String = ""
var map_name: String = ""
var health: int = MAX_HEALTH

var _role_controller: PlayerRoleController = null
var _input_dir: Vector2 = Vector2.ZERO
var _last_sent_input: Vector2 = Vector2(-999.0, -999.0)
var _send_accumulator: float = 0.0
var _input_enabled: bool = false


func _ready() -> void:
	_role_controller = get_node_or_null("PlayerRoleController") as PlayerRoleController
	if _role_controller != null:
		_role_controller.bind_player(self)
	var sync := get_node_or_null("MultiplayerSynchronizer") as MultiplayerSynchronizer
	if sync != null:
		sync.public_visibility = false
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
	var spawn_transform: Variant = instance_node.call("get_spawn_transform", peer_id)
	if spawn_transform is Transform3D:
		position = (spawn_transform as Transform3D).origin


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
	health -= amount
	if _role_controller != null:
		_role_controller.notify_damage()
	if health <= 0:
		var server_manager := get_node_or_null("/root/ServerManager")
		if server_manager != null and server_manager.has_method("handle_player_death"):
			server_manager.handle_player_death(self)


@rpc("any_peer", "call_remote", "reliable")
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


func _server_physics(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	var direction := Vector3(_input_dir.x, 0.0, _input_dir.y)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	move_and_slide()


func _client_input_tick(delta: float) -> void:
	_send_accumulator += delta
	if _send_accumulator < INPUT_SEND_INTERVAL:
		return
	_send_accumulator = 0.0
	var input := _read_input()
	if input.is_equal_approx(_last_sent_input):
		return
	_last_sent_input = input
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
	return Vector2(x, z).limit_length(1.0)


func _update_control_state() -> void:
	if not is_inside_tree() or not multiplayer.has_multiplayer_peer():
		_input_enabled = false
		return
	_input_enabled = not multiplayer.is_server() and peer_id == multiplayer.get_unique_id()
