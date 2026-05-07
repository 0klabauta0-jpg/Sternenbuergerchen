extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/simulation_combat_ai_tick_budget_harness.gd")
const REPORT_PATH: String = "res://docs/performance/simulation_combat_ai_tick_profile_report.md"
const MIN_REPETITIONS: int = 2
const BROAD_TICK_BUDGET_USEC: float = 2000000.0

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_218 Simulation Combat AI Tick Budget Pass ===")
	var harness = HARNESS_SCRIPT.new()
	var result: Dictionary = await harness.run_all(root, MIN_REPETITIONS)
	_test_summary(result)
	_test_scale_scenarios(result)
	_test_runtime_scopes(result)
	_test_hotpath_and_authority(result)
	_test_report_exists()
	print("TASK_218 harness summary: %s" % JSON.stringify(result.get("summary", {})))
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_summary(result: Dictionary) -> void:
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	_assert(int(summary.get("scenario_count", 0)) == 3, "Harness defines three simulation scale scenarios")
	_assert(bool(summary.get("has_small_mission", false)), "Summary includes small mission baseline")
	_assert(bool(summary.get("has_two_fireteams", false)), "Summary includes two-fireteam enemy-team baseline")
	_assert(bool(summary.get("has_large_medic_overwatch", false)), "Summary includes large medic/overwatch/tactics baseline")
	_assert(bool(summary.get("has_simulation_tick_percentiles", false)), "Summary marks SimulationRoot tick percentiles")
	_assert(bool(summary.get("has_combat_tick_percentiles", false)), "Summary marks CombatLoop tick percentiles")
	_assert(bool(summary.get("has_runtime_scopes", false)), "Summary marks runtime scope coverage")
	_assert(bool(summary.get("has_combat_scopes", false)), "Summary marks combat scope coverage")
	_assert(bool(summary.get("has_hotpath_audit", false)), "Summary marks hotpath audit coverage")


func _test_scale_scenarios(result: Dictionary) -> void:
	var scenarios: Dictionary = Dictionary(result.get("scenarios", {}))
	_assert(int(Dictionary(scenarios.get("small_mission", {})).get("friendly_count", 0)) == 4, "Small scenario has four friendly units")
	_assert(int(Dictionary(scenarios.get("two_fireteams_enemy_team", {})).get("fireteam_count", 0)) == 2, "Medium scenario has two fireteams")
	var large: Dictionary = Dictionary(scenarios.get("four_fireteams_multi_enemy_medic_overwatch", {}))
	_assert(int(large.get("friendly_count", 0)) == 16, "Large scenario has sixteen friendly units")
	_assert(int(large.get("enemy_count", 0)) == 12, "Large scenario has twelve enemy units")
	_assert(bool(large.get("include_medic_and_downed", false)), "Large scenario includes medic/downed pressure")
	for scenario_id in scenarios.keys():
		var scenario: Dictionary = Dictionary(scenarios.get(scenario_id, {}))
		var stats: Dictionary = Dictionary(scenario.get("stats", {}))
		_assert(_stat_has_percentiles(Dictionary(stats.get("simulation_total_tick_usec", {}))), "%s SimulationRoot tick stats expose Median/P95/P99" % String(scenario_id))
		_assert(_stat_has_percentiles(Dictionary(stats.get("combat_total_tick_usec", {}))), "%s CombatLoop tick stats expose Median/P95/P99" % String(scenario_id))
		_assert(float(Dictionary(stats.get("simulation_total_tick_usec", {})).get("p99", BROAD_TICK_BUDGET_USEC + 1.0)) < BROAD_TICK_BUDGET_USEC, "%s SimulationRoot p99 stays under broad start budget" % String(scenario_id))
		_assert(float(Dictionary(stats.get("combat_total_tick_usec", {})).get("p99", BROAD_TICK_BUDGET_USEC + 1.0)) < BROAD_TICK_BUDGET_USEC, "%s CombatLoop p99 stays under broad start budget" % String(scenario_id))


func _test_runtime_scopes(result: Dictionary) -> void:
	var scenarios: Dictionary = Dictionary(result.get("scenarios", {}))
	var required_simulation_scopes: Array = ["command_queue_usec", "effect_queue_usec", "unit_minimum_spacing_usec", "tick_signal_emit_usec"]
	var required_combat_scopes: Array = ["contact_tracking_usec", "enemy_security_usec", "enemy_team_tactics_usec", "medic_support_usec", "enemy_advance_usec", "overwatch_security_usec", "combat_fire_decision_usec"]
	for scenario_id in scenarios.keys():
		var stats: Dictionary = Dictionary(Dictionary(scenarios.get(scenario_id, {})).get("stats", {}))
		var simulation_scopes: Dictionary = Dictionary(stats.get("simulation_scopes_usec", {}))
		var combat_scopes: Dictionary = Dictionary(stats.get("combat_scopes_usec", {}))
		for scope_name in required_simulation_scopes:
			_assert(_stat_has_percentiles(Dictionary(simulation_scopes.get(scope_name, {}))), "%s SimulationRoot scope %s has stats" % [String(scenario_id), String(scope_name)])
		for scope_name in required_combat_scopes:
			_assert(_stat_has_percentiles(Dictionary(combat_scopes.get(scope_name, {}))), "%s CombatLoop scope %s has stats" % [String(scenario_id), String(scope_name)])


func _test_hotpath_and_authority(result: Dictionary) -> void:
	var scenarios: Dictionary = Dictionary(result.get("scenarios", {}))
	for scenario_id in scenarios.keys():
		var scenario: Dictionary = Dictionary(scenarios.get(scenario_id, {}))
		var audit: Dictionary = Dictionary(scenario.get("hotpath_audit", {}))
		_assert(String(audit.get("authority_root", "")) == "SimulationRoot", "%s hotpath audit keeps SimulationRoot as authority" % String(scenario_id))
		_assert(bool(audit.get("client_viewer_paths_read_only", false)), "%s hotpath audit keeps viewer paths read-only" % String(scenario_id))
		_assert(String(audit.get("scene_tree_lookup_policy", "")).find("direct_NodePath") >= 0, "%s hotpath audit documents direct NodePath/registry lookup policy" % String(scenario_id))
		var last_tick: Dictionary = _last_tick_record(scenario)
		var simulation: Dictionary = Dictionary(last_tick.get("simulation", {}))
		var combat: Dictionary = Dictionary(last_tick.get("combat", {}))
		_assert(int(simulation.get("registered_unit_count", 0)) >= int(scenario.get("enemy_count", 0)), "%s SimulationRoot reports registered units" % String(scenario_id))
		_assert(int(combat.get("active_enemy_unit_count", 0)) <= int(scenario.get("enemy_count", 0)), "%s CombatLoop reports bounded active enemy count" % String(scenario_id))
		_assert(int(simulation.get("command_queue_after_tick", 0)) <= int(scenario.get("friendly_count", 0)) + int(scenario.get("enemy_count", 0)) + 8, "%s command queue remains bounded after tick" % String(scenario_id))


func _test_report_exists() -> void:
	var report: String = _read_text(REPORT_PATH)
	_assert(not report.is_empty(), "Simulation combat AI tick profile report exists")
	_assert(report.contains("TASK_218") and report.contains("SimulationRoot") and report.contains("CombatLoop"), "Report documents TASK_218 SimulationRoot and CombatLoop scope")
	_assert(report.contains("Median") and report.contains("P95") and report.contains("P99"), "Report documents percentile fields")
	_assert(report.contains("Medic") and report.contains("Overwatch") and report.contains("Enemy-Taktik"), "Report documents Medic, Overwatch and Enemy-Taktik scopes")


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
