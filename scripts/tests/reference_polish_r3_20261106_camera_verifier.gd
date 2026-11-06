extends SceneTree
## Composition fixture; native GPU/picking/fullscreen checks are separate.
const SETUP: GDScript = preload("res://scripts/tests/mission_test_setup.gd")
var passed := 0
var failed := 0

class MapFixture extends RefCounted:
	var layout := "gm01_frontier_outpost_v1"
	func get_authored_visual_layout_id() -> String:
		return layout

class ViewFixture extends Node:
	var calls := 0
	var points: Array = []
	var size_value := 34.0
	var accept := true
	func frame_world_positions(input: Array, _padding: float, minimum: float, maximum: float) -> Dictionary:
		calls += 1
		points = input.duplicate()
		if accept:
			size_value = clampf(22.0, minimum, maximum)
		return {"framed": accept}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var setup: Node = SETUP.new()
	var map := MapFixture.new()
	setup.set("_loaded_terrain_map_data", map)
	var spawn := Marker2D.new()
	spawn.name = "Spawn"
	spawn.position = Vector2(120, 240)
	setup.add_child(spawn)
	setup.set("spawn_alpha_path", NodePath("Spawn"))
	var objective := Marker2D.new()
	objective.name = "Objective"
	objective.position = Vector2(500, 620)
	setup.add_child(objective)
	setup.set("objective_point_path", NodePath("Objective"))
	var view := ViewFixture.new()
	check(setup.has_method("_frame_reference_mission_camera"), "GM01 initial camera path exists")
	if setup.has_method("_frame_reference_mission_camera"):
		check(bool(setup.call("_frame_reference_mission_camera", view)), "GM01 camera path owns initial framing")
		check(view.calls == 1 and view.size_value == 22.0, "Exact initial 22 size via public framing API")
		check(view.points == [spawn.position, objective.position], "Only existing friendly spawn and public objective positions")
		view.size_value = 47.0
		check(bool(setup.call("_frame_reference_mission_camera", view)) and view.calls == 1 and view.size_value == 47.0, "Repeated configure preserves later manual camera")
		map.layout = "unrelated_layout"
		var unrelated := ViewFixture.new()
		check(not bool(setup.call("_frame_reference_mission_camera", unrelated)) and unrelated.calls == 0 and unrelated.size_value == 34.0, "Other authored maps keep existing camera behavior")
		unrelated.free()
		map.layout = "gm01_frontier_outpost_v1"
		var retry := ViewFixture.new()
		retry.accept = false
		check(not bool(setup.call("_frame_reference_mission_camera", retry)), "Unsuccessful framing does not claim completion")
		retry.accept = true
		check(bool(setup.call("_frame_reference_mission_camera", retry)) and retry.calls == 2, "Failed attempt remains retryable")
		retry.free()
		setup.set("_loaded_terrain_map_data", null)
		check(not bool(setup.call("_frame_reference_mission_camera", view)), "Missing map safe")
		check(not bool(setup.call("_frame_reference_mission_camera", null)), "Missing view safe")
	view.free()
	setup.free()
	print("R3_CAMERA: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R3_REFERENCE_CAMERA_PASS")
	quit(1 if failed else 0)

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("PASS: " if ok else "FAIL: ", message)
