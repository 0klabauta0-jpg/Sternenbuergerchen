extends SceneTree

const DEBRIEF_SCENE: PackedScene = preload("res://scenes/meta/debrief_test_screen.tscn")
const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_588_debrief_aar_data_bridge.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const DEBRIEF_SCREEN_PATH: String = "res://scripts/meta/debrief_screen.gd"
const META_LAYER_PATH: String = "res://scripts/meta/meta_layer_flow.gd"

var _passed: int = 0
var _failed: int = 0


class FakeTacticalController:
	extends Node

	var mini_aar_snapshot: Dictionary = {}

	func get_mini_aar_debrief_screen_snapshot() -> Dictionary:
		return mini_aar_snapshot.duplicate(true)


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_588 Debrief AAR Data Bridge ===")
	_test_docs_and_wiring()
	await _test_meta_layer_bridges_mini_aar_snapshot()
	await _test_debrief_renders_aar_bridge()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_588: FAILED")
		quit(1)
		return
	print("TASK_588: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var debrief_text: String = _read_text(DEBRIEF_SCREEN_PATH)
	var meta_layer_text: String = _read_text(META_LAYER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_588 task file exists")
	_assert(task_text.contains("Debrief AAR Data Bridge"), "TASK_588 task file names the task")
	_assert(status_text.contains("TASK_588 - Debrief AAR Data Bridge"), "Implementation status tracks TASK_588")
	_assert(status_text.contains("TASK_587 - Debrief Visual Polish Pass"), "Implementation status still tracks TASK_587")
	_assert(roadmap_text.contains("TASK_588 - Debrief AAR Data Bridge (implementiert)"), "Roadmap marks TASK_588 implemented")
	_assert(roadmap_text.contains("TASK_589 - Debrief AAR F6 Visual Evidence Pass"), "Roadmap names TASK_589 follow-up")
	_assert(report_text.contains("TASK_588 - Debrief AAR Data Bridge"), "Review workbench tracks TASK_588")
	_assert(report_text.contains("TASK_589 - Debrief AAR F6 Visual Evidence Pass"), "Review workbench names TASK_589 follow-up")
	_assert(report_text.contains("Laufender Arbeitsbericht"), "Review workbench keeps the rolling HTML work report")
	_assert(contract_text.contains("Debrief-AAR-Data-Bridge"), "Mission feedback contract documents TASK_588")
	_assert(debrief_text.contains("get_debrief_aar_data_bridge_snapshot"), "Debrief screen exposes TASK_588 snapshot")
	_assert(debrief_text.contains("AARChipStrip"), "Debrief screen renders AAR chips")
	_assert(meta_layer_text.contains("_extract_mini_aar_debrief_from_mission"), "MetaLayerFlow extracts mini AAR debrief payload")
	_assert(meta_layer_text.contains("mini_aar_debrief"), "MetaLayerFlow writes mini_aar_debrief into mission result")


func _test_meta_layer_bridges_mini_aar_snapshot() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = META_LAYER_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(8)

	var fake_mission := Node.new()
	var fake_controller := FakeTacticalController.new()
	fake_controller.name = "TacticalController"
	fake_controller.mini_aar_snapshot = _build_mini_aar_debrief_payload()
	fake_mission.add_child(fake_controller)

	var base_result: Dictionary = _build_base_mission_result()
	var merged_result: Dictionary = Dictionary(scene.call("_build_mission_result", fake_mission, base_result))
	var bridged_payload: Dictionary = Dictionary(merged_result.get("mini_aar_debrief", {}))
	_assert(String(bridged_payload.get("schema", "")) == "sternenbuergerchen.mini_aar_debrief_screen_stub.v1", "MetaLayerFlow bridges mini AAR debrief schema")
	_assert(bool(bridged_payload.get("read_only", false)), "Bridged mini AAR payload remains read-only")
	_assert(not bool(bridged_payload.get("ui_sets_gameplay_truth", true)), "Bridged mini AAR payload does not set gameplay truth")
	_assert(String(bridged_payload.get("summary_text", "")).contains("FIRE"), "Bridged mini AAR payload keeps FIRE summary")
	_assert(Array(bridged_payload.get("chips", [])).size() >= 5, "Bridged mini AAR payload keeps chips")

	fake_mission.queue_free()
	scene.queue_free()
	await _wait_frames(2)


func _test_debrief_renders_aar_bridge() -> void:
	root.size = Vector2i(1920, 1080)
	var debrief: Node = DEBRIEF_SCENE.instantiate()
	root.add_child(debrief)
	await _wait_frames(8)
	var mission_result: Dictionary = _build_base_mission_result()
	mission_result["mini_aar_debrief"] = _build_mini_aar_debrief_payload()
	debrief.call("set_mission_result", mission_result)
	await _wait_frames(8)

	var snapshot: Dictionary = Dictionary(debrief.call("get_debrief_aar_data_bridge_snapshot"))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.debrief_aar_data_bridge.v1", "Debrief AAR bridge reports stable schema")
	_assert(String(snapshot.get("gate", "")) == "pass", "Debrief AAR bridge gate passes")
	_assert(bool(snapshot.get("read_only", false)), "Debrief AAR bridge snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Debrief AAR bridge does not set gameplay truth")
	_assert(String(snapshot.get("source_schema", "")) == "sternenbuergerchen.mini_aar_debrief_screen_stub.v1", "Debrief AAR bridge reports source schema")
	_assert(bool(snapshot.get("aar_section_visible", false)), "Debrief AAR bridge section is visible")
	_assert(String(snapshot.get("aar_summary_text", "")).contains("FIRE"), "Debrief AAR summary shows FIRE")
	_assert(String(snapshot.get("aar_summary_text", "")).contains("SUP"), "Debrief AAR summary shows SUP")
	_assert(int(snapshot.get("aar_chip_count", 0)) >= 5, "Debrief AAR bridge renders at least five chips")
	_assert(int(snapshot.get("aar_row_count", 0)) >= 4, "Debrief AAR bridge renders at least four rows")
	_assert(String(snapshot.get("aar_limit_text", "")).contains("Keine XP"), "Debrief AAR bridge shows no-XP limit")
	_assert(String(snapshot.get("aar_limit_text", "")).contains("keine Ammo"), "Debrief AAR bridge shows no-Ammo limit")
	_assert(String(snapshot.get("aar_limit_text", "")).contains("keine echte Suppression"), "Debrief AAR bridge shows no-real-suppression limit")
	_assert(String(snapshot.get("visual_snapshot_gate", "")) == "pass", "Debrief visual polish stays green")
	_assert(_check_passed(snapshot, "aar_chips_visible"), "AAR chips visible check passes")
	_assert(_check_passed(snapshot, "aar_limits_honest"), "AAR limits check passes")

	debrief.queue_free()
	await _wait_frames(2)


func _build_base_mission_result() -> Dictionary:
	return {
		"winning_team_id": "team_alpha",
		"mission_outcome": "completed",
		"result": "victory",
		"win_condition_type": "objective_capture",
		"objective_captured": true,
		"duration_seconds": 185.0,
		"team_states": [
			{"unit_id": "lead_alpha", "display_name": "Lead Alpha", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 100},
			{"unit_id": "rifle_alpha", "display_name": "Rifle Alpha", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 88},
			{"unit_id": "medic_alpha", "display_name": "Medic Alpha", "fireteam_id": "ft_alpha", "vital_state": "wounded", "health_points": 42},
		],
		"fireteam_tactical_debrief": [
			{"fireteam_id": "ft_alpha", "reaction_delay_seconds": 0.42, "plan_quality": 0.76, "tempo_modifier": 1.08, "contact_report_count": 3, "contact_report_quality": 0.72, "morale": 0.68, "frustration": 0.22},
		],
	}


func _build_mini_aar_debrief_payload() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.mini_aar_debrief_screen_stub.v1",
		"task_id": "TASK_585",
		"source_schema": "sternenbuergerchen.mini_aar_combat_metrics.v1",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"screen": {
			"schema": "sternenbuergerchen.mini_aar_debrief_screen_stub.panel.v1",
			"title_text": "MINI AAR",
			"subtitle_text": "Combat metrics preview",
			"summary_text": "AAR | FIRE 12 | HIT 7 | FF 1/2 | SUP 3 | WOUND 1 | EXT 2",
			"layout_key": "mini_aar_debrief_compact_v1",
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		},
		"summary_text": "AAR | FIRE 12 | HIT 7 | FF 1/2 | SUP 3 | WOUND 1 | EXT 2",
		"rows": [
			{"id": "fire", "label": "Fire", "value_text": "FIRE 12 | HIT 7", "read_only": true},
			{"id": "friendly_fire", "label": "Friendly Fire", "value_text": "FF 1 / Risk 2", "read_only": true},
			{"id": "suppress", "label": "Suppress", "value_text": "SUP x3", "read_only": true},
			{"id": "status", "label": "Status", "value_text": "WOUND 1 | DOWN 0 | EXT 2", "read_only": true},
		],
		"chips": [
			{"id": "shots", "label": "FIRE", "value_text": "12", "style_key": "neutral", "read_only": true},
			{"id": "hits", "label": "HIT", "value_text": "7", "style_key": "good", "read_only": true},
			{"id": "ff", "label": "FF", "value_text": "1/2", "style_key": "warn", "read_only": true},
			{"id": "sup", "label": "SUP", "value_text": "3", "style_key": "accent", "read_only": true},
			{"id": "wounded", "label": "WOUND", "value_text": "1", "style_key": "warn", "read_only": true},
			{"id": "extracted", "label": "EXT", "value_text": "2", "style_key": "neutral", "read_only": true},
		],
		"limit_text": "Keine XP, keine Ammo, keine echte Suppression - nur Debrief-Vorschau aus vorhandenen Metriken.",
		"gate": "pass",
	}


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


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
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame
