extends TestCase
## Mask channel now runs on ChannelTimer; the four public reasons must survive.

const PlayerScene = preload("res://features/player/Player.tscn")
const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")


class MapStub:
	extends Node
	var map_name: String = "LootyBay"
	var safezone: bool = false


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _make_player() -> PlayerCharacter:
	var player := PlayerScene.instantiate() as PlayerCharacter
	player.name = "MaskTestPlayer"
	_tree().root.add_child(player)
	var stub := MapStub.new()
	stub.map_name = "LootyBay"
	player.add_child(stub)
	player.set("map_name", "LootyBay")
	var controller := player.get_role_controller()
	controller.configure_context(stub, "LootyBay", false)
	return player


func _drop_player(player: PlayerCharacter) -> void:
	_tree().root.remove_child(player)
	player.free()


func _start_mask(player: PlayerCharacter) -> Array:
	var controller := player.get_role_controller()
	var reasons: Array[String] = []
	controller.mask_channel_cancelled.connect(
		func(reason: String) -> void: reasons.append(reason)
	)
	assert_true(controller.server_try_mask(), "mask channel starts in LootyBay")
	return reasons


func _tick(channel: ChannelTimer, delta: float = 0.1) -> void:
	channel.call("_process", delta)


func test_mask_completes_into_criminal() -> void:
	var player := _make_player()
	var controller := player.get_role_controller()
	var reasons := _start_mask(player)
	var channel := player.get_node_or_null("MaskChannelTimer") as ChannelTimer
	assert_true(channel != null, "mask channel is parented under the player")
	_tick(channel, 3.1)
	assert_eq(controller.role, RoleControllerScript.Role.CRIMINAL, "finished mask becomes CRIMINAL")
	assert_eq(reasons.size(), 0, "completed mask is not cancelled")
	_drop_player(player)


func test_mask_cancels_on_damage() -> void:
	var player := _make_player()
	var controller := player.get_role_controller()
	var reasons := _start_mask(player)
	_tick(player.get_node("MaskChannelTimer") as ChannelTimer)
	controller.notify_damage()
	assert_eq(reasons, ["damaged"] as Array[String], "damage cancels the mask channel")
	assert_eq(controller.role, RoleControllerScript.Role.CITIZEN, "cancelled mask keeps CITIZEN")
	_drop_player(player)


func test_mask_cancels_on_move() -> void:
	var player := _make_player()
	var reasons := _start_mask(player)
	player.global_position.x += 1.0
	_tick(player.get_node("MaskChannelTimer") as ChannelTimer)
	assert_eq(reasons, ["moved"] as Array[String], "moving cancels the mask channel")
	_drop_player(player)


func test_mask_cancels_on_left_instance() -> void:
	var player := _make_player()
	var controller := player.get_role_controller()
	var stub := player.get_child(player.get_child_count() - 1) as MapStub
	var reasons := _start_mask(player)
	stub.map_name = "Motel"
	_tick(player.get_node("MaskChannelTimer") as ChannelTimer)
	assert_eq(reasons, ["left_instance"] as Array[String], "leaving LootyBay cancels the mask")
	assert_eq(controller.role, RoleControllerScript.Role.CITIZEN, "role is unchanged")
	_drop_player(player)


func test_mask_cancels_when_role_is_invalid() -> void:
	var player := _make_player()
	var controller := player.get_role_controller()
	var reasons := _start_mask(player)
	controller.role = RoleControllerScript.Role.COP
	_tick(player.get_node("MaskChannelTimer") as ChannelTimer)
	assert_eq(reasons, ["invalid_state"] as Array[String], "a changed role cancels the mask")
	_drop_player(player)


func test_mask_rejects_non_citizen_and_outside_lootybay() -> void:
	var player := _make_player()
	var controller := player.get_role_controller()
	controller.role = RoleControllerScript.Role.CRIMINAL
	assert_false(controller.server_try_mask(), "CRIMINAL cannot mask again")
	var motel_player := _make_player()
	var motel_controller := motel_player.get_role_controller()
	var motel_stub := motel_player.get_child(motel_player.get_child_count() - 1) as MapStub
	motel_stub.map_name = "Motel"
	assert_false(motel_controller.server_try_mask(), "mask needs LootyBay")
	_drop_player(player)
	_drop_player(motel_player)
