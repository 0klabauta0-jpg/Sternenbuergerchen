extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TRUTH_AUDIT_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_truth_audit.gd")
const TILE_PROPERTY_OVERLAY_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_tile_property_overlay.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_454_terrain_truth_visual_audit.md"
const CONTRACT_PATH: String = "res://docs/dev/terrain_truth_visual_audit_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_454 Terrain Truth Visual Audit ===")
	_test_policy_snapshot()
	_test_wall_segment_los_policy()
	_test_map_truth_snapshot_and_tile_entries()
	_test_tile_property_overlay_exports_dev_ui_fields()
	_test_docs_are_updated()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("TASK_454: ALL PASSED")
		quit(0)


func _test_policy_snapshot() -> void:
	var policy: Dictionary = Dictionary(TERRAIN_TRUTH_AUDIT_SCRIPT.call("build_policy_snapshot"))
	_assert(String(policy.get("terrain_authority", "")) == "TerrainRegistry", "Policy keeps TerrainRegistry as authority")
	_assert(String(policy.get("terrain3d_role", "")) == "visual_authoring_candidate", "Terrain3D is visual/authoring candidate only")
	_assert(String(policy.get("wall_los_policy", "")) == "edge_segment_blockers", "Wall LOS policy is edge/segment based")
	_assert(bool(policy.get("combat_los_uses_segment_policy", false)), "Segment policy is now explicitly active in combat LOS")
	_assert(String(policy.get("combat_los_policy_source", "")) == "LineOfSightSystem", "Policy names the active combat LOS source")
	_assert(PackedStringArray(policy.get("dev_ui_fields", PackedStringArray())).has("blocker_type"), "Policy lists blocker_type for Dev UI")


func _test_wall_segment_los_policy() -> void:
	var fixture: Dictionary = _build_map_fixture()
	var wall_tile = fixture["map_data"].call("get_tile_at_grid", Vector2i(2, 1))
	var segments: Array = Array(TERRAIN_TRUTH_AUDIT_SCRIPT.call("get_wall_segments_for_tile", wall_tile))
	_assert(segments.size() == 1 and String(Dictionary(segments[0]).get("edge_id", "")) == "ne", "Straight NE wall resolves one NE segment")
	_assert(bool(TERRAIN_TRUTH_AUDIT_SCRIPT.call("does_tile_wall_block_los", wall_tile, Vector2(2.0, 1.0), Vector2(3.0, 1.0))), "LOS crossing the wall segment blocks")
	_assert(not bool(TERRAIN_TRUTH_AUDIT_SCRIPT.call("does_tile_wall_block_los", wall_tile, Vector2(2.0, 0.65), Vector2(2.0, 1.35))), "LOS along the same wall side stays clear")
	_assert(not bool(TERRAIN_TRUTH_AUDIT_SCRIPT.call("does_tile_wall_block_los", wall_tile, Vector2(1.5, 0.5), Vector2(3.5, 0.5))), "Pure corner touch does not auto-block")

	var diagonal_tile = fixture["map_data"].call("get_tile_at_grid", Vector2i(1, 1))
	diagonal_tile.type_id = "wall_straight_nw"
	diagonal_tile.object_type_id = ""
	diagonal_tile.blocks_los = true
	diagonal_tile.object_height = 2
	_assert(bool(TERRAIN_TRUTH_AUDIT_SCRIPT.call("does_tile_wall_block_los", diagonal_tile, Vector2(0.0, 0.0), Vector2(2.0, 1.0))), "Diagonal sight blocks when it truly intersects a wall segment")


func _test_map_truth_snapshot_and_tile_entries() -> void:
	var fixture: Dictionary = _build_map_fixture()
	var map_data = fixture["map_data"]
	var snapshot: Dictionary = Dictionary(TERRAIN_TRUTH_AUDIT_SCRIPT.call("build_map_truth_snapshot", map_data))
	_assert(int(snapshot.get("tile_count", 0)) == 16, "Map audit counts all fixture tiles")
	_assert(int(snapshot.get("object_layer_count", 0)) == 1, "Map audit counts object layer props")
	_assert(int(snapshot.get("ground_under_object_count", 0)) == 1, "Bush object sits on ground")
	_assert(int(snapshot.get("object_without_ground_count", -1)) == 0, "No object replaces ground in fixture")
	_assert(int(snapshot.get("wall_segment_candidate_count", 0)) >= 1, "Map audit counts wall segment candidates")
	_assert(int(snapshot.get("whole_tile_los_blocker_count", 0)) >= 1, "Map audit still reports whole-tile LOS blockers for current runtime")

	var bush_entry: Dictionary = Dictionary(TERRAIN_TRUTH_AUDIT_SCRIPT.call("build_tile_truth_entry", fixture["bush_tile"]))
	_assert(String(bush_entry.get("object_layer_state", "")) == "object_on_ground", "Tile entry exposes object-on-ground state")
	_assert(String(bush_entry.get("blocker_type", "")) == "object_height", "Bush cover with height is reported as object-height blocker/diagnostic")
	var wall_entry: Dictionary = Dictionary(TERRAIN_TRUTH_AUDIT_SCRIPT.call("build_tile_truth_entry", fixture["wall_tile"]))
	_assert(String(wall_entry.get("blocker_type", "")) == "wall_segment_candidate", "Wall entry exposes segment blocker candidate")


func _test_tile_property_overlay_exports_dev_ui_fields() -> void:
	var fixture: Dictionary = _build_map_fixture()
	var wall_entry: Dictionary = Dictionary(TILE_PROPERTY_OVERLAY_SCRIPT.call("build_tile_entry", fixture["wall_tile"]))
	_assert(String(wall_entry.get("tile_id", "")).begins_with("tile_"), "Overlay tile entry exposes tile_id")
	_assert(String(wall_entry.get("type_id", "")) == "wall_straight_ne", "Overlay tile entry exposes type_id")
	_assert(String(wall_entry.get("blocker_type", "")) == "wall_segment_candidate", "Overlay tile entry exposes blocker_type")
	_assert(int(wall_entry.get("wall_segment_count", 0)) == 1, "Overlay tile entry exposes wall segment count")
	var overlay_snapshot: Dictionary = Dictionary(TILE_PROPERTY_OVERLAY_SCRIPT.call("build_overlay_snapshot", fixture["map_data"], true))
	_assert(String(overlay_snapshot.get("terrain_authority", "")) == "TerrainRegistry", "Overlay snapshot repeats terrain authority")
	_assert(PackedStringArray(overlay_snapshot.get("dev_ui_fields", PackedStringArray())).has("object_type_id"), "Overlay snapshot lists object_type_id Dev UI field")
	_assert(int(overlay_snapshot.get("wall_segment_candidate_count", 0)) >= 1, "Overlay snapshot exposes wall segment candidate count")
	_assert(bool(overlay_snapshot.get("visual_only", false)) and not bool(overlay_snapshot.get("ui_sets_gameplay_truth", true)), "Overlay remains visual-only")


func _test_docs_are_updated() -> void:
	var task_text: String = FileAccess.get_file_as_string(TASK_PATH)
	var contract_text: String = FileAccess.get_file_as_string(CONTRACT_PATH)
	var status_text: String = FileAccess.get_file_as_string(STATUS_PATH)
	var roadmap_text: String = FileAccess.get_file_as_string(ROADMAP_PATH)
	_assert(task_text.contains("TASK_454 - Terrain Truth Visual Audit"), "TASK_454 task file exists")
	_assert(contract_text.contains("Mauer-/Kanten-LOS Zielregel"), "Terrain audit contract documents wall edge LOS")
	_assert(status_text.contains("TASK_454 - Terrain Truth Visual Audit"), "Implementation status documents TASK_454")
	_assert(roadmap_text.contains("TASK_454 - Terrain Truth Visual Audit"), "Roadmap lists TASK_454")


func _build_map_fixture() -> Dictionary:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_454_terrain_truth_audit", Vector2i(4, 4), Vector2.ZERO, 64.0, 32.0, 3)
	var bush_tile = map_data.call("get_tile_at_grid", Vector2i(1, 1))
	bush_tile.type_id = "ground_flat"
	bush_tile.object_type_id = "nature_bush_cover"
	bush_tile.cover_value = 25
	bush_tile.object_height = 1
	bush_tile.blocks_los = false
	bush_tile.walkable = true
	var wall_tile = map_data.call("get_tile_at_grid", Vector2i(2, 1))
	wall_tile.type_id = "wall_straight_ne"
	wall_tile.object_type_id = ""
	wall_tile.cover_value = 40
	wall_tile.object_height = 2
	wall_tile.blocks_los = true
	wall_tile.walkable = false
	return {
		"map_data": map_data,
		"bush_tile": bush_tile,
		"wall_tile": wall_tile,
	}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
