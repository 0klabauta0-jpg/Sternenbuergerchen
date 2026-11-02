extends SceneTree

# Real source-viewport captures. Never substitute a generated or painted board.
const OUTPUT_DIR := "res://docs/qa/ui_native_r1_20261101/captures"
var _view := "main_menu"
var _window_size := Vector2i(1920, 1080)
var _logical_size := Vector2i(1920, 1080)
var _output_dir := OUTPUT_DIR
var _fixture_scope := "ui_native_r1_capture"
var _fixture_variant := "standard"

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--view="):
			_view = arg.trim_prefix("--view=")
		if arg.begins_with("--size="):
			var pieces := arg.trim_prefix("--size=").split("x")
			_window_size = Vector2i(int(pieces[0]), int(pieces[1]))
		if arg.begins_with("--logical-size="):
			var pieces := arg.trim_prefix("--logical-size=").split("x")
			_logical_size = Vector2i(int(pieces[0]), int(pieces[1]))
		if arg.begins_with("--output="):
			_output_dir = arg.trim_prefix("--output=")
		if arg.begins_with("--fixture-scope="):
			_fixture_scope = arg.trim_prefix("--fixture-scope=")
		if arg.begins_with("--variant="):
			_fixture_variant = arg.trim_prefix("--variant=")
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Native capture requires a real renderer; no fallback image is allowed.")
		quit(1)
		return
	root.size = _window_size
	root.content_scale_size = _logical_size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var scene: Node
	match _view:
		"main_menu", "settings", "teameditor", "escape":
			scene = load("res://scenes/ui/main_menu.tscn").instantiate()
		"lobby":
			scene = load("res://scenes/ui/multiplayer_lobby.tscn").instantiate()
		"homebase":
			scene = load("res://scenes/meta/homebase_test_screen.tscn" if _fixture_variant == "teams" else "res://scenes/meta/meta_layer_test.tscn").instantiate()
		"fob":
			scene = load("res://scenes/meta/fob_test_screen.tscn").instantiate()
		"debrief":
			scene = load("res://scenes/meta/debrief_test_screen.tscn").instantiate()
		"editor":
			scene = load("res://scenes/editor/map_editor.tscn").instantiate()
		"mission":
			scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
		"characters":
			scene = _build_character_fixture()
		_:
			push_error("Unknown capture view: " + _view)
			quit(1)
			return
	if _view in ["main_menu", "settings", "teameditor", "escape"]:
		# Keep capture-generated rosters/settings in a separate test slot.
		scene.set("_start_roster_profile_id", _fixture_scope)
		scene.set("_start_roster_save_path", "user://%s_roster.cfg" % _fixture_scope)
		scene.set("_settings_config_path", "user://%s_settings.cfg" % _fixture_scope)
	root.add_child(scene)
	current_scene = scene
	if scene is Control:
		(scene as Control).show()
	Input.warp_mouse(Vector2(2, 2))
	for _frame in range(12):
		await process_frame
	match _view:
		"settings":
			scene.call("open_settings_panel")
		"teameditor":
			scene.call("ensure_start_roster_exists", "native-ui-r1-capture", 24)
			scene.call("open_team_editor")
		"escape":
			root.get_node("GlobalEscapeMenu").call("open_menu")
		"homebase":
			if _fixture_variant == "teams":
				var generator: GDScript = load("res://scripts/meta/start_roster_generator.gd")
				var roster: Dictionary = generator.call("generate_start_roster", "native-ui-r3-homebase", 24)
				var units: Array = roster.units.slice(0, 6)
				var ids := PackedStringArray()
				for unit: Dictionary in units:
					ids.append(String(unit.unit_id))
				scene.call("setup_roster", units, PackedStringArray(ids.slice(0, 3)))
				scene.call("set_fireteam_context", PackedStringArray(["ft1", "ft1", "ft1"]), [{"id": "ft1", "label": "ALPHA", "lead_unit_id": ids[0]}])
		"fob":
			var generator: GDScript = load("res://scripts/meta/start_roster_generator.gd")
			var roster: Dictionary = generator.call("generate_start_roster", "native-ui-r1-fob", 24)
			var units: Array = roster.units.slice(0, 6)
			var ids := PackedStringArray()
			for unit: Dictionary in units:
				ids.append(String(unit.unit_id))
			scene.call("set_available_units", units)
			scene.call("configure_transfer", ids, PackedStringArray(["ft1", "ft1", "", "", "", ""]), [{"id": "ft1", "label": "ALPHA", "lead_unit_id": ids[0], "member_unit_ids": PackedStringArray([ids[0], ids[1]])}])
			scene.call("_on_staging_fireteam_dropped", "ft1", "loadout")
			if _fixture_variant == "populated":
				var pilot_id := ""
				for unit: Dictionary in units:
					if String(unit.get("roster_role_category", "")) == "pilot":
						pilot_id = String(unit.unit_id)
						break
				scene.call("set_transport_craft_state", [{"craft_id": "r3_capture_ship", "craft_type": "dropship", "display_name": "Dropship 1", "visible_in_fob": true, "is_boardable": true, "is_in_transit": false, "pilot_unit_id": pilot_id}])
		"debrief":
			scene.call("set_mission_result", _debrief_fixture())
	root.size = _window_size
	# Re-establish a neutral pointer after opening/repositioning native panels.
	# This also clears a tooltip armed by the underlying menu during startup.
	Input.warp_mouse(Vector2(2, 2))
	var neutral_motion := InputEventMouseMotion.new()
	neutral_motion.position = Vector2(2, 2)
	neutral_motion.global_position = Vector2(2, 2)
	root.push_input(neutral_motion, true)
	for _frame in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	var capture := root.get_texture().get_image()
	if capture == null or capture.is_empty():
		push_error("Renderer produced no viewport image.")
		quit(1)
		return
	var varied := false
	var first_pixel := capture.get_pixel(0, 0)
	for y in range(0, capture.get_height(), maxi(1, capture.get_height() / 24)):
		for x in range(0, capture.get_width(), maxi(1, capture.get_width() / 24)):
			if not capture.get_pixel(x, y).is_equal_approx(first_pixel):
				varied = true
	if not varied:
		push_error("Capture is an empty uniform viewport; hidden fixture is not visual evidence.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output_dir))
	var variant_suffix := "" if _fixture_variant == "standard" else "_" + _fixture_variant
	var basename := "%s%s_%dx%d" % [_view, variant_suffix, _window_size.x, _window_size.y]
	var image_path := _output_dir.path_join(basename + ".png")
	var error := capture.save_png(image_path)
	var evidence := {
		"view": _view,
		"image": image_path,
		"source_capture": true,
		"synthetic_image_fallback": false,
		"fixture_data": true,
		"fixture_variant": _fixture_variant,
		"display_driver": DisplayServer.get_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"image_size": [capture.get_width(), capture.get_height()],
		"requested_window_size": [_window_size.x, _window_size.y],
		"logical_size": [_logical_size.x, _logical_size.y],
		"scaled_capture": _logical_size != _window_size,
		"viewport_size": [root.get_visible_rect().size.x, root.get_visible_rect().size.y],
		"save_error": error,
		"note": "Real native controls/source scene; test fixture and example data, no human usability acceptance.",
		"ui_metrics": _capture_ui_metrics(scene),
	}
	if _view == "debrief":
		var result: Dictionary = scene.call("get_mission_result")
		evidence["fixture_summary"] = {
			"person_count": Array(result.get("team_states", [])).size(),
			"has_aar": not Dictionary(result.get("mini_aar_debrief", {})).is_empty(),
			"award_applied": bool(Dictionary(result.get("progression_award_summary", {})).get("award_applied", false)),
		}
	var file := FileAccess.open(_output_dir.path_join(basename + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence, "\t") + "\n")
	file.close()
	print("CAPTURE: " + JSON.stringify(evidence))
	scene.queue_free()
	for _frame in range(3):
		await process_frame
	quit(0 if error == OK else 1)

func _capture_ui_metrics(scene: Node) -> Dictionary:
	var host := scene
	var paths: Dictionary = {}
	match _view:
		"homebase":
			if _fixture_variant != "teams":
				host = scene.get_node_or_null("HomebaseScreen")
			paths = {"briefing": "Panel/Margin/VBox/MissionPanel", "teams": "Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel", "flightdeck": "Panel/Margin/VBox/ContentRow/AircraftPanel"}
		"fob":
			paths = {"teams": "Panel/Margin/VBox/ContentRow/FireteamPanel", "loadout": "Panel/Margin/VBox/ContentRow/StagingPanel", "flightdeck": "Panel/Margin/VBox/ContentRow/DropshipPanel", "boarding": "Panel/Margin/VBox/DropLightBottomRow/BoardingStatusPanel"}
		"debrief":
			paths = {"window": "Panel", "return_card": "Panel/Margin/VBox/NativeReviewLayout/ReturnCard", "return_row": "Panel/Margin/VBox/ButtonRow", "return_slot": "Panel/Margin/VBox/NativeReviewLayout/ReturnCard/Contents/ButtonRowSlot"}
		"mission":
			paths = {"objective": "TacticalUI/MissionIdentityPanel", "transport": "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel"}
	var metrics := {}
	if host != null:
		for key in paths:
			var control := host.get_node_or_null(NodePath(paths[key])) as Control
			if control != null:
				var rect := control.get_global_rect()
				metrics[key] = {"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "visible": control.is_visible_in_tree()}
	return metrics

func _build_character_fixture() -> Control:
	var theme_script: GDScript = load("res://scripts/ui/tactical_ui_theme.gd")
	var generator: GDScript = load("res://scripts/meta/start_roster_generator.gd")
	var card_scene: PackedScene = load("res://scenes/meta/components/npc_compact_card.tscn")
	var sheet: GDScript = load("res://scripts/meta/character_sheet_view.gd")
	var profile_script: GDScript = load("res://scripts/meta/meta_unit_profile.gd")
	var profiles: Array = generator.call("generate_start_roster", "native-ui-r1-characters", 24).get("units", [])
	var panel := PanelContainer.new()
	panel.name = "NativeCharacterFixture"
	panel.position = Vector2(64, 48)
	panel.size = Vector2(1792, 984)
	theme_script.call("apply_screen", panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	var cards := VBoxContainer.new()
	cards.custom_minimum_size.x = 300
	row.add_child(cards)
	var heading := Label.new()
	heading.text = "Einsatzkräfte · kompakte Karten"
	cards.add_child(heading)
	for index in range(7):
		var card := card_scene.instantiate()
		cards.add_child(card)
		card.call("setup_from_profile", profiles[index], {"selected": index == 0, "compact_mode": true, "fixed_size": false, "show_progress": index == 2, "progress_value": 0.6})
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(scroll)
	var host := VBoxContainer.new()
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(host)
	sheet.call("render", host, profile_script.new(profiles[0]), {"editable_metrics": false, "two_column_layout": true, "hide_loadout_dropdowns": true})
	return panel

func _debrief_fixture() -> Dictionary:
	if _fixture_variant == "empty":
		return {}
	if _fixture_variant == "partial":
		return {"result": "victory"}
	if _fixture_variant == "rich":
		# Pure stress fixture from the dedicated UI verifier. Loading its script
		# does not instantiate a SceneTree or run the test harness.
		var fixtures: Object = load("res://scripts/tests/ui_native_r3_debrief_verifier.gd")
		return Dictionary(fixtures.call("build_fixture", "rich"))
	return {
		"winning_team_id": "team_alpha", "mission_outcome": "completed", "result": "victory",
		"win_condition_type": "objective_capture", "objective_captured": true, "duration_seconds": 185.0,
		"team_states": [
			{"unit_id": "leader", "display_name": "Mara", "fireteam_id": "alpha", "vital_state": "fit", "health_points": 100},
			{"unit_id": "rifle", "display_name": "Jona", "fireteam_id": "alpha", "vital_state": "fit", "health_points": 88},
			{"unit_id": "medic", "display_name": "Nils", "fireteam_id": "alpha", "vital_state": "wounded", "health_points": 42},
		],
		"fireteam_tactical_debrief": [{"fireteam_id": "alpha", "reaction_delay_seconds": 0.42, "plan_quality": 0.76, "tempo_modifier": 1.08, "contact_report_count": 3, "contact_report_quality": 0.72, "morale": 0.68, "frustration": 0.22}],
	}
