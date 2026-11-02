extends SceneTree

const INDEX_SCRIPT: GDScript = preload("res://scripts/tactical/mission_runtime_index.gd")
const UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const META_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== Review 2026-11-02 P1 runtime index ===")
	await _test_existing_unit_identity_changes()
	await _test_watchers_follow_membership_and_root_binding()
	await _test_live_meta_selection_reuses_mission_slots()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_existing_unit_identity_changes() -> void:
	var mission_root := Node.new()
	root.add_child(mission_root)
	var unit: Node = UNIT_SCRIPT.new()
	unit.call("apply_identity_config", {"unit_id": "before", "team_id": "team_alpha", "fireteam_id": "blue"})
	mission_root.add_child(unit)
	var index: Node = INDEX_SCRIPT.new()
	root.add_child(index)
	index.call("bind_mission_root", mission_root, "team_alpha")
	_assert(index.call("get_unit_by_id", "before") == unit, "Initial identity resolves the real runtime unit")
	var initial_scans: int = _scan_count(index)
	unit.call("apply_identity_config", {"unit_id": "after"})
	_assert(index.call("get_unit_by_id", "after") == unit, "Identity config makes the new ID resolve on the same node")
	_assert(index.call("get_unit_by_id", "before") == null, "Identity config removes the old ID lookup")
	_assert(_scan_count(index) == initial_scans + 1, "ID mutation invalidates one lazy rebuild")
	unit.call("apply_identity_config", {"team_id": "team_bravo"})
	_assert(Array(index.call("get_friendly_units")).is_empty(), "Team config removes the node from friendlies")
	_assert(Array(index.call("get_enemy_units")) == [unit], "Team config places the node in enemies")
	_assert(Array(index.call("get_fireteam_units", "blue")).is_empty(), "Enemy assignment leaves no stale friendly Fireteam entry")
	unit.call("apply_identity_config", {"team_id": "team_alpha"})
	unit.call("set_fireteam_id", " GOLD ")
	_assert(Array(index.call("get_fireteam_units", "blue")).is_empty(), "Fireteam setter removes the old Fireteam entry")
	_assert(Array(index.call("get_fireteam_units", "gold")) == [unit], "Fireteam setter exposes the normalized new Fireteam")
	unit.call("apply_identity_config", {"fireteam_id": "red"})
	_assert(Array(index.call("get_fireteam_units", "red")) == [unit] and Array(index.call("get_fireteam_units", "gold")).is_empty(), "Identity config also invalidates Fireteam assignment")
	unit.set("unit_id", "direct")
	unit.set("team_id", "team_unused")
	unit.set("fireteam_id", "green")
	_assert(index.call("get_unit_by_id", "direct") == unit and index.call("get_unit_by_id", "after") == null, "Exported identity property changes refresh ID lookup")
	_assert(Array(index.call("get_friendly_units")).is_empty() and Array(index.call("get_enemy_units")).is_empty(), "Unused slots leave both active team lookups")
	unit.call("apply_identity_config", {"unit_id": "", "team_id": "team_alpha"})
	_assert(Array(index.call("get_friendly_units")).is_empty(), "An empty unit identity is excluded")
	unit.call("apply_identity_config", {"unit_id": "restored"})
	_assert(index.call("get_unit_by_id", "restored") == unit, "An existing empty-ID slot is observed when its identity becomes valid")
	_assert(Array(index.call("get_fireteam_units", "green")) == [unit], "Restored slot retains the current Fireteam assignment")
	var stable_scans: int = _scan_count(index)
	for _iteration in range(24):
		unit.call("apply_identity_config", {"unit_id": "restored", "team_id": "team_alpha", "fireteam_id": "green", "display_name": "Updated label"})
		unit.call("set_fireteam_id", " GREEN ")
		index.call("get_unit_by_id", "restored")
		index.call("get_friendly_units")
		index.call("get_enemy_units")
		index.call("get_fireteam_units", "green")
	_assert(_scan_count(index) == stable_scans, "Unchanged identity, display-only edits and repeated lookups remain scan-free")
	index.free()
	mission_root.queue_free()
	await process_frame


func _test_watchers_follow_membership_and_root_binding() -> void:
	var first_root := Node.new()
	var second_root := Node.new()
	root.add_child(first_root)
	root.add_child(second_root)
	var unit: Node = UNIT_SCRIPT.new()
	unit.call("apply_identity_config", {"unit_id": "watched", "team_id": "team_alpha", "fireteam_id": "blue"})
	first_root.add_child(unit)
	var index: Node = INDEX_SCRIPT.new()
	root.add_child(index)
	index.call("bind_mission_root", first_root, "team_alpha")
	_assert(index.call("get_unit_by_id", "watched") == unit, "Membership fixture indexes the first root")
	first_root.remove_child(unit)
	_assert(index.call("get_unit_by_id", "watched") == null, "Removing the slot discards its cached identity")
	var removed_scans: int = _scan_count(index)
	unit.call("apply_identity_config", {"unit_id": "detached"})
	_assert(_scan_count(index) == removed_scans, "Detached unit changes do not invalidate the previous mission")
	second_root.add_child(unit)
	index.call("bind_mission_root", second_root, "team_alpha")
	_assert(index.call("get_unit_by_id", "detached") == unit, "Rebinding observes the slot under its new root")
	index.call("bind_mission_root", first_root, "team_alpha")
	var rebound_scans: int = _scan_count(index)
	unit.call("set_fireteam_id", "gold")
	_assert(_scan_count(index) == rebound_scans, "Root rebinding disconnects identity watchers from the old mission")
	index.call("bind_mission_root", second_root, "team_alpha")
	_assert(Array(index.call("get_fireteam_units", "gold")) == [unit], "Rebinding back reads the current assignment")
	unit.queue_free()
	await process_frame
	_assert(Array(index.call("get_friendly_units")).is_empty(), "Freed slots are removed without invalid object reads")
	index.free()
	first_root.queue_free()
	second_root.queue_free()
	await process_frame


func _test_live_meta_selection_reuses_mission_slots() -> void:
	root.size = Vector2i(1920, 1080)
	var flow: Node = META_SCENE.instantiate()
	root.add_child(flow)
	await _wait_frames(3)
	flow.set("_mission_catalog", [{"mission_id": "index_regression", "mission_name": "Index regression", "map_file_path": "res://maps/Ground_Mission01_32x32.json", "scenario_file_path": "", "slot_count": 8}])
	flow.set("_selected_mission_id", "index_regression")
	var first_ids := PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie"])
	var next_ids := PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta", "unit_echo", "unit_foxtrot"])
	flow.set("_selected_unit_ids", first_ids)
	flow.set("_selected_fireteam_ids", PackedStringArray(["blue", "blue", "blue"]))
	flow.set("_mission_planning_state", {"mission_drop_source": "fob", "embarked_unit_ids": Array(first_ids)})
	flow.call("_start_or_update_active_mission")
	await _wait_frames(8)
	var mission: Node = flow.call("get_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	var setup: Node = mission.get_node("MissionSetup")
	_assert(bool(setup.get("_is_initialized")), "Real MetaLayerFlow initializes MissionSetup")
	_assert(Array(controller.call("_get_all_friendly_units", true)).size() == 3 and Array(controller.call("_get_fireteam_units", "blue", true)).size() == 3, "Live mission starts with three Blue members")
	var child_count: int = mission.get_child_count()
	var slot_ids: Array = []
	for slot_name in ["UnitAlpha", "UnitBravo", "UnitCharlie", "UnitDelta", "UnitEcho", "UnitFoxtrot"]:
		slot_ids.append(mission.get_node(slot_name).get_instance_id())
	flow.set("_selected_unit_ids", next_ids)
	flow.set("_selected_fireteam_ids", PackedStringArray(["blue", "blue", "blue", "gold", "gold", "gold"]))
	flow.set("_mission_planning_state", {"mission_drop_source": "fob", "embarked_unit_ids": Array(next_ids)})
	flow.call("_start_or_update_active_mission")
	_assert(flow.call("get_active_mission") == mission and mission.get_child_count() == child_count, "Late payload reuses the same active mission and root membership")
	var same_slots: bool = true
	for slot_index in range(slot_ids.size()):
		same_slots = same_slots and mission.get_node(["UnitAlpha", "UnitBravo", "UnitCharlie", "UnitDelta", "UnitEcho", "UnitFoxtrot"][slot_index]).get_instance_id() == slot_ids[slot_index]
	_assert(same_slots, "Late payload reuses all six existing runtime slot nodes")
	_assert(PackedStringArray(setup.get("selected_team_unit_ids")).size() == 6, "MetaLayerFlow delivers the six-unit selection to live MissionSetup")
	var friendly_count: int = Array(controller.call("_get_all_friendly_units", true)).size()
	var gold_count: int = Array(controller.call("_get_fireteam_units", "gold", true)).size()
	print("LIVE_SELECTION root_children=%d friendly=%d blue=%d gold=%d" % [child_count, friendly_count, Array(controller.call("_get_fireteam_units", "blue", true)).size(), gold_count])
	_assert(friendly_count == 6, "Live index immediately includes newly activated existing slots")
	_assert(gold_count == 3, "Live index immediately exposes the three new Gold members")
	var before: Dictionary = Dictionary(controller.call("get_mission_runtime_index_diagnostics"))
	for _iteration in range(24):
		controller.call("_get_all_friendly_units", true)
		controller.call("_get_fireteam_units", "blue", true)
		controller.call("_get_fireteam_units", "gold", true)
	var after: Dictionary = Dictionary(controller.call("get_mission_runtime_index_diagnostics"))
	_assert(int(before["membership_scan_count"]) == int(after["membership_scan_count"]), "Live controller lookups remain scan-free after selection settles")
	flow.queue_free()
	await _wait_frames(2)


func _scan_count(index: Node) -> int:
	return int(Dictionary(index.call("get_diagnostics_snapshot"))["membership_scan_count"])


func _wait_frames(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		push_error("FAIL: " + message)
