extends SceneTree

const MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== BUGFIX Mission Fireteam FOB Payload and Bubbles ===")
	await _test_mission_uses_fob_unit_configs_and_lead()
	await _test_hud_bubbles_are_compact_and_do_not_overlap()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_mission_uses_fob_unit_configs_and_lead() -> void:
	var mission: Node = MISSION_SCENE.instantiate()
	var selected_unit_ids := PackedStringArray(["player_sternenbuergerchen_08", "player_sternenbuergerchen_12"])
	var selected_fireteam_ids := PackedStringArray(["ft1", "ft1"])
	var member_loadouts: Dictionary = {
		"player_sternenbuergerchen_08": {"armor": "medium", "weapon_1": "smg", "weapon_2": "smg"},
		"player_sternenbuergerchen_12": {"armor": "light", "weapon_1": "smg", "weapon_2": "medictool", "is_fireteam_lead": true},
	}
	var fireteam_definitions: Array = [
		{
			"id": "ft1",
			"label": "Fireteam 1",
			"lead_unit_id": "player_sternenbuergerchen_12",
			"loadout": "medium",
			"member_loadouts": member_loadouts.duplicate(true),
		}
	]
	var unit_configs: Array = [
		{
			"unit_id": "player_sternenbuergerchen_08",
			"display_name": "FOB Mira Acht",
			"callsign": "MIRA",
			"portrait_path": "res://Assets/Char/Use AI Image Apr 5, 2026, 22_30_03.png",
			"role_name": "Combat Medic",
			"team_id": "team_alpha",
			"skill_leadership": 0.22,
		},
		{
			"unit_id": "player_sternenbuergerchen_12",
			"display_name": "FOB Theo Zwoelf",
			"callsign": "THEO",
			"portrait_path": "res://Assets/Char/Use AI Image Apr 5, 2026, 22_22_42.png",
			"role_name": "Fireteam Leader",
			"team_id": "team_alpha",
			"skill_leadership": 0.88,
		},
	]
	var mission_setup := mission.get_node("MissionSetup")
	mission_setup.set("selected_team_unit_ids", selected_unit_ids)
	mission_setup.set("selected_team_fireteam_ids", selected_fireteam_ids)
	mission_setup.set("selected_team_unit_configs", unit_configs)
	mission_setup.set("selected_fireteam_definitions", fireteam_definitions)
	mission_setup.set("member_loadouts", member_loadouts)
	mission_setup.set("defer_friendly_runtime_activation", false)
	mission_setup.set("allow_full_roster_when_selection_empty", false)
	root.add_child(mission)
	await _wait_frames(18)

	var tactical_controller: Node = mission.get_node("TacticalController")
	tactical_controller.call("_set_selected_fireteams", PackedStringArray(["ft1"]), false)
	await _wait_frames(4)

	var units: Array = Array(tactical_controller.call("_get_fireteam_units", "ft1", true))
	var unit_ids: PackedStringArray = _collect_unit_ids(units)
	var display_names: PackedStringArray = _collect_display_names(units)
	var leader = tactical_controller.call("_resolve_fireteam_leader_for_behavior", "ft1")
	_assert(_same_members(unit_ids, selected_unit_ids), "Mission fireteam members mirror the FOB Fireteam 1 assignment")
	_assert(display_names.has("FOB Mira Acht") and display_names.has("FOB Theo Zwoelf"), "Mission cards use FOB roster names instead of generic ID fallback names")
	_assert(leader != null and String(leader.call("get_unit_id")) == "player_sternenbuergerchen_12", "Mission lead is resolved from the FOB Fireteam lead")
	_assert(leader != null and String(leader.call("get_display_name")) == "FOB Theo Zwoelf", "Mission lead portrait/name source is the FOB roster profile")

	var selected_cards_row := mission.get_node("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow") as HBoxContainer
	var selected_card_ids: PackedStringArray = PackedStringArray()
	var selected_card_names: PackedStringArray = PackedStringArray()
	for child in selected_cards_row.get_children():
		if not child.has_method("get_unit_id") or not child.has_method("get_profile"):
			continue
		selected_card_ids.append(String(child.call("get_unit_id")))
		var profile = child.call("get_profile")
		selected_card_names.append(String(profile.display_name))
	_assert(_same_members(selected_card_ids, selected_unit_ids), "#17 SELECTED FIRETEAM shows the actual FOB Fireteam 1 members")
	_assert(selected_card_names.has("FOB Mira Acht") and selected_card_names.has("FOB Theo Zwoelf"), "#17 member cards render FOB identity profiles")

	var mini_card := mission.get_node("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox").get_child(0) as Control
	var mini_member_label := mini_card.get_node("Margin/VBox/MemberLabel") as Label
	var portrait_rect := mini_card.get_node("Margin/VBox/HeaderRow/LeaderPortraitRect") as TextureRect
	_assert(mini_member_label.text.contains("Lead FOB Theo Zwoelf"), "Fireteam mini-card names the configured FOB lead")
	_assert(portrait_rect != null and portrait_rect.texture != null, "Fireteam mini-card renders the configured lead portrait")

	mission.queue_free()
	await _wait_frames(3)


func _test_hud_bubbles_are_compact_and_do_not_overlap() -> void:
	var map_data: RefCounted = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "bugfix_hud_bubbles", Vector2i(4, 4), Vector2.ZERO, 64.0, 32.0, 2)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	var first_bubble: Dictionary = _make_hud_bubble("ft1", "bubble_ftl_ack", "Okay.\nLos.", Vector2(220.0, 120.0))
	var second_bubble: Dictionary = _make_hud_bubble("ft2", "bubble_ftl_warning", "Warte.\nBlockiert.", Vector2(220.0, 120.0))
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"feedback_bubble_dicts": [first_bubble, second_bubble],
	})
	await _wait_frames(8)

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("feedback_bubble_entries", []))
	_assert(entries.size() == 2, "HUD renderer keeps both readable feedback bubbles")
	var first_entry: Dictionary = Dictionary(entries[0])
	var second_entry: Dictionary = Dictionary(entries[1])
	var first_size: Vector2 = Vector2(first_entry.get("hud_bubble_size", Vector2.ZERO))
	var second_size: Vector2 = Vector2(second_entry.get("hud_bubble_size", Vector2.ZERO))
	var first_position: Vector2 = Vector2(first_entry.get("hud_bubble_position", Vector2.ZERO))
	var second_position: Vector2 = Vector2(second_entry.get("hud_bubble_position", Vector2.ZERO))
	_assert(first_size.x <= 160.0 and first_size.y <= 60.0 and second_size.x <= 160.0 and second_size.y <= 60.0, "HUD bubbles use the smaller manual-playtest size")
	_assert(not Rect2(first_position, first_size).grow(3.0).intersects(Rect2(second_position, second_size).grow(3.0)), "HUD bubbles are vertically separated instead of stacked on top of each other")
	_assert(first_position.x >= Vector2(first_entry.get("hud_anchor_position", Vector2.ZERO)).x, "HUD bubble is placed to the right of the fireteam-card anchor")

	primary_view.queue_free()
	await _wait_frames(3)


func _make_hud_bubble(fireteam_id: String, bubble_id: String, text: String, hud_anchor_position: Vector2) -> Dictionary:
	return {
		"display_type": "comic_bubble",
		"visual_only": true,
		"bubble_id": bubble_id,
		"text": text,
		"fireteam_id": fireteam_id,
		"unit_id": "%s_lead" % fireteam_id,
		"feedback_action": "move",
		"feedback_state": "accepted",
		"source": "bugfix_test",
		"anchor_position": Vector2.ZERO,
		"anchor_space": "hud",
		"hud_anchor_source": "fireteam_mini_card",
		"hud_anchor_position": hud_anchor_position,
		"max_size": Vector2i(148, 52),
	}


func _collect_unit_ids(units: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for unit in units:
		if unit != null and unit.has_method("get_unit_id"):
			result.append(String(unit.call("get_unit_id")))
	return result


func _collect_display_names(units: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for unit in units:
		if unit != null and unit.has_method("get_display_name"):
			result.append(String(unit.call("get_display_name")))
	return result


func _same_members(left: PackedStringArray, right: PackedStringArray) -> bool:
	if left.size() != right.size():
		return false
	for value in left:
		if not right.has(value):
			return false
	return true


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
