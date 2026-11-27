extends TestCase
## Server id helpers stay on the autoload because clients print/compare them.

const ServerManagerScript = preload("res://autoload/ServerManager.gd")


func test_server_id_format() -> void:
	var generated: String = ServerManagerScript.generate_server_id()
	assert_true(
		ServerManagerScript.is_valid_server_id(generated),
		"server id matches SV-SPACE-XXXX (got %s)" % generated
	)
	assert_eq(
		ServerManagerScript.format_server_id(7),
		"SV-SPACE-0007",
		"server id zero-pads to four digits"
	)
	assert_eq(
		ServerManagerScript.format_server_id(42),
		"SV-SPACE-0042",
		"server id pads 42"
	)
	assert_true(
		not ServerManagerScript.is_valid_server_id("SV-SPACE-123"),
		"three digit server id is rejected"
	)
	assert_true(
		not ServerManagerScript.is_valid_server_id("SV-SPACE-12345"),
		"five digit server id is rejected"
	)
	assert_true(
		not ServerManagerScript.is_valid_server_id("SV-SPACE-abcd"),
		"non numeric server id is rejected"
	)
