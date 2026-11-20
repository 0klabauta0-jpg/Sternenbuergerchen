extends "res://scripts/tests/review_completion_authentic_legacy_continue.gd"
## Real historical campaign reconstruction; no invented location, actor or fog.
## The inherited helper freezes only after the genuine world commit succeeds.
## 20.11.2026: von dem alten Zwischenstand (legacy_source_pair, wird nicht mehr geladen) auf das
## Hex-Paar return_source_pair umgezogen; Pruefungen unveraendert. NICHT per Lauf belegt (verlangt
## eine isolierte Projektkopie), nur --check-only. Wer ihn fahren kann: bitte laufen lassen.
## Achtung: Das Paar return_source_pair/ vom 13.11. scheitert am Basisstand vermutlich mit
## stale_campaign_definitions (Ortsdaten geaendert); ein neues Hex-Paar kann noetig sein.
const HEX_DIR := "res://docs/qa/review_completion_20261113/return_source_pair/"
const HEX_HOME_SHA := "c346f73b218552e5851efdc35468a259f6a06d8ebd247d75ca5d810492e675cd"
const HEX_ACTIVE_SHA := "d6e7af966ae8e5da08858e0874c3775505c05cd007c029471f0c0b8ffa295181"

func _run() -> void:
	if not LEGACY_GUARD.require_isolated_user_data(): return
	if not _check(FileAccess.file_exists("user://review2_isolation_canary.json"), "actual isolated profile canary"): await _finish(); return
	if not _copy_hex_pair(): await _finish(); return
	if not await _continue_from_files("remote view real campaign"): await _finish(); return
	# Complete deferred visual-node admission after the already frozen gameplay.
	await process_frame
	var mission: Node = _flow.get("_active_mission")
	var setup: Node = mission.get_node("MissionSetup")
	var terrain_view: Node = setup.get("_terrain_3d_view")
	if not _check(is_instance_valid(terrain_view) and terrain_view.is_inside_tree(), "actual restored scene has its real admitted terrain view"): await _finish(); return
	var registry: RefCounted = _flow.get("_location_registry")
	var location_id := String(mission.get_meta("location_id", ""))
	_check(not location_id.is_empty() and registry.get_location(location_id) == mission, "existing location registry binds the actual restored mission")
	var baseline: Dictionary = _owners()
	var fog_before: Dictionary = _fog_owner_snapshot(setup)
	# Publish the current real owner once, as MissionSetup normally does; this
	# also excludes an unrelated pending render refresh from the comparison.
	terrain_view.set_fog_of_war_state(fog_before)
	var render_before: Dictionary = terrain_view.get_inspection_blackout_snapshot()
	_check(baseline.base.get("version") == 2 and not baseline.flight_checkpoint.has("reason"), "real Base and Fleet states export before inspection")
	_check(_flow.open_location_view("star_map").get("ok", false), "actual star-map entry opens")
	var before_view: Dictionary = _flow.get_remote_inspection_snapshot()
	for invalid: Dictionary in [
		{"operation":"inspect_location", "payload":{"location_id":"not_a_catalog_location"}},
		{"operation":"inspect_orbit", "payload":{"body_id":"planet", "orbit_id":"glut_1a_orbit", "marker_id":"orbit_1"}},
		{"operation":"inspect_orbit", "payload":{"body_id":"glut_1a", "orbit_id":"glut_1a_orbit", "marker_id":"not_a_marker"}}]:
		var rejected: Dictionary = _flow._request_star_map_operation(invalid.operation, invalid.payload)
		_check(not rejected.get("ok", true) and _flow.get_remote_inspection_snapshot() == before_view, "invalid inspection identity rejects before switching views: " + String(rejected.get("reason", "")))
	var unseen := "fortified_outpost"
	_check(registry.get_location(unseen) == null, "future mission has no loaded world before inspection")
	var unknown: Dictionary = _flow._request_star_map_operation("inspect_location", {"location_id":unseen})
	var inspected: Dictionary = _flow.get_remote_inspection_snapshot()
	_check(unknown.get("ok", false) and inspected.view == "inspection" and inspected.screen.blackout and inspected.screen.visible and inspected.screen.title == "Bastion Silex", "catalogued unseen location opens an explicitly black named view")
	_check(not _flow.get("_campaign_tutorial").visible and not _flow.get("_singleplayer_services_toggle").visible, "first remote screen opening immediately suppresses unrelated tutorial and service overlays")
	_check(registry.get_location(unseen) == null and _same(baseline, _owners()), "unknown location creates no mission, actor, area, route, fuel, resource or RNG mutation")
	var remote: Control = _flow.get("_remote_inspection_screen")
	(remote.find_child("BackToStarMap", true, false) as Button).pressed.emit()
	_check(_flow.get_remote_inspection_snapshot().view == "star_map" and not remote.is_visible_in_tree(), "actual remote Back button returns to the retained star map")
	var canonical_orbit := {"kind":"orbit", "body_id":"glut_1b", "orbit_id":"glut_1b_orbit"}
	for marker_id: String in ["", "orbit_1", "orbit_2", "orbit_3"]:
		var payload := {"body_id":"glut_1b", "orbit_id":"glut_1b_orbit"}
		if not marker_id.is_empty(): payload["marker_id"] = marker_id
		var orbit: Dictionary = _flow._request_star_map_operation("inspect_orbit", payload)
		inspected = _flow.get_remote_inspection_snapshot()
		_check(orbit.get("ok", false) and inspected.target == canonical_orbit and inspected.screen.blackout and inspected.screen.title == "Vesper · OM", "canonical orbit and each validated legacy alias share one black body view: " + marker_id)
	_check(_same(baseline, _owners()) and registry.get_location(unseen) == null, "repeated orbit views never admit an area or flight or bind a mission")
	var orbit_context: Dictionary = _flow._capture_location_view_context()
	_flow._show_star_map()
	_check(not remote.is_visible_in_tree(), "intermediate callback view hides the remote orbit screen")
	_flow._restore_location_view_context(orbit_context, "inspection", mission)
	inspected = _flow.get_remote_inspection_snapshot()
	_check(inspected.view == "inspection" and inspected.target == canonical_orbit and inspected.screen.visible and inspected.screen.blackout, "callback context restores the same unknown orbit and visible blackout screen")
	var loaded: Dictionary = _flow.inspect_location_view(location_id)
	inspected = _flow.get_remote_inspection_snapshot()
	_check(loaded.get("ok", false) and _flow.get("_active_mission") == mission and inspected.view == "mission", "known loaded place focuses the same actual runtime instance")
	_check(inspected.terrain.enabled and inspected.terrain.mode == "unexplored_blackout" and inspected.terrain.source_mode == render_before.source_mode and inspected.terrain.terrain_knowledge == render_before.terrain_knowledge, "loaded inspection renders only existing terrain knowledge without changing its source mode")
	terrain_view.set_fog_of_war_state(fog_before)
	var republished: Dictionary = terrain_view.get_inspection_blackout_snapshot()
	_check(republished.enabled and republished.mode == "unexplored_blackout" and republished.source_mode == render_before.source_mode and republished.terrain_knowledge == render_before.terrain_knowledge, "regular real-owner Fog publication retains the inspection filter and the exact known tiles")
	_check(_fog_owner_snapshot(setup) == fog_before and _same(baseline, _owners()), "loaded inspection preserves the authoritative Fog and all campaign simulation owners")
	_check(_flow.inspect_location_view(location_id).get("ok", false) and _same(baseline, _owners()), "replaying loaded inspection remains a pure view operation")
	var previous_context: Dictionary = _flow._capture_location_view_context()
	# Exercise the same view-changing boundary used by a background callback,
	# then restore its captured context. No second gameplay location is faked.
	_flow._show_star_map()
	_check(not terrain_view.get_inspection_blackout_snapshot().enabled, "intermediate normal view transition clears its temporary filter")
	_flow._restore_location_view_context(previous_context, "mission", mission)
	var resumed: Dictionary = _flow.get_remote_inspection_snapshot()
	_check(resumed.target == {"kind":"location", "location_id":location_id} and resumed.terrain.enabled and resumed.terrain.mode == "unexplored_blackout" and resumed.terrain.terrain_knowledge == render_before.terrain_knowledge, "captured callback context restores the original inspection even after an intervening view switch")
	_check(_flow.open_location_view("star_map").get("ok", false), "leaving the inspected mission returns to the star map")
	_check(terrain_view.get_inspection_blackout_snapshot() == render_before and _fog_owner_snapshot(setup) == fog_before, "leaving inspection restores the original render mode without rewriting Fog knowledge")
	_check(_same(baseline, _owners()), "complete inspection journey preserves actual owners and location registry")
	# Reproduce the lifetime boundary from the third real campaign sortie:
	# the saved presentation points at a visit retired by the arrival callback.
	# Only that retired presentation node is synthetic; the replacement, its
	# planning and all campaign/terrain owners remain the actual restored mission.
	var retired_context: Dictionary = _retired_view_context(location_id)
	_flow._restore_location_view_context(retired_context, "star_map", mission)
	_check(_flow.get("_active_mission") == mission and _flow.get_remote_inspection_snapshot().view == "star_map", "retired visit reference restores the live replacement while preserving the caller star map")
	_check(_flow.get("_mission_planning_state") == mission.get_node("TacticalController").get_planning_state(), "replacement visit reads current Controller planning instead of retired callback data")
	retired_context = _retired_view_context(location_id, true)
	_flow._restore_location_view_context(retired_context, "star_map", mission)
	_check(_flow.get("_active_mission") == mission and _flow.get_remote_inspection_snapshot().view == "star_map", "queue-free visit already resolves to its live replacement before the deletion frame")
	retired_context = _retired_view_context(location_id)
	var retired_view := Node.new()
	retired_context["_inspection_target"] = {"kind":"location", "location_id":location_id}
	retired_context["_inspection_terrain_view"] = weakref(retired_view)
	retired_view.free()
	_flow._restore_location_view_context(retired_context, "mission", mission)
	inspected = _flow.get_remote_inspection_snapshot()
	_check(inspected.target == {"kind":"location", "location_id":location_id} and inspected.terrain.enabled and inspected.terrain.mode == "unexplored_blackout" and inspected.terrain.terrain_knowledge == render_before.terrain_knowledge, "same-location replacement reapplies inspection blackout to the new real view after the previous view was freed")
	retired_context = _retired_view_context(unseen)
	_flow._restore_location_view_context(retired_context, "mission", mission)
	inspected = _flow.get_remote_inspection_snapshot()
	_check(inspected.view == "inspection" and inspected.target.location_id == unseen and inspected.screen.blackout, "retired different viewed location becomes its own black inspection instead of switching to an unrelated arriving mission")
	_check(_same(baseline, _owners()), "retired view recovery does not mutate gameplay, files or location owners")
	await _finish()

func _copy_hex_pair() -> bool:
	var pairs := [[HEX_DIR + "checkpoint_v1.json", STORE.DEFAULT_PATH, HEX_HOME_SHA], [HEX_DIR + "active_checkpoint_v1.json", LEGACY_ACTIVE.DEFAULT_PATH, HEX_ACTIVE_SHA]]
	for pair in pairs:
		if not _check(FileAccess.file_exists(pair[0]) and FileAccess.get_sha256(pair[0]) == pair[2], "exact Hex source " + String(pair[0]).get_file()): return false
	if not _check(not FileAccess.file_exists(STORE.DEFAULT_PATH) and not FileAccess.file_exists(LEGACY_ACTIVE.DEFAULT_PATH), "isolated profile is empty before installing fixtures"):
		return false
	_original_home = FileAccess.get_file_as_bytes(pairs[0][0])
	_original_active = FileAccess.get_file_as_bytes(pairs[1][0])
	for pair in pairs:
		if not _check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pair[1]).get_base_dir()) == OK, "private campaign directory is available"):
			return false
		var file := FileAccess.open(pair[1], FileAccess.WRITE)
		if not _check(file != null, "private campaign fixture opens for an exact byte copy"): return false
		var bytes := FileAccess.get_file_as_bytes(pair[0])
		file.store_buffer(bytes)
		file.flush()
		var error := file.get_error()
		file.close()
		if not _check(error == OK and FileAccess.get_file_as_bytes(String(pair[1])) == bytes, "private campaign copy preserves every original byte"): return false
	return true

func _retired_view_context(location_id: String, queued: bool = false) -> Dictionary:
	var actual: Node = _flow.get("_active_mission")
	var retired := Node2D.new()
	retired.set_meta("location_id", location_id)
	_flow.set("_active_mission", retired)
	var context: Dictionary = _flow._capture_location_view_context()
	_flow.set("_active_mission", actual)
	if queued:
		root.add_child(retired)
		retired.queue_free()
	else:
		retired.free()
	context["_mission_planning_state"] = {"retired_visit":true}
	return context

func _fog_owner_snapshot(setup: Node) -> Dictionary:
	var fog: RefCounted = setup.get("_fog_of_war_system")
	var projection: Dictionary = setup.get_fog_of_war_runtime_snapshot()
	return fog.build_team_state_snapshot(String(projection.team_id))

func _owners() -> Dictionary:
	var simulation: Node = _runtime.get("_simulation")
	var mission: Node = _flow.get("_active_mission")
	var local_root: Node = mission.get_node("SimulationRoot")
	return {
		"campaign":_runtime.get("_campaign").export_state(),
		"travel":_runtime.get("_travel").get_snapshot(),
		"flight_checkpoint":_runtime.get("_travel").export_checkpoint_state(),
		"base":_runtime.get("_base_personnel").export_checkpoint_state(),
		"supply":_runtime.get("_supply").export_state(),
		"equipment":_runtime.get("_ship_equipment").export_state(),
		"space_actors":simulation.get("_space_combat_state").get_flight_snapshots(),
		"space_navigation":simulation.get("_space_combat_state").export_navigation_checkpoint(),
		"area_receipts":simulation.get("_fixture_area_receipts").duplicate(true),
		"space_rng":simulation.export_gameplay_rng_state(),
		"mission_rng":local_root.export_gameplay_rng_state(),
		"mission_ground":local_root.get_hex_ground_planning_snapshot(),
		"locations":_flow.get("_location_registry").location_ids().duplicate(),
		"home_file":FileAccess.get_sha256(STORE.DEFAULT_PATH),
		"active_file":FileAccess.get_sha256(LEGACY_ACTIVE.DEFAULT_PATH)
	}

func _finish() -> void:
	if is_instance_valid(_flow): _flow.queue_free()
	current_scene = null
	await process_frame
	if not _original_home.is_empty():
		_check(FileAccess.get_file_as_bytes(HEX_DIR + "checkpoint_v1.json") == _original_home and FileAccess.get_sha256(HEX_DIR + "checkpoint_v1.json") == HEX_HOME_SHA, "authentic Home source remains byte-identical")
		_check(FileAccess.get_file_as_bytes(HEX_DIR + "active_checkpoint_v1.json") == _original_active and FileAccess.get_sha256(HEX_DIR + "active_checkpoint_v1.json") == HEX_ACTIVE_SHA, "authentic Active source remains byte-identical")
		_check(FileAccess.get_file_as_bytes(STORE.DEFAULT_PATH) == _original_home and FileAccess.get_file_as_bytes(LEGACY_ACTIVE.DEFAULT_PATH) == _original_active, "inspection never rewrites either private campaign file")
	print("REMOTE_INSPECTION passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
