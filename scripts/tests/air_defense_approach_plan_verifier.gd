extends SceneTree
## Verifies scripts/mission/air_defense_approach_plan.gd against the real GM02
## map data. Pure: no scene, no user data.
## Task: docs/tasks/FLUGABWEHR_ANSCHLUSS_2026_11_14.md
const PLAN = preload("res://scripts/mission/air_defense_approach_plan.gd")
const AD = preload("res://scripts/combat/air_defense_engagement.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const ACCURACY = preload("res://scripts/mission/dropship_lz_accuracy_contract.gd")
const MAP_PATH := "res://maps/Ground_Mission02_128x128.json"
const SCENARIO_PATH := "res://data/mission_scenarios/ground_mission02_128x128.json"
var passed := 0
var failed := 0
var heights: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func height_at(cell: Vector2i) -> int:
	return int(heights.get(cell, 0))

## Plane offset of the controller's inbound start for an approach angle on GM02
## (APPROACH_OFFSETS normalised x the clamped off-map distance 3200, iso 64/32).
func inbound_offset(world_offset: Vector2) -> Vector2:
	var world: Vector2 = world_offset.normalized() * 3200.0
	return Vector2((world.y / 32.0 + world.x / 64.0) * 0.5, (world.y / 32.0 - world.x / 64.0) * 0.5)

func types(result: Dictionary) -> Array:
	var out: Array = []
	for event in Array(result.get("events", [])): out.append(String(event.type))
	return out

func run_plan(vehicles: Array, start: Vector2, lz: Vector2, crew_ready: bool, seed_text: String, integrity: int = 100, style: String = "") -> Dictionary:
	return PLAN.resolve({"vehicles": vehicles, "start_plane": start, "lz_plane": lz, "height_at": height_at, "crew_ready": crew_ready,
		"pilot_skill": 0.5, "seed": seed_text, "model_id": "cutlass", "integrity": integrity, "approach_style": style})

func _run() -> void:
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	for tile in Array(map.get("tiles", [])):
		heights[Vector2i(int(tile.grid_position.x), int(tile.grid_position.y))] = int(tile.height_level)
	var props: Array = Array(Dictionary(map.get("place_presentation", {})).get("props", []))
	var vehicles: Array = PLAN.vehicles_from_props(props, height_at)
	var ids: Array = []
	for vehicle in vehicles: ids.append(String(vehicle.unit_id))
	ids.sort()
	check(vehicles.size() == 2 and ids == ["donnerkeil", "hagel"], "GM02 carries exactly the two air-defence vehicles Hagel and Donnerkeil")
	var on_map := true
	for vehicle in vehicles:
		on_map = on_map and heights.has(vehicle.cell) and int(vehicle.ground_level) == int(heights[vehicle.cell])
	check(on_map, "each vehicle stands on a real GM02 tile and takes that tile's height level")
	var hagel: Dictionary = {}
	for vehicle in vehicles:
		if String(vehicle.unit_id) == "hagel": hagel = vehicle
	check(not hagel.is_empty() and Vector2i(hagel.cell) == HEX.round_axial(HEX.plane_to_axial(Vector2(138.6, 74.4))), "prop centre (plane x,z) converts to its hex cell")

	var scenario: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SCENARIO_PATH))
	var authoring: Dictionary = scenario.get("tactical_authoring", {})
	var armed: Dictionary = PLAN.crew_state(authoring, {"red_air_defense": 4})
	var down: Dictionary = PLAN.crew_state(authoring, {"red_air_defense": 0})
	check(bool(armed.known) and bool(armed.crew_ready) and String(armed.group_id) == "red_air_defense", "the scenario's air-defence group with fit members crews the vehicles")
	check(bool(down.known) and not bool(down.crew_ready), "the group at zero fit members leaves the vehicles uncrewed")
	check(not bool(PLAN.crew_state(authoring, {}).known) and not bool(PLAN.crew_state({}, {"red_air_defense": 4}).known), "no authoring or an unknown group makes the vehicles inert scenery")

	var samples: Array = PLAN.approach_samples(Vector2.ZERO, Vector2(10.0, 0.0))
	check(samples.size() == 4 and Vector2(samples[1]).is_equal_approx(Vector2(4.0, 0.0)) and Vector2(samples[-1]).is_equal_approx(Vector2(10.0, 0.0)), "the path is sampled every 4 hex cells plus the LZ itself")

	var pad_alpha := Vector2(63.9, 91.4)
	var quiet := true
	for offset in [Vector2(-180.0, -112.0), Vector2(-180.0, 112.0)]:
		var west: Dictionary = run_plan(vehicles, pad_alpha + inbound_offset(offset), pad_alpha, true, "west")
		quiet = quiet and bool(west.ok) and not bool(west.engaged) and bool(west.landing_allowed) and Array(west.result.events).is_empty()
	check(quiet, "approaches from NW and SW to the west landing field stay outside every envelope: no events, landing as before")

	var near_corner := Vector2(126.0, 76.0)
	var start: Vector2 = near_corner + inbound_offset(Vector2(-180.0, -112.0))
	# Fix-Runde 2: kein Stil = normal fliegt unter Beschuss weiter und bricht erst unter 50 % Rumpf ab; das Schiff startet daher mit 40 % (vorher 100 %, Abbruch beim ersten Beschuss).
	var hot: Dictionary = run_plan(vehicles, start, near_corner, true, "corner", 40)
	var hot_types: Array = types(hot.result)
	check(bool(hot.engaged) and hot_types.has("radar_contact"), "an approach that ends near the air-defence corner gets radar contact")
	check(hot_types.has("flak_volley") or hot_types.has("missile_launch"), "and is fired upon")
	check(hot_types.find("radar_contact") < maxi(hot_types.find("flak_volley"), hot_types.find("missile_launch")), "warning comes before fire")
	check(bool(hot.result.broke_off) and not bool(hot.landing_allowed) and String(hot.outcome) == "broke_off", "with no stored approach style the pilot breaks off and the landing does not start")
	check(String(hot.message).begins_with("Flugabwehr: Anflug abgebrochen, Rumpf ") and String(hot.message).ends_with(" %"), "break-off produces the German one-line message: " + String(hot.message))
	var again: Dictionary = run_plan(vehicles, start, near_corner, true, "corner", 40)
	check(JSON.stringify(again.result) == JSON.stringify(hot.result) and again.message == hot.message, "same seed gives the same result")
	var uncrewed: Dictionary = run_plan(vehicles, start, near_corner, false, "corner")
	check(not bool(uncrewed.engaged) and Array(uncrewed.result.events).is_empty() and bool(uncrewed.landing_allowed), "with the crew group at zero fit members nothing fires")

	var pressed: Dictionary = run_plan(vehicles, start, near_corner, true, "corner", 100, "aggressiv")
	check(String(pressed.decision) == AD.DECISION_PRESS_ON and String(hot.decision) == AD.DECISION_PRESS_ON, "every style presses on under fire (Fix-Runde 2); the break-off comes from the hull limit of the style")
	if bool(pressed.landing_allowed):
		check(String(pressed.message) == "Flugabwehr: %d Treffer, Rumpf %d %%" % [int(pressed.result.hits), int(pressed.hull_percent)], "pressing on keeps the landing and reports hits and hull: " + String(pressed.message))
	else:
		check(bool(pressed.result.broke_off) or bool(pressed.result.destroyed), "pressing on can still end in a forced break-off on low hull: " + String(pressed.message))
	check(PLAN.decision_for_style("aggressiv") == AD.DECISION_PRESS_ON and PLAN.decision_for_style("vorsichtig") == AD.DECISION_PRESS_ON and PLAN.decision_for_style("normal") == AD.DECISION_PRESS_ON and PLAN.decision_for_style("") == AD.DECISION_PRESS_ON, "all styles and no style press on (the hull limit of the style ends the approach)")

	var worn: Dictionary = run_plan(vehicles, start, near_corner, true, "corner", 60)
	check(float(worn.result.ship_state.hull) <= 60.0 and int(worn.hull_percent) <= 60, "a ship already at 60 percent starts the approach at 60 percent hull")

	var destroyed_plan: Dictionary = PLAN.summarize({"ok": true, "events": [{"type": "destroyed"}], "destroyed": true, "broke_off": false, "hull_fraction": 0.0, "hits": 9}, "x")
	check(not bool(destroyed_plan.landing_allowed) and int(destroyed_plan.hull_percent) == 1 and String(destroyed_plan.outcome) == "destroyed_forced_break_off", "a destroyed result becomes a forced break-off with the hull floored at 1 percent")

	var prior := {"asset_id": "craft_a", "asset_type": "dropship", "display_name": "Craft A", "state": "intact", "integrity": 100, "max_integrity": 100}
	var snapshot: Dictionary = PLAN.status_snapshot_after(prior, "craft_a", "Craft A", hot)
	check(String(snapshot.asset_id) == "craft_a" and int(snapshot.integrity) == int(hot.hull_percent) and String(snapshot.runtime_authority) == "SimulationRoot", "the status snapshot carries the hull as integrity for SimulationRoot")
	check(String(snapshot.state) in ["hit", "damaged", "threatened"] and bool(snapshot.warning_visible), "the status snapshot is a warning or hit state, never a loss: " + String(snapshot.state))
	var beside := Vector2(134.0, 70.0)
	var damaged_snapshot: Dictionary = {}
	var damaged_plan: Dictionary = {}
	for index in range(10):
		var close: Dictionary = run_plan(vehicles, beside + inbound_offset(Vector2(-180.0, -112.0)), beside, true, "close%d" % index, 100, "aggressiv")
		if int(close.hull_percent) < 100:
			damaged_plan = close
			damaged_snapshot = PLAN.status_snapshot_after({}, "craft_b", "Craft B", close)
			break
	check(not damaged_plan.is_empty() and int(damaged_snapshot.integrity) == int(damaged_plan.hull_percent) and String(damaged_snapshot.state) in ["hit", "damaged"], "pressing on to an LZ beside the battery costs hull and is stored as hit or damaged: " + String(damaged_plan.get("message", "")))
	_style_checks(vehicles, start, near_corner)
	print("AIR_DEFENSE_APPROACH_PLAN passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)


## Task docs/tasks/FLUGABWEHR_ANFLUGSTIL_REPARATUR_2026_11_15.md
func _style_checks(vehicles: Array, start: Vector2, near_corner: Vector2) -> void:
	var mapping := true
	for row in [["vorsichtig", "low", AD.DECISION_PRESS_ON], ["normal", "normal", AD.DECISION_PRESS_ON], ["aggressiv", "normal", AD.DECISION_PRESS_ON]]:
		mapping = mapping and PLAN.sanitize_style(row[0]) == row[0] and PLAN.profile_for_style(row[0]) == row[1] and PLAN.decision_for_style(row[0]) == row[2]
	check(mapping, "style -> profile and decision: vorsichtig low, normal normal, aggressiv normal; all press on (Fix-Runde 2)")
	var unknown := true
	for raw in ["", "  ", "kamikaze", "aggressive", "LOW"]:
		unknown = unknown and PLAN.sanitize_style(raw) == "normal" and PLAN.profile_for_style(raw) == "normal" and PLAN.decision_for_style(raw) == AD.DECISION_PRESS_ON and PLAN.normalize_style(raw).is_empty()
	check(unknown and PLAN.sanitize_style(" Aggressiv ") == "aggressiv", "unknown or empty style behaves as normal; case and spaces are tolerated")
	check(is_equal_approx(PLAN.lz_radius_factor_for_style("vorsichtig"), 1.5) and is_equal_approx(PLAN.lz_radius_factor_for_style("normal"), 1.0) and is_equal_approx(PLAN.lz_radius_factor_for_style("aggressiv"), 1.0) and is_equal_approx(PLAN.lz_radius_factor_for_style("x"), 1.0), "landing scatter factor is 1.5 only for vorsichtig")
	var base: Dictionary = ACCURACY.resolve_lz_command(Vector2(100.0, 50.0), "seed", 0.5, 0.5, true)
	var same: Dictionary = ACCURACY.resolve_lz_command(Vector2(100.0, 50.0), "seed", 0.5, 0.5, true, 1.0)
	var low: Dictionary = ACCURACY.resolve_lz_command(Vector2(100.0, 50.0), "seed", 0.5, 0.5, true, 1.5)
	check(is_equal_approx(float(base.lz_accuracy_radius), lerpf(96.0, 12.0, 0.5)) and JSON.stringify(base) == JSON.stringify(same), "default callers keep the old scatter radius and position: %.1f" % float(base.lz_accuracy_radius))
	check(is_equal_approx(float(low.lz_accuracy_radius), float(base.lz_accuracy_radius) * 1.5) and is_equal_approx(float(low.landing_deviation), float(base.landing_deviation) * 1.5), "factor 1.5 widens the scatter radius and the rolled deviation by 1.5")

	# Ridge battery: vehicle 4 levels above the flat valley the ship flies over.
	var flat := func(_cell: Vector2i) -> int: return 0
	var ridge: Array = [{"instance_id": "hagel@ridge", "unit_id": "hagel", "cell": Vector2i(0, 0), "ground_level": 4}]
	var ridge_context := {"vehicles": ridge, "start_plane": Vector2(-30.0, 0.0), "lz_plane": Vector2(6.0, 0.0), "height_at": flat, "crew_ready": true, "pilot_skill": 0.5, "seed": "ridge", "model_id": "cutlass", "integrity": 100}
	var ridge_normal: Dictionary = PLAN.resolve(ridge_context.merged({"approach_style": "normal"}))
	var ridge_low: Dictionary = PLAN.resolve(ridge_context.merged({"approach_style": "vorsichtig"}))
	# Fix-Runde 2: normal bricht nicht mehr beim ersten Beschuss ab, sondern erst unter 50 % Rumpf; hier bleibt der Rumpf bei 100 %.
	check(bool(ridge_normal.engaged) and types(ridge_normal.result).has("flak_volley") and bool(ridge_normal.landing_allowed), "normal approach past a ridge battery is fired upon and presses on while the hull stays above 50 percent: " + String(ridge_normal.message))
	var ridge_worn: Dictionary = PLAN.resolve(ridge_context.merged({"approach_style": "normal", "integrity": 40}, true))
	check(bool(ridge_worn.engaged) and not bool(ridge_worn.landing_allowed), "normal approach past a ridge battery with a hull already under 50 percent breaks off: " + String(ridge_worn.message))
	check(String(ridge_low.approach_profile) == "low" and not types(ridge_low.result).has("flak_volley") and int(ridge_low.hits) == 0 and bool(ridge_low.landing_allowed), "low approach stays below the ridge battery's horizon: no fire, landing allowed")
	var same_level: Dictionary = PLAN.resolve(ridge_context.merged({"approach_style": "vorsichtig", "vehicles": [{"instance_id": "hagel@valley", "unit_id": "hagel", "cell": Vector2i(0, 0), "ground_level": 0}]}, true))
	check(types(same_level.result).has("flak_volley"), "low flight does not protect against a battery on the same level")

	# GM02 corner approach per style (diagnostic print plus the decision rules).
	for style in ["vorsichtig", "normal", "aggressiv"]:
		var plan: Dictionary = run_plan(vehicles, start, near_corner, true, "corner", 100, style)
		print("GM02 corner style=%s profile=%s engaged=%s hits=%d outcome=%s landing=%s" % [style, plan.approach_profile, plan.engaged, int(plan.hits), plan.outcome, plan.landing_allowed])
		# Fix-Runde 2: alle Stile pressen durch, solange der Rumpf ueber der Stilgrenze bleibt.
		check(String(plan.decision) == AD.DECISION_PRESS_ON, style + " presses on on the GM02 corner approach")
	_limit_checks(vehicles, start, near_corner)


## Fix-Runde 2 (E): der Stil kommt ueber den PLAN (plan.resolve -> resolve_approach) an die Abbruchgrenze.
## Je Stil ein Anflug unter Feuer knapp ueber der Grenze (kommt durch) und knapp darunter (bricht ab);
## aggressiv mit Rumpf zwischen 10 und 35 % kommt durch.
func _limit_checks(vehicles: Array, start: Vector2, near_corner: Vector2) -> void:
	for row in [["vorsichtig", 65], ["normal", 50], ["aggressiv", 10]]:
		var style: String = row[0]
		var limit: int = row[1]
		var above: Dictionary = run_plan(vehicles, start, near_corner, true, "corner", limit + 1, style)
		var below: Dictionary = run_plan(vehicles, start, near_corner, true, "corner", limit - 1, style)
		check(bool(above.engaged) and bool(above.landing_allowed) and not bool(above.result.broke_off), "%s: under fire one point above %d percent hull the approach goes on: %s" % [style, limit, String(above.message)])
		check(bool(below.engaged) and not bool(below.landing_allowed) and bool(below.result.broke_off), "%s: under fire one point below %d percent hull the approach breaks off: %s" % [style, limit, String(below.message)])
	for hull in [11, 20, 30, 34]:
		var bold: Dictionary = run_plan(vehicles, start, near_corner, true, "corner", hull, "aggressiv")
		check(bool(bold.engaged) and bool(bold.landing_allowed), "aggressiv with %d percent hull (between 10 and 35) under fire gets through: %s" % [hull, String(bold.message)])
