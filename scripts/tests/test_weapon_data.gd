extends SceneTree

const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")

func _init() -> void:
	var passed: int = 0
	var failed: int = 0

	# Test 1: All weapon IDs are valid
	for weapon_id in ["smg", "rifle", "rail_gun"]:
		var weapon: Dictionary = WEAPON_DATA_SCRIPT.get_weapon(weapon_id)
		if weapon.get("id", "") == weapon_id:
			passed += 1
			print("PASS: get_weapon('%s') returns correct id" % weapon_id)
		else:
			failed += 1
			print("FAIL: get_weapon('%s') returned id='%s'" % [weapon_id, weapon.get("id", "")])

	# Test 2: SMG has fastest fire rate
	var smg_ticks: int = WEAPON_DATA_SCRIPT.get_ticks_between_attacks("smg")
	var rifle_ticks: int = WEAPON_DATA_SCRIPT.get_ticks_between_attacks("rifle")
	var rail_ticks: int = WEAPON_DATA_SCRIPT.get_ticks_between_attacks("rail_gun")
	if smg_ticks < rifle_ticks and rifle_ticks < rail_ticks:
		passed += 1
		print("PASS: fire rate ordering smg(%d) < rifle(%d) < rail_gun(%d)" % [smg_ticks, rifle_ticks, rail_ticks])
	else:
		failed += 1
		print("FAIL: fire rate ordering smg(%d) rifle(%d) rail_gun(%d)" % [smg_ticks, rifle_ticks, rail_ticks])

	# Test 3: Rail gun has highest damage
	var smg_dmg: int = WEAPON_DATA_SCRIPT.get_damage_per_hit("smg")
	var rifle_dmg: int = WEAPON_DATA_SCRIPT.get_damage_per_hit("rifle")
	var rail_dmg: int = WEAPON_DATA_SCRIPT.get_damage_per_hit("rail_gun")
	if smg_dmg < rifle_dmg and rifle_dmg < rail_dmg:
		passed += 1
		print("PASS: damage ordering smg(%d) < rifle(%d) < rail_gun(%d)" % [smg_dmg, rifle_dmg, rail_dmg])
	else:
		failed += 1
		print("FAIL: damage ordering smg(%d) rifle(%d) rail_gun(%d)" % [smg_dmg, rifle_dmg, rail_dmg])

	# Test 4: Rail gun uses 2x sprite scale
	var rail_scale: Vector2 = WEAPON_DATA_SCRIPT.get_sprite_scale("rail_gun")
	if rail_scale == Vector2(2.0, 2.0):
		passed += 1
		print("PASS: rail_gun sprite_scale is 2x")
	else:
		failed += 1
		print("FAIL: rail_gun sprite_scale is %s" % str(rail_scale))

	# Test 5: Normalize legacy weapon IDs
	if WEAPON_DATA_SCRIPT._normalize_weapon_id("special") == "rail_gun":
		passed += 1
		print("PASS: 'special' normalizes to 'rail_gun'")
	else:
		failed += 1
		print("FAIL: 'special' normalizes to '%s'" % WEAPON_DATA_SCRIPT._normalize_weapon_id("special"))

	if WEAPON_DATA_SCRIPT._normalize_weapon_id("sonderwaffe") == "rail_gun":
		passed += 1
		print("PASS: 'sonderwaffe' normalizes to 'rail_gun'")
	else:
		failed += 1
		print("FAIL: 'sonderwaffe' normalizes to '%s'" % WEAPON_DATA_SCRIPT._normalize_weapon_id("sonderwaffe"))

	# Test 6: Display names
	if WEAPON_DATA_SCRIPT.get_display_name("smg") == "Maschinenpistole":
		passed += 1
		print("PASS: smg display_name is Maschinenpistole")
	else:
		failed += 1
		print("FAIL: smg display_name is '%s'" % WEAPON_DATA_SCRIPT.get_display_name("smg"))

	if WEAPON_DATA_SCRIPT.get_display_name("rifle") == "Sturmgewehr":
		passed += 1
		print("PASS: rifle display_name is Sturmgewehr")
	else:
		failed += 1
		print("FAIL: rifle display_name is '%s'" % WEAPON_DATA_SCRIPT.get_display_name("rifle"))

	if WEAPON_DATA_SCRIPT.get_display_name("rail_gun") == "Schienenkanone":
		passed += 1
		print("PASS: rail_gun display_name is Schienenkanone")
	else:
		failed += 1
		print("FAIL: rail_gun display_name is '%s'" % WEAPON_DATA_SCRIPT.get_display_name("rail_gun"))

	# Test 7: Asset paths
	var rifle_se_path: String = WEAPON_DATA_SCRIPT.get_asset_path("rifle", "SE")
	if rifle_se_path == "res://Assets/kenney_space-kit/Isometric/weapon_rifle_SE.png":
		passed += 1
		print("PASS: rifle SE asset path correct")
	else:
		failed += 1
		print("FAIL: rifle SE asset path is '%s'" % rifle_se_path)

	var smg_sw_path: String = WEAPON_DATA_SCRIPT.get_asset_path("smg", "SW")
	if smg_sw_path == "res://Assets/kenney_space-kit/Isometric/weapon_gun_SW.png":
		passed += 1
		print("PASS: smg SW asset path correct")
	else:
		failed += 1
		print("FAIL: smg SW asset path is '%s'" % smg_sw_path)

	# Test 8: Invalid weapon ID falls back to default
	var invalid_weapon: Dictionary = WEAPON_DATA_SCRIPT.get_weapon("nonexistent")
	if invalid_weapon.get("id", "") == "rifle":
		passed += 1
		print("PASS: invalid weapon ID falls back to rifle")
	else:
		failed += 1
		print("FAIL: invalid weapon ID returned '%s'" % invalid_weapon.get("id", ""))

	# Test 9: get_all_weapon_ids
	var all_ids: PackedStringArray = WEAPON_DATA_SCRIPT.get_all_weapon_ids()
	if all_ids.size() == 3:
		passed += 1
		print("PASS: get_all_weapon_ids returns 3 weapons")
	else:
		failed += 1
		print("FAIL: get_all_weapon_ids returned %d weapons" % all_ids.size())

	print("\n=== WEAPON DATA TESTS: %d passed, %d failed ===" % [passed, failed])
	if failed > 0:
		print("SOME TESTS FAILED")
	else:
		print("ALL TESTS PASSED")
	quit()
