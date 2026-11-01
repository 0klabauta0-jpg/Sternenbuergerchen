extends SceneTree
## Small authored content slice. No runtime footprint inference or preview actors.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const MAP_PATH := "res://maps/frontier_workyard_24x20.json"
const SCENARIO_PATH := "res://data/mission_scenarios/frontier_workyard_24x20.json"
const UTILITY_ANCHOR := Vector2i(11,9)
# Authored from the fixed source bounds 4.68 x 3.24 m at 0.35, plus 0.30 m
# tactical clearance. It is compiled into stored tile facts exactly once.
const UTILITY_RESERVATION_HALF := Vector2(1.119,0.867)

func _initialize() -> void:
	call_deferred("generate")

func generate() -> void:
	var data = MAP.create_empty("frontier_workyard_24x20",Vector2i(24,20),Vector2(1536,64),64.0,32.0,4,"hex_axial_v1")
	data.set_terrain_visual_theme_id("frontier_illustrated_v1")
	var center: Vector2 = HEX.axial_to_plane(Vector2(UTILITY_ANCHOR))
	var reserved: Array = []
	for tile in data.get_tiles():
		tile.edge_type = "none" # Flat authored cells must not inherit the generic cliff default.
		var plane: Vector2 = HEX.axial_to_plane(Vector2(tile.grid_position))
		tile.surface_type = "road" if absf(plane.y-center.y)<1.35 and plane.x>8.0 and plane.x<23.5 else "ground"
		if absf(plane.x-center.x)<=UTILITY_RESERVATION_HALF.x and absf(plane.y-center.y)<=UTILITY_RESERVATION_HALF.y:
			tile.walkable = false
			reserved.append([tile.grid_position.x,tile.grid_position.y])
			# Open service-frame/tank group, deliberately no newly claimed full
			# LOS/cover mechanic. The static walkability is the explicit map fact.
	var anchor = data.get_tile_at_grid(UTILITY_ANCHOR)
	anchor.object_type_id = "frontier_utility_fuel_01"
	for entry in [["spawn_alpha",Vector2i(6,9)],["spawn_bravo",Vector2i(22,18)],["objective_point",Vector2i(16,9)],["rally_workyard",Vector2i(8,12)]]:
		data.set_marker_position(entry[0],data.get_tile_at_grid(entry[1]).world_position)
	if data.save_to_file(MAP_PATH)!=OK:
		push_error("Cannot save Frontier workyard map")
		quit(1)
		return
	var scenario := {
		"version":1,"scenario_id":"frontier_workyard_24x20","display_name":"Frontier: Versorgungshof (Grafik-/Authoring-Slice)",
		"map_file_path":MAP_PATH,"time_limit_seconds":900.0,"mission_slot_count_override":4,
		"objective":{"marker_id":"objective_point","capture_radius":64.0},
		"enemy_groups":[{"group_id":"distant_workyard_patrol","display_name":"Entfernte Testwache","team_id":"team_bravo","spawn_marker_id":"spawn_bravo","enemy_ids":["enemy_delta","enemy_echo"]}],
		"wave_config":{"wave_count":1,"units_per_wave":2,"first_wave_delay_seconds":600.0,"wave_delay_seconds":60.0},
		"patrol_bindings":[],
		"notes":["P07: small regular Hex map, not the frontier_art_preview fixture.","Original utility_fuel_01 at 0.35; stored occupied cells have no new LOS/cover semantics.","Existing Editor Live Test PackedScene activation is unchanged; no authored LZ or Meta deployment acceptance.","No base building, interior, fuel, resource or ship gameplay."]
	}
	var file := FileAccess.open(SCENARIO_PATH,FileAccess.WRITE)
	if file==null:
		push_error("Cannot save Frontier workyard scenario")
		quit(1)
		return
	file.store_string(JSON.stringify(scenario,"\t")+"\n")
	var out := "res://output/grafik_20261101/pass07_runtime/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var facts := {"map":MAP_PATH,"scenario":SCENARIO_PATH,"grid_size":[24,20],"topology":"hex_axial_v1","theme":"frontier_illustrated_v1","utility_anchor":[11,9],"reservation_half_plane_m":[1.119,0.867],"reserved_cells":reserved,"footprint_source":"fixed authoring dimensions, not runtime visual bounds","map_sha256":FileAccess.get_sha256(MAP_PATH)}
	var report := FileAccess.open(out+"authoring.json",FileAccess.WRITE)
	report.store_string(JSON.stringify(facts,"\t")+"\n")
	print("FRONTIER_WORKYARD_GENERATED ",JSON.stringify(facts))
	quit(0)
