extends SceneTree

const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_177 Drop Light Fixed UI Layout Contract Verifier ===")
	_test_global_contract()
	_test_component_contract()
	_test_fob_fixed_layout_contract()
	_test_homebase_fixed_layout_contract()
	_test_mission_hud_boundary_contract()
	_test_allowed_runtime_assets()
	_test_no_absolute_user_paths_in_runtime_ui_basis()

	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_177: FAILED")
		quit(1)
	else:
		print("TASK_177: ALL PASSED")
		quit(0)


func _test_global_contract() -> void:
	_assert(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT") == Vector2i(1920, 1080), "Contract fixes the target viewport to Full HD")
	_assert(int(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("BASE_SPACING")) == 8, "Contract uses the 8 px base grid")
	_assert(int(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("PANEL_RADIUS_MAX")) <= 6, "Contract caps panel radius at 6 px")
	var action_size: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("ACTION_BUTTON_SIZE")
	_assert(action_size.x == action_size.y, "Primary action buttons are square")


func _test_component_contract() -> void:
	var names: PackedStringArray = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_component_names")
	for expected_name in [
		"Panel / Fixed",
		"NPC Card / Compact",
		"NPC Stack Card",
		"Ship Slot Card",
		"Status Badge",
		"Command Button",
		"Pad Field / 3x5",
	]:
		_assert(names.has(expected_name), "Component contract includes %s" % expected_name)


func _test_fob_fixed_layout_contract() -> void:
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_fob_layout")
	_assert(_has_rect(layout, "fireteams"), "FOB contract defines #10 fireteams")
	_assert(_has_rect(layout, "loadout"), "FOB contract defines #13 loadout")
	_assert(_has_rect(layout, "flightdeck"), "FOB contract defines #14 flightdeck")
	_assert(_has_rect(layout, "boarding_status"), "FOB contract defines bottom boarding status")
	_assert(_has_rect(layout, "actions"), "FOB contract defines bottom actions")
	_assert(_all_rects_fixed_and_on_grid(layout), "FOB contract uses fixed grid-aligned Full HD rectangles")
	var loadout_rect: Rect2i = layout.get("loadout")
	var flightdeck_rect: Rect2i = layout.get("flightdeck")
	_assert(flightdeck_rect.size.x > loadout_rect.size.x, "FOB #14 flightdeck is wider than #13 loadout")
	_assert(loadout_rect.size.x < 700, "FOB #13 loadout is intentionally narrower for the wide flightdeck")


func _test_homebase_fixed_layout_contract() -> void:
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_homebase_layout")
	for key in ["mission_brief", "roster", "transfer_team", "flightdeck", "character_sheet"]:
		_assert(_has_rect(layout, key), "Homebase contract defines %s" % key)
	_assert(_all_rects_fixed_and_on_grid(layout), "Homebase contract uses fixed grid-aligned Full HD rectangles")


func _test_mission_hud_boundary_contract() -> void:
	_assert(bool(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("MISSION_SCOPE_HUD_ONLY")), "Mission drop_light scope is HUD-only")
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_mission_hud_layout")
	for key in ["command_matrix", "selected_fireteam", "mission_control"]:
		_assert(_has_rect(layout, key), "Mission HUD contract defines %s" % key)
	_assert(not layout.has("map") and not layout.has("terrain") and not layout.has("terrain_map_3d_view"), "Mission contract does not define a replacement map")
	_assert(_all_rects_fixed_and_on_grid(layout), "Mission HUD contract uses fixed grid-aligned Full HD rectangles")
	var forbidden_targets: PackedStringArray = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_mission_forbidden_runtime_targets")
	_assert(forbidden_targets.has("TerrainMap3DView"), "Mission boundary forbids TerrainMap3DView changes")
	_assert(forbidden_targets.has("SimulationRoot"), "Mission boundary forbids SimulationRoot changes")


func _test_allowed_runtime_assets() -> void:
	var paths: PackedStringArray = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_allowed_runtime_asset_paths")
	_assert(paths.size() >= 6, "Contract exposes the curated drop_light runtime asset list")
	for path in paths:
		_assert(path.begins_with("res://Assets/"), "%s is a project asset path" % path)
		_assert(not _contains_absolute_user_path(path), "%s is not an absolute user path" % path)
		_assert(ResourceLoader.exists(path), "%s exists in the project" % path)


func _test_no_absolute_user_paths_in_runtime_ui_basis() -> void:
	for file_path in [
		"res://scripts/meta/drop_light_layout_contract.gd",
		"res://scripts/meta/meta_ui_skin.gd",
		"res://scripts/ui/tactical_ui_theme.gd",
		"res://scripts/meta/fob_screen.gd",
		"res://scripts/meta/homebase_screen.gd",
	]:
		var text := _read_text_file(file_path)
		_assert(not _contains_absolute_user_path(text), "%s contains no absolute user runtime asset reference" % file_path)


func _has_rect(layout: Dictionary, key: String) -> bool:
	return layout.has(key) and typeof(layout[key]) == TYPE_RECT2I


func _all_rects_fixed_and_on_grid(layout: Dictionary) -> bool:
	for value in layout.values():
		if typeof(value) != TYPE_RECT2I:
			continue
		var rect: Rect2i = value
		if not bool(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("is_rect_inside_viewport", rect)):
			return false
		if not bool(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("is_rect_on_base_grid", rect)):
			return false
	return true


func _contains_absolute_user_path(text: String) -> bool:
	return text.contains("C:" + "\\" + "Users" + "\\") or text.contains("C:" + "/" + "Users" + "/")


func _read_text_file(file_path: String) -> String:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
