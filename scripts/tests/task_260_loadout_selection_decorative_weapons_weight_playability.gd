extends SceneTree

const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const LOADOUT_MODIFIER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/command/loadout_modifier_resolver.gd")
const FOB_SCREEN_SCRIPT: GDScript = preload("res://scripts/meta/fob_screen.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const COMBAT_FIRE_DECISION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/combat_fire_decision_resolver.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")

const NPC_VISUAL_MAPPING_PATH: String = "res://data/npc_unit_visual_mapping.json"
const REPORT_PATH: String = "res://docs/reports/playability_loadout_weight_report.md"
const RULES_PATH: String = "res://docs/dev/loadout_playability_rules.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_260 Loadout Selection Decorative Weapons Weight Playability ===")
	_test_weapon_catalog_and_selector_separation()
	_test_weight_resolver_and_snapshot_boundary()
	await _test_fob_none_selection_and_character_weight()
	await _test_mission_visual_none_has_no_hidden_weapon()
	_test_docs_exist()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_weapon_catalog_and_selector_separation() -> void:
	var all_ids: PackedStringArray = WEAPON_DATA_SCRIPT.call("get_all_weapon_ids")
	for playable_id in ["smg", "rifle", "sniper", "rocket_launcher", "medictool", "none"]:
		_assert(all_ids.has(playable_id), "WeaponData exposes gameplay loadout id %s" % playable_id)

	_assert(not bool(WEAPON_DATA_SCRIPT.call("is_attack_weapon_id", "none")), "None is not an attack weapon")
	_assert(not bool(WEAPON_DATA_SCRIPT.call("is_attack_weapon_id", "medictool")), "Medictool stays a support item, not an attack weapon")
	_assert(bool(WEAPON_DATA_SCRIPT.call("is_attack_weapon_id", "sniper")), "Sniper stays a playable attack weapon")
	_assert(float(WEAPON_DATA_SCRIPT.call("get_weight", "none")) == 0.0, "None has zero loadout weight")
	_assert(float(WEAPON_DATA_SCRIPT.call("get_weight", "medictool")) < float(WEAPON_DATA_SCRIPT.call("get_weight", "smg")), "Medictool is lighter than an SMG")
	_assert(String(WEAPON_DATA_SCRIPT.call("get_preview_path", "none")).is_empty(), "None has no preview image")
	_assert(String(WEAPON_DATA_SCRIPT.call("get_visual_loadout_id", "none")).is_empty(), "None has no visual loadout")

	var fob_screen = FOB_SCREEN_SCRIPT.new()
	var option_button := OptionButton.new()
	fob_screen.call("_populate_weapon_option_button", option_button, "none")
	var selector_ids: PackedStringArray = _option_metadata_ids(option_button)
	_assert(selector_ids.has("none"), "FOB loadout selector offers an explicit None item")
	_assert(_selected_metadata_id(option_button) == "none", "FOB loadout selector can preselect None")
	for visual_only_id in ["standard_rifle", "compact_blaster", "heavy_blaster", "sniper_rifle", "medictool_blaster"]:
		_assert(not selector_ids.has(visual_only_id), "Visual-only loadout %s is blocked from active selection" % visual_only_id)
		_assert(_blocked_reason_for_visual_only_item(visual_only_id) == "visual_only_asset_not_gameplay_item", "Blocked reason is documented for %s" % visual_only_id)
	_assert(selector_ids.has("rocket_launcher"), "Rocket launcher remains selectable as a gameplay weapon despite sharing a visual loadout id")
	_assert(String(fob_screen.call("_get_weapon_preview_path", "none")).is_empty(), "FOB preview path for None is empty")
	_assert(fob_screen.call("_get_weapon_preview_texture", "none") == null, "FOB preview texture for None is null")

	option_button.queue_free()
	fob_screen.queue_free()


func _test_weight_resolver_and_snapshot_boundary() -> void:
	var resolver = LOADOUT_MODIFIER_RESOLVER_SCRIPT.new()
	var empty_weight: float = float(resolver.call("calculate_loadout_weight", {"armor": "medium", "weapon_1": "none", "weapon_2": "none"}))
	var smg_weight: float = float(resolver.call("calculate_loadout_weight", {"armor": "medium", "weapon_1": "smg", "weapon_2": "smg"}))
	var rocket_weight: float = float(resolver.call("calculate_loadout_weight", {"armor": "heavy", "weapon_1": "rocket_launcher", "weapon_2": "none"}))
	_assert(empty_weight == 2.0, "Medium armor with no weapons weighs only the armor")
	_assert(empty_weight < smg_weight, "None lowers loadout weight compared with two SMGs")
	_assert(rocket_weight > smg_weight, "Heavy rocket loadout weighs more than standard SMG loadout")

	var none_modifiers = resolver.call("resolve_for_unit", "task_260_empty", {"armor": "medium", "weapon_1": "none", "weapon_2": "none"})
	var none_dict: Dictionary = Dictionary(none_modifiers.call("to_dict")) if none_modifiers != null else {}
	_assert(String(none_dict.get("weapon_1_id", "")) == "none", "Resolver preserves None in slot 1")
	_assert(String(none_dict.get("weapon_2_id", "")) == "none", "Resolver preserves None in slot 2")
	_assert(String(none_dict.get("range_class", "")) == "none", "Resolver marks fully empty weapon slots with range class none")
	_assert(float(none_dict.get("loadout_weight", -1.0)) == empty_weight, "Resolver serializes the same empty loadout weight")
	_assert(not _dictionary_has_key_recursive(none_dict, "visual_loadout_id"), "Modifier payload does not replicate visual loadout ids")
	_assert(not _dictionary_has_key_recursive(none_dict, "preview_path"), "Modifier payload does not replicate preview paths")
	_assert(not _dictionary_has_key_recursive(none_dict, "blaster_path"), "Modifier payload does not replicate decorative model paths")

	var secondary_modifiers = resolver.call("resolve_for_unit", "task_260_secondary", {"armor": "medium", "weapon_1": "none", "weapon_2": "smg"})
	var secondary_dict: Dictionary = Dictionary(secondary_modifiers.call("to_dict")) if secondary_modifiers != null else {}
	_assert(String(secondary_dict.get("range_class", "")) == "short", "Secondary attack weapon drives range class when slot 1 is None")
	var batch: Dictionary = Dictionary(resolver.call("resolve_for_member_loadouts", {"task_260_empty": {"armor": "medium", "weapon_1": "none", "weapon_2": "none"}}))
	_assert(batch.has("task_260_empty"), "Batch resolver keeps valid empty weapon-slot loadouts")

	var empty_unit := _make_unit("task_260_snapshot_empty", "none", "none", Vector2.ZERO)
	_assert(String(empty_unit.call("get_active_weapon_id")).is_empty(), "TestUnit exposes no active weapon for two None slots")
	_assert(not bool(empty_unit.call("has_attack_weapon")), "TestUnit has no attack weapon for two None slots")
	_assert(String(COMBAT_FIRE_DECISION_RESOLVER_SCRIPT.call("get_unit_active_weapon_id", empty_unit)).is_empty(), "Combat resolver exposes no hidden active weapon")
	var simulation_root: Node = SIMULATION_ROOT_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(simulation_root.call("_build_unit_snapshot", empty_unit))
	_assert(not snapshot.has("active_weapon_id"), "Simulation snapshot omits active_weapon_id after empty selection")
	_assert(not snapshot.has("weapon_tile_range"), "Simulation snapshot omits weapon range after empty selection")
	var fallback_unit := _make_unit("task_260_snapshot_secondary", "none", "smg", Vector2.ZERO)
	_assert(String(fallback_unit.call("get_active_weapon_id")) == "smg", "Secondary SMG remains active when slot 1 is None")
	empty_unit.queue_free()
	fallback_unit.queue_free()
	simulation_root.queue_free()


func _test_fob_none_selection_and_character_weight() -> void:
	root.size = Vector2i(1920, 1080)
	var screen: Control = _build_staged_fob_screen()
	await _wait_frames(3)
	screen.call("_set_member_loadout", "ft1", "unit_alpha", "heavy", "rocket_launcher", "none")
	await _wait_frames(3)

	var member_list := _get_loadout_member_list(screen)
	var weapon_1_select := _find_node_by_name(member_list, "Weapon1Select") as OptionButton
	var weapon_2_select := _find_node_by_name(member_list, "Weapon2Select") as OptionButton
	var weapon_1_preview := _find_node_by_name(member_list, "Weapon1Preview") as TextureRect
	var weapon_2_preview := _find_node_by_name(member_list, "Weapon2Preview") as TextureRect
	_assert(_selected_metadata_id(weapon_1_select) == "rocket_launcher", "FOB slot 1 selects Rocket as gameplay weapon")
	_assert(_selected_metadata_id(weapon_2_select) == "none", "FOB slot 2 selects None")
	_assert(weapon_1_preview != null and weapon_1_preview.texture != null, "Rocket slot keeps a project-local preview")
	_assert(weapon_2_preview != null and not weapon_2_preview.visible, "None slot hides the preview rectangle")
	_assert(weapon_2_preview != null and String(weapon_2_preview.get_meta("weapon_preview_path", "")).is_empty(), "None preview path metadata is empty")
	_assert(weapon_2_preview != null and weapon_2_preview.tooltip_text.contains("No weapon"), "None preview carries a clear empty-slot tooltip")

	var status_label := screen.get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutStatusLabel") as Label
	_assert(status_label != null and status_label.text.contains("Weight"), "FOB loadout panel shows fireteam weight")
	_assert(status_label != null and status_label.text.contains("15.0"), "FOB fireteam weight includes Rocket/None and the remaining member")
	screen.call("_open_character_overlay", "unit_alpha")
	await _wait_frames(2)
	var overlay_texts: PackedStringArray = _collect_label_texts(screen.get_node_or_null("CharacterOverlay"))
	_assert(_labels_contain(overlay_texts, "Weight 9.0"), "Character overlay shows the same member weight for Rocket/None")
	_assert(_labels_contain(overlay_texts, "Keine Waffe"), "Character overlay names the None slot as Keine Waffe")

	screen.queue_free()
	await process_frame


func _test_mission_visual_none_has_no_hidden_weapon() -> void:
	root.size = Vector2i(1920, 1080)
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_260_none_visual", Vector2i(2, 1), Vector2.ZERO)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	var empty_unit := _make_unit("task_260_none_visual_probe", "none", "none", Vector2.ZERO)
	root.add_child(empty_unit)
	primary_view.call("set_unit_nodes", [empty_unit])
	await _wait_frames(12)

	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(snapshot.get("unit_blaster_attachment_count", -1)) == 0, "3D runtime attaches no weapon model for two None slots")
	_assert(int(snapshot.get("unit_visual_loadout_count", -1)) == 0, "3D runtime does not report a weapon visual loadout for two None slots")
	_assert(int(snapshot.get("unit_visual_loadout_error_count", -1)) == 0, "3D runtime treats None as intentional, not a missing visual error")
	var unit_root := primary_view.get_node_or_null("ViewportContainer/SubViewport/WorldRoot/UnitRoot3D")
	_assert(not _node_tree_has_name_prefix(unit_root, "BlasterVisual_"), "No hidden BlasterVisual node exists for the None loadout")

	primary_view.queue_free()
	empty_unit.queue_free()
	await process_frame


func _test_docs_exist() -> void:
	_assert(FileAccess.file_exists(REPORT_PATH), "Loadout weight playability report exists")
	_assert(FileAccess.file_exists(RULES_PATH), "Loadout playability rules doc exists")
	var report: String = _read_text(REPORT_PATH)
	for required_text in ["Summary", "Inventory Separation", "Weight Findings", "Mission Snapshot", "Manual Remainder"]:
		_assert(report.contains(required_text), "Report covers %s" % required_text)
	var rules: String = _read_text(RULES_PATH)
	for required_text in ["Playable Items", "Visual-Only Items", "None Slot", "Weight", "Replication"]:
		_assert(rules.contains(required_text), "Rules doc covers %s" % required_text)


func _build_staged_fob_screen() -> Control:
	var screen: Control = FOB_TEST_SCENE.instantiate()
	root.add_child(screen)
	var roster: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	screen.call("set_available_units", roster)
	screen.call(
		"configure_transfer",
		PackedStringArray(["unit_alpha", "unit_bravo"]),
		PackedStringArray(["ft1", "ft1"]),
		[]
	)
	screen.call("_on_staging_fireteam_dropped", "ft1", "loadout")
	return screen


func _get_loadout_member_list(screen: Node) -> VBoxContainer:
	return screen.get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutMemberScroll/LoadoutMemberList") as VBoxContainer


func _make_unit(unit_id: String, weapon_1_id: String, weapon_2_id: String, position: Vector2) -> Node2D:
	var unit := TEST_UNIT_SCRIPT.new() as Node2D
	unit.unit_id = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = "ft1"
	unit.role_id = "security_guard"
	unit.weapon_1_id = weapon_1_id
	unit.weapon_2_id = weapon_2_id
	unit.global_position = position
	return unit


func _blocked_reason_for_visual_only_item(item_id: String) -> String:
	var mapping: Dictionary = _load_json(NPC_VISUAL_MAPPING_PATH)
	var visual_loadouts: Dictionary = Dictionary(mapping.get("visual_loadouts", {}))
	if visual_loadouts.has(item_id) and not PackedStringArray(WEAPON_DATA_SCRIPT.call("get_all_weapon_ids")).has(item_id):
		return "visual_only_asset_not_gameplay_item"
	return ""


func _option_metadata_ids(option_button: OptionButton) -> PackedStringArray:
	var result := PackedStringArray()
	if option_button == null:
		return result
	for index in range(option_button.item_count):
		var metadata_id: String = String(option_button.get_item_metadata(index)).strip_edges()
		if not metadata_id.is_empty():
			result.append(metadata_id)
	return result


func _selected_metadata_id(option_button: OptionButton) -> String:
	if option_button == null or option_button.selected < 0:
		return ""
	return String(option_button.get_item_metadata(option_button.selected)).strip_edges()


func _dictionary_has_key_recursive(value: Variant, key_name: String) -> bool:
	if typeof(value) == TYPE_DICTIONARY:
		var dict_value: Dictionary = Dictionary(value)
		if dict_value.has(key_name):
			return true
		for nested in dict_value.values():
			if _dictionary_has_key_recursive(nested, key_name):
				return true
	if typeof(value) == TYPE_ARRAY:
		for nested in Array(value):
			if _dictionary_has_key_recursive(nested, key_name):
				return true
	return false


func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node == null:
		return null
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null


func _collect_label_texts(node: Node) -> PackedStringArray:
	var result := PackedStringArray()
	if node == null:
		return result
	if node is Label:
		var text: String = String((node as Label).text).strip_edges()
		if not text.is_empty():
			result.append(text)
	for child in node.get_children():
		result.append_array(_collect_label_texts(child))
	return result


func _labels_contain(labels: PackedStringArray, needle: String) -> bool:
	for label in labels:
		if String(label).contains(needle):
			return true
	return false


func _node_tree_has_name_prefix(node: Node, prefix: String) -> bool:
	if node == null:
		return false
	if String(node.name).begins_with(prefix):
		return true
	for child in node.get_children():
		if _node_tree_has_name_prefix(child, prefix):
			return true
	return false


func _load_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return Dictionary(parsed)
	return {}


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
