extends SceneTree

const LOADOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/command/loadout_contract.gd")
const LOADOUT_MODIFIER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/command/loadout_modifier_resolver.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const FOB_SCREEN_SCRIPT: GDScript = preload("res://scripts/meta/fob_screen.gd")

const VISUAL_MAPPING_PATH := "res://data/npc_unit_visual_mapping.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	print("=== TASK_481 Loadout Heavy Weapon Selection ===")
	_test_contract_options_expose_heavy_weapons()
	_test_weapon_values_define_clear_roles()
	_test_preview_and_visual_assets_exist()
	_test_fob_preview_path_uses_weapon_data_catalog()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_481: FAILED")
	else:
		print("TASK_481: ALL PASSED")
	quit(_failed)


func _test_contract_options_expose_heavy_weapons() -> void:
	var primary_ids: Array = Array(LOADOUT_CONTRACT_SCRIPT.call("get_homebase_primary_weapon_ids"))
	var secondary_ids: Array = Array(LOADOUT_CONTRACT_SCRIPT.call("get_homebase_secondary_weapon_ids"))
	var fob_ids: Array = Array(LOADOUT_CONTRACT_SCRIPT.call("get_fob_weapon_ids"))
	for weapon_id in ["smg", "rifle", "sniper", "rail_gun", "rocket_launcher", "medictool"]:
		_assert(primary_ids.has(weapon_id), "Homebase primary exposes %s" % weapon_id)
		_assert(fob_ids.has(weapon_id), "FOB selector exposes %s" % weapon_id)
	for weapon_id in ["none", "smg", "rifle", "sniper", "rail_gun", "rocket_launcher", "medictool"]:
		_assert(secondary_ids.has(weapon_id), "Homebase secondary exposes %s" % weapon_id)
	_assert(fob_ids.has("none"), "FOB selector still exposes explicit none")
	_assert(String(LOADOUT_CONTRACT_SCRIPT.call("get_weapon_label", "sniper")) == "Scharf", "Sniper has compact German-facing label")
	_assert(String(LOADOUT_CONTRACT_SCRIPT.call("get_weapon_label", "rocket_launcher")) == "Rakete", "Rocket launcher has German-facing label")


func _test_weapon_values_define_clear_roles() -> void:
	var rifle_range: int = int(WEAPON_DATA_SCRIPT.call("get_effective_tile_range", "rifle"))
	var sniper_range: int = int(WEAPON_DATA_SCRIPT.call("get_effective_tile_range", "sniper"))
	var rocket_range: int = int(WEAPON_DATA_SCRIPT.call("get_effective_tile_range", "rocket_launcher"))
	var rifle_damage: int = int(WEAPON_DATA_SCRIPT.call("get_damage_per_hit", "rifle"))
	var sniper_damage: int = int(WEAPON_DATA_SCRIPT.call("get_damage_per_hit", "sniper"))
	var rocket_damage: int = int(WEAPON_DATA_SCRIPT.call("get_damage_per_hit", "rocket_launcher"))
	var rocket_ticks: int = int(WEAPON_DATA_SCRIPT.call("get_ticks_between_attacks", "rocket_launcher"))
	var sniper_ticks: int = int(WEAPON_DATA_SCRIPT.call("get_ticks_between_attacks", "sniper"))
	_assert(sniper_range > rifle_range, "Sniper outranges rifle")
	_assert(sniper_damage > rifle_damage, "Sniper hits harder than rifle")
	_assert(rocket_damage > sniper_damage, "Rocket launcher is the heavy hit option")
	_assert(rocket_ticks > sniper_ticks, "Rocket launcher fires slower than sniper")
	_assert(rocket_range < sniper_range, "Rocket launcher is not the long-range precision option")
	_assert(bool(WEAPON_DATA_SCRIPT.call("is_anti_armor_weapon_id", "rocket_launcher")), "Rocket launcher is anti-armor")

	var resolver = LOADOUT_MODIFIER_RESOLVER_SCRIPT.new()
	var sniper_weight: float = float(resolver.call("calculate_loadout_weight", {"armor": "medium", "weapon_1": "sniper", "weapon_2": "none"}))
	var rocket_weight: float = float(resolver.call("calculate_loadout_weight", {"armor": "medium", "weapon_1": "rocket_launcher", "weapon_2": "none"}))
	_assert(rocket_weight > sniper_weight, "Rocket launcher loadout is heavier than sniper")


func _test_preview_and_visual_assets_exist() -> void:
	for weapon_id in ["smg", "rifle", "sniper", "rocket_launcher", "medictool"]:
		var preview_path: String = String(WEAPON_DATA_SCRIPT.call("get_preview_path", weapon_id))
		_assert(preview_path.begins_with("res://"), "%s preview uses project path" % weapon_id)
		_assert(ResourceLoader.exists(preview_path), "%s preview texture exists" % weapon_id)

	var mapping: Dictionary = _load_json_dict(VISUAL_MAPPING_PATH)
	var visual_loadouts: Dictionary = Dictionary(mapping.get("visual_loadouts", {}))
	for loadout_id in ["sniper_rifle", "rocket_launcher", "heavy_blaster"]:
		var loadout: Dictionary = Dictionary(visual_loadouts.get(loadout_id, {}))
		_assert(not loadout.is_empty(), "%s visual loadout exists" % loadout_id)
		_assert(ResourceLoader.exists(String(loadout.get("blaster_path", ""))), "%s weapon model exists" % loadout_id)
	var weapon_visuals: Dictionary = Dictionary(mapping.get("weapon_visual_loadouts", {}))
	_assert(String(weapon_visuals.get("sniper", "")) == "sniper_rifle", "Sniper resolves to sniper visual loadout")
	_assert(String(weapon_visuals.get("rocket_launcher", "")) == "rocket_launcher", "Rocket resolves to rocket visual loadout")


func _test_fob_preview_path_uses_weapon_data_catalog() -> void:
	var fob_screen = FOB_SCREEN_SCRIPT.new()
	for weapon_id in ["sniper", "rocket_launcher", "panzerfaust"]:
		var normalized_id: String = String(WEAPON_DATA_SCRIPT.call("normalize_weapon_id", weapon_id))
		var expected_path: String = String(WEAPON_DATA_SCRIPT.call("get_preview_path", normalized_id))
		_assert(String(fob_screen.call("_get_weapon_preview_path", weapon_id)) == expected_path, "FOB preview path follows WeaponData for %s" % weapon_id)
		_assert(fob_screen.call("_get_weapon_preview_texture", weapon_id) != null, "FOB loads preview texture for %s" % weapon_id)


func _load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
