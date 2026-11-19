extends SceneTree
## Headless test runner.
## Usage: godot --headless --path . --script res://tests/run_tests.gd
## Finds every tests/**/test_*.gd, runs each test_ method, exits 1 on any failure.


func _init() -> void:
	var files: Array[String] = []
	_collect("res://tests", files)
	files.sort()
	var total := 0
	var failed: Array[String] = []
	for path in files:
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			failed.append("%s: could not load" % path)
			continue
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			var case: TestCase = script.new()
			case._current = "%s::%s" % [path.get_file(), name]
			case.call(name)
			total += 1
			failed.append_array(case.failures)
	for line in failed:
		printerr("FAIL ", line)
	print("%d tests run, %d failures" % [total, failed.size()])
	quit(1 if failed.size() > 0 or total == 0 else 0)


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_collect(dir_path.path_join(sub), out)
	for file in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			out.append(dir_path.path_join(file))
