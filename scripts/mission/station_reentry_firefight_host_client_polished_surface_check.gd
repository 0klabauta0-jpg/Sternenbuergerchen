class_name StationReentryFirefightHostClientPolishedSurfaceCheck
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_firefight_host_client_polished_surface_check.v1"
const EXPECTED_SOURCE_TASK_ID: String = "TASK_785"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_reentry_firefight_host_client_polished_surface_check.json"
const INTERACTION_LINE_LIMIT: int = 140
const SUMMARY_LINE_LIMIT: int = 96
const GUARD_LINE_LIMIT: int = 48


static func build_snapshot(host_snapshot: Dictionary, client_snapshot: Dictionary, options: Dictionary = {}) -> Dictionary:
	var host_view: Dictionary = _normalize_peer_view(host_snapshot, "host", 1)
	var client_view: Dictionary = _normalize_peer_view(client_snapshot, "client", 2)
	var same_style_id: bool = _same_text(host_view, client_view, "command_surface_style_id")
	var same_priority_order: bool = _same_string_array(host_view, client_view, "surface_priority_order")
	var same_interaction_line: bool = _same_text(host_view, client_view, "interaction_line")
	var same_primary_action: bool = _same_text(host_view, client_view, "primary_action_label")
	var same_quick_actions: bool = _same_string_array(host_view, client_view, "quick_action_labels")
	var same_guard_line: bool = _same_text(host_view, client_view, "guard_line")
	var same_summary_line: bool = _same_text(host_view, client_view, "summary_line")
	var same_no_auto_command: bool = bool(host_view.get("no_auto_command_commit", false)) == bool(client_view.get("no_auto_command_commit", true))
	var same_existing_commands: bool = bool(host_view.get("uses_existing_commands_only", false)) == bool(client_view.get("uses_existing_commands_only", true))
	var peer_context_distinct: bool = int(host_view.get("peer_id", 0)) > 0 \
		and int(client_view.get("peer_id", 0)) > 0 \
		and int(host_view.get("peer_id", 0)) != int(client_view.get("peer_id", 0))
	var team_context_present: bool = not String(host_view.get("team_id", "")).is_empty() \
		and not String(client_view.get("team_id", "")).is_empty()
	var text_budget_ok: bool = _surface_text_budget_ok(host_view) and _surface_text_budget_ok(client_view)
	var source_ready: bool = _view_source_ready(host_view) and _view_source_ready(client_view)
	var read_only_sources: bool = _view_is_read_only(host_view) and _view_is_read_only(client_view)
	var checks: Array = [
		_check("source_ready", source_ready, "Host and client are built from ready TASK_785 visible findings."),
		_check("same_style_id", same_style_id, "Host and client expose the same command-surface style id."),
		_check("same_surface_priority_order", same_priority_order, "Surface row order stays identical on both peers."),
		_check("same_interaction_line", same_interaction_line, "Interaction-Line stays identical on host and client."),
		_check("same_primary_action_label", same_primary_action, "Primary action label stays identical on host and client."),
		_check("same_quick_action_labels", same_quick_actions, "Quick-Action-Rail labels stay identical on host and client."),
		_check("same_guard_line", same_guard_line, "Guard-Line stays identical on host and client."),
		_check("same_summary_line", same_summary_line, "Summary-Line stays identical on host and client."),
		_check("same_no_auto_command_commit", same_no_auto_command, "No-Auto-Command expectation stays identical."),
		_check("same_existing_commands_only", same_existing_commands, "Existing-Commands-only expectation stays identical."),
		_check("peer_context_distinct", peer_context_distinct, "Peer context stays distinct so the check is not a copied single-peer view."),
		_check("team_context_present", team_context_present, "Both views carry team context for multiplayer review."),
		_check("text_budget_ok", text_budget_ok, "Polished surface text stays compact enough for the HUD."),
		_check("read_only_sources", read_only_sources, "The host/client polished surface check reads snapshots only."),
	]
	var failed_checks: Array[String] = _failed_check_ids(checks)
	var status: String = _build_status(failed_checks)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_786",
		"source_task_id": EXPECTED_SOURCE_TASK_ID,
		"source_schemas": PackedStringArray([
			String(host_view.get("source_schema", "")),
			String(client_view.get("source_schema", "")),
		]),
		"runtime_authority": "read-only host/client comparison over TASK_785 polished command surface findings",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"host_view": host_view,
		"client_view": client_view,
		"host_summary_line": String(host_view.get("summary_line", "")),
		"client_summary_line": String(client_view.get("summary_line", "")),
		"same_style_id": same_style_id,
		"same_surface_priority_order": same_priority_order,
		"same_interaction_line": same_interaction_line,
		"same_primary_action_label": same_primary_action,
		"same_quick_action_labels": same_quick_actions,
		"same_guard_line": same_guard_line,
		"same_summary_line": same_summary_line,
		"same_no_auto_command_commit": same_no_auto_command,
		"same_existing_commands_only": same_existing_commands,
		"peer_context_distinct": peer_context_distinct,
		"team_context_present": team_context_present,
		"text_budget_ok": text_budget_ok,
		"source_ready": source_ready,
		"read_only_sources": read_only_sources,
		"sync_gate": "pass" if failed_checks.is_empty() else "review",
		"status": status,
		"ready_for_visible_host_client_polished_surface_review": failed_checks.is_empty(),
		"manual_two_window_review_required": true,
		"manual_two_window_review_done": false,
		"checks": checks,
		"failed_checks": failed_checks,
		"failed_check_count": failed_checks.size(),
		"summary": _build_summary(status, failed_checks),
		"recommended_next_task": _recommended_next_task(status, failed_checks),
		"manifest_path": String(options.get("manifest_path", DEFAULT_MANIFEST_PATH)),
	}


static func _normalize_peer_view(snapshot: Dictionary, default_role: String, default_peer_id: int) -> Dictionary:
	var role: String = String(snapshot.get("peer_role", default_role)).strip_edges().to_lower()
	if role.is_empty():
		role = default_role
	var peer_id: int = int(snapshot.get("peer_id", default_peer_id))
	var team_id: String = String(snapshot.get("team_id", "team_alpha" if role == "host" else "team_bravo")).strip_edges()
	return {
		"peer_role": role,
		"peer_id": peer_id,
		"team_id": team_id,
		"source_schema": String(snapshot.get("schema", "")).strip_edges(),
		"source_task_id": String(snapshot.get("task_id", "")).strip_edges(),
		"source_status": String(snapshot.get("status", "")).strip_edges(),
		"source_ready": bool(snapshot.get("ready_for_next_station_firefight_iteration", false)) or String(snapshot.get("status", "")) == "ready_for_next_station_firefight_iteration",
		"manual_review_done": bool(snapshot.get("manual_review_done", false)),
		"visible_playtest_done": bool(snapshot.get("visible_playtest_done", false)),
		"command_surface_style_id": String(snapshot.get("expected_command_surface_style_id", snapshot.get("command_surface_style_id", ""))).strip_edges(),
		"surface_priority_order": _normalize_string_array(Array(snapshot.get("expected_surface_priority_order", snapshot.get("surface_priority_order", [])))),
		"interaction_line": String(snapshot.get("expected_interaction_line", snapshot.get("interaction_line", ""))).strip_edges(),
		"primary_action_label": String(snapshot.get("expected_primary_action_label", snapshot.get("primary_action_label", ""))).strip_edges(),
		"quick_action_labels": _normalize_string_array(Array(snapshot.get("expected_quick_action_labels", snapshot.get("quick_action_labels", [])))),
		"guard_line": String(snapshot.get("expected_guard_line", snapshot.get("guard_line", ""))).strip_edges(),
		"summary_line": String(snapshot.get("expected_summary_line", snapshot.get("summary_line", ""))).strip_edges(),
		"no_auto_command_commit": bool(snapshot.get("expected_no_auto_command_commit", snapshot.get("no_auto_command_commit", false))),
		"uses_existing_commands_only": bool(snapshot.get("expected_uses_existing_commands_only", snapshot.get("uses_existing_commands_only", false))),
		"read_only": bool(snapshot.get("read_only", false)),
		"ui_sets_gameplay_truth": bool(snapshot.get("ui_sets_gameplay_truth", true)),
		"creates_navigation": bool(snapshot.get("creates_navigation", true)),
		"creates_command": bool(snapshot.get("creates_command", true)),
		"creates_fire_event": bool(snapshot.get("creates_fire_event", true)),
		"creates_damage_event": bool(snapshot.get("creates_damage_event", true)),
	}


static func _view_source_ready(view: Dictionary) -> bool:
	return String(view.get("source_task_id", "")) == EXPECTED_SOURCE_TASK_ID \
		and String(view.get("source_status", "")) == "ready_for_next_station_firefight_iteration" \
		and bool(view.get("source_ready", false)) \
		and bool(view.get("manual_review_done", false)) \
		and bool(view.get("visible_playtest_done", false))


static func _view_is_read_only(view: Dictionary) -> bool:
	return bool(view.get("read_only", false)) \
		and not bool(view.get("ui_sets_gameplay_truth", true)) \
		and not bool(view.get("creates_navigation", true)) \
		and not bool(view.get("creates_command", true)) \
		and not bool(view.get("creates_fire_event", true)) \
		and not bool(view.get("creates_damage_event", true))


static func _surface_text_budget_ok(view: Dictionary) -> bool:
	return String(view.get("interaction_line", "")).length() <= INTERACTION_LINE_LIMIT \
		and String(view.get("summary_line", "")).length() <= SUMMARY_LINE_LIMIT \
		and String(view.get("guard_line", "")).length() <= GUARD_LINE_LIMIT


static func _same_text(host_view: Dictionary, client_view: Dictionary, key: String) -> bool:
	return _normalize_compare_text(String(host_view.get(key, ""))) == _normalize_compare_text(String(client_view.get(key, "")))


static func _same_string_array(host_view: Dictionary, client_view: Dictionary, key: String) -> bool:
	return _normalize_string_array(Array(host_view.get(key, []))) == _normalize_string_array(Array(client_view.get(key, [])))


static func _normalize_string_array(source: Array) -> Array[String]:
	var normalized: Array[String] = []
	for value in source:
		var text: String = String(value).strip_edges()
		if text.is_empty():
			continue
		normalized.append(text)
	return normalized


static func _normalize_compare_text(value: String) -> String:
	return " ".join(value.strip_edges().to_lower().split(" ", false))


static func _build_status(failed_checks: Array[String]) -> String:
	if failed_checks.has("source_ready") or failed_checks.has("read_only_sources"):
		return "blocked_until_task_785_visible_findings_ready"
	if failed_checks.is_empty():
		return "ready_for_host_client_polished_surface_review"
	return "needs_host_client_polished_surface_alignment"


static func _recommended_next_task(status: String, failed_checks: Array[String]) -> String:
	if status == "blocked_until_task_785_visible_findings_ready":
		return "TASK_785 - Station Reentry Firefight Command Surface Visible Findings Refresh"
	if status == "needs_host_client_polished_surface_alignment":
		if failed_checks.has("peer_context_distinct") or failed_checks.has("team_context_present"):
			return "TASK_773 - Station Reentry Host Client Identity Cue Polish"
		return "TASK_770 - Station Reentry Host Client Next Order Sync"
	return "TASK_787 - Station Reentry Firefight Player Decision Readability Pass"


static func _build_summary(status: String, failed_checks: Array[String]) -> String:
	if status == "blocked_until_task_785_visible_findings_ready":
		return "TASK_786 blockiert: TASK_785-Findings sind noch nicht als sichtbarer Polished-Surface-Review bereit."
	if status == "needs_host_client_polished_surface_alignment":
		return "Polished-Surface Host/Client-Abgleich braucht Nacharbeit: %s." % ", ".join(PackedStringArray(failed_checks))
	return "Host und Client tragen dieselbe polierte Command-Surface mit getrenntem Peer-/Team-Kontext."


static func _check(id: String, passed: bool, details: String) -> Dictionary:
	return {
		"id": id,
		"passed": passed,
		"details": details,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
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
