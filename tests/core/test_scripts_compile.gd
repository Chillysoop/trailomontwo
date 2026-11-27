extends TestCase
## Every script under src/ compiles. UI scripts aren't loaded by the other tests, so a typo in
## a screen would otherwise only show up when the game runs.


func test_every_script_compiles() -> void:
	var files: Array[String] = []
	_collect("res://src", files)
	check(files.size() > 50, "found the scripts (%d)" % files.size())
	for path in files:
		var s: GDScript = load(path)
		check(s != null and s.can_instantiate(), "%s compiles" % path)


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_collect(dir_path.path_join(sub), out)
	for f in dir.get_files():
		if f.ends_with(".gd"):
			out.append(dir_path.path_join(f))
