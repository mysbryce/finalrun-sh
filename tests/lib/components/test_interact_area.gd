extends TestCase
## InteractArea nearest-target rule.


func test_pick_nearest_empty() -> void:
	assert_eq(InteractArea.pick_nearest(Vector3.ZERO, [], 2.5), -1, "empty positions give -1")


func test_pick_nearest_out_of_range() -> void:
	assert_eq(
		InteractArea.pick_nearest(Vector3.ZERO, [Vector3(3, 0, 0)], 2.5),
		-1,
		"out-of-range position gives -1"
	)


func test_pick_nearest_edge_inclusive() -> void:
	assert_eq(
		InteractArea.pick_nearest(Vector3.ZERO, [Vector3(2.5, 0, 0)], 2.5),
		0,
		"edge distance is inclusive"
	)


func test_pick_nearest_closest() -> void:
	assert_eq(
		InteractArea.pick_nearest(
			Vector3.ZERO,
			[Vector3(2, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1.5)],
			2.5
		),
		1,
		"closest position wins"
	)


func test_pick_nearest_tie_keeps_first() -> void:
	assert_eq(
		InteractArea.pick_nearest(
			Vector3.ZERO,
			[Vector3(1, 0, 0), Vector3(-1, 0, 0)],
			2.5
		),
		0,
		"ties keep the first index"
	)
