extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const TASK_DOC_PATH: String = "res://docs/tasks/TASK_484_map_editor_palette_browser_layout.md"
const WORKFLOW_CONTRACT_PATH: String = "res://docs/dev/map_editor_asset_workflow_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_484 Map Editor Palette Browser Layout ===")
	_test_docs()
	await _test_palette_browser_layout()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_484 task file exists")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("Asset-Browser"), "Workflow contract documents asset browser layout")
	_assert(_read_text(STATUS_PATH).contains("TASK_484 - Map Editor Palette Browser Layout"), "Implementation status tracks TASK_484")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_484 - Map Editor Palette Browser Layout"), "Roadmap lists TASK_484")


func _test_palette_browser_layout() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	editor.call("_on_palette_group_button_pressed", "fahrzeuge")
	await _wait_frames(2)
	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var palette: Dictionary = Dictionary(snapshot.get("palette", {}))
	var icon_size: Vector2i = Vector2i(palette.get("preview_icon_size", Vector2i.ZERO))
	var asset_list_min_size: Vector2 = Vector2(palette.get("asset_list_min_size", Vector2.ZERO))
	var selected_preview_size: Vector2 = Vector2(palette.get("selected_preview_size", Vector2.ZERO))
	_assert(float(palette.get("panel_min_width", 0.0)) >= 420.0, "Palette panel is wide enough for readable previews")
	_assert(icon_size.x >= 64 and icon_size.y >= 64, "Asset list preview icons are readable")
	_assert(selected_preview_size.x >= 100.0 and selected_preview_size.y >= 100.0, "Selected asset preview is large")
	_assert(bool(palette.get("group_scrollable", false)), "Palette groups live in a scrollable area")
	_assert(float(palette.get("group_scroll_min_height", 0.0)) <= 170.0, "Group scroll area stays compact")
	_assert(int(palette.get("group_columns", 0)) >= 2, "Palette groups use multiple columns")
	_assert(float(palette.get("group_button_max_height", 99.0)) <= 24.0, "Palette group buttons are compact")
	_assert(int(palette.get("asset_list_icon_mode", -1)) == int(ItemList.ICON_MODE_TOP), "Asset list uses top icon mode")
	_assert(int(palette.get("asset_list_max_columns", 0)) >= 2, "Asset list uses at least two columns")
	_assert(int(palette.get("asset_list_fixed_column_width", 0)) >= 180, "Asset columns have enough width for labels")
	_assert(asset_list_min_size.y >= 540.0, "Asset list gets the main vertical space")
	_assert(String(palette.get("active_group", "")) == "fahrzeuge", "Vehicle group remains selectable")
	var visible_ids: PackedStringArray = PackedStringArray(palette.get("visible_type_ids", PackedStringArray()))
	_assert(visible_ids.has("fahrzeug_speeder_b_ne") or visible_ids.has("fahrzeug_speeder_b_se"), "Vehicle browser still exposes vehicle assets")
	var legacy_group_button := editor.get_node_or_null("UI/PalettePanel/Margin/VBox/PaletteGroups/PaletteGroup_fahrzeuge") as Button
	_assert(legacy_group_button != null, "Legacy palette group path remains available for older tests")
	editor.queue_free()
	await _wait_frames(2)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
