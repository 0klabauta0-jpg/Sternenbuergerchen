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

func in_range_samples(vehicles: Array, start: Vector2, lz: Vector2) -> int:
	var count := 0
	for sample in PLAN.approach_samples(start, lz):
		var cell: Vector2i = PLAN.plane_to_cell(Vector2(sample))
		for vehicle in vehicles:
			var unit: Dictionary = AD.unit(String(vehicle.unit_id))
			if HEX.distance(Vector2i(vehicle.cell), cell) <= maxi(int(unit.get("sight_range_hex", 0)), int(unit.get("radar_range_hex", 0))):
				count += 1
				break
	return count

func _run() -> void:
	var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	for tile in Array(map.get("tiles", [])):
		heights[Vector2i(int(tile.grid_position.x), int(tile.grid_position.y))] = int(tile.height_level)
	var vehicles: Array = PLAN.vehicles_from_props(Array(Dictionary(map.get("place_presentation", {})).get("props", [])), height_at)
	_normal_unchanged(vehicles)
	_tief_masking()
	_steil_window()
	_accident_formula()
	_accident_without_flak_and_hull()
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

## (c) Steil keeps only exposure_factor of the time inside the batteries' reach.
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
	check(total >= 4 and int(window.get("in_range", -1)) == total and int(window.get("kept", -1)) == kept and kept < total, "(c) steil keeps ceil(%d x %.1f) = %d of %d in-reach volleys: %s" % [total, factor, kept, total, str(window)])
	check(int(steil.volley_count) == kept and int(normal.volley_count) >= total, "(c) steil resolves %d volleys against normal's %d" % [int(steil.volley_count), int(normal.volley_count)])
	var normal_fire: int = types(normal.result).count("flak_volley")
	var steil_fire: int = types(steil.result).count("flak_volley")
	check(steil_fire < normal_fire, "(c) fewer opportunities to fire: %d flak volleys against %d" % [steil_fire, normal_fire])
	check(String(steil.approach_profile) == "normal" and Array(steil.path_report.stations_masked).is_empty(), "(c) steil flies at normal height and takes no terrain cover")

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

## (g) the pilot value belongs to the ship: fighter_piloting for the fighter, dropship_piloting for the dropship.
func _pilot_skill_per_model() -> void:
	var skills := {"dropship_piloting": 0.9, "fighter_piloting": 0.1}
	check(PLAN.pilot_skill_for_model("cutlass", skills) == 0.9 and PLAN.pilot_skill_for_model("buccaneer", skills) == 0.1, "(g) cutlass reads dropship_piloting, buccaneer reads fighter_piloting")
	check(PLAN.pilot_skill_for_model("", skills) == 0.9 and PLAN.pilot_skill_for_model("unbekannt", skills) == 0.9, "(g) an unknown model keeps the old dropship value")
	check(PLAN.pilot_skill_for_model("buccaneer", {"dropship_piloting": 0.9, "fighter_piloting": -1.0}) == 0.5 and PLAN.pilot_skill_for_model("cutlass", {}) == 0.5, "(g) a missing or negative value falls back to 0.5 as before")
	var steil_fighter: float = PLAN.accident_probability("steil", PLAN.pilot_skill_for_model("buccaneer", skills))
	var steil_dropship: float = PLAN.accident_probability("steil", PLAN.pilot_skill_for_model("cutlass", skills))
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
	var changed_tip: String = PLAN.path_tooltip("steil", 0.5, rules)
	check(changed_tip.contains("20 %") and changed_tip.contains("30 %") and not changed_tip.contains("15 %") and not changed_tip.contains("60 %"), "(i) and follow a changed block: " + changed_tip)
