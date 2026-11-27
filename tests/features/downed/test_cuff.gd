extends TestCase
## Cuff applies the surrender outcome and the Motel transfer, never the death
## path and never a LootDrop.

const DownedScript = preload("res://features/downed/DownedService.gd")
const PlayerScene = preload("res://features/player/Player.tscn")
const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")


class FakePlayers:
	extends PlayerService
	var players: Dictionary = {}
	var transfers: int = 0
	var death_calls: int = 0
	var last_reason: String = ""
	var events: Array = []

	func get_player(peer_id: int) -> PlayerCharacter:
		return players.get(peer_id) as PlayerCharacter

	func current_instance(_peer_id: int) -> GameInstance:
		return null

	func transfer_to_motel(_peer_id: int, reason: String) -> bool:
		transfers += 1
		last_reason = reason
		events.append(["transfer"])
		return true

	func refresh_police_vehicle(_instance: GameInstance) -> void:
		pass

	func handle_player_death(_player: Node) -> void:
		death_calls += 1


class FakeHost:
	extends Node
	var events: Array = []

	func _notify(peer_id: int, text: String) -> void:
		events.append([peer_id, text])

	func _send_client_rpc(peer_id: int, method: StringName, args: Array = []) -> void:
		events.append([peer_id, String(method), args])


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _make_player(peer_id: int, role: int) -> PlayerCharacter:
	var player := PlayerScene.instantiate() as PlayerCharacter
	player.name = "CuffTest%d" % peer_id
	_tree().root.add_child(player)
	player.set("peer_id", peer_id)
	var controller := player.get_node("PlayerRoleController") as PlayerRoleController
	controller.role = role
	return player


func _drop_player(player: PlayerCharacter) -> void:
	_tree().root.remove_child(player)
	player.free()


func test_cuff_never_uses_the_death_path() -> void:
	var cop := _make_player(10, RoleControllerScript.Role.COP)
	var criminal := _make_player(20, RoleControllerScript.Role.CRIMINAL)
	var cop_controller := cop.get_node("PlayerRoleController") as PlayerRoleController
	var criminal_controller := criminal.get_node("PlayerRoleController") as PlayerRoleController
	criminal_controller.server_set_life_state(
		RoleControllerScript.LifeState.DOWNED,
		"damage",
		1000
	)
	criminal_controller.grant_loot("diamond", 1000)
	criminal_controller.grant_gear("rifle", 500)

	var events: Array = []
	var fake := FakePlayers.new()
	fake.players = {10: cop, 20: criminal}
	fake.events = events
	var host := FakeHost.new()
	host.events = events
	var service = DownedScript.new()
	service.configure(host, null, fake, null)
	service._apply_cuff(10, 20)

	var role: int = criminal_controller.role
	var bag_size: int = criminal_controller.loot_bag.size()
	var gear_size: int = criminal_controller.equipped_gear.size()
	var cop_cash: int = cop_controller.cash
	var life: int = criminal_controller.life_state
	var outcome_index := events.find([20, "client_life_outcome", ["arrest", "cuffed"]])
	var transfer_index := events.find(["transfer"])
	_drop_player(cop)
	_drop_player(criminal)
	host.free()

	assert_eq(role, RoleControllerScript.Role.CITIZEN, "cuff uses surrender outcome")
	assert_eq(bag_size, 0, "cuffed bag is cleared")
	assert_eq(gear_size, 1, "cuffed gear is kept")
	assert_eq(cop_cash, 500, "cop is paid the cuff reward")
	assert_eq(life, RoleControllerScript.LifeState.ALIVE, "a cuffed player is arrested, not dead")
	assert_eq(fake.transfers, 1, "cuff transfers the criminal to Motel")
	assert_eq(fake.last_reason, "arrest", "cuff transfer reason is arrest")
	assert_eq(fake.death_calls, 0, "cuff never runs the death path (no LootDrop)")
	assert_true(outcome_index >= 0, "cuff sends the arrest outcome to the criminal")
	assert_true(outcome_index < transfer_index, "the outcome is sent before the transfer")
