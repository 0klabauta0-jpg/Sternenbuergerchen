extends SceneTree
## Reads real profiles and the actual Homebase popup. Relationship differences
## must follow stored links; the presentation may not change profiles or scores.
const PROFILE = preload("res://scripts/meta/meta_unit_profile.gd")
const FORMATTER = preload("res://scripts/meta/character_sheet_formatter.gd")
const BADGES = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const HOMEBASE = preload("res://scenes/meta/homebase_test_screen.tscn")
var _passed := 0
var _failed := 0

func _init() -> void:
	call_deferred("_run")

func _fixture(id: String, name_text: String, links: Array):
	return PROFILE.new({"unit_id": id, "display_name": name_text, "role_name": "Dropship Pilot", "roster_role_category": "pilot", "trait_ids": ["calm", "disciplined"], "skill_values": {"accuracy": 0.4, "speed": 0.6, "toughness": 0.5, "awareness": 0.8, "recognition": 0.7, "discipline": 0.8, "leadership": 0.5, "stealth": 0.4}, "platform_values": {"dropship_piloting": 0.85}, "relationship_links": links})

func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("FAIL: " + label)

func _run() -> void:
	var profiles: Array = [
		_fixture("detail_a", "Mara Seidel", [{"target_unit_id": "detail_b", "target_name": "Old name", "affinity": 0.35, "tags": ["trusts", "friend"], "reason": "start_roster_same_fireteam"}, {"target_unit_id": "detail_c", "affinity": -0.2, "tags": ["rival", "tension"], "reason": "start_roster_personality_friction"}]),
		_fixture("detail_b", "Timo Arendt", [{"target_unit_id": "detail_c", "affinity": 0.15, "tags": ["mentor"], "reason": "  Gemeinsam die Funkprüfung bestanden.  "}]),
		_fixture("detail_c", "Lea Brandt", []),
	]
	var names := {"detail_a": "Mara Seidel", "detail_b": "Timo Arendt", "detail_c": "Lea Brandt"}
	var before: Array = profiles.map(func(profile): return profile.to_dict())
	var scores: Array = profiles.map(func(profile): return BADGES.get_badge_progress_for_profile(profile))
	var models: Array = profiles.map(func(profile): return FORMATTER.build_sheet_view_model(profile, {"roster_names_by_id": names, "current_assignment_text": "Pilot · Mondfähre 1", "status_text": "active"}))
	var first_rows: Array = models[0].get("relationship_overview_rows", [])
	_check(first_rows.size() == 2, "Mixed profile exposes actual positive and negative relationships before details")
	if first_rows.size() == 2:
		_check(String(first_rows[0].label) == "Timo Arendt" and String(first_rows[0].value_text).contains("+0,35"), "Positive link uses current roster display name and exact signed affinity")
		_check(String(first_rows[1].label) == "Lea Brandt" and String(first_rows[1].value_text).contains("−0,20"), "Negative link identifies the actual named partner and signed score")
		_check(String(first_rows[0].value_text).contains("Vertrauen") and String(first_rows[1].value_text).contains("Spannung"), "Known relationship tags display in German")
		_check(String(first_rows[0].detail_text).contains("gleicher Trupp") and String(first_rows[1].detail_text).contains("persönliche Reibung"), "Explanation comes from stored start reasons")
	var second_rows: Array = models[1].get("relationship_overview_rows", [])
	_check(second_rows.size() == 1 and String(second_rows[0].get("label", "")) == "Lea Brandt", "Second real profile presents its different relationship identity")
	if second_rows.size() == 1:
		_check(String(second_rows[0].detail_text) == "  Gemeinsam die Funkprüfung bestanden.  ", "Custom stored reason and its whitespace remain verbatim")
	_check(Array(models[2].get("relationship_overview_rows", [])).is_empty() and String(models[2].get("relationship_empty_text", "")) == "Noch keine Beziehung bekannt.", "Same traits without stored links create no relationship")
	_check(not String(models[0].get("primary_suitability_reason", "")).is_empty(), "Strongest suitability has a visible explanation from its score owner")
	_check(Array(models[0].get("suitability_rows", [])).all(func(row: Dictionary): return not String(row.get("reason", "")).is_empty() and String(row.get("detail_text", "")).contains("Schwelle")), "Every detailed suitability retains its actual owner reason and existing threshold")
	var units: Array = profiles.map(func(profile): return profile.to_dict())
	var screen: Control = HOMEBASE.instantiate()
	root.add_child(screen)
	await process_frame
	screen.call("setup_roster", units)
	var screen_profiles_before: Dictionary = {}
	for id in Dictionary(screen.get("_profiles_by_id")):
		screen_profiles_before[id] = screen.get("_profiles_by_id")[id].to_dict()
	screen.call("_on_compact_card_open_requested", "detail_a", profiles[0], "verifier")
	for dimensions in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		screen.call("_update_character_sheet_visibility")
		for frame in range(3):
			await process_frame
		var popup: Control = screen.get_node("CharacterSheetPopup")
		var scroll: ScrollContainer = popup.find_child("PopupScroll", true, false)
		var header: Control = popup.find_child("CharacterIdentityOverview", true, false)
		var relationships: Control = popup.find_child("CharacterRelationshipOverview", true, false)
		var why: Label = popup.find_child("PrimarySuitabilityReason", true, false)
		_check(header != null and relationships != null and why != null, "%s real popup has identity, named relationships and causal suitability overview" % str(dimensions))
		if header != null and relationships != null and why != null:
			_check(scroll.get_global_rect().grow(1).encloses(header.get_global_rect()) and scroll.get_global_rect().grow(1).encloses(relationships.get_global_rect()), "%s important identity and relationships fit before scrolling" % str(dimensions))
			_check(why.get_theme_font_size("font_size") >= 13 and relationships.is_visible_in_tree(), "%s important explanation is readable and relationships begin expanded" % str(dimensions))
			var named_partner: Label = relationships.find_child("Relationship_detail_b", true, false)
			_check(named_partner != null and named_partner.text.contains("Timo Arendt") and not named_partner.text.contains("Old name"), "%s actual screen resolves current roster names for the visible partner" % str(dimensions))
			var start_role: Label = header.find_child("CharacterStartRole", true, false)
			var assignment: Label = header.find_child("CharacterAssignment", true, false)
			_check(start_role != null and assignment != null and start_role.text.contains("Pilot") and not assignment.text.is_empty(), "%s identity area uses actual saved role and separate assignment" % str(dimensions))
			print("DETAIL_RECTS ", dimensions, " popup=", popup.get_global_rect(), " header=", header.get_global_rect(), " relationships=", relationships.get_global_rect(), " reason=", why.get_global_rect())
		var values: Control = popup.find_child("CharacterSheetDetails_values", true, false)
		var toggle: Button = popup.find_child("CharacterSheetToggle_values", true, false)
		_check(values != null and not values.visible and toggle != null and toggle.size_flags_horizontal == Control.SIZE_SHRINK_BEGIN, "%s secondary values remain behind a compact action" % str(dimensions))
	var values_toggle: Button = screen.find_child("CharacterSheetToggle_values", true, false)
	if values_toggle != null:
		values_toggle.pressed.emit()
		_check(screen.find_child("ReadOnlyMetricBar_accuracy", true, false) != null and screen.find_child("CharacterSheetDetails_values", true, false).visible, "Real metric values remain reachable through the details action")
	_check(profiles.map(func(profile): return profile.to_dict()) == before and profiles.map(func(profile): return BADGES.get_badge_progress_for_profile(profile)) == scores, "Rendering and opening details preserve every profile and suitability score")
	var screen_profiles_after: Dictionary = {}
	for id in Dictionary(screen.get("_profiles_by_id")):
		screen_profiles_after[id] = screen.get("_profiles_by_id")[id].to_dict()
	_check(screen_profiles_after == screen_profiles_before, "Actual popup rendering and resizing preserve every screen-owned profile")
	screen.queue_free()
	await process_frame
	print("CHARACTER_DETAIL_HIERARCHY passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
