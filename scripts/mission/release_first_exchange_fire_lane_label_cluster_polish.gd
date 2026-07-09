class_name ReleaseFirstExchangeFireLaneLabelClusterPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_label_cluster_polish.v1"
const TASK_ID: String = "TASK_907"
const SOURCE_FINDINGS_TASK_ID: String = "TASK_906"
const SOURCE_FIRE_LANE_TASK_ID: String = "TASK_904"
const SOURCE_FIRE_LANE_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_readability_polish.v1"
const SOURCE_FIRE_LANE_STYLE_ID: String = "task_904_release_first_exchange_fire_lane_readability_v1"
const STYLE_ID: String = "task_907_release_first_exchange_fire_lane_label_cluster_v1"
const NEXT_TASK: String = "TASK_908 - Release First Exchange Fire Lane Label Cluster Real Window Recapture"


static func build_snapshot(source: Dictionary, context: Dictionary = {}) -> Dictionary:
	var findings: Dictionary = Dictionary(source.get("findings", {})).duplicate(true)
	var fire_lane: Dictionary = Dictionary(source.get("fire_lane", {})).duplicate(true)
	var primary_render: Dictionary = Dictionary(source.get("primary_render_snapshot", {})).duplicate(true)
	var fire_vfx_entries: Array = Array(primary_render.get("weapon_fire_vfx_entries", [])).duplicate(true)
	var first_fire_vfx: Dictionary = Dictionary(fire_vfx_entries[0]).duplicate(true) if not fire_vfx_entries.is_empty() else {}
	var findings_ready: bool = String(findings.get("task_id", "")) == SOURCE_FINDINGS_TASK_ID \
		and String(findings.get("status", "")) == "ready_for_fire_lane_label_cluster_polish" \
		and String(findings.get("primary_issue_id", "")) == "fire_lane_not_first_world_read"
	var fire_lane_ready: bool = String(fire_lane.get("schema", "")) == SOURCE_FIRE_LANE_SCHEMA \
		and String(fire_lane.get("task_id", "")) == SOURCE_FIRE_LANE_TASK_ID \
		and String(fire_lane.get("style_id", "")) == SOURCE_FIRE_LANE_STYLE_ID \
		and String(fire_lane.get("gate", "")) == "pass"
	var active: bool = bool(primary_render.get("release_first_exchange_fire_lane_label_cluster_polish_active", false)) \
		and String(primary_render.get("release_first_exchange_fire_lane_label_cluster_polish_style_id", "")) == STYLE_ID
	var vfx_active: bool = bool(first_fire_vfx.get("fire_lane_label_cluster_polish_active", false)) \
		and String(first_fire_vfx.get("fire_lane_label_cluster_polish_style_id", "")) == STYLE_ID
	var base_lane_width: float = float(fire_lane.get("world_combat_fire_lane_readability_lane_width", 0.0))
	var base_core_width: float = float(fire_lane.get("world_combat_fire_lane_readability_core_width", 0.0))
	var base_core_alpha: float = float(fire_lane.get("world_combat_fire_lane_readability_core_alpha", 0.0))
	var base_halo_radius: float = float(fire_lane.get("world_combat_fire_lane_readability_target_halo_radius", 0.0))
	var base_halo_alpha: float = float(fire_lane.get("world_combat_fire_lane_readability_target_halo_alpha", 0.0))
	var base_source_anchor_radius: float = float(fire_lane.get("world_combat_fire_lane_readability_source_anchor_radius", 0.0))
	var base_target_anchor_radius: float = float(fire_lane.get("world_combat_fire_lane_readability_target_anchor_radius", 0.0))
	var lane_width: float = float(primary_render.get("world_combat_fire_lane_label_cluster_lane_width", first_fire_vfx.get("world_combat_fire_lane_label_cluster_lane_width", 0.0)))
	var lane_alpha: float = float(primary_render.get("world_combat_fire_lane_label_cluster_lane_alpha", first_fire_vfx.get("world_combat_fire_lane_label_cluster_lane_alpha", 0.0)))
	var core_width: float = float(primary_render.get("world_combat_fire_lane_label_cluster_core_width", first_fire_vfx.get("world_combat_fire_lane_label_cluster_core_width", 0.0)))
	var core_alpha: float = float(primary_render.get("world_combat_fire_lane_label_cluster_core_alpha", first_fire_vfx.get("world_combat_fire_lane_label_cluster_core_alpha", 0.0)))
	var halo_radius: float = float(primary_render.get("world_combat_fire_lane_label_cluster_target_halo_radius", first_fire_vfx.get("world_combat_fire_lane_label_cluster_target_halo_radius", 0.0)))
	var halo_alpha: float = float(primary_render.get("world_combat_fire_lane_label_cluster_target_halo_alpha", first_fire_vfx.get("world_combat_fire_lane_label_cluster_target_halo_alpha", 0.0)))
	var source_anchor_radius: float = float(primary_render.get("world_combat_fire_lane_label_cluster_source_anchor_radius", first_fire_vfx.get("world_combat_fire_lane_label_cluster_source_anchor_radius", 0.0)))
	var target_anchor_radius: float = float(primary_render.get("world_combat_fire_lane_label_cluster_target_anchor_radius", first_fire_vfx.get("world_combat_fire_lane_label_cluster_target_anchor_radius", 0.0)))
	var label_font_size: int = int(primary_render.get("world_combat_fire_lane_label_cluster_status_label_font_size", first_fire_vfx.get("fire_status_label_font_size", 0)))
	var label_alpha: float = float(primary_render.get("world_combat_fire_lane_label_cluster_status_label_alpha", first_fire_vfx.get("fire_status_label_alpha", 0.0)))
	var label_offset_y: float = float(primary_render.get("world_combat_fire_lane_label_cluster_status_label_offset_y", first_fire_vfx.get("fire_status_label_offset_y", 0.0)))
	var checks: Array = [
		_check("source_findings_ready", findings_ready, "TASK_907 builds from TASK_906 visual findings."),
		_check("source_fire_lane_ready", fire_lane_ready, "TASK_907 keeps TASK_904 fire-lane as source path."),
		_check("primary_label_cluster_style_active", active and vfx_active, "Primary3D and first fire VFX report TASK_907."),
		_check("label_cluster_deemphasized", label_font_size > 0 and label_font_size <= 14 and label_alpha > 0.0 and label_alpha <= 0.62 and label_offset_y <= -40.0, "World FIRE/CONTACT label is smaller, quieter and offset away from target halo."),
		_check("lane_hierarchy_strengthened", lane_width >= base_lane_width and core_width >= base_core_width and core_width < lane_width and core_alpha >= base_core_alpha and core_alpha >= 0.90, "Fire-lane core carries first read more strongly than TASK_904."),
		_check("target_halo_quieter_than_task_904", halo_radius > 0.0 and halo_radius < base_halo_radius and halo_alpha < base_halo_alpha and halo_alpha <= 0.08, "Target halo is quieter than TASK_904."),
		_check("anchors_slightly_stronger_not_discs", source_anchor_radius > base_source_anchor_radius and source_anchor_radius <= 0.10 and target_anchor_radius > base_target_anchor_radius and target_anchor_radius <= 0.11, "Source/target anchors are stronger but still small."),
		_check("read_only_boundaries", bool(source.get("read_only", false)) and bool(findings.get("read_only", false)) and bool(fire_lane.get("read_only", false)) and not bool(source.get("ui_sets_gameplay_truth", true)) and not bool(source.get("creates_command", true)) and not bool(source.get("creates_fire_event", true)) and not bool(source.get("creates_damage_event", true)) and not bool(source.get("creates_movement", true)) and not bool(source.get("sets_multiplayer_truth", true)), "TASK_907 changes presentation only."),
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
		"source_fire_lane_task_id": SOURCE_FIRE_LANE_TASK_ID,
		"source_fire_lane_schema": SOURCE_FIRE_LANE_SCHEMA,
		"source_fire_lane_style_id": SOURCE_FIRE_LANE_STYLE_ID,
		"style_id": STYLE_ID,
		"active": active,
		"findings_ready": findings_ready,
		"fire_lane_ready": fire_lane_ready,
		"world_combat_fire_lane_label_cluster_lane_width": lane_width,
		"world_combat_fire_lane_label_cluster_lane_alpha": lane_alpha,
		"world_combat_fire_lane_label_cluster_core_width": core_width,
		"world_combat_fire_lane_label_cluster_core_alpha": core_alpha,
		"world_combat_fire_lane_label_cluster_target_halo_radius": halo_radius,
		"world_combat_fire_lane_label_cluster_target_halo_alpha": halo_alpha,
		"world_combat_fire_lane_label_cluster_source_anchor_radius": source_anchor_radius,
		"world_combat_fire_lane_label_cluster_target_anchor_radius": target_anchor_radius,
		"world_combat_fire_lane_label_cluster_status_label_font_size": label_font_size,
		"world_combat_fire_lane_label_cluster_status_label_alpha": label_alpha,
		"world_combat_fire_lane_label_cluster_status_label_offset_y": label_offset_y,
		"weapon_fire_vfx_visual_count": int(primary_render.get("weapon_fire_vfx_visual_count", 0)),
		"weapon_fire_vfx_entries": fire_vfx_entries,
		"findings": findings,
		"fire_lane": fire_lane,
		"primary_render_snapshot": primary_render,
		"checks": checks,
		"failed_checks": failed_checks,
		"gate": "pass" if failed_checks.is_empty() else "review",
		"visual_policy": "deemphasized_world_label_quieter_halo_stronger_lane_core",
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
