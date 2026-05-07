extends SceneTree

const SERVICE_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_service.gd")
const POPUP_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_popup.gd")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const MULTIPLAYER_LOBBY_SCENE: PackedScene = preload("res://scenes/ui/multiplayer_lobby.tscn")
const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const HOMEBASE_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const FOB_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const DEBRIEF_SCENE: PackedScene = preload("res://scenes/meta/debrief_test_screen.tscn")
const MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

const CATALOG_PATH: String = "res://data/contextual_help_catalog.json"
const MATRIX_PATH: String = "res://docs/qa/playability_coverage_matrix.md"
const REPORT_PATH: String = "res://docs/reports/contextual_help_coverage_layout_report.md"
const TASK_PATH: String = "res://docs/tasks/TASK_267_contextual_help_coverage_layout_verifier.md"

const REQUIRED_FIELDS: Array = [
	"help_id",
	"screen_id",
	"area_id",
	"status",
	"title",
	"compact_lines",
	"detail_lines",
	"target_audience",
	"manual_review",
]

const REQUIRED_VISIBLE_HELP_IDS: Array = [
	"main_menu.primary_routes",
	"settings.contextual_help_mode",
	"settings.fog_of_war_mode",
	"settings.display",
	"settings.audio",
	"settings.input",
	"settings.gameplay",
	"shell.global_help_button",
	"homebase.roster",
	"homebase.transfer_team",
	"fob.fireteams",
	"fob.flightdeck",
	"loadout.member_row",
	"loadout.armor",
	"loadout.weapon_slot",
	"loadout.weight",
	"loadout.weapon_preview",
	"loadout.weapon_none",
	"loadout.clear_selection",
	"loadout.empty_team_default",
	"mission_hud.command_matrix",
	"mission_hud.mission_control",
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
	"map_editor.height_tool",
	"map_editor.save_load",
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
	"multiplayer_lobby.host_join",
	"multiplayer.host",
	"multiplayer.join",
	"multiplayer.ready",
	"multiplayer.start",
	"multiplayer.disconnect",
	"multiplayer.map_download",
	"multiplayer.roster_ownership",
	"debrief.character_updates",
]

const DOCUMENTED_EXCEPTION_IDS: Array = [
	"editor.back",
]

const REQUIRED_REPORT_SECTIONS: Array = [
	"Summary",
	"Automated Coverage",
	"Text Quality",
	"Layout and Timing",
	"Documented Exceptions",
	"Manual Remainder",
]

var _passed: int = 0
var _failed: int = 0
var _warnings: PackedStringArray = PackedStringArray()


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_267 Contextual Help Coverage Layout Verifier ===")
	var catalog: Dictionary = _load_json(CATALOG_PATH)
	var entries_by_id: Dictionary = _build_entries_by_id(catalog)
	_test_catalog_text_quality(catalog, entries_by_id)
	_test_service_settings_and_timing(entries_by_id)
	await _test_popup_layout_for_catalog(entries_by_id)
	await _test_visible_help_coverage(entries_by_id)
	_test_report_matrix_and_task_status()
	for warning in _warnings:
		print("  WARN: %s" % warning)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_catalog_text_quality(catalog: Dictionary, entries_by_id: Dictionary) -> void:
	_assert(not catalog.is_empty(), "Contextual help catalog parses")
	_assert(Array(catalog.get("allowed_statuses", [])).has("todo"), "Catalog supports documented todo exceptions")
	_assert(entries_by_id.size() >= 120, "Catalog has broad contextual help coverage")
	var seen_ids: Dictionary = {}
	var allowed_statuses: Array = Array(catalog.get("allowed_statuses", []))
	var allowed_audiences: Array = Array(catalog.get("allowed_audiences", []))
	for entry_variant in Array(catalog.get("entries", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		var help_id: String = String(entry.get("help_id", "")).strip_edges()
		_assert(_is_stable_help_id(help_id), "%s uses stable help_id syntax" % help_id)
		_assert(not seen_ids.has(help_id), "%s appears only once" % help_id)
		seen_ids[help_id] = true
		for field in REQUIRED_FIELDS:
			_assert(entry.has(field), "%s has %s" % [help_id, field])
		_assert(String(entry.get("status", "")) in allowed_statuses, "%s has allowed status" % help_id)
		_assert(String(entry.get("target_audience", "")) in allowed_audiences, "%s has allowed audience" % help_id)
		_assert(entry.get("manual_review", null) is bool, "%s has boolean manual_review" % help_id)
		_assert(_entry_text_fits(entry), "%s obeys title/line length limits" % help_id)
		_assert(_entry_has_wrappable_text(entry), "%s text remains wrappable" % help_id)
	for exception_id in DOCUMENTED_EXCEPTION_IDS:
		_assert(entries_by_id.has(exception_id), "Catalog keeps documented exception %s" % exception_id)
		var exception_entry: Dictionary = Dictionary(entries_by_id.get(exception_id, {}))
		_assert(String(exception_entry.get("status", "")) == "todo", "%s is a todo exception" % exception_id)
		_assert(bool(exception_entry.get("manual_review", false)), "%s requires manual review" % exception_id)


func _test_service_settings_and_timing(entries_by_id: Dictionary) -> void:
	var service = SERVICE_SCRIPT.new()
	_assert(int(service.call("load_catalog", CATALOG_PATH)) == OK, "Service loads the contextual help catalog")
	var diagnostic: Dictionary = Dictionary(service.call("get_diagnostic_snapshot"))
	_assert(int(diagnostic.get("entry_count", 0)) == entries_by_id.size(), "Service indexes every catalog entry")
	service.call("set_help_mode", "off")
	var payload: Dictionary = Dictionary(service.call("request_help", "loadout.weight", 4.0, false))
	_assert(String(payload.get("level", "")) == SERVICE_SCRIPT.LEVEL_NONE, "Off mode suppresses help payloads")
	_assert(bool(payload.get("disabled", false)), "Off mode marks requests disabled")
	service.call("set_global_help_active", true)
	_assert(not bool(service.call("is_global_help_active")), "Global help cannot stay active while help is off")
	service.call("set_help_mode", "compact")
	_assert(String(service.call("resolve_help_level", 0.2, false)) == SERVICE_SCRIPT.LEVEL_NONE, "Short hover does not open compact help immediately")
	_assert(String(service.call("resolve_help_level", 0.45, false)) == SERVICE_SCRIPT.LEVEL_COMPACT, "Compact hover opens after configured delay")
	payload = Dictionary(service.call("request_help", "loadout.weight", 4.0, false))
	_assert(String(payload.get("level", "")) == SERVICE_SCRIPT.LEVEL_COMPACT, "Compact mode stays compact after long hover")
	_assert(Array(payload.get("detail_lines", [])).is_empty(), "Compact payload does not include detail lines")
	service.call("set_help_mode", "expanded")
	payload = Dictionary(service.call("request_help", "loadout.weight", 0.45, false))
	_assert(String(payload.get("level", "")) == SERVICE_SCRIPT.LEVEL_COMPACT, "Expanded mode starts with compact help")
	payload = Dictionary(service.call("request_help", "loadout.weight", 3.5, false))
	_assert(String(payload.get("level", "")) == SERVICE_SCRIPT.LEVEL_DETAIL, "Expanded mode reaches detail after long hover")
	_assert(not Array(payload.get("detail_lines", [])).is_empty(), "Detail payload includes detail lines")
	payload = Dictionary(service.call("request_help", "loadout.weight", 0.0, true))
	_assert(String(payload.get("level", "")) == SERVICE_SCRIPT.LEVEL_DETAIL, "Pinned help opens detail immediately")
	service.call("set_global_help_active", true)
	_assert(String(service.call("resolve_help_level", 0.0, false)) == SERVICE_SCRIPT.LEVEL_COMPACT, "Global help opens compact help without hover delay")


func _test_popup_layout_for_catalog(entries_by_id: Dictionary) -> void:
	var service = SERVICE_SCRIPT.new()
	service.call("load_catalog", CATALOG_PATH)
	service.call("set_help_mode", "expanded")
	var popup: Control = POPUP_SCRIPT.new()
	root.add_child(popup)
	await process_frame
	var viewport: Vector2 = Vector2(1920.0, 1080.0)
	var sample_targets: Array = [
		Rect2(24.0, 24.0, 44.0, 44.0),
		Rect2(1848.0, 24.0, 44.0, 44.0),
		Rect2(24.0, 1008.0, 44.0, 44.0),
		Rect2(1848.0, 1008.0, 44.0, 44.0),
		Rect2(900.0, 512.0, 80.0, 48.0),
	]
	var ids: Array = entries_by_id.keys()
	ids.sort()
	for help_id_variant in ids:
		var help_id: String = String(help_id_variant)
		var compact_payload: Dictionary = Dictionary(service.call("get_help_payload", help_id, false))
		var detail_payload: Dictionary = Dictionary(service.call("get_help_payload", help_id, true))
		_assert(not compact_payload.is_empty(), "%s builds compact popup payload" % help_id)
		_assert(not detail_payload.is_empty(), "%s builds detail-capable popup payload" % help_id)
		for target_variant in sample_targets:
			var target_rect: Rect2 = target_variant
			_show_and_assert_popup_rect(popup, compact_payload, target_rect, viewport, false, "%s compact" % help_id)
			_show_and_assert_popup_rect(popup, detail_payload, target_rect, viewport, true, "%s detail" % help_id)
	var snapshot: Dictionary = Dictionary(popup.call("get_diagnostic_snapshot"))
	_assert(int(snapshot.get("title_autowrap", 0)) == TextServer.AUTOWRAP_WORD_SMART, "Popup title wraps")
	_assert(int(snapshot.get("compact_autowrap", 0)) == TextServer.AUTOWRAP_WORD_SMART, "Popup compact text wraps")
	_assert(int(snapshot.get("detail_autowrap", 0)) == TextServer.AUTOWRAP_WORD_SMART, "Popup detail text wraps")
	popup.call("hide_help")
	_assert(not popup.visible, "Popup can hide cleanly after layout pass")
	popup.queue_free()
	await process_frame


func _show_and_assert_popup_rect(popup: Control, payload: Dictionary, target_rect: Rect2, viewport: Vector2, detail: bool, label: String) -> void:
	popup.call("show_help", payload, target_rect, viewport, detail)
	var popup_rect := Rect2(popup.position, popup.size)
	var max_width: float = float(SERVICE_SCRIPT.DEFAULT_DETAIL_MAX_WIDTH_PX if detail else SERVICE_SCRIPT.DEFAULT_COMPACT_MAX_WIDTH_PX)
	var max_height: float = viewport.y * SERVICE_SCRIPT.DEFAULT_MAX_VIEWPORT_HEIGHT_RATIO
	_assert(bool(popup.visible), "%s popup is visible" % label)
	_assert(_rect_inside_viewport(popup_rect, viewport), "%s popup stays inside viewport" % label)
	_assert(popup.size.x <= max_width, "%s popup respects max width" % label)
	_assert(popup.size.y <= max_height, "%s popup respects max height" % label)
	_assert(not popup_rect.intersects(target_rect), "%s popup avoids target when there is room" % label)


func _test_visible_help_coverage(entries_by_id: Dictionary) -> void:
	root.size = Vector2i(1920, 1080)
	var collected_ids: Dictionary = {}
	await _collect_main_menu_ids(collected_ids)
	await _collect_lobby_ids(collected_ids)
	await _collect_editor_ids(collected_ids)
	await _collect_homebase_ids(collected_ids)
	await _collect_fob_ids(collected_ids)
	await _collect_debrief_ids(collected_ids)
	await _collect_mission_ids(collected_ids)
	for help_id in collected_ids.keys():
		_assert(entries_by_id.has(String(help_id)), "Visible help_id has catalog entry: %s" % String(help_id))
	for required_id in REQUIRED_VISIBLE_HELP_IDS:
		_assert(collected_ids.has(required_id), "Required visible control carries %s" % required_id)
	for exception_id in DOCUMENTED_EXCEPTION_IDS:
		_assert(not collected_ids.has(exception_id), "%s remains a documented non-visible exception" % exception_id)
	var unused_ready_ids: PackedStringArray = PackedStringArray()
	for help_id in entries_by_id.keys():
		var id_text: String = String(help_id)
		var entry: Dictionary = Dictionary(entries_by_id.get(id_text, {}))
		if String(entry.get("status", "")) == "ready" and not collected_ids.has(id_text):
			unused_ready_ids.append(id_text)
	if unused_ready_ids.size() > 0:
		unused_ready_ids.sort()
		_warnings.append("Ready catalog IDs not seen in current fixture scenes: %s" % ", ".join(unused_ready_ids))


func _collect_main_menu_ids(collected_ids: Dictionary) -> void:
	var menu := MAIN_MENU_SCENE.instantiate()
	root.add_child(menu)
	await _wait_frames(2)
	_record_help_ids(menu, collected_ids)
	var global_button := menu.get_node_or_null("GlobalHelpButton") as Button
	_assert(global_button != null and global_button.visible, "Global help button is visible on main menu")
	if global_button != null:
		menu.call("set_contextual_help_mode", "expanded")
		await process_frame
		global_button.pressed.emit()
		await process_frame
		var snapshot: Dictionary = Dictionary(menu.call("get_contextual_help_snapshot"))
		var popup_snapshot: Dictionary = Dictionary(snapshot.get("popup", {}))
		_assert(bool(popup_snapshot.get("visible", false)), "Global help button opens a popup")
		_assert(String(popup_snapshot.get("help_id", "")) == "shell.global_help_button", "Global help popup uses shell help ID")
		menu.call("set_contextual_help_mode", "off")
		await process_frame
		snapshot = Dictionary(menu.call("get_contextual_help_snapshot"))
		var service_snapshot: Dictionary = Dictionary(snapshot.get("service", {}))
		_assert(not bool(service_snapshot.get("help_enabled", true)), "Main menu off setting disables help service")
	menu.queue_free()
	await process_frame


func _collect_lobby_ids(collected_ids: Dictionary) -> void:
	var lobby := MULTIPLAYER_LOBBY_SCENE.instantiate()
	root.add_child(lobby)
	await _wait_frames(2)
	_record_help_ids(lobby, collected_ids)
	lobby.queue_free()
	await process_frame


func _collect_editor_ids(collected_ids: Dictionary) -> void:
	var editor := MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(5)
	_record_help_ids(editor, collected_ids)
	editor.queue_free()
	await process_frame


func _collect_homebase_ids(collected_ids: Dictionary) -> void:
	var homebase := HOMEBASE_SCENE.instantiate()
	root.add_child(homebase)
	await _wait_frames(4)
	_record_help_ids(homebase, collected_ids)
	homebase.queue_free()
	await process_frame


func _collect_fob_ids(collected_ids: Dictionary) -> void:
	var fob: Control = FOB_SCENE.instantiate()
	root.add_child(fob)
	await _wait_frames(2)
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	fob.call("set_available_units", roster)
	fob.call("configure_transfer", PackedStringArray(["unit_alpha", "unit_bravo"]), PackedStringArray(["ft1", "ft1"]), [])
	fob.call("_on_staging_fireteam_dropped", "ft1", "loadout")
	fob.call("_set_member_loadout", "ft1", "unit_alpha", "heavy", "rocket_launcher", "none")
	await _wait_frames(4)
	_record_help_ids(fob, collected_ids)
	fob.queue_free()
	await process_frame


func _collect_debrief_ids(collected_ids: Dictionary) -> void:
	var debrief := DEBRIEF_SCENE.instantiate()
	root.add_child(debrief)
	await process_frame
	debrief.call("set_mission_result", {
		"result": "victory",
		"mission_outcome": "success",
		"winning_team_id": "team_alpha",
		"duration_seconds": 92.0,
		"character_events": [
			{"summary_text": "Anja gained mission XP."},
			{"summary_text": "Darius morale improved."},
		],
	})
	await _wait_frames(2)
	_record_help_ids(debrief, collected_ids)
	debrief.queue_free()
	await process_frame


func _collect_mission_ids(collected_ids: Dictionary) -> void:
	var mission := MISSION_SCENE.instantiate()
	root.add_child(mission)
	await _wait_frames(6)
	_record_help_ids(mission, collected_ids)
	mission.queue_free()
	await process_frame


func _test_report_matrix_and_task_status() -> void:
	var report: String = _read_text(REPORT_PATH)
	_assert(not report.is_empty(), "TASK_267 coverage/layout report exists")
	for section in REQUIRED_REPORT_SECTIONS:
		_assert(report.contains("## %s" % section), "Report has %s section" % section)
	for token in ["TASK_267", "editor.back", "mission.command.roe_fire_rules", "unused", "global help"]:
		_assert(report.to_lower().contains(token.to_lower()), "Report records %s" % token)
	var matrix: String = _read_text(MATRIX_PATH)
	_assert(matrix.contains("TASK_267"), "Playability matrix references TASK_267")
	_assert(matrix.contains("help_coverage_layout_gate"), "Matrix tracks contextual help coverage/layout gate")
	var task_text: String = _read_text(TASK_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_267 is marked implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_267 checklist is complete")


func _entry_text_fits(entry: Dictionary) -> bool:
	var title: String = String(entry.get("title", "")).strip_edges()
	if title.is_empty() or title.length() > 48:
		return false
	var compact_lines: Array = Array(entry.get("compact_lines", []))
	if compact_lines.is_empty() or compact_lines.size() > 3:
		return false
	for compact_line in compact_lines:
		var line: String = String(compact_line).strip_edges()
		if line.is_empty() or line.length() > 96 or line.contains("C:\\Users\\"):
			return false
	for detail_line in Array(entry.get("detail_lines", [])):
		var line: String = String(detail_line).strip_edges()
		if line.length() > 140 or line.contains("C:\\Users\\"):
			return false
	return true


func _entry_has_wrappable_text(entry: Dictionary) -> bool:
	var lines: Array = [String(entry.get("title", ""))]
	lines.append_array(Array(entry.get("compact_lines", [])))
	lines.append_array(Array(entry.get("detail_lines", [])))
	for line_variant in lines:
		for token_variant in String(line_variant).split(" ", false):
			var token: String = String(token_variant).strip_edges()
			if token.length() > 54:
				return false
	return true


func _record_help_ids(node: Node, collected_ids: Dictionary) -> void:
	if node == null:
		return
	if node.has_meta("help_id"):
		var help_id: String = String(node.get_meta("help_id", "")).strip_edges()
		if not help_id.is_empty():
			collected_ids[help_id] = true
	for child in node.get_children():
		_record_help_ids(child, collected_ids)


func _rect_inside_viewport(rect: Rect2, viewport: Vector2) -> bool:
	return rect.position.x >= 0.0 \
		and rect.position.y >= 0.0 \
		and rect.end.x <= viewport.x \
		and rect.end.y <= viewport.y


func _build_entries_by_id(catalog: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for entry_variant in Array(catalog.get("entries", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		var help_id: String = String(entry.get("help_id", "")).strip_edges()
		if not help_id.is_empty():
			result[help_id] = entry
	return result


func _is_stable_help_id(value: String) -> bool:
	if value.is_empty() or value.begins_with(".") or value.ends_with("."):
		return false
	for character_index in range(value.length()):
		var code: int = value.unicode_at(character_index)
		var is_lower: bool = code >= 97 and code <= 122
		var is_number: bool = code >= 48 and code <= 57
		var is_separator: bool = code == 46 or code == 95
		if not (is_lower or is_number or is_separator):
			return false
	return value.find("..") < 0


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
	var text: String = file.get_as_text()
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
