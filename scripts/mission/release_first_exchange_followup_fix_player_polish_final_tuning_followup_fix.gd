class_name ReleaseFirstExchangeFollowupFixPlayerPolishFinalTuningFollowupFix
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.v1"
const TASK_ID: String = "TASK_942"
const SOURCE_GATE_TASK_ID: String = "TASK_941"
const SOURCE_FINDINGS_TASK_ID: String = "TASK_940"
const BASE_FINAL_TUNING_TASK_ID: String = "TASK_938"
const SOURCE_GATE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_final_tuning_playability_smoke_gate.v1"
const SOURCE_FINDINGS_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_visual_findings.v1"
const BASE_FINAL_TUNING_SCHEMA: String = "sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning.v1"
const BASE_FINAL_TUNING_STYLE_ID: String = "task_938_release_first_exchange_followup_fix_player_polish_final_tuning_v1"
const STYLE_ID: String = "task_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_v1"
const NEXT_TASK: String = "TASK_943 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Recapture"


static func build_snapshot(source: Dictionary, context: Dictionary = {}) -> Dictionary:
	var gate_source: Dictionary = Dictionary(source.get("gate", {})).duplicate(true)
	var findings: Dictionary = Dictionary(source.get("findings", {})).duplicate(true)
	var base_final_tuning: Dictionary = Dictionary(source.get("base_final_tuning", {})).duplicate(true)
	var primary_render: Dictionary = Dictionary(source.get("primary_render_snapshot", {})).duplicate(true)
	var fire_vfx_entries: Array = Array(primary_render.get("weapon_fire_vfx_entries", [])).duplicate(true)
	var first_fire_vfx: Dictionary = Dictionary(fire_vfx_entries[0]).duplicate(true) if not fire_vfx_entries.is_empty() else {}
	var source_gate_ready: bool = String(gate_source.get("schema", "")) == SOURCE_GATE_SCHEMA \
		and String(gate_source.get("task_id", "")) == SOURCE_GATE_TASK_ID \
		and String(gate_source.get("gate", "")) == "followup_fix_required" \
		and bool(gate_source.get("followup_fix_required", false)) \
		and String(gate_source.get("source_primary_issue_id", "")) == "final_tuning_fire_lane_not_first_world_movement"
	var source_findings_ready: bool = String(findings.get("schema", "")) == SOURCE_FINDINGS_SCHEMA \
		and String(findings.get("task_id", "")) == SOURCE_FINDINGS_TASK_ID \
		and String(findings.get("status", "")) == "ready_for_followup_fix_player_polish_final_tuning_followup_fix" \
		and String(findings.get("primary_issue_id", "")) == "final_tuning_fire_lane_not_first_world_movement"
	var base_ready: bool = String(base_final_tuning.get("schema", "")) == BASE_FINAL_TUNING_SCHEMA \
		and String(base_final_tuning.get("task_id", "")) == BASE_FINAL_TUNING_TASK_ID \
		and String(base_final_tuning.get("style_id", "")) == BASE_FINAL_TUNING_STYLE_ID \
		and String(base_final_tuning.get("gate", "")) == "pass"
	var active: bool = bool(primary_render.get("release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_active", false)) \
		and String(primary_render.get("release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_style_id", "")) == STYLE_ID
	var vfx_active: bool = bool(first_fire_vfx.get("followup_fix_player_polish_final_tuning_followup_fix_active", false)) \
		and String(first_fire_vfx.get("followup_fix_player_polish_final_tuning_followup_fix_style_id", "")) == STYLE_ID
	var base_lane_width: float = float(base_final_tuning.get("world_combat_followup_fix_player_polish_final_tuning_lane_width", 0.0))
	var base_lane_alpha: float = float(base_final_tuning.get("world_combat_followup_fix_player_polish_final_tuning_lane_alpha", 1.0))
	var base_core_width: float = float(base_final_tuning.get("world_combat_followup_fix_player_polish_final_tuning_core_width", 0.0))
	var base_core_alpha: float = float(base_final_tuning.get("world_combat_followup_fix_player_polish_final_tuning_core_alpha", 0.0))
	var base_halo_radius: float = float(base_final_tuning.get("world_combat_followup_fix_player_polish_final_tuning_target_halo_radius", 1.0))
	var base_label_alpha: float = float(base_final_tuning.get("world_combat_followup_fix_player_polish_final_tuning_status_label_alpha", 1.0))
	var base_grid_alpha: float = float(base_final_tuning.get("world_combat_followup_fix_player_polish_final_tuning_grid_noise_alpha", 1.0))
	var base_world_line_alpha_factor: float = float(base_final_tuning.get("world_combat_followup_fix_player_polish_final_tuning_world_line_alpha_factor", 1.0))
	var lane_width: float = float(primary_render.get("world_combat_followup_fix_player_polish_final_tuning_followup_lane_width", first_fire_vfx.get("world_combat_followup_fix_player_polish_final_tuning_followup_lane_width", 0.0)))
	var lane_alpha: float = float(primary_render.get("world_combat_followup_fix_player_polish_final_tuning_followup_lane_alpha", first_fire_vfx.get("world_combat_followup_fix_player_polish_final_tuning_followup_lane_alpha", 0.0)))
	var core_width: float = float(primary_render.get("world_combat_followup_fix_player_polish_final_tuning_followup_core_width", first_fire_vfx.get("world_combat_followup_fix_player_polish_final_tuning_followup_core_width", 0.0)))
	var core_alpha: float = float(primary_render.get("world_combat_followup_fix_player_polish_final_tuning_followup_core_alpha", first_fire_vfx.get("world_combat_followup_fix_player_polish_final_tuning_followup_core_alpha", 0.0)))
	var halo_radius: float = float(primary_render.get("world_combat_followup_fix_player_polish_final_tuning_followup_target_halo_radius", first_fire_vfx.get("world_combat_followup_fix_player_polish_final_tuning_followup_target_halo_radius", 0.0)))
	var halo_alpha: float = float(primary_render.get("world_combat_followup_fix_player_polish_final_tuning_followup_target_halo_alpha", first_fire_vfx.get("world_combat_followup_fix_player_polish_final_tuning_followup_target_halo_alpha", 0.0)))
	var source_anchor_radius: float = float(primary_render.get("world_combat_followup_fix_player_polish_final_tuning_followup_source_anchor_radius", first_fire_vfx.get("world_combat_followup_fix_player_polish_final_tuning_followup_source_anchor_radius", 0.0)))
	var target_anchor_radius: float = float(primary_render.get("world_combat_followup_fix_player_polish_final_tuning_followup_target_anchor_radius", first_fire_vfx.get("world_combat_followup_fix_player_polish_final_tuning_followup_target_anchor_radius", 0.0)))
	var label_alpha: float = float(primary_render.get("world_combat_followup_fix_player_polish_final_tuning_followup_status_label_alpha", first_fire_vfx.get("fire_status_label_alpha", 0.0)))
	var label_offset_y: float = float(primary_render.get("world_combat_followup_fix_player_polish_final_tuning_followup_status_label_offset_y", first_fire_vfx.get("fire_status_label_offset_y", 0.0)))
	var grid_alpha: float = float(primary_render.get("world_combat_followup_fix_player_polish_final_tuning_followup_grid_noise_alpha", 1.0))
	var world_line_alpha_factor: float = float(primary_render.get("world_combat_followup_fix_player_polish_final_tuning_followup_world_line_alpha_factor", 1.0))
	var checks: Array = [
		_check("source_gate_ready", source_gate_ready, "TASK_942 builds only from TASK_941 follow-up gate."),
		_check("source_findings_ready", source_findings_ready, "TASK_942 requires TASK_940 final-tuning follow-up findings."),
		_check("base_final_tuning_ready", base_ready, "TASK_942 keeps TASK_938 as its presentation baseline."),
		_check("primary_followup_style_active", active and vfx_active, "Primary3D and first fire VFX report TASK_942."),
		_check("followup_fix_player_polish_final_tuning_followup_lane_first", lane_width > base_lane_width and lane_alpha < base_lane_alpha and core_width > base_core_width and core_alpha >= base_core_alpha, "TASK_942 makes the source-to-target lane/core more clearly first."),
		_check("label_halo_followup_retreat", label_alpha < base_label_alpha and halo_radius > 0.0 and halo_radius < base_halo_radius and halo_alpha <= 0.001, "World label and target halo retreat further behind the TASK_942 lane."),
		_check("direction_anchors_followup_weight", source_anchor_radius <= 0.225 and target_anchor_radius <= 0.225, "Direction anchors stay below the disc threshold."),
		_check("world_noise_followup_retreat", grid_alpha < base_grid_alpha and world_line_alpha_factor < base_world_line_alpha_factor, "Grid and world lines retreat further behind TASK_942."),
		_check("read_only_boundaries", bool(source.get("read_only", false)) and not bool(source.get("ui_sets_gameplay_truth", true)) and not bool(source.get("creates_command", true)) and not bool(source.get("creates_fire_event", true)) and not bool(source.get("creates_damage_event", true)) and not bool(source.get("creates_movement", true)) and not bool(source.get("sets_multiplayer_truth", true)), "TASK_942 changes presentation only."),
	]
	var failed_checks: Array = []
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed_checks.append(String(check.get("id", "")))
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_gate_task_id": SOURCE_GATE_TASK_ID,
		"source_findings_task_id": SOURCE_FINDINGS_TASK_ID,
		"base_final_tuning_task_id": BASE_FINAL_TUNING_TASK_ID,
		"source_gate_schema": SOURCE_GATE_SCHEMA,
		"source_findings_schema": SOURCE_FINDINGS_SCHEMA,
		"base_final_tuning_schema": BASE_FINAL_TUNING_SCHEMA,
		"base_final_tuning_style_id": BASE_FINAL_TUNING_STYLE_ID,
		"style_id": STYLE_ID,
		"active": active,
		"source_gate_ready": source_gate_ready,
		"source_findings_ready": source_findings_ready,
		"base_final_tuning_ready": base_ready,
		"world_combat_followup_fix_player_polish_final_tuning_followup_lane_width": lane_width,
		"world_combat_followup_fix_player_polish_final_tuning_followup_lane_alpha": lane_alpha,
		"world_combat_followup_fix_player_polish_final_tuning_followup_core_width": core_width,
		"world_combat_followup_fix_player_polish_final_tuning_followup_core_alpha": core_alpha,
		"world_combat_followup_fix_player_polish_final_tuning_followup_target_halo_radius": halo_radius,
		"world_combat_followup_fix_player_polish_final_tuning_followup_target_halo_alpha": halo_alpha,
		"world_combat_followup_fix_player_polish_final_tuning_followup_source_anchor_radius": source_anchor_radius,
		"world_combat_followup_fix_player_polish_final_tuning_followup_target_anchor_radius": target_anchor_radius,
		"world_combat_followup_fix_player_polish_final_tuning_followup_status_label_alpha": label_alpha,
		"world_combat_followup_fix_player_polish_final_tuning_followup_status_label_offset_y": label_offset_y,
		"world_combat_followup_fix_player_polish_final_tuning_followup_grid_noise_alpha": grid_alpha,
		"world_combat_followup_fix_player_polish_final_tuning_followup_world_line_alpha_factor": world_line_alpha_factor,
		"weapon_fire_vfx_entries": fire_vfx_entries,
		"source_gate": gate_source,
		"findings": findings,
		"base_final_tuning": base_final_tuning,
		"primary_render_snapshot": primary_render,
		"checks": checks,
		"failed_checks": failed_checks,
		"gate": "pass" if failed_checks.is_empty() else "review",
		"visual_policy": "followup_fix_player_polish_final_tuning_followup_lane_first",
		"recommended_next_task": String(context.get("recommended_next_task", NEXT_TASK)),
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


static func _check(check_id: String, passed: bool, text: String) -> Dictionary:
	return {
		"id": check_id,
		"passed": passed,
		"text": text,
	}
