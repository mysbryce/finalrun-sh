class_name TestCase
extends RefCounted
## Shared assertion helpers for the headless test suite.
##
## Every `tests/**/test_*.gd` extends this class and defines zero-argument
## methods named `test_*`. `tests/run_tests.gd` discovers and calls them.

var checks: int = 0
var failures: Array[String] = []


func assert_true(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func assert_false(condition: bool, message: String) -> void:
	assert_true(not condition, message)


func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	checks += 1
	var equal: bool = actual == expected
	if actual is float or expected is float:
		equal = is_equal_approx(float(actual), float(expected))
	if not equal:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])
