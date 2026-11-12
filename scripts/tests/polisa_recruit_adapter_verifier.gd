extends SceneTree
func _init() -> void:
	var script = load("res://scripts/meta/singleplayer_runtime_adapter.gd")
	if script == null:
		printerr("FAIL: adapter missing")
		quit(1)
		return
	var adapter = script.new()
	if not adapter.has_method("get_polisa_recruitment_snapshot") or not adapter.has_method("_request_polisa_recruitment"):
		printerr("FAIL: recruitment adapter API")
		quit(1)
		return
	adapter.free()
	print("PASS: recruitment adapter API loads")
	quit(0)
