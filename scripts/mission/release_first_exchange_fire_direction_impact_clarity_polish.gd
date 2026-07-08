class_name ReleaseFirstExchangeFireDirectionImpactClarityPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_fire_direction_impact_clarity_polish.v1"
const TASK_ID: String = "TASK_892"
const SOURCE_TASK_ID: String = "TASK_891"
const SOURCE_HUD_DENSITY_TASK_ID: String = "TASK_889"
const SOURCE_FIRE_VISUAL_TASK_ID: String = "TASK_880"
const STYLE_ID: String = "task_892_release_first_exchange_fire_direction_impact_clarity_v1"
const SOURCE_STYLE_ID: String = "task_889_release_first_exchange_hud_density_fire_visual_polish_v1"
const NEXT_TASK: String = "TASK_893 - Release First Exchange Fire Direction Impact Real Window Recapture"


static func build_snapshot(source: Dictionary, context: Dictionary = {}) -> Dictionary:
	var hud_density: Dictionary = Dictionary(source.get("hud_density", {})).duplicate(true)
	var primary_render: Dictionary = Dictionary(source.get("primary_render_snapshot", {})).duplicate(true)
	var fire_vfx_entries: Array = Array(primary_render.get("weapon_fire_vfx_entries", [])).duplicate(true)
	var first_fire_vfx: Dictionary = Dictionary(fire_vfx_entries[0]).duplicate(true) if not fire_vfx_entries.is_empty() else {}
	var active: bool = bool(primary_render.get("release_first_exchange_fire_direction_impact_clarity_polish_active", false)) \
		and String(primary_render.get("release_first_exchange_fire_direction_impact_clarity_polish_style_id", "")) == STYLE_ID
	var trace_width: float = float(primary_render.get("release_first_exchange_fire_direction_impact_trace_width", first_fire_vfx.get("trace_width", 0.0)))
	var impact_radius: float = float(primary_render.get("release_first_exchange_fire_direction_impact_radius", first_fire_vfx.get("impact_radius", 0.0)))
	var target_focus_radius: float = float(primary_render.get("release_first_exchange_fire_direction_target_focus_radius", first_fire_vfx.get("target_focus_radius", 0.0)))
	var direction_anchor_visible: bool = bool(first_fire_vfx.get("fire_direction_arrow_visible", false)) \
		and bool(first_fire_vfx.get("impact_relationship_anchor_visible", false)) \
		and bool(first_fire_vfx.get("target_endcap_visible", false))
	var checks: Array = [
		_check("source_hud_density_passes", String(hud_density.get("gate", "")) == "pass" and bool(hud_density.get("active", false)), "TASK_892 builds on the active TASK_889 HUD-density/fire-visual path."),
		_check("primary_style_active", active, "Primary3D receives and reports the TASK_892 clarity style."),
		_check("stronger_than_task_889", trace_width > 0.07 and impact_radius > 0.36 and target_focus_radius > 0.62, "Trace, Impact and Target-Focus are stronger than TASK_889."),
		_check("direction_impact_relationship_visible", direction_anchor_visible, "The first fire VFX entry exposes visible direction arrow, impact relationship anchor and target endcap metadata."),
		_check("fire_status_label_still_visible", bool(first_fire_vfx.get("fire_status_label_visible", false)) and int(first_fire_vfx.get("fire_status_label_font_size", 0)) >= 20, "The short target-side HIT/MISS/FIRE label remains visible and larger."),
		_check("read_only_boundaries", bool(source.get("read_only", false)) and bool(hud_density.get("read_only", false)) and not bool(source.get("ui_sets_gameplay_truth", true)) and not bool(source.get("creates_command", true)) and not bool(source.get("creates_fire_event", true)) and not bool(source.get("creates_damage_event", true)) and not bool(source.get("creates_movement", true)) and not bool(source.get("sets_multiplayer_truth", true)), "TASK_892 changes presentation only."),
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
		"source_hud_density_task_id": SOURCE_HUD_DENSITY_TASK_ID,
		"source_fire_visual_task_id": SOURCE_FIRE_VISUAL_TASK_ID,
		"style_id": STYLE_ID,
		"source_style_id": SOURCE_STYLE_ID,
		"active": active,
		"trace_width": trace_width,
		"impact_radius": impact_radius,
		"target_focus_radius": target_focus_radius,
		"direction_arrow_visible": bool(first_fire_vfx.get("fire_direction_arrow_visible", false)),
		"impact_relationship_anchor_visible": bool(first_fire_vfx.get("impact_relationship_anchor_visible", false)),
		"target_endcap_visible": bool(first_fire_vfx.get("target_endcap_visible", false)),
		"direction_arrow_width": float(first_fire_vfx.get("fire_direction_arrow_width", 0.0)),
		"direction_arrow_world": float(first_fire_vfx.get("fire_direction_arrow_world", 0.0)),
		"fire_status_label_font_size": int(first_fire_vfx.get("fire_status_label_font_size", 0)),
		"weapon_fire_vfx_visual_count": int(primary_render.get("weapon_fire_vfx_visual_count", 0)),
		"weapon_fire_vfx_entries": fire_vfx_entries,
		"hud_density": hud_density,
		"primary_render_snapshot": primary_render,
		"checks": checks,
		"failed_checks": failed_checks,
		"gate": "pass" if failed_checks.is_empty() else "review",
		"visual_policy": "source_to_target_direction_arrow_impact_anchor_and_target_endcap",
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
