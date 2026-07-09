class_name ReleaseFirstExchangeFireLaneWorldReadMicroPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_world_read_micro_polish.v1"
const TASK_ID: String = "TASK_910"
const SOURCE_FINDINGS_TASK_ID: String = "TASK_909"
const SOURCE_LABEL_CLUSTER_TASK_ID: String = "TASK_907"
const SOURCE_LABEL_CLUSTER_SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_lane_label_cluster_polish.v1"
const SOURCE_LABEL_CLUSTER_STYLE_ID: String = "task_907_release_first_exchange_fire_lane_label_cluster_v1"
const STYLE_ID: String = "task_910_release_first_exchange_fire_lane_world_read_micro_v1"
const NEXT_TASK: String = "TASK_911 - Release First Exchange Fire Lane World Read Real Window Recapture"


static func build_snapshot(source: Dictionary, context: Dictionary = {}) -> Dictionary:
	var findings: Dictionary = Dictionary(source.get("findings", {})).duplicate(true)
	var label_cluster: Dictionary = Dictionary(source.get("label_cluster", {})).duplicate(true)
	var primary_render: Dictionary = Dictionary(source.get("primary_render_snapshot", {})).duplicate(true)
	var fire_vfx_entries: Array = Array(primary_render.get("weapon_fire_vfx_entries", [])).duplicate(true)
	var first_fire_vfx: Dictionary = Dictionary(fire_vfx_entries[0]).duplicate(true) if not fire_vfx_entries.is_empty() else {}
	var findings_ready: bool = String(findings.get("task_id", "")) == SOURCE_FINDINGS_TASK_ID \
		and String(findings.get("status", "")) == "ready_for_world_read_micro_polish" \
		and String(findings.get("primary_issue_id", "")) == "label_halo_cluster_still_first_read"
	var label_cluster_ready: bool = String(label_cluster.get("schema", "")) == SOURCE_LABEL_CLUSTER_SCHEMA \
		and String(label_cluster.get("task_id", "")) == SOURCE_LABEL_CLUSTER_TASK_ID \
		and String(label_cluster.get("style_id", "")) == SOURCE_LABEL_CLUSTER_STYLE_ID \
		and String(label_cluster.get("gate", "")) == "pass"
	var active: bool = bool(primary_render.get("release_first_exchange_fire_lane_world_read_micro_polish_active", false)) \
		and String(primary_render.get("release_first_exchange_fire_lane_world_read_micro_polish_style_id", "")) == STYLE_ID
	var vfx_active: bool = bool(first_fire_vfx.get("fire_lane_world_read_micro_polish_active", false)) \
		and String(first_fire_vfx.get("fire_lane_world_read_micro_polish_style_id", "")) == STYLE_ID
	var base_lane_width: float = float(label_cluster.get("world_combat_fire_lane_label_cluster_lane_width", 0.0))
	var base_lane_alpha: float = float(label_cluster.get("world_combat_fire_lane_label_cluster_lane_alpha", 0.0))
	var base_core_width: float = float(label_cluster.get("world_combat_fire_lane_label_cluster_core_width", 0.0))
	var base_core_alpha: float = float(label_cluster.get("world_combat_fire_lane_label_cluster_core_alpha", 0.0))
	var base_halo_radius: float = float(label_cluster.get("world_combat_fire_lane_label_cluster_target_halo_radius", 0.0))
	var base_halo_alpha: float = float(label_cluster.get("world_combat_fire_lane_label_cluster_target_halo_alpha", 0.0))
	var base_source_anchor_radius: float = float(label_cluster.get("world_combat_fire_lane_label_cluster_source_anchor_radius", 0.0))
	var base_target_anchor_radius: float = float(label_cluster.get("world_combat_fire_lane_label_cluster_target_anchor_radius", 0.0))
	var base_label_font_size: int = int(label_cluster.get("world_combat_fire_lane_label_cluster_status_label_font_size", 99))
	var base_label_alpha: float = float(label_cluster.get("world_combat_fire_lane_label_cluster_status_label_alpha", 1.0))
	var base_label_offset_y: float = float(label_cluster.get("world_combat_fire_lane_label_cluster_status_label_offset_y", 0.0))
	var lane_width: float = float(primary_render.get("world_combat_fire_lane_world_read_micro_lane_width", first_fire_vfx.get("world_combat_fire_lane_world_read_micro_lane_width", 0.0)))
	var lane_alpha: float = float(primary_render.get("world_combat_fire_lane_world_read_micro_lane_alpha", first_fire_vfx.get("world_combat_fire_lane_world_read_micro_lane_alpha", 0.0)))
	var core_width: float = float(primary_render.get("world_combat_fire_lane_world_read_micro_core_width", first_fire_vfx.get("world_combat_fire_lane_world_read_micro_core_width", 0.0)))
	var core_alpha: float = float(primary_render.get("world_combat_fire_lane_world_read_micro_core_alpha", first_fire_vfx.get("world_combat_fire_lane_world_read_micro_core_alpha", 0.0)))
	var halo_radius: float = float(primary_render.get("world_combat_fire_lane_world_read_micro_target_halo_radius", first_fire_vfx.get("world_combat_fire_lane_world_read_micro_target_halo_radius", 0.0)))
	var halo_alpha: float = float(primary_render.get("world_combat_fire_lane_world_read_micro_target_halo_alpha", first_fire_vfx.get("world_combat_fire_lane_world_read_micro_target_halo_alpha", 0.0)))
	var source_anchor_radius: float = float(primary_render.get("world_combat_fire_lane_world_read_micro_source_anchor_radius", first_fire_vfx.get("world_combat_fire_lane_world_read_micro_source_anchor_radius", 0.0)))
	var target_anchor_radius: float = float(primary_render.get("world_combat_fire_lane_world_read_micro_target_anchor_radius", first_fire_vfx.get("world_combat_fire_lane_world_read_micro_target_anchor_radius", 0.0)))
	var label_font_size: int = int(primary_render.get("world_combat_fire_lane_world_read_micro_status_label_font_size", first_fire_vfx.get("fire_status_label_font_size", 0)))
	var label_alpha: float = float(primary_render.get("world_combat_fire_lane_world_read_micro_status_label_alpha", first_fire_vfx.get("fire_status_label_alpha", 0.0)))
	var label_offset_y: float = float(primary_render.get("world_combat_fire_lane_world_read_micro_status_label_offset_y", first_fire_vfx.get("fire_status_label_offset_y", 0.0)))
	var checks: Array = [
		_check("source_findings_ready", findings_ready, "TASK_910 builds from TASK_909 visual findings."),
		_check("source_label_cluster_ready", label_cluster_ready, "TASK_910 keeps TASK_907 as source path."),
		_check("primary_world_read_style_active", active and vfx_active, "Primary3D and first fire VFX report TASK_910."),
		_check("label_cluster_further_deemphasized", label_font_size > 0 and label_font_size < base_label_font_size and label_alpha > 0.0 and label_alpha < base_label_alpha and label_offset_y < base_label_offset_y, "World FIRE/CONTACT label is smaller, quieter and moved farther away."),
		_check("fire_lane_core_primary_read_strengthened", lane_width > base_lane_width and lane_alpha <= base_lane_alpha and core_width > base_core_width and core_alpha > base_core_alpha and core_alpha >= 0.94, "Fire-lane core carries the first read more strongly."),
		_check("target_halo_retreats", halo_radius > 0.0 and halo_radius < base_halo_radius and halo_alpha < base_halo_alpha and halo_alpha <= 0.05, "Target halo retreats behind the fire lane."),
		_check("anchors_stronger_without_marker_discs", source_anchor_radius > base_source_anchor_radius and source_anchor_radius <= 0.13 and target_anchor_radius > base_target_anchor_radius and target_anchor_radius <= 0.14, "Source/target anchors are stronger but still small."),
		_check("read_only_boundaries", bool(source.get("read_only", false)) and bool(findings.get("read_only", false)) and bool(label_cluster.get("read_only", false)) and not bool(source.get("ui_sets_gameplay_truth", true)) and not bool(source.get("creates_command", true)) and not bool(source.get("creates_fire_event", true)) and not bool(source.get("creates_damage_event", true)) and not bool(source.get("creates_movement", true)) and not bool(source.get("sets_multiplayer_truth", true)), "TASK_910 changes presentation only."),
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
		"source_label_cluster_task_id": SOURCE_LABEL_CLUSTER_TASK_ID,
		"source_label_cluster_schema": SOURCE_LABEL_CLUSTER_SCHEMA,
		"source_label_cluster_style_id": SOURCE_LABEL_CLUSTER_STYLE_ID,
		"style_id": STYLE_ID,
		"active": active,
		"findings_ready": findings_ready,
		"label_cluster_ready": label_cluster_ready,
		"world_combat_fire_lane_world_read_micro_lane_width": lane_width,
		"world_combat_fire_lane_world_read_micro_lane_alpha": lane_alpha,
		"world_combat_fire_lane_world_read_micro_core_width": core_width,
		"world_combat_fire_lane_world_read_micro_core_alpha": core_alpha,
		"world_combat_fire_lane_world_read_micro_target_halo_radius": halo_radius,
		"world_combat_fire_lane_world_read_micro_target_halo_alpha": halo_alpha,
		"world_combat_fire_lane_world_read_micro_source_anchor_radius": source_anchor_radius,
		"world_combat_fire_lane_world_read_micro_target_anchor_radius": target_anchor_radius,
		"world_combat_fire_lane_world_read_micro_status_label_font_size": label_font_size,
		"world_combat_fire_lane_world_read_micro_status_label_alpha": label_alpha,
		"world_combat_fire_lane_world_read_micro_status_label_offset_y": label_offset_y,
		"weapon_fire_vfx_visual_count": int(primary_render.get("weapon_fire_vfx_visual_count", 0)),
		"weapon_fire_vfx_entries": fire_vfx_entries,
		"findings": findings,
		"label_cluster": label_cluster,
		"primary_render_snapshot": primary_render,
		"checks": checks,
		"failed_checks": failed_checks,
		"gate": "pass" if failed_checks.is_empty() else "review",
		"visual_policy": "world_read_micro_polish_lane_first_label_halo_retreat",
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
