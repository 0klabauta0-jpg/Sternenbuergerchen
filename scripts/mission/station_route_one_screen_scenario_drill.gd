class_name StationRouteOneScreenScenarioDrill
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_route_one_screen_scenario_drill.v1"
const EXPECTED_ACCEPTANCE_SCHEMA: String = "sternenbuergerchen.station_route_recapture_acceptance_review.v1"
const DEFAULT_SCENARIO_PATH: String = "data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const DEFAULT_ACCEPTANCE_MANIFEST_PATH: String = "tmp/station_route_recapture_acceptance_review.json"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_route_one_screen_multiplayer_drill.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_2026_07_01.html"

const REQUIRED_PLAY_MODES: Array[String] = ["singleplayer", "coop", "multiplayer_pvp"]
const REQUIRED_ROUTE_STEPS: Array[String] = [
	"disable_air_defense",
	"open_station_door",
	"occupy_station_computer",
	"cargo_touchdown_extract",
]
const REQUIRED_ROUTE_TOKENS: Array[String] = ["AA", "DOOR", "COM", "CARGO"]
const REQUIRED_INTERACTIONS: Array[String] = [
	"aa_shutdown_zone",
	"station_route_drill_door",
	"station_computer",
	"cargo_landing_hold",
]


static func build_snapshot(scenario: Dictionary = {}, acceptance_manifest: Dictionary = {}, runtime_result: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var findings: Array = []
	_add_acceptance_findings(findings, acceptance_manifest)
	_add_scenario_findings(findings, scenario)
	_add_runtime_findings(findings, runtime_result)

	var blocker_count: int = _count_findings_by_severity(findings, "blocker")
	var warn_count: int = _count_findings_by_severity(findings, "warn")
	var scenario_ready: bool = _scenario_ready(scenario)
	var acceptance_ready: bool = _acceptance_ready(acceptance_manifest)
	var runtime_ready: bool = _runtime_ready(runtime_result)
	var status: String = _build_status(blocker_count, scenario_ready, acceptance_ready, runtime_ready)
	var vertical_slice: Dictionary = Dictionary(scenario.get("vertical_slice", {}))
	var drill: Dictionary = Dictionary(scenario.get("scenario_drill", {}))

	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_726",
		"runtime_authority": "read-only scenario drill over existing mission runtime gates",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"scenario_path": String(options.get("scenario_path", DEFAULT_SCENARIO_PATH)),
		"acceptance_manifest_path": String(options.get("acceptance_manifest_path", DEFAULT_ACCEPTANCE_MANIFEST_PATH)),
		"manifest_path": String(options.get("manifest_path", DEFAULT_MANIFEST_PATH)),
		"report_path": DEFAULT_REPORT_PATH,
		"scenario_id": String(scenario.get("scenario_id", "")),
		"display_name": String(scenario.get("display_name", "")),
		"map_file_path": String(scenario.get("map_file_path", "")),
		"play_modes": Array(vertical_slice.get("play_modes", [])),
		"route_steps": _route_step_ids(vertical_slice),
		"route_tokens": Array(drill.get("route_tokens", [])),
		"interaction_ids": _interaction_ids(vertical_slice),
		"enemy_unit_count": _enemy_unit_count(scenario),
		"team_slot_count": Array(vertical_slice.get("team_slots", [])).size(),
		"one_screen": bool(drill.get("one_screen", false)),
		"host_client_required": bool(drill.get("host_client_required", false)),
		"npc_pressure_required": bool(drill.get("npc_pressure_required", false)),
		"acceptance_ready": acceptance_ready,
		"scenario_ready": scenario_ready,
		"runtime_ready": runtime_ready,
		"blocking_issue_count": blocker_count,
		"warning_count": warn_count,
		"findings": findings,
		"status": status,
		"summary": _build_summary(status),
		"recommended_next_task": _recommended_next_task(status),
	}


static func _add_acceptance_findings(findings: Array, manifest: Dictionary) -> void:
	if manifest.is_empty():
		findings.append(_finding("missing_acceptance_manifest", "blocker", "TASK_725-Akzeptanzmanifest fehlt.", "TASK_725 verifier rerun"))
		return
	if String(manifest.get("schema", "")) != EXPECTED_ACCEPTANCE_SCHEMA:
		findings.append(_finding("unexpected_acceptance_schema", "blocker", "TASK_725-Akzeptanzmanifest hat ein unerwartetes Schema.", "TASK_725 verifier rerun"))
	if String(manifest.get("task_id", "")) != "TASK_725":
		findings.append(_finding("unexpected_acceptance_task", "blocker", "Akzeptanzmanifest gehoert nicht zu TASK_725.", "TASK_725 verifier rerun"))
	if String(manifest.get("status", "")) != "accepted_for_next_slice":
		findings.append(_finding("station_route_not_accepted_for_next_slice", "blocker", "Station-Route-Slice ist nicht fuer den naechsten Slice akzeptiert.", "TASK_725 visual review"))
	if not bool(manifest.get("read_only", false)) or bool(manifest.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("acceptance_not_readonly", "blocker", "TASK_725 verletzt read-only/UI-Truth-Regel.", "TASK_725 verifier rerun"))


static func _add_scenario_findings(findings: Array, scenario: Dictionary) -> void:
	if scenario.is_empty():
		findings.append(_finding("missing_scenario", "blocker", "Station-Route-One-Screen-Szenario fehlt.", "TASK_726 scenario file"))
		return
	if String(scenario.get("scenario_id", "")) != "station_route_one_screen_multiplayer_drill":
		findings.append(_finding("unexpected_scenario_id", "blocker", "Szenario-ID passt nicht zu TASK_726.", "TASK_726 scenario file"))
	if String(scenario.get("map_file_path", "")) != "res://maps/station_outpost_192x192.json":
		findings.append(_finding("unexpected_map_path", "blocker", "TASK_726 muss die aktuelle Station-Outpost-Map nutzen.", "TASK_726 scenario file"))
	var vertical_slice: Dictionary = Dictionary(scenario.get("vertical_slice", {}))
	var drill: Dictionary = Dictionary(scenario.get("scenario_drill", {}))
	var play_modes: Array = Array(vertical_slice.get("play_modes", []))
	for mode in REQUIRED_PLAY_MODES:
		if not play_modes.has(mode):
			findings.append(_finding("missing_play_mode_%s" % mode, "blocker", "Szenario fehlt Play-Mode: %s." % mode, "TASK_726 scenario file"))
	if not _has_team_slot(vertical_slice, "team_alpha", "attacker"):
		findings.append(_finding("missing_alpha_attacker_slot", "blocker", "Alpha-Angreifer-Teamslot fehlt.", "TASK_726 scenario file"))
	if not _has_team_slot(vertical_slice, "team_bravo", "defender"):
		findings.append(_finding("missing_bravo_defender_slot", "blocker", "Bravo-Verteidiger-Teamslot fehlt.", "TASK_726 scenario file"))
	var route_steps: Array = _route_step_ids(vertical_slice)
	if route_steps != REQUIRED_ROUTE_STEPS:
		findings.append(_finding("route_steps_not_station_drill", "blocker", "Route muss AA -> Door -> Computer -> Cargo sein.", "TASK_726 scenario file"))
	var route_tokens: Array = Array(drill.get("route_tokens", []))
	if route_tokens != REQUIRED_ROUTE_TOKENS:
		findings.append(_finding("route_tokens_not_readable", "blocker", "Route-Tokens muessen AA/DOOR/COM/CARGO sein.", "TASK_726 scenario file"))
	var interaction_ids: Array = _interaction_ids(vertical_slice)
	for interaction_id in REQUIRED_INTERACTIONS:
		if not interaction_ids.has(interaction_id):
			findings.append(_finding("missing_interaction_%s" % interaction_id, "blocker", "Szenario fehlt Interaction: %s." % interaction_id, "TASK_726 scenario file"))
	if _enemy_unit_count(scenario) < 8:
		findings.append(_finding("npc_pressure_too_low", "warn", "NPC-/Bravo-Druck ist fuer den Drill sehr niedrig.", "TASK_727 playtest balancing"))
	if not bool(drill.get("one_screen", false)):
		findings.append(_finding("not_one_screen", "blocker", "Drill ist nicht als One-Screen markiert.", "TASK_726 scenario file"))
	if not bool(drill.get("host_client_required", false)):
		findings.append(_finding("host_client_not_required", "blocker", "Drill muss Host/Client-Pfad erfordern.", "TASK_726 scenario file"))
	if not bool(drill.get("npc_pressure_required", false)):
		findings.append(_finding("npc_pressure_not_required", "blocker", "Drill muss NPC-/Bravo-Druck verlangen.", "TASK_726 scenario file"))


static func _add_runtime_findings(findings: Array, runtime_result: Dictionary) -> void:
	if runtime_result.is_empty():
		findings.append(_finding("runtime_drill_not_run", "blocker", "Runtime-Drill wurde nicht ausgefuehrt.", "TASK_726 verifier"))
		return
	if not bool(runtime_result.get("runtime_sequence_passed", false)):
		findings.append(_finding("runtime_sequence_failed", "blocker", "AA -> Door -> Computer -> Cargo wurde in der Runtime nicht stabil nachgewiesen.", "TASK_726 verifier"))
	if not bool(runtime_result.get("door_step_visible", false)):
		findings.append(_finding("door_step_not_visible", "blocker", "Door ist nicht als eigener Runtime-Schritt sichtbar.", "TASK_726 verifier"))
	if not bool(runtime_result.get("cargo_complete", false)):
		findings.append(_finding("cargo_not_complete", "blocker", "Cargo-Abflug schliesst den Drill nicht ab.", "TASK_726 verifier"))
	if not bool(runtime_result.get("read_only", false)) or bool(runtime_result.get("ui_sets_gameplay_truth", true)):
		findings.append(_finding("runtime_result_not_readonly", "blocker", "Runtime-Ergebnis verletzt read-only/UI-Truth-Regel.", "TASK_726 verifier"))


static func _scenario_ready(scenario: Dictionary) -> bool:
	var findings: Array = []
	_add_scenario_findings(findings, scenario)
	return _count_findings_by_severity(findings, "blocker") == 0


static func _acceptance_ready(manifest: Dictionary) -> bool:
	return (
		not manifest.is_empty()
		and String(manifest.get("schema", "")) == EXPECTED_ACCEPTANCE_SCHEMA
		and String(manifest.get("task_id", "")) == "TASK_725"
		and String(manifest.get("status", "")) == "accepted_for_next_slice"
		and bool(manifest.get("read_only", false))
		and not bool(manifest.get("ui_sets_gameplay_truth", true))
	)


static func _runtime_ready(result: Dictionary) -> bool:
	return (
		not result.is_empty()
		and bool(result.get("runtime_sequence_passed", false))
		and bool(result.get("door_step_visible", false))
		and bool(result.get("cargo_complete", false))
		and bool(result.get("read_only", false))
		and not bool(result.get("ui_sets_gameplay_truth", true))
	)


static func _build_status(blocker_count: int, scenario_ready: bool, acceptance_ready: bool, runtime_ready: bool) -> String:
	if blocker_count > 0:
		return "blocked"
	if not acceptance_ready:
		return "needs_station_route_acceptance"
	if not scenario_ready:
		return "needs_scenario_authoring"
	if not runtime_ready:
		return "needs_runtime_drill"
	return "ready_for_f6_host_client_playtest"


static func _build_summary(status: String) -> String:
	if status == "blocked":
		return "Station-Route-Drill hat noch harte Vertrags- oder Runtime-Blocker"
	if status == "needs_station_route_acceptance":
		return "TASK_725-Akzeptanz muss vor dem spielbaren Drill gruen sein"
	if status == "needs_scenario_authoring":
		return "Szenario-Daten brauchen noch One-Screen-/Team-/Route-Korrektur"
	if status == "needs_runtime_drill":
		return "Szenario ist da, aber Runtime-Reihenfolge wurde noch nicht nachgewiesen"
	return "Station-Route-One-Screen-Drill ist bereit fuer sichtbaren F6/Host-Client-Playtest"


static func _recommended_next_task(status: String) -> String:
	if status == "ready_for_f6_host_client_playtest":
		return "TASK_727 - Station Scenario F6/Host Client Playtest Notes"
	if status == "needs_runtime_drill":
		return "TASK_726 - rerun Station Scenario runtime drill"
	if status == "needs_scenario_authoring":
		return "TASK_726 - fix Station Scenario drill data"
	return "TASK_725 - repair Station Route acceptance evidence"


static func _route_step_ids(vertical_slice: Dictionary) -> Array:
	var result: Array = []
	for step_variant in Array(vertical_slice.get("flow_steps", [])):
		if typeof(step_variant) != TYPE_DICTIONARY:
			continue
		result.append(String(Dictionary(step_variant).get("step_id", "")).strip_edges())
	return result


static func _interaction_ids(vertical_slice: Dictionary) -> Array:
	var result: Array = []
	for interaction_variant in Array(vertical_slice.get("interaction_points", [])):
		if typeof(interaction_variant) != TYPE_DICTIONARY:
			continue
		result.append(String(Dictionary(interaction_variant).get("interaction_id", "")).strip_edges())
	return result


static func _has_team_slot(vertical_slice: Dictionary, team_id: String, role: String) -> bool:
	for slot_variant in Array(vertical_slice.get("team_slots", [])):
		if typeof(slot_variant) != TYPE_DICTIONARY:
			continue
		var slot: Dictionary = Dictionary(slot_variant)
		if String(slot.get("team_id", "")).strip_edges() == team_id and String(slot.get("role", "")).strip_edges() == role:
			return true
	return false


static func _enemy_unit_count(scenario: Dictionary) -> int:
	var count: int = 0
	for group_variant in Array(scenario.get("enemy_groups", [])):
		if typeof(group_variant) != TYPE_DICTIONARY:
			continue
		count += Array(Dictionary(group_variant).get("enemy_ids", [])).size()
	return count


static func _finding(id: String, severity: String, message: String, suggested_next: String) -> Dictionary:
	return {
		"id": id,
		"severity": severity,
		"message": message,
		"suggested_next": suggested_next,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _count_findings_by_severity(findings: Array, severity: String) -> int:
	var count: int = 0
	for finding_variant in findings:
		if typeof(finding_variant) == TYPE_DICTIONARY and String(Dictionary(finding_variant).get("severity", "")) == severity:
			count += 1
	return count
