extends SceneTree

const PrimaryHud := preload("res://scripts/mission/release_fire_exchange_contact_fire_primary_hud_polish.gd")

const TASK_PATH := "res://docs/tasks/TASK_856_release_fire_exchange_contact_fire_primary_hud_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html"
const SUMMARY_REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_08.html"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const META_PATH := "res://scripts/meta/meta_layer_flow.gd"
const SERVICE_PATH := "res://scripts/mission/release_fire_exchange_contact_fire_primary_hud_polish.gd"
const SCHEMA := "sternenbuergerchen.release_fire_exchange_contact_fire_primary_hud_polish.v1"
const STYLE_ID := "task_856_release_fire_exchange_contact_fire_primary_hud_polish_v1"
const NEXT_TASK := "TASK_857 - Release Fire Exchange Contact-Fire Primary HUD Recapture"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_856 Release Fire Exchange Contact-Fire Primary HUD Polish ===")
	_test_docs_and_static_hooks()
	_test_analyzer_accepts_contact_fire_primary_lines()
	_test_analyzer_flags_stale_no_fire_primary_lines()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_856_release_fire_exchange_contact_fire_primary_hud_polish: FAILED")
		quit(1)
		return
	print("TASK_856_release_fire_exchange_contact_fire_primary_hud_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var summary_report_text: String = _read_text(SUMMARY_REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var meta_text: String = _read_text(META_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_856 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_856 read-only analyzer exists")
	_assert(task_text.contains("Release Fire Exchange Contact-Fire Primary HUD Polish"), "Task names contact-fire primary HUD polish")
	_assert(status_text.contains("TASK_856 - Release Fire Exchange Contact-Fire Primary HUD Polish"), "Implementation status tracks TASK_856")
	_assert(roadmap_text.contains("TASK_856 - Release Fire Exchange Contact-Fire Primary HUD Polish (implementiert)"), "Roadmap marks TASK_856 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_857 follow-up")
	_assert(contract_text.contains("Release-Fire-Exchange-Contact-Fire-Primary-HUD-Polish"), "Contract documents TASK_856")
	_assert(report_text.contains("TASK_856") and report_text.contains("CONTACT FIRE |"), "Fire-exchange report tracks TASK_856")
	_assert(summary_report_text.contains("TASK_856") and summary_report_text.contains("CONTACT FIRE"), "Spielstand report tracks TASK_856")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes TASK_856 schema")
	_assert(service_text.contains(STYLE_ID), "Analyzer exposes TASK_856 style id")
	_assert(controller_text.contains("RELEASE_FIRE_EXCHANGE_CONTACT_FIRE_PRIMARY_HUD_POLISH_STYLE_ID"), "Controller exposes TASK_856 style id")
	_assert(controller_text.contains("_build_release_fire_exchange_contact_fire_primary_hud_line"), "Controller builds CONTACT FIRE primary line")
	_assert(controller_text.contains("get_release_fire_exchange_contact_fire_primary_hud_polish_snapshot"), "Controller exposes TASK_856 snapshot")
	_assert(meta_text.contains("get_release_fire_exchange_contact_fire_primary_hud_polish_snapshot"), "MetaLayer exposes TASK_856 wrapper")
	_assert(service_text.contains("\"creates_fire_event\": false"), "TASK_856 declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "TASK_856 declares no damage-event creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "TASK_856 declares no multiplayer truth mutation")
	_assert(service_text.contains("\"updates_shortcuts\": false"), "TASK_856 declares no shortcut updates")


func _test_analyzer_accepts_contact_fire_primary_lines() -> void:
	var snapshot: Dictionary = PrimaryHud.build_snapshot(_good_primary_hud_fixture(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Analyzer snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_856", "Analyzer snapshot task id is TASK_856")
	_assert(String(snapshot.get("style_id", "")) == STYLE_ID, "Analyzer snapshot exposes TASK_856 style id")
	_assert(String(snapshot.get("status", "")) == "pass", "Analyzer passes CONTACT FIRE primary fixture: %s" % JSON.stringify(snapshot.get("issues", [])))
	_assert(bool(snapshot.get("active", false)), "Primary HUD polish is active")
	_assert(String(snapshot.get("contact_fire_primary_line", "")).begins_with("CONTACT FIRE"), "Primary line begins with CONTACT FIRE")
	_assert(bool(snapshot.get("selected_fireteam_contains_contact_fire_primary", false)), "#17 contains CONTACT FIRE primary line")
	_assert(bool(snapshot.get("mission_control_contains_contact_fire_primary", false)), "#18 contains CONTACT FIRE primary line")
	_assert(not bool(snapshot.get("primary_lines_contain_debug_no_fire_before_contact_fire", true)), "NO FIRE does not precede CONTACT FIRE")
	_assert(bool(snapshot.get("read_only", false)), "Analyzer snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Analyzer snapshot does not set gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Analyzer snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Analyzer snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Analyzer snapshot creates no damage events")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Analyzer snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Analyzer snapshot updates no shortcuts")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Analyzer recommends TASK_857 recapture")


func _test_analyzer_flags_stale_no_fire_primary_lines() -> void:
	var stale: Dictionary = _good_primary_hud_fixture()
	stale["contact_fire_primary_line"] = "NO FIRE NO_LOS | F8/E8 | DET 0"
	stale["selected_fireteam_status_text"] = "NO FIRE NO_LOS | F8/E8 | DET 0\nCONTACT FIRE | FIRE alpha_1>enemy_1 | COV PART RNG OK LOS CLR FLK SIDE"
	stale["mission_control_status_text"] = "CONTACT PRESSURE | LOS korrigieren"
	var snapshot: Dictionary = PrimaryHud.build_snapshot(stale, {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "review", "Analyzer rejects stale NO FIRE primary fixture")
	_assert(issue_ids.has("primary_line_not_contact_fire"), "Analyzer flags missing CONTACT FIRE primary line")
	_assert(issue_ids.has("mission_control_missing_primary_line"), "Analyzer flags #18 missing CONTACT FIRE primary line")
	_assert(issue_ids.has("debug_no_fire_before_contact_fire"), "Analyzer flags NO FIRE before CONTACT FIRE")


func _good_primary_hud_fixture() -> Dictionary:
	var compact_line: String = "FIRE alpha_1>enemy_1 | COV PART RNG OK LOS CLR FLK SIDE"
	var primary_line: String = "CONTACT FIRE | %s" % compact_line
	return {
		"active": true,
		"contact_fire_primary_line": primary_line,
		"selected_fireteam_status_text": "%s\nNEXT HIT LESEN / DEFEND | WHY FEUER\nFT1 | Karten 4" % primary_line,
		"mission_control_status_text": "%s\nNEXT HIT LESEN / DEFEND | WHY FEUER\nLZ 12,9" % primary_line,
		"combat_hud_density": {
			"active": true,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"visibility_persistence_active": true,
			"compact_line": compact_line,
			"selected_fireteam_line": "Kampf %s" % compact_line,
			"mission_control_line": compact_line,
			"visibility_persistence": {
				"active": true,
				"read_only": true,
				"ui_sets_gameplay_truth": false,
				"creates_command": false,
				"creates_fire_event": false,
				"creates_damage_event": false,
				"sets_multiplayer_truth": false,
				"compact_line": compact_line,
			}
		},
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


func _issue_ids(issues: Array) -> Array:
	var result: Array = []
	for issue_variant in issues:
		if typeof(issue_variant) != TYPE_DICTIONARY:
			continue
		result.append(String(Dictionary(issue_variant).get("id", "")))
	return result


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
