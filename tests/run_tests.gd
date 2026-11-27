extends SceneTree
## Headless test entry point. Discovers every `tests/**/test_*.gd`, runs each
## zero-argument `test_*` method, prints per-file results, then exits 0 on
## success or 1 on failure. No network or scene tree is required.

const TESTS_ROOT: String = "res://tests"

var _total_checks: int = 0
var _total_failures: int = 0


func _initialize() -> void:
	var test_files := _find_test_files()
	if test_files.is_empty():
		printerr("No test files found under %s" % TESTS_ROOT)
		quit(1)
		return

	for path: String in test_files:
		_run_test_file(path)

	if _total_failures == 0:
		print("ALL TESTS PASSED (%d assertions)" % _total_checks)
		quit(0)
	else:
		printerr("TESTS FAILED (%d assertions, %d failures)" % [_total_checks, _total_failures])
		quit(1)


func _run_test_file(path: String) -> void:
	var script := load(path) as GDScript
	if script == null:
		_total_failures += 1
		printerr("[FAIL] %s (could not load script)" % path)
		return
	var test: TestCase = script.new() as TestCase
	if test == null:
		_total_failures += 1
		printerr("[FAIL] %s (does not extend TestCase)" % path)
		return
	var method_names: Array[String] = []
	for method: Dictionary in test.get_method_list():
		var method_name := String(method.get("name", ""))
		if method_name.begins_with("test_") and not method_names.has(method_name):
			method_names.append(method_name)
	method_names.sort()
	if method_names.is_empty():
		_total_failures += 1
		printerr("[FAIL] %s (no test_* methods)" % path)
		return
	for method_name: String in method_names:
		test.call(method_name)
	_total_checks += test.checks
	_total_failures += test.failures.size()
	if test.failures.is_empty():
		print("[PASS] %s (%d assertions)" % [path, test.checks])
	else:
		printerr("[FAIL] %s (%d assertions, %d failures)" % [path, test.checks, test.failures.size()])
		for failure: String in test.failures:
			printerr("  - " + failure)


func _find_test_files() -> Array[String]:
	var result: Array[String] = []
	_scan_tests_dir(TESTS_ROOT, result)
	result.sort()
	return result


func _scan_tests_dir(directory: String, result: Array[String]) -> void:
	var dir := DirAccess.open(directory)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			var full_path := directory.path_join(entry)
			if dir.current_is_dir():
				_scan_tests_dir(full_path, result)
			elif entry.begins_with("test_") and entry.ends_with(".gd"):
				result.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
