class_name TestCase
extends RefCounted
## Minimal base class for headless tests. Any method starting with "test_" runs.

var failures: Array[String] = []
var _current := ""


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append("%s: %s" % [_current, message])


func check_eq(actual: Variant, expected: Variant, message := "") -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s %s" % [_current, str(expected), str(actual), message])


func check_near(actual: float, expected: float, tolerance := 0.0001, message := "") -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s: expected about %s, got %s %s" % [_current, str(expected), str(actual), message])
