extends RefCounted

const ENEMY_TEAM_TACTICS_PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")
const DEFAULT_SCENARIO_DIR: String = "res://data/mission_scenarios"
const SCENARIO_POSITION_META: String = "__position__"

var _host: Node = null


func setup(host_node: Node) -> void:
	_host = host_node


func ensure_controls() -> void:
	if _host == null:
		return
	var panel_parent := _host.get_node_or_null("UI/PropertyPanel/Margin/VBox") as VBoxContainer
	var ui_root := _host.get_node_or_null("UI") as CanvasLayer
	if panel_parent == null or ui_root == null:
		return

	var scenario_panel := panel_parent.get_node_or_null("MissionScenarioPanel") as VBoxContainer
	if scenario_panel == null:
		var separator := HSeparator.new()
		separator.name = "MissionScenarioSeparator"
		panel_parent.add_child(separator)

		scenario_panel = VBoxContainer.new()
		scenario_panel.name = "MissionScenarioPanel"
		scenario_panel.add_theme_constant_override("separation", 5)
		panel_parent.add_child(scenario_panel)
		var marker_panel := panel_parent.get_node_or_null("MarkerEditorPanel") as VBoxContainer
		if marker_panel != null:
			panel_parent.move_child(separator, marker_panel.get_index())
			panel_parent.move_child(scenario_panel, marker_panel.get_index())

		var title_label := Label.new()
		title_label.name = "ScenarioTitleLabel"
		title_label.text = "Mission Scenario"
		scenario_panel.add_child(title_label)

		var toolbar := HBoxContainer.new()
		toolbar.name = "ScenarioToolbarRow"
		toolbar.add_theme_constant_override("separation", 4)
		scenario_panel.add_child(toolbar)

		var load_button := Button.new()
		load_button.name = "ScenarioLoadButton"
		load_button.text = "Load"
		toolbar.add_child(load_button)

		var save_button := Button.new()
		save_button.name = "ScenarioSaveButton"
		save_button.text = "Save"
		toolbar.add_child(save_button)

		var save_as_button := Button.new()
		save_as_button.name = "ScenarioSaveAsButton"
		save_as_button.text = "Save As"
		toolbar.add_child(save_as_button)

		var live_test_button := Button.new()
		live_test_button.name = "ScenarioLiveTestButton"
		live_test_button.text = "Live Test"
		toolbar.add_child(live_test_button)

		var path_label := Label.new()
		path_label.name = "ScenarioPathLabel"
		path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		scenario_panel.add_child(path_label)

		var map_label := Label.new()
		map_label.name = "ScenarioMapLabel"
		map_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		scenario_panel.add_child(map_label)

		_add_line_edit_row(scenario_panel, "ScenarioIdRow", "ID:", "ScenarioIdLineEdit")
		_add_line_edit_row(scenario_panel, "ScenarioNameRow", "Name:", "ScenarioNameLineEdit")
		_add_option_row(scenario_panel, "ScenarioObjectiveRow", "Obj:", "ScenarioObjectiveOption", "ScenarioObjectiveTileButton", "Use Tile")
		_add_spinbox_row(scenario_panel, "ScenarioCaptureRadiusRow", "Radius:", "ScenarioCaptureRadiusSpinBox", 1.0, 1000.0, 1.0)
		_add_spinbox_row(scenario_panel, "ScenarioTimeLimitRow", "Time:", "ScenarioTimeLimitSpinBox", 0.0, 7200.0, 30.0)
		_add_line_edit_row(scenario_panel, "ScenarioEnemyIdsRow", "Enemies:", "ScenarioEnemyIdsLineEdit")
		_add_option_row(scenario_panel, "ScenarioSpawnRow", "Spawn:", "ScenarioSpawnOption", "ScenarioSpawnTileButton", "Use Tile")
		_add_select_row(scenario_panel, "ScenarioEnemyTacticProfileRow", "Tactic:", "ScenarioEnemyTacticProfileOption")
		_add_select_row(scenario_panel, "ScenarioEnemySecurityModeRow", "Security:", "ScenarioEnemySecurityModeOption")
		_add_select_row(scenario_panel, "ScenarioEnemyFacingRow", "Facing:", "ScenarioEnemyFacingOption")
		_add_select_row(scenario_panel, "ScenarioEnemyHeavyRoleRow", "Heavy:", "ScenarioEnemyHeavyRoleOption")
		_add_select_row(scenario_panel, "ScenarioEnemyATWeaponRow", "AT Wpn:", "ScenarioEnemyATWeaponOption")
		_add_select_row(scenario_panel, "ScenarioAirAssetRiskRow", "AirRisk:", "ScenarioAirAssetRiskOption")
		_add_select_row(scenario_panel, "ScenarioLZThreatZoneRow", "LZ Risk:", "ScenarioLZThreatZoneOption")
		_add_select_row(scenario_panel, "ScenarioCommIntensityRow", "Comms:", "ScenarioCommIntensityOption")
		_add_spinbox_row(scenario_panel, "ScenarioWaveCountRow", "Waves:", "ScenarioWaveCountSpinBox", 0.0, 20.0, 1.0)
		_add_spinbox_row(scenario_panel, "ScenarioUnitsPerWaveRow", "Per Wave:", "ScenarioUnitsPerWaveSpinBox", 1.0, 20.0, 1.0)
		_add_spinbox_row(scenario_panel, "ScenarioFirstWaveDelayRow", "First:", "ScenarioFirstWaveDelaySpinBox", 0.0, 900.0, 1.0)
		_add_spinbox_row(scenario_panel, "ScenarioWaveDelayRow", "Delay:", "ScenarioWaveDelaySpinBox", 0.0, 1800.0, 1.0)

		var patrol_row := HBoxContainer.new()
		patrol_row.name = "ScenarioPatrolBindingsRow"
		patrol_row.add_theme_constant_override("separation", 4)
		scenario_panel.add_child(patrol_row)
		var patrol_label := Label.new()
		patrol_label.text = "Patrol:"
		patrol_row.add_child(patrol_label)
		var patrol_line_edit := LineEdit.new()
		patrol_line_edit.name = "ScenarioPatrolBindingsLineEdit"
		patrol_line_edit.placeholder_text = "enemy_delta:enemy_delta"
		patrol_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		patrol_row.add_child(patrol_line_edit)
		var auto_bind_button := Button.new()
		auto_bind_button.name = "ScenarioAutoBindButton"
		auto_bind_button.text = "Auto"
		patrol_row.add_child(auto_bind_button)

		var info_label := Label.new()
		info_label.name = "ScenarioInfoLabel"
		info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		scenario_panel.add_child(info_label)

	var load_dialog := ui_root.get_node_or_null("ScenarioLoadDialog") as FileDialog
	if load_dialog == null:
		load_dialog = FileDialog.new()
		load_dialog.name = "ScenarioLoadDialog"
		load_dialog.title = "Load Mission Scenario"
		load_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		load_dialog.access = FileDialog.ACCESS_RESOURCES
		load_dialog.current_dir = DEFAULT_SCENARIO_DIR
		load_dialog.filters = PackedStringArray(["*.json ; JSON mission scenario"])
		ui_root.add_child(load_dialog)

	var save_dialog := ui_root.get_node_or_null("ScenarioSaveAsDialog") as FileDialog
	if save_dialog == null:
		save_dialog = FileDialog.new()
		save_dialog.name = "ScenarioSaveAsDialog"
		save_dialog.title = "Save Mission Scenario"
		save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		save_dialog.access = FileDialog.ACCESS_RESOURCES
		save_dialog.current_dir = DEFAULT_SCENARIO_DIR
		save_dialog.filters = PackedStringArray(["*.json ; JSON mission scenario"])
		ui_root.add_child(save_dialog)

	connect_signals()
	if _host.has_method("_apply_contextual_help_ids"):
		_host.call("_apply_contextual_help_ids")
	refresh()


func connect_signals() -> void:
	var load_button := get_button("ScenarioLoadButton")
	var save_button := get_button("ScenarioSaveButton")
	var save_as_button := get_button("ScenarioSaveAsButton")
	var live_test_button := get_button("ScenarioLiveTestButton")
	var objective_tile_button := get_button("ScenarioObjectiveTileButton")
	var spawn_tile_button := get_button("ScenarioSpawnTileButton")
	var auto_bind_button := get_button("ScenarioAutoBindButton")
	if load_button != null and not load_button.pressed.is_connected(_on_load_pressed):
		load_button.pressed.connect(_on_load_pressed)
	if save_button != null and not save_button.pressed.is_connected(_on_save_pressed):
		save_button.pressed.connect(_on_save_pressed)
	if save_as_button != null and not save_as_button.pressed.is_connected(_on_save_as_pressed):
		save_as_button.pressed.connect(_on_save_as_pressed)
	if live_test_button != null and not live_test_button.pressed.is_connected(_on_live_test_pressed):
		live_test_button.pressed.connect(_on_live_test_pressed)
	if objective_tile_button != null and not objective_tile_button.pressed.is_connected(_on_use_objective_tile_pressed):
		objective_tile_button.pressed.connect(_on_use_objective_tile_pressed)
	if spawn_tile_button != null and not spawn_tile_button.pressed.is_connected(_on_use_spawn_tile_pressed):
		spawn_tile_button.pressed.connect(_on_use_spawn_tile_pressed)
	if auto_bind_button != null and not auto_bind_button.pressed.is_connected(_on_auto_bind_pressed):
		auto_bind_button.pressed.connect(_on_auto_bind_pressed)

	for line_edit in [
		get_line_edit("ScenarioIdLineEdit"),
		get_line_edit("ScenarioNameLineEdit"),
		get_line_edit("ScenarioEnemyIdsLineEdit"),
		get_line_edit("ScenarioPatrolBindingsLineEdit"),
	]:
		if line_edit != null and not line_edit.text_changed.is_connected(_on_text_changed):
			line_edit.text_changed.connect(_on_text_changed)

	for spinbox in [
		get_spinbox("ScenarioCaptureRadiusSpinBox"),
		get_spinbox("ScenarioTimeLimitSpinBox"),
		get_spinbox("ScenarioWaveCountSpinBox"),
		get_spinbox("ScenarioUnitsPerWaveSpinBox"),
		get_spinbox("ScenarioFirstWaveDelaySpinBox"),
		get_spinbox("ScenarioWaveDelaySpinBox"),
	]:
		if spinbox != null and not spinbox.value_changed.is_connected(_on_value_changed):
			spinbox.value_changed.connect(_on_value_changed)

	for option_button in [
		get_option_button("ScenarioObjectiveOption"),
		get_option_button("ScenarioSpawnOption"),
		get_option_button("ScenarioEnemyTacticProfileOption"),
		get_option_button("ScenarioEnemySecurityModeOption"),
		get_option_button("ScenarioEnemyFacingOption"),
		get_option_button("ScenarioEnemyHeavyRoleOption"),
		get_option_button("ScenarioEnemyATWeaponOption"),
		get_option_button("ScenarioAirAssetRiskOption"),
		get_option_button("ScenarioLZThreatZoneOption"),
		get_option_button("ScenarioCommIntensityOption"),
	]:
		if option_button != null and not option_button.item_selected.is_connected(_on_option_selected):
			option_button.item_selected.connect(_on_option_selected)

	var load_dialog: FileDialog = _host.get_node_or_null("UI/ScenarioLoadDialog") as FileDialog if _host != null else null
	if load_dialog != null and not load_dialog.file_selected.is_connected(_on_load_file_selected):
		load_dialog.file_selected.connect(_on_load_file_selected)
	var save_dialog: FileDialog = _host.get_node_or_null("UI/ScenarioSaveAsDialog") as FileDialog if _host != null else null
	if save_dialog != null and not save_dialog.file_selected.is_connected(_on_save_as_file_selected):
		save_dialog.file_selected.connect(_on_save_as_file_selected)


func refresh() -> void:
	if _host == null:
		return
	var panel := get_panel()
	if panel == null:
		return
	var scenario = _host.call("_ensure_mission_scenario") if _host.has_method("_ensure_mission_scenario") else null
	if scenario == null:
		return

	_host.set("_is_refreshing_scenario_controls", true)
	_refresh_marker_options()
	_refresh_enemy_tactics_options()

	var path_label := panel.get_node_or_null("ScenarioPathLabel") as Label
	var map_label := panel.get_node_or_null("ScenarioMapLabel") as Label
	var id_line_edit := get_line_edit("ScenarioIdLineEdit")
	var name_line_edit := get_line_edit("ScenarioNameLineEdit")
	var enemy_ids_line_edit := get_line_edit("ScenarioEnemyIdsLineEdit")
	var patrol_line_edit := get_line_edit("ScenarioPatrolBindingsLineEdit")
	var radius_spinbox := get_spinbox("ScenarioCaptureRadiusSpinBox")
	var time_spinbox := get_spinbox("ScenarioTimeLimitSpinBox")
	var wave_count_spinbox := get_spinbox("ScenarioWaveCountSpinBox")
	var units_per_wave_spinbox := get_spinbox("ScenarioUnitsPerWaveSpinBox")
	var first_wave_delay_spinbox := get_spinbox("ScenarioFirstWaveDelaySpinBox")
	var wave_delay_spinbox := get_spinbox("ScenarioWaveDelaySpinBox")
	var info_label := panel.get_node_or_null("ScenarioInfoLabel") as Label
	if path_label != null:
		path_label.text = "Scenario: %s%s" % [_get_current_scenario_path() if not _get_current_scenario_path().is_empty() else "(new)", " *" if _is_scenario_dirty() else ""]
	if map_label != null:
		map_label.text = "Map: %s" % (_get_current_map_path() if not _get_current_map_path().is_empty() else "(unsaved)")
	if id_line_edit != null:
		id_line_edit.text = String(scenario.get("scenario_id"))
	if name_line_edit != null:
		name_line_edit.text = String(scenario.get("display_name"))
	if enemy_ids_line_edit != null:
		enemy_ids_line_edit.text = ", ".join(scenario.call("get_enemy_ids"))
	if patrol_line_edit != null:
		patrol_line_edit.text = String(_host.call("_format_patrol_bindings_text", Array(scenario.get("patrol_bindings"))))
	if radius_spinbox != null:
		radius_spinbox.value = float(Dictionary(scenario.get("objective")).get("capture_radius", 80.0))
	if time_spinbox != null:
		time_spinbox.value = maxf(float(scenario.get("time_limit_seconds")), 0.0)
	var wave_config: Dictionary = Dictionary(scenario.get("wave_config"))
	if wave_count_spinbox != null:
		wave_count_spinbox.value = int(wave_config.get("wave_count", 1))
	if units_per_wave_spinbox != null:
		units_per_wave_spinbox.value = int(wave_config.get("units_per_wave", 2))
	if first_wave_delay_spinbox != null:
		first_wave_delay_spinbox.value = float(wave_config.get("first_wave_delay_seconds", 0.0))
	if wave_delay_spinbox != null:
		wave_delay_spinbox.value = float(wave_config.get("wave_delay_seconds", 90.0))
	if info_label != null:
		info_label.text = String(_host.call("_build_mission_scenario_info_text"))
	_host.set("_is_refreshing_scenario_controls", false)
	_host.call("_refresh_top_bar")
	_host.call("_apply_inspector_section_visibility")


func sync_from_controls() -> void:
	if _host == null:
		return
	var scenario = _host.call("_ensure_mission_scenario")
	if scenario == null:
		return
	var id_line_edit := get_line_edit("ScenarioIdLineEdit")
	var name_line_edit := get_line_edit("ScenarioNameLineEdit")
	var enemy_ids_line_edit := get_line_edit("ScenarioEnemyIdsLineEdit")
	var patrol_line_edit := get_line_edit("ScenarioPatrolBindingsLineEdit")
	var radius_spinbox := get_spinbox("ScenarioCaptureRadiusSpinBox")
	var time_spinbox := get_spinbox("ScenarioTimeLimitSpinBox")
	var wave_count_spinbox := get_spinbox("ScenarioWaveCountSpinBox")
	var units_per_wave_spinbox := get_spinbox("ScenarioUnitsPerWaveSpinBox")
	var first_wave_delay_spinbox := get_spinbox("ScenarioFirstWaveDelaySpinBox")
	var wave_delay_spinbox := get_spinbox("ScenarioWaveDelaySpinBox")

	var scenario_id: String = id_line_edit.text.strip_edges() if id_line_edit != null else String(scenario.get("scenario_id")).strip_edges()
	if scenario_id.is_empty():
		scenario_id = String(_host.call("_build_default_scenario_id"))
	var display_name: String = name_line_edit.text.strip_edges() if name_line_edit != null else String(scenario.get("display_name")).strip_edges()
	if display_name.is_empty():
		display_name = scenario_id.capitalize()
	scenario.set("scenario_id", scenario_id)
	scenario.set("display_name", display_name)
	scenario.set("map_file_path", _get_current_map_path() if not _get_current_map_path().is_empty() else "res://maps/test_mission.json")
	scenario.set("mission_slot_count_override", int(_host.call("_get_current_map_mission_slot_count")))
	if time_spinbox != null:
		scenario.set("time_limit_seconds", maxf(float(time_spinbox.value), 0.0))

	var objective: Dictionary = Dictionary(scenario.get("objective")).duplicate(true)
	objective["capture_radius"] = maxf(float(radius_spinbox.value if radius_spinbox != null else objective.get("capture_radius", 80.0)), 1.0)
	var objective_selection: String = _get_selected_metadata("ScenarioObjectiveOption")
	if objective_selection == SCENARIO_POSITION_META:
		objective.erase("marker_id")
		objective["position"] = _host.call("_get_selected_or_existing_position", objective, _host.call("_get_selected_or_map_center_position", Vector2.ZERO))
	elif not objective_selection.is_empty():
		objective["marker_id"] = objective_selection
		objective.erase("position")
	scenario.set("objective", objective)

	var enemy_ids: PackedStringArray = _host.call("_parse_string_list", enemy_ids_line_edit.text if enemy_ids_line_edit != null else "")
	if enemy_ids.is_empty():
		enemy_ids = PackedStringArray(["enemy_delta", "enemy_echo"])
	var groups: Array = Array(scenario.get("enemy_groups")).duplicate(true)
	var group: Dictionary = Dictionary(_host.call("_get_primary_enemy_group")).duplicate(true)
	if group.is_empty():
		group = {
			"group_id": "red_test_group",
			"display_name": "Test Contacts",
			"team_id": "team_bravo",
		}
	group["enemy_ids"] = Array(enemy_ids)
	group["team_id"] = String(group.get("team_id", "team_bravo")).strip_edges()
	if String(group.get("group_id", "")).strip_edges().is_empty():
		group["group_id"] = "red_test_group"
	var spawn_selection: String = _get_selected_metadata("ScenarioSpawnOption")
	if spawn_selection == SCENARIO_POSITION_META:
		group.erase("spawn_marker_id")
		group["spawn_position"] = _host.call("_get_selected_or_existing_position", group, _host.call("_get_selected_or_map_center_position", Vector2.ZERO), "spawn_position")
	elif not spawn_selection.is_empty():
		group["spawn_marker_id"] = spawn_selection
		group.erase("spawn_position")
	var tactic_profile_id: String = _get_selected_metadata("ScenarioEnemyTacticProfileOption")
	var security_mode: String = _get_selected_metadata("ScenarioEnemySecurityModeOption")
	var facing: String = _get_selected_metadata("ScenarioEnemyFacingOption")
	var heavy_weapon_role: String = _get_selected_metadata("ScenarioEnemyHeavyRoleOption")
	var at_weapon_id: String = _get_selected_metadata("ScenarioEnemyATWeaponOption")
	var air_asset_risk_profile: String = _get_selected_metadata("ScenarioAirAssetRiskOption")
	var lz_threat_zone_id: String = _get_selected_metadata("ScenarioLZThreatZoneOption")
	var communication_intensity: String = _get_selected_metadata("ScenarioCommIntensityOption")
	var tactic_input: Dictionary = Dictionary(group.get("tactics", {})).duplicate(true)
	if not tactic_profile_id.is_empty():
		tactic_input["profile_id"] = tactic_profile_id
	if not security_mode.is_empty():
		tactic_input["security_mode"] = security_mode
	if not facing.is_empty():
		tactic_input["facing"] = facing
	if not heavy_weapon_role.is_empty():
		tactic_input["heavy_weapon_role"] = heavy_weapon_role
	if at_weapon_id == "none":
		tactic_input["weapon_id"] = ""
	elif not at_weapon_id.is_empty():
		tactic_input["weapon_id"] = at_weapon_id
	if not air_asset_risk_profile.is_empty():
		tactic_input["air_asset_risk_profile"] = air_asset_risk_profile
	tactic_input["lz_threat_zone_id"] = lz_threat_zone_id
	if not communication_intensity.is_empty():
		tactic_input["communication_intensity"] = communication_intensity
	group["tactics"] = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("serialize_config", tactic_input, _host.call("_get_current_grid_size"))
	if groups.is_empty():
		groups.append(group)
	else:
		groups[0] = group
	scenario.set("enemy_groups", groups)
	_host.call("_apply_tactical_authoring_from_controls", scenario, group)

	scenario.set(
		"wave_config",
		{
			"wave_count": maxi(int(wave_count_spinbox.value if wave_count_spinbox != null else 1), 0),
			"units_per_wave": maxi(int(units_per_wave_spinbox.value if units_per_wave_spinbox != null else 2), 1),
			"first_wave_delay_seconds": maxf(float(first_wave_delay_spinbox.value if first_wave_delay_spinbox != null else 0.0), 0.0),
			"wave_delay_seconds": maxf(float(wave_delay_spinbox.value if wave_delay_spinbox != null else 90.0), 0.0),
		}
	)
	scenario.set("patrol_bindings", _host.call("_parse_patrol_bindings_text", patrol_line_edit.text if patrol_line_edit != null else ""))


func get_panel() -> VBoxContainer:
	if _host == null:
		return null
	return _host.get_node_or_null("UI/PropertyPanel/Margin/VBox/MissionScenarioPanel") as VBoxContainer


func get_button(button_name: String) -> Button:
	var panel := get_panel()
	if panel == null:
		return null
	return panel.find_child(button_name, true, false) as Button


func get_line_edit(line_edit_name: String) -> LineEdit:
	var panel := get_panel()
	if panel == null:
		return null
	return panel.find_child(line_edit_name, true, false) as LineEdit


func get_spinbox(spinbox_name: String) -> SpinBox:
	var panel := get_panel()
	if panel == null:
		return null
	return panel.find_child(spinbox_name, true, false) as SpinBox


func get_option_button(option_name: String) -> OptionButton:
	var panel := get_panel()
	if panel == null:
		return null
	return panel.find_child(option_name, true, false) as OptionButton


func get_debug_snapshot() -> Dictionary:
	return {
		"script_path": get_script().resource_path,
		"panel_exists": get_panel() != null,
		"owns_control_setup": true,
		"owns_signal_connections": true,
		"owns_refresh": true,
		"owns_sync": true,
		"scenario_id": _get_scenario_id(),
		"scenario_dirty": _is_scenario_dirty(),
	}


func _add_line_edit_row(parent: VBoxContainer, row_name: String, label_text: String, line_edit_name: String) -> void:
	var row := HBoxContainer.new()
	row.name = row_name
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	row.add_child(label)
	var line_edit := LineEdit.new()
	line_edit.name = line_edit_name
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(line_edit)


func _add_option_row(parent: VBoxContainer, row_name: String, label_text: String, option_name: String, button_name: String, button_text: String) -> void:
	var row := HBoxContainer.new()
	row.name = row_name
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	row.add_child(label)
	var option := OptionButton.new()
	option.name = option_name
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(option)
	var button := Button.new()
	button.name = button_name
	button.text = button_text
	row.add_child(button)


func _add_select_row(parent: VBoxContainer, row_name: String, label_text: String, option_name: String) -> void:
	var row := HBoxContainer.new()
	row.name = row_name
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	row.add_child(label)
	var option := OptionButton.new()
	option.name = option_name
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(option)


func _add_spinbox_row(parent: VBoxContainer, row_name: String, label_text: String, spinbox_name: String, min_value: float, max_value: float, step_value: float) -> void:
	var row := HBoxContainer.new()
	row.name = row_name
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	row.add_child(label)
	var spinbox := SpinBox.new()
	spinbox.name = spinbox_name
	spinbox.min_value = min_value
	spinbox.max_value = max_value
	spinbox.step = step_value
	spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spinbox)


func _refresh_marker_options() -> void:
	var scenario = _host.call("_ensure_mission_scenario") if _host != null else null
	if scenario == null:
		return
	var objective: Dictionary = Dictionary(scenario.get("objective"))
	var objective_option := get_option_button("ScenarioObjectiveOption")
	if objective_option != null:
		_populate_marker_option(objective_option, String(objective.get("marker_id", "")).strip_edges(), objective.has("position"))

	var spawn_option := get_option_button("ScenarioSpawnOption")
	if spawn_option != null:
		var group: Dictionary = Dictionary(_host.call("_get_primary_enemy_group"))
		_populate_marker_option(spawn_option, String(group.get("spawn_marker_id", "")).strip_edges(), group.has("spawn_position"))


func _refresh_enemy_tactics_options() -> void:
	var group: Dictionary = Dictionary(_host.call("_get_primary_enemy_group"))
	var tactics: Dictionary = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_config", group.get("tactics", {}), _host.call("_get_current_grid_size"))
	_host.call("_populate_string_option", get_option_button("ScenarioEnemyTacticProfileOption"), ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_profile_ids"), String(tactics.get("profile_id", "")))
	_host.call("_populate_string_option", get_option_button("ScenarioEnemySecurityModeOption"), ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_security_modes"), String(tactics.get("security_mode", "")))
	_host.call("_populate_string_option", get_option_button("ScenarioEnemyFacingOption"), ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_facing_options"), String(tactics.get("facing", "")))
	_host.call("_populate_string_option", get_option_button("ScenarioEnemyHeavyRoleOption"), ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_heavy_weapon_roles"), String(tactics.get("heavy_weapon_role", "none")))
	_host.call("_populate_optional_string_option", get_option_button("ScenarioEnemyATWeaponOption"), ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_anti_armor_weapon_ids"), String(tactics.get("weapon_id", "")))
	var scenario = _host.call("_ensure_mission_scenario")
	_host.call("_populate_string_option", get_option_button("ScenarioAirAssetRiskOption"), ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_air_asset_risk_profiles"), String(tactics.get("air_asset_risk_profile", Dictionary(scenario.call("get_air_asset_risk_config")).get("profile_id", "none"))))
	_host.call("_populate_optional_marker_option", get_option_button("ScenarioLZThreatZoneOption"), String(tactics.get("lz_threat_zone_id", Dictionary(scenario.call("get_air_asset_risk_config")).get("lz_threat_zone_id", ""))))
	_host.call("_populate_string_option", get_option_button("ScenarioCommIntensityOption"), ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_communication_intensities"), String(tactics.get("communication_intensity", Dictionary(scenario.call("get_tactical_authoring_config")).get("communication_intensity", "normal"))))


func _populate_marker_option(option_button: OptionButton, selected_marker_id: String, use_position: bool) -> void:
	var previous_selection: String = selected_marker_id
	if use_position:
		previous_selection = SCENARIO_POSITION_META
	option_button.clear()
	var selected_index: int = -1
	var terrain_map_data = _host.get("_terrain_map_data") if _host != null else null
	if terrain_map_data != null:
		for marker_id in PackedStringArray(terrain_map_data.call("get_marker_ids")):
			var marker_text: String = String(marker_id)
			option_button.add_item(marker_text)
			option_button.set_item_metadata(option_button.item_count - 1, marker_text)
			if marker_text == previous_selection:
				selected_index = option_button.item_count - 1
	if not selected_marker_id.is_empty() and selected_index < 0:
		option_button.add_item(selected_marker_id)
		option_button.set_item_metadata(option_button.item_count - 1, selected_marker_id)
		selected_index = option_button.item_count - 1
	option_button.add_item("Position")
	option_button.set_item_metadata(option_button.item_count - 1, SCENARIO_POSITION_META)
	if previous_selection == SCENARIO_POSITION_META:
		selected_index = option_button.item_count - 1
	if selected_index < 0 and option_button.item_count > 0:
		selected_index = 0
	if selected_index >= 0:
		option_button.select(selected_index)


func _get_selected_metadata(option_name: String) -> String:
	var option_button := get_option_button(option_name)
	if option_button == null or option_button.selected < 0 or option_button.selected >= option_button.item_count:
		return ""
	return String(option_button.get_item_metadata(option_button.selected)).strip_edges()


func _on_text_changed(_new_text: String) -> void:
	_on_control_changed()


func _on_value_changed(_value: float) -> void:
	_on_control_changed()


func _on_option_selected(_index: int) -> void:
	_on_control_changed()


func _on_control_changed() -> void:
	if _host == null or bool(_host.get("_is_refreshing_scenario_controls")):
		return
	sync_from_controls()
	_host.set("_scenario_feedback_text", "")
	_host.call("_mark_scenario_dirty", true)


func _on_load_pressed() -> void:
	var load_dialog: FileDialog = _host.get_node_or_null("UI/ScenarioLoadDialog") as FileDialog if _host != null else null
	if load_dialog == null:
		return
	load_dialog.current_dir = DEFAULT_SCENARIO_DIR
	load_dialog.popup_centered_ratio(0.65)


func _on_save_pressed() -> void:
	if _get_current_scenario_path().is_empty():
		_on_save_as_pressed()
		return
	_host.call("save_mission_scenario_from_editor", _get_current_scenario_path())


func _on_save_as_pressed() -> void:
	var save_dialog: FileDialog = _host.get_node_or_null("UI/ScenarioSaveAsDialog") as FileDialog if _host != null else null
	if save_dialog == null:
		return
	save_dialog.current_dir = DEFAULT_SCENARIO_DIR
	save_dialog.current_file = _get_current_scenario_path().get_file() if not _get_current_scenario_path().is_empty() else "%s.json" % String(_host.call("_build_default_scenario_id"))
	save_dialog.popup_centered_ratio(0.65)


func _on_live_test_pressed() -> void:
	var scene = _host.call("create_live_test_scene_from_current_scenario") if _host != null else null
	if scene == null:
		return
	var tree: SceneTree = _host.get_tree()
	if tree == null:
		scene.queue_free()
		return
	var current_scene: Node = tree.current_scene
	tree.root.add_child(scene)
	tree.current_scene = scene
	if current_scene != null:
		current_scene.queue_free()


func _on_use_objective_tile_pressed() -> void:
	var scenario = _host.call("_ensure_mission_scenario")
	if scenario == null:
		return
	var position = _host.call("_get_required_selected_tile_world_position", "Select a tile first for the objective.")
	if position == null:
		return
	var objective: Dictionary = Dictionary(scenario.get("objective")).duplicate(true)
	objective.erase("marker_id")
	objective["position"] = Vector2(position)
	scenario.set("objective", objective)
	_host.set("_scenario_feedback_text", "Objective position set.")
	_host.call("_mark_scenario_dirty", true)
	refresh()


func _on_use_spawn_tile_pressed() -> void:
	var scenario = _host.call("_ensure_mission_scenario")
	if scenario == null:
		return
	var position = _host.call("_get_required_selected_tile_world_position", "Select a tile first for the enemy spawn.")
	if position == null:
		return
	var groups: Array = Array(scenario.get("enemy_groups")).duplicate(true)
	var group: Dictionary = Dictionary(_host.call("_get_primary_enemy_group")).duplicate(true)
	if group.is_empty():
		group = {
			"group_id": "red_test_group",
			"display_name": "Test Contacts",
			"team_id": "team_bravo",
			"enemy_ids": ["enemy_delta"],
		}
	group.erase("spawn_marker_id")
	group["spawn_position"] = Vector2(position)
	if groups.is_empty():
		groups.append(group)
	else:
		groups[0] = group
	scenario.set("enemy_groups", groups)
	_host.set("_scenario_feedback_text", "Enemy spawn position set.")
	_host.call("_mark_scenario_dirty", true)
	refresh()


func _on_auto_bind_pressed() -> void:
	var scenario = _host.call("_ensure_mission_scenario")
	if scenario == null:
		return
	sync_from_controls()
	var enemy_ids: PackedStringArray = scenario.call("get_enemy_ids")
	scenario.set("patrol_bindings", _host.call("_build_auto_patrol_bindings", enemy_ids))
	_host.set("_scenario_feedback_text", "Patrol bindings refreshed.")
	_host.call("_mark_scenario_dirty", true)
	refresh()


func _on_load_file_selected(path: String) -> void:
	_host.call("load_mission_scenario_for_editor", path)


func _on_save_as_file_selected(path: String) -> void:
	_host.call("save_mission_scenario_from_editor", path)


func _get_current_map_path() -> String:
	return String(_host.get("_current_map_path")).strip_edges() if _host != null else ""


func _get_current_scenario_path() -> String:
	return String(_host.get("_current_scenario_path")).strip_edges() if _host != null else ""


func _is_scenario_dirty() -> bool:
	return bool(_host.get("_scenario_dirty")) if _host != null else false


func _get_scenario_id() -> String:
	if _host == null:
		return ""
	var scenario = _host.get("_mission_scenario")
	return String(scenario.get("scenario_id")).strip_edges() if scenario != null else ""
