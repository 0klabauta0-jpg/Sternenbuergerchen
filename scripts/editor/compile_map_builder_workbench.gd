extends SceneTree

const WORKBENCH_SCENE_PATH: String = "res://scenes/editor/map_builder_workbench.tscn"
const DEFAULT_OUTPUT_PATH: String = "res://maps/map_builder_workbench_output.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_path: String = _read_output_arg()
	var scene: PackedScene = load(WORKBENCH_SCENE_PATH) as PackedScene
	if scene == null:
		push_error("Map builder workbench scene missing: %s" % WORKBENCH_SCENE_PATH)
		quit(1)
		return
	var workbench: Node = scene.instantiate()
	root.add_child(workbench)
	await process_frame
	if not workbench.has_method("save_compiled_map"):
		push_error("Map builder workbench has no save_compiled_map()")
		quit(1)
		return
	var result: Dictionary = Dictionary(workbench.call("save_compiled_map", output_path))
	var ok: bool = bool(result.get("ok", false))
	print("Map builder compile output: %s" % String(result.get("output_path", output_path)))
	print("Map builder compile stats: %s" % str(result.get("stats", {})))
	if not ok:
		push_error("Map builder compile failed: %s" % str(result))
		quit(1)
		return
	quit(0)


func _read_output_arg() -> String:
	for arg in OS.get_cmdline_user_args():
		var value: String = String(arg)
		if value.begins_with("--output="):
			return value.trim_prefix("--output=").strip_edges()
	return DEFAULT_OUTPUT_PATH
