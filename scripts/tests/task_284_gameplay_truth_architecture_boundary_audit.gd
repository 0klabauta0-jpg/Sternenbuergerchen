extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_284_gameplay_truth_architecture_boundary_audit.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reviews/gameplay_truth_architecture_boundary_audit.md"

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const HELP_SERVICE_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_service.gd")
const HELP_POPUP_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_popup.gd")
const MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")

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
	print("=== TASK_284 Gameplay Truth Architecture Boundary Audit ===")
	_test_report_task_status_and_roadmap()
	_test_static_ui_editor_visualizer_boundaries()
	_test_release_deeplink_has_no_embedded_synthetic_runtime_mutation()
	_test_help_layer_has_no_runtime_authority_terms()
	_test_authority_source_anchors()
	await _test_ui_help_runtime_actions_do_not_mutate_simulation_root()
	await _test_remote_snapshot_apply_queues_no_client_commands_or_effects()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_report_task_status_and_roadmap() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_284 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("### TASK_284 - Gameplay Truth Architecture Boundary Audit") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_284 implemented")
	_assert(roadmap_text.contains("TASK_284 - Gameplay Truth Architecture Boundary Audit (implementiert)"), "Roadmap marks TASK_284 implemented")
	for token in [
		"## Findings",
		"Blocker",
		"Important",
		"Cleanup",
		"CommanderIntent -> FireteamExecutionPlan -> UnitAction",
		"BreakoutState",
		"TacticalCommunicationEvent",
		"AirAssetStatus",
		"Loadout",
		"Character Card",
	]:
		_assert(report_text.contains(token), "Audit report contains '%s'" % token)


func _test_static_ui_editor_visualizer_boundaries() -> void:
	var offenders: PackedStringArray = PackedStringArray()
	for root_path in UI_BOUNDARY_SCAN_ROOTS:
		for file_path in _collect_gd_files(root_path):
			var text: String = _read_text(file_path)
			var lines: PackedStringArray = text.split("\n")
			for index in range(lines.size()):
				var line: String = lines[index]
				for token in FORBIDDEN_UI_MUTATION_TOKENS:
					if line.contains(token):
						offenders.append("%s:%d contains %s" % [file_path, index + 1, token])
	_assert(offenders.is_empty(), "UI/meta/editor/visualizer layers contain no direct authoritative mutation calls: %s" % "; ".join(offenders))

	var terrain_view_text: String = _read_text("res://scripts/terrain/terrain_map_3d_view.gd")
	for token in ["enqueue_command", "enqueue_effect", "set_runtime_status", "apply_damage("]:
		_assert(not terrain_view_text.contains(token), "TerrainMap3DView does not contain %s" % token)


func _test_release_deeplink_has_no_embedded_synthetic_runtime_mutation() -> void:
	var meta_source: String = _read_text("res://scripts/meta/meta_layer_flow.gd")
	var actual_violations: PackedStringArray = _collect_release_deeplink_synthetic_runtime_mutations(meta_source)
	_assert(actual_violations.is_empty(), "Release deeplink delegates synthetic setup instead of mutating combat runtime: %s" % "; ".join(actual_violations))

	var injected_source := "func _apply_release_first_go_firefight_deeplink() -> void:\n\tcombat_driver.set(\"_current_tick\", 120)\n\nfunc harmless() -> void:\n\tpass\n"
	var injected_violations: PackedStringArray = _collect_release_deeplink_synthetic_runtime_mutations(injected_source)
	_assert(injected_violations.has(".set(\"_current_tick\""), "Focused deeplink scanner rejects an injected private tick write")


func _collect_release_deeplink_synthetic_runtime_mutations(source: String) -> PackedStringArray:
	var body: String = _function_body(source, "_apply_release_first_go_firefight_deeplink")
	var violations := PackedStringArray()
	for token in [
		"_position_release_first_enemy_near_fireteam(",
		"_prepare_release_fireteam_for_first_engagement(",
		"_stabilize_release_first_exchange_target_enemy(",
		"_force_release_first_engagement_decision(",
		"_update_release_contact_tracking(",
		".global_position =",
		".set(\"_detection_progress\"",
		".set(\"_current_tick\"",
		".set(\"_next_attack_tick\"",
		"._try_enqueue_attacks",
	]:
		if body.contains(token):
			violations.append(token)
	return violations


func _function_body(source: String, function_name: String) -> String:
	var start: int = source.find("func %s(" % function_name)
	if start < 0:
		return ""
	var finish: int = source.find("\n\nfunc ", start + 5)
	if finish < 0:
		finish = source.length()
	return source.substr(start, finish - start)


func _test_help_layer_has_no_runtime_authority_terms() -> void:
	var help_paths: PackedStringArray = [
		"res://scripts/ui/contextual_help_service.gd",
		"res://scripts/ui/contextual_help_popup.gd",
		"res://docs/dev/contextual_help_popup_ux_contract.md",
	]
	for path in help_paths:
		var text: String = _read_text(path)
		_assert(not text.contains("enqueue_command") and not text.contains("enqueue_effect"), "%s help layer does not enqueue runtime work" % path.get_file())
		_assert(not text.contains("set_runtime_status") and not text.contains("apply_damage("), "%s help layer does not set unit/asset truth" % path.get_file())
	var contract: String = _read_text("res://docs/dev/contextual_help_popup_ux_contract.md")
	_assert(contract.contains("UI aid only") and contract.contains("must never become gameplay truth"), "Contextual help contract documents visual-only boundary")


func _test_authority_source_anchors() -> void:
	var simulation_root_text: String = _read_text("res://scripts/core/simulation_root.gd")
	for token in [
		"func enqueue_command",
		"func enqueue_effect",
		"func set_multiplayer_snapshot_context",
		"func apply_multiplayer_snapshot",
		"func _apply_air_asset_status_update_effect",
	]:
		_assert(simulation_root_text.contains(token), "SimulationRoot keeps authority anchor %s" % token)

	var command_contract_text: String = _read_text("res://scripts/multiplayer/multiplayer_command_contract.gd")
	for token in [
		"FORBIDDEN_STATE_KEYS",
		"fireteam_plan_status",
		"breakout_state",
		"communication_events",
		"air_asset_status",
		"FORBIDDEN_LZ_SOURCES",
		"host_required",
	]:
		_assert(command_contract_text.contains(token), "Multiplayer command contract guards %s" % token)

	var docs_to_tokens: Dictionary = {
		"res://docs/dev/commander_fireteam_delegation_contract.md": ["CommanderIntent -> FireteamExecutionPlan -> UnitAction", "UI may create or display", "SimulationRoot"],
		"res://docs/dev/tactical_breakout_exception_contract.md": ["Breakout", "ui_sets_gameplay_truth = false", "runtime_authority"],
		"res://docs/dev/tactical_multiplayer_authority_snapshot.md": ["apply_multiplayer_snapshot", "enqueued keine Commands", "air_asset_status"],
		"res://docs/dev/air_asset_threat_damage_contract.md": ["AirAssetStatus", "SimulationRoot", "UI zeigt den Status"],
		"res://docs/dev/loadout_playability_rules.md": ["LoadoutModifierResolver", "Weight", "hidden item"],
	}
	for path in docs_to_tokens.keys():
		var text: String = _read_text(path)
		for token in Array(docs_to_tokens[path]):
			_assert(text.contains(String(token)), "%s documents %s" % [path.get_file(), String(token)])

	var dropship_adapter: String = _read_text("res://scripts/mission/mission_dropship_effect_adapter.gd")
	_assert(dropship_adapter.contains("\"runtime_authority\": \"SimulationRoot\"") and dropship_adapter.contains("\"ui_sets_gameplay_truth\": false"), "Dropship effect adapter labels AirAssetStatus as SimulationRoot authority")
	var air_asset_status: String = _read_text("res://scripts/mission/air_asset_status.gd")
	_assert(air_asset_status.contains("snapshot[\"runtime_authority\"] = RUNTIME_AUTHORITY") and air_asset_status.contains("snapshot[\"ui_sets_gameplay_truth\"] = false"), "AirAssetStatus snapshot labels UI as non-authority")


func _test_ui_help_runtime_actions_do_not_mutate_simulation_root() -> void:
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	get_root().add_child(simulation_root)

	var service = HELP_SERVICE_SCRIPT.new()
	var load_error: Error = service.call("load_catalog")
	_assert(load_error == OK, "ContextualHelpService loads catalog for runtime boundary smoke")
	service.call("set_help_mode", "expanded")
	service.call("set_global_help_active", true)
	var payload: Dictionary = Dictionary(service.call("request_help", "mission.command.roe_fire_rules", 4.0, true))
	_assert(not payload.is_empty() and String(payload.get("help_id", "")) == "mission.command.roe_fire_rules", "Help payload resolves without gameplay dependency")

	var popup = HELP_POPUP_SCRIPT.new()
	popup.name = "ContextualHelpPopup"
	get_root().add_child(popup)
	popup.call("show_help", payload, Rect2(Vector2(96.0, 96.0), Vector2(80.0, 40.0)), Vector2(1920.0, 1080.0), true)
	popup.call("hide_help")
	_assert(simulation_root.command_queue.is_empty(), "Help popup interaction enqueues no SimulationRoot commands")
	_assert(simulation_root.effects_queue.is_empty(), "Help popup interaction enqueues no SimulationRoot effects")

	popup.queue_free()
	simulation_root.queue_free()
	await process_frame


func _test_remote_snapshot_apply_queues_no_client_commands_or_effects() -> void:
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "ClientSimulationRoot"
	get_root().add_child(simulation_root)
	var contract = MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(contract.call("build_state_snapshot", {
		"tick": 7,
		"commander_intents": [
			{"command_id": "intent_truth_audit", "verb": "take", "team_id": "team_alpha", "fireteam_id": "blue", "target_position": Vector2(64.0, 64.0)},
		],
		"fireteam_plan_status": [
			{"plan_id": "plan_truth_audit", "command_id": "intent_truth_audit", "team_id": "team_alpha", "fireteam_id": "blue", "phase": 0, "ui_sets_gameplay_truth": false},
		],
		"communication_events": [
			{"event_id": "comm_truth_audit", "event_type": "copy", "team_id": "team_alpha", "fireteam_id": "blue"},
		],
		"breakout_states": [
			{"breakout_id": "breakout_truth_audit", "event_id": "comm_truth_audit", "plan_id": "plan_truth_audit", "command_id": "intent_truth_audit", "fireteam_id": "blue", "status": "holding"},
		],
		"air_asset_status": [
			{"asset_id": "mission_dropship", "asset_type": "dropship", "state": "damaged", "runtime_authority": "SimulationRoot", "ui_sets_gameplay_truth": false},
		],
	}))
	var apply_result: Dictionary = Dictionary(simulation_root.call("apply_multiplayer_snapshot", snapshot))
	var last_server_state: Dictionary = Dictionary(simulation_root.call("get_last_server_state"))
	_assert(bool(apply_result.get("accepted", false)), "Client accepts normalized tactical snapshot")
	_assert(simulation_root.command_queue.is_empty(), "Applying server snapshot enqueues no client commands")
	_assert(simulation_root.effects_queue.is_empty(), "Applying server snapshot enqueues no client effects")
	_assert(Array(last_server_state.get("commander_intents", [])).size() == 1, "CommanderIntent is mirrored as read-only server state")
	_assert(Array(last_server_state.get("air_asset_status", [])).size() == 1, "AirAssetStatus is mirrored as read-only server state")

	simulation_root.queue_free()
	await process_frame


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


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
