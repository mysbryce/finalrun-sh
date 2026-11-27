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
