extends SceneTree
const BASE = preload("res://scenes/meta/explorable_homebase.tscn")
const SOURCES := {
	"habitat_cutaway_01": "res://Assets/curated/frontier_illustrated_20261101/structures_pass04/habitat_cutaway_01.glb",
	"freihafen_hall_01": "res://Assets/curated/frontier_illustrated_20261101/structures_pass04/freihafen_hall_01.glb"
}
var passed := 0
var failed := 0
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
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
			var actual: Dictionary = structures.get(id, {})
			_check(bool(actual.get("visible", false)), mode + " shows furnished source " + id)
			_check(String(actual.get("source_path", "")) == SOURCES[id] and String(actual.get("actual_sha256", "")) == FileAccess.get_sha256(SOURCES[id]), mode + " uses original unchanged GLB " + id)
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
