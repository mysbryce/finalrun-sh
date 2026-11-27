extends TestCase
## Reusable hold-interact channel: completion, movement and cancellation reasons.


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _make_actor() -> Node3D:
	var actor := Node3D.new()
	_tree().root.add_child(actor)
	return actor


func _make_timer(actor: Node3D, check: Callable = Callable()) -> ChannelTimer:
	var timer := ChannelTimer.new()
	_tree().root.add_child(timer)
	timer.start(2.0, actor, 0.75, check)
	return timer


func test_completes_after_duration() -> void:
	var actor := _make_actor()
	var timer := _make_timer(actor)
	var completed: Array[bool] = []
	timer.completed.connect(func() -> void: completed.append(true))
	timer.call("_process", 1.0)
	assert_true(timer.is_active(), "channel keeps running before the duration ends")
	timer.call("_process", 1.1)
	assert_false(timer.is_active(), "channel stops when the timer finishes")
	assert_eq(completed.size(), 1, "completed is emitted exactly once")
	timer.free()
	actor.free()


func test_moving_cancels_with_moved() -> void:
	var actor := _make_actor()
	var timer := _make_timer(actor)
	var reasons: Array[String] = []
	timer.cancelled.connect(func(reason: String) -> void: reasons.append(reason))
	actor.position.x = 2.0
	timer.call("_process", 0.1)
	assert_false(timer.is_active(), "moving cancels the channel")
	assert_eq(reasons, ["moved"] as Array[String], "movement reports the moved reason")
	timer.free()
	actor.free()


func test_cancel_check_reason_is_used() -> void:
	var actor := _make_actor()
	var timer := _make_timer(actor, func() -> String: return "no_los")
	var reasons: Array[String] = []
	timer.cancelled.connect(func(reason: String) -> void: reasons.append(reason))
	timer.call("_process", 0.1)
	assert_eq(reasons, ["no_los"] as Array[String], "cancel_check reason is forwarded")
	timer.free()
	actor.free()


func test_public_cancel_emits_reason_once() -> void:
	var actor := _make_actor()
	var timer := _make_timer(actor)
	var reasons: Array[String] = []
	timer.cancelled.connect(func(reason: String) -> void: reasons.append(reason))
	timer.cancel("damaged")
	timer.cancel("disconnected")
	assert_false(timer.is_active(), "cancel deactivates the channel")
	assert_eq(reasons, ["damaged"] as Array[String], "only the first cancel is emitted")
	timer.free()
	actor.free()


func test_actor_freed_cancels_with_actor_state() -> void:
	var actor := _make_actor()
	var timer := _make_timer(actor)
	var reasons: Array[String] = []
	timer.cancelled.connect(func(reason: String) -> void: reasons.append(reason))
	actor.free()
	timer.call("_process", 0.1)
	assert_eq(reasons, ["actor_state"] as Array[String], "a missing actor cancels the channel")
	timer.free()


func test_reason_contract() -> void:
	var expected: Array[String] = [
		"moved",
		"out_of_range",
		"no_los",
		"damaged",
		"disconnected",
		"target_state",
		"actor_state",
		"left_instance",
		"invalid_state",
	]
	assert_eq(ChannelTimer.REASONS, expected, "ChannelTimer exposes the documented reason set")
