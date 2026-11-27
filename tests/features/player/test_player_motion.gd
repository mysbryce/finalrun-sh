extends TestCase
## Camera-relative movement math and server-side facing helpers.

const PlayerScript = preload("res://features/player/Player.gd")
const EPSILON: float = 0.001


func test_camera_relative_forward_at_zero_yaw() -> void:
	var result: Vector2 = PlayerScript.camera_relative_input(Vector2(0, -1), 0.0)
	assert_true(result.distance_to(Vector2(0, -1)) < EPSILON, "zero yaw keeps W as forward")


func test_camera_relative_forward_at_quarter_turn() -> void:
	var result: Vector2 = PlayerScript.camera_relative_input(Vector2(0, -1), PI / 2)
	assert_true(result.distance_to(Vector2(-1, 0)) < EPSILON, "quarter turn turns W left")


func test_camera_relative_right_at_quarter_turn() -> void:
	var result: Vector2 = PlayerScript.camera_relative_input(Vector2(1, 0), PI / 2)
	assert_true(result.distance_to(Vector2(0, -1)) < EPSILON, "quarter turn turns D forward")


func test_camera_relative_clamps_diagonal() -> void:
	var result: Vector2 = PlayerScript.camera_relative_input(Vector2(1, -1), 0.0)
	assert_true(absf(result.length() - 1.0) < EPSILON, "diagonal input is clamped to length 1")


func test_facing_yaw_forward() -> void:
	assert_true(absf(PlayerScript.facing_yaw(Vector3(0, 0, -1))) < EPSILON, "forward is yaw 0")


func test_facing_yaw_left() -> void:
	assert_true(absf(PlayerScript.facing_yaw(Vector3(-1, 0, 0)) - PI / 2) < EPSILON, "left is yaw PI/2")


func test_turn_toward_moves_partway() -> void:
	var result: float = PlayerScript.turn_toward(0.0, 1.0, 0.01)
	assert_true(result > 0.0 and result < 1.0, "small delta turns partway")


func test_turn_toward_large_delta_reaches_target() -> void:
	var result: float = PlayerScript.turn_toward(0.0, 1.0, 1.0)
	assert_true(absf(result - 1.0) < EPSILON, "large delta reaches the target yaw")


func test_smoothed_position_slides_partway() -> void:
	var result: Vector3 = PlayerScript.smoothed_position(Vector3.ZERO, Vector3(1, 0, 0), 0.016)
	assert_true(result.x > 0.0 and result.x < 1.0, "small gap slides partway")


func test_smoothed_position_snaps_when_far() -> void:
	var result: Vector3 = PlayerScript.smoothed_position(Vector3.ZERO, Vector3(10, 0, 0), 0.016)
	assert_eq(result, Vector3(10, 0, 0), "large gap snaps to the target")


func test_interp_weight_bounds() -> void:
	assert_true(absf(PlayerScript.interp_weight(0.0)) < EPSILON, "zero delta has zero weight")
	assert_true(absf(PlayerScript.interp_weight(10.0) - 1.0) < EPSILON, "large delta approaches full weight")


func test_player_scene_replicates_snapshot() -> void:
	var packed: PackedScene = load("res://features/player/Player.tscn") as PackedScene
	var player: Node = packed.instantiate()
	var sync := player.get_node("MultiplayerSynchronizer") as MultiplayerSynchronizer
	var paths: Array[NodePath] = sync.replication_config.get_properties()
	player.free()
	assert_true(paths.has(NodePath(".:sync_position")), "replicates sync_position")
	assert_true(paths.has(NodePath(".:sync_yaw")), "replicates sync_yaw")
	assert_false(paths.has(NodePath(".:position")), "no longer replicates position")
