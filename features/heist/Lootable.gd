class_name Lootable
extends Node3D
## Minimal server-authoritative loot container.
##
## Lockpicking is silent. Smashing is loud and raises an alert that the server
## sends only to COP and CRIMINAL members of the same instance, together with
## the world position of the lootable.

const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")

@export var loot_id: String = "valuables"
@export var value: int = 250
@export var locked: bool = true

var looted: bool = false


## Only an ALIVE CRIMINAL may loot (mask first).
static func role_may_loot(role: int, life_state: int) -> bool:
	return role == RoleControllerScript.Role.CRIMINAL and life_state == RoleControllerScript.LifeState.ALIVE


## A client-sent lootable name must be one plain node name (no path parts).
static func is_valid_lootable_name(lootable_name: String) -> bool:
	return not lootable_name.is_empty() and lootable_name.validate_node_name() == lootable_name


## Finds `<map_root>/Lootables/<lootable_name>`, or null.
static func find_in(map_root: Node, lootable_name: String) -> Lootable:
	if map_root == null or not is_instance_valid(map_root):
		return null
	if not is_valid_lootable_name(lootable_name):
		return null
	return map_root.get_node_or_null(NodePath("Lootables/" + lootable_name)) as Lootable


func mark_looted() -> void:
	looted = true
	visible = false
	set_process(false)


func server_lockpick(player: Node) -> bool:
	if not _can_be_looted_by(player):
		return false
	_grant_to(player)
	return true


func server_smash(player: Node) -> bool:
	if not _can_be_looted_by(player):
		return false
	_grant_to(player)
	_broadcast_loud_alert()
	return true


func server_can_interact(player: Node) -> bool:
	return _can_be_looted_by(player)


func _can_be_looted_by(player: Node) -> bool:
	if not multiplayer.is_server() or looted or player == null or not is_instance_valid(player):
		return false
	var instance := _find_instance()
	if instance == null:
		return false
	var player_instance: Variant = player.get("instance_id")
	if player_instance == null or String(player_instance) != String(instance.get("instance_id")):
		return false
	var controller := player.get_node_or_null("PlayerRoleController") as PlayerRoleController
	if controller == null:
		return false
	return role_may_loot(controller.role, controller.life_state)


func _grant_to(player: Node) -> void:
	mark_looted()
	var controller := player.get_node_or_null("PlayerRoleController")
	if controller != null:
		controller.call("grant_loot", loot_id, value)
	var instance := _find_instance()
	if instance != null:
		instance.call("rpc_to_members", "client_lootable_looted", [String(name)])


func _broadcast_loud_alert() -> void:
	var instance := _find_instance()
	if instance == null:
		return
	var roles: Array = [
		RoleControllerScript.Role.COP,
		RoleControllerScript.Role.CRIMINAL,
	]
	var peers: Array = instance.call("get_member_peers_with_roles", roles)
	instance.call("rpc_to_specific_members", "client_loot_alert", [global_position, loot_id, true], peers)


func _find_instance() -> Node:
	var node: Node = self
	while node != null:
		if node is GameInstance:
			return node
		node = node.get_parent()
	return null
