class_name ReleaseFirstExchangeFireLaneReadabilityPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_readability_polish.v1"
const TASK_ID: String = "TASK_904"
const SOURCE_TASK_ID: String = "TASK_903"
const SOURCE_MARKER_SCALE_TASK_ID: String = "TASK_901"
const SOURCE_FINDINGS_STATUS: String = "ready_for_fire_lane_readability_polish"
const SOURCE_MARKER_SCALE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_combat_marker_scale_world_noise_polish.v1"
const SOURCE_MARKER_SCALE_STYLE_ID: String = "task_901_release_first_exchange_combat_marker_scale_world_noise_v1"
const STYLE_ID: String = "task_904_release_first_exchange_fire_lane_readability_v1"
const NEXT_TASK: String = "TASK_905 - Release First Exchange Fire Lane Real Window Recapture"


static func build_snapshot(source: Dictionary, context: Dictionary = {}) -> Dictionary:
	var findings: Dictionary = Dictionary(source.get("findings", {})).duplicate(true)
	var marker_scale: Dictionary = Dictionary(source.get("marker_scale", {})).duplicate(true)
	var primary_render: Dictionary = Dictionary(source.get("primary_render_snapshot", {})).duplicate(true)
	var fire_vfx_entries: Array = Array(primary_render.get("weapon_fire_vfx_entries", [])).duplicate(true)
	var first_fire_vfx: Dictionary = Dictionary(fire_vfx_entries[0]).duplicate(true) if not fire_vfx_entries.is_empty() else {}
	var findings_ready: bool = String(findings.get("status", "")) == SOURCE_FINDINGS_STATUS \
		and String(findings.get("task_id", "")) == SOURCE_TASK_ID \
		and String(findings.get("primary_issue_id", "")) == "fire_lane_still_too_subtle"
	var marker_scale_ready: bool = String(marker_scale.get("gate", "")) == "pass" \
		and String(marker_scale.get("schema", "")) == SOURCE_MARKER_SCALE_SCHEMA \
		and String(marker_scale.get("style_id", "")) == SOURCE_MARKER_SCALE_STYLE_ID
	var active: bool = bool(primary_render.get("release_first_exchange_fire_lane_readability_polish_active", false)) \
		and String(primary_render.get("release_first_exchange_fire_lane_readability_polish_style_id", "")) == STYLE_ID
	var vfx_active: bool = bool(first_fire_vfx.get("fire_lane_readability_polish_active", false)) \
		and String(first_fire_vfx.get("fire_lane_readability_polish_style_id", "")) == STYLE_ID
	var lane_visible: bool = bool(primary_render.get("world_combat_fire_lane_readability_lane_visible", false)) \
		and bool(first_fire_vfx.get("world_combat_fire_lane_readability_lane_visible", false))
	var core_visible: bool = bool(primary_render.get("world_combat_fire_lane_readability_core_visible", false)) \
		and bool(first_fire_vfx.get("world_combat_fire_lane_readability_core_visible", false))
	var source_anchor_visible: bool = bool(primary_render.get("world_combat_fire_lane_readability_source_anchor_visible", false)) \
		and bool(first_fire_vfx.get("world_combat_fire_lane_readability_source_anchor_visible", false))
	var target_anchor_visible: bool = bool(primary_render.get("world_combat_fire_lane_readability_target_anchor_visible", false)) \
		and bool(first_fire_vfx.get("world_combat_fire_lane_readability_target_anchor_visible", false))
	var halo_visible: bool = bool(primary_render.get("world_combat_fire_lane_readability_target_halo_visible", false)) \
		and bool(first_fire_vfx.get("world_combat_fire_lane_readability_target_halo_visible", false))
	var source_glow_visible: bool = bool(primary_render.get("world_combat_fire_lane_readability_source_glow_visible", false)) \
		and bool(first_fire_vfx.get("world_combat_fire_lane_readability_source_glow_visible", false))
	var marker_lane_width: float = float(marker_scale.get("world_combat_marker_scale_lane_width", 0.0))
	var marker_lane_alpha: float = float(marker_scale.get("world_combat_marker_scale_lane_alpha", 0.0))
	var marker_halo_radius: float = float(marker_scale.get("world_combat_marker_scale_target_halo_radius", 0.0))
	var marker_halo_alpha: float = float(marker_scale.get("world_combat_marker_scale_target_halo_alpha", 0.0))
	var marker_source_glow_radius: float = float(marker_scale.get("world_combat_marker_scale_source_glow_radius", 0.0))
	var marker_grid_alpha: float = float(marker_scale.get("world_combat_marker_scale_grid_noise_alpha", 1.0))
	var marker_world_alpha_factor: float = float(marker_scale.get("world_combat_marker_scale_world_line_alpha_factor", 1.0))
	var lane_width: float = float(primary_render.get("world_combat_fire_lane_readability_lane_width", first_fire_vfx.get("world_combat_fire_lane_readability_lane_width", 0.0)))
	var lane_alpha: float = float(primary_render.get("world_combat_fire_lane_readability_lane_alpha", first_fire_vfx.get("world_combat_fire_lane_readability_lane_alpha", 0.0)))
	var core_width: float = float(primary_render.get("world_combat_fire_lane_readability_core_width", first_fire_vfx.get("world_combat_fire_lane_readability_core_width", 0.0)))
	var core_alpha: float = float(primary_render.get("world_combat_fire_lane_readability_core_alpha", first_fire_vfx.get("world_combat_fire_lane_readability_core_alpha", 0.0)))
	var halo_radius: float = float(primary_render.get("world_combat_fire_lane_readability_target_halo_radius", first_fire_vfx.get("world_combat_fire_lane_readability_target_halo_radius", 0.0)))
	var halo_alpha: float = float(primary_render.get("world_combat_fire_lane_readability_target_halo_alpha", first_fire_vfx.get("world_combat_fire_lane_readability_target_halo_alpha", 0.0)))
	var target_focus_radius: float = float(primary_render.get("world_combat_fire_lane_readability_target_focus_radius", first_fire_vfx.get("world_combat_fire_lane_readability_target_focus_radius", 0.0)))
	var source_glow_radius: float = float(primary_render.get("world_combat_fire_lane_readability_source_glow_radius", first_fire_vfx.get("world_combat_fire_lane_readability_source_glow_radius", 0.0)))
	var source_glow_alpha: float = float(primary_render.get("world_combat_fire_lane_readability_source_glow_alpha", first_fire_vfx.get("world_combat_fire_lane_readability_source_glow_alpha", 0.0)))
	var source_anchor_radius: float = float(primary_render.get("world_combat_fire_lane_readability_source_anchor_radius", first_fire_vfx.get("world_combat_fire_lane_readability_source_anchor_radius", 0.0)))
	var target_anchor_radius: float = float(primary_render.get("world_combat_fire_lane_readability_target_anchor_radius", first_fire_vfx.get("world_combat_fire_lane_readability_target_anchor_radius", 0.0)))
	var grid_noise_alpha: float = float(primary_render.get("world_combat_fire_lane_readability_grid_noise_alpha", 1.0))
	var world_line_alpha_factor: float = float(primary_render.get("world_combat_fire_lane_readability_world_line_alpha_factor", 1.0))
	var world_line_width_factor: float = float(primary_render.get("world_combat_fire_lane_readability_world_line_width_factor", 1.0))
	var checks: Array = [
		_check("source_findings_ready", findings_ready, "TASK_904 builds from TASK_903 fire-lane findings."),
		_check("source_marker_scale_path_ready", marker_scale_ready, "TASK_904 keeps TASK_901 marker/world-noise polish as source path."),
		_check("primary_fire_lane_style_active", active and vfx_active, "Primary3D and first fire VFX report TASK_904."),
		_check("fire_lane_first_read_stronger", lane_visible and core_visible and lane_width > marker_lane_width and lane_width <= 0.10 and lane_alpha >= marker_lane_alpha - 0.12 and core_width > 0.02 and core_width < lane_width and core_alpha >= 0.82, "Fire lane gets a clearer soft guide plus a narrow bright core."),
		_check("anchors_small_not_marker_disc", source_anchor_visible and target_anchor_visible and source_anchor_radius > 0.0 and source_anchor_radius <= 0.08 and target_anchor_radius > 0.0 and target_anchor_radius <= 0.09, "Source/target anchors clarify direction without large marker discs."),
		_check("target_marker_stays_quiet", halo_visible and halo_radius > 0.0 and halo_radius <= marker_halo_radius and halo_alpha <= marker_halo_alpha and target_focus_radius <= 0.50, "Target halo/focus stay quieter than TASK_901."),
		_check("source_glow_stays_quiet", source_glow_visible and source_glow_radius <= marker_source_glow_radius and source_glow_alpha <= 0.32, "Source glow remains a cue, not a blob."),
		_check("world_noise_remains_subdued", grid_noise_alpha <= marker_grid_alpha and world_line_alpha_factor <= marker_world_alpha_factor and world_line_width_factor < 0.34, "Grid/world-line noise stays below TASK_901."),
		_check("read_only_boundaries", bool(source.get("read_only", false)) and bool(findings.get("read_only", false)) and bool(marker_scale.get("read_only", false)) and not bool(source.get("ui_sets_gameplay_truth", true)) and not bool(source.get("creates_command", true)) and not bool(source.get("creates_fire_event", true)) and not bool(source.get("creates_damage_event", true)) and not bool(source.get("creates_movement", true)) and not bool(source.get("sets_multiplayer_truth", true)), "TASK_904 changes presentation only."),
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
		"source_marker_scale_task_id": SOURCE_MARKER_SCALE_TASK_ID,
		"style_id": STYLE_ID,
		"source_marker_scale_schema": SOURCE_MARKER_SCALE_SCHEMA,
		"source_marker_scale_style_id": SOURCE_MARKER_SCALE_STYLE_ID,
		"active": active,
		"findings_ready": findings_ready,
		"marker_scale_ready": marker_scale_ready,
		"world_combat_fire_lane_readability_lane_visible": lane_visible,
		"world_combat_fire_lane_readability_lane_width": lane_width,
		"world_combat_fire_lane_readability_lane_alpha": lane_alpha,
		"world_combat_fire_lane_readability_core_visible": core_visible,
		"world_combat_fire_lane_readability_core_width": core_width,
		"world_combat_fire_lane_readability_core_alpha": core_alpha,
		"world_combat_fire_lane_readability_target_halo_visible": halo_visible,
		"world_combat_fire_lane_readability_target_halo_radius": halo_radius,
		"world_combat_fire_lane_readability_target_halo_alpha": halo_alpha,
		"world_combat_fire_lane_readability_target_focus_radius": target_focus_radius,
		"world_combat_fire_lane_readability_source_glow_visible": source_glow_visible,
		"world_combat_fire_lane_readability_source_glow_radius": source_glow_radius,
		"world_combat_fire_lane_readability_source_glow_alpha": source_glow_alpha,
		"world_combat_fire_lane_readability_source_anchor_visible": source_anchor_visible,
		"world_combat_fire_lane_readability_source_anchor_radius": source_anchor_radius,
		"world_combat_fire_lane_readability_target_anchor_visible": target_anchor_visible,
		"world_combat_fire_lane_readability_target_anchor_radius": target_anchor_radius,
		"world_combat_fire_lane_readability_grid_noise_dimming_active": bool(primary_render.get("world_combat_fire_lane_readability_grid_noise_dimming_active", false)),
		"world_combat_fire_lane_readability_grid_noise_alpha": grid_noise_alpha,
		"world_combat_fire_lane_readability_world_line_dimming_active": bool(primary_render.get("world_combat_fire_lane_readability_world_line_dimming_active", false)),
		"world_combat_fire_lane_readability_world_line_alpha_factor": world_line_alpha_factor,
		"world_combat_fire_lane_readability_world_line_width_factor": world_line_width_factor,
		"weapon_fire_vfx_visual_count": int(primary_render.get("weapon_fire_vfx_visual_count", 0)),
		"weapon_fire_vfx_entries": fire_vfx_entries,
		"findings": findings,
		"marker_scale": marker_scale,
		"primary_render_snapshot": primary_render,
		"checks": checks,
		"failed_checks": failed_checks,
		"gate": "pass" if failed_checks.is_empty() else "review",
		"visual_policy": "soft_lane_plus_bright_core_with_small_anchors",
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
