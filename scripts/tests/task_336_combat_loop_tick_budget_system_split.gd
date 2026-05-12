extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/simulation_combat_ai_tick_budget_harness.gd")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_loop_driver.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_336_combat_loop_tick_budget_system_split.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/combat_loop_tick_budget_system_split.md"
const DRIVER_PATH: String = "res://scripts/mission/mission_combat_loop_driver.gd"

const REQUIRED_PHASES: Array = [
	"bleedout_queue",
	"leadership",
	"detection_timers",
	"contact_tracking",
	"enemy_security",
	"enemy_team_tactics",
	"flank_vulnerability",
	"cooldowns",
	"medic_support",
	"enemy_advance",
	"friendly_standard_behavior",
	"overwatch_security",
	"combat_fire_decision",
	"combat_resolution",
	"multiplayer_snapshot_context",
	"status_update",
]
const REQUIRED_SCOPE_KEYS: Array = [
	"bleedout_queue_usec",
	"leadership_usec",
	"detection_timers_usec",
	"contact_tracking_usec",
	"enemy_security_usec",
	"enemy_team_tactics_usec",
	"flank_vulnerability_usec",
	"cooldowns_usec",
	"medic_support_usec",
	"enemy_advance_usec",
	"friendly_standard_behavior_usec",
	"overwatch_security_usec",
	"combat_fire_decision_usec",
	"combat_resolution_usec",
	"multiplayer_snapshot_context_usec",
	"status_update_usec",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_336 Combat Loop Tick Budget System Split ===")
	_test_docs_status_and_report()
	_test_static_phase_inventory_contract()
	await _test_live_phase_telemetry()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_docs_status_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_336 task file marks implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_336 checklist is complete")
	_assert(status_text.contains("### TASK_336 - Combat Loop Tick Budget System Split") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_336 implemented")
	_assert(roadmap_text.contains("TASK_336 - Combat Loop Tick Budget System Split (implementiert"), "Roadmap marks TASK_336 implemented")
	for token in ["Phaseninventar", "Phase-Dauer", "Hauptzaehler", "Every-N", "SimulationRoot"]:
		_assert(report_text.contains(token), "Report documents %s" % token)


func _test_static_phase_inventory_contract() -> void:
	var driver_text: String = _read_text(DRIVER_PATH)
	_assert(driver_text.contains("COMBAT_TICK_PHASE_ORDER"), "Combat driver declares explicit phase order")
	_assert(driver_text.contains("_run_core_combat_tick_phases"), "Combat driver delegates tick execution to phase runner")
	_assert(driver_text.contains("_execute_combat_tick_phase"), "Combat driver isolates phase execution")
	_assert(driver_text.contains("get_combat_tick_phase_inventory_snapshot"), "Combat driver exposes phase inventory snapshot")
	_assert(not driver_text.contains("scope_started_usec"), "Old inline scope timer variable is removed from tick path")

	var driver = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	var inventory: Dictionary = Dictionary(driver.call("get_combat_tick_phase_inventory_snapshot"))
	var phase_order: Array = Array(inventory.get("phase_order", []))
	var catalog: Array = Array(inventory.get("phase_catalog", []))
	_assert(_same_string_array(phase_order, REQUIRED_PHASES), "Phase order matches documented TASK_336 inventory")
	_assert(catalog.size() == REQUIRED_PHASES.size(), "Phase catalog has one entry per phase")
	_assert(_phase_ids_are_unique(catalog), "Phase ids are unique")
	_assert(_catalog_scope_keys(catalog).size() == REQUIRED_SCOPE_KEYS.size(), "Phase catalog exposes scope keys for all phases")
	for scope_key in REQUIRED_SCOPE_KEYS:
		_assert(_catalog_scope_keys(catalog).has(scope_key), "Phase catalog exposes scope %s" % String(scope_key))
	_assert(_phase_has_dependency(catalog, "contact_tracking", "detection_timers"), "Contact tracking depends on detection timers")
	_assert(_phase_has_dependency(catalog, "combat_fire_decision", "overwatch_security"), "Fire decision depends on overwatch phase")
	_assert(_phase_has_dependency(catalog, "multiplayer_snapshot_context", "combat_resolution"), "Snapshot publication depends on combat resolution")
	var candidates: Array = Array(inventory.get("budget_candidate_phase_ids", []))
	_assert(candidates.has("enemy_team_tactics") and candidates.has("flank_vulnerability"), "Inventory marks later Every-N review candidates")
	_assert(String(inventory.get("authority_root", "")) == "SimulationRoot", "Inventory keeps SimulationRoot as authority")
	_assert(not bool(inventory.get("rules_rebalanced", true)), "Inventory declares no combat rebalance")
	driver.free()


func _test_live_phase_telemetry() -> void:
	var harness = HARNESS_SCRIPT.new()
	var result: Dictionary = await harness.run_all(root, 1)
	var scenarios: Dictionary = Dictionary(result.get("scenarios", {}))
	_assert(not scenarios.is_empty(), "Combat budget harness returns scenarios")
	for scenario_id_variant in scenarios.keys():
		var scenario_id: String = String(scenario_id_variant)
		var scenario: Dictionary = Dictionary(scenarios.get(scenario_id_variant, {}))
		var last_tick: Dictionary = _last_tick_record(scenario)
		var combat: Dictionary = Dictionary(last_tick.get("combat", {}))
		var phase_records: Array = Array(combat.get("phase_records", []))
		var phase_order: Array = Array(combat.get("phase_order", []))
		var scopes: Dictionary = Dictionary(combat.get("scopes_usec", {}))
		_assert(_same_string_array(phase_order, REQUIRED_PHASES), "%s live snapshot keeps explicit phase order" % scenario_id)
		_assert(_same_string_array(_phase_ids_from_records(phase_records), REQUIRED_PHASES), "%s phase records follow phase order" % scenario_id)
		_assert(Array(combat.get("phase_catalog", [])).size() == REQUIRED_PHASES.size(), "%s live snapshot includes phase catalog" % scenario_id)
		for scope_key in REQUIRED_SCOPE_KEYS:
			_assert(scopes.has(scope_key), "%s live scopes include %s" % [scenario_id, String(scope_key)])
			_assert(float(scopes.get(scope_key, -1.0)) >= 0.0, "%s live scope %s is non-negative" % [scenario_id, String(scope_key)])
		_assert(_records_have_durations_and_counters(phase_records), "%s phase records expose durations and counters" % scenario_id)
		_assert(_record_counter_int(phase_records, "contact_tracking", "contact_count") >= 0, "%s contact phase records contact count" % scenario_id)
		_assert(_record_counter_int(phase_records, "overwatch_security", "overwatch_shot_count") >= 0, "%s overwatch phase records shot count" % scenario_id)
		_assert(_record_counter_int(phase_records, "enemy_team_tactics", "enemy_team_tactics_group_count") >= 0, "%s tactics phase records group count" % scenario_id)
		_assert(Array(combat.get("budget_candidate_phase_ids", [])).has("enemy_security"), "%s live snapshot carries budget candidates" % scenario_id)
		var audit: Dictionary = Dictionary(combat.get("hotpath_audit", {}))
		_assert(String(audit.get("authority_root", "")) == "SimulationRoot", "%s hotpath audit keeps SimulationRoot authority" % scenario_id)

	var summary: Dictionary = Dictionary(result.get("summary", {}))
	_assert(bool(summary.get("has_combat_scopes", false)), "Harness still marks combat scope coverage")
	var large_stats: Dictionary = Dictionary(Dictionary(scenarios.get("four_fireteams_multi_enemy_medic_overwatch", {})).get("stats", {}))
	var combat_scopes: Dictionary = Dictionary(large_stats.get("combat_scopes_usec", {}))
	for scope_key in ["enemy_team_tactics_usec", "flank_vulnerability_usec", "friendly_standard_behavior_usec"]:
		_assert(_stat_has_percentiles(Dictionary(combat_scopes.get(scope_key, {}))), "Large scenario keeps stats for %s" % scope_key)


func _phase_ids_from_records(records: Array) -> Array:
	var result: Array = []
	for record_variant in records:
		var record: Dictionary = Dictionary(record_variant)
		result.append(String(record.get("phase_id", "")))
	return result


func _catalog_scope_keys(catalog: Array) -> Array:
	var result: Array = []
	for definition_variant in catalog:
		var definition: Dictionary = Dictionary(definition_variant)
		var scope_key: String = String(definition.get("scope_key", "")).strip_edges()
		if not scope_key.is_empty():
			result.append(scope_key)
	return result


func _phase_ids_are_unique(catalog: Array) -> bool:
	var seen: Dictionary = {}
	for definition_variant in catalog:
		var phase_id: String = String(Dictionary(definition_variant).get("phase_id", ""))
		if phase_id.is_empty() or seen.has(phase_id):
			return false
		seen[phase_id] = true
	return true


func _phase_has_dependency(catalog: Array, phase_id: String, dependency_id: String) -> bool:
	for definition_variant in catalog:
		var definition: Dictionary = Dictionary(definition_variant)
		if String(definition.get("phase_id", "")) != phase_id:
			continue
		return Array(definition.get("hard_dependencies", [])).has(dependency_id)
	return false


func _records_have_durations_and_counters(records: Array) -> bool:
	if records.is_empty():
		return false
	for record_variant in records:
		var record: Dictionary = Dictionary(record_variant)
		if String(record.get("phase_id", "")).is_empty():
			return false
		if String(record.get("scope_key", "")).is_empty():
			return false
		if int(record.get("duration_usec", -1)) < 0:
			return false
		if typeof(record.get("counters", null)) != TYPE_DICTIONARY:
			return false
	return true


func _record_counter_int(records: Array, phase_id: String, counter_key: String) -> int:
	for record_variant in records:
		var record: Dictionary = Dictionary(record_variant)
		if String(record.get("phase_id", "")) != phase_id:
			continue
		return int(Dictionary(record.get("counters", {})).get(counter_key, -1))
	return -1


func _stat_has_percentiles(stat: Dictionary) -> bool:
	return int(stat.get("count", 0)) > 0 \
		and float(stat.get("median", -1.0)) >= 0.0 \
		and float(stat.get("p95", -1.0)) >= float(stat.get("median", 0.0)) \
		and float(stat.get("p99", -1.0)) >= float(stat.get("median", 0.0))


func _last_tick_record(scenario: Dictionary) -> Dictionary:
	var runs: Array = Array(scenario.get("runs", []))
	if runs.is_empty():
		return {}
	var last_run: Dictionary = Dictionary(runs.back())
	var ticks: Array = Array(last_run.get("ticks", []))
	if ticks.is_empty():
		return {}
	return Dictionary(ticks.back())


func _same_string_array(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	for index in range(expected.size()):
		if String(actual[index]) != String(expected[index]):
			return false
	return true


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
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
