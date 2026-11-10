extends SceneTree


func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://manifest.json"))
	var packer := PCKPacker.new()
	var error: Error = packer.pck_start(String(manifest.output))
	if error != OK:
		push_error("PCK start failed: %d" % error)
		quit(1)
		return
	for entry: Dictionary in manifest.files:
		error = packer.add_file(String(entry.path), String(entry.source))
		if error != OK:
			push_error("PCK add failed: %s error %d" % [entry.path, error])
			quit(1)
			return
	error = packer.flush()
	print("PORTRAIT_PACK_BUILT files=%d error=%d" % [manifest.files.size(), error])
	quit(0 if error == OK else 1)
