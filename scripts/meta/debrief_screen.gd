class_name DebriefTestScreen
extends Control

const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")

const PERSONNEL_EVENT_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/personnel_event_model.gd")
const AIR_ASSET_RECOVERY_STATE_SCRIPT: GDScript = preload("res://scripts/meta/air_asset_recovery_state.gd")
const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const BACKGROUND_IMAGE_CATALOG_SCRIPT: GDScript = preload("res://scripts/assets/background_image_catalog.gd")
const PORTRAIT_IDENTITY_CATALOG_SCRIPT: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
const BACKGROUND_ID: String = "debrief_desert_explosion_base"
const DEBRIEF_SUMMARY_CHIP_COUNT_MIN := 5
const DEBRIEF_TEAM_STATUS_MAX_CHARS := 180
const DEBRIEF_AAR_CHIP_COUNT_MIN := 5
const DEBRIEF_AAR_ROW_COUNT_MIN := 4
const DEBRIEF_AAR_SUMMARY_MAX_CHARS := 96
const DEBRIEF_AAR_ROWS_MAX_CHARS := 180
const DEBRIEF_AAR_LIMIT_MAX_CHARS := 120
const DEBRIEF_AAR_LAYOUT_STYLE_ID := "debrief_aar_layout_polish_v1"
const DEBRIEF_SKILL_PREVIEW_MAX_CHARS := 160
const DEBRIEF_SKILL_PREVIEW_TOKEN_COUNT_MIN := 2
const DEBRIEF_SKILL_PREVIEW_STYLE_ID := "debrief_skill_preview_v1"
const DEBRIEF_SKILL_AWARD_MAX_CHARS := 128
const DEBRIEF_SKILL_AWARD_STYLE_ID := "debrief_skill_award_contract_v1"
const SKILL_AWARD_SUMMARY_SCHEMA := "sternenbuergerchen.skill_progress_award_summary.v1"

signal return_to_fob_requested()
signal return_to_homebase_requested()

var _mission_result: Dictionary = {}
var _native_review_slots: Dictionary = {}
var _native_review_people: VBoxContainer
var _native_review_heading: Label
var _native_review_pending := false


func _ready() -> void:
	TACTICAL_UI_THEME_SCRIPT.apply_screen(self)
	set_meta("native_ui_screen_family", "debrief")
	_apply_background_texture()
	var to_fob_button: Button = get_node("Panel/Margin/VBox/ButtonRow/ReturnToFOBButton")
	var to_homebase_button: Button = get_node("Panel/Margin/VBox/ButtonRow/ReturnToHomebaseButton")
	if not to_fob_button.pressed.is_connected(_on_return_to_fob_pressed):
		to_fob_button.pressed.connect(_on_return_to_fob_pressed)
	if not to_homebase_button.pressed.is_connected(_on_return_to_homebase_pressed):
		to_homebase_button.pressed.connect(_on_return_to_homebase_pressed)

	_apply_readability_style()
	_render_result()
	_apply_contextual_help_ids()
	if not resized.is_connected(_queue_native_review_layout):
		resized.connect(_queue_native_review_layout)


func set_mission_result(mission_result: Dictionary) -> void:
	_mission_result = mission_result.duplicate(true)
	if is_inside_tree():
		_render_result()


func get_mission_result() -> Dictionary:
	return _mission_result.duplicate(true)


func get_debrief_visual_polish_snapshot() -> Dictionary:
	var summary_strip := get_node_or_null("Panel/Margin/VBox/SummaryStrip") as HBoxContainer
	var result_label := get_node_or_null("Panel/Margin/VBox/ResultLabel") as Label
	var team_state_label := get_node_or_null("Panel/Margin/VBox/TeamStateLabel") as Label
	var homebase_button := get_node_or_null("Panel/Margin/VBox/ButtonRow/ReturnToHomebaseButton") as Button
	var fob_button := get_node_or_null("Panel/Margin/VBox/ButtonRow/ReturnToFOBButton") as Button
	var chips: Array = []
	if summary_strip != null:
		for child in summary_strip.get_children():
			var chip_label := child as Label
			if chip_label == null:
				continue
			chips.append({
				"name": chip_label.name,
				"text": chip_label.text,
				"style_id": String(chip_label.get_meta("debrief_chip_style_id", "")),
			})
	var checks: Array = []
	_append_visual_polish_check(checks, "summary_strip_visible", summary_strip != null and summary_strip.visible, "Summary strip should be visible.")
	_append_visual_polish_check(checks, "summary_chips_visible", chips.size() >= DEBRIEF_SUMMARY_CHIP_COUNT_MIN, "Debrief should show compact outcome chips.")
	_append_visual_polish_check(checks, "result_text_compact", result_label != null and result_label.text.length() <= 140 and result_label.text.count("\n") <= 1, "Result text should be short enough to scan.")
	_append_visual_polish_check(checks, "team_status_compact", team_state_label != null and team_state_label.text.length() <= DEBRIEF_TEAM_STATUS_MAX_CHARS, "Team status should stay compact.")
	_append_visual_polish_check(checks, "homebase_primary_action", homebase_button != null and String(homebase_button.get_meta("debrief_action_role", "")) == "primary_homebase", "Return to Homebase should read as the primary action.")
	_append_visual_polish_check(checks, "fob_secondary_action", fob_button != null and String(fob_button.get_meta("debrief_action_role", "")) == "secondary_fob", "Return to FOB should remain secondary.")
	_append_visual_polish_check(checks, "background_readability_policy", String(get_node_or_null("Panel").get_meta("background_readability_policy", "")) == "dimmed_catalog_background" if get_node_or_null("Panel") != null else false, "Dimmed background readability policy should remain active.")
	_append_visual_polish_check(checks, "read_only", true, "Snapshot reads visual state only.")
	var failed_count: int = 0
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed_count += 1
	return {
		"schema": "sternenbuergerchen.debrief_visual_polish.v1",
		"task_id": "TASK_587",
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"layout_key": "debrief_visual_polish_v1",
		"has_mission_result": not _mission_result.is_empty(),
		"summary_chip_count": chips.size(),
		"summary_chips": chips,
		"result_text": result_label.text if result_label != null else "",
		"result_text_length": result_label.text.length() if result_label != null else 0,
		"result_line_count": result_label.get_line_count() if result_label != null else 0,
		"team_status_text": team_state_label.text if team_state_label != null else "",
		"team_status_length": team_state_label.text.length() if team_state_label != null else 0,
		"primary_action_label": homebase_button.text if homebase_button != null else "",
		"secondary_action_label": fob_button.text if fob_button != null else "",
		"visual_only": true,
		"checks": checks,
	}


func get_debrief_aar_data_bridge_snapshot() -> Dictionary:
	var payload: Dictionary = _extract_debrief_aar_payload()
	var summary_label := get_node_or_null("Panel/Margin/VBox/AARSummaryLabel") as Label
	var chip_strip := get_node_or_null("Panel/Margin/VBox/AARChipStrip") as HBoxContainer
	var rows_label := get_node_or_null("Panel/Margin/VBox/AARRowsLabel") as Label
	var limit_label := get_node_or_null("Panel/Margin/VBox/AARLimitLabel") as Label
	var chips: Array = []
	if chip_strip != null:
		for child in chip_strip.get_children():
			var chip_label := child as Label
			if chip_label == null:
				continue
			chips.append({
				"name": chip_label.name,
				"text": chip_label.text,
				"style_id": String(chip_label.get_meta("debrief_aar_chip_style_id", "")),
			})
	var visual_snapshot: Dictionary = get_debrief_visual_polish_snapshot()
	var row_count: int = int(rows_label.get_meta("debrief_aar_row_count", 0)) if rows_label != null else 0
	var summary_text: String = summary_label.text if summary_label != null else ""
	var limit_text: String = limit_label.text if limit_label != null else ""
	var checks: Array = []
	_append_visual_polish_check(checks, "source_schema_available", String(payload.get("schema", "")) == "sternenbuergerchen.mini_aar_debrief_screen_stub.v1", "Debrief should receive the mini AAR debrief snapshot.")
	_append_visual_polish_check(checks, "aar_section_visible", summary_label != null and summary_label.visible and chip_strip != null and chip_strip.visible, "AAR section should be visible when data exists.")
	_append_visual_polish_check(checks, "aar_summary_mentions_fire_and_sup", summary_text.contains("FIRE") and summary_text.contains("SUP"), "AAR summary should expose fire and suppress metrics.")
	_append_visual_polish_check(checks, "aar_chips_visible", chips.size() >= DEBRIEF_AAR_CHIP_COUNT_MIN, "AAR chips should be compact and visible.")
	_append_visual_polish_check(checks, "aar_rows_visible", row_count >= DEBRIEF_AAR_ROW_COUNT_MIN, "AAR rows should include the existing metrics.")
	_append_visual_polish_check(checks, "aar_limits_honest", limit_text.contains("Keine XP") and limit_text.contains("keine Ammo") and limit_text.contains("keine echte Suppression"), "AAR bridge should keep limits honest.")
	_append_visual_polish_check(checks, "visual_polish_still_green", String(visual_snapshot.get("gate", "")) == "pass", "AAR bridge should not regress the Debrief visual polish gate.")
	_append_visual_polish_check(checks, "read_only", true, "Snapshot reads debrief AAR state only.")
	var failed_count: int = 0
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed_count += 1
	return {
		"schema": "sternenbuergerchen.debrief_aar_data_bridge.v1",
		"task_id": "TASK_588",
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"layout_key": "debrief_aar_bridge_v1",
		"source_schema": String(payload.get("schema", "")),
		"aar_section_visible": summary_label != null and summary_label.visible,
		"aar_summary_text": summary_text,
		"aar_chip_count": chips.size(),
		"aar_chips": chips,
		"aar_row_count": row_count,
		"aar_rows_text": rows_label.text if rows_label != null else "",
		"aar_limit_text": limit_text,
		"visual_snapshot_gate": String(visual_snapshot.get("gate", "")),
		"visual_only": true,
		"checks": checks,
	}


func get_debrief_aar_visual_evidence_snapshot() -> Dictionary:
	var bridge_snapshot: Dictionary = get_debrief_aar_data_bridge_snapshot()
	var panel := get_node_or_null("Panel") as Control
	var summary_label := get_node_or_null("Panel/Margin/VBox/AARSummaryLabel") as Label
	var chip_strip := get_node_or_null("Panel/Margin/VBox/AARChipStrip") as HBoxContainer
	var rows_label := get_node_or_null("Panel/Margin/VBox/AARRowsLabel") as Label
	var limit_label := get_node_or_null("Panel/Margin/VBox/AARLimitLabel") as Label
	var button_row := get_node_or_null("Panel/Margin/VBox/ButtonRow") as HBoxContainer
	var panel_rect: Rect2 = panel.get_global_rect() if panel != null else Rect2()
	var summary_rect: Rect2 = summary_label.get_global_rect() if summary_label != null else Rect2()
	var chip_rect: Rect2 = chip_strip.get_global_rect() if chip_strip != null else Rect2()
	var rows_rect: Rect2 = rows_label.get_global_rect() if rows_label != null else Rect2()
	var limit_rect: Rect2 = limit_label.get_global_rect() if limit_label != null else Rect2()
	var button_rect: Rect2 = button_row.get_global_rect() if button_row != null else Rect2()
	var aar_section_rect: Rect2 = _merge_rects([summary_rect, chip_rect, rows_rect, limit_rect])
	var button_gap: float = button_rect.position.y - (limit_rect.position.y + limit_rect.size.y) if button_row != null and limit_label != null else -1.0
	var summary_text: String = String(bridge_snapshot.get("aar_summary_text", "")).strip_edges()
	var rows_text: String = String(bridge_snapshot.get("aar_rows_text", "")).strip_edges()
	var limit_text: String = String(bridge_snapshot.get("aar_limit_text", "")).strip_edges()
	var chips: Array = Array(bridge_snapshot.get("aar_chips", []))
	var checks: Array = []
	_append_visual_polish_check(checks, "bridge_gate_pass", String(bridge_snapshot.get("gate", "")) == "pass", "TASK_588 AAR bridge should stay green.")
	_append_visual_polish_check(checks, "aar_controls_visible", summary_label != null and summary_label.visible and chip_strip != null and chip_strip.visible and rows_label != null and rows_label.visible and limit_label != null and limit_label.visible, "AAR controls should be visible in the Debrief viewport.")
	_append_visual_polish_check(checks, "aar_controls_inside_panel", _rect_inside(summary_rect, panel_rect) and _rect_inside(chip_rect, panel_rect) and _rect_inside(rows_rect, panel_rect) and _rect_inside(limit_rect, panel_rect), "AAR controls should stay inside the Debrief panel.")
	_append_visual_polish_check(checks, "aar_before_buttons", button_row != null and aar_section_rect.position.y + aar_section_rect.size.y <= button_rect.position.y + 1.0, "AAR section should sit before the return buttons.")
	_append_visual_polish_check(checks, "aar_button_gap_visible", button_gap >= 0.0, "AAR section should not overlap the button row.")
	_append_visual_polish_check(checks, "aar_section_height_compact", aar_section_rect.size.y > 0.0 and aar_section_rect.size.y <= 180.0, "AAR section should stay compact enough for the Debrief.")
	_append_visual_polish_check(checks, "summary_text_compact", summary_text.length() <= 96 and summary_text.count("\n") == 0, "AAR summary should remain one compact scan line.")
	_append_visual_polish_check(checks, "rows_text_compact", rows_text.length() <= 180 and rows_text.count("\n") == 0, "AAR rows should remain a compact detail line.")
	_append_visual_polish_check(checks, "limit_text_compact", limit_text.length() <= 120 and limit_text.count("\n") == 0, "AAR limit text should remain compact.")
	_append_visual_polish_check(checks, "chips_compact", chips.size() >= DEBRIEF_AAR_CHIP_COUNT_MIN and chip_rect.size.y <= 44.0, "AAR chips should fit into one compact strip.")
	_append_visual_polish_check(checks, "read_only", true, "Snapshot reads visual evidence only.")
	var failed_count: int = 0
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed_count += 1
	return {
		"schema": "sternenbuergerchen.debrief_aar_visual_evidence.v1",
		"task_id": "TASK_589",
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"layout_key": "debrief_aar_visual_evidence_v1",
		"bridge_gate": String(bridge_snapshot.get("gate", "")),
		"source_schema": String(bridge_snapshot.get("source_schema", "")),
		"panel_rect": _rect_to_dict(panel_rect),
		"aar_section_rect": _rect_to_dict(aar_section_rect),
		"aar_summary_rect": _rect_to_dict(summary_rect),
		"aar_chip_strip_rect": _rect_to_dict(chip_rect),
		"aar_rows_rect": _rect_to_dict(rows_rect),
		"aar_limit_rect": _rect_to_dict(limit_rect),
		"button_row_rect": _rect_to_dict(button_rect),
		"button_gap": button_gap,
		"aar_summary_text": summary_text,
		"aar_rows_text": rows_text,
		"aar_limit_text": limit_text,
		"aar_chip_count": chips.size(),
		"aar_row_count": int(bridge_snapshot.get("aar_row_count", 0)),
		"manual_review_required": true,
		"manual_review_done": false,
		"visual_only": true,
		"checks": checks,
	}


func get_debrief_aar_layout_polish_snapshot() -> Dictionary:
	var bridge_snapshot: Dictionary = get_debrief_aar_data_bridge_snapshot()
	var visual_snapshot: Dictionary = get_debrief_aar_visual_evidence_snapshot()
	var summary_label := get_node_or_null("Panel/Margin/VBox/AARSummaryLabel") as Label
	var chip_strip := get_node_or_null("Panel/Margin/VBox/AARChipStrip") as HBoxContainer
	var rows_label := get_node_or_null("Panel/Margin/VBox/AARRowsLabel") as Label
	var limit_label := get_node_or_null("Panel/Margin/VBox/AARLimitLabel") as Label
	var summary_text: String = summary_label.text.strip_edges() if summary_label != null else ""
	var rows_text: String = rows_label.text.strip_edges() if rows_label != null else ""
	var limit_text: String = limit_label.text.strip_edges() if limit_label != null else ""
	var chips: Array = Array(bridge_snapshot.get("aar_chips", []))
	var summary_style_id: String = String(summary_label.get_meta("debrief_aar_summary_style_id", "")) if summary_label != null else ""
	var rows_style_id: String = String(rows_label.get_meta("debrief_aar_rows_style_id", "")) if rows_label != null else ""
	var limit_style_id: String = String(limit_label.get_meta("debrief_aar_limit_style_id", "")) if limit_label != null else ""
	var chip_style_count: int = 0
	if chip_strip != null:
		for child in chip_strip.get_children():
			var chip_label := child as Label
			if chip_label == null:
				continue
			if String(chip_label.get_meta("debrief_aar_chip_style_id", "")) == "debrief_aar_chip_v1":
				chip_style_count += 1
	var checks: Array = []
	_append_visual_polish_check(checks, "bridge_gate_pass", String(bridge_snapshot.get("gate", "")) == "pass", "TASK_588 AAR bridge should stay green.")
	_append_visual_polish_check(checks, "visual_gate_pass", String(visual_snapshot.get("gate", "")) == "pass", "TASK_589 visual evidence should stay green.")
	_append_visual_polish_check(checks, "summary_prefix_clean", summary_text.begins_with("AAR |") and not summary_text.contains("AAR: AAR"), "AAR summary should not duplicate the prefix.")
	_append_visual_polish_check(checks, "summary_compact", summary_text.length() <= DEBRIEF_AAR_SUMMARY_MAX_CHARS and summary_text.count("\n") == 0, "AAR summary should stay one compact line.")
	_append_visual_polish_check(checks, "rows_compact", rows_text.length() <= DEBRIEF_AAR_ROWS_MAX_CHARS and rows_text.count("\n") == 0, "AAR rows should stay compact.")
	_append_visual_polish_check(checks, "limit_compact", limit_text.length() <= DEBRIEF_AAR_LIMIT_MAX_CHARS and limit_text.count("\n") == 0, "AAR limit text should stay compact.")
	_append_visual_polish_check(checks, "summary_style_applied", summary_style_id == "debrief_aar_summary_v2", "AAR summary style should be applied.")
	_append_visual_polish_check(checks, "rows_style_applied", rows_style_id == "debrief_aar_rows_v2", "AAR rows style should be applied.")
	_append_visual_polish_check(checks, "limit_style_applied", limit_style_id == "debrief_aar_limit_v2", "AAR limit style should be applied.")
	_append_visual_polish_check(checks, "chips_visible", chips.size() >= DEBRIEF_AAR_CHIP_COUNT_MIN and chip_style_count >= DEBRIEF_AAR_CHIP_COUNT_MIN, "AAR chips should remain visible and styled.")
	_append_visual_polish_check(checks, "button_gap_preserved", float(visual_snapshot.get("button_gap", -1.0)) >= 0.0, "AAR section should not overlap the buttons.")
	_append_visual_polish_check(checks, "read_only", true, "Snapshot reads layout state only.")
	var failed_count: int = 0
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed_count += 1
	return {
		"schema": "sternenbuergerchen.debrief_aar_layout_polish.v1",
		"task_id": "TASK_590",
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"layout_key": DEBRIEF_AAR_LAYOUT_STYLE_ID,
		"bridge_gate": String(bridge_snapshot.get("gate", "")),
		"visual_gate": String(visual_snapshot.get("gate", "")),
		"source_schema": String(bridge_snapshot.get("source_schema", "")),
		"aar_summary_text": summary_text,
		"summary_has_duplicate_prefix": summary_text.contains("AAR: AAR"),
		"aar_rows_text": rows_text,
		"aar_limit_text": limit_text,
		"summary_length": summary_text.length(),
		"rows_length": rows_text.length(),
		"limit_length": limit_text.length(),
		"aar_chip_count": chips.size(),
		"aar_row_count": int(bridge_snapshot.get("aar_row_count", 0)),
		"button_gap": float(visual_snapshot.get("button_gap", -1.0)),
		"aar_section_height": float(Dictionary(visual_snapshot.get("aar_section_rect", {})).get("height", 0.0)),
		"style_ids": {
			"layout": DEBRIEF_AAR_LAYOUT_STYLE_ID,
			"summary": summary_style_id,
			"rows": rows_style_id,
			"limit": limit_style_id,
			"chip_styled_count": chip_style_count,
		},
		"visual_only": true,
		"checks": checks,
	}


func get_debrief_skill_progress_preview_snapshot() -> Dictionary:
	var aar_snapshot: Dictionary = get_debrief_aar_layout_polish_snapshot()
	var skill_label := get_node_or_null("Panel/Margin/VBox/SkillProgressPreviewLabel") as Label
	var text: String = skill_label.text.strip_edges() if skill_label != null else ""
	var entries: Array = Array(skill_label.get_meta("debrief_skill_preview_entries", [])) if skill_label != null else []
	var style_id: String = String(skill_label.get_meta("debrief_skill_preview_style_id", "")) if skill_label != null else ""
	var checks: Array = []
	_append_visual_polish_check(checks, "skill_preview_visible", skill_label != null and skill_label.visible, "Skill preview should be visible when mission result data exists.")
	_append_visual_polish_check(checks, "skill_preview_compact", text.length() <= DEBRIEF_SKILL_PREVIEW_MAX_CHARS and text.count("\n") == 0, "Skill preview should stay one compact scan line.")
	_append_visual_polish_check(checks, "skill_preview_named", text.begins_with("Skill Preview:"), "Skill preview should be explicitly marked as preview.")
	_append_visual_polish_check(checks, "skill_preview_has_tokens", entries.size() >= DEBRIEF_SKILL_PREVIEW_TOKEN_COUNT_MIN, "Skill preview should expose multiple progress tokens.")
	_append_visual_polish_check(checks, "skill_preview_style_applied", style_id == DEBRIEF_SKILL_PREVIEW_STYLE_ID, "Skill preview style should be applied.")
	_append_visual_polish_check(checks, "aar_layout_still_green", String(aar_snapshot.get("gate", "")) == "pass", "Skill preview should not regress the Debrief AAR layout gate.")
	_append_visual_polish_check(checks, "read_only", true, "Snapshot reads skill preview state only.")
	var failed_count: int = 0
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed_count += 1
	return {
		"schema": "sternenbuergerchen.debrief_skill_progress_preview.v1",
		"task_id": "TASK_592",
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"layout_key": DEBRIEF_SKILL_PREVIEW_STYLE_ID,
		"preview_text": text,
		"preview_length": text.length(),
		"preview_visible": skill_label != null and skill_label.visible,
		"preview_entries": entries,
		"preview_token_count": entries.size(),
		"style_id": style_id,
		"aar_layout_gate": String(aar_snapshot.get("gate", "")),
		"visual_only": true,
		"checks": checks,
	}


func get_debrief_skill_award_contract_snapshot() -> Dictionary:
	var preview_snapshot: Dictionary = get_debrief_skill_progress_preview_snapshot()
	var award_label := get_node_or_null("Panel/Margin/VBox/SkillAwardSummaryLabel") as Label
	var award_summary: Dictionary = Dictionary(_mission_result.get("progression_award_summary", {})).duplicate(true)
	var text: String = award_label.text.strip_edges() if award_label != null else ""
	var style_id: String = String(award_label.get_meta("debrief_skill_award_style_id", "")) if award_label != null else ""
	var checks: Array = []
	_append_visual_polish_check(checks, "award_summary_schema", String(award_summary.get("schema", "")) == SKILL_AWARD_SUMMARY_SCHEMA, "Award summary should use the stable resolver schema.")
	_append_visual_polish_check(checks, "award_authority_resolver", String(award_summary.get("authority", "")) == "MissionProgressionResolver", "Award authority should stay in MissionProgressionResolver.")
	_append_visual_polish_check(checks, "award_source_unit_updates", String(award_summary.get("source", "")) == "progression_unit_updates", "Award summary should be derived from progression unit updates.")
	_append_visual_polish_check(checks, "award_applied", bool(award_summary.get("award_applied", false)), "Award summary should describe already applied progression.")
	_append_visual_polish_check(checks, "award_label_visible", award_label != null and award_label.visible, "Debrief should show award summary when resolver data exists.")
	_append_visual_polish_check(checks, "award_label_compact", text.length() <= DEBRIEF_SKILL_AWARD_MAX_CHARS and text.count("\n") == 0, "Award summary should stay one compact scan line.")
	_append_visual_polish_check(checks, "award_label_named", text.begins_with("Skill Awards:"), "Award summary should be visibly distinct from preview.")
	_append_visual_polish_check(checks, "award_has_xp", int(award_summary.get("total_xp_delta", 0)) > 0, "Award summary should include XP totals.")
	_append_visual_polish_check(checks, "award_has_growth_token", int(award_summary.get("skill_gain_count", 0)) > 0 or int(award_summary.get("ftl_tactical_gain_count", 0)) > 0, "Award summary should include skill or FTL growth tokens.")
	_append_visual_polish_check(checks, "award_style_applied", style_id == DEBRIEF_SKILL_AWARD_STYLE_ID, "Award summary style should be applied.")
	_append_visual_polish_check(checks, "preview_still_green", String(preview_snapshot.get("gate", "")) == "pass", "Award contract should not regress the preview gate.")
	_append_visual_polish_check(checks, "read_only", bool(award_summary.get("read_only", false)) and not bool(award_summary.get("ui_sets_gameplay_truth", true)), "Debrief reads resolver award data only.")
	var failed_count: int = 0
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed_count += 1
	return {
		"schema": "sternenbuergerchen.debrief_skill_award_contract.v1",
		"task_id": "TASK_593",
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"layout_key": DEBRIEF_SKILL_AWARD_STYLE_ID,
		"award_text": text,
		"award_length": text.length(),
		"award_visible": award_label != null and award_label.visible,
		"award_summary_schema": String(award_summary.get("schema", "")),
		"award_authority": String(award_summary.get("authority", "")),
		"award_source": String(award_summary.get("source", "")),
		"total_xp_delta": int(award_summary.get("total_xp_delta", 0)),
		"skill_gain_count": int(award_summary.get("skill_gain_count", 0)),
		"ftl_tactical_gain_count": int(award_summary.get("ftl_tactical_gain_count", 0)),
		"recovery_count": int(award_summary.get("recovery_count", 0)),
		"unit_award_count": int(award_summary.get("unit_award_count", 0)),
		"listed_award_count": int(award_summary.get("listed_award_count", 0)),
		"style_id": style_id,
		"preview_gate": String(preview_snapshot.get("gate", "")),
		"visual_only": true,
		"checks": checks,
	}


func get_background_catalog_snapshot() -> Dictionary:
	var entry: Dictionary = Dictionary(BACKGROUND_IMAGE_CATALOG_SCRIPT.call("get_entry", BACKGROUND_ID))
	var background := get_node_or_null("Background") as TextureRect
	var shade := get_node_or_null("BackgroundShade") as ColorRect
	var panel := get_node_or_null("Panel") as PanelContainer
	var panel_style: StyleBoxFlat = null
	if panel != null:
		panel_style = panel.get_theme_stylebox("panel") as StyleBoxFlat
	return {
		"background_id": BACKGROUND_ID,
		"path": String(entry.get("res_path", "")),
		"entry": entry,
		"uses_catalog": not entry.is_empty(),
		"has_texture": background != null and background.texture != null,
		"stretch_mode": int(background.stretch_mode) if background != null else -1,
		"shade_alpha": shade.color.a if shade != null else 0.0,
		"panel_alpha": panel_style.bg_color.a if panel_style != null else 0.0,
		"visual_only": true,
	}


func _render_result() -> void:
	var result_label: Label = get_node("Panel/Margin/VBox/ResultLabel")
	var team_state_label: Label = get_node("Panel/Margin/VBox/TeamStateLabel")
	var summary_strip: HBoxContainer = _ensure_summary_strip()
	var air_asset_label: Label = _ensure_air_asset_events_label()
	var ftl_feedback_label: Label = _ensure_ftl_feedback_label()
	var aar_summary_label: Label = _ensure_aar_summary_label()
	var aar_chip_strip: HBoxContainer = _ensure_aar_chip_strip()
	var aar_rows_label: Label = _ensure_aar_rows_label()
	var aar_limit_label: Label = _ensure_aar_limit_label()
	var skill_preview_label: Label = _ensure_skill_progress_preview_label()
	var skill_award_label: Label = _ensure_skill_award_summary_label()
	var character_events_label: Label = _ensure_character_events_label()
	var personnel_events_label: Label = _ensure_personnel_events_label()
	_apply_help_id(character_events_label, "debrief.character_updates")
	_apply_help_id(air_asset_label, "fob.flightdeck")
	_apply_help_id(ftl_feedback_label, "character_sheet.ftl_tactical_impact")
	_apply_help_id(aar_summary_label, "debrief.mini_aar")
	_apply_help_id(skill_preview_label, "debrief.skill_preview")
	_apply_help_id(skill_award_label, "debrief.skill_awards")

	if _mission_result.is_empty():
		_render_summary_chips(summary_strip, [
			{"id": "result", "text": "PENDING"},
			{"id": "winner", "text": "WIN -"},
			{"id": "duration", "text": "TIME -"},
			{"id": "condition", "text": "COND -"},
			{"id": "objective", "text": "OBJ -"},
		])
		result_label.text = "Mission pending | Debrief data unavailable"
		team_state_label.text = "Team: unavailable"
		air_asset_label.text = "Air asset: pending"
		ftl_feedback_label.text = "FTL feedback: pending"
		_render_aar_bridge({}, aar_summary_label, aar_chip_strip, aar_rows_label, aar_limit_label)
		_render_skill_progress_preview(skill_preview_label, [])
		_render_skill_award_summary(skill_award_label, {})
		character_events_label.text = "Character updates: pending"
		personnel_events_label.text = "Personnel updates: pending"
		_apply_readability_style()
		_refresh_native_review_cards()
		return

	var winner_team_id: String = String(_mission_result.get("winning_team_id", ""))
	var result: String = String(_mission_result.get("result", "ended"))
	var mission_outcome: String = String(_mission_result.get("mission_outcome", "ended"))
	var win_condition_type: String = String(_mission_result.get("win_condition_type", ""))
	var duration_seconds: float = float(_mission_result.get("duration_seconds", 0.0))
	var objective_captured: bool = bool(_mission_result.get("objective_captured", false))

	var winner_text: String = winner_team_id
	if winner_text.is_empty():
		winner_text = "unknown"

	_render_summary_chips(summary_strip, [
		{"id": "result", "text": result.to_upper()},
		{"id": "winner", "text": "WIN %s" % winner_text.to_upper()},
		{"id": "duration", "text": "TIME %ss" % _format_debrief_seconds(duration_seconds)},
		{"id": "condition", "text": "COND %s" % _format_compact_token(win_condition_type, "unknown")},
		{"id": "objective", "text": "OBJ %s" % ("TAKEN" if objective_captured else "OPEN")},
	])
	result_label.text = "Mission %s | %s | Winner %s | %s" % [
		mission_outcome,
		result.to_upper(),
		winner_text,
		_format_compact_token(win_condition_type, "condition unknown"),
	]

	var team_state_counts: Dictionary = {}
	var team_state_tokens: PackedStringArray = []
	for member_state in _mission_result.get("team_states", []):
		var display_name: String = String(member_state.get("display_name", member_state.get("unit_id", "")))
		var vital_state: String = String(member_state.get("vital_state", "unknown"))
		var health_points: int = int(member_state.get("health_points", -1))
		team_state_counts[vital_state] = int(team_state_counts.get(vital_state, 0)) + 1
		if team_state_tokens.size() < 4:
			var health_text := "%dHP" % health_points if health_points >= 0 else "HP unbekannt"
			team_state_tokens.append("%s %s %s" % [display_name, vital_state.to_upper(), health_text])

	if team_state_tokens.is_empty():
		team_state_label.text = "Team: unavailable"
	else:
		team_state_label.text = "Team: %s | %s" % [
			_format_team_state_counts(team_state_counts),
			" | ".join(team_state_tokens),
		]

	var recovery_state: Dictionary = Dictionary(_mission_result.get("air_asset_recovery", {})).duplicate(true)
	if recovery_state.is_empty():
		air_asset_label.text = "Air asset: no loss reported"
	else:
		air_asset_label.text = String(AIR_ASSET_RECOVERY_STATE_SCRIPT.call("build_debrief_summary", recovery_state))

	var ftl_feedback_lines: PackedStringArray = _build_ftl_feedback_lines(Array(_mission_result.get("fireteam_tactical_debrief", [])))
	if ftl_feedback_lines.is_empty():
		ftl_feedback_label.text = "FTL feedback: unavailable"
	else:
		ftl_feedback_label.text = "FTL feedback:\n%s" % "\n".join(ftl_feedback_lines)

	_render_aar_bridge(_extract_debrief_aar_payload(), aar_summary_label, aar_chip_strip, aar_rows_label, aar_limit_label)
	_render_skill_progress_preview(skill_preview_label, _build_skill_progress_preview_entries())
	_render_skill_award_summary(skill_award_label, Dictionary(_mission_result.get("progression_award_summary", {})))

	var character_event_lines: PackedStringArray = []
	for event_variant in Array(_mission_result.get("character_events", [])):
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = Dictionary(event_variant)
		var summary_text: String = String(event.get("summary_text", "")).strip_edges()
		if summary_text.is_empty():
			continue
		character_event_lines.append(summary_text)
		if character_event_lines.size() >= 5:
			break
	if character_event_lines.is_empty():
		character_events_label.text = "Character updates: none"
	else:
		character_events_label.text = "Character updates:\n%s" % "\n".join(character_event_lines)

	var personnel_event_lines: PackedStringArray = PackedStringArray()
	for event_variant in Array(_mission_result.get("personnel_events", [])):
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var message: String = String(PERSONNEL_EVENT_MODEL_SCRIPT.call("format_event_message", Dictionary(event_variant))).strip_edges()
		if message.is_empty():
			continue
		personnel_event_lines.append(message)
		if personnel_event_lines.size() >= 5:
			break
	if personnel_event_lines.is_empty():
		personnel_events_label.text = "Personnel updates: none"
	else:
		personnel_events_label.text = "Personnel updates:\n%s" % "\n".join(personnel_event_lines)
	_apply_readability_style()
	_refresh_native_review_cards()


func _refresh_native_review_cards() -> void:
	_ensure_native_review_cards()
	_native_review_heading.text = "Ergebnis ausstehend" if _mission_result.is_empty() else "Einsatz abgeschlossen"
	for child in _native_review_people.get_children():
		_native_review_people.remove_child(child)
		child.queue_free()
	var states: Array = _mission_result.get("team_states", [])
	for entry in states:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var member: Dictionary = entry
		var card := PanelContainer.new()
		card.name = "PersonCard_%d" % _native_review_people.get_child_count()
		card.set_meta("debrief_member_id", String(member.get("unit_id", "")))
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		TACTICAL_UI_THEME_SCRIPT.style_card(card)
		_native_review_people.add_child(card)
		var contents := VBoxContainer.new()
		contents.name = "Contents"
		contents.add_theme_constant_override("separation", 4)
		card.add_child(contents)
		var identity_row := HBoxContainer.new()
		identity_row.name = "IdentityRow"
		identity_row.add_theme_constant_override("separation", 10)
		contents.add_child(identity_row)
		var portrait_id := String(member.get("portrait_id", "")).strip_edges()
		var portrait_path := String(member.get("portrait_path", "")).strip_edges()
		if not portrait_id.is_empty() or not portrait_path.is_empty():
			var texture := PORTRAIT_IDENTITY_CATALOG_SCRIPT.load_texture(portrait_id, portrait_path) as Texture2D
			if texture != null:
				var portrait := TextureRect.new()
				portrait.custom_minimum_size = Vector2(48, 48)
				portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				portrait.texture = texture
				identity_row.add_child(portrait)
		var identity := Label.new()
		identity.name = "IdentityLabel"
		identity.text = String(member.get("display_name", member.get("unit_id", "Person unbekannt")))
		if identity.text.strip_edges().is_empty():
			identity.text = "Person unbekannt"
		identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		identity.clip_text = true
		identity.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		TACTICAL_UI_THEME_SCRIPT.style_label(identity, false, 16)
		identity_row.add_child(identity)
		var status := Label.new()
		status.name = "StatusLabel"
		var vital := String(member.get("vital_state", "unknown"))
		var status_names := {"fit": "Einsatzfähig", "wounded": "Verletzt", "down": "Ausgefallen", "dead": "Verstorben"}
		var fireteam := String(member.get("fireteam_id", "")).to_upper()
		status.text = "%s%s" % [status_names.get(vital, "Status unbekannt"), " · " + fireteam if not fireteam.is_empty() else ""]
		TACTICAL_UI_THEME_SCRIPT.style_label(status, true, 12)
		contents.add_child(status)
		var health := Label.new()
		health.name = "HealthLabel"
		var hp := int(member.get("health_points", -1))
		health.text = "%d HP" % hp if hp >= 0 else "Gesundheit unbekannt"
		TACTICAL_UI_THEME_SCRIPT.style_label(health, false, 13)
		contents.add_child(health)
	if _native_review_people.get_child_count() == 0:
		var empty := Label.new()
		empty.text = "Keine Personendaten im Einsatzbericht."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		TACTICAL_UI_THEME_SCRIPT.style_label(empty, true, 14)
		_native_review_people.add_child(empty)
	for source_name in _native_review_slots:
		var source := get_node_or_null("Panel/Margin/VBox/" + source_name) as Control
		var slot := _native_review_slots[source_name] as Control
		slot.visible = source != null and source.visible
	var layout := get_node("Panel/Margin/VBox/NativeReviewLayout")
	layout.get_node("BodyRow/DetailsGrid/AARCard/Contents/EmptyLabel").visible = _extract_debrief_aar_payload().is_empty()
	layout.get_node("BodyRow/DetailsGrid/ProgressCard/Contents/EmptyLabel").visible = not (get_node("Panel/Margin/VBox/SkillProgressPreviewLabel") as Label).visible and not (get_node("Panel/Margin/VBox/SkillAwardSummaryLabel") as Label).visible
	_queue_native_review_layout()


func _ensure_native_review_cards() -> void:
	var old_vbox := get_node("Panel/Margin/VBox") as VBoxContainer
	if old_vbox.has_node("NativeReviewLayout"):
		return
	# Public Label/Button NodePaths and connected instances stay intact. Native
	# containers size the card slots; only these bounded legacy leaves are placed
	# into them on render/resize. The person list has its own real scroll ancestry.
	for child in old_vbox.get_children():
		if child is Control:
			child.set_as_top_level(true)
			child.set_anchors_preset(Control.PRESET_TOP_LEFT)
			child.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			child.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			child.custom_minimum_size = Vector2.ZERO
			child.z_index = 10
	old_vbox.add_theme_constant_override("separation", 0)
	var layout := VBoxContainer.new()
	layout.name = "NativeReviewLayout"
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 10)
	old_vbox.add_child(layout)
	var result := _make_review_card(layout, "ResultCard", "")
	_add_review_slot(result, "TitleLabel", 22)
	_native_review_heading = Label.new()
	_native_review_heading.name = "OutcomeHeading"
	TACTICAL_UI_THEME_SCRIPT.style_label(_native_review_heading, false, 26)
	_native_review_heading.add_theme_color_override("font_color", TACTICAL_UI_THEME_SCRIPT.COLOR_ACCENT)
	result.add_child(_native_review_heading)
	_add_review_slot(result, "ResultLabel", 20)
	_add_review_slot(result, "SummaryStrip", 28)
	var body := HBoxContainer.new()
	body.name = "BodyRow"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	layout.add_child(body)
	var people := _make_review_card(body, "PeopleCard", "Personenfolgen")
	var people_card := people.get_parent() as Control
	people_card.custom_minimum_size.x = 320
	people_card.size_flags_stretch_ratio = 0.85
	_add_review_slot(people, "TeamStateLabel", 48)
	var scroll := ScrollContainer.new()
	scroll.name = "PeopleScroll"
	scroll.custom_minimum_size = Vector2(0, 96)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	people.add_child(scroll)
	_native_review_people = VBoxContainer.new()
	_native_review_people.name = "DebriefPeopleList"
	_native_review_people.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_native_review_people.add_theme_constant_override("separation", 8)
	scroll.add_child(_native_review_people)
	var details := GridContainer.new()
	details.name = "DetailsGrid"
	details.columns = 2
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.size_flags_stretch_ratio = 1.85
	details.add_theme_constant_override("h_separation", 10)
	details.add_theme_constant_override("v_separation", 10)
	body.add_child(details)
	var feedback := _make_review_card(details, "FeedbackCard", "FTL-Rückmeldung")
	_add_review_slot(feedback, "FTLFeedbackLabel", 64)
	var aar := _make_review_card(details, "AARCard", "Gefechtsauswertung")
	_add_review_slot(aar, "AARSummaryLabel", 20)
	_add_review_slot(aar, "AARChipStrip", 26)
	_add_review_slot(aar, "AARRowsLabel", 32)
	_add_review_slot(aar, "AARLimitLabel", 28)
	_add_review_empty(aar, "Keine Gefechtsauswertung im Bericht.")
	var events := _make_review_card(details, "EventsCard", "Gemeldete Ereignisse")
	_add_review_slot(events, "CharacterEventsLabel", 52)
	_add_review_slot(events, "PersonnelEventsLabel", 52)
	var progress := _make_review_card(details, "ProgressCard", "Entwicklung · Vorschau / bestätigte Folgen")
	_add_review_slot(progress, "SkillProgressPreviewLabel", 44)
	_add_review_slot(progress, "SkillAwardSummaryLabel", 44)
	_add_review_empty(progress, "Keine Entwicklungsdaten oder bestätigten Auszeichnungen im Bericht.")
	var returns := _make_review_card(layout, "ReturnCard", "Rückweg · vorhandene Ziele")
	_add_review_slot(returns, "AirAssetEventsLabel", 22)
	_add_review_slot(returns, "ButtonRow", 40)
	set_meta("native_debrief_card_layout", "r2_snapshot_cards")


func _make_review_card(parent: Node, card_name: String, heading: String) -> VBoxContainer:
	var card := PanelContainer.new()
	card.name = card_name
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL if parent is GridContainer or parent is HBoxContainer else Control.SIZE_FILL
	TACTICAL_UI_THEME_SCRIPT.style_card(card)
	parent.add_child(card)
	var contents := VBoxContainer.new()
	contents.name = "Contents"
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_theme_constant_override("separation", 6)
	card.add_child(contents)
	if not heading.is_empty():
		var title := Label.new()
		title.text = heading
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		TACTICAL_UI_THEME_SCRIPT.style_label(title, false, 16)
		contents.add_child(title)
	return contents


func _add_review_slot(parent: VBoxContainer, source_name: String, height: int) -> void:
	var slot := Control.new()
	slot.name = source_name + "Slot"
	slot.custom_minimum_size = Vector2(0, height)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(slot)
	# Native containers can finish sorting after the first deferred render.
	# Follow actual slot geometry changes, without polling or frame rebuilds.
	slot.item_rect_changed.connect(_queue_native_review_layout)
	_native_review_slots[source_name] = slot


func _add_review_empty(parent: VBoxContainer, text: String) -> void:
	var empty := Label.new()
	empty.name = "EmptyLabel"
	empty.text = text
	empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	TACTICAL_UI_THEME_SCRIPT.style_label(empty, true, 13)
	parent.add_child(empty)


func _queue_native_review_layout() -> void:
	if _native_review_pending or not is_inside_tree() or _native_review_slots.is_empty():
		return
	_native_review_pending = true
	call_deferred("_apply_native_review_geometry")


func _apply_native_review_geometry() -> void:
	_native_review_pending = false
	set_meta("native_debrief_layout_passes", int(get_meta("native_debrief_layout_passes", 0)) + 1)
	for source_name in _native_review_slots:
		var source := get_node_or_null("Panel/Margin/VBox/" + source_name) as Control
		var slot := _native_review_slots[source_name] as Control
		if source == null or not source.visible or not slot.visible:
			continue
		if not source.is_set_as_top_level():
			source.set_as_top_level(true)
			source.set_anchors_preset(Control.PRESET_TOP_LEFT)
			source.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			source.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var rect := slot.get_global_rect()
		if source is Label:
			var label := source as Label
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.clip_text = true
			label.max_lines_visible = maxi(1, int(rect.size.y / float(label.get_theme_font_size("font_size") + 4)))
			label.tooltip_text = label.text
			label.mouse_filter = Control.MOUSE_FILTER_STOP
		# These legacy leaves are top-level Controls: use canvas-local absolute
		# position, then settle after any already queued legacy container sort.
		source.position = rect.position
		source.size = rect.size
		source.set_deferred("position", rect.position)
		source.set_deferred("size", rect.size)
		source.set_meta("native_debrief_card_slot", source_name)


func _ensure_character_events_label() -> Label:
	var vbox := get_node("Panel/Margin/VBox") as VBoxContainer
	var existing := vbox.get_node_or_null("CharacterEventsLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "CharacterEventsLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var button_row := vbox.get_node_or_null("ButtonRow")
	if button_row != null:
		vbox.add_child(label)
		vbox.move_child(label, button_row.get_index())
	else:
		vbox.add_child(label)
	return label


func _ensure_air_asset_events_label() -> Label:
	var vbox := get_node("Panel/Margin/VBox") as VBoxContainer
	var existing := vbox.get_node_or_null("AirAssetEventsLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "AirAssetEventsLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var button_row := vbox.get_node_or_null("ButtonRow")
	if button_row != null:
		vbox.add_child(label)
		vbox.move_child(label, button_row.get_index())
	else:
		vbox.add_child(label)
	return label


func _ensure_ftl_feedback_label() -> Label:
	var vbox := get_node("Panel/Margin/VBox") as VBoxContainer
	var existing := vbox.get_node_or_null("FTLFeedbackLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "FTLFeedbackLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var character_label := vbox.get_node_or_null("CharacterEventsLabel")
	var button_row := vbox.get_node_or_null("ButtonRow")
	if character_label != null:
		vbox.add_child(label)
		vbox.move_child(label, character_label.get_index())
	elif button_row != null:
		vbox.add_child(label)
		vbox.move_child(label, button_row.get_index())
	else:
		vbox.add_child(label)
	return label


func _ensure_aar_summary_label() -> Label:
	return _ensure_debrief_label_before_button_row("AARSummaryLabel")


func _ensure_aar_rows_label() -> Label:
	return _ensure_debrief_label_before_button_row("AARRowsLabel")


func _ensure_aar_limit_label() -> Label:
	return _ensure_debrief_label_before_button_row("AARLimitLabel")


func _ensure_skill_progress_preview_label() -> Label:
	return _ensure_debrief_label_before_button_row("SkillProgressPreviewLabel")


func _ensure_skill_award_summary_label() -> Label:
	return _ensure_debrief_label_before_button_row("SkillAwardSummaryLabel")


func _ensure_debrief_label_before_button_row(label_name: String) -> Label:
	var vbox := get_node("Panel/Margin/VBox") as VBoxContainer
	var existing := vbox.get_node_or_null(label_name) as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = label_name
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var button_row := vbox.get_node_or_null("ButtonRow")
	if button_row != null:
		vbox.add_child(label)
		vbox.move_child(label, button_row.get_index())
	else:
		vbox.add_child(label)
	return label


func _ensure_aar_chip_strip() -> HBoxContainer:
	var vbox := get_node("Panel/Margin/VBox") as VBoxContainer
	var existing := vbox.get_node_or_null("AARChipStrip") as HBoxContainer
	if existing != null:
		return existing
	var strip := HBoxContainer.new()
	strip.name = "AARChipStrip"
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.add_theme_constant_override("separation", 8)
	var rows_label := vbox.get_node_or_null("AARRowsLabel")
	if rows_label != null:
		vbox.add_child(strip)
		vbox.move_child(strip, rows_label.get_index())
	else:
		var button_row := vbox.get_node_or_null("ButtonRow")
		if button_row != null:
			vbox.add_child(strip)
			vbox.move_child(strip, button_row.get_index())
		else:
			vbox.add_child(strip)
	return strip


func _apply_contextual_help_ids() -> void:
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/CharacterEventsLabel") as Control, "debrief.character_updates")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/AirAssetEventsLabel") as Control, "fob.flightdeck")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/FTLFeedbackLabel") as Control, "character_sheet.ftl_tactical_impact")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/AARSummaryLabel") as Control, "debrief.mini_aar")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/SkillProgressPreviewLabel") as Control, "debrief.skill_preview")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/SkillAwardSummaryLabel") as Control, "debrief.skill_awards")


func _apply_readability_style() -> void:
	var panel := get_node_or_null("Panel") as PanelContainer
	if panel != null:
		META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "frame")
		_apply_debrief_panel_style(panel)
		panel.set_meta("debrief_contrast_policy", "translucent_high_contrast_panel")
		panel.set_meta("background_readability_policy", "dimmed_catalog_background")

	META_UI_SKIN_SCRIPT.style_header_label(get_node_or_null("Panel/Margin/VBox/TitleLabel"), 18)
	var title_label := get_node_or_null("Panel/Margin/VBox/TitleLabel") as Label
	if title_label != null:
		title_label.text = "Mission Debrief"
		title_label.set_meta("debrief_title_style_id", "debrief_title_v1")
	_apply_summary_chip_style()
	for path in [
		"Panel/Margin/VBox/ResultLabel",
		"Panel/Margin/VBox/TeamStateLabel",
		"Panel/Margin/VBox/AirAssetEventsLabel",
		"Panel/Margin/VBox/FTLFeedbackLabel",
		"Panel/Margin/VBox/AARSummaryLabel",
		"Panel/Margin/VBox/AARRowsLabel",
		"Panel/Margin/VBox/AARLimitLabel",
		"Panel/Margin/VBox/SkillProgressPreviewLabel",
		"Panel/Margin/VBox/SkillAwardSummaryLabel",
		"Panel/Margin/VBox/CharacterEventsLabel",
		"Panel/Margin/VBox/PersonnelEventsLabel",
	]:
		var label := get_node_or_null(path) as Label
		if label == null:
			continue
		META_UI_SKIN_SCRIPT.style_body_label(label, 13)
		label.add_theme_color_override("font_color", Color("d7e2e8"))
	var aar_limit_label := get_node_or_null("Panel/Margin/VBox/AARLimitLabel") as Label
	if aar_limit_label != null:
		aar_limit_label.add_theme_color_override("font_color", Color("a8b7c0"))
		aar_limit_label.add_theme_font_size_override("font_size", 12)
	_apply_aar_layout_polish_style()
	_apply_skill_progress_preview_style()
	_apply_skill_award_summary_style()
	_apply_aar_chip_style()

	for path in [
		"Panel/Margin/VBox/ButtonRow/ReturnToFOBButton",
		"Panel/Margin/VBox/ButtonRow/ReturnToHomebaseButton",
	]:
		var button := get_node_or_null(path) as Button
		if button == null:
			continue
		if button.name == "ReturnToHomebaseButton":
			META_UI_SKIN_SCRIPT.style_primary_button(button)
			button.set_meta("debrief_action_role", "primary_homebase")
		else:
			META_UI_SKIN_SCRIPT.style_secondary_button(button)
			button.set_meta("debrief_action_role", "secondary_fob")


func _apply_help_id(control: Control, help_id: String) -> void:
	if control == null:
		return
	var normalized_id: String = help_id.strip_edges()
	if normalized_id.is_empty():
		return
	control.set_meta("help_id", normalized_id)
	control.tooltip_text = ""


func _build_ftl_feedback_lines(entries: Array) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var fireteam_id: String = String(entry.get("fireteam_id", "")).strip_edges().to_upper()
		if fireteam_id.is_empty():
			fireteam_id = "TEAM"
		var reaction_delay: float = maxf(float(entry.get("reaction_delay_seconds", 0.0)), 0.0)
		var plan_quality: float = clampf(float(entry.get("plan_quality", 0.5)), 0.0, 1.0)
		var tempo_delta: int = int(round((clampf(float(entry.get("tempo_modifier", 1.0)), 0.0, 2.0) - 1.0) * 100.0))
		var contact_count: int = maxi(int(entry.get("contact_report_count", 0)), 0)
		var report_quality: float = clampf(float(entry.get("contact_report_quality", 0.5)), 0.0, 1.0)
		var morale: float = clampf(float(entry.get("morale", 0.5)), 0.0, 1.0)
		var frustration: float = clampf(float(entry.get("frustration", 0.0)), 0.0, 1.0)
		lines.append("%s: Reaktion %.2fs | Plan %s | Tempo %+d%% | Kontakte %d (Meldung %s) | Moral %s" % [
			fireteam_id,
			reaction_delay,
			_format_debrief_quality_bucket(plan_quality),
			tempo_delta,
			contact_count,
			_format_contact_report_quality_bucket(report_quality),
			_format_debrief_morale_bucket(morale, frustration),
		])
		if lines.size() >= 4:
			break
	return lines


func _extract_debrief_aar_payload() -> Dictionary:
	if _mission_result.is_empty():
		return {}
	var payload: Dictionary = Dictionary(_mission_result.get("mini_aar_debrief", {})).duplicate(true)
	if String(payload.get("schema", "")) == "sternenbuergerchen.mini_aar_debrief_screen_stub.v1":
		return payload
	var fallback: Dictionary = Dictionary(_mission_result.get("mini_aar", {})).duplicate(true)
	if String(fallback.get("schema", "")) == "sternenbuergerchen.mini_aar_debrief_screen_stub.v1":
		return fallback
	return {}


func _render_aar_bridge(payload: Dictionary, summary_label: Label, chip_strip: HBoxContainer, rows_label: Label, limit_label: Label) -> void:
	var has_payload: bool = String(payload.get("schema", "")) == "sternenbuergerchen.mini_aar_debrief_screen_stub.v1"
	if not has_payload:
		if summary_label != null:
			summary_label.text = "AAR: unavailable"
			summary_label.visible = false
		if chip_strip != null:
			chip_strip.visible = false
			_render_aar_chips(chip_strip, [])
		if rows_label != null:
			rows_label.text = ""
			rows_label.visible = false
			rows_label.set_meta("debrief_aar_row_count", 0)
		if limit_label != null:
			limit_label.text = ""
			limit_label.visible = false
		_apply_aar_layout_polish_style()
		return
	var summary_text: String = String(payload.get("summary_text", "")).strip_edges()
	if summary_text.is_empty():
		summary_text = String(Dictionary(payload.get("screen", {})).get("summary_text", "")).strip_edges()
	if summary_label != null:
		summary_label.text = _format_aar_summary_text(summary_text)
		summary_label.visible = true
	if chip_strip != null:
		chip_strip.visible = true
		_render_aar_chips(chip_strip, Array(payload.get("chips", [])))
	var row_lines: PackedStringArray = PackedStringArray()
	for row_variant in Array(payload.get("rows", [])):
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = Dictionary(row_variant)
		var label_text: String = String(row.get("label", row.get("id", ""))).strip_edges()
		var value_text: String = String(row.get("value_text", "")).strip_edges()
		if label_text.is_empty() or value_text.is_empty():
			continue
		row_lines.append("%s: %s" % [label_text, value_text])
		if row_lines.size() >= 4:
			break
	if rows_label != null:
		rows_label.text = "AAR Details: %s" % " | ".join(row_lines)
		rows_label.visible = not row_lines.is_empty()
		rows_label.set_meta("debrief_aar_row_count", row_lines.size())
	if limit_label != null:
		limit_label.text = String(payload.get("limit_text", "")).strip_edges()
		limit_label.visible = not limit_label.text.is_empty()
	_apply_aar_layout_polish_style()


func _render_aar_chips(strip: HBoxContainer, chips: Array) -> void:
	if strip == null:
		return
	while strip.get_child_count() > chips.size():
		var extra := strip.get_child(strip.get_child_count() - 1)
		strip.remove_child(extra)
		extra.queue_free()
	for index in range(chips.size()):
		var chip_data: Dictionary = Dictionary(chips[index])
		var chip: Label = null
		if index < strip.get_child_count():
			chip = strip.get_child(index) as Label
		if chip == null:
			chip = Label.new()
			strip.add_child(chip)
		var chip_id: String = String(chip_data.get("id", index)).strip_edges()
		var label_text: String = String(chip_data.get("label", chip_id)).strip_edges()
		var value_text: String = String(chip_data.get("value_text", "")).strip_edges()
		chip.name = "AARChip_%s" % chip_id
		chip.text = "%s %s" % [label_text, value_text]
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.clip_text = true
		chip.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		chip.set_meta("debrief_aar_chip_style_id", "debrief_aar_chip_v1")
		chip.set_meta("style_key", String(chip_data.get("style_key", "neutral")))
	_apply_aar_chip_style()


func _build_skill_progress_preview_entries() -> Array:
	var entries: Array = []
	for member_state_variant in Array(_mission_result.get("team_states", [])):
		if typeof(member_state_variant) != TYPE_DICTIONARY:
			continue
		var member_state: Dictionary = Dictionary(member_state_variant)
		var display_name: String = String(member_state.get("display_name", member_state.get("unit_id", "Unit"))).strip_edges()
		if display_name.is_empty():
			display_name = "Unit"
		var vital_state: String = String(member_state.get("vital_state", "unknown")).strip_edges().to_lower()
		var progress_hint: String = _format_skill_preview_status_hint(vital_state)
		entries.append({
			"id": String(member_state.get("unit_id", display_name)).strip_edges(),
			"kind": "unit",
			"label": display_name,
			"hint": progress_hint,
			"source": "team_states",
			"read_only": true,
		})
		if entries.size() >= 3:
			break
	for ftl_variant in Array(_mission_result.get("fireteam_tactical_debrief", [])):
		if typeof(ftl_variant) != TYPE_DICTIONARY:
			continue
		var ftl_entry: Dictionary = Dictionary(ftl_variant)
		var fireteam_id: String = String(ftl_entry.get("fireteam_id", "FT")).strip_edges().to_upper()
		if fireteam_id.is_empty():
			fireteam_id = "FT"
		entries.append({
			"id": fireteam_id.to_lower(),
			"kind": "fireteam",
			"label": fireteam_id,
			"hint": _format_skill_preview_ftl_hint(ftl_entry),
			"source": "fireteam_tactical_debrief",
			"read_only": true,
		})
		break
	return entries


func _format_skill_preview_status_hint(vital_state: String) -> String:
	match vital_state:
		"fit":
			return "field +"
		"wounded":
			return "recovery +"
		"down":
			return "medical review"
		"dead":
			return "loss review"
		_:
			return "field data"


func _format_skill_preview_ftl_hint(entry: Dictionary) -> String:
	var plan_quality: float = clampf(float(entry.get("plan_quality", 0.0)), 0.0, 1.0)
	var report_quality: float = clampf(float(entry.get("contact_report_quality", 0.0)), 0.0, 1.0)
	if plan_quality >= 0.66 and report_quality >= 0.66:
		return "tactics +"
	if plan_quality >= 0.66:
		return "orders +"
	if report_quality >= 0.66:
		return "reports +"
	return "lessons +"


func _render_skill_progress_preview(label: Label, entries: Array) -> void:
	if label == null:
		return
	if entries.is_empty():
		label.text = ""
		label.visible = false
		label.set_meta("debrief_skill_preview_entries", [])
		label.set_meta("debrief_skill_preview_token_count", 0)
		_apply_skill_progress_preview_style()
		return
	var tokens: PackedStringArray = PackedStringArray()
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var label_text: String = String(entry.get("label", "Unit")).strip_edges()
		var hint_text: String = String(entry.get("hint", "preview")).strip_edges()
		if label_text.is_empty() or hint_text.is_empty():
			continue
		tokens.append("%s %s" % [label_text, hint_text])
		if tokens.size() >= 4:
			break
	label.text = "Skill Preview: %s" % " | ".join(tokens)
	label.visible = not tokens.is_empty()
	label.set_meta("debrief_skill_preview_entries", entries)
	label.set_meta("debrief_skill_preview_token_count", tokens.size())
	_apply_skill_progress_preview_style()


func _render_skill_award_summary(label: Label, award_summary: Dictionary) -> void:
	if label == null:
		return
	if String(award_summary.get("schema", "")) != SKILL_AWARD_SUMMARY_SCHEMA:
		label.text = ""
		label.visible = false
		label.set_meta("debrief_skill_award_summary", {})
		_apply_skill_award_summary_style()
		return
	var text: String = String(award_summary.get("award_text", "")).strip_edges()
	if text.is_empty():
		text = "Awards: XP +%d | Skill %d | FTL %d | Recovery %d" % [
			int(award_summary.get("total_xp_delta", 0)),
			int(award_summary.get("skill_gain_count", 0)),
			int(award_summary.get("ftl_tactical_gain_count", 0)),
			int(award_summary.get("recovery_count", 0)),
		]
	if text.begins_with("Awards:"):
		text = text.substr(7).strip_edges()
	label.text = "Skill Awards: %s" % text
	label.visible = true
	label.set_meta("debrief_skill_award_summary", award_summary.duplicate(true))
	_apply_skill_award_summary_style()


func _format_aar_summary_text(summary_text: String) -> String:
	var normalized: String = summary_text.strip_edges()
	if normalized.begins_with("AAR:"):
		normalized = normalized.substr(4).strip_edges()
	if normalized.begins_with("AAR |"):
		normalized = normalized.substr(5).strip_edges()
	if normalized.begins_with("|"):
		normalized = normalized.substr(1).strip_edges()
	if normalized.is_empty():
		return "AAR unavailable"
	return "AAR | %s" % normalized


func _apply_aar_layout_polish_style() -> void:
	var summary_label := get_node_or_null("Panel/Margin/VBox/AARSummaryLabel") as Label
	var rows_label := get_node_or_null("Panel/Margin/VBox/AARRowsLabel") as Label
	var limit_label := get_node_or_null("Panel/Margin/VBox/AARLimitLabel") as Label
	if summary_label != null:
		summary_label.clip_text = true
		summary_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		summary_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		summary_label.add_theme_color_override("font_color", Color("62d4dd"))
		summary_label.add_theme_font_size_override("font_size", 14)
		summary_label.set_meta("debrief_aar_layout_style_id", DEBRIEF_AAR_LAYOUT_STYLE_ID)
		summary_label.set_meta("debrief_aar_summary_style_id", "debrief_aar_summary_v2")
	if rows_label != null:
		rows_label.clip_text = true
		rows_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		rows_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		rows_label.add_theme_color_override("font_color", Color("d7e2e8"))
		rows_label.add_theme_font_size_override("font_size", 12)
		rows_label.set_meta("debrief_aar_layout_style_id", DEBRIEF_AAR_LAYOUT_STYLE_ID)
		rows_label.set_meta("debrief_aar_rows_style_id", "debrief_aar_rows_v2")
	if limit_label != null:
		limit_label.clip_text = true
		limit_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		limit_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		limit_label.add_theme_color_override("font_color", Color("a8b7c0"))
		limit_label.add_theme_font_size_override("font_size", 11)
		limit_label.set_meta("debrief_aar_layout_style_id", DEBRIEF_AAR_LAYOUT_STYLE_ID)
		limit_label.set_meta("debrief_aar_limit_style_id", "debrief_aar_limit_v2")


func _apply_skill_progress_preview_style() -> void:
	var label := get_node_or_null("Panel/Margin/VBox/SkillProgressPreviewLabel") as Label
	if label == null:
		return
	label.clip_text = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_color_override("font_color", Color("cfe7b5"))
	label.add_theme_font_size_override("font_size", 12)
	label.set_meta("debrief_skill_preview_style_id", DEBRIEF_SKILL_PREVIEW_STYLE_ID)


func _apply_skill_award_summary_style() -> void:
	var label := get_node_or_null("Panel/Margin/VBox/SkillAwardSummaryLabel") as Label
	if label == null:
		return
	label.clip_text = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_color_override("font_color", Color("f6df8f"))
	label.add_theme_font_size_override("font_size", 12)
	label.set_meta("debrief_skill_award_style_id", DEBRIEF_SKILL_AWARD_STYLE_ID)


func _apply_aar_chip_style() -> void:
	var strip := get_node_or_null("Panel/Margin/VBox/AARChipStrip") as HBoxContainer
	if strip == null:
		return
	for child in strip.get_children():
		var chip := child as Label
		if chip == null:
			continue
		var style_key: String = String(chip.get_meta("style_key", "neutral"))
		chip.add_theme_color_override("font_color", Color("10161b"))
		chip.add_theme_font_size_override("font_size", 11)
		chip.add_theme_stylebox_override("normal", _build_aar_chip_stylebox(style_key))


func _build_aar_chip_stylebox(style_key: String) -> StyleBoxFlat:
	var stylebox := _build_chip_stylebox()
	match style_key:
		"good":
			stylebox.bg_color = Color("76d99a")
			stylebox.border_color = Color("9be7b4")
		"warn":
			stylebox.bg_color = Color("ffd34d")
			stylebox.border_color = Color("ffe07f")
		"accent":
			stylebox.bg_color = Color("62d4dd")
			stylebox.border_color = Color("9ce8ed")
		_:
			stylebox.bg_color = Color("d7e2e8")
			stylebox.border_color = Color("94a6b0")
	return stylebox


func _format_debrief_quality_bucket(value: float) -> String:
	if value >= 0.66:
		return "stark"
	if value >= 0.42:
		return "solide"
	return "roh"


func _format_contact_report_quality_bucket(value: float) -> String:
	if value >= 0.70:
		return "hoch"
	if value >= 0.42:
		return "mittel"
	return "niedrig"


func _format_debrief_morale_bucket(morale: float, frustration: float) -> String:
	if morale < 0.35 or frustration >= 0.68:
		return "kritisch"
	if morale < 0.48 or frustration >= 0.46:
		return "sinkt"
	if morale >= 0.64 and frustration <= 0.28:
		return "stabil"
	return "ruhig"


func _ensure_summary_strip() -> HBoxContainer:
	var vbox := get_node("Panel/Margin/VBox") as VBoxContainer
	var existing := vbox.get_node_or_null("SummaryStrip") as HBoxContainer
	if existing != null:
		return existing
	var strip := HBoxContainer.new()
	strip.name = "SummaryStrip"
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.add_theme_constant_override("separation", 8)
	vbox.add_child(strip)
	var result_label := vbox.get_node_or_null("ResultLabel")
	if result_label != null:
		vbox.move_child(strip, result_label.get_index())
	return strip


func _render_summary_chips(strip: HBoxContainer, chips: Array) -> void:
	if strip == null:
		return
	while strip.get_child_count() > chips.size():
		var extra := strip.get_child(strip.get_child_count() - 1)
		strip.remove_child(extra)
		extra.queue_free()
	for index in range(chips.size()):
		var chip_data: Dictionary = Dictionary(chips[index])
		var chip: Label = null
		if index < strip.get_child_count():
			chip = strip.get_child(index) as Label
		if chip == null:
			chip = Label.new()
			strip.add_child(chip)
		chip.name = "DebriefChip_%s" % String(chip_data.get("id", index)).strip_edges()
		chip.text = String(chip_data.get("text", "")).strip_edges()
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.clip_text = true
		chip.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		chip.set_meta("debrief_chip_style_id", "debrief_summary_chip_v1")
	_apply_summary_chip_style()


func _apply_summary_chip_style() -> void:
	var strip := get_node_or_null("Panel/Margin/VBox/SummaryStrip") as HBoxContainer
	if strip == null:
		return
	for child in strip.get_children():
		var chip := child as Label
		if chip == null:
			continue
		chip.add_theme_color_override("font_color", Color("172026"))
		chip.add_theme_font_size_override("font_size", 11)
		chip.add_theme_stylebox_override("normal", _build_chip_stylebox())


func _build_chip_stylebox() -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color("d7e2e8")
	stylebox.border_color = Color("94a6b0")
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.corner_radius_top_left = 5
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_left = 5
	stylebox.corner_radius_bottom_right = 5
	stylebox.content_margin_left = 8
	stylebox.content_margin_top = 5
	stylebox.content_margin_right = 8
	stylebox.content_margin_bottom = 5
	return stylebox


func _format_debrief_seconds(seconds: float) -> String:
	var total_seconds: int = maxi(int(round(seconds)), 0)
	var minutes: int = total_seconds / 60
	var remaining_seconds: int = total_seconds % 60
	if minutes <= 0:
		return "%d" % remaining_seconds
	return "%d:%02d" % [minutes, remaining_seconds]


func _format_compact_token(value: String, fallback: String) -> String:
	var normalized: String = value.strip_edges()
	if normalized.is_empty():
		normalized = fallback
	return normalized.replace("_", " ").to_upper()


func _format_team_state_counts(counts: Dictionary) -> String:
	var keys: Array = counts.keys()
	keys.sort()
	var parts: PackedStringArray = PackedStringArray()
	for key_variant in keys:
		var key: String = String(key_variant).strip_edges()
		if key.is_empty():
			continue
		parts.append("%s %d" % [key.to_upper(), int(counts.get(key, 0))])
	if parts.is_empty():
		return "UNKNOWN"
	return " / ".join(parts)


func _append_visual_polish_check(checks: Array, check_id: String, passed: bool, message: String) -> void:
	checks.append({
		"id": check_id,
		"passed": passed,
		"message": message,
	})


func _rect_to_dict(rect: Rect2) -> Dictionary:
	return {
		"x": rect.position.x,
		"y": rect.position.y,
		"width": rect.size.x,
		"height": rect.size.y,
		"right": rect.position.x + rect.size.x,
		"bottom": rect.position.y + rect.size.y,
	}


func _rect_inside(inner: Rect2, outer: Rect2) -> bool:
	if inner.size.x <= 0.0 or inner.size.y <= 0.0 or outer.size.x <= 0.0 or outer.size.y <= 0.0:
		return false
	return inner.position.x >= outer.position.x \
		and inner.position.y >= outer.position.y \
		and inner.position.x + inner.size.x <= outer.position.x + outer.size.x + 1.0 \
		and inner.position.y + inner.size.y <= outer.position.y + outer.size.y + 1.0


func _merge_rects(rects: Array) -> Rect2:
	var has_rect: bool = false
	var min_x: float = 0.0
	var min_y: float = 0.0
	var max_x: float = 0.0
	var max_y: float = 0.0
	for rect_variant in rects:
		var rect: Rect2 = rect_variant
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		if not has_rect:
			min_x = rect.position.x
			min_y = rect.position.y
			max_x = rect.position.x + rect.size.x
			max_y = rect.position.y + rect.size.y
			has_rect = true
			continue
		min_x = minf(min_x, rect.position.x)
		min_y = minf(min_y, rect.position.y)
		max_x = maxf(max_x, rect.position.x + rect.size.x)
		max_y = maxf(max_y, rect.position.y + rect.size.y)
	if not has_rect:
		return Rect2()
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)


func _apply_background_texture() -> void:
	var nodes: Dictionary = _ensure_background_nodes()
	var background := nodes.get("background") as TextureRect
	var shade := nodes.get("shade") as ColorRect
	var result: Dictionary = Dictionary(BACKGROUND_IMAGE_CATALOG_SCRIPT.call("apply_to_texture_rect", background, BACKGROUND_ID))
	var entry: Dictionary = Dictionary(result.get("entry", BACKGROUND_IMAGE_CATALOG_SCRIPT.call("get_entry", BACKGROUND_ID)))
	if shade != null:
		var dim_strength: float = clampf(float(entry.get("dim_strength", 0.62)), 0.0, 0.95)
		shade.color = Color(0.015, 0.027, 0.033, dim_strength)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if background != null:
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.set_meta("background_id", BACKGROUND_ID)
		background.set_meta("visual_only", true)


func _ensure_background_nodes() -> Dictionary:
	var background := get_node_or_null("Background") as TextureRect
	if background == null:
		background = TextureRect.new()
		background.name = "Background"
		add_child(background)
		move_child(background, 0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.offset_left = 0.0
	background.offset_top = 0.0
	background.offset_right = 0.0
	background.offset_bottom = 0.0
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var shade := get_node_or_null("BackgroundShade") as ColorRect
	if shade == null:
		shade = ColorRect.new()
		shade.name = "BackgroundShade"
		add_child(shade)
		move_child(shade, min(1, get_child_count() - 1))
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.offset_left = 0.0
	shade.offset_top = 0.0
	shade.offset_right = 0.0
	shade.offset_bottom = 0.0
	return {"background": background, "shade": shade}


func _apply_debrief_panel_style(panel: PanelContainer) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", TACTICAL_UI_THEME_SCRIPT.get_theme().get_stylebox("panel", "PanelContainer"))


func _ensure_personnel_events_label() -> Label:
	var vbox := get_node("Panel/Margin/VBox") as VBoxContainer
	var existing := vbox.get_node_or_null("PersonnelEventsLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "PersonnelEventsLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var button_row := vbox.get_node_or_null("ButtonRow")
	if button_row != null:
		vbox.add_child(label)
		vbox.move_child(label, button_row.get_index())
	else:
		vbox.add_child(label)
	return label


func _on_return_to_fob_pressed() -> void:
	return_to_fob_requested.emit()


func _on_return_to_homebase_pressed() -> void:
	return_to_homebase_requested.emit()
