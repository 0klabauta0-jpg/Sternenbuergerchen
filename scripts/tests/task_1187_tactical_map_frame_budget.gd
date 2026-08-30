extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/tactical_map_frame_budget_harness.gd")

var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var options: Dictionary = {}
	if OS.get_cmdline_user_args().has("--task1187-fast"):
		options = {
			"warmup_ticks": 2,
			"physics_ticks": 6,
			"minimum_process_frames": 12,
			"minimum_process_duration_msec": 0,
			"combat_fixture_repetitions": 1,
		}
	var report: Dictionary = await HARNESS_SCRIPT.new().run(self, options)
	print("TACTICAL_MAP_FRAME_BUDGET_JSON=%s" % JSON.stringify(report))
	_assert(String(report.get("schema", "")) == "sternenbuergerchen.tactical_map_frame_budget.v1", "Harness emits the canonical tactical-map schema")
	var metadata: Dictionary = Dictionary(report.get("metadata", {}))
	_assert(String(metadata.get("status", "")) == "measured", "Harness reaches the tactical runtime")
	_assert(int(metadata.get("physics_tick_count", 0)) >= int(options.get("physics_ticks", 600)), "Harness records its requested physics ticks")
	_assert(int(metadata.get("process_frame_count", 0)) >= int(options.get("minimum_process_frames", 3600)), "Harness records its requested process frames")
	_assert(int(metadata.get("process_duration_msec", 0)) >= int(options.get("minimum_process_duration_msec", 60000)), "Harness records its requested process duration")
	var scopes: Dictionary = Dictionary(report.get("scopes", {}))
	for scope_name in ["frame_script_total_usec", "terrain.unit_proxy_sync_usec", "controller.execution_updates_usec", "combat.contact_tracking_usec", "interaction.first_visible_frame_usec"]:
		_assert(Dictionary(scopes.get(scope_name, {})).has("invocation_count"), "%s exposes an invocation counter" % scope_name)
	var budget_status: Dictionary = Dictionary(report.get("budget_status", {}))
	var frame_budget: Dictionary = Dictionary(budget_status.get("frame_script_total_usec", {}))
	_assert(Dictionary(frame_budget.get("thresholds", {})).has("p95"), "Frame-budget report loads the tactical-map p95 threshold")
	print("=== RESULTS: %d failed ===" % _failed)
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
