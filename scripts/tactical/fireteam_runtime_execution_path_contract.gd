class_name FireteamRuntimeExecutionPathContract
extends RefCounted

const SCHEMA_VERSION: int = 1
const ACTIVE_PATH_ID: String = "mission_tactical"
const LEGACY_PATH_ID: String = "runtime_leader_ftltask"
const LEGACY_POLICY: String = "compatibility_adapter_only"
const RUNTIME_AUTHORITY: String = "SimulationRoot"
const SIMULATION_ENQUEUE_METHOD: String = "SimulationRoot.enqueue_command"
const CONTROLLER_SCRIPT_PATH: String = "res://scripts/tactical/mission_tactical_sandbox_controller.gd"
const MOVEMENT_CONTROLLER_SCRIPT_PATH: String = "res://scripts/tactical/fireteam_movement_controller.gd"
const SECURITY_CONTROLLER_SCRIPT_PATH: String = "res://scripts/tactical/fireteam_security_controller.gd"


static func build_snapshot(controller_script_path: String = CONTROLLER_SCRIPT_PATH) -> Dictionary:
	var normalized_controller_path: String = controller_script_path.strip_edges()
	if normalized_controller_path.is_empty():
		normalized_controller_path = CONTROLLER_SCRIPT_PATH
	return {
		"schema_version": SCHEMA_VERSION,
		"active_path_id": ACTIVE_PATH_ID,
		"active_path_label": "Mission Tactical Fireteam Runtime",
		"command_entry_owner": "MissionTacticalSandboxController",
		"command_entry_script": normalized_controller_path,
		"selection_owner": "MissionTacticalSandboxController",
		"waypoint_owner": "MissionTacticalSandboxController",
		"area_order_owner": "MissionTacticalSandboxController",
		"phase_owner": "MissionTacticalSandboxController/PhaseController",
		"movement_owner": "FireteamMovementController",
		"movement_script": MOVEMENT_CONTROLLER_SCRIPT_PATH,
		"security_owner": "FireteamSecurityController",
		"security_script": SECURITY_CONTROLLER_SCRIPT_PATH,
		"runtime_authority": RUNTIME_AUTHORITY,
		"simulation_enqueue_method": SIMULATION_ENQUEUE_METHOD,
		"unit_lookup_authority": "UnitRegistry",
		"runtime_command_shape": "UnitCommand dictionary per fireteam member",
		"live_go_methods": PackedStringArray([
			"_activate_next_waypoint_for_plan",
			"_issue_waypoint_for_fireteam",
			"FireteamMovementController.start_execution",
		]),
		"new_fireteam_gameplay_path": ACTIVE_PATH_ID,
		"legacy_path_id": LEGACY_PATH_ID,
		"legacy_policy": LEGACY_POLICY,
		"legacy_allowed_uses": PackedStringArray([
			"baseline_tests",
			"compatibility_adapter",
			"migration_reference",
		]),
		"forbidden_new_uses": PackedStringArray([
			"ftltask_only_visible_mission_gameplay",
			"ui_owned_unit_truth",
			"snapshot_owned_gameplay_truth",
		]),
		"runtime_leader_is_primary_visible_path": false,
		"requires_simulation_root_enqueue": true,
		"requires_no_scene_tree_hotpath_scan": true,
		"ui_sets_unit_truth": false,
		"ui_sets_gameplay_truth": false,
		"snapshots_are_truth": false,
		"production_extraction_needed": false,
		"production_extraction_policy": "MissionTacticalSandboxController is extracted to scripts/tactical; scripts/tests paths are compatibility adapters only.",
	}


static func validate_snapshot(snapshot: Dictionary) -> Dictionary:
	var issues: PackedStringArray = PackedStringArray()
	_require_equals(snapshot, "schema_version", SCHEMA_VERSION, issues)
	_require_equals(snapshot, "active_path_id", ACTIVE_PATH_ID, issues)
	_require_equals(snapshot, "new_fireteam_gameplay_path", ACTIVE_PATH_ID, issues)
	_require_equals(snapshot, "legacy_policy", LEGACY_POLICY, issues)
	_require_equals(snapshot, "runtime_authority", RUNTIME_AUTHORITY, issues)
	_require_equals(snapshot, "simulation_enqueue_method", SIMULATION_ENQUEUE_METHOD, issues)
	_require_bool(snapshot, "requires_simulation_root_enqueue", true, issues)
	_require_bool(snapshot, "ui_sets_unit_truth", false, issues)
	_require_bool(snapshot, "ui_sets_gameplay_truth", false, issues)
	_require_bool(snapshot, "snapshots_are_truth", false, issues)
	_require_bool(snapshot, "runtime_leader_is_primary_visible_path", false, issues)
	return {
		"valid": issues.is_empty(),
		"issues": issues,
	}


static func is_valid_snapshot(snapshot: Dictionary) -> bool:
	return bool(validate_snapshot(snapshot).get("valid", false))


static func _require_equals(snapshot: Dictionary, key: String, expected, issues: PackedStringArray) -> void:
	if not snapshot.has(key):
		issues.append("missing_%s" % key)
		return
	if snapshot.get(key) != expected:
		issues.append("invalid_%s" % key)


static func _require_bool(snapshot: Dictionary, key: String, expected: bool, issues: PackedStringArray) -> void:
	if not snapshot.has(key):
		issues.append("missing_%s" % key)
		return
	if bool(snapshot.get(key)) != expected:
		issues.append("invalid_%s" % key)
