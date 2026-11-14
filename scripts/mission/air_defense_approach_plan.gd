extends RefCounted
## Ground air defence on a real landing approach: builds the input of the pure
## resolver scripts/combat/air_defense_engagement.gd from map data and turns its
## result into a landing outcome and an AirAssetStatus snapshot.
## Contract: docs/dev/ground_air_defense_engagement_contract.md
## Task: docs/tasks/FLUGABWEHR_ANSCHLUSS_2026_11_14.md
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


## One volley per sample. Terrain masking is not wired yet: line of sight is true.
static func build_volleys(vehicles: Array, samples: Array, height_at: Callable, crew_ready: bool, profile_id: String = APPROACH_PROFILE) -> Array:
	var volleys: Array = []
	for sample in samples:
		var cell: Vector2i = plane_to_cell(Vector2(sample))
		var ship_ground: int = int(height_at.call(cell))
		var contacts: Dictionary = {}
		for vehicle in vehicles:
			contacts[String(vehicle.instance_id)] = {"unit_id": String(vehicle.unit_id), "range_hex": HEX.distance(Vector2i(vehicle.cell), cell),
				"height_delta_levels": AD.height_delta_levels(ship_ground, profile_id, int(vehicle.ground_level)),
				"has_line_of_sight": true, "crew_ready": crew_ready}
		volleys.append({"cell": cell, "contacts": contacts})
	return volleys


static func decision_for_style(approach_style: String) -> String:
	return AD.DECISION_PRESS_ON if approach_style.strip_edges().to_lower() in ["aggressiv", "aggressive"] else AD.DECISION_BREAK_OFF


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


## context: vehicles, start_plane, lz_plane, height_at, crew_ready, pilot_skill,
## seed, model_id, integrity (0..100), approach_style.
static func resolve(context: Dictionary) -> Dictionary:
	var ship: Dictionary = ship_for(String(context.get("model_id", DEFAULT_MODEL)), int(context.get("integrity", 100)))
	if not bool(ship.get("ok", false)):
		return ship
	var height_at: Callable = context.get("height_at")
	var samples: Array = approach_samples(Vector2(context.get("start_plane", Vector2.ZERO)), Vector2(context.get("lz_plane", Vector2.ZERO)))
	var decision: String = decision_for_style(String(context.get("approach_style", "")))
	var result: Dictionary = AD.resolve_approach({
		"seed": String(context.get("seed", "")), "pilot_skill": float(context.get("pilot_skill", 0.5)),
		"ship_model": String(ship.model_id), "ship_stats": ship.stats, "ship_state": ship.state, "decision": decision,
		"volleys": build_volleys(Array(context.get("vehicles", [])), samples, height_at, bool(context.get("crew_ready", false))),
	})
	var plan: Dictionary = summarize(result, String(context.get("seed", "")))
	plan["decision"] = decision
	plan["volley_count"] = samples.size()
	return plan


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
