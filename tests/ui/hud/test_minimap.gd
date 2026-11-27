extends TestCase
## Minimap camera placement and its HUD rect / hidden-without-target state.


func test_camera_position() -> void:
	assert_eq(
		Minimap.camera_position(Vector3(3, 1, -4)),
		Vector3(3, 1 + GameConst.HUD_MINIMAP_HEIGHT, -4),
		"camera sits HUD_MINIMAP_HEIGHT above the target"
	)


func test_minimap_rect_and_hidden_without_target() -> void:
	var map := Minimap.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(map)
	var map_position := map.position
	var map_size := map.size
	var map_visible := map.visible
	var child_count := map.get_child_count()
	map.free()
	assert_eq(map_position, GameConst.HUD_MINIMAP_RECT.position, "minimap position matches the HUD rect")
	assert_eq(map_size, GameConst.HUD_MINIMAP_RECT.size, "minimap size matches the HUD rect")
	assert_false(map_visible, "minimap hidden without a target")
	assert_eq(child_count, 1, "minimap owns one SubViewport child")
