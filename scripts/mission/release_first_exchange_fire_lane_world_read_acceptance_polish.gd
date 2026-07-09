class_name ReleaseFirstExchangeFireLaneWorldReadAcceptancePolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_acceptance_polish.v1"
const TASK_ID: String = "TASK_913"
const SOURCE_FINDINGS_TASK_ID: String = "TASK_912"
const SOURCE_WORLD_READ_TASK_ID: String = "TASK_910"
const SOURCE_WORLD_READ_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_micro_polish.v1"
const SOURCE_WORLD_READ_STYLE_ID: String = "task_910_release_first_exchange_fire_lane_world_read_micro_v1"
const STYLE_ID: String = "task_913_release_first_exchange_fire_lane_world_read_acceptance_v1"
const NEXT_TASK: String = "TASK_914 - Release First Exchange Fire Lane World Read Acceptance Recapture"


static func build_snapshot(source: Dictionary, context: Dictionary = {}) -> Dictionary:
	var findings: Dictionary = Dictionary(source.get("findings", {})).duplicate(true)
	var world_read: Dictionary = Dictionary(source.get("world_read_micro", {})).duplicate(true)
	var primary_render: Dictionary = Dictionary(source.get("primary_render_snapshot", {})).duplicate(true)
	var fire_vfx_entries: Array = Array(primary_render.get("weapon_fire_vfx_entries", [])).duplicate(true)
	var first_fire_vfx: Dictionary = Dictionary(fire_vfx_entries[0]).duplicate(true) if not fire_vfx_entries.is_empty() else {}
	var findings_ready: bool = String(findings.get("task_id", "")) == SOURCE_FINDINGS_TASK_ID \
		and String(findings.get("status", "")) == "ready_for_world_read_acceptance_polish" \
		and String(findings.get("primary_issue_id", "")) == "fire_lane_not_first_world_read_after_micro_polish"
	var world_read_ready: bool = String(world_read.get("schema", "")) == SOURCE_WORLD_READ_SCHEMA \
		and String(world_read.get("task_id", "")) == SOURCE_WORLD_READ_TASK_ID \
		and String(world_read.get("style_id", "")) == SOURCE_WORLD_READ_STYLE_ID \
		and String(world_read.get("gate", "")) == "pass"
	var active: bool = bool(primary_render.get("release_first_exchange_fire_lane_world_read_acceptance_polish_active", false)) \
		and String(primary_render.get("release_first_exchange_fire_lane_world_read_acceptance_polish_style_id", "")) == STYLE_ID
	var vfx_active: bool = bool(first_fire_vfx.get("fire_lane_world_read_acceptance_polish_active", false)) \
		and String(first_fire_vfx.get("fire_lane_world_read_acceptance_polish_style_id", "")) == STYLE_ID
	var base_lane_width: float = float(world_read.get("world_combat_fire_lane_world_read_micro_lane_width", 0.0))
	var base_lane_alpha: float = float(world_read.get("world_combat_fire_lane_world_read_micro_lane_alpha", 0.0))
	var base_core_width: float = float(world_read.get("world_combat_fire_lane_world_read_micro_core_width", 0.0))
	var base_core_alpha: float = float(world_read.get("world_combat_fire_lane_world_read_micro_core_alpha", 0.0))
	var base_halo_radius: float = float(world_read.get("world_combat_fire_lane_world_read_micro_target_halo_radius", 0.0))
	var base_halo_alpha: float = float(world_read.get("world_combat_fire_lane_world_read_micro_target_halo_alpha", 0.0))
	var base_source_anchor_radius: float = float(world_read.get("world_combat_fire_lane_world_read_micro_source_anchor_radius", 0.0))
	var base_target_anchor_radius: float = float(world_read.get("world_combat_fire_lane_world_read_micro_target_anchor_radius", 0.0))
	var base_label_font_size: int = int(world_read.get("world_combat_fire_lane_world_read_micro_status_label_font_size", 99))
	var base_label_alpha: float = float(world_read.get("world_combat_fire_lane_world_read_micro_status_label_alpha", 1.0))
	var base_label_offset_y: float = float(world_read.get("world_combat_fire_lane_world_read_micro_status_label_offset_y", 0.0))
	var lane_width: float = float(primary_render.get("world_combat_fire_lane_world_read_acceptance_lane_width", first_fire_vfx.get("world_combat_fire_lane_world_read_acceptance_lane_width", 0.0)))
	var lane_alpha: float = float(primary_render.get("world_combat_fire_lane_world_read_acceptance_lane_alpha", first_fire_vfx.get("world_combat_fire_lane_world_read_acceptance_lane_alpha", 0.0)))
	var core_width: float = float(primary_render.get("world_combat_fire_lane_world_read_acceptance_core_width", first_fire_vfx.get("world_combat_fire_lane_world_read_acceptance_core_width", 0.0)))
	var core_alpha: float = float(primary_render.get("world_combat_fire_lane_world_read_acceptance_core_alpha", first_fire_vfx.get("world_combat_fire_lane_world_read_acceptance_core_alpha", 0.0)))
	var halo_radius: float = float(primary_render.get("world_combat_fire_lane_world_read_acceptance_target_halo_radius", first_fire_vfx.get("world_combat_fire_lane_world_read_acceptance_target_halo_radius", 0.0)))
	var halo_alpha: float = float(primary_render.get("world_combat_fire_lane_world_read_acceptance_target_halo_alpha", first_fire_vfx.get("world_combat_fire_lane_world_read_acceptance_target_halo_alpha", 0.0)))
	var source_anchor_radius: float = float(primary_render.get("world_combat_fire_lane_world_read_acceptance_source_anchor_radius", first_fire_vfx.get("world_combat_fire_lane_world_read_acceptance_source_anchor_radius", 0.0)))
	var target_anchor_radius: float = float(primary_render.get("world_combat_fire_lane_world_read_acceptance_target_anchor_radius", first_fire_vfx.get("world_combat_fire_lane_world_read_acceptance_target_anchor_radius", 0.0)))
	var label_font_size: int = int(primary_render.get("world_combat_fire_lane_world_read_acceptance_status_label_font_size", first_fire_vfx.get("fire_status_label_font_size", 0)))
	var label_alpha: float = float(primary_render.get("world_combat_fire_lane_world_read_acceptance_status_label_alpha", first_fire_vfx.get("fire_status_label_alpha", 0.0)))
	var label_offset_y: float = float(primary_render.get("world_combat_fire_lane_world_read_acceptance_status_label_offset_y", first_fire_vfx.get("fire_status_label_offset_y", 0.0)))
	var checks: Array = [
		_check("source_findings_ready", findings_ready, "TASK_913 builds from TASK_912 visual findings."),
		_check("source_world_read_ready", world_read_ready, "TASK_913 keeps TASK_910 as source path."),
		_check("primary_acceptance_style_active", active and vfx_active, "Primary3D and first fire VFX report TASK_913."),
		_check("fire_lane_core_first_read_strengthened", lane_width > base_lane_width and lane_alpha <= base_lane_alpha and core_width > base_core_width and core_alpha >= base_core_alpha and core_alpha >= 0.97, "Fire-lane core carries the first world read."),
		_check("label_halo_cluster_retreats_further", label_font_size > 0 and label_font_size <= base_label_font_size and label_alpha < base_label_alpha and label_offset_y < base_label_offset_y and halo_radius > 0.0 and halo_radius < base_halo_radius and halo_alpha < base_halo_alpha, "World label and target halo retreat further behind the lane."),
		_check("direction_anchors_acceptance_weight", source_anchor_radius > base_source_anchor_radius and source_anchor_radius <= 0.155 and target_anchor_radius > base_target_anchor_radius and target_anchor_radius <= 0.16, "Source/target anchors carry direction without becoming large discs."),
		_check("read_only_boundaries", bool(source.get("read_only", false)) and bool(findings.get("read_only", false)) and bool(world_read.get("read_only", false)) and not bool(source.get("ui_sets_gameplay_truth", true)) and not bool(source.get("creates_command", true)) and not bool(source.get("creates_fire_event", true)) and not bool(source.get("creates_damage_event", true)) and not bool(source.get("creates_movement", true)) and not bool(source.get("sets_multiplayer_truth", true)), "TASK_913 changes presentation only."),
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
		"source_world_read_task_id": SOURCE_WORLD_READ_TASK_ID,
		"source_world_read_schema": SOURCE_WORLD_READ_SCHEMA,
		"source_world_read_style_id": SOURCE_WORLD_READ_STYLE_ID,
		"style_id": STYLE_ID,
		"active": active,
		"findings_ready": findings_ready,
		"world_read_ready": world_read_ready,
		"world_combat_fire_lane_world_read_acceptance_lane_width": lane_width,
		"world_combat_fire_lane_world_read_acceptance_lane_alpha": lane_alpha,
		"world_combat_fire_lane_world_read_acceptance_core_width": core_width,
		"world_combat_fire_lane_world_read_acceptance_core_alpha": core_alpha,
		"world_combat_fire_lane_world_read_acceptance_target_halo_radius": halo_radius,
		"world_combat_fire_lane_world_read_acceptance_target_halo_alpha": halo_alpha,
		"world_combat_fire_lane_world_read_acceptance_source_anchor_radius": source_anchor_radius,
		"world_combat_fire_lane_world_read_acceptance_target_anchor_radius": target_anchor_radius,
		"world_combat_fire_lane_world_read_acceptance_status_label_font_size": label_font_size,
		"world_combat_fire_lane_world_read_acceptance_status_label_alpha": label_alpha,
		"world_combat_fire_lane_world_read_acceptance_status_label_offset_y": label_offset_y,
		"weapon_fire_vfx_visual_count": int(primary_render.get("weapon_fire_vfx_visual_count", 0)),
		"weapon_fire_vfx_entries": fire_vfx_entries,
		"findings": findings,
		"world_read_micro": world_read,
		"primary_render_snapshot": primary_render,
		"checks": checks,
		"failed_checks": failed_checks,
		"gate": "pass" if failed_checks.is_empty() else "review",
		"visual_policy": "acceptance_polish_fire_lane_first_world_read",
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
