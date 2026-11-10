extends SceneTree
## Distinguishes saved role, actual assignment and live suitability while
## keeping a compact read-only sheet and the editable sheet's controls.
const PROFILE = preload("res://scripts/meta/meta_unit_profile.gd")
const FORMATTER = preload("res://scripts/meta/character_sheet_formatter.gd")
const VIEW = preload("res://scripts/meta/character_sheet_view.gd")
const BADGES = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
var _passed := 0
var _failed := 0

func _init() -> void:
	call_deferred("_run")

func _fixture(role: String, value: float):
	return PROFILE.new({"unit_id": "fixture_" + role, "display_name": "Pruefperson", "roster_role_category": role, "role_name": "Dropship Pilot" if role == "pilot" else "Operator", "trait_ids": ["calm"], "skill_values": {"accuracy": value, "speed": value, "toughness": value, "awareness": value, "recognition": value, "discipline": value, "leadership": value, "stealth": value}, "communication_values": {"speech_quality": value, "speech_quantity": value}, "behavior_axes": {"contact_stability": value, "initiative": value, "order_fidelity": value, "autonomy": value}, "platform_values": {"dropship_piloting": value}, "progression": {"morale": 0.5, "frustration": 0.0}})

func _run() -> void:
	var pilot = _fixture("pilot", 0.2)
	var operator = _fixture("operator", 0.8)
	var before: Dictionary = pilot.to_dict()
	var assigned: Dictionary = FORMATTER.build_sheet_view_model(pilot, {"current_assignment_text": "Pilot · Mondfähre 1"})
	var unassigned: Dictionary = FORMATTER.build_sheet_view_model(operator)
	_check(String(assigned.get("start_role_text", "")) == "Pilot", "Saved pilot category remains visible even with weak pilot suitability")
	_check(String(assigned.get("current_assignment_text", "")) == "Pilot · Mondfähre 1", "Actual assignment is supplied independently of suitability")
	_check(String(unassigned.get("start_role_text", "")) == "Operator" and String(unassigned.get("current_assignment_text", "")).contains("nicht belegt"), "Strong operator suitability fabricates neither a pilot career nor an assignment")
	_check(String(Dictionary(Array(assigned.get("core_rows", [{}]))[0]).get("label", "")) == "Treffsicherheit", "Visible core stat uses German copy")
	var trait_row: Dictionary = Array(assigned.get("trait_rows", [{}]))[0]
	_check(String(trait_row.get("label", "")) == "Gelassen" and String(trait_row.get("detail_text", "")).contains("Führung +0,15"), "Trait explanation retains its exact signed effect in German")
	var stock = _fixture("pilot", 0.2)
	stock.callsign = "ROOK"
	stock.biography_text = "Pruefperson, callsign ROOK, joins the starting roster as pilot with useful strengths and visible gaps."
	stock.short_description = stock.biography_text
	var stock_before: Dictionary = stock.to_dict()
	var stock_model: Dictionary = FORMATTER.build_sheet_view_model(stock)
	_check(String(stock_model.short_description).contains("Startrolle: Pilot") and not String(stock_model.short_description).contains("joins the starting roster"), "Stock generated biography displays saved German facts without inventing a career")
	_check(stock.to_dict() == stock_before, "Translating stock display text preserves the saved biography and profile")
	var custom = _fixture("operator", 0.8)
	custom.short_description = "  My custom English history. Bitte exakt lassen.  "
	custom.biography_text = "Unchanged custom background."
	var custom_before: Dictionary = custom.to_dict()
	var custom_model: Dictionary = FORMATTER.build_sheet_view_model(custom)
	_check(String(custom_model.short_description) == custom.short_description and custom.to_dict() == custom_before, "Custom prose and surrounding whitespace remain verbatim in display and profile")
	var preset = _fixture("operator", 0.4)
	preset.short_description = "Former dock security lead who rebuilt a scattered relief squad into a disciplined boarding cell."
	_check(String(FORMATTER.build_sheet_view_model(preset).short_description).contains("Startrolle: Operator"), "Known preset biography uses actual saved role instead of untranslated stock history")
	var resolver = BADGES.new()
	if _check(resolver.has_method("get_pilot_score_breakdown"), "Existing score owner exposes actual pilot inputs"):
		var low: Dictionary = resolver.call("get_pilot_score_breakdown", pilot)
		var high: Dictionary = resolver.call("get_pilot_score_breakdown", operator)
		_check(is_equal_approx(float(low.get("score", -1.0)), 0.28) and is_equal_approx(float(high.get("score", -1.0)), 0.80), "Breakdown retains exact existing weighted score and role-context bonus")
		_check(is_equal_approx(float(low.get("role_bonus", -1.0)), 0.08) and is_zero_approx(float(high.get("role_bonus", -1.0))), "Saved role context is disclosed separately from measured inputs")
		_check(Array(low.get("factors", [])).size() == 7 and is_equal_approx(float(low.get("threshold", 0.0)), 0.52), "Breakdown exposes all seven factors and existing badge threshold")
	var host := VBoxContainer.new()
	host.size = Vector2(700, 900)
	root.add_child(host)
	VIEW.render(host, pilot, {"editable_metrics": false, "two_column_layout": true, "current_assignment_text": "Pilot · Mondfähre 1", "hide_loadout_dropdowns": true})
	await process_frame
	var sheet := host.find_child("SheetRoot", true, false) as Control
	_check(sheet != null and sheet.custom_minimum_size.x <= 700, "Read-only sheet fits the compact content width")
	var values := host.find_child("CharacterSheetDetails_values", true, false) as Control
	var toggle := host.find_child("CharacterSheetToggle_values", true, false) as Button
	_check(values != null and not values.visible and toggle != null, "Secondary stat details begin collapsed")
	if toggle != null and values != null:
		toggle.pressed.emit()
		_check(values.visible and host.find_child("ReadOnlyMetricBar_accuracy", true, false) != null, "Values action reveals the real read-only stat bars")
		_check(toggle.size_flags_horizontal == Control.SIZE_SHRINK_BEGIN, "Details action keeps its intrinsic width")
	var readable := true
	for label: Label in host.find_children("*", "Label", true, false):
		if not label.text.is_empty() and label.get_theme_font_size("font_size") < 15:
			readable = false
	_check(readable, "Compact read-only body and derivation labels use at least 15px fonts")
	var suitability := host.find_child("CharacterSheetDetails_suitability", true, false) as Control
	_check(values.get_index() < suitability.get_index(), "Core values precede all role derivations")
	var awareness_label := host.find_child("ReadOnlyMetricLabel_awareness", true, false) as Label
	_check(awareness_label != null and not awareness_label.clip_text and awareness_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "Larger compact metric labels wrap instead of clipping")
	var trait_label := host.find_child("TraitLabel_calm", true, false) as Label
	_check(trait_label != null and trait_label.tooltip_text.contains("Führung"), "Trait effect remains accessible on hover")
	_check(pilot.to_dict() == before, "Rendering and revealing details mutate no profile or assignment data")
	VIEW.render(host,pilot,{"editable_metrics":false,"two_column_layout":true,"current_assignment_text":"Pilot · Mondfähre 1","hide_loadout_dropdowns":true})
	_check(host.find_child("CharacterSheetDetails_values",true,false)==values and values.visible,"unchanged read-only refresh preserves expanded branches and controls")
	VIEW.render(host,pilot,{"editable_metrics":true,"two_column_layout":true})
	await process_frame
	_check(host.find_child("MetricSlider_accuracy",true,false)!=null,"editable character mode still renders its own controls")
	VIEW.render(host,pilot,{"editable_metrics":false,"two_column_layout":true,"current_assignment_text":"Pilot · Mondfähre 1","hide_loadout_dropdowns":true})
	await process_frame
	_check(host.find_child("MetricSlider_accuracy",true,false)==null and host.find_child("ReadOnlyMetricBar_accuracy",true,false)!=null,"return from editor invalidates old read-only cache")
	host.queue_free()
	await process_frame
	print("CHARACTER_SHEET_COMPACT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _check(value: bool, label: String) -> bool:
	if value:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		printerr("FAIL: ", label)
	return value
