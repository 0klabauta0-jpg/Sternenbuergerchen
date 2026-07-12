extends SceneTree

const LOBBY_SOURCE_PATH := "res://scripts/ui/multiplayer_lobby_screen.gd"
const HARNESS_PATH := "res://scripts/tools/capture_release_host_client_entry_playtest.ps1"

var _failed := 0


func _initialize() -> void:
	var lobby_source := FileAccess.get_file_as_string(LOBBY_SOURCE_PATH)
	for token in [
		"movement_wall_time_msec",
		"simulation_tick",
		"physics_fps",
		"movement_start_position",
		"movement_distance_travelled",
		"movement_remaining_distance",
		"movement_progress_ratio",
		"RELEASE_TRACE_HEARTBEAT_MSEC",
	]:
		_assert(lobby_source.contains(token), "Release First Contact trace exposes %s" % token)
	_assert(lobby_source.contains("Time.get_ticks_msec() - _release_first_contact_advance_started_msec"), "Movement wall time is derived from a monotonic clock")
	_assert(lobby_source.contains("trace_heartbeat_bucket"), "Unchanged First Contact stages still write periodic movement evidence")
	_assert(lobby_source.contains('get_mission_marker_world_position", "spawn_bravo"'), "Release Contact Approach follows the runtime enemy spawn marker")
	_assert(not lobby_source.contains('"spawn_enemy_defense"') and not lobby_source.contains('"spawn_enemy_patrol"'), "Release Contact Approach does not treat decorative enemy markers as runtime truth")

	var harness_source := FileAccess.get_file_as_string(HARNESS_PATH)
	for token in [
		"movement_pace",
		"movement_remaining_distance",
		"movement_distance_travelled",
		"movement_progress_ratio",
	]:
		_assert(harness_source.contains(token), "Release harness preserves %s evidence" % token)
	_assert(harness_source.contains('"TASK_1151"'), "First Contact pace manifest identifies TASK_1151")

	print("TASK_1151 connected release movement pace evidence: %d/17 PASS" % (17 - _failed))
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
