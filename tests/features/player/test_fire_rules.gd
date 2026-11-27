extends TestCase
## Pure hitscan fire rules: fire interval and aim sanitizing.

const EPSILON: float = 0.001


func test_fire_allowed_after_interval() -> void:
	assert_true(PlayerService.fire_allowed(1250, 1000, 250), "250 ms after the last shot is allowed")


func test_fire_blocked_inside_interval() -> void:
	assert_false(PlayerService.fire_allowed(1249, 1000, 250), "one ms short of the interval is blocked")


func test_fire_allowed_first_shot() -> void:
	assert_true(PlayerService.fire_allowed(1000, 0, 250), "the first shot is always allowed")


func test_sanitize_aim_normalizes() -> void:
	var dir: Vector3 = PlayerService.sanitize_aim(Vector3(0, 0, -5))
	assert_true(dir.distance_to(Vector3(0, 0, -1)) < EPSILON, "aim is normalized")


func test_sanitize_aim_rejects_zero() -> void:
	assert_eq(PlayerService.sanitize_aim(Vector3.ZERO), Vector3.ZERO, "zero aim is rejected")


func test_sanitize_aim_rejects_nan() -> void:
	assert_eq(PlayerService.sanitize_aim(Vector3(NAN, 0, 1)), Vector3.ZERO, "NaN aim is rejected")


func test_sanitize_aim_rejects_inf() -> void:
	assert_eq(PlayerService.sanitize_aim(Vector3(INF, 0, 1)), Vector3.ZERO, "infinite aim is rejected")
