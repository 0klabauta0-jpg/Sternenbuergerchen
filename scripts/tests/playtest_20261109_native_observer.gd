extends SceneTree
## Test-only native observer: normal main-menu startup and real OS inputs.
## External requests control only capture, window size and test shutdown.

const OUT := "res://docs/qa/singleplayer_20261109/raw/native/"
const REQUEST := "res://.superpowers/sdd/2026-11-09-singleplayer-basis-orte-ui/native-request.json"
var _elapsed: float = 0.0
var _last_request: String = ""
var _frame_count: int = 0
var _max_delta: float = 0.0
var _inputs: Node

class InputObserver extends Node:
	var counts := {"mouse_press": 0, "key_press": 0, "mouse_motion": 0}
	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			counts.mouse_press += 1
		elif event is InputEventKey and event.pressed and not event.echo:
			counts.key_press += 1
		elif event is InputEventMouseMotion:
			counts.mouse_motion += 1

func _initialize() -> void:
	call_deferred("_start")

func _start() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_inputs = InputObserver.new()
	root.add_child(_inputs)
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	root.title = "SternenBuergerchen — Einzelspieler AP8"
	print("NATIVE_PROFILE ", OS.get_user_data_dir())

func _process(delta: float) -> bool:
	_frame_count += 1
	_max_delta = maxf(_max_delta, delta)
	_elapsed += delta
	if _elapsed < 0.25 or not FileAccess.file_exists(REQUEST):
		return false
	_elapsed = 0.0
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(REQUEST))
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var request: Dictionary = parsed
	var id: String = String(request.get("id", ""))
	if id.is_empty() or id == _last_request:
		return false
	_last_request = id
	if request.has("resolution"):
		var resolution: Array = request.resolution
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(int(resolution[0]), int(resolution[1]))
	if request.has("capture"):
		call_deferred("_capture", String(request.capture).get_file())
	if request.get("quit", false):
		quit()
	return false

func _capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + label + ".png")
	var info: Dictionary = {"window_size": root.size, "frame_count": _frame_count, "max_frame_delta_seconds": _max_delta, "inputs": _inputs.get("counts"), "profile": OS.get_user_data_dir(), "current_scene": current_scene.name if current_scene != null else ""}
	var flow: Node = root.find_child("MetaLayerTest", true, false)
	if flow == null:
		flow = root.find_child("MetaLayer", true, false)
	if flow != null and flow.has_method("get_singleplayer_snapshot"):
		info["singleplayer"] = flow.call("get_singleplayer_snapshot")
	var file := FileAccess.open(OUT + label + ".json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(info, "\t"))
	print("NATIVE_CAPTURE ", label)
