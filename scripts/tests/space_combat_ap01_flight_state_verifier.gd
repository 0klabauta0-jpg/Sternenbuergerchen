extends SceneTree
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")

func _initialize() -> void:
	var failures := 0
	var flight = FLIGHT.new()
	if not flight.configure("craft1", {"position_plane": Vector2.ZERO}).ok: failures += 1
	if not flight.commit_motion({"expected_revision": 0, "position_plane": Vector2(2, 0)}, 1).ok: failures += 1
	var before: Dictionary = flight.get_snapshot()
	if flight.commit_motion({"expected_revision": 1, "position_plane": Vector2(3, 0)}, 1).reason != "stale_tick": failures += 1
	if flight.commit_motion({"expected_revision": 0, "position_plane": Vector2(3, 0)}, 2).reason != "stale_revision": failures += 1
	if flight.commit_motion({"expected_revision": 1, "mass": 0.0}, 2).reason != "invalid_pose": failures += 1
	if flight.get_snapshot() != before: failures += 1
	print("SPACE_COMBAT_AP01_FLIGHT passed=", 6 - failures, " failed=", failures)
	quit(1 if failures else 0)
