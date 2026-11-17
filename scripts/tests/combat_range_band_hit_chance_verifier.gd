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
	_root.free()
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
	# A shot without any weapon id must not break and gets no modifier either.
	_assert(_is(_shot("", 4.0), _neutral), "shot without weapon id: no zone modifier")


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
