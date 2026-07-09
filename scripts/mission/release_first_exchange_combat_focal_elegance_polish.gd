class_name ReleaseFirstExchangeCombatFocalElegancePolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_combat_focal_elegance_polish.v1"
const TASK_ID: String = "TASK_898"
const SOURCE_TASK_ID: String = "TASK_897"
const SOURCE_FOCAL_TASK_ID: String = "TASK_895"
const SOURCE_FINDINGS_STATUS: String = "ready_for_focal_elegance_polish"
const SOURCE_FOCAL_SCHEMA: String = "sternenbuergerchen.release_first_exchange_world_combat_focal_hierarchy_polish.v1"
const SOURCE_FOCAL_STYLE_ID: String = "task_895_release_first_exchange_world_combat_focal_hierarchy_v1"
const STYLE_ID: String = "task_898_release_first_exchange_combat_focal_elegance_v1"
const NEXT_TASK: String = "TASK_899 - Release First Exchange Combat Focal Elegance Real Window Recapture"


static func build_snapshot(source: Dictionary, context: Dictionary = {}) -> Dictionary:
	var findings: Dictionary = Dictionary(source.get("findings", {})).duplicate(true)
	var focal: Dictionary = Dictionary(source.get("focal", {})).duplicate(true)
	var primary_render: Dictionary = Dictionary(source.get("primary_render_snapshot", {})).duplicate(true)
	var fire_vfx_entries: Array = Array(primary_render.get("weapon_fire_vfx_entries", [])).duplicate(true)
	var first_fire_vfx: Dictionary = Dictionary(fire_vfx_entries[0]).duplicate(true) if not fire_vfx_entries.is_empty() else {}
	var findings_ready: bool = String(findings.get("status", "")) == SOURCE_FINDINGS_STATUS \
		and String(findings.get("task_id", "")) == SOURCE_TASK_ID
	var focal_ready: bool = String(focal.get("gate", "")) == "pass" \
		and String(focal.get("schema", "")) == SOURCE_FOCAL_SCHEMA \
		and String(focal.get("style_id", "")) == SOURCE_FOCAL_STYLE_ID
	var active: bool = bool(primary_render.get("release_first_exchange_combat_focal_elegance_polish_active", false)) \
		and String(primary_render.get("release_first_exchange_combat_focal_elegance_polish_style_id", "")) == STYLE_ID
	var lane_visible: bool = bool(primary_render.get("world_combat_focal_elegance_lane_visible", false)) \
		and bool(first_fire_vfx.get("world_combat_focal_elegance_lane_visible", false))
	var target_halo_visible: bool = bool(primary_render.get("world_combat_focal_elegance_target_halo_visible", false)) \
		and bool(first_fire_vfx.get("world_combat_focal_elegance_target_halo_visible", false))
	var source_glow_visible: bool = bool(primary_render.get("world_combat_focal_elegance_source_glow_visible", false)) \
		and bool(first_fire_vfx.get("world_combat_focal_elegance_source_glow_visible", false))
	var lane_width: float = float(primary_render.get("world_combat_focal_elegance_lane_width", first_fire_vfx.get("world_combat_focal_elegance_lane_width", 0.0)))
	var lane_alpha: float = float(primary_render.get("world_combat_focal_elegance_lane_alpha", first_fire_vfx.get("world_combat_focal_elegance_lane_alpha", 0.0)))
	var target_halo_radius: float = float(primary_render.get("world_combat_focal_elegance_target_halo_radius", first_fire_vfx.get("world_combat_focal_elegance_target_halo_radius", 0.0)))
	var target_halo_alpha: float = float(primary_render.get("world_combat_focal_elegance_target_halo_alpha", first_fire_vfx.get("world_combat_focal_elegance_target_halo_alpha", 0.0)))
	var source_glow_radius: float = float(primary_render.get("world_combat_focal_elegance_source_glow_radius", first_fire_vfx.get("world_combat_focal_elegance_source_glow_radius", 0.0)))
	var source_glow_alpha: float = float(primary_render.get("world_combat_focal_elegance_source_glow_alpha", first_fire_vfx.get("world_combat_focal_elegance_source_glow_alpha", 0.0)))
	var debug_reduced: bool = bool(primary_render.get("world_combat_focal_elegance_debugginess_reduced", false)) \
		and bool(first_fire_vfx.get("world_combat_focal_elegance_debugginess_reduced", false))
	var checks: Array = [
		_check("source_findings_ready", findings_ready, "TASK_898 builds from TASK_897's focal-elegance finding."),
		_check("source_focal_path_ready", focal_ready, "TASK_898 keeps the TASK_895 focal hierarchy path active."),
		_check("primary_elegance_style_active", active, "Primary3D reports the TASK_898 focal elegance style."),
		_check("elegant_lane_visible_and_softer", lane_visible and lane_width > 0.055 and lane_width < 0.135 and lane_alpha < 0.92, "The source-to-target lane stays visible but is softer than TASK_895."),
		_check("halo_and_source_less_debuggy", target_halo_visible and source_glow_visible and target_halo_radius < 0.98 and target_halo_alpha < 0.42 and source_glow_radius < 0.34 and source_glow_alpha < 0.58, "Target halo and source glow stay visible but less blocky/debug-like than TASK_895."),
		_check("debugginess_reduced", debug_reduced, "Render metadata explicitly marks TASK_898 as reducing the debug-like focal read."),
		_check("read_only_boundaries", bool(source.get("read_only", false)) and bool(focal.get("read_only", false)) and not bool(source.get("ui_sets_gameplay_truth", true)) and not bool(source.get("creates_command", true)) and not bool(source.get("creates_fire_event", true)) and not bool(source.get("creates_damage_event", true)) and not bool(source.get("creates_movement", true)) and not bool(source.get("sets_multiplayer_truth", true)), "TASK_898 changes presentation only."),
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
		"source_focal_task_id": SOURCE_FOCAL_TASK_ID,
		"style_id": STYLE_ID,
		"source_focal_schema": SOURCE_FOCAL_SCHEMA,
		"source_focal_style_id": SOURCE_FOCAL_STYLE_ID,
		"active": active,
		"findings_ready": findings_ready,
		"focal_ready": focal_ready,
		"world_combat_focal_elegance_lane_visible": lane_visible,
		"world_combat_focal_elegance_lane_width": lane_width,
		"world_combat_focal_elegance_lane_alpha": lane_alpha,
		"world_combat_focal_elegance_target_halo_visible": target_halo_visible,
		"world_combat_focal_elegance_target_halo_radius": target_halo_radius,
		"world_combat_focal_elegance_target_halo_alpha": target_halo_alpha,
		"world_combat_focal_elegance_source_glow_visible": source_glow_visible,
		"world_combat_focal_elegance_source_glow_radius": source_glow_radius,
		"world_combat_focal_elegance_source_glow_alpha": source_glow_alpha,
		"world_combat_focal_elegance_debugginess_reduced": debug_reduced,
		"weapon_fire_vfx_visual_count": int(primary_render.get("weapon_fire_vfx_visual_count", 0)),
		"weapon_fire_vfx_entries": fire_vfx_entries,
		"findings": findings,
		"focal": focal,
		"primary_render_snapshot": primary_render,
		"checks": checks,
		"failed_checks": failed_checks,
		"gate": "pass" if failed_checks.is_empty() else "review",
		"visual_policy": "soft_source_to_target_lane_ring_halo_subtle_source_glow",
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
