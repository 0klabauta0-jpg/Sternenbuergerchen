extends SceneTree
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	var mapping: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/terrain_3d_asset_mapping.json"))
	var view = VIEW.new()
	var result: Dictionary = {}
	for family in ["habitat", "hall"]:
		mapping.models["_current_" + family] = {"model_path": "res://scenes/terrain/frontier_%s_exterior.tscn" % family, "scale": 1.0}
	for id in mapping.models:
		if not (String(id).begins_with("_current_") or String(id).begins_with("factory_building_") or String(id).begins_with("spacekit_hangar_") or String(id).begins_with("gebaeude_")): continue
		var entry: Dictionary = mapping.models[id]
		var model: Node3D = load(String(entry.model_path)).instantiate()
		view.call("_normalize_asset_model_instance", model)
		var bounds: Dictionary = view.call("_get_local_visual_bounds", model)
		var lo: Vector3 = bounds.min
		var hi: Vector3 = bounds.max
		result[id] = {"path": entry.model_path, "scale": entry.get("scale",1.0), "min": [lo.x,lo.y,lo.z], "max": [hi.x,hi.y,hi.z]}
		model.free()
	var f := FileAccess.open("res://docs/qa/map_save_building_migration_20261110/old_building_bounds.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"\t",true,true)); f.close()
	view.free()
	quit()
