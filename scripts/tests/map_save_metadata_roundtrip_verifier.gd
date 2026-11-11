extends SceneTree
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
var passed := 0
var failed := 0
var scratch := "user://map_save_metadata_%d/" % OS.get_process_id()
func _init() -> void:
	call_deferred("_run")
func _check(condition: bool, message: String) -> void:
	if condition: passed += 1
	else: failed += 1
	print("PASS: " if condition else "FAIL: ", message)
func _run() -> void:
	for name in ["campaign_intro_base", "homebase_frontier_exploration", "trade_outpost", "satellite_crash_site", "fortified_outpost", "Ground_Mission01_32x32"]:
		var path := "res://maps/%s.json" % name
		var before_hash := FileAccess.get_sha256(path)
		var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var map = MAP.load_from_file(path)
		map.set_map_name("Edited " + name)
		var target: String = scratch + name + ".json"
		_check(map.save_to_file(target) == OK, name + " SaveAs succeeds")
		var after: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(target))
		for key in ["homebase_exploration", "place_world", "singleplayer_site", "place_presentation"]:
			if before.has(key): _check(after.get(key) == before[key], name + " preserves " + key)
		_check(after.map_name == "Edited " + name, name + " canonical edits win")
		_check(Array(before.tiles).size() == Array(after.tiles).size(), name + " retains all tiles")
		_check(MAP.load_from_file(target).get_map_name() == after.map_name, name + " reloads saved edit")
		_check(FileAccess.get_sha256(path) == before_hash, name + " original untouched")
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://maps/test_mission.json"))
	original["future_metadata"] = {"version": 2, "nested": [{"room": "A", "enabled": false}, 7, null]}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(scratch))
	var input: String = scratch + "future.json"
	var file := FileAccess.open(input, FileAccess.WRITE)
	file.store_string(JSON.stringify(original)); file.close()
	original = JSON.parse_string(FileAccess.get_file_as_string(input))
	var future = MAP.load_from_file(input)
	future.set_map_name("New canonical name")
	future.get_tiles()[0].cover_value = 73
	var output: String = scratch + "future_saved.json"
	_check(future.save_to_file(output) == OK, "future metadata SaveAs succeeds")
	var result: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(output))
	_check(result.get("future_metadata") == original.future_metadata, "unknown nested metadata survives")
	_check(result.map_name == "New canonical name", "metadata cannot overwrite edited map name")
	var reloaded = MAP.load_from_file(output)
	_check(reloaded.get_tiles()[0].cover_value == 73, "metadata cannot overwrite edited tiles")
	var second: String = scratch + "future_twice.json"
	_check(reloaded.save_to_file(second) == OK, "second save succeeds")
	_check(Dictionary(JSON.parse_string(FileAccess.get_file_as_string(second))).get("future_metadata") == original.future_metadata, "metadata survives repeated save/reload")
	print("MAP_SAVE_METADATA passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
