class_name StationReentryReleaseCandidateRealWindowFirefightSightReview
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.station_reentry_release_candidate_real_window_firefight_sight_review.v1"
const EXPECTED_SOURCE_SCHEMA: String = "sternenbuergerchen.station_reentry_release_candidate_firefight_feel_hud_polish_review.v1"
const EXPECTED_SOURCE_TASK_ID: String = "TASK_814"
const DEFAULT_RELEASE_DIR: String = "C:/dev/Sternenbuergerchen_rel"
const DEFAULT_EXE_PATH: String = "C:/dev/Sternenbuergerchen_rel/Sternenbuergerchen_rel.exe"
const DEFAULT_PCK_PATH: String = "C:/dev/Sternenbuergerchen_rel/Sternenbuergerchen_rel.pck"
const DEFAULT_MANIFEST_PATH: String = "tmp/station_reentry_release_candidate_real_window_firefight_sight_review.json"
const DEFAULT_REPORT_PATH: String = "docs/reports/project_current_state_handbook_reentry_2026_07_01.html"

const REQUIRED_CHECK_IDS: PackedStringArray = [
	"fresh_release_exe_started",
	"taskbar_shortcut_target_verified",
	"singleplayer_homebase_actionable",
	"start_mission_reachable",
	"lz_drop_preview_go_reached",
	"first_firefight_hud_readable",
	"next_player_action_understandable",
	"no_stop_homebase_blockers",
	"no_panel_overlap_visible",
	"notes_exported",
]

const ISSUE_FLAG_IDS: PackedStringArray = [
	"stale_export_or_shortcut",
	"homebase_blocked_after_singleplayer",
	"mission_start_blocked",
	"drop_or_go_confusing",
	"firefight_hud_unreadable",
	"performance_or_stutter",
	"visual_polish_needed",
]


static func build_snapshot(source_snapshot: Dictionary = {}, review_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var release_dir: String = _option_string(options, "release_dir", DEFAULT_RELEASE_DIR)
	var exe_path: String = _option_string(options, "exe_path", DEFAULT_EXE_PATH)
	var pck_path: String = _option_string(options, "pck_path", DEFAULT_PCK_PATH)
	var expected_shortcut_target: String = _option_string(options, "expected_taskbar_shortcut_target", exe_path)
	var shortcut_target: String = _option_string(options, "taskbar_shortcut_target", String(review_notes.get("taskbar_shortcut_target", "")))
	var source_valid: bool = _source_is_valid(source_snapshot)
	var source_read_only: bool = _source_is_read_only(source_snapshot)
	var source_status: String = String(source_snapshot.get("status", ""))
	var release_exe_exists: bool = FileAccess.file_exists(exe_path)
	var release_pck_exists: bool = FileAccess.file_exists(pck_path)
	var shortcut_matches_release: bool = _paths_equal(shortcut_target, expected_shortcut_target)
	var manual_review_done: bool = _read_bool(review_notes, "manual_review_done")
	var visible_window_readback_available: bool = _read_bool(review_notes, "visible_window_readback_available")
	var required_checks: Array = _build_required_checks(review_notes, release_exe_exists, release_pck_exists, shortcut_matches_release)
	var missing_check_ids: Array[String] = _missing_check_ids(required_checks)
	var issue_flags: Array = _build_issue_flags(review_notes)
	var active_issue_ids: Array[String] = _active_issue_ids(issue_flags)
	var status: String = _build_status(source_valid, source_read_only, source_status, release_exe_exists, release_pck_exists, shortcut_matches_release, manual_review_done, missing_check_ids, active_issue_ids)

	return {
		"schema": SNAPSHOT_SCHEMA,
		"task_id": "TASK_815",
		"source_task_id": EXPECTED_SOURCE_TASK_ID,
		"source_schema": String(source_snapshot.get("schema", "")),
		"source_status": source_status,
		"runtime_authority": "read-only real window sight review over TASK_814 release candidate firefight HUD polish",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"source_valid": source_valid,
		"source_read_only": source_read_only,
		"source_passed": source_status == "pass",
		"release_dir": release_dir,
		"exe_path": exe_path,
		"pck_path": pck_path,
		"release_exe_exists": release_exe_exists,
		"release_pck_exists": release_pck_exists,
		"taskbar_shortcut_target": shortcut_target,
		"expected_taskbar_shortcut_target": expected_shortcut_target,
		"taskbar_shortcut_matches_release": shortcut_matches_release,
		"manual_review_required": true,
		"manual_review_done": manual_review_done,
		"visible_window_readback_available": visible_window_readback_available,
		"firefight_hud_readout": String(source_snapshot.get("compact_line", "")),
		"player_next_action_line": String(source_snapshot.get("player_next_action_line", "")),
		"player_why_line": String(source_snapshot.get("player_why_line", "")),
		"required_real_window_checks": required_checks,
		"missing_check_ids": missing_check_ids,
		"issue_flags": issue_flags,
		"active_issue_ids": active_issue_ids,
		"active_issue_count": active_issue_ids.size(),
		"review_notes": review_notes.duplicate(true),
		"status": status,
		"summary": _build_summary(status, missing_check_ids, active_issue_ids),
		"recommended_next_task": _recommended_next_task(status, active_issue_ids),
		"report_path": _option_string(options, "report_path", DEFAULT_REPORT_PATH),
		"manifest_path": _option_string(options, "manifest_path", DEFAULT_MANIFEST_PATH),
	}


static func write_manifest(path: String = DEFAULT_MANIFEST_PATH, source_snapshot: Dictionary = {}, review_notes: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var merged_options: Dictionary = options.duplicate(true)
	merged_options["manifest_path"] = path
	var snapshot: Dictionary = build_snapshot(source_snapshot, review_notes, merged_options)
	var dir_path: String = path.get_base_dir()
	if dir_path.strip_edges() != "":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(snapshot, "\t"))
		file.close()
	return snapshot


static func _source_is_valid(source: Dictionary) -> bool:
	return not source.is_empty() \
			and String(source.get("schema", "")) == EXPECTED_SOURCE_SCHEMA \
			and String(source.get("task_id", "")) == EXPECTED_SOURCE_TASK_ID


static func _source_is_read_only(source: Dictionary) -> bool:
	return bool(source.get("read_only", false)) \
			and not bool(source.get("ui_sets_gameplay_truth", true)) \
			and not bool(source.get("creates_navigation", true)) \
			and not bool(source.get("creates_command", true)) \
			and not bool(source.get("creates_fire_event", true)) \
			and not bool(source.get("creates_damage_event", true)) \
			and not bool(source.get("sets_multiplayer_truth", true))


static func _build_required_checks(review_notes: Dictionary, exe_exists: bool, pck_exists: bool, shortcut_matches_release: bool) -> Array:
	var checks: Array = []
	for check_id in REQUIRED_CHECK_IDS:
		var passed: bool = _read_bool(review_notes, check_id)
		if check_id == "fresh_release_exe_started":
			passed = passed and exe_exists and pck_exists
		if check_id == "taskbar_shortcut_target_verified":
			passed = passed and shortcut_matches_release
		checks.append(_gate(check_id, passed, _required_check_label(check_id)))
	return checks


static func _build_issue_flags(review_notes: Dictionary) -> Array:
	var flags: Array = []
	for issue_id in ISSUE_FLAG_IDS:
		flags.append(_gate(issue_id, _read_bool(review_notes, issue_id), _issue_label(issue_id)))
	return flags


static func _build_status(source_valid: bool, source_read_only: bool, source_status: String, exe_exists: bool, pck_exists: bool, shortcut_matches_release: bool, manual_review_done: bool, missing_check_ids: Array[String], active_issue_ids: Array[String]) -> String:
	if not source_valid or not source_read_only:
		return "blocked_until_task_814"
	if source_status != "pass":
		return "blocked_until_firefight_hud_polish"
	if not exe_exists or not pck_exists:
		return "blocked_until_fresh_export"
	if not shortcut_matches_release:
		return "needs_shortcut_refresh"
	if not manual_review_done:
		return "needs_real_window_firefight_review"
	if not missing_check_ids.is_empty():
		return "needs_real_window_review_completion"
	if not active_issue_ids.is_empty():
		return "needs_visible_firefight_findings"
	return "ready_for_release_candidate_iteration"


static func _recommended_next_task(status: String, active_issue_ids: Array[String]) -> String:
	match status:
		"blocked_until_task_814":
			return "TASK_814 - Station Reentry Release Candidate Firefight Feel And HUD Polish Review"
		"blocked_until_firefight_hud_polish":
			return "TASK_814 - fix Firefight HUD polish gates"
		"blocked_until_fresh_export":
			return "Export runtime release and refresh C:/dev/Sternenbuergerchen_rel"
		"needs_shortcut_refresh":
			return "Refresh taskbar shortcut to the current release EXE"
		"needs_real_window_firefight_review":
			return "TASK_815 - run real window firefight sight review"
		"needs_real_window_review_completion":
			return "TASK_815 - complete missing real-window review checks"
		"needs_visible_firefight_findings":
			return "TASK_816 - Station Reentry Release Candidate Visible Firefight Findings"
		"ready_for_release_candidate_iteration":
			return "TASK_816 - Station Reentry Release Candidate Visible Firefight Findings"
	return "TASK_815 - Station Reentry Release Candidate Real Window Firefight Sight Review"


static func _build_summary(status: String, missing_check_ids: Array[String], active_issue_ids: Array[String]) -> String:
	match status:
		"blocked_until_task_814":
			return "Real-window sight review blockiert: TASK_814 fehlt, ist ungueltig oder nicht read-only."
		"blocked_until_firefight_hud_polish":
			return "Firefight-HUD-Polish ist noch nicht gruen."
		"blocked_until_fresh_export":
			return "Frischer Release-Export fehlt oder ist unvollstaendig."
		"needs_shortcut_refresh":
			return "Taskleisten-/Startpfad zeigt nicht auf die aktuelle Release-EXE."
		"needs_real_window_firefight_review":
			return "Echter Fensterblick ist noch nicht bewusst abgeschlossen."
		"needs_real_window_review_completion":
			return "Echter Fensterblick ist begonnen, aber Pflichtchecks fehlen: %s" % ", ".join(PackedStringArray(missing_check_ids))
		"needs_visible_firefight_findings":
			return "Echter Fensterblick hat aktive Findings: %s" % ", ".join(PackedStringArray(active_issue_ids))
		"ready_for_release_candidate_iteration":
			return "Release-EXE, Shortcut und erster Firefight-Blick sind issue-frei nachvollziehbar."
	return "Real-window sight review braucht erneute Pruefung."


static func _missing_check_ids(checks: Array) -> Array[String]:
	var missing: Array[String] = []
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			missing.append(String(check.get("id", "")))
	return missing


static func _active_issue_ids(issue_flags: Array) -> Array[String]:
	var active: Array[String] = []
	for issue_variant in issue_flags:
		var issue: Dictionary = Dictionary(issue_variant)
		if bool(issue.get("passed", false)):
			active.append(String(issue.get("id", "")))
	return active


static func _gate(id: String, passed: bool, label: String) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"passed": passed,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


static func _read_bool(source: Dictionary, key: String) -> bool:
	if not source.has(key):
		return false
	var value = source.get(key)
	if typeof(value) == TYPE_STRING:
		var text: String = String(value).strip_edges().to_lower()
		return text == "true" or text == "yes" or text == "1" or text == "ok"
	return bool(value)


static func _option_string(options: Dictionary, key: String, fallback: String) -> String:
	var value: String = String(options.get(key, fallback)).strip_edges()
	return fallback if value == "" else value


static func _paths_equal(left: String, right: String) -> bool:
	var normalized_left: String = left.replace("\\", "/").strip_edges().to_lower()
	var normalized_right: String = right.replace("\\", "/").strip_edges().to_lower()
	return normalized_left != "" and normalized_left == normalized_right


static func _required_check_label(check_id: String) -> String:
	match check_id:
		"fresh_release_exe_started":
			return "Frische Release-EXE wurde gestartet"
		"taskbar_shortcut_target_verified":
			return "Taskleisten-Ziel zeigt auf die aktuelle Release-EXE"
		"singleplayer_homebase_actionable":
			return "Einzelspieler oeffnet eine bedienbare Homebase"
		"start_mission_reachable":
			return "Start Mission ist erreichbar und nicht blockiert"
		"lz_drop_preview_go_reached":
			return "LZ, Drop, Preview und GO wurden erreicht"
		"first_firefight_hud_readable":
			return "Erster Firefight-HUD-Blick ist lesbar"
		"next_player_action_understandable":
			return "Naechster Spielergriff ist verstaendlich"
		"no_stop_homebase_blockers":
			return "Keine STOP-Blocker in Homebase/Flightdeck"
		"no_panel_overlap_visible":
			return "Keine sichtbaren Panel-Ueberlappungen"
		"notes_exported":
			return "Review-Notizen wurden exportiert"
	return check_id


static func _issue_label(issue_id: String) -> String:
	match issue_id:
		"stale_export_or_shortcut":
			return "Alter Export oder alter Shortcut sichtbar"
		"homebase_blocked_after_singleplayer":
			return "Homebase nach Einzelspieler blockiert"
		"mission_start_blocked":
			return "Missionstart blockiert"
		"drop_or_go_confusing":
			return "Drop, Preview oder GO sind unklar"
		"firefight_hud_unreadable":
			return "Firefight-HUD ist unlesbar"
		"performance_or_stutter":
			return "Performance/Stottern im Fenster"
		"visual_polish_needed":
			return "Sichtbarer Polish-Bedarf"
	return issue_id
