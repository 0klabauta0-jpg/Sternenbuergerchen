class_name MetaMapScreen
extends Control

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")

var _map_file_path: String = "res://maps/test_mission.json"
var _mission_name: String = "Operation: FOB Transfer"
var _mission_slot_count: int = 3
var _selected_unit_ids: PackedStringArray = []
var _fob_overview: Dictionary = {}


func _ready() -> void:
	META_UI_SKIN_SCRIPT.apply_map(self)
	_render()


func set_map_context(mission_name: String, map_file_path: String, selected_unit_ids: PackedStringArray, fob_overview: Dictionary, mission_slot_count: int = 3) -> void:
	_mission_name = mission_name.strip_edges() if not mission_name.strip_edges().is_empty() else _mission_name
	_map_file_path = map_file_path.strip_edges() if not map_file_path.strip_edges().is_empty() else _map_file_path
	_mission_slot_count = maxi(mission_slot_count, 1)
	_selected_unit_ids = selected_unit_ids.duplicate()
	_fob_overview = fob_overview.duplicate(true)
	if is_inside_tree():
		_render()


func _render() -> void:
	var map_name_label := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MapNameLabel") as Label
	var operator_count_label := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/OperatorCountLabel") as Label
	var fireteam_count_label := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/FireteamCountLabel") as Label
	var mission_summary_label := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionSummaryLabel") as Label
	var map_data_label := get_node("Panel/Margin/VBox/ContentRow/MapPanel/MapMargin/MapVBox/MapDataLabel") as Label
	var map_help_label := get_node("Panel/Margin/VBox/ContentRow/MapPanel/MapMargin/MapVBox/MapHelpLabel") as Label
	var fireteam_overview_label := get_node("Panel/Margin/VBox/ContentRow/SummaryPanel/SummaryMargin/SummaryVBox/FireteamOverviewLabel") as Label
	var dropship_overview_label := get_node("Panel/Margin/VBox/ContentRow/SummaryPanel/SummaryMargin/SummaryVBox/DropshipOverviewLabel") as Label
	var respawn_overview_label := get_node("Panel/Margin/VBox/ContentRow/SummaryPanel/SummaryMargin/SummaryVBox/RespawnOverviewLabel") as Label

	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", _map_file_path)
	var map_name: String = _map_file_path.get_file().get_basename()
	var grid_size := Vector2i.ZERO
	var tile_count: int = 0
	if terrain_map_data != null:
		if terrain_map_data.has_method("get_map_name"):
			map_name = String(terrain_map_data.call("get_map_name"))
		if terrain_map_data.has_method("get_grid_size"):
			grid_size = terrain_map_data.call("get_grid_size")
		if terrain_map_data.has_method("get_tiles"):
			tile_count = int((terrain_map_data.call("get_tiles") as Array).size())

	var fireteams: Array = _fob_overview.get("fireteams", [])
	map_name_label.text = "Map: %s" % map_name
	operator_count_label.text = "Operators: %d" % _selected_unit_ids.size()
	fireteam_count_label.text = "Slots: %d | Fireteams: %d" % [_mission_slot_count, fireteams.size()]
	mission_summary_label.text = "%s on %s. Read-only map overview of the current meta preparation; no editor or gameplay commit happens here." % [_mission_name, map_name]
	map_data_label.text = "File: %s\nGrid: %d x %d\nTiles: %d" % [_map_file_path, grid_size.x, grid_size.y, tile_count]
	map_help_label.text = "Die Map-Ansicht bleibt bewusst read-only. Sie spiegelt nur den aktuellen Missions- und FOB-Vorbereitungsstand auf derselben Meta-Ebene."
	fireteam_overview_label.text = _build_fireteam_overview_text(fireteams)
	dropship_overview_label.text = "Dropship\n\n%s\n%s" % [
		String(_fob_overview.get("dropship_status", "Dropship: waiting for active fireteams")),
		String(_fob_overview.get("dropship_queue", "Boarding queue: no active fireteams")),
	]
	respawn_overview_label.text = _build_respawn_overview_text(fireteams)


func _build_fireteam_overview_text(fireteams: Array) -> String:
	if fireteams.is_empty():
		return "Fireteams\n\nNo FOB fireteams prepared yet."

	var lines: PackedStringArray = ["Fireteams", ""]
	for fireteam_variant in fireteams:
		if typeof(fireteam_variant) != TYPE_DICTIONARY:
			continue
		var fireteam: Dictionary = fireteam_variant
		var member_names: PackedStringArray = fireteam.get("member_names", PackedStringArray())
		lines.append("%s: %s | %s" % [
			"%s (Lead %s)" % [String(fireteam.get("label", "FT")), String(fireteam.get("lead_name", "none"))],
			"none" if member_names.is_empty() else ", ".join(member_names),
			String(fireteam.get("loadout", "medium")).to_upper(),
		])
	return "\n".join(lines)


func _build_respawn_overview_text(fireteams: Array) -> String:
	if fireteams.is_empty():
		return "Respawn + Loadout\n\nNo focused FOB staging available."

	var lines: PackedStringArray = ["Respawn + Loadout", ""]
	for fireteam_variant in fireteams:
		if typeof(fireteam_variant) != TYPE_DICTIONARY:
			continue
		var fireteam: Dictionary = fireteam_variant
		lines.append("%s: Respawn %s | Loadout %s" % [
			String(fireteam.get("label", "FT")),
			"FOB" if bool(fireteam.get("respawn_enabled", false)) else "off",
			String(fireteam.get("loadout", "medium")).to_upper(),
		])
	return "\n".join(lines)