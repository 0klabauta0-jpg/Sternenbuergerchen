extends SceneTree

const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_559_factory_colormap_uid_loader_guard.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const VIEW_PATH: String = "res://scripts/terrain/terrain_map_3d_view.gd"
const FACTORY_COLORMAP_TEXTURE_PATH: String = "res://Assets/curated/kenney/factory/models/Textures/colormap.png"
const FACTORY_MODEL_PATHS: Array[String] = [
	"res://Assets/curated/kenney/factory/models/detail-tank.glb",
	"res://Assets/curated/kenney/factory/models/building-a.glb",
	"res://Assets/curated/kenney/factory/models/chimney-medium.glb",
	"res://Assets/curated/kenney/factory/models/building-d.glb",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_559 Factory Colormap UID Loader Guard ===")
	_test_docs_and_wiring()
	_test_factory_colormap_uid_loader_guard()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_559: FAILED")
		quit(1)
		return
	print("TASK_559: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var view_text: String = _read_text(VIEW_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_559 task file exists")
	_assert(task_text.contains("Factory Colormap UID Loader Guard"), "TASK_559 task file names the task")
	_assert(status_text.contains("TASK_559 - Factory Colormap UID Loader Guard"), "Implementation status tracks TASK_559")
	_assert(roadmap_text.contains("TASK_559 - Factory Colormap UID Loader Guard (implementiert)"), "Roadmap marks TASK_559 implemented")
	_assert(roadmap_text.contains("TASK_560 - Frontier Probe Multiplayer F6 Visual Polish Follow-up"), "Roadmap names TASK_560 follow-up")
	_assert(report_text.contains("TASK_559 - Factory Colormap UID Loader Guard"), "Review workbench tracks TASK_559")
	_assert(view_text.contains("_ensure_factory_colormap_uid_registered"), "TerrainMap3DView exposes Factory colormap UID guard")


func _test_factory_colormap_uid_loader_guard() -> void:
	_assert(ResourceLoader.exists(FACTORY_COLORMAP_TEXTURE_PATH), "Factory shared colormap texture exists")
	var deterministic_id: int = ResourceUID.create_id_for_path(FACTORY_COLORMAP_TEXTURE_PATH)
	_assert(deterministic_id != ResourceUID.INVALID_ID, "Factory shared colormap has deterministic path UID")
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	for model_path in FACTORY_MODEL_PATHS:
		var packed_scene = view.call("_get_asset_model_scene_by_path", model_path)
		_assert(packed_scene != null, "%s loads as PackedScene through TerrainMap3DView" % model_path.get_file())
	_assert(ResourceUID.has_id(deterministic_id), "Factory deterministic colormap UID is registered before GLB loads")
	_assert(ResourceUID.get_id_path(deterministic_id) == FACTORY_COLORMAP_TEXTURE_PATH, "Factory deterministic colormap UID points to shared texture path")
	view.queue_free()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
