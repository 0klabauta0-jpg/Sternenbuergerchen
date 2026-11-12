extends SceneTree

const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var map = MAP.create_empty("radar_marker_fixture", Vector2i(4, 4), Vector2.ZERO)
	var position: Vector2 = map.get_tile_at_grid(Vector2i(1, 1)).world_position
	var view = VIEW.new(); root.add_child(view); view.configure_from_map(map)
	view.set_mission_drop_visual_state({"dropship_visuals":[{"craft_id":"radar:contact", "radar_contact":true, "dropship_visible":true, "dropship_position":position, "show_lz_marker":false, "show_approach_vector":false}]})
	for i in range(4): await process_frame
	var markers := view.find_children("AirRadar_*", "Label3D", true, false)
	assert(markers.size() == 1 and markers[0].text == "◇ LUFTKONTAKT")
	view.set_mission_drop_visual_state({"dropship_visuals":[]})
	for i in range(4): await process_frame
	assert(view.find_children("AirRadar_*", "Label3D", true, false).is_empty())
	view.queue_free(); await process_frame
	print("AIR_RADAR_MARKER passed")
	quit()
