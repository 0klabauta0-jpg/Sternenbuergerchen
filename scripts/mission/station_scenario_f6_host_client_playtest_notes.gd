class_name StationScenarioF6HostClientPlaytestNotes
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_scenario_f6_host_client_playtest_notes.v1"
const EXPECTED_DRILL_SCHEMA: String = "sternenbuergerchen.station_route_one_screen_scenario_drill.v1"
const DEFAULT_DRILL_MANIFEST_PATH: String = "tmp/station_route_one_screen_multiplayer_drill.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_scenario_f6_host_client_playtest_notes.json"

const REQUIRED_CHECK_IDS: Array[String] = [
	"playtest_done",
	"real_f6_window_reviewed",
	"host_client_two_window_reviewed",
	"aa_door_com_cargo_route_readable",
	"door_computer_cargo_cues_obvious",
	"fireteam_orders_feel_fast",
	"performance_feels_fast",
	"no_hud_overlap_blocks_map",
	"wrong_team_or_bravo_context_clear",
]

const ISSUE_FLAG_IDS: Array[String] = [
	"needs_route_readability_polish",
	"needs_hud_overlap_polish",
	"needs_performance_pass",
	"needs_host_client_sync_fix",
	"needs_command_feedback_polish",
	"needs_old_harness_modernization",
]

const HOMEBASE_RECAPTURE_CHECKS: Array[Dictionary] = [
	{"id": "cargo_end_reached", "label": "Cargo-Ende erreicht"},
	{"id": "debrief_visible_after_cargo", "label": "Debrief nach Cargo sichtbar"},
	{"id": "return_homebase_clicked", "label": "Return-to-Homebase ausgefuehrt"},
	{"id": "homebase_summary_mentions_station_drill", "label": "Homebase-Summary nennt Station Drill"},
	{"id": "homebase_return_panel_title_visible", "label": "Return-Panel-Titel ist sichtbar"},
	{"id": "homebase_return_panel_action_visible", "label": "Return-Panel-Aktionszeile ist sichtbar"},
	{"id": "homebase_return_panel_chips_visible", "label": "Return-Panel-Step-Chips sind sichtbar"},
	{"id": "homebase_return_panel_matches_task_755", "label": "Return-Panel entspricht TASK_755"},
	{"id": "homebase_next_sortie_line_matches_task_749", "label": "Next-Sortie-Zeile entspricht TASK_749"},
	{"id": "old_debug_next_sortie_markers_absent", "label": "Alte englische Debug-Marker fehlen"},
	{"id": "performance_feels_fast", "label": "Homebase-Return fuehlt sich performant an"},
	{"id": "workbench_notes_exported", "label": "Workbench-Notizen exportiert"},
]


static func build_snapshot(drill_manifest: Dictionary = {}, existing_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	_add_drill_findings(findings, drill_manifest)
	var recapture_findings: Dictionary = Dictionary(options.get("recapture_findings", {}))
	var recapture_evidence: Dictionary = _build_recapture_evidence(recapture_findings, options)
	var homebase_recapture_review: Dictionary = _build_homebase_recapture_review(recapture_evidence, existing_notes)
	var homebase_recapture_findings: Dictionary = _build_homebase_recapture_findings(homebase_recapture_review)
	var homebase_recapture_findings_refresh: Dictionary = _build_homebase_recapture_findings_refresh(homebase_recapture_review, recapture_evidence)
	var homebase_return_acceptance_review: Dictionary = _build_homebase_return_acceptance_review(homebase_recapture_findings_refresh)
	var required_checks: Array = _build_required_checks(existing_notes)
	var issue_flags: Array = _build_issue_flags(existing_notes)
	var completed_check_count: int = _count_completed_checks(required_checks)
	var active_issue_count: int = _count_active_flags(issue_flags)
	var playtest_done: bool = _read_bool(existing_notes, "station_scenario_playtest.playtest_done")
	var rating: String = _read_choice(existing_notes, "station_scenario_playtest.rating", "open")
	var blocker_count: int = _count_findings_by_severity(findings, "blocker")
	var status: String = _build_status(blocker_count, playtest_done, active_issue_count, rating)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_727",
		"runtime_authority": "manual playtest notes over TASK_726 station scenario drill",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_review_required": true,
		"manual_review_done": playtest_done,
		"playtest_done": playtest_done,
		"status": status,
		"rating": rating,
		"source_drill_schema": String(drill_manifest.get("schema", "")),
		"source_drill_status": String(drill_manifest.get("status", "")),
		"source_drill_task_id": String(drill_manifest.get("task_id", "")),
		"source_drill_scenario_path": String(drill_manifest.get("scenario_path", "data/mission_scenarios/station_route_one_screen_multiplayer_drill.json")),
		"source_drill_manifest_path": String(options.get("drill_manifest_path", DEFAULT_DRILL_MANIFEST_PATH)),
		"recapture_evidence": recapture_evidence,
		"recapture_ready_for_workbench": bool(recapture_evidence.get("ready_for_workbench", false)),
		"source_recapture_manifest_path": String(recapture_evidence.get("manifest_path", "")),
		"homebase_recapture_review": homebase_recapture_review,
		"homebase_recapture_review_status": String(homebase_recapture_review.get("status", "")),
		"homebase_recapture_findings": homebase_recapture_findings,
		"homebase_recapture_findings_status": String(homebase_recapture_findings.get("status", "")),
		"homebase_recapture_findings_refresh": homebase_recapture_findings_refresh,
		"homebase_recapture_findings_refresh_status": String(homebase_recapture_findings_refresh.get("status", "")),
		"homebase_return_acceptance_review": homebase_return_acceptance_review,
		"homebase_return_acceptance_status": String(homebase_return_acceptance_review.get("status", "")),
		"report_path": String(options.get("report_path", DEFAULT_REPORT_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_MANIFEST_PATH)),
		"required_checks": required_checks,
		"required_check_count": required_checks.size(),
		"completed_check_count": completed_check_count,
		"issue_flags": issue_flags,
		"active_issue_count": active_issue_count,
		"findings": findings,
		"blocking_issue_count": blocker_count,
		"summary": _build_summary(status, completed_check_count, required_checks.size(), active_issue_count),
		"recommended_next_task": _recommended_next_task(status),
	}


static func _build_recapture_evidence(recapture_findings: Dictionary, options: Dictionary) -> Dictionary:
	var manifest_path: String = String(options.get("recapture_manifest_path", "tmp/station_scenario_identity_cue_recapture_findings.json"))
	var status: String = String(recapture_findings.get("status", ""))
	var real_run_done: bool = bool(recapture_findings.get("real_run_done", false))
	var host_crop_ready: bool = bool(recapture_findings.get("host_crop_ready", false))
	var client_crop_ready: bool = bool(recapture_findings.get("client_crop_ready", false))
	var cue_visible: bool = bool(recapture_findings.get("cue_visible", false))
	var future_blocker_hidden: bool = bool(recapture_findings.get("future_blocker_hidden_in_display", false))
	var ready_for_workbench: bool = real_run_done and host_crop_ready and client_crop_ready and cue_visible and future_blocker_hidden
	var homebase_task_id: String = String(recapture_findings.get("station_homebase_host_client_recapture_task_id", ""))
	var homebase_packet_path: String = String(recapture_findings.get("station_homebase_host_client_recapture_packet_path", ""))
	var homebase_expected_line: String = String(recapture_findings.get("station_homebase_expected_readiness_line", ""))
	var homebase_summary_fragment: String = String(recapture_findings.get("station_homebase_expected_summary_fragment", ""))
	var homebase_return_panel_task_id: String = String(recapture_findings.get("station_homebase_return_panel_polish_task_id", ""))
	var homebase_return_panel_style_id: String = String(recapture_findings.get("station_homebase_expected_return_panel_style_id", ""))
	var homebase_return_panel_title: String = String(recapture_findings.get("station_homebase_expected_return_panel_title", ""))
	var homebase_return_panel_action: String = String(recapture_findings.get("station_homebase_expected_return_panel_action", ""))
	var homebase_return_panel_chip_count: int = int(recapture_findings.get("station_homebase_expected_return_panel_chip_count", 0))
	var homebase_return_panel_step_labels: Array = _array_from_variant(recapture_findings.get("station_homebase_expected_return_panel_step_labels", []))
	var homebase_forbidden_markers: Array = _array_from_variant(recapture_findings.get("station_homebase_forbidden_debug_fragments", []))
	var homebase_manual_checks: Array = _array_from_variant(recapture_findings.get("station_homebase_recapture_manual_checks", []))
	var homebase_review_required: bool = bool(recapture_findings.get("station_homebase_recapture_review_required", false))
	var homebase_review_done: bool = bool(recapture_findings.get("station_homebase_recapture_review_done", false))
	var return_panel_evidence_ready: bool = homebase_return_panel_task_id == "TASK_755" and not homebase_return_panel_style_id.is_empty() and not homebase_return_panel_title.is_empty() and not homebase_return_panel_action.is_empty() and homebase_return_panel_chip_count >= 5 and not homebase_return_panel_step_labels.is_empty()
	var homebase_ready_for_workbench: bool = not homebase_task_id.is_empty() and not homebase_packet_path.is_empty() and not homebase_expected_line.is_empty() and not homebase_summary_fragment.is_empty() and return_panel_evidence_ready and not homebase_forbidden_markers.is_empty() and not homebase_manual_checks.is_empty() and homebase_review_required and not homebase_review_done
	return {
		"schema": String(recapture_findings.get("schema", "")),
		"task_id": String(recapture_findings.get("task_id", "")),
		"manifest_path": manifest_path,
		"status": status,
		"real_run_done": real_run_done,
		"host_crop_ready": host_crop_ready,
		"client_crop_ready": client_crop_ready,
		"host_crop_path": String(recapture_findings.get("host_crop_path", "tmp/host_client_two_window_host_review.png")),
		"client_crop_path": String(recapture_findings.get("client_crop_path", "tmp/host_client_two_window_client_review.png")),
		"cue_visible": cue_visible,
		"identity_text": String(recapture_findings.get("identity_text", "")),
		"display_route_line": String(recapture_findings.get("display_route_line", "")),
		"future_blocker_hidden_in_display": future_blocker_hidden,
		"ready_for_workbench": ready_for_workbench,
		"homebase_recapture_task_id": homebase_task_id,
		"homebase_recapture_packet_path": homebase_packet_path,
		"homebase_expected_summary_fragment": homebase_summary_fragment,
		"homebase_expected_readiness_line": homebase_expected_line,
		"homebase_return_panel_polish_task_id": homebase_return_panel_task_id,
		"homebase_return_panel_style_id": homebase_return_panel_style_id,
		"homebase_return_panel_title": homebase_return_panel_title,
		"homebase_return_panel_action": homebase_return_panel_action,
		"homebase_return_panel_chip_count": homebase_return_panel_chip_count,
		"homebase_return_panel_step_labels": homebase_return_panel_step_labels,
		"homebase_return_panel_evidence_ready": return_panel_evidence_ready,
		"homebase_forbidden_debug_fragments": homebase_forbidden_markers,
		"homebase_recapture_manual_checks": homebase_manual_checks,
		"homebase_recapture_review_required": homebase_review_required,
		"homebase_recapture_review_done": homebase_review_done,
		"homebase_recapture_ready_for_workbench": homebase_ready_for_workbench,
		"manual_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _array_from_variant(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return Array(value).duplicate()
	if typeof(value) == TYPE_PACKED_STRING_ARRAY:
		var result: Array = []
		for entry in PackedStringArray(value):
			result.append(entry)
		return result
	if typeof(value) == TYPE_STRING:
		var text: String = String(value)
		if text.is_empty():
			return []
		var parts: PackedStringArray = text.split(",", false)
		var result: Array = []
		for part in parts:
			var trimmed: String = String(part).strip_edges()
			if not trimmed.is_empty():
				result.append(trimmed)
		return result
	return []


static func _build_homebase_recapture_review(recapture_evidence: Dictionary, existing_notes: Dictionary) -> Dictionary:
	var evidence_ready: bool = bool(recapture_evidence.get("homebase_recapture_ready_for_workbench", false))
	var manual_done: bool = _read_bool(existing_notes, "station_scenario_playtest.homebase_recapture.manual_review_done")
	var checks: Array = []
	var missing_check_ids: Array[String] = []
	for check_def in HOMEBASE_RECAPTURE_CHECKS:
		var check: Dictionary = Dictionary(check_def)
		var id: String = String(check.get("id", ""))
		var checked: bool = _read_bool(existing_notes, "station_scenario_playtest.homebase_recapture.%s" % id)
		checks.append({
			"id": id,
			"label": String(check.get("label", id)),
			"checked": checked,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
		if not checked:
			missing_check_ids.append(id)
	var status: String = "missing_homebase_recapture_prefill"
	if evidence_ready and not manual_done:
		status = "needs_homebase_recapture_review"
	elif evidence_ready and manual_done and not missing_check_ids.is_empty():
		status = "needs_homebase_recapture_completion"
	elif evidence_ready and manual_done and missing_check_ids.is_empty():
		status = "ready_for_homebase_findings"
	return {
		"schema": "sternenbuergerchen.station_homebase_recapture_review_gate.v1",
		"task_id": "TASK_753",
		"source_task_id": "TASK_752",
		"status": status,
		"evidence_ready": evidence_ready,
		"manual_review_required": true,
		"manual_review_done": manual_done,
		"required_checks": checks,
		"required_check_count": checks.size(),
		"completed_check_count": checks.size() - missing_check_ids.size(),
		"missing_check_ids": missing_check_ids,
		"ready_for_findings": status == "ready_for_homebase_findings",
		"recommended_next_task": _recommended_homebase_recapture_next_task(status),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _recommended_homebase_recapture_next_task(status: String) -> String:
	if status == "missing_homebase_recapture_prefill":
		return "TASK_752 - rerun Station Homebase Recapture Workbench Prefill"
	if status == "needs_homebase_recapture_review":
		return "TASK_753 - run Station Homebase Recapture Workbench review"
	if status == "needs_homebase_recapture_completion":
		return "TASK_753 - complete missing Homebase recapture checks"
	return "TASK_754 - Station Homebase Recapture Findings"


static func _build_homebase_recapture_findings(homebase_review: Dictionary) -> Dictionary:
	var review_status: String = String(homebase_review.get("status", ""))
	var missing_check_ids: Array = _array_from_variant(homebase_review.get("missing_check_ids", []))
	var status: String = "blocked_missing_real_homebase_review"
	var summary: String = "Echter Homebase-Recapture-Review ist noch offen."
	var recommended_next: String = "TASK_753 - run Station Homebase Recapture Workbench review"
	var findings: Array = []
	if review_status == "needs_homebase_recapture_completion":
		status = "needs_review_completion"
		summary = "Homebase-Recapture-Review ist angefangen, aber Pflichtchecks fehlen."
		recommended_next = "TASK_753 - complete missing Homebase recapture checks"
		findings.append(_finding("missing_homebase_recapture_checks", "blocker", "Homebase-Recapture-Review ist unvollstaendig: %s" % ", ".join(PackedStringArray(missing_check_ids)), recommended_next))
	elif review_status == "ready_for_homebase_findings":
		status = "ready_for_homebase_panel_polish"
		summary = "Homebase-Recapture ist vollstaendig geprueft; naechster sinnvoller Griff ist sichtbarer Panel-Polish."
		recommended_next = "TASK_755 - Station Homebase Return Panel Polish"
		findings.append(_finding("homebase_return_panel_polish_ready", "followup", "Cargo -> Debrief -> Homebase ist reviewbar; naechster Polish soll den Return-Moment sichtbarer und spielbarer machen.", recommended_next))
	else:
		findings.append(_finding("real_homebase_recapture_review_missing", "blocker", "Ohne echten Workbench-Export darf kein Homebase-Recapture-Polish als belegt gelten.", recommended_next))
	return {
		"schema": "sternenbuergerchen.station_homebase_recapture_findings.v1",
		"task_id": "TASK_754",
		"source_task_id": "TASK_753",
		"status": status,
		"source_review_status": review_status,
		"summary": summary,
		"missing_check_ids": missing_check_ids,
		"finding_count": findings.size(),
		"findings": findings,
		"recommended_next_task": recommended_next,
		"ready_for_runtime_polish": status == "ready_for_homebase_panel_polish",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
	}


static func _build_homebase_recapture_findings_refresh(homebase_review: Dictionary, recapture_evidence: Dictionary) -> Dictionary:
	var review_status: String = String(homebase_review.get("status", ""))
	var missing_check_ids: Array = _array_from_variant(homebase_review.get("missing_check_ids", []))
	var task_756_ready: bool = String(recapture_evidence.get("homebase_return_panel_polish_task_id", "")) == "TASK_755" and bool(recapture_evidence.get("homebase_return_panel_evidence_ready", false))
	var status: String = "blocked_missing_task_756_window_review"
	var summary: String = "TASK_756-Homebase-Fensterreview ist noch offen; der Panel-Polish darf nicht als sichtbar abgenommen gelten."
	var recommended_next: String = "TASK_757 - run updated Homebase Recapture Workbench export"
	var findings: Array = []
	if review_status == "needs_homebase_recapture_completion":
		status = "needs_task_756_panel_check_completion"
		summary = "TASK_756-Review ist angefangen, aber Pflichtchecks zum Return-Panel oder Homebase-Abschluss fehlen."
		recommended_next = "TASK_757 - complete TASK_756 Homebase panel checks"
		findings.append(_finding("task_756_panel_checks_incomplete", "blocker", "Fehlende TASK_756-Checks: %s" % ", ".join(PackedStringArray(missing_check_ids)), recommended_next))
	elif review_status == "ready_for_homebase_findings":
		status = "ready_for_homebase_acceptance_review"
		summary = "TASK_756-Review ist vollstaendig; naechster sinnvoller Schritt ist Acceptance statt weiterer Panel-Polish."
		recommended_next = "TASK_758 - Station Homebase Return Acceptance Review"
		findings.append(_finding("task_756_ready_for_acceptance_review", "followup", "Cargo -> Debrief -> Homebase inklusive TASK_755-Return-Panel ist geprueft; jetzt eng akzeptieren oder echte Restreibung schneiden.", recommended_next))
	else:
		findings.append(_finding("task_756_real_window_review_missing", "blocker", "Der aktualisierte TASK_756-Fensterlauf wurde noch nicht als echter Workbench-Export abgeschlossen.", recommended_next))
	return {
		"schema": "sternenbuergerchen.station_homebase_recapture_findings_refresh.v1",
		"task_id": "TASK_757",
		"source_task_id": "TASK_756",
		"source_findings_task_id": "TASK_754",
		"source_panel_task_id": String(recapture_evidence.get("homebase_return_panel_polish_task_id", "")),
		"source_review_status": review_status,
		"task_756_evidence_ready": task_756_ready,
		"status": status,
		"summary": summary,
		"missing_check_ids": missing_check_ids,
		"finding_count": findings.size(),
		"findings": findings,
		"recommended_next_task": recommended_next,
		"ready_for_acceptance_review": status == "ready_for_homebase_acceptance_review",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
	}


static func _build_homebase_return_acceptance_review(findings_refresh: Dictionary) -> Dictionary:
	var refresh_status: String = String(findings_refresh.get("status", ""))
	var missing_check_ids: Array = _array_from_variant(findings_refresh.get("missing_check_ids", []))
	var status: String = "blocked_missing_homebase_return_review"
	var summary: String = "Homebase-Return-Acceptance ist blockiert, weil der echte TASK_756-Fensterreview noch fehlt."
	var recommended_next: String = "TASK_758 - run Homebase Return acceptance from real Workbench export"
	var accepted_for_next_station_slice: bool = false
	var findings: Array = []
	if refresh_status == "needs_task_756_panel_check_completion":
		status = "needs_task_756_completion"
		summary = "Homebase-Return-Acceptance wartet auf fehlende TASK_756-Panel-/Reviewchecks."
		recommended_next = "TASK_758 - complete TASK_756 checks before acceptance"
		findings.append(_finding("homebase_return_acceptance_missing_checks", "blocker", "Acceptance nicht moeglich; fehlende Checks: %s" % ", ".join(PackedStringArray(missing_check_ids)), recommended_next))
	elif refresh_status == "ready_for_homebase_acceptance_review":
		status = "accepted_for_next_station_slice"
		summary = "Homebase-Return ist eng genug fuer den naechsten Station-Slice akzeptiert; das ist keine Gesamtspiel-Abnahme."
		recommended_next = "TASK_759 - Station Slice Next Playtest Target"
		accepted_for_next_station_slice = true
		findings.append(_finding("homebase_return_slice_accepted", "accepted", "Cargo -> Debrief -> Homebase inklusive Return-Panel ist fuer den naechsten kleinen Station-Slice akzeptiert.", recommended_next))
	else:
		findings.append(_finding("homebase_return_acceptance_review_missing", "blocker", "Acceptance braucht zuerst einen echten TASK_756-Workbench-Export oder vollstaendige Review-Evidence.", recommended_next))
	return {
		"schema": "sternenbuergerchen.station_homebase_return_acceptance_review.v1",
		"task_id": "TASK_758",
		"source_task_id": "TASK_757",
		"source_recapture_task_id": String(findings_refresh.get("source_task_id", "")),
		"source_panel_task_id": String(findings_refresh.get("source_panel_task_id", "")),
		"source_refresh_status": refresh_status,
		"status": status,
		"summary": summary,
		"accepted_scope": "homebase_return_slice_only",
		"accepted_for_next_station_slice": accepted_for_next_station_slice,
		"not_full_game_acceptance": true,
		"missing_check_ids": missing_check_ids,
		"finding_count": findings.size(),
		"findings": findings,
		"recommended_next_task": recommended_next,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
	}


static func _add_drill_findings(findings: Array, drill_manifest: Dictionary) -> void:
	if drill_manifest.is_empty():
		findings.append(_finding("missing_task_726_manifest", "blocker", "TASK_726-Drillmanifest fehlt.", "TASK_726 verifier rerun"))
		return
	if String(drill_manifest.get("schema", "")) != EXPECTED_DRILL_SCHEMA:
		findings.append(_finding("unexpected_task_726_schema", "blocker", "TASK_726-Manifest hat ein unerwartetes Schema.", "TASK_726 verifier rerun"))
	if String(drill_manifest.get("task_id", "")) != "TASK_726":
		findings.append(_finding("unexpected_task_id", "blocker", "Drillmanifest gehoert nicht zu TASK_726.", "TASK_726 verifier rerun"))
	if String(drill_manifest.get("status", "")) != "ready_for_f6_host_client_playtest":
		findings.append(_finding("drill_not_ready_for_visible_playtest", "blocker", "Station-Szenario ist nicht bereit fuer sichtbaren F6/Host-Client-Playtest.", "TASK_726 repair"))
	if not bool(drill_manifest.get("read_only", false)) or bool(drill_manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("drill_manifest_not_readonly", "blocker", "TASK_726-Manifest verletzt read-only/UI-Truth-Regel.", "TASK_726 verifier rerun"))


static func _build_required_checks(existing_notes: Dictionary) -> Array:
	return [
		_check("playtest_done", "Playtest bewusst abgeschlossen und exportiert", existing_notes),
		_check("real_f6_window_reviewed", "Echtes F6-Fenster gestartet und angesehen", existing_notes),
		_check("host_client_two_window_reviewed", "Host/Client-Zwei-Fenster-Lauf angesehen", existing_notes),
		_check("aa_door_com_cargo_route_readable", "AA -> Door -> Computer -> Cargo ist ohne Debugwissen lesbar", existing_notes),
		_check("door_computer_cargo_cues_obvious", "Door-, Computer- und Cargo-Cues sind offensichtlich genug", existing_notes),
		_check("fireteam_orders_feel_fast", "Fireteam-Orders fuehlen sich zuegig an", existing_notes),
		_check("performance_feels_fast", "Fensterlauf wirkt performant genug", existing_notes),
		_check("no_hud_overlap_blocks_map", "HUD verdeckt keine wichtige Kartenentscheidung", existing_notes),
		_check("wrong_team_or_bravo_context_clear", "Wrong-Team-/Bravo-Kontext ist verstaendlich", existing_notes),
	]


static func _build_issue_flags(existing_notes: Dictionary) -> Array:
	return [
		_flag("needs_route_readability_polish", "Route/Objective-Lesbarkeit braucht Polish", existing_notes),
		_flag("needs_hud_overlap_polish", "HUD/Panel-Ueberdeckung braucht Polish", existing_notes),
		_flag("needs_performance_pass", "Performance/Gefuehl braucht eigenen Pass", existing_notes),
		_flag("needs_host_client_sync_fix", "Host/Client-Sync oder Authority-Cues brauchen Fix", existing_notes),
		_flag("needs_command_feedback_polish", "Command-/GO-/Door-Feedback braucht Polish", existing_notes),
		_flag("needs_old_harness_modernization", "Alte Pre-Boot-Harnesses sollen modernisiert werden", existing_notes),
	]


static func _check(id: String, label: String, existing_notes: Dictionary) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"checked": _read_bool(existing_notes, "station_scenario_playtest.%s" % id),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _flag(id: String, label: String, existing_notes: Dictionary) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"active": _read_bool(existing_notes, "station_scenario_playtest.issues.%s" % id),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _read_bool(notes: Dictionary, dotted_key: String) -> bool:
	var direct_value: Variant = _get_path(notes, dotted_key)
	if typeof(direct_value) == TYPE_BOOL:
		return bool(direct_value)
	var controls: Dictionary = Dictionary(notes.get("controls", {}))
	var control_value: Variant = _get_path(controls, dotted_key)
	return bool(control_value) if typeof(control_value) == TYPE_BOOL else false


static func _read_choice(notes: Dictionary, dotted_key: String, fallback: String) -> String:
	var active_choices: Dictionary = Dictionary(notes.get("active_choices", {}))
	var choice_value: Variant = _get_path(active_choices, dotted_key)
	if typeof(choice_value) == TYPE_STRING and not String(choice_value).is_empty():
		return String(choice_value)
	var direct_value: Variant = _get_path(notes, dotted_key)
	if typeof(direct_value) == TYPE_STRING and not String(direct_value).is_empty():
		return String(direct_value)
	return fallback


static func _get_path(source: Dictionary, dotted_key: String) -> Variant:
	var cursor: Variant = source
	for part in dotted_key.split("."):
		if typeof(cursor) != TYPE_DICTIONARY:
			return null
		var dict: Dictionary = Dictionary(cursor)
		if not dict.has(part):
			return null
		cursor = dict.get(part)
	return cursor


static func _build_status(blocker_count: int, playtest_done: bool, active_issue_count: int, rating: String) -> String:
	if blocker_count > 0:
		return "blocked"
	if not playtest_done:
		return "needs_visible_playtest"
	if active_issue_count > 0 or rating == "needs_polish" or rating == "blocked":
		return "needs_followup_polish"
	return "ready_for_findings"


static func _build_summary(status: String, completed_check_count: int, required_check_count: int, active_issue_count: int) -> String:
	if status == "blocked":
		return "Station-Szenario-Playtestnotizen blockiert: TASK_726-Drillmanifest fehlt oder ist ungueltig"
	if status == "needs_visible_playtest":
		return "Sichtbarer F6/Host-Client-Playtest offen, %d/%d Checks gesetzt" % [completed_check_count, required_check_count]
	if status == "needs_followup_polish":
		return "Playtestnotizen enthalten %d Follow-up-Flag(s)" % active_issue_count
	return "Playtestnotizen sind bereit fuer Findings-Verdichtung"


static func _recommended_next_task(status: String) -> String:
	if status == "blocked":
		return "TASK_726 - rerun Station Scenario runtime drill"
	if status == "needs_visible_playtest":
		return "TASK_727 - run visible F6/Host Client station playtest"
	return "TASK_728 - Station Scenario Playtest Findings"


static func _finding(id: String, severity: String, message: String, suggested_next: String) -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"message": message,
		"suggested_next": suggested_next,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _count_completed_checks(required_checks: Array) -> int:
	var count: int = 0
	for check_variant in required_checks:
		if typeof(check_variant) == TYPE_DICTIONARY and bool(Dictionary(check_variant).get("checked", false)):
			count += 1
	return count


static func _count_active_flags(issue_flags: Array) -> int:
	var count: int = 0
	for flag_variant in issue_flags:
		if typeof(flag_variant) == TYPE_DICTIONARY and bool(Dictionary(flag_variant).get("active", false)):
			count += 1
	return count


static func _count_findings_by_severity(findings: Array, severity: String) -> int:
	var count: int = 0
	for finding_variant in findings:
		if typeof(finding_variant) == TYPE_DICTIONARY and String(Dictionary(finding_variant).get("severity", "")) == severity:
			count += 1
	return count
