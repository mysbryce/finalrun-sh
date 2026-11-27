extends TestCase
## Downed state machine: damage, bleed-out, re-down window, revive and the one
## authoritative writer. Uses real PlayerCharacter nodes where it matters.

const PlayerScene = preload("res://features/player/Player.tscn")
const RoleControllerScript = preload("res://features/player/PlayerRoleController.gd")


class MapStub:
	extends Node
	var map_name: String = "LootyBay"
	var safezone: bool = false


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _make_player(p_map_name: String = "LootyBay") -> PlayerCharacter:
	var player := PlayerScene.instantiate() as PlayerCharacter
	player.name = "LifeStateTestPlayer"
	_tree().root.add_child(player)
	var stub := MapStub.new()
	stub.map_name = p_map_name
	player.add_child(stub)
	player.set("map_name", p_map_name)
	var controller := player.get_role_controller()
	controller.configure_context(stub, p_map_name, false)
	controller.role = RoleControllerScript.Role.CRIMINAL
	return player


func _drop_player(player: PlayerCharacter) -> void:
	_tree().root.remove_child(player)
	player.free()


func test_zero_hp_downs_in_lootybay() -> void:
	var player := _make_player()
	var controller := player.get_role_controller()
	var before: int = int(Time.get_unix_time_from_system() * 1000.0)
	player.take_damage(25)
	assert_eq(player.life_state, RoleControllerScript.LifeState.ALIVE, "one hit does not down")
	player.take_damage(25)
	player.take_damage(25)
	assert_eq(player.life_state, RoleControllerScript.LifeState.ALIVE, "75 damage is not lethal")
	player.take_damage(25)
	assert_eq(player.life_state, RoleControllerScript.LifeState.DOWNED, "0 HP knocks the player down")
	assert_eq(player.health, 0, "a downed body has 0 HP")
	var deadline: int = controller.downed_deadline_ms
	assert_true(deadline >= before + 59000, "deadline starts ~60 s ahead")
	assert_true(deadline <= before + 61000, "deadline uses DOWNED_BLEEDOUT_SECONDS")
	_drop_player(player)


func test_downed_hit_penalty_and_bleedout_math() -> void:
	var player := _make_player()
	var controller := player.get_role_controller()
	player.take_damage(100)
	var deadline: int = controller.downed_deadline_ms
	var died: bool = controller.server_apply_downed_damage(deadline - 10000)
	assert_false(died, "a hit with time left does not kill")
	assert_eq(
		controller.downed_deadline_ms,
		deadline - 5000,
		"each downed hit removes DOWNED_HIT_PENALTY_SECONDS"
	)
	assert_eq(player.life_state, RoleControllerScript.LifeState.DOWNED, "still downed after a hit")
	deadline = controller.downed_deadline_ms
	died = controller.server_apply_downed_damage(deadline)
	assert_true(died, "the hit at/after the deadline kills")
	assert_eq(player.life_state, RoleControllerScript.LifeState.DEAD, "bleed-out writes DEAD")
	_drop_player(player)


func test_redown_within_window_goes_straight_to_dead() -> void:
	var player := _make_player()
	var controller := player.get_role_controller()
	player.take_damage(100)
	assert_eq(player.life_state, RoleControllerScript.LifeState.DOWNED, "first down")
	var now: int = int(Time.get_unix_time_from_system() * 1000.0)
	controller.server_set_life_state(
		RoleControllerScript.LifeState.ALIVE,
		"revive",
		now
	)
	assert_eq(player.health, 25, "revive restores REVIVE_HP_RATIO of max HP")
	assert_true(controller.was_recently_revived(now + 1000), "inside the re-down window")
	player.take_damage(100)
	assert_eq(
		player.life_state,
		RoleControllerScript.LifeState.DEAD,
		"a re-down inside the window goes straight to DEAD"
	)
	_drop_player(player)


func test_outside_lootybay_zero_hp_dies() -> void:
	var player := _make_player("Motel")
	player.take_damage(100)
	assert_eq(
		player.life_state,
		RoleControllerScript.LifeState.DEAD,
		"0 HP outside LootyBay uses the death path"
	)
	_drop_player(player)


func test_writer_is_idempotent_and_tracks_causes() -> void:
	var controller = RoleControllerScript.new()
	var events: Array = []
	controller.life_state_changed.connect(
		func(old_state: int, new_state: int, cause: String) -> void:
			events.append([old_state, new_state, cause])
	)
	controller.server_set_life_state(RoleControllerScript.LifeState.DOWNED, "damage", 1000)
	controller.server_set_life_state(RoleControllerScript.LifeState.DOWNED, "damage", 2000)
	assert_eq(events.size(), 1, "writing the same state is a no-op")
	assert_eq(controller.downed_deadline_ms, 61000, "downed deadline is now + bleed-out")
	controller.server_set_life_state(RoleControllerScript.LifeState.DEAD, "finish", 3000)
	assert_eq(events.size(), 2, "a real change emits one event")
	assert_eq(String(events[1][2]), "finish", "cause is preserved")
	assert_eq(controller.downed_deadline_ms, 0, "DEAD clears the bleed-out deadline")
	controller.free()


func test_revive_ends_redown_window() -> void:
	var controller = RoleControllerScript.new()
	var now: int = 1000000
	controller.server_set_life_state(RoleControllerScript.LifeState.DOWNED, "damage", now)
	controller.server_set_life_state(RoleControllerScript.LifeState.ALIVE, "revive", now)
	assert_true(controller.was_recently_revived(now + 30000), "window includes the boundary")
	assert_false(controller.was_recently_revived(now + 30001), "window expires after 30 s")
	controller.free()


func test_disconnect_and_finish_causes_write_dead() -> void:
	var controller = RoleControllerScript.new()
	controller.server_set_life_state(RoleControllerScript.LifeState.DOWNED, "damage", 1000)
	controller.server_set_life_state(RoleControllerScript.LifeState.DEAD, "disconnect", 2000)
	assert_eq(
		controller.life_state,
		RoleControllerScript.LifeState.DEAD,
		"disconnect while downed writes DEAD"
	)
	var other = RoleControllerScript.new()
	other.server_set_life_state(RoleControllerScript.LifeState.DOWNED, "damage", 1000)
	other.server_set_life_state(RoleControllerScript.LifeState.DEAD, "finish", 2000)
	assert_eq(other.life_state, RoleControllerScript.LifeState.DEAD, "finish writes DEAD")
	controller.free()
	other.free()
