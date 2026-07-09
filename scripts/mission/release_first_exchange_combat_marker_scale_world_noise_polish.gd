class_name ReleaseFirstExchangeCombatMarkerScaleWorldNoisePolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_combat_marker_scale_world_noise_polish.v1"
const TASK_ID: String = "TASK_901"
const SOURCE_TASK_ID: String = "TASK_900"
const SOURCE_ELEGANCE_TASK_ID: String = "TASK_898"
const SOURCE_FOCAL_TASK_ID: String = "TASK_895"
const SOURCE_FINDINGS_STATUS: String = "ready_for_marker_scale_world_noise_polish"
const SOURCE_ELEGANCE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_combat_focal_elegance_polish.v1"
const SOURCE_ELEGANCE_STYLE_ID: String = "task_898_release_first_exchange_combat_focal_elegance_v1"
const STYLE_ID: String = "task_901_release_first_exchange_combat_marker_scale_world_noise_v1"
const NEXT_TASK: String = "TASK_902 - Release First Exchange Combat Marker Scale Real Window Recapture"


static func build_snapshot(source: Dictionary, context: Dictionary = {}) -> Dictionary:
	var findings: Dictionary = Dictionary(source.get("findings", {})).duplicate(true)
	var elegance: Dictionary = Dictionary(source.get("elegance", {})).duplicate(true)
	var primary_render: Dictionary = Dictionary(source.get("primary_render_snapshot", {})).duplicate(true)
	var fire_vfx_entries: Array = Array(primary_render.get("weapon_fire_vfx_entries", [])).duplicate(true)
	var first_fire_vfx: Dictionary = Dictionary(fire_vfx_entries[0]).duplicate(true) if not fire_vfx_entries.is_empty() else {}
	var findings_ready: bool = String(findings.get("status", "")) == SOURCE_FINDINGS_STATUS \
		and String(findings.get("task_id", "")) == SOURCE_TASK_ID
	var elegance_ready: bool = String(elegance.get("gate", "")) == "pass" \
		and String(elegance.get("schema", "")) == SOURCE_ELEGANCE_SCHEMA \
		and String(elegance.get("style_id", "")) == SOURCE_ELEGANCE_STYLE_ID
	var active: bool = bool(primary_render.get("release_first_exchange_combat_marker_scale_world_noise_polish_active", false)) \
		and String(primary_render.get("release_first_exchange_combat_marker_scale_world_noise_polish_style_id", "")) == STYLE_ID
	var marker_active: bool = bool(first_fire_vfx.get("combat_marker_scale_world_noise_polish_active", false)) \
		and String(first_fire_vfx.get("combat_marker_scale_world_noise_polish_style_id", "")) == STYLE_ID
	var halo_visible: bool = bool(primary_render.get("world_combat_marker_scale_target_halo_visible", false)) \
		and bool(first_fire_vfx.get("world_combat_marker_scale_target_halo_visible", false))
	var lane_visible: bool = bool(primary_render.get("world_combat_marker_scale_lane_visible", false)) \
		and bool(first_fire_vfx.get("world_combat_marker_scale_lane_visible", false))
	var source_glow_visible: bool = bool(primary_render.get("world_combat_marker_scale_source_glow_visible", false)) \
		and bool(first_fire_vfx.get("world_combat_marker_scale_source_glow_visible", false))
	var halo_radius: float = float(primary_render.get("world_combat_marker_scale_target_halo_radius", first_fire_vfx.get("world_combat_marker_scale_target_halo_radius", 0.0)))
	var halo_alpha: float = float(primary_render.get("world_combat_marker_scale_target_halo_alpha", first_fire_vfx.get("world_combat_marker_scale_target_halo_alpha", 0.0)))
	var focus_radius: float = float(primary_render.get("world_combat_marker_scale_target_focus_radius", first_fire_vfx.get("world_combat_marker_scale_target_focus_radius", 0.0)))
	var lane_width: float = float(primary_render.get("world_combat_marker_scale_lane_width", first_fire_vfx.get("world_combat_marker_scale_lane_width", 0.0)))
	var lane_alpha: float = float(primary_render.get("world_combat_marker_scale_lane_alpha", first_fire_vfx.get("world_combat_marker_scale_lane_alpha", 0.0)))
	var source_glow_radius: float = float(primary_render.get("world_combat_marker_scale_source_glow_radius", first_fire_vfx.get("world_combat_marker_scale_source_glow_radius", 0.0)))
	var source_glow_alpha: float = float(primary_render.get("world_combat_marker_scale_source_glow_alpha", first_fire_vfx.get("world_combat_marker_scale_source_glow_alpha", 0.0)))
	var grid_noise_alpha: float = float(primary_render.get("world_combat_marker_scale_grid_noise_alpha", 1.0))
	var world_line_alpha_factor: float = float(primary_render.get("world_combat_marker_scale_world_line_alpha_factor", 1.0))
	var world_line_width_factor: float = float(primary_render.get("world_combat_marker_scale_world_line_width_factor", 1.0))
	var checks: Array = [
		_check("source_findings_ready", findings_ready, "TASK_901 builds from TASK_900 marker/world-noise findings."),
		_check("source_elegance_path_ready", elegance_ready, "TASK_901 keeps TASK_898 focal elegance as its source path."),
		_check("primary_marker_scale_style_active", active and marker_active, "Primary3D and the first fire VFX report TASK_901."),
		_check("target_marker_scaled_down", halo_visible and halo_radius > 0.0 and halo_radius < 0.64 and halo_alpha < 0.24 and focus_radius > 0.0 and focus_radius < 0.72, "Target halo and focus are smaller and less marker-like than TASK_898."),
		_check("source_to_target_lane_still_reads", lane_visible and lane_width > 0.045 and lane_width < 0.082 and lane_alpha >= 0.58, "The source-to-target lane stays readable while the target marker shrinks."),
		_check("source_glow_reduced", source_glow_visible and source_glow_radius < 0.23 and source_glow_alpha < 0.36, "Source glow is quieter than TASK_898."),
		_check("world_noise_reduced", grid_noise_alpha < 0.42 and world_line_alpha_factor < 0.34 and world_line_width_factor < 0.42, "Grid and world-line noise are more subdued than TASK_898/895."),
		_check("read_only_boundaries", bool(source.get("read_only", false)) and bool(elegance.get("read_only", false)) and not bool(source.get("ui_sets_gameplay_truth", true)) and not bool(source.get("creates_command", true)) and not bool(source.get("creates_fire_event", true)) and not bool(source.get("creates_damage_event", true)) and not bool(source.get("creates_movement", true)) and not bool(source.get("sets_multiplayer_truth", true)), "TASK_901 changes presentation only."),
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
		"source_elegance_task_id": SOURCE_ELEGANCE_TASK_ID,
		"source_focal_task_id": SOURCE_FOCAL_TASK_ID,
		"style_id": STYLE_ID,
		"source_elegance_schema": SOURCE_ELEGANCE_SCHEMA,
		"source_elegance_style_id": SOURCE_ELEGANCE_STYLE_ID,
		"active": active,
		"findings_ready": findings_ready,
		"elegance_ready": elegance_ready,
		"world_combat_marker_scale_lane_visible": lane_visible,
		"world_combat_marker_scale_lane_width": lane_width,
		"world_combat_marker_scale_lane_alpha": lane_alpha,
		"world_combat_marker_scale_target_halo_visible": halo_visible,
		"world_combat_marker_scale_target_halo_radius": halo_radius,
		"world_combat_marker_scale_target_halo_alpha": halo_alpha,
		"world_combat_marker_scale_target_focus_radius": focus_radius,
		"world_combat_marker_scale_source_glow_visible": source_glow_visible,
		"world_combat_marker_scale_source_glow_radius": source_glow_radius,
		"world_combat_marker_scale_source_glow_alpha": source_glow_alpha,
		"world_combat_marker_scale_grid_noise_dimming_active": bool(primary_render.get("world_combat_marker_scale_grid_noise_dimming_active", false)),
		"world_combat_marker_scale_grid_noise_alpha": grid_noise_alpha,
		"world_combat_marker_scale_world_line_dimming_active": bool(primary_render.get("world_combat_marker_scale_world_line_dimming_active", false)),
		"world_combat_marker_scale_world_line_alpha_factor": world_line_alpha_factor,
		"world_combat_marker_scale_world_line_width_factor": world_line_width_factor,
		"weapon_fire_vfx_visual_count": int(primary_render.get("weapon_fire_vfx_visual_count", 0)),
		"weapon_fire_vfx_entries": fire_vfx_entries,
		"findings": findings,
		"elegance": elegance,
		"primary_render_snapshot": primary_render,
		"checks": checks,
		"failed_checks": failed_checks,
		"gate": "pass" if failed_checks.is_empty() else "review",
		"visual_policy": "smaller_target_halo_quieter_source_glow_reduced_grid_world_noise",
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
