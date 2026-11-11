extends SceneTree
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")

func _initialize() -> void:
	var flight = FLIGHT.new()
	var failed := 0
	if not flight.configure("ship", {"position_plane":Vector2.ZERO}).get("ok", false): failed += 1
	var initial: Dictionary = flight.get_snapshot()
	if initial.get("coordinate_frame") != "strategic" or initial.get("space_area_id") != "": failed += 1
	var wrong := {"expected_revision":initial.revision, "coordinate_frame":"local", "space_area_id":"orbit_approach:moon", "position_plane":Vector2(1, 1)}
	if flight.commit_motion(wrong, 0).get("reason") != "area_transition_required" or flight.get_snapshot() != initial: failed += 1
	var local = FLIGHT.new()
	if not local.configure("local_ship", {"position_plane":Vector2(1,1), "coordinate_frame":"local", "space_area_id":"orbit_approach:moon"}).get("ok", false): failed += 1
	var snap: Dictionary = local.get_snapshot()
	if snap.coordinate_frame != "local" or snap.space_area_id != "orbit_approach:moon": failed += 1
	if not local.commit_motion({"expected_revision":snap.revision, "position_plane":Vector2(2,1)}, 0).get("ok", false): failed += 1
	if FLIGHT.new().configure("invalid", {"position_plane":Vector2.ZERO, "coordinate_frame":"local", "space_area_id":""}).get("ok", false): failed += 1
	if FLIGHT.new().configure("invalid", {"position_plane":Vector2.ZERO, "coordinate_frame":"strategic", "space_area_id":"orbit_approach:moon"}).get("ok", false): failed += 1
	print("SPACE_COMBAT_AREA_FLIGHT passed=", 8 - failed, " failed=", failed)
	quit(1 if failed else 0)
