extends SceneTree
const BASE = preload("res://scenes/meta/explorable_homebase.tscn")
const SOURCES := {
	"habitat_cutaway_01": "res://Assets/curated/frontier_illustrated_20261101/structures_pass04/habitat_cutaway_01.glb",
	"freihafen_hall_01": "res://Assets/curated/frontier_illustrated_20261101/structures_pass04/freihafen_hall_01.glb"
}
const ORIGINAL_SHA := {"habitat_cutaway_01":"6524cd513b1d474dba4a855ef1dad32ec4539513acb46bf73cd1b44463a2d50f","freihafen_hall_01":"cc17a4cebc805a3f165eecd0e3bef95b7a92e851dc592fb8867b92597a894508"}
var REPLACED_IDS: Array = preload("res://scripts/meta/structure_model_overrides.gd").replaced_ids()
var passed := 0
var failed := 0
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	for id in SOURCES:
		_check(FileAccess.get_sha256(SOURCES[id]) == ORIGINAL_SHA[id], "unchanged archived furnished original " + id)
	for mode in ["campaign", "skirmish"]:
		var base: Control = BASE.instantiate()
		root.add_child(base)
		await process_frame
		base.call("set_transport_snapshot", {"mode": mode})
		base.call("set_active", true)
		await process_frame
		var snapshot: Dictionary = base.call("get_exploration_snapshot")
		_check(snapshot.map_grid_size == Vector2i(36, 28), mode + " retains the larger base map")
		_check(Array(snapshot.interiors).size() == 2, mode + " retains both authored building areas")
		_check(Array(snapshot.landing_pads).size() == 2, mode + " retains stable landing footprints")
		_check(int(snapshot.cutaway_wall_visual_count) == 0, mode + " renders no bare replacement walls")
		var structures: Dictionary = snapshot.get("structure_visuals", {})
		for id in SOURCES:
			# Ersetzt ein neues Modell das Gebaeude (habitat_cutaway_01 -> Pod), wird das alte gar nicht mehr geladen.
			if String(id) in REPLACED_IDS:
				_check(not structures.has(id), mode + " does not load replaced furnished source " + id)
				continue
			var actual: Dictionary = structures.get(id, {})
			_check(bool(actual.get("visible", false)), mode + " shows furnished source " + id)
			var candidate := "res://Assets/curated/base_access_20261109/" + String(id) + ".glb"
			_check(String(actual.get("source_path", "")) == candidate and String(actual.get("actual_sha256", "")) == FileAccess.get_sha256(candidate), mode + " uses verified furnished doorway candidate " + id)
			_check(String(actual.get("original_path", "")) == SOURCES[id] and String(actual.get("route", "")) == "furnished_cutaway_with_door_openings", mode + " retains original furnished source provenance " + id)
		base.call("set_active", false)
		base.queue_free()
		await process_frame
	print("BASE_ORIGINAL_ROOMS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
	print("PASS: " if value else "FAIL: ", label)
