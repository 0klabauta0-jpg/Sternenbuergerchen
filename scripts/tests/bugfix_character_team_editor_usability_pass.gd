extends SceneTree

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")
const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const PORTRAIT_IDENTITY_CATALOG_SCRIPT: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
const NPC_RANK_BADGE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const CHARACTER_SHEET_VIEW_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_view.gd")
const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const UNIT_PROFILE_MATH_SCRIPT: GDScript = preload("res://scripts/npc/unit_profile_math.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== BUGFIX Character Team Editor Usability Pass ===")
	_test_rookie_budget_policy_contract()
	_test_rank_badges_expose_dynamic_help_details()
	await _test_team_editor_character_identity_and_metric_persistence()
	await _test_help_hover_ignores_freed_controls()
	await _test_map_editor_layer_stack_hint()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_rookie_budget_policy_contract() -> void:
	var editor: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("normalize_team_editor"))
	var policy: Dictionary = Dictionary(editor.get("point_budget_policy", {}))
	var size_policy: Dictionary = Dictionary(editor.get("team_size_policy", {}))
	_assert(int(editor.get("point_budget_max", 0)) == 30, "Team editor keeps the Rookie total budget at 30")
	_assert(int(policy.get("min_per_stat", -1)) == 0 and int(policy.get("max_per_stat", 0)) == 10, "Team editor exposes per-focus min/max")
	_assert(bool(policy.get("locks_supported", false)), "Team editor budget policy exposes focus locks")
	var stat_locks: Dictionary = Dictionary(editor.get("stat_locks", {}))
	for definition_variant in Array(editor.get("stat_definitions", [])):
		var definition: Dictionary = Dictionary(definition_variant)
		_assert(not String(definition.get("effect_text", "")).strip_edges().is_empty(), "Stat %s explains its derived effect" % String(definition.get("id", "")))
		_assert(stat_locks.has(String(definition.get("id", ""))), "Stat %s has an explicit lock flag" % String(definition.get("id", "")))
	_assert(int(size_policy.get("singleplayer_initial_min", 0)) == 20 and int(size_policy.get("singleplayer_initial_max", 0)) == 30, "Singleplayer start size policy is visible")
	_assert(int(size_policy.get("multiplayer_side_cap", 0)) == 40, "Multiplayer side cap is documented for UI scroll planning")


func _test_rank_badges_expose_dynamic_help_details() -> void:
	var shooter_profile: Dictionary = {
		"role_name": "Marksman",
		"weapon_1_id": "rifle",
		"skill_values": {
			"accuracy": 0.82,
			"leadership": 0.24,
		},
		"platform_values": {},
	}
	var badges: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("derive_badges", shooter_profile, 3))
	var shooter_badge: Dictionary = _find_badge(badges, "shooter")
	_assert(not shooter_badge.is_empty(), "Shooter badge can be derived from weapon and Accuracy")
	_assert(String(shooter_badge.get("help_id", "")) == "character_sheet.rank_badge.shooter", "Shooter badge exposes a granular help id")
	_assert(String(shooter_badge.get("reason", "")).contains("Treffsicherheit"), "Shooter badge reason explains the source value")
	_assert(String(shooter_badge.get("detail_text", "")).contains("0,52"), "Shooter badge detail exposes the threshold formula")
	var badge_control := TextureRect.new()
	NPC_RANK_BADGE_RESOLVER_SCRIPT.call("apply_badge_help_metadata", badge_control, shooter_badge)
	_assert(String(badge_control.get_meta("help_id", "")) == "character_sheet.rank_badge.shooter", "Badge controls carry the granular contextual help id")
	_assert(String(badge_control.tooltip_text).contains("Treffsicherheit"), "Badge native tooltip keeps the composition text for FOB/Homebase")
	badge_control.free()
	var stale_badge_profile: Dictionary = {
		"role_name": "Old Label",
		"rank_badges": [{"badge_key": "medic", "badge_id": "badge_role_medic", "label": "Medic"}],
		"skill_values": {"accuracy": 0.86, "awareness": 0.78, "recognition": 0.74, "discipline": 0.72, "speed": 0.62, "leadership": 0.20, "toughness": 0.44},
		"communication_values": {"speech_quality": 0.66, "speech_quantity": 0.44},
		"behavior_axes": {"order_fidelity": 0.74, "contact_stability": 0.62, "autonomy": 0.55, "initiative": 0.58},
		"platform_values": {},
	}
	var dynamic_badges: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badges_for_profile", stale_badge_profile, 3))
	_assert(_has_badge(dynamic_badges, "shooter") and not _only_badge(dynamic_badges, "medic"), "Stored rank_badges do not override live value-derived role rings")
	var value_medic_profile: Dictionary = {
		"role_name": "Rookie",
		"weapon_1_id": "none",
		"weapon_2_id": "none",
		"skill_values": {"discipline": 0.80, "awareness": 0.72, "recognition": 0.76, "toughness": 0.62, "accuracy": 0.30, "leadership": 0.42},
		"communication_values": {"speech_quality": 0.78, "speech_quantity": 0.38},
		"behavior_axes": {"order_fidelity": 0.80, "contact_stability": 0.76, "autonomy": 0.54, "initiative": 0.48},
		"platform_values": {},
	}
	_assert(_has_badge(Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("derive_badges", value_medic_profile, 3)), "medic"), "Medic ring can emerge from editable core/comms/behavior values without a fixed role label")
	var rookie_profile: Dictionary = {
		"role_name": "Rookie",
		"weapon_1_id": "none",
		"weapon_2_id": "none",
		"skill_values": {"accuracy": 0.18, "leadership": 0.16},
		"platform_values": {"dropship_piloting": 0.12},
	}
	var next_requirements: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_next_badge_requirements", rookie_profile, 2))
	_assert(not next_requirements.is_empty() and String(Dictionary(next_requirements[0]).get("requirement_text", "")).contains("Nötig"), "Rank badge resolver exposes next-rank requirements for greyed badges")
	var platform_low: Dictionary = Dictionary(UNIT_PROFILE_MATH_SCRIPT.call("build_character_bundle", {
		"role_id": "security_guard",
		"skill_accuracy": 0.30,
		"skill_speed": 0.30,
		"skill_toughness": 0.30,
		"skill_leadership": 0.20,
		"behavior_axes": {"initiative": 0.20, "order_fidelity": 0.20, "contact_stability": 0.20, "autonomy": 0.20},
	}))
	var platform_high: Dictionary = Dictionary(UNIT_PROFILE_MATH_SCRIPT.call("build_character_bundle", {
		"role_id": "security_guard",
		"skill_accuracy": 0.30,
		"skill_speed": 0.30,
		"skill_toughness": 0.30,
		"skill_leadership": 0.20,
		"behavior_axes": {"initiative": 0.90, "order_fidelity": 0.90, "contact_stability": 0.90, "autonomy": 0.90},
	}))
	var low_dropship: float = float(Dictionary(platform_low.get("platform_values", {})).get("dropship_piloting", -1.0))
	var high_dropship: float = float(Dictionary(platform_high.get("platform_values", {})).get("dropship_piloting", -1.0))
	_assert(low_dropship >= 0.0 and high_dropship > low_dropship + 0.10, "Platform skills derive from behavior axes instead of role-only fallbacks")
	var host := VBoxContainer.new()
	root.add_child(host)
	CHARACTER_SHEET_VIEW_SCRIPT.call("render", host, META_UNIT_PROFILE_SCRIPT.new(rookie_profile), {"show_badge_progress": true})
	var locked_badge := _find_node_with_meta(host, "rank_badge_locked") as TextureRect
	_assert(locked_badge != null and bool(locked_badge.get_meta("rank_badge_locked", false)), "Character sheet greys out rank badge icons when no rank is reached")
	_assert(locked_badge != null and String(locked_badge.tooltip_text).contains("Nötig"), "Greyed badge hover tooltip explains what the next rank needs")
	_assert(host.find_child("RankBadgeGrid", true, false) is GridContainer, "Character sheet renders role rings as a badge grid")
	_assert(host.find_child("RankBadgeLabel_pilot", true, false) is Label, "Character sheet labels each badge below the icon")
	_assert(_count_nodes_with_meta(host, "rank_badge_progress_candidate") >= 6, "Character sheet can show all role-ring possibilities as progress badges")
	_assert(host.find_child("NextRankRequirementLabel", true, false) is Label, "Character sheet renders next-rank requirement text below badges")
	host.queue_free()


func _test_team_editor_character_identity_and_metric_persistence() -> void:
	root.size = Vector2i(1920, 1080)
	var save_path: String = "user://bugfix_team_character_editor_%d/roster_v1.json" % Time.get_ticks_msec()
	var menu := MAIN_MENU_SCENE.instantiate() as Control
	root.add_child(menu)
	await _wait_frames(3)
	menu.call("set_start_roster_store_path_for_tests", save_path, "bugfix_team_character_editor", true)
	menu.call("ensure_start_roster_exists", "bugfix_team_character_editor_seed", 24)
	_assert(_start_roster_badges_are_capped(menu), "Start roster begins with at most one active role ring per NPC")
	var library_snapshot: Dictionary = Dictionary(menu.call("get_team_library_snapshot"))
	_assert(bool(library_snapshot.get("edit_enabled", false)), "Created team list exposes an explicit edit action")
	menu.call("open_team_editor")
	menu.call("set_team_editor_view_mode_for_tests", "nine")
	await _wait_frames(2)
	var sheet_snapshot: Dictionary = Dictionary(menu.call("get_team_editor_snapshot"))
	var selected_unit_id: String = String(sheet_snapshot.get("selected_unit_id", ""))
	_assert(String(sheet_snapshot.get("view_mode", "")) == "sheet" and bool(sheet_snapshot.get("sheet_visible", false)), "Team editor is sheet-only even when a legacy card mode is requested")
	_assert(menu.find_child("TeamEditorViewSixButton", true, false) == null and menu.find_child("TeamEditorViewNineButton", true, false) == null, "Legacy 6er/9er team editor tabs are removed")
	_assert(bool(sheet_snapshot.get("character_name_edit_visible", false)), "Character sheet mode exposes a name editor")
	_assert(int(sheet_snapshot.get("character_portrait_option_count", 0)) >= 30, "Character sheet mode exposes portrait choices from the catalog")
	_assert(int(sheet_snapshot.get("character_portrait_option_icon_count", 0)) >= 30, "Portrait dropdown entries include mini preview icons")
	_assert(bool(sheet_snapshot.get("character_has_portrait_preview", false)), "Character sheet mode shows a live portrait preview")
	var help_ids: PackedStringArray = _collect_help_ids(menu)
	for required_help_id in [
		"team_editor.team_name",
		"team_editor.symbol",
		"team_editor.stat.lock",
		"character_sheet.name",
		"character_sheet.portrait",
		"character_sheet.skill_group_budget",
		"character_sheet.value_lock",
		"character_sheet.core.accuracy",
		"character_sheet.platform.dropship_piloting",
		"character_sheet.trait.calm",
		"character_sheet.trait.steady",
	]:
		_assert(help_ids.has(required_help_id), "Team editor exposes granular help popup ID: %s" % required_help_id)
	_assert(String(sheet_snapshot.get("budget_explanation", "")).contains("NPC-Werte"), "Team focus copy explains that NPC values are edited separately")
	_assert(not bool(sheet_snapshot.get("short_description_section_visible", true)), "Team editor sheet hides the short description block")
	_assert(menu.find_child("CharacterSheetTwoColumnBody", true, false) != null and menu.find_child("CharacterSheetValuesColumn", true, false) != null and menu.find_child("CharacterSheetContextColumn", true, false) != null, "Character sheet renders value bars left and affected context right")
	_assert(menu.find_child("NextRankRequirementLabel", true, false) is Label, "Character sheet shows next-rank requirements below the badges")
	_assert(menu.find_child("TeamEditorBadgeGrid", true, false) is GridContainer, "Team editor card badges are arranged in labeled columns")
	_assert(_count_nodes_with_meta(menu, "rank_badge_progress_candidate") >= 6, "Team editor sheet shows achieved and greyed role-ring possibilities")
	_assert(_scroll_has_hover_contract(menu, "TeamEditorCardsScroll") and _scroll_has_hover_contract(menu, "TeamEditorStatsScroll"), "Team editor scroll regions activate on hover")
	_assert(menu.find_child("TeamEditorValue_tactics", true, false) is HSlider, "Team focus values are draggable sliders")
	_assert(menu.find_child("TeamEditorLock_tactics", true, false) is Button, "Team focus rows expose a lock button")
	var focus_plus_button := menu.find_child("TeamEditorPlus_tactics", true, false) as Button
	var focus_plus_button_found: bool = focus_plus_button != null
	var focus_before_plus: Dictionary = Dictionary(Dictionary(menu.call("get_team_editor_snapshot")).get("allocations", {})).duplicate(true)
	if focus_plus_button != null:
		focus_plus_button.emit_signal("pressed")
		await _wait_frames(2)
	var focus_after_plus: Dictionary = Dictionary(Dictionary(menu.call("get_team_editor_snapshot")).get("allocations", {})).duplicate(true)
	var focus_plus_ok: bool = focus_plus_button_found \
		and int(focus_after_plus.get("tactics", 0)) == int(focus_before_plus.get("tactics", 0)) + 1 \
		and _team_focus_total(focus_after_plus) == 30 \
		and _team_focus_delta_sum(focus_before_plus, focus_after_plus, -1, "tactics") == 1
	_assert(focus_plus_ok, "Team focus plus takes one point from another unlocked focus")
	var focus_target: Dictionary = Dictionary(menu.call("set_team_editor_stat_for_tests", "tactics", 10))
	var focus_after_target: Dictionary = Dictionary(Dictionary(menu.call("get_team_editor_snapshot")).get("allocations", {})).duplicate(true)
	_assert(int(focus_target.get("value", 0)) == 10 and _all_other_team_focus_values_equal(focus_after_target, "tactics", 4), "Raising one focus by five lowers the five other focus values by one each")
	var focus_lower: Dictionary = Dictionary(menu.call("set_team_editor_stat_for_tests", "tactics", 5))
	var focus_after_lower: Dictionary = Dictionary(Dictionary(menu.call("get_team_editor_snapshot")).get("allocations", {})).duplicate(true)
	_assert(int(focus_lower.get("value", 0)) == 5 and _all_other_team_focus_values_equal(focus_after_lower, "tactics", 5), "Lowering one focus by five returns one point to each other unlocked focus")
	menu.call("set_team_editor_view_mode_for_tests", "sheet")
	await _wait_frames(2)
	var set_name: Dictionary = Dictionary(menu.call("set_team_editor_unit_name_for_tests", selected_unit_id, "Edited Rookie"))
	_assert(bool(set_name.get("ok", false)) and _unit_field(menu, selected_unit_id, "display_name") == "Edited Rookie", "Character name edits persist immediately")
	var next_portrait_id: String = _find_different_portrait_id(String(_unit_field(menu, selected_unit_id, "portrait_id")))
	var set_portrait: Dictionary = Dictionary(menu.call("set_team_editor_unit_portrait_for_tests", selected_unit_id, next_portrait_id))
	_assert(bool(set_portrait.get("ok", false)) and _unit_field(menu, selected_unit_id, "portrait_id") == next_portrait_id, "Portrait selection persists immediately")
	var medical_low: Dictionary = Dictionary(menu.call("set_team_editor_stat_for_tests", "medical", 0))
	var tactics_high: Dictionary = Dictionary(menu.call("set_team_editor_stat_for_tests", "tactics", 10))
	var blocked_above_max: Dictionary = Dictionary(menu.call("set_team_editor_stat_for_tests", "tactics", 11))
	_assert(bool(medical_low.get("ok", false)) and bool(tactics_high.get("ok", false)), "Rookie budget can move points between focuses")
	_assert(int(blocked_above_max.get("value", 0)) == 10, "Per-focus max blocks values above 10")
	var locked_tactics: Dictionary = Dictionary(menu.call("set_team_editor_stat_lock_for_tests", "tactics", true))
	var blocked_locked_tactics: Dictionary = Dictionary(menu.call("set_team_editor_stat_for_tests", "tactics", 3))
	_assert(bool(locked_tactics.get("ok", false)) and String(blocked_locked_tactics.get("reason", "")) == "locked" and int(blocked_locked_tactics.get("value", 0)) == 10, "Locked team focus blocks direct value changes")
	menu.call("set_team_editor_stat_lock_for_tests", "tactics", false)
	var old_accuracy: float = _unit_skill_value(menu, selected_unit_id, "accuracy")
	var old_function_summary: String = String(Dictionary(menu.call("get_team_editor_snapshot")).get("selected_unit_function_summary", ""))
	var plus_button := menu.find_child("MetricPlus_accuracy", true, false) as Button
	_assert(plus_button != null, "Character sheet renders editable core metric controls in the team editor")
	_assert(menu.find_child("MetricSlider_accuracy", true, false) is HSlider, "Character sheet core metric renders a draggable slider")
	_assert(menu.find_child("MetricLock_accuracy", true, false) is Button, "Character sheet core metric renders a lock button")
	var metric_value_label := menu.find_child("MetricValueLabel_accuracy", true, false) as Label
	var metric_minus_button := menu.find_child("MetricMinus_accuracy", true, false) as Button
	_assert(metric_value_label != null and metric_minus_button != null and metric_value_label.get_parent() == metric_minus_button.get_parent() and metric_value_label.get_index() < metric_minus_button.get_index(), "Character metric value is placed left of the minus button")
	_assert(menu.find_child("MetricGroupBudget_progression", true, false) is Label, "Character sheet status bars are grouped with a point budget")
	_assert(menu.find_child("MetricGroupBudget_skill_values", true, false) is Label, "Character sheet core values show a group point budget")
	_assert(menu.find_child("MetricPlus_dropship_piloting", true, false) != null, "Character sheet exposes editable dropship piloting")
	_assert(menu.find_child("MetricPlus_freighter_piloting", true, false) != null, "Character sheet exposes editable freighter piloting")
	_assert(menu.find_child("MetricPlus_fighter_piloting", true, false) != null, "Character sheet exposes editable fighter piloting")
	var old_speed: float = _unit_skill_value(menu, selected_unit_id, "speed")
	var speed_slider := menu.find_child("MetricSlider_speed", true, false) as HSlider
	_assert(speed_slider != null, "Character sheet speed metric exposes a drag slider")
	if speed_slider != null:
		speed_slider.emit_signal("drag_started")
		speed_slider.emit_signal("value_changed", maxf(old_speed - 0.10, 0.0))
		await _wait_frames(2)
		_assert(is_instance_valid(speed_slider), "Dragging a metric slider keeps the sheet controls alive before commit")
		_assert(is_equal_approx(_unit_skill_value(menu, selected_unit_id, "speed"), old_speed), "Dragging a metric slider does not save and refresh on every mouse move")
		speed_slider.emit_signal("drag_ended", true)
		await _wait_frames(2)
		_assert(_unit_skill_value(menu, selected_unit_id, "speed") < old_speed - 0.001, "Metric slider commits once when the drag ends")
	if plus_button != null:
		plus_button.emit_signal("pressed")
		await _wait_frames(2)
		_assert(is_instance_valid(plus_button), "Metric plus keeps the sheet controls alive during the value commit")
	_assert(_unit_skill_value(menu, selected_unit_id, "accuracy") > old_accuracy, "Character metric edits persist back into the roster")
	var stress_plus_button := menu.find_child("MetricPlus_speed", true, false) as Button
	var stress_minus_button := menu.find_child("MetricMinus_speed", true, false) as Button
	_assert(stress_plus_button != null and stress_minus_button != null, "Character sheet exposes stable controls for repeated metric edits")
	for _stress_index in range(12):
		if is_instance_valid(stress_plus_button) and not stress_plus_button.disabled:
			stress_plus_button.emit_signal("pressed")
		if is_instance_valid(stress_minus_button) and not stress_minus_button.disabled:
			stress_minus_button.emit_signal("pressed")
		await _wait_frames(1)
	_assert((stress_plus_button == null or is_instance_valid(stress_plus_button)) and (stress_minus_button == null or is_instance_valid(stress_minus_button)), "Repeated metric edits do not free the active sheet controls")
	var new_function_summary: String = String(Dictionary(menu.call("get_team_editor_snapshot")).get("selected_unit_function_summary", ""))
	_assert(new_function_summary != old_function_summary, "Derived function summary refreshes after a live value edit")
	var accuracy_after_edit: float = _unit_skill_value(menu, selected_unit_id, "accuracy")
	var core_before_rebalance: Dictionary = Dictionary(_unit_field(menu, selected_unit_id, "skill_values")).duplicate(true)
	var core_points_before_rebalance: int = _unit_skill_points(menu, selected_unit_id)
	var budget_set: Dictionary = Dictionary(menu.call("set_team_editor_metric_group_budget_for_tests", selected_unit_id, "skill_values", core_points_before_rebalance))
	await _wait_frames(2)
	var rebalance_plus_button := menu.find_child("MetricPlus_accuracy", true, false) as Button
	_assert(bool(budget_set.get("ok", false)) and rebalance_plus_button != null and not rebalance_plus_button.disabled, "Core budget can be clamped to current spend for redistribution test")
	if rebalance_plus_button != null:
		rebalance_plus_button.emit_signal("pressed")
		await _wait_frames(2)
	var core_after_rebalance: Dictionary = Dictionary(_unit_field(menu, selected_unit_id, "skill_values")).duplicate(true)
	_assert(_unit_skill_points(menu, selected_unit_id) == core_points_before_rebalance, "Raising one core value keeps the group budget balanced")
	_assert(_unit_skill_value(menu, selected_unit_id, "accuracy") > accuracy_after_edit and _any_core_value_decreased(core_before_rebalance, core_after_rebalance, "accuracy"), "Raising one unlocked core value pulls points from another unlocked core value")
	accuracy_after_edit = _unit_skill_value(menu, selected_unit_id, "accuracy")
	var metric_lock_result: Dictionary = Dictionary(menu.call("set_team_editor_metric_lock_for_tests", selected_unit_id, "skill_values", "accuracy", true))
	await _wait_frames(2)
	var metric_lock_snapshot: Dictionary = Dictionary(menu.call("get_team_editor_snapshot"))
	_assert(bool(metric_lock_result.get("ok", false)) and Dictionary(metric_lock_snapshot.get("metric_locks", {})).has("%s|skill_values.accuracy" % selected_unit_id), "Character metric locks persist in team editor data")
	var locked_plus_button := menu.find_child("MetricPlus_accuracy", true, false) as Button
	_assert(locked_plus_button != null and locked_plus_button.disabled, "Locked character metric disables upward edits")
	if locked_plus_button != null:
		locked_plus_button.emit_signal("pressed")
		await _wait_frames(2)
	_assert(is_equal_approx(_unit_skill_value(menu, selected_unit_id, "accuracy"), accuracy_after_edit), "Locked character metric keeps its value when pressed")
	_assert(menu.find_child("DerivedDependencyGuide", true, false) != null, "Character sheet shows a visual dependency guide for derived values")
	var derived_detail := menu.find_child("DerivedDetail_arbeitsweise", true, false) as Label
	_assert(derived_detail != null and derived_detail.custom_minimum_size.x >= 220.0 and derived_detail.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "Derived values show readable formula/detail text without one-letter wrapping")
	menu.queue_free()
	await _wait_frames(2)


func _test_help_hover_ignores_freed_controls() -> void:
	var menu := MAIN_MENU_SCENE.instantiate() as Control
	root.add_child(menu)
	await _wait_frames(3)
	var hover_target := Button.new()
	hover_target.name = "FreedHelpHoverProbe"
	menu.add_child(hover_target)
	menu.call("_on_help_target_entered", hover_target, "team_editor.stat.tactics")
	var hover_token: int = int(menu.get("_help_hover_token"))
	hover_target.queue_free()
	await _wait_frames(2)
	_assert(not bool(menu.call("_help_hover_is_current", hover_token, "team_editor.stat.tactics", hover_target)), "Main menu help hover ignores controls freed before the delayed popup")
	await _wait_frames(40)
	var help_snapshot: Dictionary = Dictionary(menu.call("get_contextual_help_snapshot"))
	var popup_snapshot: Dictionary = Dictionary(help_snapshot.get("popup", {}))
	_assert(not bool(popup_snapshot.get("visible", false)), "Delayed help popup stays hidden after its hover target was freed")
	menu.queue_free()
	await _wait_frames(2)


func _test_map_editor_layer_stack_hint() -> void:
	var editor := MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	_assert(bool(editor.call("select_grid_for_authoring", Vector2i(1, 1))), "Map editor can select a tile for layer-stack inspection")
	var map_data = editor.get("_terrain_map_data")
	var tile_data = map_data.call("get_tile_at_grid", Vector2i(1, 1)) if map_data != null else null
	_assert(tile_data != null, "Selected map tile exists")
	if tile_data != null:
		tile_data.type_id = "station_wall"
		tile_data.object_type_id = "spacekit_satellite_dish"
		editor.call("_refresh_property_panel")
		var selected_tile: Dictionary = Dictionary(Dictionary(editor.call("get_map_editor_usability_snapshot", false)).get("selected_tile", {}))
		var layer_stack: Dictionary = Dictionary(selected_tile.get("layer_stack", {}))
		_assert(String(layer_stack.get("structure_layer", "")) == "station_wall", "Layer stack keeps the structure layer")
		_assert(String(layer_stack.get("object_layer", "")) == "spacekit_satellite_dish", "Layer stack keeps an object on top of the structure")
		_assert(bool(layer_stack.get("has_object_on_structure", false)), "Map editor documents object-on-structure stacking")
		_assert(String(layer_stack.get("help_text", "")).contains("Satellitenschuessel"), "Layer stack tooltip explains the satellite dish workflow")
	editor.queue_free()
	await _wait_frames(2)


func _unit_field(menu: Control, unit_id: String, key: String) -> Variant:
	for unit_variant in Array(Dictionary(menu.get("_start_roster")).get("units", [])):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		if String(unit.get("unit_id", "")) == unit_id:
			return unit.get(key)
	return null


func _unit_skill_value(menu: Control, unit_id: String, skill_id: String) -> float:
	var skill_values: Dictionary = Dictionary(_unit_field(menu, unit_id, "skill_values"))
	return float(skill_values.get(skill_id, 0.0))


func _unit_skill_points(menu: Control, unit_id: String) -> int:
	var skill_values: Dictionary = Dictionary(_unit_field(menu, unit_id, "skill_values"))
	var total: int = 0
	for skill_id in ["accuracy", "speed", "toughness", "awareness", "recognition", "stealth", "discipline", "leadership"]:
		total += roundi(clampf(float(skill_values.get(skill_id, 0.0)), 0.0, 1.0) * 20.0)
	return total


func _team_focus_total(allocations: Dictionary) -> int:
	var total: int = 0
	for stat_id in ["tactics", "medical", "engineering", "piloting", "discipline", "recon"]:
		total += int(allocations.get(stat_id, 0))
	return total


func _team_focus_delta_sum(before_values: Dictionary, after_values: Dictionary, expected_delta: int, ignored_stat_id: String) -> int:
	var total: int = 0
	for stat_id in ["tactics", "medical", "engineering", "piloting", "discipline", "recon"]:
		if stat_id == ignored_stat_id:
			continue
		if int(after_values.get(stat_id, 0)) - int(before_values.get(stat_id, 0)) == expected_delta:
			total += 1
	return total


func _all_other_team_focus_values_equal(values: Dictionary, ignored_stat_id: String, expected_value: int) -> bool:
	for stat_id in ["tactics", "medical", "engineering", "piloting", "discipline", "recon"]:
		if stat_id == ignored_stat_id:
			continue
		if int(values.get(stat_id, -999)) != expected_value:
			return false
	return true


func _any_core_value_decreased(before_values: Dictionary, after_values: Dictionary, ignored_skill_id: String) -> bool:
	for skill_id in ["accuracy", "speed", "toughness", "awareness", "recognition", "stealth", "discipline", "leadership"]:
		if skill_id == ignored_skill_id:
			continue
		if float(after_values.get(skill_id, 0.0)) < float(before_values.get(skill_id, 0.0)) - 0.001:
			return true
	return false


func _start_roster_badges_are_capped(menu: Control) -> bool:
	for unit_variant in Array(Dictionary(menu.get("_start_roster")).get("units", [])):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		if Array(unit.get("rank_badges", [])).size() > 1:
			return false
		var achieved_count: int = 0
		var progress: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badge_progress_for_profile", META_UNIT_PROFILE_SCRIPT.new(unit), 0, false))
		for badge_variant in progress:
			if typeof(badge_variant) != TYPE_DICTIONARY:
				continue
			var badge: Dictionary = Dictionary(badge_variant)
			if String(badge.get("badge_key", "")).strip_edges() == "enemy":
				continue
			if bool(badge.get("achieved", false)):
				achieved_count += 1
		if achieved_count > 1:
			return false
	return true


func _find_badge(badges: Array, badge_key: String) -> Dictionary:
	for badge_variant in badges:
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		if String(badge.get("badge_key", "")).strip_edges() == badge_key:
			return badge
	return {}


func _has_badge(badges: Array, badge_key: String) -> bool:
	return not _find_badge(badges, badge_key).is_empty()


func _only_badge(badges: Array, badge_key: String) -> bool:
	var seen_badge: bool = false
	for badge_variant in badges:
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		seen_badge = true
		if String(badge.get("badge_key", "")).strip_edges() != badge_key:
			return false
	return seen_badge


func _find_node_with_meta(node: Node, meta_key: String) -> Node:
	if node == null:
		return null
	if node.has_meta(meta_key):
		return node
	for child in node.get_children():
		var found := _find_node_with_meta(child, meta_key)
		if found != null:
			return found
	return null


func _count_nodes_with_meta(node: Node, meta_key: String) -> int:
	if node == null:
		return 0
	var count: int = 1 if node.has_meta(meta_key) else 0
	for child in node.get_children():
		count += _count_nodes_with_meta(child, meta_key)
	return count


func _find_different_portrait_id(current_id: String) -> String:
	for entry_variant in Array(PORTRAIT_IDENTITY_CATALOG_SCRIPT.call("get_candidate_entries")):
		var entry: Dictionary = Dictionary(entry_variant)
		var entry_id: String = String(entry.get("id", ""))
		if not entry_id.is_empty() and entry_id != current_id:
			return entry_id
	return current_id


func _scroll_has_hover_contract(root_node: Node, node_name: String) -> bool:
	var scroll := root_node.find_child(node_name, true, false) as ScrollContainer
	return scroll != null and bool(scroll.get_meta("hover_scroll_enabled", false)) and scroll.focus_mode == Control.FOCUS_ALL


func _collect_help_ids(node: Node) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if node == null:
		return result
	if node.has_meta("help_id"):
		var help_id: String = String(node.get_meta("help_id", "")).strip_edges()
		if not help_id.is_empty() and not result.has(help_id):
			result.append(help_id)
	for child in node.get_children():
		for child_help_id in _collect_help_ids(child):
			if not result.has(child_help_id):
				result.append(child_help_id)
	return result


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
