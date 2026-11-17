extends SceneTree

## E1: the distance to the target (three fixed zones) enters the hit chance.
## Every number is read from the real damage resolution (SimulationRoot._apply_damage_effect,
## signal damage_effect_resolved -> hit_chance_resolved); the test does not rebuild the formula.
## "neutral" = the chance the same shot gets with weapon "none" (no zone modifier). The test unit
## itself adds a small constant offset to the input chance, so the checks compare against neutral.

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const MAP_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TILE_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX_GRID_SCRIPT: GDScript = preload("res://scripts/terrain/hex_grid.gd")

const TILE: float = 72.0
const INPUT: float = 0.5
const EPS: float = 0.0001
# Representative distances in tiles: near, mid, far.
const NEAR_TILES: int = 4
const MID_TILES: int = 9
const FAR_TILES: int = 22
# Expected table (from the order brief): near, mid, far.
const TABLE: Dictionary = {
	"pistol": [0.10, -0.15, 0.00],
	"smg": [0.15, -0.10, 0.00],
	"rifle": [0.00, 0.05, -0.10],
	"sniper": [-0.20, 0.00, 0.10],
	"rail_gun": [-0.10, 0.00, -0.05],
	"rocket_launcher": [-0.10, 0.00, 0.00],
	"none": [0.00, 0.00, 0.00],
	"medictool": [0.00, 0.00, 0.00],
}

var _passed: int = 0
var _failed: int = 0
var _root: Node
var _simulation
var _attacker: Node2D
var _target: Node2D
var _captured: Array = []
var _neutral: float = 0.0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== E1 range band hit chance verifier ===")
	_setup()
	_test_zone_constants_and_bands()
	_test_table_per_weapon_and_zone()
	_test_zone_borders_through_real_shot()
	_test_clamping()
	_test_weapon_order()
	_test_support_and_none()
	_test_weapon_without_key()
	_test_fractional_distance_legacy()
	_test_active_weapon_fallback()
	_test_hex_branch()
	_test_hex_moving_shooter()
	_root.free()
	if _hex_scene != null:
		_hex_scene.free()
	print("combat_range_band_hit_chance_verifier passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _setup() -> void:
	_root = Node.new()
	get_root().add_child(_root)
	var registry = UNIT_REGISTRY_SCRIPT.new()
	registry.name = "UnitRegistry"
	_root.add_child(registry)
	_simulation = SIMULATION_ROOT_SCRIPT.new()
	_simulation.name = "SimulationRoot"
	_simulation.unit_registry_path = NodePath("../UnitRegistry")
	_root.add_child(_simulation)
	_simulation.set_combat_rng_seed(7)
	_attacker = _make_unit("e1_attacker", "team_alpha", "blue", Vector2.ZERO)
	_target = _make_unit("e1_target", "team_bravo", "red", Vector2(TILE, 0.0))
	_root.add_child(_attacker)
	_root.add_child(_target)
	registry.call("register_unit", _attacker.get_unit_id(), _attacker)
	registry.call("register_unit", _target.get_unit_id(), _target)
	_simulation.damage_effect_resolved.connect(func(result: Dictionary) -> void: _captured.append(result))
	_neutral = _shot("none", 4.0)
	print("neutral chance for input %.2f: %.4f" % [INPUT, _neutral])


## One real shot at the given distance in tiles; returns the resolved hit chance.
func _shot(weapon_id: String, tiles: float, input_chance: float = INPUT) -> float:
	_target.global_position = Vector2(tiles * TILE, 0.0)
	_captured.clear()
	_simulation.call("_apply_damage_effect", {
		"effect_type": "damage",
		"unit_id": _target.get_unit_id(),
		"attacker_unit_id": _attacker.get_unit_id(),
		"attacker_team_id": _attacker.get_team_id(),
		"weapon_id": weapon_id,
		"damage": 1,
		"hit_chance": input_chance,
		"damage_multiplier": 1.0,
		"target_cover_override": 0.0,
		"roll_override": 0.0,
	})
	if _captured.is_empty():
		return -1.0
	return float(Dictionary(_captured[0]).get("hit_chance_resolved", -1.0))


func _is(got: float, expected: float) -> bool:
	return absf(got - expected) < EPS


func _test_zone_constants_and_bands() -> void:
	var constants: Dictionary = WEAPON_DATA_SCRIPT.get_script_constant_map()
	_assert(int(constants.get("RANGE_BAND_NEAR_MAX_TILES", -1)) == 6, "RANGE_BAND_NEAR_MAX_TILES is 6")
	_assert(int(constants.get("RANGE_BAND_MID_MAX_TILES", -1)) == 18, "RANGE_BAND_MID_MAX_TILES is 18")
	var bands: Dictionary = {0.0: "near", 1.0: "near", 6.0: "near", 7.0: "mid", 18.0: "mid", 19.0: "far", 40.0: "far"}
	for tiles in bands.keys():
		_assert(String(WEAPON_DATA_SCRIPT.call("get_range_band", float(tiles))) == String(bands[tiles]), "band at %s tiles is %s" % [tiles, bands[tiles]])


func _test_table_per_weapon_and_zone() -> void:
	var zones: Array = [NEAR_TILES, MID_TILES, FAR_TILES]
	var zone_names: Array = ["near", "mid", "far"]
	for weapon_id in TABLE.keys():
		var expected: Array = TABLE[weapon_id]
		for i in range(3):
			var got: float = _shot(String(weapon_id), float(zones[i]))
			_assert(_is(got, _neutral + float(expected[i])), "%s %s (%d tiles): chance %.3f = neutral %.3f %+.2f" % [weapon_id, zone_names[i], zones[i], got, _neutral, float(expected[i])])
	_assert(_is(_shot("smg", 4.0), _neutral + 0.15), "smg at 4 tiles: neutral + 0.15")
	_assert(_is(_shot("smg", 9.0), _neutral - 0.10), "smg at 9 tiles: neutral - 0.10")


func _test_zone_borders_through_real_shot() -> void:
	# sniper: near -0.20, mid 0.00, far +0.10
	_assert(_is(_shot("sniper", 6.0), _neutral - 0.20), "sniper at exactly 6 tiles counts as near (neutral - 0.20)")
	_assert(_is(_shot("sniper", 7.0), _neutral), "sniper at 7 tiles counts as mid (neutral)")
	_assert(_is(_shot("sniper", 18.0), _neutral), "sniper at exactly 18 tiles counts as mid (neutral)")
	_assert(_is(_shot("sniper", 19.0), _neutral + 0.10), "sniper at 19 tiles counts as far (neutral + 0.10)")
	# rifle: near 0.00, mid +0.05, far -0.10
	_assert(_is(_shot("rifle", 6.0), _neutral), "rifle at 6 tiles is near (neutral)")
	_assert(_is(_shot("rifle", 7.0), _neutral + 0.05), "rifle at 7 tiles is mid (neutral + 0.05)")
	_assert(_is(_shot("rifle", 18.0), _neutral + 0.05), "rifle at 18 tiles is mid (neutral + 0.05)")
	_assert(_is(_shot("rifle", 19.0), _neutral - 0.10), "rifle at 19 tiles is far (neutral - 0.10)")


func _test_clamping() -> void:
	# input 0.90 + 0.15 (smg near) is above 1.0 -> capped at 0.95
	_assert(_is(_shot("smg", 3.0, 0.90), 0.95), "smg near with input 0.90 stays at the upper limit 0.95")
	# input 0.10 - 0.15 (pistol mid) is below 0 -> raised to 0.05
	_assert(_is(_shot("pistol", 10.0, 0.10), 0.05), "pistol mid with input 0.10 stays at the lower limit 0.05")
	# Order "add first, then clamp": input 1.05 + unit offset + sniper near (-0.20) stays below the cap.
	# Right: 1.05 + offset - 0.20 (offset = neutral - input, about -0.011) = about 0.839.
	# Wrong (clamp first, then subtract): 0.95 - 0.20 = 0.75.
	var offset: float = _neutral - INPUT
	var summed: float = _shot("sniper", 4.0, 1.05)
	_assert(_is(summed, 1.05 + offset - 0.20) and absf(summed - 0.75) > 0.05, "sniper near with input 1.05: add first, then clamp (%.4f = 1.05 %+.4f - 0.20, not 0.75)" % [summed, offset])
	# Plain addition without any clamp: pistol mid (-0.15) with input 0.30 -> 0.30 + offset - 0.15 (about 0.139).
	_assert(_is(_shot("pistol", 10.0, 0.30), 0.30 + offset - 0.15), "pistol mid with input 0.30: plain addition 0.30 + offset - 0.15")


func _test_weapon_order() -> void:
	# Same input for everybody: the order follows the zone modifier alone.
	var n_smg: float = _shot("smg", 4.0)        # neutral + 0.15
	var n_pistol: float = _shot("pistol", 4.0)  # neutral + 0.10
	var n_rifle: float = _shot("rifle", 4.0)    # neutral + 0.00
	var n_sniper: float = _shot("sniper", 4.0)  # neutral - 0.20
	_assert(n_smg > n_pistol and n_pistol > n_rifle and n_rifle > n_sniper, "near, equal skill: smg (+0.15) > pistol (+0.10) > rifle (0) > sniper (-0.20)")
	var m_rifle: float = _shot("rifle", 15.0)    # +0.05
	var m_sniper: float = _shot("sniper", 15.0)  # 0
	var m_smg: float = _shot("smg", 15.0)        # -0.10
	var m_pistol: float = _shot("pistol", 15.0)  # -0.15
	_assert(m_rifle > m_sniper and m_sniper > m_smg and m_smg > m_pistol, "15 tiles, equal skill: rifle (+0.05) > sniper (0) > smg (-0.10) > pistol (-0.15)")
	var f_sniper: float = _shot("sniper", 25.0)  # +0.10
	var f_rifle: float = _shot("rifle", 25.0)    # -0.10
	_assert(f_sniper > f_rifle, "far (25 tiles), equal skill: sniper (+0.10) > rifle (-0.10)")
	# With the real catalog base chances (pistol/smg 0.40, rifle 0.45, sniper 0.55) the unit offset is
	# the same for all of them, so the final values are input + offset + modifier.
	var offset: float = _neutral - INPUT
	var c_smg: float = _shot("smg", 4.0, float(WEAPON_DATA_SCRIPT.get_base_hit_chance("smg")))        # 0.40 + 0.15
	var c_pistol: float = _shot("pistol", 4.0, float(WEAPON_DATA_SCRIPT.get_base_hit_chance("pistol"))) # 0.40 + 0.10
	var c_rifle: float = _shot("rifle", 4.0, float(WEAPON_DATA_SCRIPT.get_base_hit_chance("rifle")))   # 0.45 + 0.00
	var c_sniper: float = _shot("sniper", 4.0, float(WEAPON_DATA_SCRIPT.get_base_hit_chance("sniper"))) # 0.55 - 0.20
	_assert(_is(c_smg, 0.55 + offset) and _is(c_pistol, 0.50 + offset) and _is(c_rifle, 0.45 + offset) and _is(c_sniper, 0.35 + offset), "near, catalog base chances: smg 0.55 > pistol 0.50 > rifle 0.45 > sniper 0.35 (plus unit offset)")
	var c_sniper_far: float = _shot("sniper", 25.0, float(WEAPON_DATA_SCRIPT.get_base_hit_chance("sniper")))  # 0.55 + 0.10
	var c_rifle_far: float = _shot("rifle", 25.0, float(WEAPON_DATA_SCRIPT.get_base_hit_chance("rifle")))    # 0.45 - 0.10
	_assert(_is(c_sniper_far, 0.65 + offset) and _is(c_rifle_far, 0.35 + offset), "far (25 tiles), catalog base chances: sniper 0.65, rifle 0.35 (plus unit offset)")


func _test_support_and_none() -> void:
	for weapon_id in ["none", "medictool"]:
		for tiles in [2.0, 6.0, 9.0, 19.0, 30.0]:
			var got: float = _shot(String(weapon_id), float(tiles))
			_assert(_is(got, _neutral), "%s at %s tiles: no zone modifier (%.3f)" % [weapon_id, tiles, got])
	# (Shots without weapon id in the effect use the active weapon of the shooter: see _test_active_weapon_fallback.)


func _test_weapon_without_key() -> void:
	var no_key: Dictionary = {"id": "test_gun", "base_hit_chance": 0.5, "effective_tile_range": 30}
	for tiles in [1.0, 6.0, 12.0, 25.0]:
		_assert(_is(float(WEAPON_DATA_SCRIPT.call("get_range_band_hit_modifier_for_weapon", no_key, float(tiles))), 0.0), "weapon dictionary without range_band_hit_modifier: modifier 0 at %s tiles" % tiles)
	var with_key: Dictionary = {"range_band_hit_modifier": {"near": 0.2, "mid": -0.3, "far": 0.4}}
	_assert(_is(float(WEAPON_DATA_SCRIPT.call("get_range_band_hit_modifier_for_weapon", with_key, 3.0)), 0.2), "weapon dictionary with key: near value")
	_assert(_is(float(WEAPON_DATA_SCRIPT.call("get_range_band_hit_modifier_for_weapon", with_key, 10.0)), -0.3), "weapon dictionary with key: mid value")
	_assert(_is(float(WEAPON_DATA_SCRIPT.call("get_range_band_hit_modifier_for_weapon", with_key, 20.0)), 0.4), "weapon dictionary with key: far value")
	var partial: Dictionary = {"range_band_hit_modifier": {"near": 0.2}}
	_assert(_is(float(WEAPON_DATA_SCRIPT.call("get_range_band_hit_modifier_for_weapon", partial, 10.0)), 0.0), "weapon dictionary with partial key: missing zone gives 0")


func _test_fractional_distance_legacy() -> void:
	# The range check does not round (world distance against the range), so neither does the zone.
	_assert(_is(_shot("sniper", 6.0), _neutral - 0.20), "6.0 tiles is near (sniper, neutral - 0.20)")
	_assert(_is(_shot("sniper", 6.4), _neutral), "6.4 tiles is mid, not rounded down to near (sniper, neutral)")
	_assert(_is(_shot("sniper", 18.0), _neutral), "18.0 tiles is mid (sniper, neutral)")
	_assert(_is(_shot("sniper", 18.4), _neutral + 0.10), "18.4 tiles is far, not rounded down to mid (sniper, neutral + 0.10)")
	_assert(_is(_shot("rifle", 18.4), _neutral - 0.10), "18.4 tiles is far (rifle, neutral - 0.10)")


func _test_active_weapon_fallback() -> void:
	# An effect without weapon_id uses the active weapon of the shooter (this is the overwatch case).
	_attacker.weapon_1_id = "smg"
	_attacker.weapon_2_id = "smg"
	_assert(String(_attacker.call("get_active_weapon_id")) == "smg", "fixture: the active weapon of the test shooter is smg")
	_assert(_is(_shot("", 4.0), _neutral + 0.15), "no weapon_id in the effect, active weapon smg near: neutral + 0.15")
	_assert(_is(_shot("", 9.0), _neutral - 0.10), "no weapon_id in the effect, active weapon smg mid: neutral - 0.10")
	_attacker.weapon_1_id = "rifle"
	_attacker.weapon_2_id = "rifle"
	_assert(_is(_shot("", 4.0), _neutral), "no weapon_id in the effect, active weapon rifle near: neutral")


## Real hex ground runtime (setup like hex_movement_verifier / hex_ground_lifecycle_verifier):
## shooter and targets stand on hex cells of one row, the zone counts hex steps.
var _hex_sim
var _hex_terrain
var _hex_units
var _hex_scene: Node
var _hex_neutral: float = 0.0


func _build_hex_rig() -> bool:
	_hex_scene = Node.new()
	get_root().add_child(_hex_scene)
	_hex_terrain = REGISTRY_SCRIPT.new()
	_hex_terrain.name = "HexTerrain"
	_hex_scene.add_child(_hex_terrain)
	_hex_terrain.configure_iso_grid(Vector2.ZERO, 64, 32, "hex_axial_v1")
	for x in range(26):
		for y in range(2):
			_hex_terrain.register_tile(TILE_SCRIPT.new({"tile_id": "r%d_%d" % [x, y], "grid_position": Vector2i(x, y)}))
	_hex_terrain.register_tile(TILE_SCRIPT.new({"tile_id": "r0_7", "grid_position": Vector2i(0, 7)}))
	_hex_units = UNIT_REGISTRY_SCRIPT.new()
	_hex_units.name = "HexUnits"
	_hex_scene.add_child(_hex_units)
	_hex_sim = SIMULATION_ROOT_SCRIPT.new()
	_hex_sim.name = "HexSim"
	_hex_scene.add_child(_hex_sim)
	_hex_sim.unit_registry_path = _hex_sim.get_path_to(_hex_units)
	_hex_sim.terrain_registry_path = _hex_sim.get_path_to(_hex_terrain)
	_hex_sim.set_combat_rng_seed(7)
	var map = MAP_SCRIPT.create_empty("range_band_hex", Vector2i(26, 8), Vector2.ZERO, 64, 32, 3, "hex_axial_v1")
	map.set_tactical_grid_rules("hex_tactical_v1")
	_hex_sim.configure_hex_ground_runtime(map, _hex_terrain)
	_hex_sim.damage_effect_resolved.connect(func(result: Dictionary) -> void: _captured.append(result))
	var batch: Array[Dictionary] = []
	_hex_add_unit("hx_att", "team_alpha", Vector2i(0, 0), batch)
	for d in [4, 6, 7, 9, 18, 19, 22]:
		_hex_add_unit("hx_t%d" % d, "team_bravo", Vector2i(d, 0), batch)
	# cells off the row where hex steps and world distance fall into DIFFERENT zones (found by search, see _test_hex_off_row)
	_hex_add_unit("hx_ws_near", "team_bravo", Vector2i(0, 7), batch)
	_hex_add_unit("hx_ws_far", "team_bravo", Vector2i(18, 1), batch)
	# registered with the root but never admitted to the ground runtime: no hex state
	var loose: Node2D = _make_unit("hx_loose", "team_bravo", "red", _hex_terrain.grid_to_world(Vector2i(9, 1)))
	_hex_scene.add_child(loose)
	_hex_units.register_unit("hx_loose", loose)
	_hex_sim.register_known_unit("hx_loose", loose)
	var admitted: Dictionary = _hex_sim.admit_hex_ground_units(batch)
	return bool(admitted.get("ok", false))


func _hex_add_unit(unit_id: String, team_id: String, grid: Vector2i, batch: Array[Dictionary]) -> void:
	var unit: Node2D = _make_unit(unit_id, team_id, "blue" if team_id == "team_alpha" else "red", _hex_terrain.grid_to_world(grid))
	_hex_scene.add_child(unit)
	_hex_units.register_unit(unit_id, unit)
	_hex_sim.register_known_unit(unit_id, unit)
	batch.append({"unit_id": unit_id, "grid": grid})


func _hex_shot(weapon_id: String, target_id: String, input_chance: float = INPUT) -> Dictionary:
	_captured.clear()
	_hex_sim.call("_apply_damage_effect", {
		"effect_type": "damage",
		"unit_id": target_id,
		"attacker_unit_id": "hx_att",
		"attacker_team_id": "team_alpha",
		"weapon_id": weapon_id,
		"damage": 1,
		"hit_chance": input_chance,
		"damage_multiplier": 1.0,
		"target_cover_override": 0.0,
		"roll_override": 0.0,
	})
	if _captured.is_empty():
		return {}
	return Dictionary(_captured[0])


func _test_hex_branch() -> void:
	var rig_ok: bool = _build_hex_rig()
	_assert(rig_ok and bool(_hex_sim.call("is_hex_ground_runtime_active")), "fixture: hex ground runtime is active and the units are admitted")
	if not rig_ok:
		return
	var neutral_result: Dictionary = _hex_shot("none", "hx_t4")
	_hex_neutral = float(neutral_result.get("hit_chance_resolved", -1.0))
	_assert(_hex_neutral > 0.0, "hex: neutral shot resolves (%.4f)" % _hex_neutral)
	var shooter_cell: Vector2i = Vector2i(_hex_sim.call("get_hex_unit_state", "hx_att").grid)
	_assert(shooter_cell == Vector2i(0, 0) and Vector2i(_hex_sim.call("get_hex_unit_state", "hx_t19").grid) == Vector2i(19, 0), "fixture: shooter on cell (0,0), target t19 on cell (19,0), 19 hex steps")
	var cases: Array = [
		["sniper", "hx_t6", -0.20, "6 hex steps = near"],
		["sniper", "hx_t7", 0.0, "7 hex steps = mid"],
		["sniper", "hx_t18", 0.0, "18 hex steps = mid"],
		["sniper", "hx_t19", 0.10, "19 hex steps = far"],
		["rifle", "hx_t19", -0.10, "19 hex steps = far (rifle)"],
		["rifle", "hx_t7", 0.05, "7 hex steps = mid (rifle)"],
		["smg", "hx_t4", 0.15, "4 hex steps = near (smg)"],
		["smg", "hx_t9", -0.10, "9 hex steps = mid (smg)"],
	]
	for c in cases:
		var got: float = float(_hex_shot(String(c[0]), String(c[1])).get("hit_chance_resolved", -1.0))
		_assert(_is(got, _hex_neutral + float(c[2])), "hex %s: %s -> neutral %+.2f (%.4f)" % [c[0], c[3], float(c[2]), got])
	# No hex state for the target: no distance, no modifier (not a script error).
	# smg is the discriminating weapon: at the loose target's world distance (below) the legacy branch would say mid = -0.10.
	var loose_world: float = _hex_world_tiles(Vector2i(0, 0), Vector2i(9, 1))
	_assert(String(WEAPON_DATA_SCRIPT.get_range_band(loose_world)) == "mid", "fixture: the target without hex state is %.2f world tiles away (mid, smg would get -0.10 by world distance)" % loose_world)
	var loose_smg: float = float(_hex_shot("smg", "hx_loose").get("hit_chance_resolved", -1.0))
	var loose_none: float = float(_hex_shot("none", "hx_loose").get("hit_chance_resolved", -1.0))
	_assert(loose_smg > 0.0 and _is(loose_smg, loose_none), "hex: target without hex state gets modifier 0 with smg (%.4f = %.4f)" % [loose_smg, loose_none])
	_test_hex_off_row()
	# Clamp order in hex too: input 1.05, sniper near (6 steps)
	var hex_offset: float = _hex_neutral - INPUT
	var summed: float = float(_hex_shot("sniper", "hx_t6", 1.05).get("hit_chance_resolved", -1.0))
	_assert(_is(summed, 1.05 + hex_offset - 0.20), "hex: sniper near with input 1.05: add first, then clamp (%.4f)" % summed)


## World distance between two hex cells in tiles, measured like the legacy branch (world distance / world units per tile).
func _hex_world_tiles(from_cell: Vector2i, to_cell: Vector2i) -> float:
	var upt: float = WEAPON_DATA_SCRIPT.get_world_units_per_tile(_hex_terrain)
	return Vector2(_hex_terrain.grid_to_world(from_cell)).distance_to(Vector2(_hex_terrain.grid_to_world(to_cell))) / upt


## Targets off the row: hex steps and world distance give DIFFERENT zones, so only the hex step count passes.
func _test_hex_off_row() -> void:
	# Search proof that such cells exist (cells up to 25 steps from (0,0) on this grid).
	var differing: int = 0
	for q in range(0, 26):
		for r in range(0, 26):
			var steps: int = HEX_GRID_SCRIPT.distance(Vector2i(0, 0), Vector2i(q, r))
			if steps >= 1 and steps <= 25 and WEAPON_DATA_SCRIPT.get_range_band(float(steps)) != WEAPON_DATA_SCRIPT.get_range_band(_hex_world_tiles(Vector2i(0, 0), Vector2i(q, r))):
				differing += 1
	_assert(differing > 0, "fixture: %d cells (q,r >= 0, up to 25 steps) have different zones by hex steps and by world distance" % differing)
	var cells: Array = [
		["hx_ws_near", Vector2i(0, 7), "sniper", 0.0, "near", "mid"],
		["hx_ws_near", Vector2i(0, 7), "smg", -0.10, "near", "mid"],
		["hx_ws_far", Vector2i(18, 1), "sniper", 0.10, "mid", "far"],
		["hx_ws_far", Vector2i(18, 1), "rifle", -0.10, "mid", "far"],
	]
	for c in cells:
		var cell: Vector2i = c[1]
		var steps: int = HEX_GRID_SCRIPT.distance(Vector2i(0, 0), cell)
		var world: float = _hex_world_tiles(Vector2i(0, 0), cell)
		var steps_zone: String = String(WEAPON_DATA_SCRIPT.get_range_band(float(steps)))
		var world_zone: String = String(WEAPON_DATA_SCRIPT.get_range_band(world))
		var label: String = "cell (%d,%d): %d steps = %s, world distance %.2f tiles = %s" % [cell.x, cell.y, steps, steps_zone, world, world_zone]
		_assert(steps_zone != world_zone, "fixture: " + label)
		var got: float = float(_hex_shot(String(c[2]), String(c[0])).get("hit_chance_resolved", -1.0))
		_assert(_is(got, _hex_neutral + float(c[3])), "hex %s by steps (%s): neutral %+.2f (%.4f)" % [c[2], label, float(c[3]), got])


func _test_hex_moving_shooter() -> void:
	if _hex_sim == null:
		return
	# The shooter walks from (0,0) towards (3,0). While it moves, the moving-shot factor applies AFTER the zone modifier:
	# result = clamp(clamp(input + offset + zone) * factor). Target t6 stays within 6 steps all the way (near, sniper -0.20).
	_hex_sim.enqueue_command({"type": "move_to_position", "unit_id": "hx_att", "team_id": "team_alpha", "target_position": _hex_terrain.grid_to_world(Vector2i(3, 0)), "move_speed_factor": 0.2, "command_token": "move_hx_att", "requeue_until_target": true})
	for i in range(3):
		_hex_sim._physics_process(0.1)
	var state: Dictionary = _hex_sim.call("get_hex_unit_state", "hx_att")
	var moving: bool = bool(Dictionary(state.get("movement_state", {})).get("moving", false))
	_assert(moving, "fixture: the shooter is moving on the hex ground")
	var distance: int = int(HEX_GRID_SCRIPT.distance(Vector2i(state.get("grid", Vector2i.ZERO)), Vector2i(6, 0)))
	_assert(distance <= 6 and distance >= 3, "fixture: the moving shooter is %d steps from target t6 (near zone)" % distance)
	var none_result: Dictionary = _hex_shot("none", "hx_t6")
	var sniper_result: Dictionary = _hex_shot("sniper", "hx_t6")
	var factor: float = float(sniper_result.get("moving_shot_accuracy_multiplier", 1.0))
	var offset: float = _hex_neutral - INPUT
	var right: float = clampf(clampf(INPUT + offset - 0.20, 0.05, 0.95) * factor, 0.05, 0.95)
	var wrong: float = clampf(clampf(INPUT + offset, 0.05, 0.95) * factor - 0.20, 0.05, 0.95)
	var got: float = float(sniper_result.get("hit_chance_resolved", -1.0))
	_assert(bool(sniper_result.get("attacker_moving", false)) and factor < 1.0, "moving shot: the resolution reports a moving shooter with factor %.4f" % factor)
	_assert(_is(got, right) and absf(right - wrong) > 0.005, "moving shot: (neutral-input offset %+.4f + zone -0.20) x factor %.4f = %.4f, not zone after the factor (%.4f); got %.4f" % [offset, factor, right, wrong, got])
	_assert(_is(float(none_result.get("hit_chance_resolved", -1.0)), clampf((INPUT + offset) * factor, 0.05, 0.95)), "moving shot: weapon none gets only the factor")


func _make_unit(unit_id: String, team_id: String, fireteam_id: String, position: Vector2) -> Node2D:
	var unit: Node2D = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.global_position = position
	unit.weapon_1_id = "rifle"
	unit.weapon_2_id = "rifle"
	return unit


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		print("FAIL: %s" % message)
