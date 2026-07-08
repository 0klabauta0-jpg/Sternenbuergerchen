class_name ReleaseFirstExchangeWorldCombatFocalHierarchyPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_world_combat_focal_hierarchy_polish.v1"
const TASK_ID: String = "TASK_895"
const SOURCE_TASK_ID: String = "TASK_894"
const SOURCE_DIRECTION_TASK_ID: String = "TASK_892"
const SOURCE_FINDINGS_STATUS: String = "ready_for_world_combat_focal_polish"
const STYLE_ID: String = "task_895_release_first_exchange_world_combat_focal_hierarchy_v1"
const SOURCE_DIRECTION_STYLE_ID: String = "task_892_release_first_exchange_fire_direction_impact_clarity_v1"
const NEXT_TASK: String = "TASK_896 - Release First Exchange World Combat Focal Real Window Recapture"


static func build_snapshot(source: Dictionary, context: Dictionary = {}) -> Dictionary:
	var findings: Dictionary = Dictionary(source.get("findings", {})).duplicate(true)
	var direction: Dictionary = Dictionary(source.get("direction", {})).duplicate(true)
	var primary_render: Dictionary = Dictionary(source.get("primary_render_snapshot", {})).duplicate(true)
	var fire_vfx_entries: Array = Array(primary_render.get("weapon_fire_vfx_entries", [])).duplicate(true)
	var first_fire_vfx: Dictionary = Dictionary(fire_vfx_entries[0]).duplicate(true) if not fire_vfx_entries.is_empty() else {}
	var findings_ready: bool = String(findings.get("status", "")) == SOURCE_FINDINGS_STATUS \
		and String(findings.get("task_id", "")) == SOURCE_TASK_ID
	var direction_ready: bool = bool(direction.get("active", false)) \
		and String(direction.get("style_id", direction.get("primary_style_id", ""))) == SOURCE_DIRECTION_STYLE_ID
	var active: bool = bool(primary_render.get("release_first_exchange_world_combat_focal_hierarchy_active", false)) \
		and String(primary_render.get("release_first_exchange_world_combat_focal_hierarchy_style_id", "")) == STYLE_ID
	var lane_visible: bool = bool(primary_render.get("world_combat_focal_lane_visible", false)) \
		and bool(first_fire_vfx.get("world_combat_focal_lane_visible", false))
	var target_halo_visible: bool = bool(primary_render.get("world_combat_focal_target_halo_visible", false)) \
		and bool(first_fire_vfx.get("world_combat_focal_target_halo_visible", false))
	var source_glow_visible: bool = bool(primary_render.get("world_combat_focal_source_glow_visible", false)) \
		and bool(first_fire_vfx.get("world_combat_focal_source_glow_visible", false))
	var lane_width: float = float(primary_render.get("world_combat_focal_lane_width", first_fire_vfx.get("world_combat_focal_lane_width", 0.0)))
	var target_halo_radius: float = float(primary_render.get("world_combat_focal_target_halo_radius", first_fire_vfx.get("world_combat_focal_target_halo_radius", 0.0)))
	var source_glow_radius: float = float(primary_render.get("world_combat_focal_source_glow_radius", first_fire_vfx.get("world_combat_focal_source_glow_radius", 0.0)))
	var grid_dimming_active: bool = bool(primary_render.get("world_combat_focal_grid_noise_dimming_active", false))
	var world_line_dimming_active: bool = bool(primary_render.get("world_combat_focal_world_line_dimming_active", false))
	var checks: Array = [
		_check("source_findings_ready", findings_ready, "TASK_895 builds from TASK_894's world-combat focal finding."),
		_check("source_direction_path_ready", direction_ready, "TASK_895 keeps the TASK_892 direction/impact path active."),
		_check("primary_focal_hierarchy_style_active", active, "Primary3D reports the TASK_895 focal hierarchy style."),
		_check("source_to_target_lane_visible", lane_visible and lane_width > 0.095, "The first fire VFX exposes a stronger source-to-target focal lane."),
		_check("source_and_target_focus_visible", source_glow_visible and source_glow_radius > 0.24 and target_halo_visible and target_halo_radius > 0.78, "Source glow and target halo are visible and stronger than TASK_892."),
		_check("world_noise_dimmed", grid_dimming_active and float(primary_render.get("world_combat_focal_grid_noise_alpha", 1.0)) < 1.0 and world_line_dimming_active, "Grid/world noise is de-emphasized during the active exchange."),
		_check("read_only_boundaries", bool(source.get("read_only", false)) and bool(direction.get("read_only", false)) and not bool(source.get("ui_sets_gameplay_truth", true)) and not bool(source.get("creates_command", true)) and not bool(source.get("creates_fire_event", true)) and not bool(source.get("creates_damage_event", true)) and not bool(source.get("creates_movement", true)) and not bool(source.get("sets_multiplayer_truth", true)), "TASK_895 changes presentation only."),
	]
	var failed_checks: Array = []
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed_checks.append(String(check.get("id", "")))
	return {
		"schema": SCHEMA,
		"task_id": TASK_ID,
		"source_task_id": SOURCE_TASK_ID,
		"source_direction_task_id": SOURCE_DIRECTION_TASK_ID,
		"style_id": STYLE_ID,
		"source_direction_style_id": SOURCE_DIRECTION_STYLE_ID,
		"active": active,
		"findings_ready": findings_ready,
		"direction_ready": direction_ready,
		"world_combat_focal_lane_visible": lane_visible,
		"world_combat_focal_lane_width": lane_width,
		"world_combat_focal_target_halo_visible": target_halo_visible,
		"world_combat_focal_target_halo_radius": target_halo_radius,
		"world_combat_focal_source_glow_visible": source_glow_visible,
		"world_combat_focal_source_glow_radius": source_glow_radius,
		"world_combat_focal_grid_noise_dimming_active": grid_dimming_active,
		"world_combat_focal_grid_noise_alpha": float(primary_render.get("world_combat_focal_grid_noise_alpha", 1.0)),
		"world_combat_focal_world_line_dimming_active": world_line_dimming_active,
		"world_combat_focal_world_line_alpha_factor": float(primary_render.get("world_combat_focal_world_line_alpha_factor", 1.0)),
		"weapon_fire_vfx_visual_count": int(primary_render.get("weapon_fire_vfx_visual_count", 0)),
		"weapon_fire_vfx_entries": fire_vfx_entries,
		"findings": findings,
		"direction": direction,
		"primary_render_snapshot": primary_render,
		"checks": checks,
		"failed_checks": failed_checks,
		"gate": "pass" if failed_checks.is_empty() else "review",
		"visual_policy": "world_combat_focal_lane_source_glow_target_halo_grid_noise_dim",
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
