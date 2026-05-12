extends SceneTree

const LOADOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/command/loadout_contract.gd")
const LOADOUT_MODIFIER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/command/loadout_modifier_resolver.gd")
const HOMEBASE_TEST_SCENE: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_353 Shared Loadout Contract Helper ===")
	_test_contract_aliases_and_defaults()
	await _test_homebase_and_fob_use_shared_contract()
	await _test_ui_options_and_export_keep_canonical_rail_gun()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_353: FAILED")
		quit(1)
	else:
		print("TASK_353: ALL PASSED")
		quit(0)


func _test_contract_aliases_and_defaults() -> void:
	_assert(String(LOADOUT_CONTRACT_SCRIPT.call("normalize_armor_id", "standard", "heavy")) == "heavy", "Armor alias standard resolves through explicit fallback")
	_assert(String(LOADOUT_CONTRACT_SCRIPT.call("normalize_weapon_id", "special", "rifle")) == "rail_gun", "special aliases to canonical WeaponData rail_gun")
	_assert(String(LOADOUT_CONTRACT_SCRIPT.call("normalize_weapon_id", "support_lmg", "rifle")) == "rail_gun", "support_lmg aliases to canonical rail_gun")
	_assert(String(LOADOUT_CONTRACT_SCRIPT.call("normalize_weapon_id", "panzerfaust", "rifle")) == "rocket_launcher", "panzerfaust aliases to rocket_launcher")

	var homebase_default: Dictionary = Dictionary(LOADOUT_CONTRACT_SCRIPT.call("make_member_loadout", "", "", "", "medium", "rifle", "none"))
	_assert(homebase_default.get("armor") == "medium" and homebase_default.get("weapon_1") == "rifle" and homebase_default.get("weapon_2") == "none", "Homebase default strategy is medium/rifle/none")

	var fob_default: Dictionary = Dictionary(LOADOUT_CONTRACT_SCRIPT.call("make_member_loadout", "", "", "", "medium", "smg", "smg"))
	_assert(fob_default.get("armor") == "medium" and fob_default.get("weapon_1") == "smg" and fob_default.get("weapon_2") == "smg", "FOB default strategy is medium/smg/smg")

	var resolver = LOADOUT_MODIFIER_RESOLVER_SCRIPT.new()
	var modifiers = resolver.call("resolve_for_unit", "unit_rail", {"armor": "heavy", "weapon_1": "rail_gun", "weapon_2": "rifle"})
	_assert(modifiers != null and String(modifiers.weapon_1_id) == "special", "Resolver explicitly maps canonical rail_gun to legacy special balance formula")


func _test_homebase_and_fob_use_shared_contract() -> void:
	var homebase: Control = HOMEBASE_TEST_SCENE.instantiate()
	var fob: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(homebase)
	root.add_child(fob)
	await process_frame

	_assert(String(homebase.call("_normalize_loadout_id", "standard")) == "medium", "Homebase armor normalization uses shared standard alias")
	_assert(String(fob.call("_normalize_loadout_id", "standard")) == "medium", "FOB armor normalization uses shared standard alias")
	_assert(String(homebase.call("_normalize_weapon_id", "special")) == "rail_gun", "Homebase special alias keeps rail_gun contract value")
	_assert(String(fob.call("_normalize_weapon_id", "special")) == "rail_gun", "FOB special alias keeps rail_gun contract value")
	_assert(Dictionary(homebase.call("_make_member_loadout", "", "", "")).get("weapon_2") == "none", "Homebase wrapper keeps shared secondary default")
	_assert(Dictionary(fob.call("_make_member_loadout", "", "", "")).get("weapon_2") == "smg", "FOB wrapper keeps shared secondary default")

	homebase.queue_free()
	fob.queue_free()
	await process_frame


func _test_ui_options_and_export_keep_canonical_rail_gun() -> void:
	var homebase: Control = HOMEBASE_TEST_SCENE.instantiate()
	var fob: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(homebase)
	root.add_child(fob)
	await process_frame

	var homebase_primary_options: Array = Array(homebase.call("_get_homebase_primary_weapon_options"))
	var homebase_secondary_options: Array = Array(homebase.call("_get_homebase_secondary_weapon_options"))
	_assert(homebase_primary_options.has("rail_gun"), "Homebase primary options expose canonical rail_gun")
	_assert(homebase_secondary_options.has("rail_gun"), "Homebase secondary options expose canonical rail_gun")
	_assert(String(homebase.call("_build_homebase_loadout_option_label", "rail_gun")) == "Railgun", "Homebase rail_gun label comes from shared contract")

	var option_button := OptionButton.new()
	fob.call("_populate_weapon_option_button", option_button, "special")
	var fob_option_ids: PackedStringArray = _collect_option_metadata(option_button)
	_assert(fob_option_ids.has("rail_gun"), "FOB weapon selector exposes canonical rail_gun")
	_assert(_selected_metadata_id(option_button) == "rail_gun", "FOB selector preselects special as canonical rail_gun")

	var homebase_loadout: Dictionary = Dictionary(homebase.call("_make_member_loadout", "heavy", "special", "none"))
	var fob_loadout: Dictionary = Dictionary(fob.call("_make_member_loadout", "heavy", "special", "none"))
	_assert(homebase_loadout.get("weapon_1") == "rail_gun", "Homebase export loadout keeps canonical rail_gun")
	_assert(fob_loadout.get("weapon_1") == "rail_gun", "FOB export loadout keeps canonical rail_gun")

	homebase.queue_free()
	fob.queue_free()
	await process_frame


func _collect_option_metadata(option_button: OptionButton) -> PackedStringArray:
	var result: PackedStringArray = []
	for item_index in range(option_button.item_count):
		result.append(String(option_button.get_item_metadata(item_index)).strip_edges())
	return result


func _selected_metadata_id(option_button: OptionButton) -> String:
	if option_button.selected < 0:
		return ""
	return String(option_button.get_item_metadata(option_button.selected)).strip_edges()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
