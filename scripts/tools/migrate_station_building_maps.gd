extends SceneTree
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const MIGRATION = preload("res://scripts/tools/frontier_station_building_migration.gd")
func _init() -> void: call_deferred("_run")
func _run() -> void:
	for name in ["station_outpost_64x64", "station_outpost_192x192"]:
		var path := "res://maps/%s.json" % name
		var map_data = MAP.load_from_file(path)
		if not MIGRATION.apply(map_data): quit(1); return
		if map_data.save_to_file(path) != OK: quit(1); return
		print("MIGRATED: ", path)
	quit()
