extends SceneTree
## Abschnitt LA: Anflugarten Steil / Normal / Tief (Regelkern, ohne Szene).
## Prueft scripts/mission/air_defense_approach_plan.gd: Normal rechnet wie vor LA,
## Tief laesst das Gelaende die Flugabwehr verdecken, Steil verkuerzt das Zeitfenster
## im Wirkbereich, Steil und Tief tragen ein Unfallrisiko pmax x (1 - Pilot)^2.
## Alle Wuerfe laufen ueber feste Samen; kein Zufall im Test.
const PLAN = preload("res://scripts/mission/air_defense_approach_plan.gd")
const AD = preload("res://scripts/combat/air_defense_engagement.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const MAP_PATH := "res://maps/Ground_Mission02_128x128.json"
var passed := 0
var failed := 0
var heights: Dictionary = {}
var ridge: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func height_at(cell: Vector2i) -> int:
	return int(heights.get(cell, 0))

func ridge_height_at(cell: Vector2i) -> int:
	return int(ridge.get(cell, 0))

func flat_height_at(_cell: Vector2i) -> int:
	return 0

func inbound_offset(world_offset: Vector2) -> Vector2:
	var world: Vector2 = world_offset.normalized() * 3200.0
	return Vector2((world.y / 32.0 + world.x / 64.0) * 0.5, (world.y / 32.0 - world.x / 64.0) * 0.5)

func cell_plane(cell: Vector2i) -> Vector2:
	return HEX.axial_to_plane(Vector2(cell))

## Fingerprint of everything LA must leave untouched for the approach path "normal".
func digest(plan: Dictionary) -> String:
	var text: String = JSON.stringify([plan.result, plan.message, plan.outcome, plan.hull_percent, plan.landing_allowed, plan.volley_count, plan.engaged, plan.decision, plan.approach_profile])
	return "%d:%d" % [text.hash(), text.length()]

func types(result: Dictionary, unit: String = "") -> Array:
	var out: Array = []
	for event in Array(result.get("events", [])):
		if unit.is_empty() or String(event.get("unit", "")) == unit:
			out.append(String(event.type))
	return out

## Samples at which the (single) station has the ship inside its WEAPON range (min..max), counted here
## independently of exposure_window.
func in_range_samples(vehicles: Array, start: Vector2, lz: Vector2) -> int:
	var count := 0
	for sample in PLAN.approach_samples(start, lz):
		var cell: Vector2i = PLAN.plane_to_cell(Vector2(sample))
		for vehicle in vehicles:
			var unit: Dictionary = AD.unit(String(vehicle.unit_id))
			var distance: int = HEX.distance(Vector2i(vehicle.cell), cell)
			if distance >= int(unit.get("weapon_min_range_hex", 0)) and distance <= int(unit.get("weapon_range_hex", 0)):
				count += 1
				break
	return count

## The batteries' firing opportunities of one approach, without any dice that could change them: the
## ship has a hull no hit can break, always presses on, and every flak volley / missile launch of the
## resolver's event list is one opportunity. Returns {instance_id: count}.
func opportunities(context: Dictionary) -> Dictionary:
	var volleys: Array = PLAN.approach_volleys(context).volleys
	var ship: Dictionary = PLAN.ship_for("cutlass", 100)
	var state: Dictionary = ship.state
	state.hull = 1.0e9
	state.hull_capacity = 1.0e9
	var result: Dictionary = AD.resolve_approach({"seed": "opportunities", "pilot_skill": 0.5, "ship_model": "cutlass", "ship_stats": ship.stats, "ship_state": state, "decision": AD.DECISION_PRESS_ON, "volleys": volleys})
	var counts: Dictionary = {}
	for event in Array(result.get("events", [])):
		if String(event.type) in ["flak_volley", "missile_launch"]:
			counts[String(event.unit)] = int(counts.get(String(event.unit), 0)) + 1
	return counts

func _run() -> void:
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	for tile in Array(map.get("tiles", [])):
		heights[Vector2i(int(tile.grid_position.x), int(tile.grid_position.y))] = int(tile.height_level)
	var vehicles: Array = PLAN.vehicles_from_props(Array(Dictionary(map.get("place_presentation", {})).get("props", [])), height_at)
	_normal_unchanged(vehicles)
	_tief_masking()
	_tief_real_heights(vehicles)
	_station_cover_counts_weapon_range()
	_steil_window()
	_steil_per_battery_window()
	_steil_gm02_counts(vehicles)
	_accident_formula()
	_accident_without_flak_and_hull()
	_accident_text_after_flak()
	_pilot_skill_per_model()
	_repeat_and_data()
	print("APPROACH_PROFILE_RULES passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

## (a) Normal is bit-identical to the pre-LA result for three existing cases.
func _normal_unchanged(vehicles: Array) -> void:
	var near_corner := Vector2(126.0, 76.0)
	var start: Vector2 = near_corner + inbound_offset(Vector2(-180.0, -112.0))
	var base := {"vehicles": vehicles, "start_plane": start, "lz_plane": near_corner, "height_at": height_at, "crew_ready": true, "pilot_skill": 0.5, "seed": "corner", "model_id": "cutlass", "integrity": 100}
	var ridge_vehicle: Array = [{"instance_id": "hagel@ridge", "unit_id": "hagel", "cell": Vector2i(0, 0), "ground_level": 4}]
	var ridge_base := {"vehicles": ridge_vehicle, "start_plane": Vector2(-30.0, 0.0), "lz_plane": Vector2(6.0, 0.0), "height_at": flat_height_at, "crew_ready": true, "pilot_skill": 0.5, "seed": "ridge", "model_id": "cutlass", "integrity": 100}
	var cases := [
		["GM02 corner, no style", base.merged({"approach_style": ""}), "1668426422:1328"],
		["GM02 corner, aggressiv", base.merged({"approach_style": "aggressiv"}), "908210372:1362"],
		["ridge battery, normal style", ridge_base.merged({"approach_style": "normal"}), "231239791:1176"],
		["ridge battery, vorsichtig", ridge_base.merged({"approach_style": "vorsichtig"}), "450075823:698"],
	]
	for entry in cases:
		var context: Dictionary = entry[1]
		check(digest(PLAN.resolve(context)) == String(entry[2]), "(a) path omitted = pre-LA result: " + String(entry[0]))
		check(digest(PLAN.resolve(context.merged({"approach_path": "normal"}))) == String(entry[2]), "(a) path normal = pre-LA result: " + String(entry[0]))
	var normal_plan: Dictionary = PLAN.resolve(base.merged({"approach_style": "", "approach_path": "normal", "seed": "corner"}))
	check(String(normal_plan.get("approach_path", "")) == "normal" and not bool(Dictionary(normal_plan.get("path_report", {})).get("accident", {}).get("possible", false)), "(a) normal carries no accident chance")

## (b) Tief: terrain masks batteries; open batteries fire as before; flat map unchanged.
func _tief_masking() -> void:
	var battery_a := {"instance_id": "hagel@A", "unit_id": "hagel", "cell": Vector2i(0, -4), "ground_level": 0}
	var battery_b := {"instance_id": "hagel@B", "unit_id": "hagel", "cell": Vector2i(0, 4), "ground_level": 0}
	var stations: Array = [battery_a, battery_b]
	ridge.clear()
	for dq in range(-3, 4):
		for dr in range(-3, 4):
			var cell := Vector2i(0, -4) + Vector2i(dq, dr)
			if HEX.distance(cell, Vector2i(0, -4)) == 2:
				ridge[cell] = 8
	var context := {"vehicles": stations, "start_plane": cell_plane(Vector2i(-40, 0)), "lz_plane": cell_plane(Vector2i(6, 0)), "height_at": ridge_height_at, "crew_ready": true,
		"pilot_skill": 0.5, "seed": "mask", "model_id": "cutlass", "integrity": 100, "approach_style": "aggressiv"}
	var normal: Dictionary = PLAN.resolve(context.merged({"approach_path": "normal"}))
	var tief: Dictionary = PLAN.resolve(context.merged({"approach_path": "tief"}))
	check(types(normal.result, "hagel@A").has("flak_volley") and types(normal.result, "hagel@B").has("flak_volley"), "(b) normal: both batteries fire, the ridge changes nothing")
	check(types(tief.result, "hagel@B").has("flak_volley"), "(b) tief: the battery with a clear view still fires")
	check(not types(tief.result, "hagel@A").has("flak_volley") and types(tief.result, "hagel@A").has("masked"), "(b) tief: the battery behind the ridge is masked and does not engage")
	var report: Dictionary = Dictionary(tief.get("path_report", {}))
	check(int(report.get("stations_total", -1)) == 2 and Array(report.get("stations_masked", [])) == ["hagel@A"], "(b) the result names which station was masked: " + str(report.get("stations_masked")))
	check(String(tief.message).contains("Tiefflug: 1 von 2 Stellungen durch Gelände verdeckt."), "(b) the card sentence reports the masking: " + String(tief.message))
	check(String(tief.approach_profile) == "low", "(b) tief flies at the low profile from the data")
	context["height_at"] = flat_height_at
	var flat_normal: Dictionary = PLAN.resolve(context.merged({"approach_path": "normal"}))
	var flat_tief: Dictionary = PLAN.resolve(context.merged({"approach_path": "tief"}))
	check(JSON.stringify(flat_normal.result) == JSON.stringify(flat_tief.result) and Array(flat_tief.path_report.stations_masked).is_empty(), "(b) on a flat map tief changes nothing about the air defence")
	# A ridge between battery and flight line that is lower than both ends does not mask.
	for cell in ridge.keys():
		ridge[cell] = 0
	context["height_at"] = ridge_height_at
	var low_ridge: Dictionary = PLAN.resolve(context.merged({"approach_path": "tief"}))
	check(types(low_ridge.result, "hagel@A").has("flak_volley"), "(b) a ridge as low as the ground masks nothing")

## (c) Steil keeps only exposure_factor of the time inside each battery's WEAPON range.
func _steil_window() -> void:
	var stations: Array = [{"instance_id": "hagel@A", "unit_id": "hagel", "cell": Vector2i(0, -4), "ground_level": 0}]
	var start: Vector2 = cell_plane(Vector2i(-40, 0))
	var lz: Vector2 = cell_plane(Vector2i(6, 0))
	var context := {"vehicles": stations, "start_plane": start, "lz_plane": lz, "height_at": flat_height_at, "crew_ready": true, "pilot_skill": 0.5, "seed": "steil", "model_id": "cutlass", "integrity": 100, "approach_style": "aggressiv"}
	var factor: float = float(Dictionary(PLAN.path_rules("steil")).get("exposure_factor", -1.0))
	check(is_equal_approx(factor, 0.6), "(c) steil exposure factor in the data starts at 0.6")
	var total: int = in_range_samples(stations, start, lz)
	var normal: Dictionary = PLAN.resolve(context.merged({"approach_path": "normal"}))
	var steil: Dictionary = PLAN.resolve(context.merged({"approach_path": "steil"}))
	var window: Dictionary = Dictionary(Dictionary(steil.get("path_report", {})).get("window", {}))
	var kept: int = ceili(float(total) * factor)
	check(total >= 4 and int(window.get("in_range", -1)) == total and int(window.get("kept", -1)) == kept and kept < total, "(c) steil keeps ceil(%d x %.1f) = %d of %d volleys inside the weapon range: %s" % [total, factor, kept, total, str(window)])
	check(int(steil.volley_count) == int(normal.volley_count), "(c) steil flies the whole approach (%d volleys, as normal's %d); only the battery's window is cut" % [int(steil.volley_count), int(normal.volley_count)])
	var normal_fire: int = types(normal.result).count("flak_volley")
	var steil_fire: int = types(steil.result).count("flak_volley")
	check(steil_fire < normal_fire, "(c) fewer opportunities to fire: %d flak volleys against %d" % [steil_fire, normal_fire])
	check(String(steil.approach_profile) == "normal" and Array(steil.path_report.stations_masked).is_empty(), "(c) steil flies at normal height and takes no terrain cover")

## (b2) Tief on the REAL GM02 heights (the map file is only read): from LZ (93,73) on the NW approach
## the Hagel at (96,86) has the ship in weapon range but no clear line to it; the Donnerkeil still sees it.
func _tief_real_heights(vehicles: Array) -> void:
	var lz: Vector2 = cell_plane(Vector2i(93, 73))
	var context := {"vehicles": vehicles, "start_plane": lz + inbound_offset(Vector2(-180.0, -112.0)), "lz_plane": lz, "height_at": height_at, "crew_ready": true,
		"pilot_skill": 0.5, "seed": "tiefcase", "model_id": "cutlass", "integrity": 100, "approach_style": "aggressiv"}
	var normal: Dictionary = PLAN.resolve(context.merged({"approach_path": "normal"}))
	var tief: Dictionary = PLAN.resolve(context.merged({"approach_path": "tief"}))
	var report: Dictionary = Dictionary(tief.get("path_report", {}))
	check(Array(report.get("stations_masked", [])) == ["hagel@96,86"] and Array(report.get("stations_in_range", [])).size() == 2, "(b2) GM02 real heights: only the Hagel is masked, both batteries had the ship in weapon range: " + str(report.get("stations_masked")))
	check(types(normal.result, "hagel@96,86").has("flak_volley"), "(b2) the same approach flown as normal: the Hagel fires")
	check(not types(tief.result, "hagel@96,86").has("flak_volley") and types(tief.result, "hagel@96,86").has("masked"), "(b2) flown as tief: the Hagel is masked by the real hills and does not fire")
	check(String(tief.message).contains("Tiefflug: 1 von 2 Stellungen durch Gelände verdeckt."), "(b2) the card sentence counts the stations that had the ship in weapon range: " + String(tief.message))
	check(int(tief.volley_count) == int(normal.volley_count) and String(tief.approach_profile) == "low", "(b2) tief flies the same %d volleys as normal, at the low profile" % int(tief.volley_count))

## (b3) "N of M stations masked" counts the stations that had the ship in their WEAPON range, not their radar range.
func _station_cover_counts_weapon_range() -> void:
	var vehicles: Array = [{"instance_id": "a", "unit_id": "hagel"}, {"instance_id": "b", "unit_id": "donnerkeil"}, {"instance_id": "c", "unit_id": "hagel"}]
	var shut := {"in_reach": true, "in_weapon_range": true, "has_line_of_sight": false}
	var open := {"in_reach": true, "in_weapon_range": true, "has_line_of_sight": true}
	var radar_only := {"in_reach": true, "in_weapon_range": false, "has_line_of_sight": false}
	var volleys: Array = [
		{"contacts": {"a": shut, "b": radar_only, "c": open}},
		{"contacts": {"a": shut, "b": radar_only, "c": shut}},
	]
	var cover: Dictionary = PLAN.station_cover(vehicles, volleys)
	check(Array(cover.masked) == ["a"] and Array(cover.in_range) == ["a", "c"], "(b3) a station blocked only outside its weapon range is neither masked nor counted; one with a clear volley is not masked: " + str(cover))
	check(PLAN.masked_stations(vehicles, volleys) == ["a"], "(b3) masked_stations gives the same list")
	check(PLAN.in_weapon_range("donnerkeil", 5) == false and PLAN.in_weapon_range("donnerkeil", 6) and PLAN.in_weapon_range("donnerkeil", 45) and not PLAN.in_weapon_range("donnerkeil", 46) and PLAN.in_weapon_range("hagel", 0) and PLAN.in_weapon_range("hagel", 16) and not PLAN.in_weapon_range("hagel", 17), "(b3) weapon range is min..max from the unit data (Donnerkeil 6..45, Hagel 0..16)")

## (c2) The Steil window is cut PER BATTERY from its weapon range: n >= 3 volleys always lose one, 1 or 2 lose none.
func _steil_per_battery_window() -> void:
	var station: Array = [{"instance_id": "hagel@W", "unit_id": "hagel", "cell": Vector2i(0, 0), "ground_level": 0}]
	var cut_ok := true
	var spared_ok := true
	var shape_ok := true
	var failed_n: Array = []
	for n in range(1, 41):
		var samples: Array = []
		for _i in range(5):
			samples.append(cell_plane(Vector2i(40, 0)))
		for _i in range(n):
			samples.append(cell_plane(Vector2i(8, 0)))
		samples.append(cell_plane(Vector2i(40, 0)))
		var window: Dictionary = PLAN.exposure_window(samples, station, 0.6)
		var entry: Dictionary = Dictionary(window.stations).get("hagel@W", {})
		var kept: int = int(entry.get("kept", -1))
		var dropped: Array = Array(entry.get("dropped", []))
		shape_ok = shape_ok and int(entry.get("in_range", -1)) == n and kept == ceili(float(n) * 0.6) and dropped.size() == n - kept
		if n >= 3:
			cut_ok = cut_ok and kept < n and dropped.size() >= 1
		else:
			spared_ok = spared_ok and kept == n and dropped.is_empty()
		if not (shape_ok and cut_ok and spared_ok) and failed_n.is_empty():
			failed_n.append(n)
		# The dropped volleys are the FIRST ones of the battery's zone (indices 5 ..).
		for index in range(dropped.size()):
			shape_ok = shape_ok and int(dropped[index]) == 5 + index
	check(shape_ok and cut_ok and spared_ok, "(c2) for n = 1..40 volleys in weapon range: kept = ceil(0.6 n), n >= 3 loses at least one, n = 1 and 2 lose none, the first ones are dropped (first failing n: %s)" % str(failed_n))
	var untouched: Dictionary = PLAN.exposure_window([cell_plane(Vector2i(8, 0)), cell_plane(Vector2i(8, 0)), cell_plane(Vector2i(8, 0))], station, 1.0)
	var floor_one: Dictionary = PLAN.exposure_window([cell_plane(Vector2i(8, 0)), cell_plane(Vector2i(8, 0)), cell_plane(Vector2i(8, 0))], station, 0.0)
	check(int(untouched.kept) == 3 and int(floor_one.kept) == 1, "(c2) factor 1.0 keeps everything, factor 0 keeps one volley")
	# Two batteries with different weapon ranges: each window starts where ITS weapon reaches the ship.
	var two: Array = [{"instance_id": "hagel@H", "unit_id": "hagel", "cell": Vector2i(0, -4), "ground_level": 0}, {"instance_id": "donnerkeil@D", "unit_id": "donnerkeil", "cell": Vector2i(0, -6), "ground_level": 0}]
	var start: Vector2 = cell_plane(Vector2i(-60, 0))
	var lz: Vector2 = cell_plane(Vector2i(6, 0))
	var samples2: Array = PLAN.approach_samples(start, lz)
	var window2: Dictionary = PLAN.exposure_window(samples2, two, 0.6)
	var zones: Dictionary = {"hagel@H": [], "donnerkeil@D": []}
	for index in range(samples2.size()):
		var cell: Vector2i = PLAN.plane_to_cell(Vector2(samples2[index]))
		if HEX.distance(Vector2i(0, -4), cell) <= 16:
			zones["hagel@H"].append(index)
		var d: int = HEX.distance(Vector2i(0, -6), cell)
		if d >= 6 and d <= 45:
			zones["donnerkeil@D"].append(index)
	var hagel: Dictionary = Dictionary(window2.stations).get("hagel@H", {})
	var donnerkeil: Dictionary = Dictionary(window2.stations).get("donnerkeil@D", {})
	check(int(hagel.get("in_range", -1)) == Array(zones["hagel@H"]).size() and int(donnerkeil.get("in_range", -1)) == Array(zones["donnerkeil@D"]).size() and int(donnerkeil.in_range) > int(hagel.in_range), "(c2) each battery counts its own weapon-range volleys: Hagel %d, Donnerkeil %d" % [int(hagel.get("in_range", -1)), int(donnerkeil.get("in_range", -1))])
	var hagel_first_kept: int = int(Array(zones["hagel@H"])[Array(hagel.dropped).size()])
	var donnerkeil_first_kept: int = int(Array(zones["donnerkeil@D"])[Array(donnerkeil.dropped).size()])
	check(Array(hagel.dropped) == Array(zones["hagel@H"]).slice(0, Array(hagel.dropped).size()) and hagel_first_kept > int(Array(zones["hagel@H"])[0]) and donnerkeil_first_kept > int(Array(zones["donnerkeil@D"])[0]) and hagel_first_kept > donnerkeil_first_kept, "(c2) the Hagel's kept window starts at volley %d, the Donnerkeil's at %d: not at the radar range of the longest-reaching battery" % [hagel_first_kept, donnerkeil_first_kept])
	# The volleys the resolver gets: dropped volleys carry no contact for that battery only.
	var volleys: Array = PLAN.build_volleys(two, samples2, flat_height_at, true, "normal", false, PLAN.silenced_volleys(window2))
	var silenced_hagel := 0
	var silenced_wrong := 0
	for index in range(volleys.size()):
		var contacts: Dictionary = Dictionary(volleys[index]).contacts
		if bool(Dictionary(contacts["hagel@H"]).get("outside_window", false)):
			silenced_hagel += 1
			silenced_wrong += 0 if Array(hagel.dropped).has(index) else 1
		if bool(Dictionary(contacts["donnerkeil@D"]).get("outside_window", false)) != Array(donnerkeil.dropped).has(index):
			silenced_wrong += 1
	check(silenced_hagel == Array(hagel.dropped).size() and silenced_wrong == 0, "(c2) exactly the dropped volleys of each battery are silenced (%d for the Hagel)" % silenced_hagel)
	# A window with nothing in weapon range cuts nothing.
	var far: Dictionary = PLAN.exposure_window([cell_plane(Vector2i(60, 0)), cell_plane(Vector2i(61, 0))], station, 0.6)
	check(Dictionary(far.stations).is_empty() and int(far.kept) == 0, "(c2) no battery in weapon range: nothing to cut")

## (c3) Steil on the REAL GM02 batteries, counted without dice (the map file is only read): every landing cell within 30 of
## a battery x the four approach angles. Hagel must lose at least a quarter of its firing opportunities; the Donnerkeil
## (two missiles, reload 3) reaches 25 % only with a smaller factor, which is measured here as well.
func _steil_gm02_counts(vehicles: Array) -> void:
	var angles: Array = [Vector2(-180.0, -112.0), Vector2(180.0, -112.0), Vector2(-180.0, 112.0), Vector2(180.0, 112.0)]
	var cells: Array = []
	for cell in heights.keys():
		for vehicle in vehicles:
			if HEX.distance(Vector2i(vehicle.cell), cell) <= 30:
				cells.append(cell)
				break
	cells.sort()
	var half_rules: Dictionary = AD.definition().duplicate(true)
	half_rules.approach_paths.paths.steil.exposure_factor = 0.5
	var sums := {"normal": {"hagel": 0, "donnerkeil": 0}, "steil": {"hagel": 0, "donnerkeil": 0}, "half": {"hagel": 0, "donnerkeil": 0}}
	var combos := 0
	for index in range(0, cells.size(), 6):
		var lz: Vector2 = cell_plane(cells[index])
		for world_offset in angles:
			var context := {"vehicles": vehicles, "start_plane": lz + inbound_offset(world_offset), "lz_plane": lz, "height_at": height_at, "crew_ready": true, "pilot_skill": 0.5, "seed": "scan", "model_id": "cutlass", "integrity": 100, "approach_style": "aggressiv"}
			var normal: Dictionary = opportunities(context.merged({"approach_path": "normal"}))
			var steil: Dictionary = opportunities(context.merged({"approach_path": "steil"}))
			var half: Dictionary = opportunities(context.merged({"approach_path": "steil", "rules": half_rules}))
			combos += 1
			for vehicle in vehicles:
				var id: String = String(vehicle.instance_id)
				var kind: String = String(vehicle.unit_id)
				sums.normal[kind] += int(normal.get(id, 0))
				sums.steil[kind] += int(steil.get(id, 0))
				sums.half[kind] += int(half.get(id, 0))
	var cut := {}
	for key in ["steil", "half"]:
		for kind in ["hagel", "donnerkeil"]:
			cut["%s_%s" % [key, kind]] = 100.0 * (1.0 - float(sums[key][kind]) / maxf(float(sums.normal[kind]), 1.0))
	print("GM02 firing opportunities over %d landing zone x angle combinations (no dice):" % combos)
	for kind in ["hagel", "donnerkeil"]:
		print("  ", kind, ": normal ", sums.normal[kind], ", steil 0.6 ", sums.steil[kind], " (-", snappedf(cut["steil_" + kind], 0.1), " %), steil 0.5 ", sums.half[kind], " (-", snappedf(cut["half_" + kind], 0.1), " %)")
	check(combos >= 1500 and int(sums.normal.hagel) > 1000 and int(sums.normal.donnerkeil) > 1000, "(c3) the count covers %d combinations with %d Hagel and %d Donnerkeil opportunities in normal" % [combos, int(sums.normal.hagel), int(sums.normal.donnerkeil)])
	check(float(cut.steil_hagel) >= 25.0, "(c3) steil 0.6 takes %.1f %% of the Hagel's firing opportunities (target 25 %%)" % float(cut.steil_hagel))
	check(float(cut.steil_donnerkeil) >= 15.0, "(c3) steil 0.6 takes %.1f %% of the Donnerkeil's firing opportunities (it has 2 missiles; the 25 %% target is not reached at 0.6)" % float(cut.steil_donnerkeil))
	check(float(cut.half_hagel) >= 25.0 and float(cut.half_donnerkeil) >= 25.0, "(c3) with the factor 0.5 both kinds lose at least 25 %%: Hagel %.1f %%, Donnerkeil %.1f %%" % [float(cut.half_hagel), float(cut.half_donnerkeil)])
	print("NOTE (c3): the 25 %% target for the Donnerkeil is %s at 0.6 (%.1f %%); the factor 0.5 gives %.1f %%." % ["reached" if float(cut.steil_donnerkeil) >= 25.0 else "NOT reached", float(cut.steil_donnerkeil), float(cut.half_donnerkeil)])

## (d) Accident chance = pmax x (1 - pilot)^2; zero for normal.
func _accident_formula() -> void:
	var cases := [["steil", 0.0, 0.15], ["steil", 0.5, 0.0375], ["steil", 0.9, 0.0015], ["tief", 0.0, 0.25], ["tief", 0.5, 0.0625], ["tief", 0.9, 0.0025]]
	for entry in cases:
		var probability: float = PLAN.accident_probability(String(entry[0]), float(entry[1]))
		check(absf(probability - float(entry[2])) < 0.00001, "(d) %s, pilot %.1f: chance %.4f" % [entry[0], entry[1], probability])
	check(PLAN.accident_probability("normal", 0.0) == 0.0 and not bool(PLAN.accident_check("normal", 0.0, "x").possible), "(d) normal has no accident chance, whatever the pilot")
	var check_result: Dictionary = PLAN.accident_check("tief", 0.5, "seed-d")
	check(absf(float(check_result.probability) - 0.0625) < 0.00001 and float(check_result.roll) >= 0.0 and float(check_result.roll) < 1.0 and bool(check_result.occurred) == (float(check_result.roll) < float(check_result.probability)), "(d) the result names the roll and the threshold: roll %.4f against %.4f" % [float(check_result.roll), float(check_result.probability)])

func find_accident_seed(path: String, pilot: float, wanted: bool) -> String:
	for index in range(2000):
		var seed_text := "lasearch-%d" % index
		if bool(PLAN.accident_check(path, pilot, seed_text).occurred) == wanted:
			return seed_text
	return ""

## (e) accident without any air defence, (f) hull loss bounds and the 1 % floor.
func _accident_without_flak_and_hull() -> void:
	var seed_text: String = find_accident_seed("tief", 0.0, true)
	check(not seed_text.is_empty(), "(e) a fixed seed with an accident for tief and pilot 0.0 exists")
	var context := {"vehicles": [], "start_plane": cell_plane(Vector2i(-40, 0)), "lz_plane": cell_plane(Vector2i(6, 0)), "height_at": flat_height_at, "crew_ready": false,
		"pilot_skill": 0.0, "seed": seed_text, "model_id": "cutlass", "integrity": 100, "approach_style": "", "approach_path": "tief"}
	var plan: Dictionary = PLAN.resolve(context)
	var accident: Dictionary = Dictionary(Dictionary(plan.get("path_report", {})).get("accident", {}))
	check(bool(plan.ok) and not bool(plan.engaged) and bool(accident.get("occurred", false)) and bool(plan.landing_allowed), "(e) no air defence at the site and the accident still happens; the landing goes on")
	check(String(plan.outcome) == "accident" and int(plan.hull_percent) == 100 - int(accident.hull_loss), "(e) the outcome is an accident and the hull is down by the rolled loss: " + String(plan.message))
	check(String(plan.message) == "Unfall im Tiefflug: Rumpf -%d %%." % int(accident.hull_loss), "(e) the card sentence names the accident: " + String(plan.message))
	var snapshot: Dictionary = PLAN.status_snapshot_after({}, "craft_x", "Craft X", plan)
	check(int(snapshot.integrity) == int(plan.hull_percent) and String(snapshot.state) in ["hit", "damaged"], "(e) the status snapshot stores the accident damage: %s / %s" % [str(snapshot.integrity), str(snapshot.state)])
	var quiet_seed: String = find_accident_seed("tief", 0.0, false)
	var quiet: Dictionary = PLAN.resolve(context.merged({"seed": quiet_seed}, true))
	check(not bool(quiet.engaged) and String(quiet.outcome) == "none" and String(quiet.message).is_empty() and int(quiet.hull_percent) == 100, "(e) a seed without accident leaves the approach untouched and silent")
	var losses: Dictionary = {}
	var floor_ok := true
	var bounds_ok := true
	for index in range(400):
		var result: Dictionary = PLAN.accident_check("steil", 0.0, "loss-%d" % index)
		if bool(result.occurred):
			var loss: int = int(result.hull_loss)
			losses[loss] = true
			bounds_ok = bounds_ok and loss >= 20 and loss <= 40
	check(bounds_ok and losses.size() >= 5, "(f) hull loss stays within 20..40 points and varies: %d distinct values" % losses.size())
	# Floor: a loss larger than the hull (limits widened to 100 points) leaves 1 %, never 0.
	var wide: Dictionary = AD.definition().duplicate(true)
	wide.approach_paths.accident.hull_loss_min_percent = 100
	wide.approach_paths.accident.hull_loss_max_percent = 100
	var worn: Dictionary = PLAN.resolve(context.merged({"rules": wide}))
	check(int(worn.hull_percent) == 1 and String(worn.outcome) == "accident", "(f) an accident never takes the hull under 1 %%: %d" % int(worn.hull_percent))
	var worn_snapshot: Dictionary = PLAN.status_snapshot_after({}, "craft_x", "Craft X", worn)
	check(int(worn_snapshot.integrity) == 1 and String(worn.message) == "Unfall im Tiefflug: Rumpf -99 %.", "(f) the stored integrity is 1 and the sentence names the applied loss: %s / %s" % [str(worn_snapshot.integrity), String(worn.message)])
	# An approach the air defence breaks off does not roll the accident.
	var hot_context := {"vehicles": [{"instance_id": "hagel@C", "unit_id": "hagel", "cell": Vector2i(0, -2), "ground_level": 0}], "start_plane": cell_plane(Vector2i(-40, 0)), "lz_plane": cell_plane(Vector2i(6, 0)),
		"height_at": flat_height_at, "crew_ready": true, "pilot_skill": 0.0, "seed": seed_text, "model_id": "cutlass", "integrity": 100, "approach_style": "", "approach_path": "tief"}
	var hot: Dictionary = PLAN.resolve(hot_context)
	check(not bool(hot.landing_allowed) and not bool(Dictionary(Dictionary(hot.path_report).get("accident", {})).get("occurred", false)), "(f) a broken-off approach never lands, so it does not roll an accident")

## (f2) K2: flak hits and an accident in one approach: the card names the hull ONCE, after the accident.
func _accident_text_after_flak() -> void:
	var stations: Array = [{"instance_id": "hagel@A", "unit_id": "hagel", "cell": Vector2i(0, -4), "ground_level": 0}]
	var context := {"vehicles": stations, "start_plane": cell_plane(Vector2i(-40, 0)), "lz_plane": cell_plane(Vector2i(6, 0)), "height_at": flat_height_at, "crew_ready": true, "pilot_skill": 0.0,
		"model_id": "cutlass", "integrity": 100, "approach_style": "aggressiv", "approach_path": "tief"}
	var found := false
	for index in range(2000):
		var seed_text := "k2-%d" % index
		var plan: Dictionary = PLAN.resolve(context.merged({"seed": seed_text}, true))
		if not (bool(plan.accident_occurred) and bool(plan.engaged) and bool(plan.landing_allowed) and int(plan.hits) > 0):
			continue
		# On a flat map tief changes nothing about the flak: normal gives the hull BEFORE the accident.
		var normal: Dictionary = PLAN.resolve(context.merged({"seed": seed_text, "approach_path": "normal"}, true))
		var loss: int = int(plan.path_report.accident.hull_loss_applied)
		var expected: String = "Flugabwehr: %d Treffer. Unfall im Tiefflug: Rumpf -%d %%, jetzt %d %%." % [int(plan.hits), loss, int(plan.hull_percent)]
		check(String(plan.message) == expected, "(f2) flak hits plus accident read '%s'" % String(plan.message))
		check(int(plan.hull_percent) == maxi(int(normal.hull_percent) - loss, 1) and int(plan.hull_percent) < int(normal.hull_percent) and not String(plan.message).contains("Treffer, Rumpf"), "(f2) the stated hull is the one AFTER the accident (%d), not the flak-only value (%d)" % [int(plan.hull_percent), int(normal.hull_percent)])
		check(String(plan.outcome) == "pressed_on" and bool(plan.landing_allowed), "(f2) the outcome stays the flak outcome and the landing goes on")
		found = true
		break
	check(found, "(f2) a fixed seed with flak hits and an accident exists")

## (g) the pilot value belongs to the ship: fighter_piloting for the fighter, dropship_piloting for the dropship.
func _pilot_skill_per_model() -> void:
	var skills := {"dropship_piloting": 0.9, "fighter_piloting": 0.1}
	check(PLAN.pilot_skill_for_craft_type("dropship", skills) == 0.9 and PLAN.pilot_skill_for_craft_type("fighter", skills) == 0.1, "(g) a dropship reads dropship_piloting, a fighter reads fighter_piloting (by craft_type, no model name in the code)")
	check(PLAN.pilot_skill_for_craft_type("", skills) == 0.9 and PLAN.pilot_skill_for_craft_type("freighter", skills) == 0.9 and PLAN.pilot_skill_for_craft_type("FIGHTER ", skills) == 0.1, "(g) an unknown or empty craft_type keeps the old dropship value; fighter is matched without case and blanks")
	# K1: campaign pilots carry only dropship_piloting (fighter_piloting stays unset = -1): the fighter then flies with that value as before LA.
	check(PLAN.pilot_skill_for_craft_type("fighter", {"dropship_piloting": 0.7, "fighter_piloting": -1.0}) == 0.7 and PLAN.pilot_skill_for_craft_type("fighter", {"dropship_piloting": 0.7}) == 0.7, "(g) a fighter without fighter_piloting falls back to dropship_piloting, not to 0.5")
	check(PLAN.pilot_skill_for_craft_type("fighter", {"dropship_piloting": -1.0, "fighter_piloting": -1.0}) == 0.5 and PLAN.pilot_skill_for_craft_type("fighter", {}) == 0.5 and PLAN.pilot_skill_for_craft_type("dropship", {"fighter_piloting": 0.8}) == 0.5, "(g) with neither value (or only the other craft's) the value is 0.5 as before")
	check(PLAN.pilot_skill_for_craft_type("dropship", {"dropship_piloting": -1.0, "fighter_piloting": 0.8}) == 0.5, "(g) a dropship never reads fighter_piloting")
	var steil_fighter: float = PLAN.accident_probability("steil", PLAN.pilot_skill_for_craft_type("fighter", skills))
	var steil_dropship: float = PLAN.accident_probability("steil", PLAN.pilot_skill_for_craft_type("dropship", skills))
	check(absf(steil_fighter - 0.15 * 0.81) < 0.00001 and absf(steil_dropship - 0.15 * 0.01) < 0.00001, "(g) the same pilot has a different chance in the fighter than in the dropship")

## (h) repeating the same order gives the same result; (i) every number comes from the data block.
func _repeat_and_data() -> void:
	var stations: Array = [{"instance_id": "hagel@A", "unit_id": "hagel", "cell": Vector2i(0, -4), "ground_level": 0}]
	var context := {"vehicles": stations, "start_plane": cell_plane(Vector2i(-40, 0)), "lz_plane": cell_plane(Vector2i(6, 0)), "height_at": flat_height_at, "crew_ready": true, "pilot_skill": 0.0,
		"seed": "repeat", "model_id": "cutlass", "integrity": 100, "approach_style": "aggressiv"}
	for path in ["steil", "tief"]:
		var first: Dictionary = PLAN.resolve(context.merged({"approach_path": path}))
		var second: Dictionary = PLAN.resolve(context.merged({"approach_path": path}))
		check(JSON.stringify(first) == JSON.stringify(second), "(h) the same %s order gives the identical result, accident roll included" % path)
	var rules: Dictionary = AD.definition().duplicate(true)
	var paths: Dictionary = Dictionary(Dictionary(rules.get("approach_paths", {})).get("paths", {}))
	check(paths.has("steil") and paths.has("tief") and Dictionary(rules.approach_paths).has("accident"), "(i) the data file carries the approach_paths block with steil, tief and the accident limits")
	# Changed numbers change the outcome.
	rules.approach_paths.paths.steil.exposure_factor = 0.3
	rules.approach_paths.paths.steil.accident_max = 0.2
	var total: int = in_range_samples(stations, Vector2(context.start_plane), Vector2(context.lz_plane))
	var narrow: Dictionary = PLAN.resolve(context.merged({"approach_path": "steil", "rules": rules}))
	check(int(narrow.path_report.window.kept) == ceili(float(total) * 0.3), "(i) a changed exposure factor changes the steil window: kept %d of %d" % [int(narrow.path_report.window.kept), total])
	rules.approach_paths.paths.tief.accident_max = 1.0
	rules.approach_paths.accident.hull_loss_min_percent = 50
	rules.approach_paths.accident.hull_loss_max_percent = 50
	var sure: Dictionary = PLAN.resolve(context.merged({"approach_path": "tief", "rules": rules, "approach_style": "", "vehicles": []}, true))
	check(bool(sure.path_report.accident.occurred) and int(sure.path_report.accident.hull_loss) == 50 and int(sure.hull_percent) == 50, "(i) a changed accident maximum and loss range apply: pilot 0.0, chance 1.0, loss 50")
	check(absf(PLAN.accident_probability("tief", 0.0, rules) - 1.0) < 0.00001, "(i) the probability formula reads pmax from the data")
	rules.approach_paths.paths.tief.accident_max = 0.0
	var none: Dictionary = PLAN.resolve(context.merged({"approach_path": "tief", "rules": rules, "vehicles": []}, true))
	check(not bool(none.path_report.accident.possible) and String(none.outcome) == "none", "(i) accident_max 0 switches the risk off")
	# Missing block: the game behaves as before (normal).
	var bare: Dictionary = AD.definition().duplicate(true)
	bare.erase("approach_paths")
	for path in ["steil", "tief"]:
		var plain: Dictionary = PLAN.resolve(context.merged({"approach_path": "normal"}))
		var without_block: Dictionary = PLAN.resolve(context.merged({"approach_path": path, "rules": bare}))
		check(digest(plain) == digest(without_block), "(i) without the data block %s behaves exactly like normal" % path)
	var steil_tip: String = PLAN.path_tooltip("steil", 0.5)
	check(steil_tip.contains("15 %") and steil_tip.contains("60 %") and PLAN.path_tooltip("tief", 0.5).contains("25 %"), "(i) the tooltips take their numbers from the data: " + steil_tip)
	check(steil_tip.contains("Waffenreichweite") and steil_tip.contains("Hat eine Stellung nur ein oder zwei Feuergelegenheiten, bringt Steil nichts") and not steil_tip.contains("kaum spürbar"), "(i) the Steil tooltip says the cut counts in weapon range and that Steil brings nothing for one or two firing chances: " + steil_tip)
	var changed_tip: String = PLAN.path_tooltip("steil", 0.5, rules)
	check(changed_tip.contains("20 %") and changed_tip.contains("30 %") and not changed_tip.contains("15 %") and not changed_tip.contains("60 %"), "(i) and follow a changed block: " + changed_tip)
