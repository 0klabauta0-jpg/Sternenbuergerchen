extends SceneTree

const DEV_MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_fireteam_dev_test.tscn")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Fireteam Dev Testing Verifier ===")
	_test_nearest_walkable_grid_skips_rocks()
	await _test_unit_world_events_only_show_critical_text()
	await _test_direct_dev_mission_starts_with_active_fireteams_and_editor()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_nearest_walkable_grid_skips_rocks() -> void:
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	registry.register_tile(_make_tile(registry, Vector2i(0, 0), true, "ground_flat"))
	registry.register_tile(_make_tile(registry, Vector2i(1, 0), false, "rock_large"))
	registry.register_tile(_make_tile(registry, Vector2i(2, 0), true, "ground_flat"))
	var rock_world: Vector2 = registry.grid_to_world(Vector2i(1, 0))
	var nearest: Variant = registry.call("get_nearest_walkable_grid", rock_world)
	_assert(typeof(nearest) == TYPE_VECTOR2I, "TerrainRegistry returns a walkable replacement grid for rock targets")
	_assert(nearest != Vector2i(1, 0), "Nearest walkable replacement never points back to the rock tile")


func _test_unit_world_events_only_show_critical_text() -> void:
	var unit = TEST_UNIT_SCRIPT.new()
	get_root().add_child(unit)
	await process_frame
	unit.call("show_event_text", "HIT -3")
	_assert(String(unit.get("_current_event_text")).is_empty(), "Routine hit popups stay off the unit")
	unit.call("show_event_text", "FEUERSTOPP GEBROCHEN!")
	_assert(String(unit.get("_current_event_text")) == "FEUERSTOPP GEBROCHEN!", "Critical fire-discipline popup remains visible over the unit")
	unit.queue_free()


func _test_direct_dev_mission_starts_with_active_fireteams_and_editor() -> void:
	var scene = DEV_MISSION_SCENE.instantiate()
	get_root().add_child(scene)
	await process_frame
	await process_frame

	var mission_setup = scene.get_node_or_null("MissionSetup")
	_assert(mission_setup != null and not bool(mission_setup.get("defer_friendly_runtime_activation")), "Direct dev mission skips deferred dropship activation")

	var unit_registry = scene.get_node_or_null("UnitRegistry")
	var units: Array = unit_registry.call("get_all_units") if unit_registry != null else []
	var friendly_id: String = ""
	for unit in units:
		if unit != null and unit.has_method("get_team_id") and String(unit.call("get_team_id")) == "team_alpha":
			friendly_id = String(unit.call("get_unit_id"))
			break
	_assert(not friendly_id.is_empty(), "Direct dev mission starts with active friendly fireteam units")

	var controller = scene.get_node_or_null("TacticalController")
	if controller != null and not friendly_id.is_empty():
		controller.call("_open_character_overlay", friendly_id)
		await process_frame
	var dev_panel = scene.get_node_or_null("TacticalUI/CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll/OverlayContentVBox/DevStatsPanel")
	_assert(dev_panel != null, "Mission character sheet exposes DEV-WERTE sliders")
	if controller != null:
		var gold_card = _find_fireteam_mini_card(scene, "gold")
		var had_gold_card: bool = gold_card != null
		var gold_card_center := Vector2.ZERO
		var click_event := InputEventMouseButton.new()
		click_event.button_index = MOUSE_BUTTON_LEFT
		click_event.pressed = true
		if had_gold_card:
			var primary_action := gold_card.get_node_or_null("MarginContainer/VBox/HeaderRow/PrimaryActionButton") as Button
			_assert(primary_action == null or not primary_action.visible, "Fireteam mini-card hides redundant Select button")
			gold_card_center = gold_card.get_global_rect().get_center()
			click_event.position = gold_card_center
			controller.call("_begin_selection_interaction", gold_card_center, false)
			gold_card.emit_signal("gui_input", click_event)
			await process_frame
			var release_event := InputEventMouseButton.new()
			release_event.button_index = MOUSE_BUTTON_LEFT
			release_event.pressed = false
			release_event.position = gold_card_center
			controller.call("_unhandled_input", release_event)
			await process_frame
		var selected_fireteams: PackedStringArray = controller.call("get_selected_fireteam_ids")
		_assert(had_gold_card and selected_fireteams.size() == 1 and String(selected_fireteams[0]) == "gold", "Gold fireteam mini-card keeps Fireteam Gold selected after mouse release")

	scene.queue_free()
	await process_frame


func _find_fireteam_mini_card(scene: Node, fireteam_id: String) -> Control:
	var host = scene.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox")
	if host == null:
		return null
	for child in host.get_children():
		if child is Control and String(child.get_meta("fireteam_id", "")).strip_edges().to_lower() == fireteam_id:
			return child as Control
	return null


func _make_tile(registry, grid_position: Vector2i, walkable: bool, type_id: String):
	return TERRAIN_TILE_DATA_SCRIPT.new(
		{
			"tile_id": "%d_%d" % [grid_position.x, grid_position.y],
			"type_id": type_id,
			"grid_position": grid_position,
			"world_position": registry.grid_to_world(grid_position),
			"walkable": walkable,
			"surface_type": "rock" if not walkable else "ground",
		}
	)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("  FAIL: %s" % message)
