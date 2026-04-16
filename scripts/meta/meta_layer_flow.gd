extends Node

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const AVAILABLE_TEAM_UNITS: Array = [
	{
		"unit_id": "unit_alpha",
		"display_name": "Unit Alpha",
		"team_id": "team_alpha",
	},
	{
		"unit_id": "unit_bravo",
		"display_name": "Unit Bravo",
		"team_id": "team_alpha",
	},
	{
		"unit_id": "unit_charlie",
		"display_name": "Unit Charlie",
		"team_id": "team_alpha",
	},
]
const FRIENDLY_NODE_NAMES_BY_ID: Dictionary = {
	"unit_alpha": "UnitAlpha",
	"unit_bravo": "UnitBravo",
	"unit_charlie": "UnitCharlie",
}

var _selected_unit_ids: PackedStringArray = ["unit_alpha", "unit_bravo"]
var _active_mission = null


func _ready() -> void:
	var homebase_screen = _get_homebase_screen()
	var fob_screen = _get_fob_screen()
	if homebase_screen == null or fob_screen == null:
		push_warning("MetaLayerFlow requires HomebaseScreen and FOBScreen children.")
		return

	if not homebase_screen.team_confirmed.is_connected(_on_homebase_team_confirmed):
		homebase_screen.team_confirmed.connect(_on_homebase_team_confirmed)

	if not fob_screen.back_requested.is_connected(_on_fob_back_requested):
		fob_screen.back_requested.connect(_on_fob_back_requested)

	if not fob_screen.mission_start_requested.is_connected(_on_fob_mission_start_requested):
		fob_screen.mission_start_requested.connect(_on_fob_mission_start_requested)

	homebase_screen.setup_roster(AVAILABLE_TEAM_UNITS, _selected_unit_ids)
	fob_screen.set_team(_selected_unit_ids)
	_show_homebase()


func get_selected_unit_ids() -> PackedStringArray:
	return _selected_unit_ids.duplicate()


func get_active_mission():
	return _active_mission


func _on_homebase_team_confirmed(selected_unit_ids: PackedStringArray) -> void:
	_selected_unit_ids = selected_unit_ids.duplicate()
	_get_fob_screen().set_team(_selected_unit_ids)
	_show_fob()


func _on_fob_back_requested() -> void:
	_show_homebase()


func _on_fob_mission_start_requested(selected_unit_ids: PackedStringArray) -> void:
	_selected_unit_ids = selected_unit_ids.duplicate()
	_start_mission()


func _start_mission() -> void:
	var mission_host = _get_mission_host()
	if mission_host == null:
		push_warning("MetaLayerFlow requires a MissionHost child.")
		return

	if _active_mission != null:
		_active_mission.queue_free()
		_active_mission = null

	var mission_instance = MISSION_TEST_SCENE.instantiate()
	_configure_mission_instance(mission_instance, _selected_unit_ids)
	mission_host.add_child(mission_instance)
	_active_mission = mission_instance
	_show_mission()


func _configure_mission_instance(mission_instance: Node, selected_unit_ids: PackedStringArray) -> void:
	if selected_unit_ids.is_empty():
		return

	var mission_setup = mission_instance.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("selected_team_unit_ids", selected_unit_ids)

	var command_flow_driver = mission_instance.get_node_or_null("CommandFlowDriver")
	if command_flow_driver != null:
		command_flow_driver.set("unit_id", String(selected_unit_ids[0]))

	var combat_driver = mission_instance.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("friendly_unit_paths", _build_selected_friendly_paths(selected_unit_ids))


func _build_selected_friendly_paths(selected_unit_ids: PackedStringArray) -> Array[NodePath]:
	var selected_paths: Array[NodePath] = []
	for unit_id in selected_unit_ids:
		var node_name: String = String(FRIENDLY_NODE_NAMES_BY_ID.get(unit_id, ""))
		if node_name.is_empty():
			continue

		selected_paths.append(NodePath("../%s" % node_name))

	return selected_paths


func _show_homebase() -> void:
	var homebase_screen = _get_homebase_screen()
	var fob_screen = _get_fob_screen()
	if homebase_screen != null:
		homebase_screen.visible = true
		homebase_screen.set_selected_unit_ids(_selected_unit_ids)
	if fob_screen != null:
		fob_screen.visible = false


func _show_fob() -> void:
	var homebase_screen = _get_homebase_screen()
	var fob_screen = _get_fob_screen()
	if homebase_screen != null:
		homebase_screen.visible = false
	if fob_screen != null:
		fob_screen.visible = true
		fob_screen.set_team(_selected_unit_ids)


func _show_mission() -> void:
	var homebase_screen = _get_homebase_screen()
	var fob_screen = _get_fob_screen()
	if homebase_screen != null:
		homebase_screen.visible = false
	if fob_screen != null:
		fob_screen.visible = false


func _get_homebase_screen():
	return get_node_or_null("HomebaseScreen")


func _get_fob_screen():
	return get_node_or_null("FOBScreen")


func _get_mission_host():
	return get_node_or_null("MissionHost")
