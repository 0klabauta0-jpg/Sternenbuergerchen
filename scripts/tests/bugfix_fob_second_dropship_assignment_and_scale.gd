extends SceneTree

const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== FOB Second Dropship Assignment and Scale Bugfix ===")
	await _test_fireteams_stage_to_the_dropped_craft()
	await _test_fireteam_membership_lookup_ignores_removed_definition()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_fireteams_stage_to_the_dropped_craft() -> void:
	var screen: Control = FOB_TEST_SCENE.instantiate()
	screen.visible = true
	root.add_child(screen)
	await _wait_frames(4)

	screen.call("set_available_units", _build_units())
	screen.call(
		"configure_transfer",
		PackedStringArray(["unit_a", "unit_b", "unit_c", "unit_d", "unit_e", "unit_f", "unit_g", "unit_h"]),
		PackedStringArray(["ft1", "ft1", "ft1", "ft1", "ft2", "ft2", "ft2", "ft2"]),
		[
			{"id": "ft1", "label": "FT1", "lead_unit_id": "unit_a"},
			{"id": "ft2", "label": "FT2", "lead_unit_id": "unit_e"},
		]
	)
	screen.call("set_transport_craft_state", [
		{
			"craft_id": "dropship_1",
			"display_name": "Dropship 1",
			"visible_in_fob": true,
			"is_boardable": true,
			"pilot_unit_id": "",
		},
		{
			"craft_id": "dropship_2",
			"display_name": "Dropship 2",
			"visible_in_fob": true,
			"is_boardable": true,
			"pilot_unit_id": "",
		},
	])
	await _wait_frames(4)

	screen.call("_on_staging_fireteam_dropped", "ft1", "dropship|dropship_1")
	await _wait_frames(2)
	var dropship_1_boarding_snapshot: Dictionary = Dictionary(screen.call("get_flightdeck_snapshot"))
	var dropship_1_boarding_state: Dictionary = Dictionary(Dictionary(dropship_1_boarding_snapshot.get("dropship_state_by_craft", {})).get("dropship_1", {}))
	_assert(String(dropship_1_boarding_state.get("phase", "")) == "boarding", "Dropship 1 starts boarding FT1")
	screen.call("_on_staging_fireteam_dropped", "ft2", "dropship|dropship_2")
	await _wait_frames(4)

	var snapshot: Dictionary = Dictionary(screen.call("get_flightdeck_snapshot"))
	var state_by_craft: Dictionary = Dictionary(snapshot.get("dropship_state_by_craft", {}))
	var dropship_1_state: Dictionary = Dictionary(state_by_craft.get("dropship_1", {}))
	var dropship_2_state: Dictionary = Dictionary(state_by_craft.get("dropship_2", {}))
	var dropship_1_seconds_before_tick: float = float(dropship_1_state.get("boarding_seconds", 0.0))
	var dropship_2_seconds_before_tick: float = float(dropship_2_state.get("boarding_seconds", 0.0))
	var drop_state: Dictionary = Dictionary(screen.call("build_mission_drop_state"))
	_assert(String(snapshot.get("selected_craft_id", "")) == "dropship_2", "Dropping onto Dropship 2 selects Dropship 2")
	_assert(Array(dropship_1_state.get("staged_fireteam_ids", [])).has("ft1"), "Dropship 1 keeps FT1 in its own queue")
	_assert(not Array(dropship_1_state.get("staged_fireteam_ids", [])).has("ft2"), "Dropship 1 does not steal FT2")
	_assert(Array(dropship_2_state.get("staged_fireteam_ids", [])).has("ft2"), "Dropship 2 receives FT2")
	_assert(not Array(dropship_2_state.get("staged_fireteam_ids", [])).has("ft1"), "Dropship 2 does not inherit FT1")
	_assert(String(dropship_1_state.get("phase", "")) == "boarding", "Dropship 1 keeps boarding after Dropship 2 is selected")
	_assert(String(dropship_2_state.get("phase", "")) == "boarding", "Dropship 2 can board alongside Dropship 1")
	screen.call("_on_dropship_timer_timeout")
	await _wait_frames(2)
	var tick_snapshot: Dictionary = Dictionary(screen.call("get_flightdeck_snapshot"))
	var tick_states: Dictionary = Dictionary(tick_snapshot.get("dropship_state_by_craft", {}))
	var dropship_1_tick_state: Dictionary = Dictionary(tick_states.get("dropship_1", {}))
	var dropship_2_tick_state: Dictionary = Dictionary(tick_states.get("dropship_2", {}))
	_assert(String(tick_snapshot.get("selected_craft_id", "")) == "dropship_2", "Dropship timer keeps the selected craft stable while ticking every craft")
	_assert(float(dropship_1_tick_state.get("boarding_seconds", 0.0)) < dropship_1_seconds_before_tick, "Dropship 1 boarding timer keeps ticking while Dropship 2 is selected")
	_assert(float(dropship_2_tick_state.get("boarding_seconds", 0.0)) < dropship_2_seconds_before_tick, "Dropship 2 boarding timer ticks independently")
	_assert(String(drop_state.get("transport_craft_id", "")) == "dropship_2", "Mission drop state points at the currently selected craft")
	_assert(Array(drop_state.get("queued_fireteam_ids", [])).has("ft2") and not Array(drop_state.get("queued_fireteam_ids", [])).has("ft1"), "Mission drop queue mirrors Dropship 2, not Dropship 1")
	_assert(not _fireteam_list_contains(screen, "ft1") and not _fireteam_list_contains(screen, "ft2"), "#10 hides fireteams staged in any dropship")

	var dropship_2_card: Control = _find_craft_card(screen, "dropship_2")
	var ship_texture: TextureRect = null
	if dropship_2_card != null:
		ship_texture = dropship_2_card.get_node_or_null("MarginContainer/VBox/ContentRow/ShipTexture") as TextureRect
	_assert(dropship_2_card != null and String(dropship_2_card.get("drop_kind")) == "dropship|dropship_2", "Dropship 2 card owns a dedicated drop target")
	_assert(ship_texture != null and ship_texture.custom_minimum_size.x >= 176.0 and ship_texture.custom_minimum_size.y >= 104.0, "FOB shipcard renders a larger dropship texture target")
	_assert(ship_texture != null and ship_texture.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "FOB shipcard crops transparent padding instead of centering a tiny sprite")

	screen.call("_on_transport_craft_selected", "dropship_1")
	await _wait_frames(2)
	var selected_back_state: Dictionary = Dictionary(screen.call("build_mission_drop_state"))
	_assert(String(selected_back_state.get("transport_craft_id", "")) == "dropship_1", "Selecting Dropship 1 restores its stored queue")
	_assert(Array(selected_back_state.get("queued_fireteam_ids", [])).has("ft1") and not Array(selected_back_state.get("queued_fireteam_ids", [])).has("ft2"), "Dropship 1 queue remains separate after switching back")

	screen.queue_free()
	await _wait_frames(2)

func _test_fireteam_membership_lookup_ignores_removed_definition() -> void:
	var screen: Control = FOB_TEST_SCENE.instantiate()
	screen.visible = true
	root.add_child(screen)
	await _wait_frames(4)

	screen.call("set_available_units", _build_units())
	screen.call(
		"configure_transfer",
		PackedStringArray(["unit_a", "unit_e"]),
		PackedStringArray(["ft1", "ft2"]),
		[
			{"id": "ft1", "label": "FT1", "lead_unit_id": "unit_a"},
			{"id": "ft2", "label": "FT2", "lead_unit_id": "unit_e"},
		]
	)
	await _wait_frames(2)

	screen.set("_fireteam_definitions", [{"id": "ft1", "label": "FT1", "lead_unit_id": "unit_a"}])
	screen.set("_selected_fireteam_ids", PackedStringArray(["ft1", "ft2"]))
	var stale_members := PackedStringArray(screen.call("_get_member_unit_ids_for_fireteam", "ft2"))
	var assignments: Dictionary = Dictionary(screen.call("_build_assignment_lookup"))
	_assert(stale_members.is_empty(), "Deleted fireteam definitions do not keep stale parallel-array members")
	_assert(String(assignments.get("unit_e", "")) == "", "Assignment lookup clears fireteam IDs without a live definition")

	screen.queue_free()
	await _wait_frames(2)



func _build_units() -> Array:
	return [
		{"unit_id": "unit_a", "display_name": "Anja"},
		{"unit_id": "unit_b", "display_name": "Bero"},
		{"unit_id": "unit_c", "display_name": "Cora"},
		{"unit_id": "unit_d", "display_name": "Dima"},
		{"unit_id": "unit_e", "display_name": "Edda"},
		{"unit_id": "unit_f", "display_name": "Faro"},
		{"unit_id": "unit_g", "display_name": "Gina"},
		{"unit_id": "unit_h", "display_name": "Hale"},
	]


func _find_craft_card(screen: Control, craft_id: String) -> Control:
	var container := screen.get_node_or_null(_dropship_queue_list_path()) as VBoxContainer
	if container == null:
		return null
	for child in container.get_children():
		var control := child as Control
		if control != null and String(control.get_meta("transport_craft_id", "")) == craft_id:
			return control
	return null


func _fireteam_list_contains(screen: Control, fireteam_id: String) -> bool:
	var container := screen.get_node_or_null(_fireteam_list_path()) as VBoxContainer
	if container == null:
		return false
	for child in container.get_children():
		if child.has_method("get_fireteam_id") and String(child.call("get_fireteam_id")) == fireteam_id:
			return true
	return false


func _fireteam_list_path() -> String:
	return "Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll/FireteamList"


func _dropship_queue_list_path() -> String:
	return "Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipQueueScroll/DropshipQueueList"


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
