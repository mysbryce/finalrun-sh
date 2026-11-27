extends TestCase
## Death and arrest outcomes the server sends to the owner before the Motel
## transfer.

const PlayerScene = preload("res://features/player/Player.tscn")
const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")


class FakeHost:
	extends Node
	var sent: Array = []

	func _notify(_peer_id: int, _text: String) -> void:
		pass

	func _send_client_rpc(peer_id: int, method: StringName, args: Array = []) -> void:
		sent.append([peer_id, String(method), args])


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Runs one life-state change on a real player node and returns the sent RPCs.
func _sent_for(cause: String) -> Array:
	var host := FakeHost.new()
	var service := PlayerService.new()
	service._host = host
	var player := PlayerScene.instantiate()
	player.name = "LifeOutcomeTest"
	_tree().root.add_child(player)
	player.set("peer_id", 20)
	service._on_player_life_state_changed(
		RoleControllerScript.LifeState.DOWNED,
		RoleControllerScript.LifeState.DEAD,
		cause,
		player
	)
	var sent: Array = host.sent.duplicate(true)
	_tree().root.remove_child(player)
	player.free()
	host.free()
	return sent


func test_death_cause_mapping() -> void:
	assert_eq(PlayerService.death_cause("bleedout"), "bleed_out", "bleedout maps to bleed_out")
	assert_eq(PlayerService.death_cause("finish"), "finished", "finish maps to finished")
	assert_eq(PlayerService.death_cause("damage"), "other", "damage maps to other")
	assert_eq(PlayerService.death_cause("redown"), "other", "redown maps to other")


func test_death_sends_life_outcome() -> void:
	var sent := _sent_for("bleedout")
	assert_eq(sent, [[20, "client_life_outcome", ["death", "bleed_out"]]], "death sends the outcome to the owner")


func test_disconnect_death_sends_nothing() -> void:
	var sent := _sent_for("disconnect")
	assert_eq(sent, [], "a disconnect death sends no outcome")
