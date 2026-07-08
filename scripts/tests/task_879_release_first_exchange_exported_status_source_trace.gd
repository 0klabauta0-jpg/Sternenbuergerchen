extends SceneTree

const TraceReview := preload("res://scripts/mission/release_first_exchange_exported_status_source_trace.gd")

const TASK_PATH := "res://docs/tasks/TASK_879_release_first_exchange_exported_status_source_trace.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const META_PATH := "res://scripts/meta/meta_layer_flow.gd"
const SERVICE_PATH := "res://scripts/mission/release_first_exchange_exported_status_source_trace.gd"
const TOOL_PATH := "res://scripts/tools/capture_release_first_exchange_exported_status_source_trace.ps1"
const MANIFEST_PATH := "res://tmp/release_first_exchange_exported_status_source_trace.json"
const OUTPUT_PATH := "res://tmp/release_first_exchange_exported_status_source_trace_review.json"
const SCHEMA := "sternenbuergerchen.release_first_exchange_exported_status_source_trace_review.v1"
const CAPTURE_SCHEMA := "sternenbuergerchen.release_first_exchange_exported_status_source_trace.v1"
const RUNTIME_SCHEMA := "sternenbuergerchen.release_first_exchange_exported_status_source_trace_runtime.v1"
const FIRST_GO_ARG := "--release-singleplayer-first-go-firefight"
const NEXT_OVERRIDE_TASK := "TASK_880 - Release First Exchange Exported HUD Refresh Override Fix"
const NEXT_ACTIVATION_TASK := "TASK_880 - Release First Exchange Exported Status Source Activation Fix"
const NEXT_VISUAL_TASK := "TASK_880 - Release First Exchange Fire Visual Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_879 Release First Exchange Exported Status Source Trace ===")
	_test_docs_and_static_hooks()
	_test_missing_trace_blocks()
	_test_activation_missing_recommends_activation_fix()
	_test_activation_then_final_override_recommends_hud_refresh_fix()
	_test_optional_actual_capture_manifest()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_879_release_first_exchange_exported_status_source_trace: FAILED")
		quit(1)
		return
	print("TASK_879_release_first_exchange_exported_status_source_trace: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var meta_text: String = _read_text(META_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_879 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_879 analyzer exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_879 capture tool exists")
	_assert(task_text.contains("Release First Exchange Exported Status Source Trace"), "Task names TASK_879")
	_assert(task_text.contains("Keine neuen Commands"), "Task states no command creation")
	_assert(status_text.contains("TASK_879 - Release First Exchange Exported Status Source Trace"), "Implementation status tracks TASK_879")
	_assert(roadmap_text.contains("TASK_879 - Release First Exchange Exported Status Source Trace (implementiert)"), "Roadmap marks TASK_879 implemented")
	_assert(roadmap_text.contains(NEXT_VISUAL_TASK), "Roadmap names TASK_880 follow-up")
	_assert(contract_text.contains("Release-First-Exchange-Exported-Status-Source-Trace (TASK_879)"), "Contract documents TASK_879")
	_assert(meta_text.contains("STERNENBUERGERCHEN_RELEASE_FIRST_EXCHANGE_TRACE_PATH"), "MetaLayer exposes TASK_879 trace env var")
	_assert(meta_text.contains("_append_release_first_exchange_exported_status_trace_sample"), "MetaLayer appends TASK_879 samples")
	_assert(meta_text.contains("_write_release_first_exchange_exported_status_trace"), "MetaLayer writes TASK_879 trace")
	_assert(meta_text.contains("after_contact_fire_readability_fix"), "MetaLayer samples after TASK_873/TASK_876 source handoff")
	_assert(meta_text.contains("deeplink_final"), "MetaLayer samples final deeplink status")
	_assert(tool_text.contains("release_first_exchange_exported_status_source_trace_runtime.json"), "Capture tool expects runtime trace file")
	_assert(tool_text.contains("release_first_exchange_visible_status_recapture.ps1"), "Capture tool reuses TASK_877 recapture")
	_assert(tool_text.contains("read_only_trace = $true"), "Capture tool declares read-only trace")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes TASK_879 review schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_879\""), "Analyzer writes TASK_879 id")
	_assert(service_text.contains("exported_status_source_overwritten_after_activation"), "Analyzer names HUD refresh override issue")
	_assert(service_text.contains("exported_status_source_activation_not_observed"), "Analyzer names activation issue")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer declares no command creation")
	_assert(service_text.contains("\"creates_fire_event\": false"), "Analyzer declares no fire-event creation")
	_assert(service_text.contains("\"creates_damage_event\": false"), "Analyzer declares no damage-event creation")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer declares no multiplayer truth")


func _test_missing_trace_blocks() -> void:
	var snapshot: Dictionary = TraceReview.build_snapshot({})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing capture manifest blocks TASK_879")
	_assert(blocker_ids.has("capture_schema_mismatch"), "Missing manifest reports capture schema mismatch")
	_assert(blocker_ids.has("capture_task_mismatch"), "Missing manifest reports task mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing manifest reports TASK_878 mismatch")
	_assert(blocker_ids.has("source_visible_status_mismatch"), "Missing manifest reports TASK_876 mismatch")
	_assert(blocker_ids.has("source_recapture_mismatch"), "Missing manifest reports TASK_877 mismatch")
	_assert(blocker_ids.has("launch_argument_mismatch"), "Missing manifest reports launch mismatch")
	_assert(blocker_ids.has("runtime_trace_missing"), "Missing manifest reports trace missing")
	_assert(blocker_ids.has("runtime_trace_schema_mismatch"), "Missing manifest reports runtime schema mismatch")
	_assert(blocker_ids.has("runtime_trace_too_few_samples"), "Missing manifest reports too few samples")
	_assert(bool(snapshot.get("read_only", false)), "Blocked snapshot remains read-only")
	_assert(not bool(snapshot.get("creates_command", true)), "Blocked snapshot creates no command")


func _test_activation_missing_recommends_activation_fix() -> void:
	var snapshot: Dictionary = TraceReview.build_snapshot(_capture_manifest(false, false))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_879")
	_assert(String(snapshot.get("status", "")) == "ready_for_followup", "Traceable capture is follow-up ready")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Traceable capture has no blockers")
	_assert(not bool(snapshot.get("activation_observed", true)), "Snapshot records missing TASK_876 activation")
	_assert(issue_ids.has("exported_status_source_activation_not_observed"), "Snapshot reports missing activation")
	_assert(String(snapshot.get("primary_issue_id", "")) == "exported_status_source_activation_not_observed", "Missing activation is primary")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_ACTIVATION_TASK, "Snapshot recommends activation fix")
	_assert(bool(snapshot.get("read_only", false)), "Activation snapshot is read-only")
	_assert(not bool(snapshot.get("sets_multiplayer_truth", true)), "Activation snapshot sets no multiplayer truth")


func _test_activation_then_final_override_recommends_hud_refresh_fix() -> void:
	var snapshot: Dictionary = TraceReview.build_snapshot(_capture_manifest(true, true))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(bool(snapshot.get("activation_observed", false)), "Snapshot records TASK_876 activation")
	_assert(bool(snapshot.get("final_no_los_or_contact_pressure_observed", false)), "Snapshot records final NO_LOS/CONTACT_PRESSURE")
	_assert(String(snapshot.get("latest_stage", "")) == "deeplink_final", "Latest sample is final")
	_assert(String(snapshot.get("latest_selected_fireteam_status_text", "")).contains("NO_LOS"), "Latest selected text records NO_LOS")
	_assert(String(snapshot.get("latest_event_log_short_text", "")).contains("CONTACT PRESSURE"), "Latest event log records CONTACT PRESSURE")
	_assert(issue_ids.has("exported_status_source_overwritten_after_activation"), "Snapshot reports overwrite after activation")
	_assert(String(snapshot.get("primary_issue_id", "")) == "exported_status_source_overwritten_after_activation", "Override is primary issue")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_OVERRIDE_TASK, "Snapshot recommends HUD refresh override fix")
	_assert(String(snapshot.get("avoid_next_action", "")) == "do_not_add_more_contact_fire_text_without_fixing_traced_source_loss", "Snapshot rejects more cosmetic CONTACT FIRE")
	_assert(not bool(snapshot.get("creates_fire_event", true)), "Override snapshot creates no fire events")
	_assert(not bool(snapshot.get("creates_damage_event", true)), "Override snapshot creates no damage")


func _test_optional_actual_capture_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		_assert(true, "TASK_879 actual capture manifest is optional before local export capture")
		return
	var manifest: Dictionary = _read_json_dict(MANIFEST_PATH)
	var snapshot: Dictionary = TraceReview.build_snapshot(manifest)
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Actual capture builds TASK_879 schema")
	_assert(String(snapshot.get("task_id", "")) == "TASK_879", "Actual capture keeps TASK_879 task id")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_878", "Actual capture links TASK_878")
	_assert(String(snapshot.get("source_visible_status_task_id", "")) == "TASK_876", "Actual capture links TASK_876")
	_assert(bool(snapshot.get("runtime_trace_written", false)), "Actual capture includes runtime trace")
	_assert(bool(snapshot.get("read_only", false)), "Actual capture snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Actual capture sets no gameplay truth")
	_assert(not bool(snapshot.get("updates_shortcuts", true)), "Actual capture updates no shortcuts")


func _test_manifest_roundtrip() -> void:
	var source_manifest: Dictionary = _read_json_dict(MANIFEST_PATH) if FileAccess.file_exists(MANIFEST_PATH) else _capture_manifest(true, true)
	var snapshot: Dictionary = TraceReview.build_snapshot(source_manifest)
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_879 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_879", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_878", "Roundtrip keeps TASK_878 link")
	_assert(String(roundtrip.get("recommended_direction", "")) == "fix_exported_status_source_activation_or_hud_refresh_override_from_trace_evidence", "Roundtrip keeps recommendation direction")
	_assert(bool(roundtrip.get("read_only", false)), "Roundtrip keeps read-only boundary")


func _capture_manifest(activation_observed: bool, final_override: bool) -> Dictionary:
	var runtime_trace: Dictionary = _runtime_trace(activation_observed, final_override)
	return {
		"schema": CAPTURE_SCHEMA,
		"task_id": "TASK_879",
		"source_task_id": "TASK_878",
		"source_visible_status_task_id": "TASK_876",
		"source_recapture_task_id": "TASK_877",
		"source_readability_task_id": "TASK_873",
		"gate": "review",
		"branch": "task/release-first-exchange-exported-status-source-trace",
		"git_head": "test",
		"launch_argument": FIRST_GO_ARG,
		"runtime_trace_written": true,
		"runtime_trace_schema": RUNTIME_SCHEMA,
		"runtime_trace_sample_count": int(runtime_trace.get("sample_count", 0)),
		"runtime_trace_activation_observed": activation_observed,
		"runtime_trace_final_no_los_or_contact_pressure_observed": final_override,
		"runtime_trace": runtime_trace,
		"hard_failures": [],
		"warnings": [],
		"read_only_trace": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


func _runtime_trace(activation_observed: bool, final_override: bool) -> Dictionary:
	var samples: Array = [
		_sample("deeplink_requested", false, false, "", "", ""),
		_sample("mission_runtime_nodes_ready", false, false, "", "", ""),
		_sample("after_contact_fire_readability_fix", activation_observed, activation_observed, "CONTACT FIRE | FT1>A", "CONTACT FIRE | FT1>A", "CONTACT FIRE: Feuerwechsel lesen"),
		_sample(
			"deeplink_final",
			activation_observed,
			activation_observed and not final_override,
			"#17 Kampf NO FIRE NO_LOS" if final_override else "CONTACT FIRE | FT1>A",
			"#18 Kampf NO FIRE NO_LOS" if final_override else "CONTACT FIRE | FT1>A",
			"#19 CONTACT PRESSURE: Position korrigieren" if final_override else "CONTACT FIRE: Feuerwechsel lesen"
		),
	]
	return {
		"schema": RUNTIME_SCHEMA,
		"task_id": "TASK_879",
		"source_task_id": "TASK_878",
		"source_visible_status_task_id": "TASK_876",
		"sample_count": samples.size(),
		"activation_observed": activation_observed,
		"final_no_los_or_contact_pressure_observed": final_override,
		"latest_sample": samples[samples.size() - 1],
		"samples": samples,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


func _sample(stage: String, status_source_active: bool, density_source_active: bool, selected: String, mission: String, event_log: String) -> Dictionary:
	return {
		"stage": stage,
		"status_source_active": status_source_active,
		"combat_hud_density_status_source_active": density_source_active,
		"visibility_persistence_task_id": "TASK_876" if status_source_active else "",
		"selected_fireteam_status_text": selected,
		"mission_control_status_text": mission,
		"event_log_short_text": event_log,
		"selected_contains_no_los": selected.contains("NO_LOS") or selected.contains("LOS/RANGE"),
		"mission_contains_no_los": mission.contains("NO_LOS") or mission.contains("LOS/RANGE"),
		"event_log_contains_contact_pressure": event_log.contains("CONTACT PRESSURE"),
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
