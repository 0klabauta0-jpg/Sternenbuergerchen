class_name ReleaseFirstExchangeExportedStatusSourceTrace
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_exported_status_source_trace_review.v1"
const TASK_ID: String = "TASK_879"
const SOURCE_TASK_ID: String = "TASK_878"
const SOURCE_VISIBLE_STATUS_TASK_ID: String = "TASK_876"
const SOURCE_RECAPTURE_TASK_ID: String = "TASK_877"
const EXPECTED_CAPTURE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_exported_status_source_trace.v1"
const EXPECTED_RUNTIME_TRACE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_exported_status_source_trace_runtime.v1"
const FIRST_GO_ARG: String = "--release-singleplayer-first-go-firefight"
const NEXT_ACTIVATION_TASK: String = "TASK_880 - Release First Exchange Exported Status Source Activation Fix"
const NEXT_OVERRIDE_TASK: String = "TASK_880 - Release First Exchange Exported HUD Refresh Override Fix"
const NEXT_VISUAL_TASK: String = "TASK_880 - Release First Exchange Fire Visual Polish"


static func build_snapshot(capture_manifest: Dictionary) -> Dictionary:
	var runtime_trace_variant: Variant = capture_manifest.get("runtime_trace", {})
	var runtime_trace: Dictionary = Dictionary(runtime_trace_variant).duplicate(true) if typeof(runtime_trace_variant) == TYPE_DICTIONARY else {}
	var capture_schema: String = String(capture_manifest.get("schema", "")).strip_edges()
	var runtime_schema: String = String(capture_manifest.get("runtime_trace_schema", runtime_trace.get("schema", ""))).strip_edges()
	var sample_count: int = int(capture_manifest.get("runtime_trace_sample_count", runtime_trace.get("sample_count", 0)))
	var samples: Array = Array(runtime_trace.get("samples", []))
	var latest_sample: Dictionary = Dictionary(runtime_trace.get("latest_sample", {})).duplicate(true)
	var activation_observed: bool = bool(capture_manifest.get("runtime_trace_activation_observed", runtime_trace.get("activation_observed", false)))
	var final_no_los_or_pressure: bool = bool(capture_manifest.get(
		"runtime_trace_final_no_los_or_contact_pressure_observed",
		runtime_trace.get("final_no_los_or_contact_pressure_observed", false)
	))
	var blockers: Array = _build_blockers(capture_manifest, capture_schema, runtime_schema, runtime_trace, sample_count)
	var issues: Array = _build_issues(activation_observed, final_no_los_or_pressure, latest_sample, blockers)
	var positives: Array = _build_positives(capture_manifest, runtime_trace, activation_observed, samples)
	var recommended_next_task: String = _recommended_next_task(activation_observed, final_no_los_or_pressure, blockers)
	var status: String = "blocked" if not blockers.is_empty() else "ready_for_followup"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_visible_status_task_id": SOURCE_VISIBLE_STATUS_TASK_ID,
		"source_recapture_task_id": SOURCE_RECAPTURE_TASK_ID,
		"capture_schema": capture_schema,
		"capture_schema_ok": capture_schema == EXPECTED_CAPTURE_SCHEMA,
		"capture_gate": String(capture_manifest.get("gate", "")),
		"branch": String(capture_manifest.get("branch", "")),
		"git_head": String(capture_manifest.get("git_head", "")),
		"launch_argument": String(capture_manifest.get("launch_argument", "")),
		"launch_argument_ok": String(capture_manifest.get("launch_argument", "")) == FIRST_GO_ARG,
		"runtime_trace_written": bool(capture_manifest.get("runtime_trace_written", false)) or not runtime_trace.is_empty(),
		"runtime_trace_schema": runtime_schema,
		"runtime_trace_schema_ok": runtime_schema == EXPECTED_RUNTIME_TRACE_SCHEMA,
		"runtime_trace_path": String(capture_manifest.get("runtime_trace_path", "")),
		"runtime_trace_sample_count": sample_count,
		"runtime_trace_stage_sequence": _stage_sequence(samples),
		"activation_observed": activation_observed,
		"final_no_los_or_contact_pressure_observed": final_no_los_or_pressure,
		"latest_stage": String(latest_sample.get("stage", "")),
		"latest_selected_fireteam_status_text": String(latest_sample.get("selected_fireteam_status_text", "")),
		"latest_mission_control_status_text": String(latest_sample.get("mission_control_status_text", "")),
		"latest_event_log_short_text": String(latest_sample.get("event_log_short_text", "")),
		"latest_status_source_active": bool(latest_sample.get("status_source_active", false)),
		"latest_combat_hud_density_status_source_active": bool(latest_sample.get("combat_hud_density_status_source_active", false)),
		"latest_combat_hud_density_compact_line": String(latest_sample.get("combat_hud_density_compact_line", "")),
		"positive_findings": positives,
		"positive_finding_count": positives.size(),
		"issues": issues,
		"issue_count": issues.size(),
		"primary_issue_id": String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else "",
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"status": status,
		"recommended_next_task": recommended_next_task,
		"recommended_direction": "fix_exported_status_source_activation_or_hud_refresh_override_from_trace_evidence",
		"avoid_next_action": "do_not_add_more_contact_fire_text_without_fixing_traced_source_loss",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


static func _build_blockers(capture_manifest: Dictionary, capture_schema: String, runtime_schema: String, runtime_trace: Dictionary, sample_count: int) -> Array:
	var blockers: Array = []
	if capture_schema != EXPECTED_CAPTURE_SCHEMA:
		blockers.append({"id": "capture_schema_mismatch", "text": "TASK_879-Capture-Schema fehlt oder passt nicht."})
	if String(capture_manifest.get("task_id", "")) != TASK_ID:
		blockers.append({"id": "capture_task_mismatch", "text": "Manifest nennt nicht TASK_879."})
	if String(capture_manifest.get("source_task_id", "")) != SOURCE_TASK_ID:
		blockers.append({"id": "source_task_mismatch", "text": "Manifest nennt nicht TASK_878 als Quelle."})
	if String(capture_manifest.get("source_visible_status_task_id", "")) != SOURCE_VISIBLE_STATUS_TASK_ID:
		blockers.append({"id": "source_visible_status_mismatch", "text": "Manifest nennt nicht TASK_876 als sichtbare Statusquelle."})
	if String(capture_manifest.get("source_recapture_task_id", "")) != SOURCE_RECAPTURE_TASK_ID:
		blockers.append({"id": "source_recapture_mismatch", "text": "Manifest nennt nicht TASK_877 als Recapture-Quelle."})
	if String(capture_manifest.get("launch_argument", "")) != FIRST_GO_ARG:
		blockers.append({"id": "launch_argument_mismatch", "text": "Manifest nutzt nicht den First-GO-Firefight-Deep-Link."})
	if String(capture_manifest.get("gate", "")) == "fail":
		blockers.append({"id": "capture_gate_failed", "text": "TASK_879-Capture meldet fail."})
	if not bool(capture_manifest.get("runtime_trace_written", false)) and runtime_trace.is_empty():
		blockers.append({"id": "runtime_trace_missing", "text": "Runtime-Trace-Datei fehlt."})
	if runtime_schema != EXPECTED_RUNTIME_TRACE_SCHEMA:
		blockers.append({"id": "runtime_trace_schema_mismatch", "text": "Runtime-Trace-Schema fehlt oder passt nicht."})
	if sample_count < 4:
		blockers.append({"id": "runtime_trace_too_few_samples", "text": "Runtime-Trace hat zu wenige Verlaufssamples."})
	var hard_failures: Array = Array(capture_manifest.get("hard_failures", []))
	if not hard_failures.is_empty():
		blockers.append({"id": "capture_hard_failures", "text": "Capture meldet Hard-Failures.", "hard_failures": hard_failures})
	return blockers


static func _build_issues(activation_observed: bool, final_no_los_or_pressure: bool, latest_sample: Dictionary, blockers: Array) -> Array:
	var issues: Array = []
	if not blockers.is_empty():
		issues.append({
			"id": "trace_not_reviewable",
			"severity": "blocking",
			"text": "TASK_879-Trace ist noch nicht belastbar reviewbar.",
			"recommended_task": "rerun TASK_879 capture",
		})
		return issues
	if not activation_observed:
		issues.append({
			"id": "exported_status_source_activation_not_observed",
			"severity": "release_readability_blocker",
			"text": "Die TASK_876-Statusquelle wurde im exportierten Runtime-Trace nicht aktiv beobachtet.",
			"recommended_task": NEXT_ACTIVATION_TASK,
		})
	elif final_no_los_or_pressure:
		issues.append({
			"id": "exported_status_source_overwritten_after_activation",
			"severity": "release_readability_blocker",
			"text": "Die TASK_876-Statusquelle wurde beobachtet, aber die finale Spielerlesung kippt wieder auf NO_LOS oder CONTACT PRESSURE.",
			"recommended_task": NEXT_OVERRIDE_TASK,
		})
	else:
		issues.append({
			"id": "exported_status_source_trace_acceptance_ready",
			"severity": "followup_visual",
			"text": "Die Trace-Evidence zeigt keine finale NO_LOS-/CONTACT-PRESSURE-Ueberschreibung; der naechste Schritt kann sichtbares Fire-Feedback polieren.",
			"recommended_task": NEXT_VISUAL_TASK,
		})
	if String(latest_sample.get("stage", "")) != "deeplink_final":
		issues.append({
			"id": "trace_latest_stage_not_final",
			"severity": "review",
			"text": "Der letzte Trace-Sample ist nicht deeplink_final; der Exportlauf sollte erneut geprueft werden.",
			"recommended_task": "rerun TASK_879 capture",
		})
	return issues


static func _build_positives(capture_manifest: Dictionary, runtime_trace: Dictionary, activation_observed: bool, samples: Array) -> Array:
	var positives: Array = []
	if String(capture_manifest.get("launch_argument", "")) == FIRST_GO_ARG:
		positives.append({"id": "first_go_firefight_deeplink_recorded", "text": "Der Exportlauf nutzt den First-GO-Firefight-Deep-Link."})
	if bool(capture_manifest.get("runtime_trace_written", false)) or not runtime_trace.is_empty():
		positives.append({"id": "runtime_trace_written", "text": "Der exportierte Runtime-Pfad hat eine Trace-Datei geschrieben."})
	if samples.size() >= 4:
		positives.append({"id": "runtime_trace_has_stage_sequence", "text": "Der Trace enthaelt mehrere zeitliche Samples."})
	if activation_observed:
		positives.append({"id": "task_876_activation_observed", "text": "TASK_876-Statusquellen-Aktivierung wurde im Trace beobachtet."})
	if bool(runtime_trace.get("read_only", false)) \
			and not bool(runtime_trace.get("ui_sets_gameplay_truth", true)) \
			and not bool(runtime_trace.get("creates_command", true)) \
			and not bool(runtime_trace.get("creates_fire_event", true)) \
			and not bool(runtime_trace.get("creates_damage_event", true)) \
			and not bool(runtime_trace.get("sets_multiplayer_truth", true)):
		positives.append({"id": "read_only_boundaries_recorded", "text": "Der Runtime-Trace deklariert read-only-Grenzen."})
	return positives


static func _recommended_next_task(activation_observed: bool, final_no_los_or_pressure: bool, blockers: Array) -> String:
	if not blockers.is_empty():
		return "TASK_879 - Rerun Exported Status Source Trace"
	if not activation_observed:
		return NEXT_ACTIVATION_TASK
	if final_no_los_or_pressure:
		return NEXT_OVERRIDE_TASK
	return NEXT_VISUAL_TASK


static func _stage_sequence(samples: Array) -> Array:
	var stages: Array = []
	for sample_variant in samples:
		var sample: Dictionary = Dictionary(sample_variant)
		stages.append(String(sample.get("stage", "")))
	return stages
