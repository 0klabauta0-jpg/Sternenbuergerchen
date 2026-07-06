extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_828_release_ultrawide_canvas_stretch.md"
const PROJECT_PATH := "res://project.godot"
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/main_menu.tscn"
const HOMEBASE_SCENE_PATH := "res://scenes/meta/homebase_test_screen.tscn"
const META_LAYER_SCENE_PATH := "res://scenes/meta/meta_layer_test.tscn"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_828 Release Ultrawide Canvas Stretch ===")
	_test_task_doc_exists()
	_test_project_stretch_contract()
	await _test_fullscreen_control_roots()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_828_release_ultrawide_canvas_stretch: FAILED")
		quit(1)
		return
	print("TASK_828_release_ultrawide_canvas_stretch: ALL PASSED")
	quit(0)


func _test_task_doc_exists() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "Task file exists")


func _test_project_stretch_contract() -> void:
	var project_text: String = _read_text(PROJECT_PATH)
	_assert(project_text.contains('window/size/viewport_width=1920'), "Project keeps FullHD base viewport width")
	_assert(project_text.contains('window/size/viewport_height=1080'), "Project keeps FullHD base viewport height")
	_assert(project_text.contains('window/stretch/mode="canvas_items"'), "Project uses canvas item stretch mode")
	_assert(project_text.contains('window/stretch/aspect="expand"'), "Project expands canvas on wider windows")
	_assert(String(ProjectSettings.get_setting("display/window/stretch/mode", "")) == "canvas_items", "ProjectSettings exposes canvas item stretch mode")
	_assert(String(ProjectSettings.get_setting("display/window/stretch/aspect", "")) == "expand", "ProjectSettings exposes expand aspect")


func _test_fullscreen_control_roots() -> void:
	var main_menu := _instantiate_scene(MAIN_MENU_SCENE_PATH) as Control
	_assert(main_menu != null, "Main menu instantiates as Control")
	if main_menu != null:
		_assert(_is_fullscreen_anchored(main_menu), "Main menu root is fullscreen anchored")
		main_menu.queue_free()
		await process_frame

	var homebase := _instantiate_scene(HOMEBASE_SCENE_PATH) as Control
	_assert(homebase != null, "Homebase screen instantiates as Control")
	if homebase != null:
		_assert(_is_fullscreen_anchored(homebase), "Homebase root is fullscreen anchored")
		var panel := homebase.get_node_or_null("Panel") as Control
		_assert(panel != null and _is_fullscreen_anchored(panel), "Homebase panel fills the expanded canvas")
		homebase.queue_free()
		await process_frame

	var meta_layer := _instantiate_scene(META_LAYER_SCENE_PATH)
	_assert(meta_layer != null, "MetaLayer scene instantiates")
	if meta_layer != null:
		var meta_homebase := meta_layer.get_node_or_null("HomebaseScreen") as Control
		_assert(meta_homebase != null and _is_fullscreen_anchored(meta_homebase), "MetaLayer Homebase child remains fullscreen anchored")
		meta_layer.queue_free()
		await process_frame


func _instantiate_scene(path: String) -> Node:
	var packed_scene := ResourceLoader.load(path) as PackedScene
	if packed_scene == null:
		return null
	var node := packed_scene.instantiate()
	root.add_child(node)
	return node


func _is_fullscreen_anchored(control: Control) -> bool:
	if control == null:
		return false
	return is_equal_approx(control.anchor_left, 0.0) \
		and is_equal_approx(control.anchor_top, 0.0) \
		and is_equal_approx(control.anchor_right, 1.0) \
		and is_equal_approx(control.anchor_bottom, 1.0)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
