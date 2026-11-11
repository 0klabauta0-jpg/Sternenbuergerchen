extends SceneTree
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var failures := 0
	var fleet = FLEET.new()
	if not fleet.configure().ok: failures += 1
	fleet.register_craft("a")
	var flight: RefCounted = fleet.get_flight_state("a")
	if flight == null or flight != fleet.get_flight_state("a"): failures += 1
	var launch := {"contract_category": "singleplayer_space_travel", "operation": "launch_to_orbit", "payload": {"craft_id": "a"}, "request_id": "l"}
	if not fleet.apply_command(launch, {"runtime_authorized": true}).ok: failures += 1
	var travel: Dictionary = fleet.get_snapshot("a")
	var projected: Vector2 = flight.get_snapshot().position_plane / GRID.EXTENT
	if not projected.is_equal_approx(GRID.pair(travel.position)) or flight.get_snapshot().craft_id != "a": failures += 1
	print("SPACE_COMBAT_AP01_BINDING passed=", 4 - failures, " failed=", failures)
	quit(1 if failures else 0)
