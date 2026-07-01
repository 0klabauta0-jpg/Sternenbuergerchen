class_name StationReentryNextPlayableSliceAcceptance
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_next_playable_slice_acceptance.v1"


static func build_snapshot(inputs: Dictionary = {}) -> Dictionary:
	var preview: Dictionary = Dictionary(inputs.get("preview", {}))
	var performance: Dictionary = Dictionary(inputs.get("performance", {}))
	var host_client_sync: Dictionary = Dictionary(inputs.get("host_client_sync", {}))
	var export_findings: Dictionary = Dictionary(inputs.get("export_findings", {}))
	var identity_cue: Dictionary = Dictionary(inputs.get("identity_cue", {}))
	var real_capture: Dictionary = Dictionary(inputs.get("real_capture", {}))
	var gates: Array = [
		_gate("first_preview_before_go", _preview_gate_passes(preview), "Erste Mission-Preview ist vor GO lesbar."),
		_gate("performance_feel", _performance_gate_passes(performance), "Performance-Feel-Gate ist gruen genug fuer sichtbaren Reentry."),
		_gate("host_client_sync", _host_client_sync_gate_passes(host_client_sync), "Host/Client lesen Next-Order, Route und Cue konsistent."),
		_gate("export_findings_ready", _export_findings_gate_passes(export_findings), "TASK_772-Findings sind bereit fuer die naechste Iteration."),
		_gate("identity_cue", _identity_cue_gate_passes(identity_cue), "Fireteam-Karten unterscheiden OWN/VIEW/FT ? read-only."),
		_gate("real_capture_written", _real_capture_gate_passes(real_capture), "Echter Zwei-Fenster-Re-Capture wurde geschrieben."),
	]
	var failed_gate_ids: Array[String] = _failed_gate_ids(gates)
	var status: String = _build_status(failed_gate_ids)
	var accepted: bool = status == "accepted_for_next_playable_slice"
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_774",
		"source_task_ids": ["TASK_768", "TASK_769", "TASK_770", "TASK_772", "TASK_773"],
		"accepted_scope": "station_reentry_next_playable_slice_only",
		"not_full_game_acceptance": true,
		"status": status,
		"summary": _build_summary(status, failed_gate_ids),
		"accepted_for_next_playable_slice": accepted,
		"ready_for_next_design_slice": accepted,
		"gates": gates,
		"gate_count": gates.size(),
		"passed_gate_count": gates.size() - failed_gate_ids.size(),
		"failed_gate_ids": failed_gate_ids,
		"recommended_next_task": _recommended_next_task(status, failed_gate_ids),
		"manual_long_playtest_required": true,
		"manual_long_playtest_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
	}


static func _preview_gate_passes(preview: Dictionary) -> bool:
	if preview.is_empty():
		return false
	if String(preview.get("task_id", "TASK_768")) != "TASK_768":
		return false
	if bool(preview.get("ui_sets_gameplay_truth", true)) or bool(preview.get("creates_command", true)):
		return false
	return bool(preview.get("preview_gate_ok", false)) \
		and bool(preview.get("station_context_ok", false)) \
		and String(preview.get("selected_order_text", "")).contains("PREVIEW")


static func _performance_gate_passes(performance: Dictionary) -> bool:
	if performance.is_empty():
		return false
	if String(performance.get("task_id", "TASK_769")) != "TASK_769":
		return false
	if bool(performance.get("ui_sets_gameplay_truth", true)) or bool(performance.get("creates_command", true)):
		return false
	return String(performance.get("performance_gate", "")) == "pass" \
		and bool(performance.get("ready_for_visible_playtest", false)) \
		and bool(performance.get("repeated_snapshot_budget_ok", false))


static func _host_client_sync_gate_passes(sync: Dictionary) -> bool:
	if sync.is_empty():
		return false
	if String(sync.get("task_id", "TASK_770")) != "TASK_770":
		return false
	if bool(sync.get("ui_sets_gameplay_truth", true)) or bool(sync.get("creates_command", true)):
		return false
	return String(sync.get("sync_gate", "")) == "pass" \
		and bool(sync.get("same_next_order", false)) \
		and bool(sync.get("same_route_line", false)) \
		and bool(sync.get("same_cue_line", false)) \
		and bool(sync.get("peer_context_distinct", false))


static func _export_findings_gate_passes(findings: Dictionary) -> bool:
	if findings.is_empty():
		return false
	if String(findings.get("task_id", "TASK_772")) != "TASK_772":
		return false
	if bool(findings.get("ui_sets_gameplay_truth", true)) or bool(findings.get("creates_command", true)):
		return false
	return String(findings.get("status", "")) == "ready_for_next_station_iteration" \
		and int(findings.get("active_issue_count", 0)) == 0 \
		and Array(findings.get("missing_check_ids", [])).is_empty()


static func _identity_cue_gate_passes(identity_cue: Dictionary) -> bool:
	if identity_cue.is_empty():
		return false
	if bool(identity_cue.get("ui_sets_gameplay_truth", true)) or bool(identity_cue.get("creates_command", true)):
		return false
	var relation: String = String(identity_cue.get("relation", ""))
	return String(identity_cue.get("schema", "")) == "sternenbuergerchen.station_reentry_host_client_fireteam_card_context.v1" \
		and bool(identity_cue.get("visible", false)) \
		and ["own", "foreign", "unknown"].has(relation) \
		and not String(identity_cue.get("text", "")).strip_edges().is_empty()


static func _real_capture_gate_passes(capture: Dictionary) -> bool:
	if capture.is_empty():
		return false
	if bool(capture.get("ui_sets_gameplay_truth", false)):
		return false
	return bool(capture.get("launch_requested", false)) \
		and bool(capture.get("real_run_done", false)) \
		and bool(capture.get("screenshot_written", false)) \
		and bool(capture.get("host_screenshot_written", false)) \
		and bool(capture.get("client_screenshot_written", false))


static func _gate(id: String, passed: bool, label: String) -> Dictionary:
	return {
		"id": id,
		"passed": passed,
		"label": label,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _failed_gate_ids(gates: Array) -> Array[String]:
	var failed: Array[String] = []
	for gate_variant in gates:
		if typeof(gate_variant) != TYPE_DICTIONARY:
			continue
		var gate: Dictionary = Dictionary(gate_variant)
		if not bool(gate.get("passed", false)):
			failed.append(String(gate.get("id", "")))
	return failed


static func _build_status(failed_gate_ids: Array[String]) -> String:
	if failed_gate_ids.is_empty():
		return "accepted_for_next_playable_slice"
	if failed_gate_ids.size() == 1 and failed_gate_ids.has("real_capture_written"):
		return "needs_reentry_recapture"
	if failed_gate_ids.size() > 1:
		return "blocked_until_reentry_gates_green"
	if failed_gate_ids.has("identity_cue"):
		return "needs_identity_cue_polish"
	if failed_gate_ids.has("host_client_sync") or failed_gate_ids.has("export_findings_ready"):
		return "needs_host_client_polish"
	if failed_gate_ids.has("performance_feel"):
		return "needs_performance_feel_polish"
	return "blocked_until_reentry_gates_green"


static func _build_summary(status: String, failed_gate_ids: Array[String]) -> String:
	match status:
		"accepted_for_next_playable_slice":
			return "Station-Reentry ist eng genug fuer den naechsten spielbaren Slice akzeptiert; keine Gesamtspiel-Abnahme."
		"needs_reentry_recapture":
			return "Alle technischen Gates sind gruen, aber der echte Re-Capture fehlt oder wurde nicht geschrieben."
		"needs_identity_cue_polish":
			return "Fireteam-Identity-Cue ist noch nicht eindeutig genug fuer Host/Client-Reentry."
		"needs_host_client_polish":
			return "Host/Client-Reentry-Sync oder Findings sind noch nicht gruen genug."
		"needs_performance_feel_polish":
			return "Reentry-Performance-Gefuehl ist noch nicht akzeptierbar."
	return "Station-Reentry-Acceptance blockiert; fehlende Gates: %s" % ", ".join(failed_gate_ids)


static func _recommended_next_task(status: String, failed_gate_ids: Array[String]) -> String:
	match status:
		"accepted_for_next_playable_slice":
			return "TASK_775 - Station Reentry Mission Interaction Feel Pass"
		"needs_reentry_recapture":
			return "TASK_774 - rerun short Host/Client Reentry capture"
		"needs_identity_cue_polish":
			return "TASK_773 - Station Reentry Host Client Identity Cue Polish"
		"needs_host_client_polish":
			return "TASK_770/TASK_772 - repair Host/Client sync or findings"
		"needs_performance_feel_polish":
			return "TASK_769 - Station Reentry Performance Feel Pass"
	if failed_gate_ids.has("first_preview_before_go"):
		return "TASK_768 - Station Reentry First Mission Preview Polish"
	return "TASK_774 - complete missing Reentry acceptance gates"
