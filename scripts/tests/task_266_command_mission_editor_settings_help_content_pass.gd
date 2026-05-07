extends SceneTree

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const MULTIPLAYER_LOBBY_SCENE: PackedScene = preload("res://scenes/ui/multiplayer_lobby.tscn")
const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const CATALOG_PATH: String = "res://data/contextual_help_catalog.json"
const COPY_DOC_PATH: String = "res://docs/content/command_mission_editor_settings_help_copy.md"
const MATRIX_PATH: String = "res://docs/qa/playability_coverage_matrix.md"
const TASK_PATH: String = "res://docs/tasks/TASK_266_command_mission_editor_settings_help_content_pass.md"

const REQUIRED_READY_IDS: Array = [
	"mission.command_matrix",
	"mission.selected_fireteam",
	"mission.mission_control",
	"mission.command.move",
	"mission.command.defend",
	"mission.command.hold",
	"mission.command.flank",
	"mission.command.take",
	"mission.command.attack_area",
	"mission.command.defend_area",
	"mission.command.area_order",
	"mission.command.go_plan",
	"mission.command.stance",
	"mission.command.advance_style",
	"mission.command.overwatch",
	"mission.command.security",
	"mission.command.medic_adjacent",
	"mission.command.set_lz",
	"mission.command.call_dropship",
	"mission.command.approach",
	"mission.command.clear_target",
	"settings.display",
	"settings.audio",
	"settings.input",
	"settings.gameplay",
	"settings.fog_of_war.off",
	"settings.fog_of_war.known_terrain",
	"settings.fog_of_war.unexplored_blackout",
	"multiplayer.host",
	"multiplayer.join",
	"multiplayer.ready",
	"multiplayer.start",
	"multiplayer.disconnect",
	"multiplayer.map_download",
	"multiplayer.roster_ownership",
	"editor.tile_palette",
	"editor.brush_size",
	"editor.height_tool",
	"editor.edge.slope",
	"editor.edge.cliff",
	"editor.surface",
	"editor.object",
	"editor.save",
	"editor.load",
	"editor.save_as",
	"editor.playtest",
]

const REQUIRED_TODO_IDS: Array = [
	"editor.back",
	"mission.command.roe_fire_rules",
]

const MAIN_MENU_HELP_IDS: Array = [
	"settings.display",
	"settings.audio",
	"settings.input",
	"settings.gameplay",
	"settings.fog_of_war_mode",
	"settings.contextual_help_mode",
]

const LOBBY_HELP_IDS: Array = [
	"multiplayer.host",
	"multiplayer.join",
	"multiplayer.ready",
	"multiplayer.start",
	"multiplayer.disconnect",
	"multiplayer.map_download",
	"multiplayer.roster_ownership",
]

const EDITOR_HELP_IDS: Array = [
	"editor.tile_palette",
	"editor.brush_size",
	"editor.height_tool",
	"editor.edge.slope",
	"editor.edge.cliff",
	"editor.surface",
	"editor.object",
	"editor.save",
	"editor.load",
	"editor.save_as",
	"editor.playtest",
]

const MISSION_HELP_IDS: Array = [
	"mission.command_matrix",
	"mission.selected_fireteam",
	"mission.mission_control",
	"mission.command.move",
	"mission.command.defend",
	"mission.command.flank",
	"mission.command.take",
	"mission.command.attack_area",
	"mission.command.defend_area",
	"mission.command.area_order",
	"mission.command.go_plan",
	"mission.command.stance",
	"mission.command.advance_style",
	"mission.command.overwatch",
	"mission.command.security",
	"mission.command.medic_adjacent",
	"mission.command.set_lz",
	"mission.command.call_dropship",
	"mission.command.approach",
	"mission.command.clear_target",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_266 Command Mission Editor Settings Help Content Pass ===")
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	var entries_by_id: Dictionary = _build_entries_by_id(catalog)
	_test_catalog_content(catalog, entries_by_id)
	await _test_settings_help_ids(entries_by_id)
	await _test_multiplayer_lobby_help_ids(entries_by_id)
	await _test_map_editor_help_ids(entries_by_id)
	await _test_mission_help_ids(entries_by_id)
	_test_copy_doc_and_matrix()
	_test_task_status()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_catalog_content(catalog: Dictionary, entries_by_id: Dictionary) -> void:
	_assert(not catalog.is_empty(), "Contextual help catalog parses")
	_assert(Array(catalog.get("allowed_statuses", [])).has("todo"), "Catalog permits todo status for coverage report")
	for required_id in REQUIRED_READY_IDS:
		_assert(entries_by_id.has(required_id), "Catalog contains %s" % required_id)
		var entry: Dictionary = Dictionary(entries_by_id.get(required_id, {}))
		_assert(String(entry.get("status", "")) == "ready", "%s is ready copy" % required_id)
		_assert(["mission", "settings", "multiplayer", "editor"].has(String(entry.get("screen_id", ""))), "%s uses TASK_266 grouping" % required_id)
		_assert(_entry_text_is_compact(entry), "%s text fits compact/detail limits" % required_id)
	for todo_id in REQUIRED_TODO_IDS:
		_assert(entries_by_id.has(todo_id), "Catalog contains todo %s" % todo_id)
		var todo_entry: Dictionary = Dictionary(entries_by_id.get(todo_id, {}))
		_assert(String(todo_entry.get("status", "")) == "todo", "%s is marked todo" % todo_id)
		_assert(bool(todo_entry.get("manual_review", false)), "%s requires manual review" % todo_id)
		_assert(_entry_text_is_compact(todo_entry), "%s todo text still fits" % todo_id)
	_test_duplicate_ids(entries_by_id, Array(catalog.get("entries", [])))


func _test_settings_help_ids(entries_by_id: Dictionary) -> void:
	var menu := MAIN_MENU_SCENE.instantiate()
	root.add_child(menu)
	await process_frame
	var help_ids: PackedStringArray = _collect_help_ids(menu)
	for required_id in MAIN_MENU_HELP_IDS:
		_assert(help_ids.has(required_id), "Main menu settings carries %s" % required_id)
		_assert(entries_by_id.has(required_id), "Catalog contains main menu help_id %s" % required_id)
	menu.queue_free()
	await process_frame


func _test_multiplayer_lobby_help_ids(entries_by_id: Dictionary) -> void:
	var lobby := MULTIPLAYER_LOBBY_SCENE.instantiate()
	root.add_child(lobby)
	await process_frame
	var help_ids: PackedStringArray = _collect_help_ids(lobby)
	for required_id in LOBBY_HELP_IDS:
		_assert(help_ids.has(required_id), "Multiplayer lobby carries %s" % required_id)
		_assert(entries_by_id.has(required_id), "Catalog contains lobby help_id %s" % required_id)
	lobby.queue_free()
	await process_frame


func _test_map_editor_help_ids(entries_by_id: Dictionary) -> void:
	var editor := MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(3)
	var help_ids: PackedStringArray = _collect_help_ids(editor)
	for required_id in EDITOR_HELP_IDS:
		_assert(help_ids.has(required_id), "Map editor carries %s" % required_id)
		_assert(entries_by_id.has(required_id), "Catalog contains editor help_id %s" % required_id)
	_assert(not help_ids.has("editor.back"), "Editor back help remains todo because no Back control exists")
	editor.queue_free()
	await process_frame


func _test_mission_help_ids(entries_by_id: Dictionary) -> void:
	var mission := MISSION_SCENE.instantiate()
	root.add_child(mission)
	await _wait_frames(5)
	var help_ids: PackedStringArray = _collect_help_ids(mission)
	for required_id in MISSION_HELP_IDS:
		_assert(help_ids.has(required_id), "Mission HUD carries %s" % required_id)
		_assert(entries_by_id.has(required_id), "Catalog contains mission help_id %s" % required_id)
	mission.queue_free()
	await process_frame


func _test_copy_doc_and_matrix() -> void:
	var copy_doc: String = _read_text(COPY_DOC_PATH)
	_assert(not copy_doc.is_empty(), "TASK_266 copy document exists")
	for token in ["Mission IDs", "Settings IDs", "Multiplayer IDs", "Editor IDs", "Source Rules", "Todo Coverage"]:
		_assert(copy_doc.contains("## %s" % token), "Copy doc has %s section" % token)
	for required_id in REQUIRED_READY_IDS:
		_assert(copy_doc.contains("`%s`" % required_id), "Copy doc references %s" % required_id)
	for todo_id in REQUIRED_TODO_IDS:
		_assert(copy_doc.contains("`%s`" % todo_id), "Copy doc records todo %s" % todo_id)
	var matrix: String = _read_text(MATRIX_PATH)
	for token in ["TASK_266", "`mission.command.*`", "`editor.*`", "`multiplayer.*`", "`settings.fog_of_war.*`"]:
		_assert(matrix.contains(token), "Playability matrix covers %s" % token)


func _test_task_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_266 is marked implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_266 checklist is complete")


func _test_duplicate_ids(entries_by_id: Dictionary, entries: Array) -> void:
	var count_by_id: Dictionary = {}
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var help_id: String = String(entry.get("help_id", ""))
		count_by_id[help_id] = int(count_by_id.get(help_id, 0)) + 1
	for help_id in count_by_id.keys():
		_assert(int(count_by_id.get(help_id, 0)) == 1, "Catalog help_id is unique: %s" % String(help_id))
	_assert(entries_by_id.size() == count_by_id.size(), "Catalog entry map matches unique ID count")


func _entry_text_is_compact(entry: Dictionary) -> bool:
	var title: String = String(entry.get("title", ""))
	if title.is_empty() or title.length() > 48:
		return false
	var compact_lines: Array = Array(entry.get("compact_lines", []))
	if compact_lines.is_empty() or compact_lines.size() > 3:
		return false
	for compact_line in compact_lines:
		var line: String = String(compact_line)
		if line.length() > 96 or line.contains("C:\\Users\\"):
			return false
	for detail_line in Array(entry.get("detail_lines", [])):
		var line: String = String(detail_line)
		if line.length() > 140 or line.contains("C:\\Users\\"):
			return false
	return true


func _build_entries_by_id(catalog: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for entry_variant in Array(catalog.get("entries", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		var help_id: String = String(entry.get("help_id", "")).strip_edges()
		if not help_id.is_empty():
			result[help_id] = entry
	return result


func _collect_help_ids(node: Node) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if node == null:
		return result
	if node.has_meta("help_id"):
		var help_id: String = String(node.get_meta("help_id", "")).strip_edges()
		if not help_id.is_empty() and not result.has(help_id):
			result.append(help_id)
	for child in node.get_children():
		for child_help_id in _collect_help_ids(child):
			if not result.has(child_help_id):
				result.append(child_help_id)
	return result


func _load_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return Dictionary(parsed)
	return {}


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
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
