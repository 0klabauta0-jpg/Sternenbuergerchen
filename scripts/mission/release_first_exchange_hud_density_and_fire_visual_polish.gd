class_name ReleaseFirstExchangeHudDensityAndFireVisualPolish
extends RefCounted

const SCHEMA: String = "sternenbuergerchen.release_first_exchange_hud_density_fire_visual_polish.v1"
const TASK_ID: String = "TASK_889"
const SOURCE_TASK_ID: String = "TASK_888"
const SOURCE_HUD_SYNC_TASK_ID: String = "TASK_883"
const SOURCE_VISIBLE_STATUS_TASK_ID: String = "TASK_876"
const SOURCE_FIRE_VISUAL_TASK_ID: String = "TASK_880"
const STYLE_ID: String = "task_889_release_first_exchange_hud_density_fire_visual_polish_v1"
const NEXT_TASK: String = "TASK_890 - Release First Exchange HUD Density Real Window Recapture"


static func build_snapshot(source: Dictionary, context: Dictionary = {}) -> Dictionary:
	var hud_sync: Dictionary = Dictionary(source.get("hud_sync", {})).duplicate(true)
	var event_log_panel: Dictionary = Dictionary(source.get("event_log_panel", {})).duplicate(true)
	var primary_render: Dictionary = Dictionary(source.get("primary_render_snapshot", {})).duplicate(true)
	var selected_text: String = String(source.get("selected_fireteam_status_text", "")).strip_edges()
	var mission_text: String = String(source.get("mission_control_status_text", "")).strip_edges()
	var active: bool = bool(source.get("active", false)) \
		and bool(hud_sync.get("active", false)) \
		and _starts_contact_fire(selected_text) \
		and _starts_contact_fire(mission_text)
	var trace_width: float = float(primary_render.get("release_first_exchange_hud_density_fire_visual_trace_width", 0.0))
	var impact_radius: float = float(primary_render.get("release_first_exchange_hud_density_fire_visual_impact_radius", 0.0))
	var target_focus_radius: float = float(primary_render.get("release_first_exchange_hud_density_fire_visual_target_focus_radius", 0.0))
	var checks: Array = [
		_check("hud_sync_source_active", bool(hud_sync.get("active", false)), "TASK_889 builds on the existing TASK_883/TASK_876 CONTACT-FIRE source."),
		_check("selected_fireteam_contact_fire_first", _starts_contact_fire(selected_text), "#17 starts with CONTACT FIRE."),
		_check("mission_control_contact_fire_first", _starts_contact_fire(mission_text), "#18 starts with CONTACT FIRE."),
		_check("selected_fireteam_line_budget", _line_count(selected_text) <= 3, "#17 keeps a short first-exchange line budget."),
		_check("mission_control_line_budget", _line_count(mission_text) <= 4, "#18 keeps a short first-exchange line budget."),
		_check("event_log_comfort_style", bool(event_log_panel.get("release_first_exchange_hud_density_fire_visual_polish_active", false)), "#19 applies the TASK_889 readability style."),
		_check("event_log_visible_cap_reduced", int(event_log_panel.get("max_visible_events", 0)) <= 5, "#19 shows fewer simultaneous event rows."),
		_check("event_log_minimum_size_larger", float(event_log_panel.get("custom_minimum_size_x", 0.0)) >= 360.0 and float(event_log_panel.get("custom_minimum_size_y", 0.0)) >= 220.0, "#19 has a larger readable frame."),
		_check("primary3d_fire_visual_style_active", bool(primary_render.get("release_first_exchange_hud_density_fire_visual_polish_active", false)), "Primary3D reports the TASK_889 fire visual style."),
		_check("fire_visuals_stronger_than_task880", trace_width > 0.052 and impact_radius > 0.28 and target_focus_radius > 0.48, "FireTrace, Impact and Target-Focus are stronger than TASK_880."),
		_check("read_only_boundaries", bool(source.get("read_only", false)) and not bool(source.get("ui_sets_gameplay_truth", true)) and not bool(source.get("creates_command", true)) and not bool(source.get("creates_fire_event", true)) and not bool(source.get("creates_damage_event", true)) and not bool(source.get("creates_movement", true)) and not bool(source.get("sets_multiplayer_truth", true)), "TASK_889 changes presentation only."),
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
		"source_hud_sync_task_id": SOURCE_HUD_SYNC_TASK_ID,
		"source_visible_status_task_id": SOURCE_VISIBLE_STATUS_TASK_ID,
		"source_fire_visual_task_id": SOURCE_FIRE_VISUAL_TASK_ID,
		"style_id": STYLE_ID,
		"active": active,
		"selected_fireteam_status_text": selected_text,
		"mission_control_status_text": mission_text,
		"selected_fireteam_line_count": _line_count(selected_text),
		"mission_control_line_count": _line_count(mission_text),
		"event_log_panel": event_log_panel,
		"primary_render_snapshot": primary_render,
		"trace_width": trace_width,
		"impact_radius": impact_radius,
		"target_focus_radius": target_focus_radius,
		"fire_status_label_font_size": int(primary_render.get("release_first_exchange_hud_density_fire_visual_status_label_font_size", 0)),
		"readability_policy": "contact_fire_first_reduce_hud_density_prioritize_trace_impact_target_focus",
		"checks": checks,
		"failed_checks": failed_checks,
		"gate": "pass" if active and failed_checks.is_empty() else "review",
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


static func _starts_contact_fire(text: String) -> bool:
	return text.strip_edges().to_upper().begins_with("CONTACT FIRE")


static func _line_count(text: String) -> int:
	var stripped: String = text.strip_edges()
	if stripped.is_empty():
		return 0
	return stripped.split("\n", false).size()


static func _check(check_id: String, passed: bool, text: String) -> Dictionary:
	return {
		"id": check_id,
		"passed": passed,
		"text": text,
	}
