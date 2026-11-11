extends SceneTree
const STATE = preload("res://scripts/core/space_combat_state.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var state = STATE.new()
	var id := "space_fixture_inactive"
	var area := "orbit_approach:moon"
	var cell: Vector2i = GRID.from_offset(Vector2i(200,100))
	var flight = FLIGHT.new()
	flight.configure(id, {"position_plane":GRID.HEX.axial_to_plane(Vector2(cell)), "motion_mode":"tactical", "coordinate_frame":"local", "space_area_id":area})
	var definition := {"craft_id":id, "faction_id":"player", "control_domain":"player", "start_hex":cell, "footprint_hexes":[Vector2i.ZERO]}
	var failed := 0
	if not state.admit_actor(definition, flight, true).get("ok", false): failed += 1
	var claim: Array[Vector2i] = [cell + Vector2i(1,0)]
	state.record_navigation_claim(id, area, claim)
	if state.deactivate_actor(id).get("reason") != "flight_not_inactive": failed += 1
	var prepared: Dictionary = state.validate_deactivation(id, 0, state.get_area_revision(area))
	var activity: Dictionary = flight.validate_space_activity_transition({"expected_revision":0, "motion_mode":"inactive"}, 1)
	if not prepared.get("ok", false) or not activity.get("ok", false) or flight.get_snapshot().motion_mode != "tactical": failed += 1
	flight._publish_space_activity_transition(activity)
	state._publish_deactivation(prepared)
	if state.get_actor(id) != null or state.get_inactive_actor(id) != flight or not state.query_navigation_claims(claim, area).is_empty(): failed += 1
	state.sync_moved_actors()
	if not state.get_flight_snapshots().is_empty(): failed += 1
	if state.admit_actor(definition, flight, true).get("reason") != "already_inactive": failed += 1
	var next: Vector2i = cell + Vector2i(1,0)
	var proposal := {"expected_revision":flight.get_snapshot().revision, "motion_mode":"tactical", "position_plane":GRID.HEX.axial_to_plane(Vector2(next))}
	var blocker = FLIGHT.new()
	blocker.configure("space_fixture_blocker", {"position_plane":proposal.position_plane, "motion_mode":"tactical", "coordinate_frame":"local", "space_area_id":area})
	state.admit_actor({"craft_id":"space_fixture_blocker", "faction_id":"enemy", "control_domain":"enemy", "start_hex":next, "footprint_hexes":[Vector2i.ZERO]}, blocker, true)
	if state.preview_reactivation(id, proposal, 2).get("reason") != "occupied" or flight.get_snapshot().motion_mode != "inactive": failed += 1
	state.remove_actor("space_fixture_blocker")
	if not state.preview_reactivation(id, proposal, 2).get("ok", false) or flight.get_snapshot().motion_mode != "inactive": failed += 1
	flight.commit_space_activity_transition(proposal, 2)
	if not state.reactivate_actor(id).get("ok", false) or state.get_actor(id) != flight or state.get_inactive_actor(id) != null: failed += 1
	var cells: Array[Vector2i] = [next]
	if state.query_cells(cells, area) != [id]: failed += 1
	print("SPACE_COMBAT_AREA_INACTIVE passed=", 10 - failed, " failed=", failed)
	quit(1 if failed else 0)
