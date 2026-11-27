extends TestCase
## Allowed map routes are a pure function, testable without a network.


func test_allowed_routes() -> void:
	assert_true(TransferService.is_route_allowed("Motel", "LootyBay"), "Motel -> LootyBay")
	assert_true(TransferService.is_route_allowed("Motel", "House"), "Motel -> House")
	assert_true(TransferService.is_route_allowed("Motel", "Center"), "Motel -> Center")
	assert_true(TransferService.is_route_allowed("House", "Motel"), "House -> Motel")
	assert_true(TransferService.is_route_allowed("House", "Center"), "House -> Center")
	assert_true(TransferService.is_route_allowed("Center", "Motel"), "Center -> Motel")
	assert_true(TransferService.is_route_allowed("Center", "House"), "Center -> House")


func test_blocked_routes() -> void:
	assert_false(TransferService.is_route_allowed("LootyBay", "Motel"), "LootyBay -> Motel is exit-only")
	assert_false(TransferService.is_route_allowed("LootyBay", "House"), "LootyBay -> House is blocked")
	assert_false(TransferService.is_route_allowed("LootyBay", "Center"), "LootyBay -> Center is blocked")
	assert_false(TransferService.is_route_allowed("Center", "LootyBay"), "Center -> LootyBay is blocked")
	assert_false(TransferService.is_route_allowed("House", "LootyBay"), "House -> LootyBay is blocked")
	assert_false(TransferService.is_route_allowed("Motel", "Motel"), "same-map transfer is rejected")
	assert_false(TransferService.is_route_allowed("Unknown", "Motel"), "unknown source is rejected")
