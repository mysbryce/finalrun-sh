extends TestCase
## DownedService tells the downed target about revive/finish channels, and a
## second press on the same action cancels the running channel.

const DownedScript = preload("res://features/downed/DownedService.gd")
const PlayerScene = preload("res://features/player/Player.tscn")
const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")


class FakePlayers:
	extends PlayerService
	var players: Dictionary = {}

	func get_player(peer_id: int) -> PlayerCharacter:
		return players.get(peer_id) as PlayerCharacter

	func get_controller(peer_id: int) -> PlayerRoleController:
		var player := get_player(peer_id)
		if player == null:
			return null
		return player.get_node("PlayerRoleController") as PlayerRoleController


class FakeHost:
	extends Node
	var notes: Array = []
	var sent: Array = []

	func _notify(peer_id: int, text: String) -> void:
		notes.append([peer_id, text])

	func _send_client_rpc(peer_id: int, method: StringName, args: Array = []) -> void:
		sent.append([peer_id, String(method), args])


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _make_player(peer_id: int) -> PlayerCharacter:
	var player := PlayerScene.instantiate() as PlayerCharacter
	player.name = "DownedChannelTest%d" % peer_id
	_tree().root.add_child(player)
	player.set("peer_id", peer_id)
	return player


func _drop_player(player: PlayerCharacter) -> void:
	_tree().root.remove_child(player)
	player.free()


func _setup() -> Array:
	var actor := _make_player(10)
	var fake := FakePlayers.new()
	fake.players = {10: actor}
	var host := FakeHost.new()
	var service = DownedScript.new()
	service.configure(host, null, fake, null)
	return [service, host, actor]


func test_start_sends_duration_to_target() -> void:
	var parts := _setup()
	var service = parts[0]
	var host: FakeHost = parts[1]
	var actor: PlayerCharacter = parts[2]
	service._start_channel(10, 20, "revive", 5.0)
	var sent: Array = host.sent.duplicate(true)
	_drop_player(actor)
	host.free()
	assert_eq(sent, [[20, "client_downed_channel", ["revive", 5000]]], "target gets the revive duration")


func test_press_again_cancels() -> void:
	var parts := _setup()
	var service = parts[0]
	var host: FakeHost = parts[1]
	var actor: PlayerCharacter = parts[2]
	service._start_channel(10, 20, "revive", 5.0)
	host.sent.clear()
	service.request_revive(10, 20)
	var channels_empty: bool = service._channels.is_empty()
	var notes: Array = host.notes.duplicate(true)
	var sent: Array = host.sent.duplicate(true)
	_drop_player(actor)
	host.free()
	assert_true(channels_empty, "pressing again removes the channel")
	assert_true(notes.has([10, "Action cancelled (pressed_again)"]), "actor is told the action was cancelled")
	assert_eq(sent, [[20, "client_downed_channel", ["revive", 0]]], "target is told the revive ended")


func test_other_target_is_still_busy() -> void:
	var parts := _setup()
	var service = parts[0]
	var host: FakeHost = parts[1]
	var actor: PlayerCharacter = parts[2]
	service._start_channel(10, 20, "revive", 5.0)
	service.request_revive(10, 30)
	var notes: Array = host.notes.duplicate(true)
	_drop_player(actor)
	host.free()
	assert_true(notes.has([10, "You are already channelling"]), "a different target keeps the busy message")
