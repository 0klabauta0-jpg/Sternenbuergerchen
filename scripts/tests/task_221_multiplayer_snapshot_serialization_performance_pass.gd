extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/multiplayer_snapshot_performance_harness.gd")
const REPORT_PATH: String = "res://docs/performance/multiplayer_snapshot_performance_report.md"
const BROAD_TIME_BUDGET_USEC: float = 2000000.0
const BROAD_JSON_BUDGET_BYTES: float = 262144.0

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_221 Multiplayer Snapshot Serialization Performance Pass ===")
	var harness = HARNESS_SCRIPT.new()
	var result: Dictionary = harness.run_all(root)
	_test_summary(result)
	_test_scenarios(result)
	_test_determinism(result)
	_test_frequency_plan(result)
	_test_report_exists()
	print("TASK_221 harness summary: %s" % JSON.stringify(result.get("summary", {})))
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_summary(result: Dictionary) -> void:
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	_assert(int(summary.get("scenario_count", 0)) == 3, "Harness defines small, medium and large snapshot scenarios")
	_assert(bool(summary.get("has_build_apply_timing", false)), "Summary marks build/apply timing coverage")
	_assert(bool(summary.get("has_size_metrics", false)), "Summary marks payload size metrics")
	_assert(bool(summary.get("deterministic_canonical_payload", false)), "Summary marks deterministic canonical payload")
	_assert(bool(summary.get("all_scenarios_side_effect_free", false)), "Summary marks side-effect-free client apply")
	_assert(bool(summary.get("all_payloads_id_only", false)), "Summary marks ID-only asset/VFX/bubble payloads")


func _test_scenarios(result: Dictionary) -> void:
	var scenarios: Dictionary = Dictionary(result.get("scenarios", {}))
	for scenario_id in ["small_8_units", "medium_32_units", "large_96_units"]:
		var scenario: Dictionary = Dictionary(scenarios.get(scenario_id, {}))
		var stats: Dictionary = Dictionary(scenario.get("stats", {}))
		var counts: Dictionary = Dictionary(scenario.get("last_snapshot_counts", {}))
		var metrics: Dictionary = Dictionary(scenario.get("last_metrics", {}))
		var side_effects: Dictionary = Dictionary(scenario.get("side_effects", {}))
		_assert(int(scenario.get("accepted_apply_count", 0)) == int(scenario.get("iterations", -1)), "%s applies every increasing snapshot" % scenario_id)
		_assert(_stat_under_budget(Dictionary(stats.get("build_usec", {})), BROAD_TIME_BUDGET_USEC), "%s build p99 stays under broad start budget" % scenario_id)
		_assert(_stat_under_budget(Dictionary(stats.get("apply_usec", {})), BROAD_TIME_BUDGET_USEC), "%s apply p99 stays under broad start budget" % scenario_id)
		_assert(_stat_under_budget(Dictionary(stats.get("json_bytes", {})), BROAD_JSON_BUDGET_BYTES), "%s JSON estimate stays under broad start budget" % scenario_id)
		_assert(int(counts.get("unit_count", 0)) == int(scenario.get("unit_count", -1)), "%s unit count is measured" % scenario_id)
		_assert(int(counts.get("fire_event_count", 0)) > 0, "%s carries fire event VFX IDs" % scenario_id)
		_assert(int(counts.get("feedback_bubble_count", 0)) > 0, "%s carries feedback bubble IDs" % scenario_id)
		_assert(int(counts.get("enemy_team_tactics_count", 0)) > 0, "%s carries enemy tactics display state" % scenario_id)
		_assert(bool(counts.get("has_objective", false)), "%s carries objective state" % scenario_id)
		_assert(Array(metrics.get("large_payload_offenders", PackedStringArray())).is_empty(), "%s payload has no raw text/path/asset offenders" % scenario_id)
		_assert(String(metrics.get("asset_reference_policy", "")) == "ids_only_no_texture_paths_or_raw_payloads", "%s documents ID-only asset policy" % scenario_id)
		_assert(int(side_effects.get("command_queue_size", -1)) == 0, "%s client apply enqueues no commands" % scenario_id)
		_assert(int(side_effects.get("effects_queue_size", -1)) == 0, "%s client apply enqueues no effects" % scenario_id)


func _test_determinism(result: Dictionary) -> void:
	var determinism: Dictionary = Dictionary(result.get("determinism", {}))
	_assert(bool(determinism.get("canonical_equal", false)), "Contract normalizes snapshots deterministically independent of input order")
	_assert(_is_sorted(PackedStringArray(determinism.get("unit_ids", PackedStringArray()))), "Unit snapshots are sorted by unit_id")
	_assert(_is_sorted(PackedStringArray(determinism.get("fire_event_ids", PackedStringArray()))), "Fire event snapshots are sorted by tick/sequence/event_id")
	_assert(not PackedStringArray(determinism.get("feedback_bubble_ids", PackedStringArray())).is_empty(), "Determinism probe includes feedback bubbles")
	_assert(Array(determinism.get("large_payload_offenders", PackedStringArray())).is_empty(), "Determinism probe strips raw text/path asset payloads")


func _test_frequency_plan(result: Dictionary) -> void:
	var plan: Dictionary = Dictionary(result.get("frequency_plan", {}))
	_assert(PackedStringArray(plan.get("every_snapshot", PackedStringArray())).has("units.position"), "Frequency plan keeps unit positions in every snapshot")
	_assert(PackedStringArray(plan.get("event_or_delta_candidates", PackedStringArray())).has("fire_events"), "Frequency plan marks fire events as event/delta candidates")
	_assert(PackedStringArray(plan.get("event_or_delta_candidates", PackedStringArray())).has("feedback_bubbles"), "Frequency plan marks feedback bubbles as event/delta candidates")
	_assert(PackedStringArray(plan.get("id_only_fields", PackedStringArray())).has("muzzle_id"), "Frequency plan keeps muzzle visuals as IDs")
	_assert(PackedStringArray(plan.get("id_only_fields", PackedStringArray())).has("bubble_id"), "Frequency plan keeps bubbles as IDs")
	_assert(String(plan.get("client_viewer_boundary", "")).contains("no_commands"), "Frequency plan documents no-command viewer boundary")


func _test_report_exists() -> void:
	var report: String = _read_text(REPORT_PATH)
	_assert(not report.is_empty(), "Multiplayer snapshot performance report exists")
	for required_text in ["TASK_221", "Build", "Apply", "JSON", "ID-only", "Network-Profiler"]:
		_assert(report.contains(required_text), "Report documents '%s'" % required_text)


func _stat_under_budget(stat: Dictionary, budget: float) -> bool:
	return int(stat.get("count", 0)) > 0 and float(stat.get("p99", budget + 1.0)) < budget


func _is_sorted(values: PackedStringArray) -> bool:
	var copy: PackedStringArray = PackedStringArray(values)
	copy.sort()
	return copy == values


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
