class_name FirstDecisionReleasePlayableSlice
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.first_decision_release_playable_slice.v1"
const TASK_ID: String = "TASK_960"
const SOURCE_TASK_ID: String = "TASK_959"
const SOURCE_SCHEMA: String = "sternenbuergerchen.first_decision_playability_smoke.v1"
const NEXT_REVIEW_TASK: String = "TASK_960 - First Decision Release Playable Slice"
const NEXT_TASK: String = "TASK_961 - Release First Decision Integrated Playtest"

const REQUIRED_SLICE_CHECKS: PackedStringArray = [
	"homebase_ready",
	"fireteam_ready",
	"flightdeck_ready",
	"dropship_payload_ready",
	"mission_loaded",
	"lz_selected",
	"drop_completed",
	"fireteam_deployed",
	"decision_preview_visible",
	"next_why_visible",
	"risk_preview_visible",
	"go_boundary_preserved",
	"go_confirmed",
	"post_go_feedback_visible",
	"command_queue_lifecycle_clear",
	"performance_hotpath_ok",
	"no_new_hud_gameplay_truth",
	"multiplayer_snapshot_boundary_preserved",
]


static func build_snapshot(source_smoke: Dictionary, release_spine_trace: Dictionary = {}) -> Dictionary:
	var blockers: Array = _build_blockers(source_smoke)
	var trace_available: bool = bool(release_spine_trace.get("trace_available", false))
	var missing_checks: Array = _missing_slice_checks(release_spine_trace)
	var issues: Array = []
	if blockers.is_empty():
		if not trace_available:
			issues.append(_issue("release_spine_trace_missing", "Der First-Decision-Release-Slice wurde noch nicht als Ablauf-Trace belegt."))
		else:
			issues = _build_trace_issues(release_spine_trace, missing_checks)
	var release_slice_playable: bool = blockers.is_empty() and trace_available and issues.is_empty() and missing_checks.is_empty()
	var gate: String = "blocked"
	var recommended_next_task: String = NEXT_REVIEW_TASK
	var recommended_direction: String = "run_first_decision_release_slice_trace"
	if blockers.is_empty():
		if release_slice_playable:
			gate = "release_slice_playable"
			recommended_next_task = NEXT_TASK
			recommended_direction = "run_integrated_first_decision_release_playtest"
		elif trace_available:
			gate = "release_slice_regression_found"
			recommended_next_task = NEXT_TASK
			recommended_direction = "fix_first_decision_release_slice_regressions"
		else:
			gate = "needs_release_slice_trace"
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_schema": String(source_smoke.get("schema", "")),
		"source_gate": String(source_smoke.get("gate", "")),
		"source_smoke_passed": bool(source_smoke.get("smoke_passed", false)),
		"launch_argument": String(release_spine_trace.get("launch_argument", "")),
		"trace_available": trace_available,
		"required_slice_checks": Array(REQUIRED_SLICE_CHECKS),
		"missing_slice_checks": missing_checks,
		"missing_slice_check_count": missing_checks.size(),
		"covered_release_stages": _covered_release_stages(release_spine_trace) if trace_available else [],
		"release_slice_playable": release_slice_playable,
		"gate": gate,
		"issues": issues,
		"issue_count": issues.size(),
		"blocking_issues": blockers,
		"blocking_issue_count": blockers.size(),
		"primary_issue_id": String(Dictionary(blockers[0]).get("id", "")) if not blockers.is_empty() else (String(Dictionary(issues[0]).get("id", "")) if not issues.is_empty() else ""),
		"recommended_next_task": recommended_next_task,
		"recommended_direction": recommended_direction,
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


static func _build_blockers(source_smoke: Dictionary) -> Array:
	var blockers: Array = []
	if String(source_smoke.get("schema", "")) != SOURCE_SCHEMA:
		blockers.append(_issue("source_schema_mismatch", "TASK_959-Smoke-Schema fehlt oder passt nicht."))
	if String(source_smoke.get("task_id", "")) != SOURCE_TASK_ID:
		blockers.append(_issue("source_task_mismatch", "Source nennt nicht TASK_959."))
	if String(source_smoke.get("gate", "")) != "smoke_passed" or not bool(source_smoke.get("smoke_passed", false)):
		blockers.append(_issue("source_smoke_not_passed", "TASK_959-Source hat den First-Decision-Smoke nicht bestanden."))
	if not bool(source_smoke.get("read_only", false)):
		blockers.append(_issue("source_not_read_only", "TASK_959-Source ist nicht read-only."))
	if bool(source_smoke.get("ui_sets_gameplay_truth", true)):
		blockers.append(_issue("source_sets_ui_gameplay_truth", "TASK_959-Source darf keine UI-Gameplay-Wahrheit setzen."))
	return blockers


static func _build_trace_issues(release_spine_trace: Dictionary, missing_checks: Array) -> Array:
	var issues: Array = []
	for check_id_variant in missing_checks:
		var check_id: String = String(check_id_variant)
		issues.append(_issue(_issue_id_for_missing_check(check_id), _text_for_missing_check(check_id)))
	if String(release_spine_trace.get("launch_argument", "")) != "--release-singleplayer-lz-drop-preview":
		issues.append(_issue("launch_argument_mismatch", "Der Slice nutzt nicht den First-Decision-LZ-Drop-Preview-Deep-Link."))
	return issues


static func _missing_slice_checks(release_spine_trace: Dictionary) -> Array:
	var missing: Array = []
	for check_id in REQUIRED_SLICE_CHECKS:
		if not bool(release_spine_trace.get(String(check_id), false)):
			missing.append(String(check_id))
	return missing


static func _covered_release_stages(release_spine_trace: Dictionary) -> Array:
	var stages: Array = []
	if bool(release_spine_trace.get("homebase_ready", false)) and bool(release_spine_trace.get("fireteam_ready", false)):
		stages.append("homebase_ready")
	if bool(release_spine_trace.get("flightdeck_ready", false)) and bool(release_spine_trace.get("dropship_payload_ready", false)):
		stages.append("flightdeck_payload")
	if bool(release_spine_trace.get("mission_loaded", false)) and bool(release_spine_trace.get("lz_selected", false)) and bool(release_spine_trace.get("drop_completed", false)):
		stages.append("mission_lz_drop")
	if bool(release_spine_trace.get("fireteam_deployed", false)) and bool(release_spine_trace.get("decision_preview_visible", false)) and bool(release_spine_trace.get("risk_preview_visible", false)):
		stages.append("first_decision_preview")
	if bool(release_spine_trace.get("go_confirmed", false)) and bool(release_spine_trace.get("post_go_feedback_visible", false)):
		stages.append("go_and_post_go_feedback")
	return stages


static func _issue_id_for_missing_check(check_id: String) -> String:
	match check_id:
		"post_go_feedback_visible":
			return "post_go_feedback_missing"
		"performance_hotpath_ok":
			return "performance_hotpath_not_ok"
		"no_new_hud_gameplay_truth":
			return "hud_gameplay_truth_risk"
		"multiplayer_snapshot_boundary_preserved":
			return "multiplayer_snapshot_boundary_risk"
		_:
			return "%s_missing" % check_id


static func _text_for_missing_check(check_id: String) -> String:
	match check_id:
		"homebase_ready":
			return "Homebase ist im Release-Slice nicht bereit."
		"fireteam_ready":
			return "Fireteam ist im Release-Slice nicht bereit."
		"flightdeck_ready":
			return "Flightdeck ist im Release-Slice nicht bereit."
		"dropship_payload_ready":
			return "Dropship-Payload ist im Release-Slice nicht bereit."
		"mission_loaded":
			return "Mission ist im Release-Slice nicht geladen."
		"lz_selected":
			return "LZ ist im Release-Slice nicht gesetzt."
		"drop_completed":
			return "Drop ist im Release-Slice nicht abgeschlossen."
		"fireteam_deployed":
			return "Fireteam ist im Release-Slice nicht deployed."
		"decision_preview_visible":
			return "First-Decision-Preview ist im Release-Slice nicht sichtbar."
		"next_why_visible":
			return "NEXT/WHY ist im Release-Slice nicht sichtbar."
		"risk_preview_visible":
			return "Risk-/Threat-Preview ist im Release-Slice nicht sichtbar."
		"go_boundary_preserved":
			return "GO-Grenze ist im Release-Slice nicht erhalten."
		"go_confirmed":
			return "GO ist im Release-Slice nicht bestaetigt."
		"post_go_feedback_visible":
			return "Nach GO fehlt sichtbares Feedback."
		"command_queue_lifecycle_clear":
			return "Command-Queue-Lifecycle ist im Release-Slice nicht klar."
		"performance_hotpath_ok":
			return "Hotpath-Ruhe ist im Release-Slice nicht belegt."
		"no_new_hud_gameplay_truth":
			return "HUD-Read-only-Grenze ist im Release-Slice nicht belegt."
		"multiplayer_snapshot_boundary_preserved":
			return "Multiplayer-Snapshot-Grenze ist im Release-Slice nicht belegt."
		_:
			return "Ein Slice-Pflichtcheck fehlt: %s." % check_id


static func _issue(issue_id: String, text: String) -> Dictionary:
	return {
		"id": issue_id,
		"text": text,
	}
