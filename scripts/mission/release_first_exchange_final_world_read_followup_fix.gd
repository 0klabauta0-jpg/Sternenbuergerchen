class_name ReleaseFirstExchangeFinalWorldReadFollowupFix
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_final_world_read_followup_fix.v1"
const TASK_ID: String = "TASK_920"
const SOURCE_FINDINGS_TASK_ID: String = "TASK_918"
const SOURCE_FINAL_TASK_ID: String = "TASK_916"
const SOURCE_FINDINGS_SCHEMA: String = "sternenbuergerchen.release_first_exchange_final_world_read_visual_findings.v1"
const SOURCE_FINAL_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_final_polish.v1"
const SOURCE_FINAL_STYLE_ID: String = "task_916_release_first_exchange_fire_lane_world_read_final_v1"
const STYLE_ID: String = "task_920_release_first_exchange_final_world_read_followup_v1"
const NEXT_TASK: String = "TASK_921 - Release First Exchange Followup World Read Recapture"


static func build_snapshot(source: Dictionary, context: Dictionary = {}) -> Dictionary:
	var findings: Dictionary = Dictionary(source.get("findings", {})).duplicate(true)
	var final_polish: Dictionary = Dictionary(source.get("final_polish", {})).duplicate(true)
	var primary_render: Dictionary = Dictionary(source.get("primary_render_snapshot", {})).duplicate(true)
	var fire_vfx_entries: Array = Array(primary_render.get("weapon_fire_vfx_entries", [])).duplicate(true)
	var first_fire_vfx: Dictionary = Dictionary(fire_vfx_entries[0]).duplicate(true) if not fire_vfx_entries.is_empty() else {}
	var findings_ready: bool = String(findings.get("schema", "")) == SOURCE_FINDINGS_SCHEMA \
		and String(findings.get("task_id", "")) == SOURCE_FINDINGS_TASK_ID \
		and String(findings.get("source_final_task_id", "")) == SOURCE_FINAL_TASK_ID \
		and String(findings.get("status", "")) == "ready_for_final_world_read_followup_fix"
	var final_ready: bool = String(final_polish.get("schema", "")) == SOURCE_FINAL_SCHEMA \
		and String(final_polish.get("task_id", "")) == SOURCE_FINAL_TASK_ID \
		and String(final_polish.get("style_id", "")) == SOURCE_FINAL_STYLE_ID \
		and String(final_polish.get("gate", "")) == "pass"
	var active: bool = bool(primary_render.get("release_first_exchange_final_world_read_followup_fix_active", false)) \
		and String(primary_render.get("release_first_exchange_final_world_read_followup_fix_style_id", "")) == STYLE_ID
	var vfx_active: bool = bool(first_fire_vfx.get("final_world_read_followup_fix_active", false)) \
		and String(first_fire_vfx.get("final_world_read_followup_fix_style_id", "")) == STYLE_ID
	var base_lane_width: float = float(final_polish.get("world_combat_fire_lane_world_read_final_lane_width", 0.0))
	var base_lane_alpha: float = float(final_polish.get("world_combat_fire_lane_world_read_final_lane_alpha", 0.0))
	var base_core_width: float = float(final_polish.get("world_combat_fire_lane_world_read_final_core_width", 0.0))
	var base_core_alpha: float = float(final_polish.get("world_combat_fire_lane_world_read_final_core_alpha", 0.0))
	var base_halo_radius: float = float(final_polish.get("world_combat_fire_lane_world_read_final_target_halo_radius", 0.0))
	var base_halo_alpha: float = float(final_polish.get("world_combat_fire_lane_world_read_final_target_halo_alpha", 0.0))
	var base_source_anchor_radius: float = float(final_polish.get("world_combat_fire_lane_world_read_final_source_anchor_radius", 0.0))
	var base_target_anchor_radius: float = float(final_polish.get("world_combat_fire_lane_world_read_final_target_anchor_radius", 0.0))
	var base_label_font_size: int = int(final_polish.get("world_combat_fire_lane_world_read_final_status_label_font_size", 99))
	var base_label_alpha: float = float(final_polish.get("world_combat_fire_lane_world_read_final_status_label_alpha", 1.0))
	var base_label_offset_y: float = float(final_polish.get("world_combat_fire_lane_world_read_final_status_label_offset_y", 0.0))
	var lane_width: float = float(primary_render.get("world_combat_final_world_read_followup_lane_width", first_fire_vfx.get("world_combat_final_world_read_followup_lane_width", 0.0)))
	var lane_alpha: float = float(primary_render.get("world_combat_final_world_read_followup_lane_alpha", first_fire_vfx.get("world_combat_final_world_read_followup_lane_alpha", 0.0)))
	var core_width: float = float(primary_render.get("world_combat_final_world_read_followup_core_width", first_fire_vfx.get("world_combat_final_world_read_followup_core_width", 0.0)))
	var core_alpha: float = float(primary_render.get("world_combat_final_world_read_followup_core_alpha", first_fire_vfx.get("world_combat_final_world_read_followup_core_alpha", 0.0)))
	var halo_radius: float = float(primary_render.get("world_combat_final_world_read_followup_target_halo_radius", first_fire_vfx.get("world_combat_final_world_read_followup_target_halo_radius", 0.0)))
	var halo_alpha: float = float(primary_render.get("world_combat_final_world_read_followup_target_halo_alpha", first_fire_vfx.get("world_combat_final_world_read_followup_target_halo_alpha", 0.0)))
	var source_anchor_radius: float = float(primary_render.get("world_combat_final_world_read_followup_source_anchor_radius", first_fire_vfx.get("world_combat_final_world_read_followup_source_anchor_radius", 0.0)))
	var target_anchor_radius: float = float(primary_render.get("world_combat_final_world_read_followup_target_anchor_radius", first_fire_vfx.get("world_combat_final_world_read_followup_target_anchor_radius", 0.0)))
	var label_font_size: int = int(primary_render.get("world_combat_final_world_read_followup_status_label_font_size", first_fire_vfx.get("fire_status_label_font_size", 0)))
	var label_alpha: float = float(primary_render.get("world_combat_final_world_read_followup_status_label_alpha", first_fire_vfx.get("fire_status_label_alpha", 0.0)))
	var label_offset_y: float = float(primary_render.get("world_combat_final_world_read_followup_status_label_offset_y", first_fire_vfx.get("fire_status_label_offset_y", 0.0)))
	var checks: Array = [
		_check("source_findings_ready", findings_ready, "TASK_920 builds from TASK_918 follow-up findings."),
		_check("source_final_polish_ready", final_ready, "TASK_920 keeps TASK_916 as the source path."),
		_check("primary_followup_style_active", active and vfx_active, "Primary3D and first fire VFX report TASK_920."),
		_check("fire_lane_followup_first_read_strengthened", lane_width > base_lane_width and lane_alpha <= base_lane_alpha and core_width > base_core_width and core_alpha >= base_core_alpha and core_alpha >= 1.0, "Follow-up fire-lane core carries the world read."),
		_check("label_halo_followup_retreat", label_font_size > 0 and label_font_size <= base_label_font_size and label_alpha < base_label_alpha and label_offset_y < base_label_offset_y and halo_radius > 0.0 and halo_radius < base_halo_radius and halo_alpha < base_halo_alpha, "World label and target halo retreat behind the follow-up lane."),
		_check("direction_anchors_followup_weight", source_anchor_radius > base_source_anchor_radius and source_anchor_radius <= 0.18 and target_anchor_radius > base_target_anchor_radius and target_anchor_radius <= 0.18, "Follow-up anchors carry direction without becoming discs."),
		_check("read_only_boundaries", bool(source.get("read_only", false)) and bool(findings.get("read_only", false)) and bool(final_polish.get("read_only", false)) and not bool(source.get("ui_sets_gameplay_truth", true)) and not bool(source.get("creates_command", true)) and not bool(source.get("creates_fire_event", true)) and not bool(source.get("creates_damage_event", true)) and not bool(source.get("creates_movement", true)) and not bool(source.get("sets_multiplayer_truth", true)), "TASK_920 changes presentation only."),
	]
	var failed_checks: Array = []
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed_checks.append(String(check.get("id", "")))
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_findings_task_id": SOURCE_FINDINGS_TASK_ID,
		"source_final_task_id": SOURCE_FINAL_TASK_ID,
		"source_findings_schema": SOURCE_FINDINGS_SCHEMA,
		"source_final_schema": SOURCE_FINAL_SCHEMA,
		"source_final_style_id": SOURCE_FINAL_STYLE_ID,
		"style_id": STYLE_ID,
		"active": active,
		"findings_ready": findings_ready,
		"final_polish_ready": final_ready,
		"world_combat_final_world_read_followup_lane_width": lane_width,
		"world_combat_final_world_read_followup_lane_alpha": lane_alpha,
		"world_combat_final_world_read_followup_core_width": core_width,
		"world_combat_final_world_read_followup_core_alpha": core_alpha,
		"world_combat_final_world_read_followup_target_halo_radius": halo_radius,
		"world_combat_final_world_read_followup_target_halo_alpha": halo_alpha,
		"world_combat_final_world_read_followup_source_anchor_radius": source_anchor_radius,
		"world_combat_final_world_read_followup_target_anchor_radius": target_anchor_radius,
		"world_combat_final_world_read_followup_status_label_font_size": label_font_size,
		"world_combat_final_world_read_followup_status_label_alpha": label_alpha,
		"world_combat_final_world_read_followup_status_label_offset_y": label_offset_y,
		"weapon_fire_vfx_visual_count": int(primary_render.get("weapon_fire_vfx_visual_count", 0)),
		"weapon_fire_vfx_entries": fire_vfx_entries,
		"findings": findings,
		"final_polish": final_polish,
		"primary_render_snapshot": primary_render,
		"checks": checks,
		"failed_checks": failed_checks,
		"gate": "pass" if failed_checks.is_empty() else "review",
		"visual_policy": "followup_fix_fire_lane_first_world_read",
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
