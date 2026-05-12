extends SceneTree

const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_337_architecture_performance_ux_followup_gate.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const ARCHITECTURE_PATH: String = "res://docs/ARCHITECTURE.md"
const CODEX_RULES_PATH: String = "res://docs/CODEX_RULES.md"
const REPORT_PATH: String = "res://docs/reports/architecture_performance_ux_followup_gate.md"
const MANUAL_CHECKLIST_PATH: String = "res://docs/manual_checks/architecture_performance_ux_followup_checklist.md"
const BUDGET_CONTRACT_PATH: String = "res://data/performance_budget_contract.json"
const MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const CONTRACT_PATH: String = "res://scripts/ui/mission_command_hierarchy_contract.gd"
const FEEDBACK_ADAPTER_PATH: String = "res://scripts/mission/mission_command_feedback_snapshot_adapter.gd"
const TACTICAL_CONTROLLER_PATH: String = "res://scripts/mission/mission_tactical_sandbox_controller.gd"
const COMBAT_DRIVER_PATH: String = "res://scripts/mission/mission_combat_loop_driver.gd"

const PREREQ_TASKS: Array = [
	{
		"id": "TASK_330",
		"title": "Mission Runtime Scripts Productization Followup",
		"task": "res://docs/tasks/TASK_330_mission_runtime_scripts_productization_followup.md",
		"report": "res://docs/reports/mission_runtime_scripts_productization_followup.md",
		"test": "",
	},
	{
		"id": "TASK_331",
		"title": "Mission Tactical Controller Adapter Split First Slice",
		"task": "res://docs/tasks/TASK_331_mission_tactical_controller_adapter_split_first_slice.md",
		"report": "res://docs/reports/mission_tactical_controller_adapter_split_first_slice.md",
		"test": "res://scripts/tests/task_331_mission_tactical_controller_adapter_split_first_slice.gd",
	},
	{
		"id": "TASK_332",
		"title": "Terrain Map Frame Budget Proxy Sync Pass",
		"task": "res://docs/tasks/TASK_332_terrain_map_frame_budget_proxy_sync_pass.md",
		"report": "res://docs/reports/terrain_map_frame_budget_proxy_sync_pass.md",
		"test": "res://scripts/tests/task_332_terrain_map_frame_budget_proxy_sync_pass.gd",
	},
	{
		"id": "TASK_333",
		"title": "Navigation Fallback Budget Contract Alignment",
		"task": "res://docs/tasks/TASK_333_navigation_fallback_budget_contract_alignment.md",
		"report": "res://docs/reports/navigation_fallback_budget_contract_alignment.md",
		"test": "res://scripts/tests/task_333_navigation_fallback_budget_contract_alignment.gd",
	},
	{
		"id": "TASK_334",
		"title": "Drop Light Layout Profiles Compact Resolution",
		"task": "res://docs/tasks/TASK_334_drop_light_layout_profiles_compact_resolution.md",
		"report": "res://docs/reports/drop_light_layout_profiles_compact_resolution.md",
		"test": "res://scripts/tests/task_334_drop_light_layout_profiles_compact_resolution.gd",
	},
	{
		"id": "TASK_335",
		"title": "Tactical Feedback Truth Command Clarity Pass",
		"task": "res://docs/tasks/TASK_335_tactical_feedback_truth_command_clarity_pass.md",
		"report": "res://docs/reports/tactical_feedback_truth_command_clarity_pass.md",
		"test": "res://scripts/tests/task_335_tactical_feedback_truth_command_clarity_pass.gd",
	},
	{
		"id": "TASK_336",
		"title": "Combat Loop Tick Budget System Split",
		"task": "res://docs/tasks/TASK_336_combat_loop_tick_budget_system_split.md",
		"report": "res://docs/reports/combat_loop_tick_budget_system_split.md",
		"test": "res://scripts/tests/task_336_combat_loop_tick_budget_system_split.gd",
	},
]

const REQUIRED_GATE_SCRIPTS: Array = [
	"res://scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd",
	"res://scripts/tests/task_282_tactical_overhaul_playability_performance_help_gate.gd",
	"res://scripts/tests/task_286_ui_feedback_truth_regression_review.gd",
]

const PRODUCTIVE_MISSION_SCRIPTS: PackedStringArray = [
	"res://scripts/mission/mission_test_setup.gd",
	"res://scripts/mission/mission_command_flow_driver.gd",
	"res://scripts/mission/mission_combat_loop_driver.gd",
	"res://scripts/mission/mission_tactical_sandbox_controller.gd",
	"res://scripts/mission/mission_objective_status_view.gd",
	"res://scripts/mission/mission_respawn_overlay.gd",
	"res://scripts/mission/enemy_wave_controller.gd",
	"res://scripts/mission/phase_controller.gd",
]

const RUNTIME_TEST_PATH_TOKENS: PackedStringArray = [
	"res://scripts/tests/mission_tactical_sandbox_controller.gd",
	"res://scripts/tests/mission_combat_loop_driver.gd",
	"res://scripts/tests/mission_test_setup.gd",
	"res://scripts/tests/mission_command_flow_driver.gd",
	"res://scripts/tests/mission_map_camera_controller.gd",
	"res://scripts/tests/mission_objective_status_view.gd",
	"res://scripts/tests/mission_respawn_overlay.gd",
	"res://scripts/tests/enemy_wave_controller.gd",
	"res://scripts/tests/phase_controller.gd",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_337 Architecture Performance UX Followup Gate ===")
	_test_task_docs_status_and_reports()
	_test_prerequisite_series_artifacts()
	_test_architecture_boundary_contract()
	_test_performance_budget_and_reports()
	_test_manual_checklist_contract()
	await _test_live_fullhd_and_compact_command_feedback_smoke()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_task_docs_status_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_337 task file marks implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_337 task checklist is complete")
	_assert(status_text.contains("### TASK_337 - Architecture Performance UX Followup Gate") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_337 implemented")
	_assert(roadmap_text.contains("TASK_337 - Architecture Performance UX Followup Gate (implementiert"), "Roadmap marks TASK_337 implemented")
	_assert(FileAccess.file_exists(REPORT_PATH), "TASK_337 closure report exists")
	_assert(FileAccess.file_exists(MANUAL_CHECKLIST_PATH), "TASK_337 manual checklist exists")
	for token in ["TASK_330", "TASK_331", "TASK_332", "TASK_333", "TASK_334", "TASK_335", "TASK_336", "Architektur", "Performance", "UI", "Findings"]:
		_assert(report_text.contains(token), "Closure report covers %s" % token)


func _test_prerequisite_series_artifacts() -> void:
	for task_variant in PREREQ_TASKS:
		var task: Dictionary = Dictionary(task_variant)
		var task_id: String = String(task.get("id", ""))
		var task_path: String = String(task.get("task", ""))
		var report_path: String = String(task.get("report", ""))
		var test_path: String = String(task.get("test", ""))
		var task_text: String = _read_text(task_path)
		_assert(FileAccess.file_exists(task_path), "%s task document exists" % task_id)
		_assert(task_text.contains("## Status: IMPLEMENTIERT"), "%s task document marks implemented" % task_id)
		_assert(not task_text.contains("- [ ]"), "%s task checklist has no unchecked item" % task_id)
		_assert(FileAccess.file_exists(report_path), "%s report exists" % task_id)
		_assert(_read_text(report_path).strip_edges().length() > 200, "%s report has substantive content" % task_id)
		if not test_path.is_empty():
			_assert(FileAccess.file_exists(test_path), "%s verifier exists" % task_id)
	for script_path in REQUIRED_GATE_SCRIPTS:
		_assert(FileAccess.file_exists(script_path), "Required followup gate script exists: %s" % script_path.get_file())


func _test_architecture_boundary_contract() -> void:
	var architecture_text: String = _read_text(ARCHITECTURE_PATH)
	var codex_rules_text: String = _read_text(CODEX_RULES_PATH)
	for token in ["Gameplay-Wahrheit liegt nicht im UI", "State-Mutationen laufen zentral", "SimulationRoot", "EventRouter", "UpdateManager"]:
		_assert(architecture_text.contains(token), "Architecture document keeps boundary token %s" % token)
	for token in ["UI ist Anzeige", "State-Mutationen nur", "SimulationRoot", "Keine versteckte Logik"]:
		_assert(codex_rules_text.contains(token), "Codex rules keep boundary token %s" % token)

	var scene_text: String = _read_text(MISSION_SCENE_PATH)
	for script_path in PRODUCTIVE_MISSION_SCRIPTS:
		_assert(scene_text.contains(script_path), "Mission scene references productive runtime script %s" % script_path.get_file())
	for forbidden_token in RUNTIME_TEST_PATH_TOKENS:
		_assert(not scene_text.contains(forbidden_token), "Mission scene no longer references productive runtime test path %s" % forbidden_token.get_file())

	var forbidden_refs: Array = _find_forbidden_runtime_test_refs(["res://scenes", "res://scripts/mission", "res://scripts/core", "res://scripts/ui"])
	_assert(forbidden_refs.is_empty(), "Productive scene/core/mission/ui paths contain no stale productive scripts/tests runtime refs")
	if not forbidden_refs.is_empty():
		for ref in forbidden_refs:
			print("  stale runtime test ref: %s" % String(ref))

	var contract_text: String = _read_text(CONTRACT_PATH)
	var adapter_text: String = _read_text(FEEDBACK_ADAPTER_PATH)
	var controller_text: String = _read_text(TACTICAL_CONTROLLER_PATH)
	var combat_driver_text: String = _read_text(COMBAT_DRIVER_PATH)
	_assert(contract_text.contains("UI_SETS_GAMEPLAY_TRUTH: bool = false"), "Command hierarchy declares UI truth boundary")
	_assert(contract_text.contains("visual_only"), "Command hierarchy exposes visual-only contract")
	_assert(adapter_text.contains("\"command_clarity\""), "Feedback adapter includes command clarity snapshot")
	_assert(controller_text.contains("_command_feedback_adapter.call(\"build_snapshot\""), "Tactical controller delegates feedback snapshot assembly")
	_assert(combat_driver_text.contains("COMBAT_TICK_PHASE_ORDER"), "Combat loop keeps explicit phase order")
	_assert(combat_driver_text.contains("phase_records"), "Combat loop exposes phase records")
	_assert(combat_driver_text.contains("SimulationRoot"), "Combat loop keeps SimulationRoot authority visible")
	for token in ["enqueue_command", "enqueue_effect", "set_runtime_status", "assign_unit_command", "apply_damage(", "take_damage("]:
		_assert(not adapter_text.contains(token), "Feedback adapter contains no gameplay mutation token %s" % token)


func _test_performance_budget_and_reports() -> void:
	var contract: Dictionary = _read_json(BUDGET_CONTRACT_PATH)
	var project_budget: Dictionary = Dictionary(contract.get("project_budget", {}))
	for section in ["render", "navigation", "simulation", "ui", "assets", "snapshot"]:
		_assert(project_budget.has(section), "Performance budget contract keeps %s section" % section)
	var navigation_budget: Dictionary = Dictionary(project_budget.get("navigation", {}))
	_assert(int(navigation_budget.get("max_path_query_budget_per_tick", -1)) == 1, "Navigation query budget remains aligned at one new query per tick")
	_assert(int(navigation_budget.get("max_fallback_path_attempts_per_request", -1)) == 1, "Navigation fallback path-attempt budget remains one per request")
	_assert(bool(navigation_budget.get("require_fallback_diagnostics", false)), "Navigation budget requires fallback diagnostics")
	var simulation_budget: Dictionary = Dictionary(project_budget.get("simulation", {}))
	_assert(bool(simulation_budget.get("require_scope_timings", false)), "Simulation budget still requires scope timings")
	_assert(bool(simulation_budget.get("require_hotpath_audit", false)), "Simulation budget still requires hotpath audit")
	var ui_budget: Dictionary = Dictionary(project_budget.get("ui", {}))
	_assert(bool(ui_budget.get("require_fixed_window", false)), "UI budget still requires fixed window contract")

	for task_variant in PREREQ_TASKS:
		var task: Dictionary = Dictionary(task_variant)
		var task_id: String = String(task.get("id", ""))
		var report_text: String = _read_text(String(task.get("report", ""))).to_lower()
		_assert(not _contains_critical_regression_token(report_text), "%s report contains no critical regression token" % task_id)


func _test_manual_checklist_contract() -> void:
	var checklist_text: String = _read_text(MANUAL_CHECKLIST_PATH)
	for token in ["FullHD", "1280x720", "Mission-Command-Flow", "Dropship/LZ", "zwei lokale Instanzen", "Multiplayer", "Follow-up"]:
		_assert(checklist_text.contains(token), "Manual checklist covers %s" % token)


func _test_live_fullhd_and_compact_command_feedback_smoke() -> void:
	var full_hd: String = String(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("PROFILE_FULL_HD"))
	var compact: String = String(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("PROFILE_COMPACT_720"))
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_profile_for_viewport", Vector2i(1920, 1080)) == full_hd, "FullHD viewport resolves to full_hd layout profile")
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_profile_for_viewport", Vector2i(1280, 720)) == compact, "1280x720 viewport resolves to compact_720 layout profile")

	root.size = Vector2i(1920, 1080)
	var fullhd_scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(fullhd_scene)
	await _wait_frames(24)
	var fullhd_ui := fullhd_scene.get_node_or_null("TacticalUI") as CanvasLayer
	var fullhd_controller := fullhd_scene.get_node_or_null("TacticalController")
	var fullhd_simulation_root := fullhd_scene.get_node_or_null("SimulationRoot")
	_assert(fullhd_ui != null and String(fullhd_ui.get_meta("drop_light_layout_profile", "")) == full_hd, "Mission HUD records full_hd profile at 1920x1080")
	_assert(fullhd_controller != null and fullhd_simulation_root != null, "Mission scene exposes controller and SimulationRoot for feedback smoke")
	if fullhd_controller != null and fullhd_simulation_root != null:
		var command_count_before: int = fullhd_simulation_root.command_queue.size()
		var effect_count_before: int = fullhd_simulation_root.effects_queue.size()
		fullhd_controller.call("_set_selected_fireteams", PackedStringArray(), false)
		await _wait_frames(6)
		var feedback: Dictionary = Dictionary(fullhd_controller.call("get_command_feedback_snapshot"))
		var move_action: Dictionary = _get_feedback_action(feedback, "move")
		var move_button: Dictionary = _get_feedback_button(feedback, "move")
		var clarity: Dictionary = Dictionary(feedback.get("command_clarity", {}))
		_assert(String(move_action.get("disabled_reason_code", "")) == "no_fireteam_selected", "FullHD command feedback exposes missing-selection disabled reason")
		_assert(String(move_button.get("tooltip_text", "")).contains("Select a fireteam"), "FullHD Move tooltip exposes playable disabled reason")
		_assert(bool(clarity.get("visual_only", false)) and not bool(clarity.get("ui_sets_gameplay_truth", true)), "Command clarity snapshot remains visual-only")
		_assert(fullhd_simulation_root.command_queue.size() == command_count_before, "Feedback read enqueues no SimulationRoot commands")
		_assert(fullhd_simulation_root.effects_queue.size() == effect_count_before, "Feedback read enqueues no SimulationRoot effects")
	fullhd_scene.queue_free()
	await _wait_frames(4)

	root.size = Vector2i(1280, 720)
	var compact_scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(compact_scene)
	await _wait_frames(24)
	var compact_ui := compact_scene.get_node_or_null("TacticalUI") as CanvasLayer
	_assert(compact_ui != null and String(compact_ui.get_meta("drop_light_layout_profile", "")) == compact, "Mission HUD records compact_720 profile at 1280x720")
	for button_name in ["MoveButton", "GoCommandMatrixButton", "SetLZButton", "CallDropshipButton"]:
		_assert(_button_reachable_by_name(compact_scene, button_name, Vector2i(1280, 720)), "Compact mission button remains reachable: %s" % button_name)
	compact_scene.queue_free()
	await _wait_frames(4)


func _get_feedback_action(feedback: Dictionary, action_id: String) -> Dictionary:
	var hierarchy: Dictionary = Dictionary(feedback.get("command_hierarchy", {}))
	var actions: Dictionary = Dictionary(hierarchy.get("actions_by_id", {}))
	return Dictionary(actions.get(action_id, {}))


func _get_feedback_button(feedback: Dictionary, action_id: String) -> Dictionary:
	return Dictionary(Dictionary(feedback.get("command_buttons", {})).get(action_id, {}))


func _button_reachable_by_name(root_node: Node, button_name: String, viewport_size: Vector2i) -> bool:
	var button := root_node.find_child(button_name, true, false) as Button
	if button == null or not (button.visible and button.is_visible_in_tree()):
		return false
	if button.size.x < 32.0 or button.size.y < 32.0:
		return false
	return Rect2(Vector2.ZERO, Vector2(float(viewport_size.x), float(viewport_size.y))).grow(1.0).encloses(Rect2(button.global_position, button.size))


func _find_forbidden_runtime_test_refs(root_paths: Array) -> Array:
	var result: Array = []
	for root_path_variant in root_paths:
		result.append_array(_find_forbidden_runtime_test_refs_recursive(String(root_path_variant)))
	return result


func _find_forbidden_runtime_test_refs_recursive(path: String) -> Array:
	var result: Array = []
	var dir := DirAccess.open(path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while not entry.is_empty():
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var child_path: String = "%s/%s" % [path, entry]
		if dir.current_is_dir():
			result.append_array(_find_forbidden_runtime_test_refs_recursive(child_path))
		elif entry.ends_with(".gd") or entry.ends_with(".tscn"):
			var text: String = _read_text(child_path)
			for token in RUNTIME_TEST_PATH_TOKENS:
				if text.contains(token):
					result.append("%s -> %s" % [child_path, token])
		entry = dir.get_next()
	dir.list_dir_end()
	return result


func _contains_critical_regression_token(text: String) -> bool:
	var blocked_tokens: PackedStringArray = [
		"kritische regression",
		"critical regression",
		"critical budget regression",
		"budget exceeded",
		"budgetueberschreitung kritisch",
		"fehlgeschlagen",
	]
	for token in blocked_tokens:
		if text.contains(token):
			return true
	return false


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


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
