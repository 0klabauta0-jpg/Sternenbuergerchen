extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_286_ui_feedback_truth_regression_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reviews/ui_feedback_truth_regression_review.md"

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const HELP_SERVICE_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_service.gd")
const HELP_POPUP_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_popup.gd")
const COMIC_BUBBLE_RUNTIME_GATE_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_runtime_gate.gd")
const COMIC_BUBBLE_SETTINGS_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_settings.gd")

const FORBIDDEN_UI_MUTATION_TOKENS: PackedStringArray = [
	"enqueue_command",
	"enqueue_effect",
	"submit_network_command_for_peer",
	"request_command(",
	"apply_multiplayer_snapshot",
	"set_multiplayer_snapshot_context",
	"set_runtime_status",
	"apply_remote_vital_update",
	"set_vital_state",
	"apply_damage(",
	"take_damage(",
]

const UI_BOUNDARY_SCAN_ROOTS: PackedStringArray = [
	"res://scripts/ui",
	"res://scripts/meta",
	"res://scripts/editor",
	"res://scripts/tactical/visuals",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_286 UI Feedback Truth Regression Review ===")
	_test_docs_report_and_status()
	_test_static_ui_meta_editor_visualizer_boundaries()
	await _test_mission_feedback_snapshots_do_not_mutate_simulation_root()
	await _test_map_feedback_render_filters_visual_only_payloads()
	await _test_help_and_bubble_runtime_state_have_no_simulation_side_effects()
	_test_character_loadout_and_editor_display_boundaries()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs_report_and_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_286 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("### TASK_286 - UI Feedback Truth Regression Review") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_286 implemented")
	_assert(roadmap_text.contains("TASK_286 - UI Feedback Truth Regression Review (implementiert)"), "Roadmap marks TASK_286 implemented")
	for token in [
		"## Findings",
		"Blocker",
		"Important",
		"Cleanup",
		"stale UI",
		"duplicate",
		"missing",
		"direct",
		"disabled",
		"visual_only",
		"Selection",
		"Loadout",
		"Editor",
	]:
		_assert(report_text.to_lower().contains(String(token).to_lower()), "Review report contains %s" % token)


func _test_static_ui_meta_editor_visualizer_boundaries() -> void:
	var offenders: PackedStringArray = PackedStringArray()
	for root_path in UI_BOUNDARY_SCAN_ROOTS:
		for file_path in _collect_gd_files(root_path):
			var lines: PackedStringArray = _read_text(file_path).split("\n")
			for index in range(lines.size()):
				var line: String = String(lines[index])
				for token in FORBIDDEN_UI_MUTATION_TOKENS:
					if line.contains(token):
						offenders.append("%s:%d contains %s" % [file_path, index + 1, token])
	_assert(offenders.is_empty(), "UI/meta/editor/visualizer layers contain no direct authoritative mutation calls: %s" % "; ".join(offenders))

	var terrain_view_text: String = _read_text("res://scripts/terrain/terrain_map_3d_view.gd")
	for token in ["enqueue_command", "enqueue_effect", "set_runtime_status", "apply_damage(", "apply_multiplayer_snapshot"]:
		_assert(not terrain_view_text.contains(token), "TerrainMap3DView render path does not contain %s" % token)

	var hierarchy_text: String = _read_text("res://scripts/ui/mission_command_hierarchy_contract.gd")
	_assert(hierarchy_text.contains("const VISUAL_ONLY: bool = true"), "Mission command hierarchy pins visual-only state")
	_assert(hierarchy_text.contains("const UI_SETS_GAMEPLAY_TRUTH: bool = false"), "Mission command hierarchy pins UI as non-authority")


func _test_mission_feedback_snapshots_do_not_mutate_simulation_root() -> void:
	root.size = Vector2i(1920, 1080)
	var scene = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(12)
	var controller: Node = scene.get_node("TacticalController")
	var primary_view: Node = scene.get_node("Primary3DView")
	var simulation_root: Node = scene.get_node("SimulationRoot")
	var command_count_before: int = simulation_root.command_queue.size()
	var effect_count_before: int = simulation_root.effects_queue.size()

	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	await _wait_frames(6)
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var hierarchy: Dictionary = Dictionary(feedback.get("command_hierarchy", {}))
	var map_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(_same_string_set(Array(feedback.get("selected_fireteam_ids", [])), ["blue", "gold"]), "#17/#18 feedback snapshot mirrors the selected fireteams")
	_assert(_same_string_set(Array(map_snapshot.get("order_selected_fireteam_ids", [])), Array(feedback.get("selected_fireteam_ids", []))), "2.5D map mirrors the same selection snapshot")
	_assert(bool(hierarchy.get("visual_only", false)), "Command hierarchy snapshot is visual-only")
	_assert(not bool(hierarchy.get("ui_sets_gameplay_truth", true)), "Command hierarchy snapshot says UI does not set gameplay truth")
	_assert(int(hierarchy.get("selected_fireteam_count", 0)) == 2 and bool(hierarchy.get("multi_fireteam_context", false)), "Hierarchy context uses the same multi-selection")
	_assert(_all_hierarchy_actions_are_visual_only(Dictionary(hierarchy.get("actions_by_id", {}))), "All hierarchy actions carry visual-only/non-authority metadata")
	_assert(_disabled_actions_have_reasons(Dictionary(hierarchy.get("actions_by_id", {}))), "Disabled hierarchy actions expose a reason")
	_assert(simulation_root.command_queue.size() == command_count_before, "Selection and feedback refresh enqueue no SimulationRoot commands")
	_assert(simulation_root.effects_queue.size() == effect_count_before, "Selection and feedback refresh enqueue no SimulationRoot effects")

	controller.call("_set_selected_fireteams", PackedStringArray(), false)
	await _wait_frames(4)
	var empty_hierarchy: Dictionary = Dictionary(controller.call("get_command_hierarchy_snapshot"))
	var empty_actions: Dictionary = Dictionary(empty_hierarchy.get("actions_by_id", {}))
	_assert(String(Dictionary(empty_actions.get("move", {})).get("disabled_reason", "")).contains("select"), "No-selection Move disabled reason is specific")
	scene.queue_free()
	await _wait_frames(2)


func _test_map_feedback_render_filters_visual_only_payloads() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task286_feedback_truth", Vector2i(6, 6), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	var valid_bubble: Dictionary = {
		"display_type": "comic_bubble",
		"bubble_id": "task286_valid",
		"text": "Copy",
		"anchor_position": Vector2(128.0, 128.0),
		"visual_only": true,
		"source": "fireteamleader_command_feedback",
		"fireteam_id": "blue",
		"unit_id": "unit_alpha",
	}
	var non_visual_bubble: Dictionary = valid_bubble.duplicate(true)
	non_visual_bubble["bubble_id"] = "task286_non_visual"
	non_visual_bubble["visual_only"] = false
	var wrong_type_bubble: Dictionary = valid_bubble.duplicate(true)
	wrong_type_bubble["bubble_id"] = "task286_wrong_type"
	wrong_type_bubble["display_type"] = "status_label"
	var valid_event: Dictionary = {
		"event_id": "task286_event",
		"event_type": "order_received",
		"fireteam_id": "blue",
		"channels": PackedStringArray(["map_marker"]),
		"anchor_position": Vector2(192.0, 128.0),
		"map_label": "COPY",
		"short_text": "Copy",
		"priority": 80,
		"visual_only": true,
	}
	var non_visual_event: Dictionary = valid_event.duplicate(true)
	non_visual_event["event_id"] = "task286_event_non_visual"
	non_visual_event["visual_only"] = false
	var wrong_channel_event: Dictionary = valid_event.duplicate(true)
	wrong_channel_event["event_id"] = "task286_event_wrong_channel"
	wrong_channel_event["channels"] = PackedStringArray(["selected_fireteam"])
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"feedback_bubble_dicts": [non_visual_bubble, wrong_type_bubble, valid_bubble],
		"tactical_communication_event_dicts": [non_visual_event, wrong_channel_event, valid_event],
	})
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(snapshot.get("feedback_bubble_visual_count", 0)) == 1, "3D map renders only visual-only comic bubble payloads")
	_assert(int(snapshot.get("tactical_communication_event_visual_count", 0)) == 1, "3D map renders only visual-only map-marker communication events")
	var bubble_entries: Array = Array(snapshot.get("feedback_bubble_entries", []))
	var event_entries: Array = Array(snapshot.get("tactical_communication_event_entries", []))
	_assert(bubble_entries.size() == 1 and String(Dictionary(bubble_entries[0]).get("bubble_id", "")) == "task286_valid", "Bubble render snapshot keeps only the accepted visual payload")
	_assert(event_entries.size() == 1 and String(Dictionary(event_entries[0]).get("event_id", "")) == "task286_event", "Communication render snapshot keeps only the accepted visual event")
	primary_view.queue_free()
	await _wait_frames(2)


func _test_help_and_bubble_runtime_state_have_no_simulation_side_effects() -> void:
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	root.add_child(simulation_root)
	var command_count_before: int = simulation_root.command_queue.size()
	var effect_count_before: int = simulation_root.effects_queue.size()

	var service = HELP_SERVICE_SCRIPT.new()
	var load_error: Error = service.call("load_catalog")
	_assert(load_error == OK, "ContextualHelpService loads help catalog")
	service.call("set_help_mode", "expanded")
	service.call("set_global_help_active", true)
	var help_payload: Dictionary = Dictionary(service.call("request_help", "mission.command.call_dropship", 4.0, true))
	_assert(String(help_payload.get("help_id", "")) == "mission.command.call_dropship", "Help payload resolves mission command help without runtime dependency")
	var popup = HELP_POPUP_SCRIPT.new()
	root.add_child(popup)
	popup.call("show_help", help_payload, Rect2(Vector2(160.0, 160.0), Vector2(64.0, 48.0)), Vector2(1920.0, 1080.0), true)
	popup.call("hide_help")

	var gate = COMIC_BUBBLE_RUNTIME_GATE_SCRIPT.new()
	gate.call("set_settings", {"mode": "normal", "command_feedback_cooldown_msec": 1000})
	var bubble_payload: Dictionary = {
		"display_type": "comic_bubble",
		"bubble_id": "task286_gate",
		"text": "Copy",
		"anchor_position": Vector2(96.0, 128.0),
		"visual_only": true,
		"source": "fireteamleader_command_feedback",
		"feedback_action": "move",
		"feedback_state": "accepted",
		"fireteam_id": "blue",
		"unit_id": "unit_alpha",
	}
	_assert(bool(gate.call("should_emit_payload", bubble_payload, COMIC_BUBBLE_SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 1000)), "Bubble runtime gate allows first visual payload")
	_assert(not bool(gate.call("should_emit_payload", bubble_payload, COMIC_BUBBLE_SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK, 1200)), "Bubble runtime gate cooldown blocks duplicate visual payload")
	var gate_snapshot: Dictionary = Dictionary(gate.call("get_snapshot"))
	_assert(Array(gate_snapshot.get("cooldown_keys", [])).size() == 1, "Bubble runtime gate stores only cooldown presentation state")
	_assert(simulation_root.command_queue.size() == command_count_before, "Help and bubble runtime gate enqueue no SimulationRoot commands")
	_assert(simulation_root.effects_queue.size() == effect_count_before, "Help and bubble runtime gate enqueue no SimulationRoot effects")

	popup.queue_free()
	simulation_root.queue_free()
	await _wait_frames(2)


func _test_character_loadout_and_editor_display_boundaries() -> void:
	var fob_text: String = _read_text("res://scripts/meta/fob_screen.gd")
	var character_formatter_text: String = _read_text("res://scripts/meta/character_sheet_formatter.gd")
	var editor_text: String = _read_text("res://scripts/editor/map_editor.gd")
	_assert(fob_text.contains("_calculate_fireteam_loadout_weight") and fob_text.contains("LOADOUT_MODIFIER_RESOLVER_SCRIPT"), "FOB loadout weight display derives from LoadoutModifierResolver")
	_assert(character_formatter_text.contains("combat_effect_summary_text"), "Character sheet formats combat/loadout effects as profile text")
	for token in FORBIDDEN_UI_MUTATION_TOKENS:
		_assert(not fob_text.contains(token), "FOB screen does not contain %s" % token)
		_assert(not character_formatter_text.contains(token), "Character sheet formatter does not contain %s" % token)
		_assert(not editor_text.contains(token), "Map editor display path does not contain %s" % token)


func _all_hierarchy_actions_are_visual_only(actions_by_id: Dictionary) -> bool:
	if actions_by_id.is_empty():
		return false
	for action_id_variant in actions_by_id.keys():
		var action: Dictionary = Dictionary(actions_by_id[action_id_variant])
		if not bool(action.get("visual_only", false)):
			return false
		if bool(action.get("ui_sets_gameplay_truth", true)):
			return false
	return true


func _disabled_actions_have_reasons(actions_by_id: Dictionary) -> bool:
	if actions_by_id.is_empty():
		return false
	for action_id_variant in actions_by_id.keys():
		var action: Dictionary = Dictionary(actions_by_id[action_id_variant])
		if bool(action.get("disabled", false)) and String(action.get("disabled_reason", "")).strip_edges().is_empty():
			return false
	return true


func _same_string_set(left: Array, right: Array) -> bool:
	var left_values: PackedStringArray = _to_lower_sorted_strings(left)
	var right_values: PackedStringArray = _to_lower_sorted_strings(right)
	if left_values.size() != right_values.size():
		return false
	for index in range(left_values.size()):
		if left_values[index] != right_values[index]:
			return false
	return true


func _to_lower_sorted_strings(values: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for value_variant in values:
		var value: String = String(value_variant).strip_edges().to_lower()
		if not value.is_empty():
			result.append(value)
	result.sort()
	return result


func _collect_gd_files(root_path: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var directory := DirAccess.open(root_path)
	if directory == null:
		return result
	directory.list_dir_begin()
	var file_name: String = directory.get_next()
	while not file_name.is_empty():
		var child_path: String = root_path.path_join(file_name)
		if directory.current_is_dir():
			for nested_path in _collect_gd_files(child_path):
				result.append(nested_path)
		elif file_name.ends_with(".gd"):
			result.append(child_path)
		file_name = directory.get_next()
	directory.list_dir_end()
	return result


func _read_text(path: String) -> String:
	if path.is_empty() or not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
