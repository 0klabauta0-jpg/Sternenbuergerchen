extends SceneTree

const Findings := preload("res://scripts/mission/release_first_exchange_combat_focal_elegance_visual_findings.gd")

const TASK_PATH := "res://docs/tasks/TASK_900_release_first_exchange_combat_focal_elegance_visual_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH := "res://docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_combat_focal_elegance_visual_findings.gd"
const SOURCE_MANIFEST_PATH := "res://tmp/release_first_exchange_combat_focal_elegance_real_window_recapture.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_combat_focal_elegance_visual_findings.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_combat_focal_elegance_visual_findings.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_exchange_combat_focal_elegance_real_window_recapture.v1"
const ELEGANCE_SCHEMA := "sternenbuergerchen.release_first_exchange_combat_focal_elegance_polish.v1"
const ELEGANCE_STYLE_ID := "task_898_release_first_exchange_combat_focal_elegance_v1"
const FOCAL_STYLE_ID := "task_895_release_first_exchange_world_combat_focal_hierarchy_v1"
const WORLD_RECAPTURE_SCHEMA := "sternenbuergerchen.release_first_exchange_world_combat_focal_real_window_recapture.v1"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_TASK := "TASK_901 - Release First Exchange Combat Marker Scale And World Noise Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_900 Release First Exchange Combat Focal Elegance Visual Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_manifest_blocks()
	_test_visual_findings_from_review_notes()
	_test_clean_notes_can_accept()
	_test_optional_actual_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_900_release_first_exchange_combat_focal_elegance_visual_findings: FAILED")
		quit(1)
		return
	print("TASK_900_release_first_exchange_combat_focal_elegance_visual_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_900 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_900 analyzer exists")
	_assert(task_text.contains("Release First Exchange Combat Focal Elegance Visual Findings"), "Task names TASK_900")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_901 follow-up")
	_assert(status_text.contains("TASK_900 - Release First Exchange Combat Focal Elegance Visual Findings"), "Implementation status tracks TASK_900")
	_assert(roadmap_text.contains("TASK_900 - Release First Exchange Combat Focal Elegance Visual Findings (implementiert)"), "Roadmap marks TASK_900 implemented")
	_assert(roadmap_text.contains(NEXT_TASK), "Roadmap names TASK_901 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Combat-Focal-Elegance-Visual-Findings (TASK_900)"), "Contract documents TASK_900")
	_assert(report_text.contains("TASK_900") and report_text.contains("TASK_901"), "HTML report tracks TASK_900 and TASK_901")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_900 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_900\""), "Analyzer writes TASK_900 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_899\""), "Analyzer links TASK_899")
	_assert(service_text.contains("SOURCE_ELEGANCE_TASK_ID: String = \"TASK_898\""), "Analyzer links TASK_898")
	_assert(service_text.contains("SOURCE_FOCAL_TASK_ID: String = \"TASK_895\""), "Analyzer links TASK_895")
	_assert(service_text.contains("SOURCE_FINDINGS_TASK_ID: String = \"TASK_897\""), "Analyzer links TASK_897")
	_assert(service_text.contains("target_halo_still_reads_marker_disc"), "Analyzer names marker-like halo issue")
	_assert(service_text.contains("grid_world_noise_competes_with_focal_signal"), "Analyzer names grid/world-noise issue")
	_assert(service_text.contains("source_to_target_relationship_still_not_elegant"), "Analyzer names source-target elegance issue")
	_assert(service_text.contains("do_not_add_more_contact_fire_text_or_reopen_damage_logic"), "Analyzer rejects text/damage churn")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer declares no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth")
	_assert(service_text.contains("\"updates_shortcuts\": false"), "Analyzer updates no shortcuts")


func _test_missing_manifest_blocks() -> void:
	var snapshot: Dictionary = Findings.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source manifest blocks TASK_900")
	_assert(blocker_ids.has("capture_schema_mismatch"), "Missing manifest reports schema mismatch")
	_assert(blocker_ids.has("capture_task_mismatch"), "Missing manifest reports TASK_899 mismatch")
	_assert(blocker_ids.has("source_elegance_task_mismatch"), "Missing manifest reports TASK_898 mismatch")
	_assert(blocker_ids.has("source_focal_task_mismatch"), "Missing manifest reports TASK_895 mismatch")
	_assert(blocker_ids.has("source_findings_task_mismatch"), "Missing manifest reports TASK_897 mismatch")
	_assert(blocker_ids.has("source_world_recapture_task_mismatch"), "Missing manifest reports TASK_896 mismatch")
	_assert(blocker_ids.has("elegance_style_mismatch"), "Missing manifest reports TASK_898 style mismatch")
	_assert(blocker_ids.has("focal_style_mismatch"), "Missing manifest reports TASK_895 style mismatch")
	_assert(blocker_ids.has("manual_visual_review_missing"), "Missing notes report manual review missing")
	_assert(blocker_ids.has("correct_window_content_not_confirmed"), "Missing notes report window confirmation missing")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot remains read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no commands")


func _test_visual_findings_from_review_notes() -> void:
	var snapshot: Dictionary = Findings.build_snapshot(_good_manifest(), _review_notes_with_issues())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var positive_ids: Array = _issue_ids(Array(snapshot.get("positive_findings", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_900")
	_assert(String(snapshot.get("task_id", "")) == "TASK_900", "Snapshot task id matches TASK_900")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_899", "Snapshot links TASK_899")
	_assert(String(snapshot.get("source_elegance_task_id", "")) == "TASK_898", "Snapshot links TASK_898")
	_assert(String(snapshot.get("source_focal_task_id", "")) == "TASK_895", "Snapshot links TASK_895")
	_assert(String(snapshot.get("source_findings_task_id", "")) == "TASK_897", "Snapshot links TASK_897")
	_assert(String(snapshot.get("source_world_recapture_task_id", "")) == "TASK_896", "Snapshot links TASK_896")
	_assert(String(snapshot.get("status", "")) == "ready_for_marker_scale_world_noise_polish", "Findings recommend marker/world-noise polish")
	_assert(bool(snapshot.get("final_source_contact_fire", false)), "Snapshot records final source CONTACT FIRE")
	_assert(bool(snapshot.get("manual_visual_review_done", false)), "Snapshot records manual review")
	_assert(not bool(snapshot.get("player_readability_ok", true)), "Snapshot does not accept readability")
	_assert(positive_ids.has("final_source_contact_fire_clean"), "Snapshot keeps source positive")
	_assert(positive_ids.has("trusted_window_handle_capture"), "Snapshot keeps trusted capture positive")
	_assert(positive_ids.has("contact_fire_hud_surfaces_present"), "Snapshot records CONTACT FIRE surfaces")
	_assert(positive_ids.has("event_log_contact_fire_visible"), "Snapshot records event-log contact fire")
	_assert(positive_ids.has("world_fire_label_visible"), "Snapshot records FIRE world label")
	_assert(positive_ids.has("elegant_lane_visible"), "Snapshot records elegant lane")
	_assert(positive_ids.has("source_glow_visible"), "Snapshot records source glow")
	_assert(positive_ids.has("target_halo_visible"), "Snapshot records target halo")
	_assert(issue_ids.has("target_halo_still_reads_marker_disc"), "Snapshot records marker-like target halo issue")
	_assert(issue_ids.has("grid_world_noise_competes_with_focal_signal"), "Snapshot records grid/world-noise issue")
	_assert(issue_ids.has("source_to_target_relationship_still_not_elegant"), "Snapshot records source-target issue")
	_assert(issue_ids.has("fire_label_and_halo_overlap_attention"), "Snapshot records FIRE label/halo attention issue")
	_assert(issue_ids.has("bottom_hud_still_competes_with_world_combat"), "Snapshot records bottom HUD competition")
	_assert(String(snapshot.get("primary_issue_id", "")) == "target_halo_still_reads_marker_disc", "Marker-like halo is primary issue")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_901")
	_assert(String(snapshot.get("recommended_direction", "")) == "polish_marker_scale_and_world_noise_without_reopening_combat_truth", "Snapshot recommends tight marker/world-noise polish")
	_assert(String(snapshot.get("avoid_next_action", "")) == "do_not_add_more_contact_fire_text_or_reopen_damage_logic", "Snapshot rejects text/damage churn")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot is read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot sets no gameplay truth")
	_assert(not bool(snapshot.get("creates_command", true)), "Snapshot creates no commands")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Snapshot creates no damage events")
	_assert(not bool(snapshot.get("creates_movement", true)), "Snapshot creates no movement")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Snapshot sets no multiplayer truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Snapshot updates no shortcuts")


func _test_clean_notes_can_accept() -> void:
	var notes: Dictionary = _review_notes_with_issues()
	notes["player_readability_ok"] = true
	notes["target_halo_still_reads_marker_disc"] = false
	notes["grid_world_noise_competes_with_focal_signal"] = false
	notes["source_to_target_relationship_still_not_elegant"] = false
	notes["fire_label_and_halo_overlap_attention"] = false
	notes["bottom_hud_still_competes_with_world_combat"] = false
	notes["source_to_target_relationship_obvious"] = true
	var snapshot: Dictionary = Findings.build_snapshot(_good_manifest(), notes)
	_assert(String(snapshot.get("status", "")) == "accepted_for_release_smoke", "Clean notes can accept TASK_900")
	_assert(bool(snapshot.get("player_readability_ok", false)), "Clean notes mark player readability OK")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Clean notes have no issues")


func _test_optional_actual_manifest() -> void:
	if not FileAccess.file_exists(SOURCE_MANIFEST_PATH):
		_assert(true, "TASK_899 manifest is optional before local capture")
		return
	var manifest: Dictionary = _read_json_dict(SOURCE_MANIFEST_PATH)
	var snapshot: Dictionary = Findings.build_snapshot(manifest, _review_notes_with_issues())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual manifest builds TASK_900 schema")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_899", "Actual manifest links TASK_899")
	_assert(String(snapshot.get("capture_gate", "")) == "review_ready", "Actual manifest keeps review-ready gate")
	_assert(bool(snapshot.get("final_source_contact_fire", false)), "Actual manifest keeps CONTACT FIRE source")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Actual manifest recommends TASK_901")
	_assert(bool(snapshot.get("read_only", false)), "Actual manifest snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual manifest snapshot sets no gameplay truth")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(SOURCE_MANIFEST_PATH) if FileAccess.file_exists(SOURCE_MANIFEST_PATH) else _good_manifest()
	var snapshot: Dictionary = Findings.build_snapshot(source_manifest, _review_notes_with_issues())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_900 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_900", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_899", "Roundtrip keeps TASK_899 link")
	_assert(String(roundtrip.get("status", "")) == "ready_for_marker_scale_world_noise_polish", "Roundtrip keeps findings status")
	_assert(String(roundtrip.get("primary_issue_id", "")) == "target_halo_still_reads_marker_disc", "Roundtrip keeps primary issue")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip keeps read-only boundary")


func _good_manifest() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_899",
		"source_task_id": "TASK_898",
		"source_focal_task_id": "TASK_895",
		"source_findings_task_id": "TASK_897",
		"source_world_recapture_task_id": "TASK_896",
		"gate": "review_ready",
		"branch": "task/release-first-exchange-player-readability-polish-review",
		"git_head": "test",
		"launch_argument": FIRST_GO_ARG,
		"expected_elegance_schema": ELEGANCE_SCHEMA,
		"expected_elegance_style_id": ELEGANCE_STYLE_ID,
		"expected_focal_style_id": FOCAL_STYLE_ID,
		"source_world_recapture_schema": WORLD_RECAPTURE_SCHEMA,
		"source_world_recapture_gate": "review_ready",
		"post_final_capture_after_deeplink_final": true,
		"post_final_window_capture_method": "window_handle_print",
		"post_final_window_capture_trusted": true,
		"post_final_window_screenshot_written": true,
		"post_final_window_screenshot_path": "tmp/release_first_exchange_combat_focal_elegance_real_window_recapture.png",
		"post_final_desktop_screenshot_path": "tmp/release_first_exchange_combat_focal_elegance_real_window_recapture_desktop.png",
		"hard_failures": [],
		"final_source_snapshot": {
			"source_observed_state": "FINAL_SOURCE_CONTACT_FIRE",
			"stage": "deeplink_final",
			"selected_starts_contact_fire": true,
			"mission_starts_contact_fire": true,
			"event_log_contains_contact_fire": true,
			"event_log_contains_contact_pressure": false,
		},
		"post_final_combat_focal_elegance_render_review": {
			"screenshot_observed_state": "TASK_899_REVIEW_REQUIRED",
			"expected_elegant_lane": true,
			"expected_target_halo_smaller_than_task_895": true,
			"expected_source_glow_subtle": true,
		},
	}


func _review_notes_with_issues() -> Dictionary:
	return {
		"manual_visual_review_done": true,
		"correct_window_content_confirmed": true,
		"observed_window_state": "CONTACT_FIRE_VISIBLE_FOCAL_ELEGANCE_STILL_MARKERLIKE",
		"review_screenshot_path": "tmp/release_first_exchange_combat_focal_elegance_real_window_recapture.png",
		"player_readability_ok": false,
		"contact_fire_hud_surfaces_present": true,
		"event_log_contact_fire_visible": true,
		"world_fire_label_visible": true,
		"elegant_lane_visible": true,
		"source_glow_visible": true,
		"target_halo_visible": true,
		"source_to_target_relationship_obvious": false,
		"command_surfaces_still_usable": true,
		"target_halo_still_reads_marker_disc": true,
		"grid_world_noise_competes_with_focal_signal": true,
		"source_to_target_relationship_still_not_elegant": true,
		"fire_label_and_halo_overlap_attention": true,
		"bottom_hud_still_competes_with_world_combat": true,
	}


func _issue_ids(issues: Array) -> Array:
	var ids: Array = []
	for issue_variant in issues:
		ids.append(String(Dictionary(issue_variant).get("id", "")))
	return ids


func _read_json_dict(path: String) -> Dictionary:
	var text: String = _read_text(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return Dictionary(parsed)
	return {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
