extends RefCounted
## Ground air defence on a real landing approach: builds the input of the pure
## resolver scripts/combat/air_defense_engagement.gd from map data and turns its
## result into a landing outcome and an AirAssetStatus snapshot.
## Contract: docs/dev/ground_air_defense_engagement_contract.md
## Task: docs/tasks/FLUGABWEHR_ANSCHLUSS_2026_11_14.md,
## docs/tasks/FLUGABWEHR_ANFLUGSTIL_REPARATUR_2026_11_15.md (approach style, repair)
## Pure static helpers: no state, no scene. The mission controller commits the
## snapshot through SimulationRoot's air_asset_status_update effect.

const AD = preload("res://scripts/combat/air_defense_engagement.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const CATALOG = preload("res://scripts/mission/space_component_catalog.gd")
const SYSTEMS = preload("res://scripts/tactical/space_component_systems.gd")
const AIR_ASSET_STATUS = preload("res://scripts/mission/air_asset_status.gd")
const SAMPLE_STEP_HEX := 4.0
const APPROACH_PROFILE := "normal"
const DEFAULT_MODEL := "cutlass"
const OUTCOME_NONE := "none"
const OUTCOME_PRESSED_ON := "pressed_on"
const OUTCOME_BROKE_OFF := "broke_off"
const OUTCOME_DESTROYED := "destroyed_forced_break_off"
## Approach style per mission craft (task FLUGABWEHR_ANFLUGSTIL_REPARATUR_2026_11_15).
const STYLE_CAUTIOUS := "vorsichtig"
const STYLE_NORMAL := "normal"
const STYLE_AGGRESSIVE := "aggressiv"
const APPROACH_STYLES: PackedStringArray = ["vorsichtig", "normal", "aggressiv"]
const DEFAULT_APPROACH_STYLE := STYLE_NORMAL
const STYLE_LABELS := {"vorsichtig": "Vorsichtig", "normal": "Normal", "aggressiv": "Aggressiv"}
const STYLE_TOOLTIPS := {
	"vorsichtig": "Tiefflug unter dem Radar, dreht unter Beschuss ab; Landung ungenauer (Streukreis x 1,5).",
	"normal": "Normale Flughoehe, dreht unter Beschuss ab.",
	"aggressiv": "Normale Flughoehe, fliegt unter Beschuss weiter und landet trotz Treffern.",
}
## Approach path per mission craft (task LA, 2026-11-22): the second axis next to the style.
## Numbers live in data/combat/air_defense_units.json "approach_paths"; a missing block
## makes every path behave like "normal". Normal never changes a result.
const LOS = preload("res://scripts/core/los_system.gd")
const PATH_STEEP := "steil"
const PATH_NORMAL := "normal"
const PATH_LOW := "tief"
const APPROACH_PATHS: PackedStringArray = ["steil", "normal", "tief"]
const DEFAULT_APPROACH_PATH := PATH_NORMAL
const PATH_LABELS := {"steil": "Steil", "normal": "Normal", "tief": "Tief"}
const PATH_FLIGHT_NAMES := {"steil": "Steilflug", "normal": "Normalflug", "tief": "Tiefflug"}
const OUTCOME_ACCIDENT := "accident"
const CRAFT_TYPE_FIGHTER := "fighter"
const DEFAULT_PILOT_SKILL := 0.5
## Steil: a battery's volley outside its kept window sees the ship this far away, i.e. not at all.
const OUTSIDE_WINDOW_RANGE := 100000


static func plane_to_cell(plane: Vector2) -> Vector2i:
	return HEX.round_axial(HEX.plane_to_axial(plane))


## Fractional axial grid position (TerrainRegistry.world_to_grid_float) to plane.
static func axial_to_plane(axial: Vector2) -> Vector2:
	return HEX.axial_to_plane(axial)


## Every map prop whose asset is an air-defence unit id is one vehicle.
## height_at: Callable(Vector2i) -> int, 0 outside the map.
static func vehicles_from_props(props: Array, height_at: Callable) -> Array:
	var units: Dictionary = Dictionary(AD.definition().get("units", {}))
	var result: Array = []
	for prop_variant in props:
		if typeof(prop_variant) != TYPE_DICTIONARY:
			continue
		var prop: Dictionary = prop_variant
		var unit_id: String = String(prop.get("asset", ""))
		var center: Variant = prop.get("center")
		if not units.has(unit_id) or typeof(center) != TYPE_ARRAY or Array(center).size() < 2:
			continue
		var cell: Vector2i = plane_to_cell(Vector2(float(center[0]), float(center[1])))
		result.append({"instance_id": "%s@%d,%d" % [unit_id, cell.x, cell.y], "unit_id": unit_id, "cell": cell, "ground_level": int(height_at.call(cell))})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.instance_id) < String(b.instance_id))
	return result


## Crew from the scenario's air-defence enemy group (fit counts as the scenario
## runtime gates read them). known = false: no authoring or group, inert scenery.
static func crew_state(tactical_authoring: Dictionary, enemy_group_fit_counts: Dictionary) -> Dictionary:
	var group_id: String = String(Dictionary(tactical_authoring.get("air_asset_risk", {})).get("enemy_group_id", "")).strip_edges()
	if group_id.is_empty() or not enemy_group_fit_counts.has(group_id):
		return {"known": false, "crew_ready": false, "group_id": group_id, "fit_count": 0}
	var fit_count: int = int(enemy_group_fit_counts.get(group_id, 0))
	return {"known": true, "crew_ready": fit_count > 0, "group_id": group_id, "fit_count": fit_count}


## Straight line in plane coordinates, one sample every step hex cells, plus the LZ.
static func approach_samples(start_plane: Vector2, lz_plane: Vector2, step: float = SAMPLE_STEP_HEX) -> Array:
	var samples: Array = []
	var length: float = start_plane.distance_to(lz_plane)
	var direction: Vector2 = (lz_plane - start_plane).normalized() if length > 0.0 else Vector2.ZERO
	for index in range(int(floor(length / step)) + 1):
		samples.append(start_plane + direction * step * float(index))
	if samples.is_empty() or Vector2(samples[-1]).distance_to(lz_plane) > 0.001:
		samples.append(lz_plane)
	return samples


## One volley per sample. Line of sight is true unless terrain_masking is set (approach
## path "tief"): then every contact in reach is checked with LosSystem.find_first_blocker_grid
## against the map's height levels, between the weapon mount and the ship's flight height.
static func build_volleys(vehicles: Array, samples: Array, height_at: Callable, crew_ready: bool, profile_id: String = APPROACH_PROFILE, terrain_masking: bool = false, silenced: Dictionary = {}) -> Array:
	var volleys: Array = []
	var los: Variant = LOS.new() if terrain_masking else null
	var reader: Variant = _HeightReader.new(height_at) if terrain_masking else null
	for index in range(samples.size()):
		var cell: Vector2i = plane_to_cell(Vector2(samples[index]))
		var ship_ground: int = int(height_at.call(cell))
		var contacts: Dictionary = {}
		for vehicle in vehicles:
			var range_hex: int = HEX.distance(Vector2i(vehicle.cell), cell)
			var height_delta: int = AD.height_delta_levels(ship_ground, profile_id, int(vehicle.ground_level))
			var contact := {"unit_id": String(vehicle.unit_id), "range_hex": range_hex, "height_delta_levels": height_delta, "has_line_of_sight": true, "crew_ready": crew_ready}
			if terrain_masking:
				var in_reach: bool = range_hex <= reach_hex(String(vehicle.unit_id))
				contact["in_reach"] = in_reach
				contact["in_weapon_range"] = in_weapon_range(String(vehicle.unit_id), range_hex)
				if in_reach:
					var mount: float = float(int(vehicle.ground_level) + AD.MOUNT_LEVELS)
					var blocker: Vector2i = los.find_first_blocker_grid(Vector2i(vehicle.cell), cell, reader, Vector2.INF, Vector2.INF, false, Vector2(mount, mount + float(height_delta)))
					contact["has_line_of_sight"] = blocker == LOS.NO_BLOCKER_GRID
			# Steil: this battery's volleys before its kept window do not see the ship (and lose its track).
			if Dictionary(silenced.get(String(vehicle.instance_id), {})).has(index):
				contact["range_hex"] = OUTSIDE_WINDOW_RANGE
				contact["outside_window"] = true
			contacts[String(vehicle.instance_id)] = contact
		volleys.append({"cell": cell, "contacts": contacts})
	return volleys


## Distance (hex cells) at which the unit can shoot: between its minimum and maximum weapon range.
static func in_weapon_range(unit_id: String, range_hex: int) -> bool:
	var unit_data: Dictionary = AD.unit(unit_id)
	return float(range_hex) >= float(unit_data.get("weapon_min_range_hex", 0)) and float(range_hex) <= float(unit_data.get("weapon_range_hex", 0))


## Farthest distance (hex cells) at which the unit can notice a ship at all.
static func reach_hex(unit_id: String) -> int:
	var unit_data: Dictionary = AD.unit(unit_id)
	return maxi(int(unit_data.get("sight_range_hex", 0)), int(unit_data.get("radar_range_hex", 0)))


## The map's height levels as a terrain reader for LosSystem: every cell is an occluder
## as high as its height level (the map's own blocks_los flags only carry walls).
class _HeightReader:
	extends RefCounted
	class _Tile:
		extends RefCounted
		var height_level: int = 0
		var blocks_los: bool = true
		var object_height: int = 0
	var _height_at: Callable
	func _init(height_at: Callable) -> void:
		_height_at = height_at
	func get_grid_topology() -> String:
		return HEX.TOPOLOGY_ID
	func get_tile_at_grid(cell: Vector2i):
		var tile := _Tile.new()
		tile.height_level = int(_height_at.call(cell))
		return tile
	func blocks_los_at_grid(_cell: Vector2i) -> bool:
		return true
	func get_object_height_at_grid(_cell: Vector2i) -> int:
		return 0


## Known style or "" for an unknown value (commands reject "", stored state falls back).
static func normalize_style(approach_style: String) -> String:
	var style: String = approach_style.strip_edges().to_lower()
	return style if APPROACH_STYLES.has(style) else ""


## Unknown or empty style behaves as "normal".
static func sanitize_style(approach_style: String) -> String:
	var style: String = normalize_style(approach_style)
	return style if not style.is_empty() else DEFAULT_APPROACH_STYLE


static func profile_for_style(approach_style: String) -> String:
	return "low" if sanitize_style(approach_style) == STYLE_CAUTIOUS else APPROACH_PROFILE


static func decision_for_style(approach_style: String) -> String:
	return AD.DECISION_PRESS_ON if sanitize_style(approach_style) == STYLE_AGGRESSIVE else AD.DECISION_BREAK_OFF


## Landing scatter radius factor: the low profile's lz_radius_factor, 1.0 otherwise.
static func lz_radius_factor_for_style(approach_style: String) -> float:
	var profiles: Dictionary = Dictionary(AD.definition().get("approach_profiles", {}))
	return float(Dictionary(profiles.get(profile_for_style(approach_style), {})).get("lz_radius_factor", 1.0))


## Known path or "" for an unknown value (commands reject "", stored state falls back).
static func normalize_path(approach_path: String) -> String:
	var path: String = approach_path.strip_edges().to_lower()
	return path if APPROACH_PATHS.has(path) else ""


## Unknown or empty path behaves as "normal".
static func sanitize_path(approach_path: String) -> String:
	var path: String = normalize_path(approach_path)
	return path if not path.is_empty() else DEFAULT_APPROACH_PATH


## Arrival mode per mission craft (task LB): its own axis next to path and style, no fourth path.
## "land" = as before (touch down, troop leaves); "circle" = stays airborne over the landing zone.
const ARRIVAL_LAND := "land"
const ARRIVAL_CIRCLE := "circle"
const ARRIVAL_MODES: PackedStringArray = ["land", "circle"]
const DEFAULT_ARRIVAL_MODE := ARRIVAL_LAND
const ARRIVAL_LABELS := {"land": "Landen", "circle": "Kreisen"}
const ARRIVAL_CIRCLE_HINT := "Das Schiff landet nicht, sondern bleibt über der Landezone in der Luft. Der Trupp bleibt an Bord, bis du landen lässt."


## Known arrival mode or "" for an unknown value (commands reject "", stored state falls back).
static func normalize_arrival_mode(arrival_mode: String) -> String:
	var mode: String = arrival_mode.strip_edges().to_lower()
	return mode if ARRIVAL_MODES.has(mode) else ""


## Unknown or empty mode behaves as "land".
static func sanitize_arrival_mode(arrival_mode: String) -> String:
	var mode: String = normalize_arrival_mode(arrival_mode)
	return mode if not mode.is_empty() else DEFAULT_ARRIVAL_MODE


## Data of one path: {} for normal, an unknown path and a missing data block (= behaves like normal).
## rules: optional replacement of the whole data file (tests); default AD.definition().
static func path_rules(approach_path: String, rules: Dictionary = {}) -> Dictionary:
	var path: String = sanitize_path(approach_path)
	if path == PATH_NORMAL:
		return {}
	var source: Dictionary = rules if not rules.is_empty() else AD.definition()
	return Dictionary(Dictionary(Dictionary(source.get("approach_paths", {})).get("paths", {})).get(path, {}))


static func path_has_effect(approach_path: String, rules: Dictionary = {}) -> bool:
	return not path_rules(approach_path, rules).is_empty()


static func accident_rules(rules: Dictionary = {}) -> Dictionary:
	var source: Dictionary = rules if not rules.is_empty() else AD.definition()
	return Dictionary(Dictionary(source.get("approach_paths", {})).get("accident", {}))


## Accident chance of one approach: pmax x (1 - pilot)^2 (pmax from the data, 0 for normal).
static func accident_probability(approach_path: String, pilot_skill: float, rules: Dictionary = {}) -> float:
	var pmax: float = float(path_rules(approach_path, rules).get("accident_max", 0.0))
	var pilot: float = clampf(pilot_skill, 0.0, 1.0)
	return clampf(pmax * (1.0 - pilot) * (1.0 - pilot), 0.0, 1.0)


## One seeded accident roll per approach: same seed text, same result (a repeated order does not
## roll again). Two numbers are drawn every time (accident roll, hull loss roll), so the loss
## never depends on whether the accident happened. Hull loss is in percentage points.
static func accident_check(approach_path: String, pilot_skill: float, seed_text: String, rules: Dictionary = {}) -> Dictionary:
	var path: String = sanitize_path(approach_path)
	var probability: float = accident_probability(path, pilot_skill, rules)
	var result := {"path": path, "possible": probability > 0.0, "pilot_skill": clampf(pilot_skill, 0.0, 1.0), "probability": probability, "threshold": probability,
		"roll": -1.0, "occurred": false, "hull_loss": 0, "reason": ""}
	if probability <= 0.0:
		result["reason"] = "kein Unfallrisiko"
		return result
	var limits: Dictionary = accident_rules(rules)
	var loss_min: int = int(limits.get("hull_loss_min_percent", 20))
	var loss_max: int = maxi(int(limits.get("hull_loss_max_percent", 40)), loss_min)
	var rng := RandomNumberGenerator.new()
	rng.seed = AD.seed_to_int("%s:approach_path:%s" % [seed_text, path])
	var roll: float = rng.randf()
	var loss_roll: float = rng.randf()
	result["roll"] = roll
	result["occurred"] = roll < probability
	result["hull_loss"] = roundi(lerpf(float(loss_min), float(loss_max), loss_roll)) if bool(result.occurred) else 0
	result["reason"] = "Wurf %.3f %s Schwelle %.3f" % [roll, "unter" if bool(result.occurred) else "nicht unter", probability]
	return result


## The pilot value that belongs to the ship, by the craft's own craft_type (the craft card / aircraft
## definition carries "dropship" or "fighter"): a fighter reads fighter_piloting and, where that is
## unset (campaign pilots carry only dropship_piloting), the dropship_piloting the approach read before
## LA; every other craft reads dropship_piloting. skills: {"dropship_piloting": float, "fighter_piloting":
## float}; missing or negative values (unset) fall back to 0.5 like the approach always did.
static func pilot_skill_for_craft_type(craft_type: String, skills: Dictionary) -> float:
	var keys: Array = ["fighter_piloting", "dropship_piloting"] if craft_type.strip_edges().to_lower() == CRAFT_TYPE_FIGHTER else ["dropship_piloting"]
	for key in keys:
		var value: Variant = skills.get(key, -1.0)
		if typeof(value) in [TYPE_FLOAT, TYPE_INT] and float(value) >= 0.0:
			return clampf(float(value), 0.0, 1.0)
	return DEFAULT_PILOT_SKILL


## Steil: the time in the effective area is counted PER BATTERY, in the volleys where the ship is inside
## that battery's weapon range (not its radar or sight range, which is longer). Of those n volleys
## the ship keeps the last ceil(n x factor); in the earlier ones that battery has no track on it
## (it has to find the ship again, so it needs its warning and lock volleys anew). Fewer than three
## volleys in weapon range lose nothing: ceil(1 x f) = 1, ceil(2 x f) = 2 for f = 0.6.
## Returns {"stations": {id: {"in_range", "kept", "dropped": [volley indices]}}, "in_range", "kept", "factor"}
## (in_range / kept summed over the stations). No battery in weapon range: nothing to cut.
static func exposure_window(samples: Array, vehicles: Array, factor: float) -> Dictionary:
	var stations: Dictionary = {}
	var total: int = 0
	var kept_total: int = 0
	for vehicle in vehicles:
		var zone: Array = []
		for index in range(samples.size()):
			var cell: Vector2i = plane_to_cell(Vector2(samples[index]))
			if in_weapon_range(String(vehicle.unit_id), HEX.distance(Vector2i(vehicle.cell), cell)):
				zone.append(index)
		var in_range: int = zone.size()
		if in_range == 0:
			continue
		var kept: int = in_range if factor >= 1.0 else clampi(ceili(float(in_range) * maxf(factor, 0.0)), 1, in_range)
		stations[String(vehicle.instance_id)] = {"in_range": in_range, "kept": kept, "dropped": zone.slice(0, in_range - kept)}
		total += in_range
		kept_total += kept
	return {"stations": stations, "in_range": total, "kept": kept_total, "factor": factor}


## exposure_window -> build_volleys' silenced argument: {instance_id: {volley index: true}}.
static func silenced_volleys(window: Dictionary) -> Dictionary:
	var silenced: Dictionary = {}
	var stations: Dictionary = Dictionary(window.get("stations", {}))
	for instance_id in stations.keys():
		var indices: Dictionary = {}
		for index in Array(Dictionary(stations[instance_id]).get("dropped", [])):
			indices[int(index)] = true
		silenced[String(instance_id)] = indices
	return silenced


## Stations that had the ship inside their WEAPON range (min..max) at some volley but never a clear
## line to it there. "in_range" lists the stations that had it in weapon range at all.
static func station_cover(vehicles: Array, volleys: Array) -> Dictionary:
	var masked: Array = []
	var in_range: Array = []
	for vehicle in vehicles:
		var instance_id: String = String(vehicle.instance_id)
		var clear: int = 0
		var blocked: int = 0
		for volley in volleys:
			var contact: Dictionary = Dictionary(Dictionary(volley).get("contacts", {})).get(instance_id, {})
			if not bool(contact.get("in_weapon_range", false)):
				continue
			if bool(contact.get("has_line_of_sight", true)):
				clear += 1
			else:
				blocked += 1
		if clear + blocked > 0:
			in_range.append(instance_id)
		if blocked > 0 and clear == 0:
			masked.append(instance_id)
	return {"masked": masked, "in_range": in_range}


static func masked_stations(vehicles: Array, volleys: Array) -> Array:
	return Array(station_cover(vehicles, volleys).masked)


static func _percent_text(fraction: float) -> String:
	var percent: float = fraction * 100.0
	if absf(percent - roundf(percent)) < 0.05:
		return "%d" % roundi(percent)
	return ("%.1f" % percent).replace(".", ",")


## Hint text of one path button; every number comes from the data and the ship's pilot
## (pilot_skill < 0: no pilot figure).
static func path_tooltip(approach_path: String, pilot_skill: float = -1.0, rules: Dictionary = {}) -> String:
	var path: String = sanitize_path(approach_path)
	if path == PATH_NORMAL:
		return "Normale Flugbahn: wie bisher, kein zusätzliches Unfallrisiko."
	var data: Dictionary = path_rules(path, rules)
	var label: String = String(PATH_LABELS.get(path, path))
	if data.is_empty():
		return "%s: ohne Wirkung (keine Daten)." % label
	var parts: Array = []
	if data.has("exposure_factor"):
		parts.append("kürzer im Feuer (je Stellung nur %s %% der Zeit in deren Waffenreichweite). Hat eine Stellung nur ein oder zwei Feuergelegenheiten, bringt Steil nichts" % _percent_text(float(data.exposure_factor)))
	if bool(data.get("terrain_masking", false)):
		parts.append("Gelände kann die Flugabwehr verdecken")
	var text: String = "%s: %s." % [label, ", ".join(parts)] if not parts.is_empty() else "%s." % label
	var pmax: float = float(data.get("accident_max", 0.0))
	if pmax > 0.0:
		text += " Unfallrisiko %s %% mal Pilotenfaktor" % _percent_text(pmax)
		if pilot_skill >= 0.0:
			text += ", bei diesem Piloten %s %%" % _percent_text(accident_probability(path, pilot_skill, rules))
		text += "."
	return text


## Effective stats of the model's default loadout; hull from integrity (0..100).
static func ship_for(model_id: String, integrity: int, max_integrity: int = 100) -> Dictionary:
	var models: Dictionary = Dictionary(CATALOG.definition().get("models", {}))
	var model: String = model_id if models.has(model_id) else DEFAULT_MODEL
	var stats: Dictionary = CATALOG.effective_stats(model, CATALOG.default_loadout(model))
	if not bool(stats.get("ok", false)):
		return {"ok": false, "reason": "ship_stats_unavailable"}
	var initial: Dictionary = SYSTEMS.initial(stats, float(stats.get("hull_capacity", 100.0)))
	if not bool(initial.get("ok", false)):
		return {"ok": false, "reason": "ship_stats_unavailable"}
	var state: Dictionary = initial.state
	var fraction: float = clampf(float(integrity) / float(maxi(max_integrity, 1)), 0.01, 1.0)
	state.hull = float(state.hull_capacity) * fraction
	return {"ok": true, "model_id": model, "stats": stats, "state": state}


## The samples and volleys of one approach (before any dice): path, its data, the steil window per
## battery, the volley list the resolver gets. Same context as resolve(). Tests count the batteries'
## firing opportunities with it; resolve() uses it.
static func approach_volleys(context: Dictionary) -> Dictionary:
	var rules: Dictionary = Dictionary(context.get("rules", {}))
	var path: String = sanitize_path(String(context.get("approach_path", "")))
	var path_data: Dictionary = path_rules(path, rules)
	var height_at: Callable = context.get("height_at")
	var vehicles: Array = Array(context.get("vehicles", []))
	var samples: Array = approach_samples(Vector2(context.get("start_plane", Vector2.ZERO)), Vector2(context.get("lz_plane", Vector2.ZERO)), float(path_data.get("sample_step_hex", SAMPLE_STEP_HEX)))
	var style: String = sanitize_style(String(context.get("approach_style", "")))
	var profile_id: String = String(path_data.get("profile", profile_for_style(style)))
	var window: Dictionary = {}
	if path_data.has("exposure_factor"):
		window = exposure_window(samples, vehicles, float(path_data.exposure_factor))
	var masking: bool = bool(path_data.get("terrain_masking", false))
	var volleys: Array = build_volleys(vehicles, samples, height_at, bool(context.get("crew_ready", false)), profile_id, masking, silenced_volleys(window))
	return {"path": path, "path_data": path_data, "vehicles": vehicles, "samples": samples, "style": style, "profile_id": profile_id,
		"decision": decision_for_style(style), "window": window, "volleys": volleys}


## context: vehicles, start_plane, lz_plane, height_at, crew_ready, pilot_skill,
## seed, model_id, integrity (0..100), approach_style, approach_path (LA; "" = normal),
## rules (optional replacement of the data file, tests only).
## Path "normal" (or a missing approach_paths block) computes exactly as before LA.
static func resolve(context: Dictionary) -> Dictionary:
	var ship: Dictionary = ship_for(String(context.get("model_id", DEFAULT_MODEL)), int(context.get("integrity", 100)))
	if not bool(ship.get("ok", false)):
		return ship
	var rules: Dictionary = Dictionary(context.get("rules", {}))
	var approach: Dictionary = approach_volleys(context)
	var path: String = String(approach.path)
	var path_data: Dictionary = approach.path_data
	var vehicles: Array = approach.vehicles
	var samples: Array = approach.samples
	var style: String = String(approach.style)
	var profile_id: String = String(approach.profile_id)
	var decision: String = String(approach.decision)
	var window: Dictionary = approach.window
	var volleys: Array = approach.volleys
	var result: Dictionary = AD.resolve_approach({
		"seed": String(context.get("seed", "")), "pilot_skill": float(context.get("pilot_skill", 0.5)),
		"ship_model": String(ship.model_id), "ship_stats": ship.stats, "ship_state": ship.state, "decision": decision,
		"volleys": volleys,
	})
	var plan: Dictionary = summarize(result, String(context.get("seed", "")))
	plan["decision"] = decision
	plan["approach_style"] = style
	plan["approach_profile"] = profile_id
	plan["volley_count"] = samples.size()
	plan["approach_path"] = path
	if not path_data.is_empty() and bool(plan.get("ok", false)):
		_apply_path_effects(plan, path, path_data, vehicles, volleys, window, context, rules)
	return plan


## LA: terrain cover report, steil window and the one accident roll, written into the plan
## (plan.path_report, a changed plan.message / outcome / hull_percent). Only for paths with data.
static func _apply_path_effects(plan: Dictionary, path: String, path_data: Dictionary, vehicles: Array, volleys: Array, window: Dictionary, context: Dictionary, rules: Dictionary) -> void:
	var report := {"path": path, "stations_total": vehicles.size(), "stations_in_range": [], "stations_masked": [], "window": {}}
	if not window.is_empty():
		var window_stations: Dictionary = {}
		for instance_id in Dictionary(window.stations).keys():
			window_stations[instance_id] = {"in_range": int(Dictionary(window.stations[instance_id]).in_range), "kept": int(Dictionary(window.stations[instance_id]).kept)}
		report["window"] = {"in_range": int(window.in_range), "kept": int(window.kept), "factor": float(window.factor), "stations": window_stations}
	var sentences: Array = []
	var flight_name: String = String(PATH_FLIGHT_NAMES.get(path, path))
	if bool(path_data.get("terrain_masking", false)):
		var cover: Dictionary = station_cover(vehicles, volleys)
		var masked: Array = cover.masked
		report["stations_masked"] = masked
		report["stations_in_range"] = cover.in_range
		if not masked.is_empty():
			# N of the stations that would have had the ship in weapon range (not all stations on the map).
			sentences.append("%s: %d von %d Stellungen durch Gelände verdeckt." % [flight_name, masked.size(), Array(cover.in_range).size()])
	var accident: Dictionary = accident_check(path, float(context.get("pilot_skill", DEFAULT_PILOT_SKILL)), String(context.get("seed", "")), rules)
	if bool(accident.possible) and not bool(plan.get("landing_allowed", true)):
		# The air defence turned the approach away: it never reaches the ground, so nothing is rolled against it.
		accident["occurred"] = false
		accident["hull_loss"] = 0
		accident["skipped"] = "approach_aborted"
	if bool(accident.occurred):
		var floor_percent: int = hull_floor_percent(rules)
		var before: int = int(plan.hull_percent)
		plan["hull_percent"] = maxi(before - int(accident.hull_loss), floor_percent)
		accident["hull_loss_applied"] = before - int(plan.hull_percent)
		if String(plan.get("outcome", OUTCOME_NONE)) == OUTCOME_NONE:
			plan["outcome"] = OUTCOME_ACCIDENT
		if String(plan.get("message", "")).begins_with("Flugabwehr: "):
			# After flak hits the card names the hull once, AFTER the accident: the flak sentence loses its
			# own hull figure (it was the value before the accident).
			plan["message"] = "Flugabwehr: %d Treffer" % int(plan.get("hits", 0))
			sentences.append("Unfall im %s: Rumpf -%d %%, jetzt %d %%." % [flight_name, int(accident.hull_loss_applied), int(plan.hull_percent)])
		else:
			sentences.append("Unfall im %s: Rumpf -%d %%." % [flight_name, int(accident.hull_loss_applied)])
	report["accident"] = accident
	plan["path_report"] = report
	plan["accident_occurred"] = bool(accident.occurred)
	if not sentences.is_empty():
		var flak_text: String = String(plan.get("message", ""))
		plan["message"] = (flak_text + ". " if not flak_text.is_empty() else "") + " ".join(sentences)


static func hull_floor_percent(rules: Dictionary = {}) -> int:
	return maxi(int(accident_rules(rules).get("hull_floor_percent", 1)), 1)


## Landing outcome and German one-line message from a resolver result.
static func summarize(result: Dictionary, seed_text: String) -> Dictionary:
	if not bool(result.get("ok", false)):
		return {"ok": false, "reason": String(result.get("reason", "resolver_failed")), "engaged": false, "landing_allowed": true, "result": result}
	var plan: Dictionary = {"ok": true, "engaged": not Array(result.get("events", [])).is_empty(), "result": result,
		"event_id": "air_defense:" + seed_text, "landing_allowed": true, "outcome": OUTCOME_NONE, "message": "",
		"hits": int(result.get("hits", 0)), "hull_percent": roundi(float(result.get("hull_fraction", 1.0)) * 100.0)}
	if not bool(plan.engaged):
		return plan
	if bool(result.get("destroyed", false)):
		# No crashed-dropship path exists in the controller: forced break-off, hull floored at 1 %.
		plan.hull_percent = 1
		plan.outcome = OUTCOME_DESTROYED
		plan.landing_allowed = false
		plan.message = "Flugabwehr: Anflug abgebrochen, Schiff schwer getroffen, Rumpf 1 %"
	elif bool(result.get("broke_off", false)):
		plan.hull_percent = maxi(int(plan.hull_percent), 1)
		plan.outcome = OUTCOME_BROKE_OFF
		plan.landing_allowed = false
		plan.message = "Flugabwehr: Anflug abgebrochen, Rumpf %d %%" % int(plan.hull_percent)
	else:
		plan.hull_percent = maxi(int(plan.hull_percent), 1)
		plan.outcome = OUTCOME_PRESSED_ON
		plan.message = "Flugabwehr: %d Treffer, Rumpf %d %%" % [int(plan.hits), int(plan.hull_percent)]
	return plan


## Next AirAssetStatus snapshot of the craft: integrity := hull percent,
## state hit / damaged after damage, otherwise a visible warning.
static func status_snapshot_after(prior: Dictionary, craft_id: String, display_name: String, plan: Dictionary) -> Dictionary:
	var seed_status: Dictionary = prior.duplicate(true)
	if seed_status.is_empty():
		seed_status = {"asset_type": AIR_ASSET_STATUS.TYPE_DROPSHIP, "display_name": display_name, "state": AIR_ASSET_STATUS.STATE_INTACT, "integrity": 100, "max_integrity": 100}
	seed_status["asset_id"] = craft_id
	var status = AIR_ASSET_STATUS.from_dict(seed_status)
	var previous_integrity: int = int(status.integrity)
	var next_integrity: int = clampi(roundi(float(plan.get("hull_percent", 100)) * float(status.max_integrity) / 100.0), 1, int(status.max_integrity))
	status.apply_threat({"next_state": AIR_ASSET_STATUS.STATE_THREATENED, "warning_visible": true, "reason": "air_defense_" + String(plan.get("outcome", OUTCOME_NONE)),
		"event_id": String(plan.get("event_id", "")), "weapon_id": "", "attacker_unit_id": ""})
	if next_integrity < previous_integrity:
		status.apply_damage(previous_integrity - next_integrity)
	elif int(plan.get("hits", 0)) > 0:
		status.state = AIR_ASSET_STATUS.STATE_HIT
	status.metadata["air_defense"] = {"outcome": String(plan.get("outcome", "")), "hits": int(plan.get("hits", 0)),
		"hull_percent": int(plan.get("hull_percent", 100)), "event_id": String(plan.get("event_id", ""))}
	return Dictionary(status.to_snapshot()).duplicate(true)


## Status after a ground service repair: integrity full, state intact, warning off.
## Terminal states (destroyed / crashed) are not repaired here.
static func repaired_status_snapshot(prior: Dictionary, event_id: String = "") -> Dictionary:
	if prior.is_empty() or AIR_ASSET_STATUS.is_terminal_state(String(prior.get("state", ""))):
		return {}
	var status = AIR_ASSET_STATUS.from_dict(prior.duplicate(true))
	status.integrity = int(status.max_integrity)
	status.state = AIR_ASSET_STATUS.STATE_INTACT
	status.warning_visible = false
	status.locked_by_unit_id = ""
	status.threat_weapon_id = ""
	status.last_reason = "ground_service_repair"
	if not event_id.is_empty():
		status.last_event_id = event_id
	return Dictionary(status.to_snapshot()).duplicate(true)
