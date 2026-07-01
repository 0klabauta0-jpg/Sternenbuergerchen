class_name StationReentryPerformanceFeelPass
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_performance_feel_pass.v1"
const DEFAULT_BUDGET_USEC: int = 2000000
const DEFAULT_SELECTED_ORDER_CHAR_LIMIT: int = 118
const DEFAULT_ROUTE_CUE_CHAR_LIMIT: int = 96


static func build_snapshot(preview_snapshot: Dictionary, performance_sample: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var selected_order_text: String = String(preview_snapshot.get("selected_order_text", "")).strip_edges()
	var route_line: String = String(preview_snapshot.get("station_route_line", "")).strip_edges()
	var cue_line: String = String(preview_snapshot.get("station_cue_line", "")).strip_edges()
	var risk_state: String = String(preview_snapshot.get("risk_state", "unknown")).strip_edges().to_lower()
	var selected_order_char_limit: int = int(options.get("selected_order_char_limit", DEFAULT_SELECTED_ORDER_CHAR_LIMIT))
	var route_cue_char_limit: int = int(options.get("route_cue_char_limit", DEFAULT_ROUTE_CUE_CHAR_LIMIT))
	var sample_count: int = int(performance_sample.get("sample_count", 0))
	var avg_usec: int = int(performance_sample.get("avg_usec", 0))
	var max_usec: int = int(performance_sample.get("max_usec", 0))
	var total_usec: int = int(performance_sample.get("total_usec", 0))
	var budget_avg_usec: int = int(performance_sample.get("budget_avg_usec", DEFAULT_BUDGET_USEC))
	var budget_max_usec: int = int(performance_sample.get("budget_max_usec", DEFAULT_BUDGET_USEC))
	var repeated_snapshot_budget_ok: bool = sample_count <= 0 or (avg_usec <= budget_avg_usec and max_usec <= budget_max_usec)
	var preview_gate_ok: bool = String(preview_snapshot.get("gate", "")) == "pass"
	var preview_read_only: bool = bool(preview_snapshot.get("read_only", false)) \
		and not bool(preview_snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(preview_snapshot.get("creates_command", true))
	var preview_text_ok: bool = selected_order_text.contains("PREVIEW") \
		and selected_order_text.contains("ETA") \
		and (selected_order_text.contains("RISK") or selected_order_text.contains("SAFE") or selected_order_text.contains("SUICIDAL"))
	var selected_order_budget_ok: bool = not selected_order_text.is_empty() and selected_order_text.length() <= selected_order_char_limit
	var station_context_ok: bool = bool(preview_snapshot.get("station_context_active", false)) and (not route_line.is_empty() or not cue_line.is_empty())
	var route_cue_budget_ok: bool = route_line.length() <= route_cue_char_limit and cue_line.length() <= route_cue_char_limit
	var ready: bool = repeated_snapshot_budget_ok \
		and preview_gate_ok \
		and preview_read_only \
		and preview_text_ok \
		and selected_order_budget_ok \
		and station_context_ok \
		and route_cue_budget_ok
	var checks: Array = [
		_check("preview_gate_ok", preview_gate_ok, "TASK_768 preview gate remains green."),
		_check("preview_read_only", preview_read_only, "Preview remains read-only and creates no command."),
		_check("preview_text_ok", preview_text_ok, "Selected order text names PREVIEW, ETA and risk."),
		_check("selected_order_budget_ok", selected_order_budget_ok, "Selected order text stays compact enough for the HUD."),
		_check("station_context_ok", station_context_ok, "Station route or cue remains visible in Reentry context."),
		_check("route_cue_budget_ok", route_cue_budget_ok, "Route and cue lines remain inside compact text budgets."),
		_check("repeated_snapshot_budget_ok", repeated_snapshot_budget_ok, "Repeated snapshot sample stays inside broad project budget."),
	]
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_769",
		"source_task_id": "TASK_768",
		"source_schema": String(preview_snapshot.get("schema", "")),
		"source_gate": String(preview_snapshot.get("gate", "")),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"performance_gate": "pass" if repeated_snapshot_budget_ok else "warn",
		"ready_for_visible_playtest": ready,
		"preview_gate_ok": preview_gate_ok,
		"preview_read_only": preview_read_only,
		"preview_text_ok": preview_text_ok,
		"selected_order_budget_ok": selected_order_budget_ok,
		"station_context_ok": station_context_ok,
		"route_cue_budget_ok": route_cue_budget_ok,
		"repeated_snapshot_budget_ok": repeated_snapshot_budget_ok,
		"selected_order_text": selected_order_text,
		"selected_order_char_count": selected_order_text.length(),
		"selected_order_char_limit": selected_order_char_limit,
		"station_route_line": route_line,
		"station_route_char_count": route_line.length(),
		"station_cue_line": cue_line,
		"station_cue_char_count": cue_line.length(),
		"route_cue_char_limit": route_cue_char_limit,
		"risk_state": risk_state,
		"risk_preview_text": String(preview_snapshot.get("risk_preview_text", "")).strip_edges(),
		"distance_world": float(preview_snapshot.get("distance_world", -1.0)),
		"eta_seconds_estimate": float(preview_snapshot.get("eta_seconds_estimate", -1.0)),
		"sample_count": sample_count,
		"total_usec": total_usec,
		"avg_usec": avg_usec,
		"max_usec": max_usec,
		"budget_avg_usec": budget_avg_usec,
		"budget_max_usec": budget_max_usec,
		"checks": checks,
		"failed_checks": _failed_check_ids(checks),
		"manual_profiler_required": true,
		"manual_profiler_done": false,
		"recommended_next_task": "TASK_770 - Station Reentry Host Client Next Order Sync",
	}


static func _check(id: String, passed: bool, details: String) -> Dictionary:
	return {
		"id": id,
		"passed": passed,
		"details": details,
	}


static func _failed_check_ids(checks: Array) -> Array[String]:
	var failed: Array[String] = []
	for check_variant in checks:
		if typeof(check_variant) != TYPE_DICTIONARY:
			continue
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed.append(String(check.get("id", "")))
	return failed
