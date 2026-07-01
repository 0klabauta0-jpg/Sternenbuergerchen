class_name StationReentryHostClientNextOrderSync
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_host_client_next_order_sync.v1"
const DEFAULT_NEXT_ORDER_CHAR_LIMIT: int = 118
const DEFAULT_ROUTE_CUE_CHAR_LIMIT: int = 96


static func build_snapshot(host_snapshot: Dictionary, client_snapshot: Dictionary, options: Dictionary = {}) -> Dictionary:
	var host_view: Dictionary = _normalize_peer_view(host_snapshot, "host", 1)
	var client_view: Dictionary = _normalize_peer_view(client_snapshot, "client", 2)
	var next_order_char_limit: int = int(options.get("next_order_char_limit", DEFAULT_NEXT_ORDER_CHAR_LIMIT))
	var route_cue_char_limit: int = int(options.get("route_cue_char_limit", DEFAULT_ROUTE_CUE_CHAR_LIMIT))
	var same_next_order: bool = _normalize_compare_text(String(host_view.get("next_order_text", ""))) == _normalize_compare_text(String(client_view.get("next_order_text", "")))
	var same_route_line: bool = _normalize_compare_text(String(host_view.get("station_route_line", ""))) == _normalize_compare_text(String(client_view.get("station_route_line", "")))
	var same_cue_line: bool = _normalize_compare_text(String(host_view.get("station_cue_line", ""))) == _normalize_compare_text(String(client_view.get("station_cue_line", "")))
	var peer_context_distinct: bool = int(host_view.get("peer_id", 0)) > 0 \
		and int(client_view.get("peer_id", 0)) > 0 \
		and int(host_view.get("peer_id", 0)) != int(client_view.get("peer_id", 0))
	var team_context_present: bool = not String(host_view.get("team_id", "")).is_empty() \
		and not String(client_view.get("team_id", "")).is_empty()
	var text_budget_ok: bool = String(host_view.get("next_order_text", "")).length() <= next_order_char_limit \
		and String(client_view.get("next_order_text", "")).length() <= next_order_char_limit \
		and String(host_view.get("station_route_line", "")).length() <= route_cue_char_limit \
		and String(client_view.get("station_route_line", "")).length() <= route_cue_char_limit \
		and String(host_view.get("station_cue_line", "")).length() <= route_cue_char_limit \
		and String(client_view.get("station_cue_line", "")).length() <= route_cue_char_limit
	var source_ready: bool = _view_source_ready(host_view) and _view_source_ready(client_view)
	var read_only_sources: bool = _view_is_read_only(host_view) and _view_is_read_only(client_view)
	var checks: Array = [
		_check("source_ready", source_ready, "Host and client views are built from ready Reentry preview/performance snapshots."),
		_check("same_next_order", same_next_order, "Host and client expose the same visible next-order text."),
		_check("same_route_line", same_route_line, "Host and client expose the same station route line."),
		_check("same_cue_line", same_cue_line, "Host and client expose the same station cue line."),
		_check("peer_context_distinct", peer_context_distinct, "Peer context stays distinct so the sync check is not a copied single-peer view."),
		_check("team_context_present", team_context_present, "Both views carry their team context for later authority checks."),
		_check("text_budget_ok", text_budget_ok, "Next-order and route/cue lines stay compact enough for HUD use."),
		_check("read_only_sources", read_only_sources, "The sync contract reads snapshots only and creates no gameplay command."),
	]
	var failed_checks: Array[String] = _failed_check_ids(checks)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_770",
		"source_task_id": "TASK_769",
		"source_schemas": PackedStringArray([
			String(host_view.get("source_schema", "")),
			String(client_view.get("source_schema", "")),
		]),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"host_view": host_view,
		"client_view": client_view,
		"host_next_order_text": String(host_view.get("next_order_text", "")),
		"client_next_order_text": String(client_view.get("next_order_text", "")),
		"station_route_line": String(host_view.get("station_route_line", "")),
		"station_cue_line": String(host_view.get("station_cue_line", "")),
		"same_next_order": same_next_order,
		"same_route_line": same_route_line,
		"same_cue_line": same_cue_line,
		"peer_context_distinct": peer_context_distinct,
		"team_context_present": team_context_present,
		"text_budget_ok": text_budget_ok,
		"source_ready": source_ready,
		"read_only_sources": read_only_sources,
		"sync_gate": "pass" if failed_checks.is_empty() else "review",
		"ready_for_visible_host_client_playtest": failed_checks.is_empty(),
		"manual_two_window_review_required": true,
		"manual_two_window_review_done": false,
		"next_order_char_limit": next_order_char_limit,
		"route_cue_char_limit": route_cue_char_limit,
		"checks": checks,
		"failed_checks": failed_checks,
		"recommended_next_task": "TASK_771 - Station Reentry Visible Host Client Playtest Export",
	}


static func _normalize_peer_view(snapshot: Dictionary, default_role: String, default_peer_id: int) -> Dictionary:
	var role: String = String(snapshot.get("peer_role", default_role)).strip_edges().to_lower()
	if role.is_empty():
		role = default_role
	var peer_id: int = int(snapshot.get("peer_id", default_peer_id))
	var team_id: String = String(snapshot.get("team_id", "team_alpha" if role == "host" else "team_bravo")).strip_edges()
	var next_order: String = String(snapshot.get("next_order_text", snapshot.get("selected_order_text", ""))).strip_edges()
	return {
		"peer_role": role,
		"peer_id": peer_id,
		"team_id": team_id,
		"next_order_text": next_order,
		"station_route_line": String(snapshot.get("station_route_line", "")).strip_edges(),
		"station_cue_line": String(snapshot.get("station_cue_line", "")).strip_edges(),
		"source_schema": String(snapshot.get("schema", "")).strip_edges(),
		"source_task_id": String(snapshot.get("task_id", "")).strip_edges(),
		"source_gate": String(snapshot.get("performance_gate", snapshot.get("gate", snapshot.get("sync_gate", "")))).strip_edges(),
		"ready": bool(snapshot.get("ready_for_visible_playtest", snapshot.get("ready_for_visible_host_client_playtest", false))),
		"read_only": bool(snapshot.get("read_only", false)),
		"ui_sets_gameplay_truth": bool(snapshot.get("ui_sets_gameplay_truth", true)),
		"creates_command": bool(snapshot.get("creates_command", true)),
	}


static func _view_source_ready(view: Dictionary) -> bool:
	var source_gate: String = String(view.get("source_gate", "")).strip_edges().to_lower()
	return bool(view.get("ready", false)) and (source_gate.is_empty() or source_gate == "pass")


static func _view_is_read_only(view: Dictionary) -> bool:
	return bool(view.get("read_only", false)) \
		and not bool(view.get("ui_sets_gameplay_truth", true)) \
		and not bool(view.get("creates_command", true))


static func _normalize_compare_text(value: String) -> String:
	return " ".join(value.strip_edges().to_lower().split(" ", false))


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
