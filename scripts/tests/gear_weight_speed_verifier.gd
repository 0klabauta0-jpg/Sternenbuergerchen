extends SceneTree

## Rechnerischer Pruefer: Pistole wiegt wie das Sanitaetswerkzeug (1 kg); nur Anzug laeuft schneller als leichte Ruestung.
## Ohne Einsatzszene: Resolver + TestUnit-Tempo (speed_multiplier) mit leeren Waffenplaetzen.

const RESOLVER_SCRIPT: GDScript = preload("res://scripts/command/loadout_modifier_resolver.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== gear_weight_speed_verifier ===")
	_test_pistol_weight()
	_test_armor_weight_and_speed()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	print("ALL TESTS PASSED" if _failed == 0 else "FAIL")
	quit(1 if _failed > 0 else 0)


func _test_pistol_weight() -> void:
	var resolver = RESOLVER_SCRIPT.new()
	_assert(float(WEAPON_DATA_SCRIPT.call("get_weight", "pistol")) == 1.0, "WeaponData: Pistole 1 kg")
	_assert(float(WEAPON_DATA_SCRIPT.call("get_weight", "medictool")) == 1.0, "WeaponData: Sanitaetswerkzeug 1 kg")
	var pistol_w: float = float(resolver.call("calculate_loadout_weight", {"armor": "suit", "weapon_1": "pistol", "weapon_2": "none"}))
	var med_w: float = float(resolver.call("calculate_loadout_weight", {"armor": "suit", "weapon_1": "medictool", "weapon_2": "none"}))
	var none_w: float = float(resolver.call("calculate_loadout_weight", {"armor": "suit", "weapon_1": "none", "weapon_2": "none"}))
	_assert(pistol_w == med_w, "Resolver: Pistole wiegt so viel wie Sanitaetswerkzeug (%.2f / %.2f)" % [pistol_w, med_w])
	_assert(is_equal_approx(pistol_w - none_w, 1.0), "Resolver: Pistole bringt genau 1 kg Last (%.2f)" % (pistol_w - none_w))


func _test_armor_weight_and_speed() -> void:
	var resolver = RESOLVER_SCRIPT.new()
	var speeds: Dictionary = {}
	var weights: Dictionary = {}
	for armor in ["suit", "light", "medium", "heavy"]:
		var loadout: Dictionary = {"armor": armor, "weapon_1": "none", "weapon_2": "none"}
		weights[armor] = float(resolver.call("calculate_loadout_weight", loadout))
		var mods = resolver.call("resolve_for_unit", "gear_" + armor, loadout)
		var unit = TEST_UNIT_SCRIPT.new()
		unit.apply_identity_config({"unit_id": "gear_" + armor, "team_id": "team_alpha"})
		unit.apply_loadout_modifiers(Dictionary(mods.call("to_dict")))
		speeds[armor] = float(unit.get_combat_speed_multiplier())
		unit.free()
	print("  Tempo: ", speeds, "  Gewicht: ", weights)
	_assert(speeds["suit"] > speeds["light"], "nur Anzug schneller als leicht (%.3f > %.3f)" % [speeds["suit"], speeds["light"]])
	_assert(speeds["light"] > speeds["medium"], "leicht schneller als mittel")
	_assert(speeds["medium"] > speeds["heavy"], "mittel schneller als schwer")
	_assert(weights["suit"] < weights["light"], "Anzug wiegt weniger als leichte Ruestung (%.2f < %.2f)" % [weights["suit"], weights["light"]])
	_assert(weights["light"] < weights["medium"] and weights["medium"] < weights["heavy"], "Gewicht waechst leicht < mittel < schwer")


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
