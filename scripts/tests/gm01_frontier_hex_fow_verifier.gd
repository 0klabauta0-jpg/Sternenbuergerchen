extends SceneTree
## Actual default-map rendering state over multiple frames; no gameplay writes.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
var passed := 0
var failed := 0
var _rendered_slot_assertion_count := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)

func run() -> void:
	if OS.get_cmdline_user_args().has("--require-rendered-slots"):
		check(DisplayServer.get_name() != "headless", "Required rendered-slot proof uses a real display backend, not headless Dummy readback")
	var data = MAP.load_from_file("res://maps/Ground_Mission01_32x32.json")
	var view = VIEW.new()
	root.add_child(view)
	view.configure_from_map(data)
	check(data.get_grid_topology() == "hex_axial_v1", "Default mission is a real Hex map")
	var known := {"mode":"known_terrain", "team_id":"team_alpha", "terrain_knowledge":{"visible_tile_ids":[]}, "current_visibility":{"visible_target_ids":["visible_enemy"]}}
	view.set_fog_of_war_state(known)
	var flashes := 0
	for iteration in range(12):
		if iteration == 6:
			view.render_map()
		if is_instance_valid(view.get("_fow_overlay_safety_cover")):
			flashes += 1
		await process_frame
	check(flashes == 0, "Known terrain never receives a temporary all-black rectangle, including a cold rebuild")
	check(bool(view.call("_fow_is_target_currently_visible", "visible_enemy")) and not bool(view.call("_fow_is_target_currently_visible", "hidden_enemy")), "Removing the known-map flash preserves dynamic enemy filtering")
	var snapshot: Dictionary = view.get_render_snapshot()
	check(int(snapshot.get("tile_grid_line_count", 0)) > 0 and bool(snapshot.get("authored_visual_grid_visible", false)), "Actual Hex edges are visible by default")
	var mask: ArrayMesh = view.call("_make_fow_tile_overlay_mesh", 1.0)
	check(mask != null and mask.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == 18, "Visibility mask has six flat triangles, without doubled prism faces")
	var blackout := known.duplicate(true)
	blackout["mode"] = "unexplored_blackout"
	view.set_fog_of_war_state(blackout)
	check(is_instance_valid(view.get("_fow_overlay_safety_cover")), "Unexplored mode retains its protective blackout while unknown cells are batched")
	var cover := view.get("_fow_overlay_safety_cover") as Node3D
	check(cover.position.y > float(view.get("_authored_visual_top_y")) and cover.position.y > 3.0, "Unknown protection is above the actual tall meshes, independently of gameplay height classes")
	for iteration in range(48):
		await process_frame
		if not bool(view.get("_fow_overlay_full_rebuild_pending")):
			break
	snapshot = view.get_render_snapshot()
	check(not is_instance_valid(view.get("_fow_overlay_safety_cover")) and int(snapshot.get("fow_unknown_tile_count", 0)) == data.get_tiles().size(), "Completed unknown-cell masks protect every saved cell and replace the temporary cover")
	check(data.get_tiles().size() == 9408, "Continuous-snapshot regression uses all 9408 actual saved GM01 cells")
	await _test_continuous_snapshots(view, "known_terrain", "team_alpha")
	await _test_continuous_snapshots(view, "unexplored_blackout", "team_alpha")
	await _test_continuous_snapshots(view, "unexplored_blackout", "team_beta")
	var west := Vector2i(-16, 40)
	var world: Vector2 = data.call("_grid_to_world", west)
	view.focus_world_position(world)
	view.call("_clamp_focus_to_map")
	check(view.get_camera_focus_grid_position().distance_to(Vector2(west)) < 0.01, "Negative axial coordinates remain reachable by the real camera clamp")
	check(bool(view.call("_visual_chunk_overlaps_map", Vector2i(-1, 3))) and not bool(view.call("_visual_chunk_overlaps_map", Vector2i(100, 3))), "Streaming bounds include negative Hex chunks and reject distant chunks")
	view.focus_map_center()
	var plane: Vector2 = view.get("_map_plane_bounds").get_center()
	var hex = preload("res://scripts/terrain/hex_grid.gd")
	check(hex.axial_to_plane(view.get_camera_focus_grid_position()).distance_to(plane) < 0.01, "Default framing uses the physical Hex footprint")
	var before_pan: Vector2 = hex.axial_to_plane(view.get_camera_focus_grid_position())
	var yaw := deg_to_rad(view.get_camera_yaw_degrees())
	view.pan_camera(Vector2.UP, 0.02)
	var movement: Vector2 = hex.axial_to_plane(view.get_camera_focus_grid_position()) - before_pan
	var expected := Vector2(-sin(yaw), -cos(yaw))
	check(movement.normalized().dot(expected) > 0.999, "Keyboard and drag panning use the camera's physical directions on Hex terrain")
	view.free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed])
	print("GM01_HEX_FOW_ALL_PASS" if failed == 0 else "GM01_HEX_FOW_FAILED")
	if failed == 0 and DisplayServer.get_name() != "headless" and _rendered_slot_assertion_count == 3:
		print("GM01_HEX_FOW_RENDERED_ALL_PASS")
	quit(0 if failed == 0 else 1)


func _streaming_snapshot(mode: String, team_id: String, ids: PackedStringArray, phase: int, revision: int) -> Dictionary:
	var visible: Array = [ids[0], ids[ids.size() - 2]]
	var explored: Array = [ids[1], ids[ids.size() - 1]]
	if phase % 2 == 1:
		visible = [ids[1], ids[ids.size() - 1]]
		explored = [ids[0], ids[ids.size() - 2]]
	return {
		"mode": mode, "team_id": team_id, "visibility_revision": revision,
		"terrain_knowledge": {"visible_tile_ids": visible, "explored_tile_ids": explored},
		"current_visibility": {
			"visible_target_ids": ["contact_a" if revision % 2 == 0 else "contact_b"],
			"visible_event_ids": ["event_a" if revision % 2 == 0 else "event_b"],
		},
		# These are complete snapshots, deliberately without producer delta hints.
	}


func _test_continuous_snapshots(view, mode: String, team_id: String) -> void:
	var label := "%s/%s continuous full snapshots" % [mode, team_id]
	var ids := PackedStringArray(view.get("_fow_overlay_render_tile_ids"))
	check(ids.size() == 9408, label + ": resident mask covers the actual map")
	if ids.size() < 4:
		return
	var previous_mesh: MultiMesh = view.get("_fow_overlay_multimesh")
	var start_full := int(view.get("_fow_overlay_full_rebuild_count"))
	var start_rebuild := int(view.get("_fow_overlay_rebuild_count"))
	var state := _streaming_snapshot(mode, team_id, ids, 0, 3)
	view.set_fog_of_war_state(state)
	var mesh: MultiMesh = view.get("_fow_overlay_multimesh")
	check(mesh != null and mesh != previous_mesh and bool(view.get("_fow_overlay_full_rebuild_pending")) and int(view.get("_fow_overlay_pending_cursor")) == 0, label + ": mode/team switch starts the original full build")
	var initial_cover = view.get("_fow_overlay_safety_cover")
	var is_unknown := mode == "unexplored_blackout"
	check(is_instance_valid(initial_cover) == is_unknown, label + ": only unknown terrain starts with protective blackout")
	# approximate_position is render-only. Without a position-based visibility
	# fallback, exactly the currently published target ID may become a contact.
	view.set_contact_entries([
		{"unit_id": "contact_a", "approximate_position": Vector2.ZERO},
		{"unit_id": "contact_b", "approximate_position": Vector2.ZERO},
	])
	var cursor_preserved := true
	var batch_progress_preserved := true
	var mesh_preserved := true
	var cover_preserved := true
	var contacts_match := true
	var contact_only_does_not_rebuild := true
	var samples_match := true
	var changed_built_and_pending := false
	var frames := 0
	var phase := 0
	for iteration in range(48):
		var before_cursor := int(view.get("_fow_overlay_pending_cursor"))
		var before_pending := bool(view.get("_fow_overlay_full_rebuild_pending"))
		var before_delta := int(view.get("_fow_overlay_delta_apply_count"))
		var revision := 10 + iteration * 7
		var contact_only := iteration % 4 == 3
		if contact_only:
			state = state.duplicate(true)
			state["visibility_revision"] = revision
			state["current_visibility"] = _streaming_snapshot(mode, team_id, ids, phase, revision)["current_visibility"]
		else:
			phase += 1
			state = _streaming_snapshot(mode, team_id, ids, phase, revision)
		view.set_fog_of_war_state(state)
		cursor_preserved = cursor_preserved and before_pending and bool(view.get("_fow_overlay_full_rebuild_pending")) and int(view.get("_fow_overlay_pending_cursor")) == before_cursor
		mesh_preserved = mesh_preserved and view.get("_fow_overlay_multimesh") == mesh
		if contact_only:
			contact_only_does_not_rebuild = contact_only_does_not_rebuild and int(view.get("_fow_overlay_delta_apply_count")) == before_delta
		elif before_cursor >= 512 and before_cursor < ids.size() - 2:
			changed_built_and_pending = true
			var actual_states: Dictionary = view.get("_fow_overlay_tile_states_by_id")
			var visible: Array = state["terrain_knowledge"]["visible_tile_ids"]
			for index in [0, 1, ids.size() - 2, ids.size() - 1]:
				var expected := "visible" if visible.has(ids[index]) else ("known" if not is_unknown else "explored")
				samples_match = samples_match and String(actual_states.get(ids[index], "missing")) == expected
		var entries: Array = view.call("_get_contact_visual_entries")
		var target_id := String(state["current_visibility"]["visible_target_ids"][0])
		contacts_match = contacts_match and entries.size() == 1 and int(view.get("_fow_hidden_contact_count")) == 1
		if entries.size() == 1:
			contacts_match = contacts_match and String(entries[0].get("unit_id", "")) == target_id
		contacts_match = contacts_match and bool(view.call("_fow_is_event_currently_visible", String(state["current_visibility"]["visible_event_ids"][0]))) and not bool(view.call("_fow_is_target_currently_visible", "hidden_enemy"))
		cover_preserved = cover_preserved and (is_instance_valid(view.get("_fow_overlay_safety_cover")) == is_unknown)
		if is_unknown:
			cover_preserved = cover_preserved and view.get("_fow_overlay_safety_cover") == initial_cover and not bool(view.get("_fow_overlay_multimesh_instance").visible)
		await process_frame
		frames += 1
		if not bool(view.get("_fow_overlay_full_rebuild_pending")):
			break
		var advanced := int(view.get("_fow_overlay_pending_cursor")) - before_cursor
		batch_progress_preserved = batch_progress_preserved and advanced >= 0 and advanced <= 512
	check(not bool(view.get("_fow_overlay_full_rebuild_pending")) and frames <= 48, label + ": finishes within the unchanged 48-frame bound despite continual updates")
	check(cursor_preserved and batch_progress_preserved and mesh_preserved, label + ": setters never reset the original 512-cell cursor or replace its mask")
	check(changed_built_and_pending and samples_match, label + ": complete snapshots update both previously built and still-pending slots across skipped revisions")
	check(contact_only_does_not_rebuild and contacts_match, label + ": contact-only updates preserve terrain work and keep the real contact/event filter current")
	check(cover_preserved and not is_instance_valid(view.get("_fow_overlay_safety_cover")) and bool(view.get("_fow_overlay_multimesh_instance").visible), label + ": unknown protection survives to completion; known terrain never flashes black")
	check(int(view.get("_fow_overlay_full_rebuild_count")) == start_full + 1 and int(view.get("_fow_overlay_rebuild_count")) == start_rebuild + 1, label + ": exactly one full build completes")
	_assert_complete_snapshot(view, ids, state, label)
	var final_states: Dictionary = Dictionary(view.get("_fow_overlay_tile_states_by_id")).duplicate(true)
	var final_delta := int(view.get("_fow_overlay_delta_apply_count"))
	for iteration in range(4):
		state = state.duplicate(true)
		state["visibility_revision"] = int(state["visibility_revision"]) + 11
		state["current_visibility"] = _streaming_snapshot(mode, team_id, ids, phase, int(state["visibility_revision"]))["current_visibility"]
		view.set_fog_of_war_state(state)
		await process_frame
	check(view.get("_fow_overlay_multimesh") == mesh and not bool(view.get("_fow_overlay_full_rebuild_pending")) and int(view.get("_fow_overlay_full_rebuild_count")) == start_full + 1 and int(view.get("_fow_overlay_rebuild_count")) == start_rebuild + 1 and int(view.get("_fow_overlay_delta_apply_count")) == final_delta and view.get("_fow_overlay_tile_states_by_id") == final_states, label + ": completed terrain also ignores contact-only revisions without rebuilding")
	print("FOW_CONTINUOUS_SNAPSHOT ", JSON.stringify({"mode": mode, "team_id": team_id, "cells": ids.size(), "frames": frames, "last_revision": state["visibility_revision"]}))


func _assert_complete_snapshot(view, ids: PackedStringArray, state: Dictionary, label: String) -> void:
	var visible: Array = state["terrain_knowledge"]["visible_tile_ids"]
	var explored: Array = state["terrain_knowledge"]["explored_tile_ids"]
	var known := String(state["mode"]) == "known_terrain"
	var actual: Dictionary = view.get("_fow_overlay_tile_states_by_id")
	var counts := {"visible": 0, "known": 0, "explored": 0, "unknown": 0}
	var states_match := actual.size() == ids.size()
	var rendered_match := true
	var mesh: MultiMesh = view.get("_fow_overlay_multimesh")
	var slots: Dictionary = view.get("_fow_overlay_slot_by_tile_id")
	var alpha := {"visible": 0.0, "known": 0.08, "explored": 0.62, "unknown": 1.0}
	var authored_top := float(view.get("_authored_visual_top_y"))
	var mismatches: Array = []
	var can_read_rendered_slots := DisplayServer.get_name() != "headless"
	for tile_id in ids:
		var expected := "visible" if visible.has(tile_id) else ("known" if known else ("explored" if explored.has(tile_id) else "unknown"))
		counts[expected] += 1
		var actual_state := String(actual.get(tile_id, "missing"))
		var tile_state_matches := actual_state == expected
		states_match = states_match and tile_state_matches
		if not can_read_rendered_slots:
			if not tile_state_matches and mismatches.size() < 3:
				mismatches.append({"tile_id": tile_id, "expected": expected, "actual": actual_state})
			continue
		if mesh == null or not slots.has(tile_id):
			rendered_match = false
			if mismatches.size() < 3:
				mismatches.append({"tile_id": tile_id, "expected": expected, "actual": actual_state, "mesh_missing": mesh == null, "slot_missing": not slots.has(tile_id), "authored_top": authored_top})
			continue
		var slot := int(slots[tile_id])
		var color: Color = mesh.get_instance_color(slot)
		var position: Vector3 = mesh.get_instance_transform(slot).origin
		var tile_render_matches := absf(color.a - float(alpha[expected])) < 0.01
		if expected == "visible":
			tile_render_matches = tile_render_matches and position.y < -99999.0
		elif expected == "unknown":
			tile_render_matches = tile_render_matches and position.y > authored_top
		rendered_match = rendered_match and tile_render_matches
		if (not tile_state_matches or not tile_render_matches) and mismatches.size() < 3:
			mismatches.append({"tile_id": tile_id, "slot": slot, "expected": expected, "actual": actual_state, "expected_alpha": alpha[expected], "actual_alpha": color.a, "position": [position.x, position.y, position.z], "authored_top": authored_top})
	var snapshot: Dictionary = view.get_render_snapshot()
	if not mismatches.is_empty():
		print("FOW_FINAL_SLOT_MISMATCH ", JSON.stringify({"case": label, "display_server": DisplayServer.get_name(), "state_count": actual.size(), "slot_count": slots.size(), "mismatches": mismatches}))
	check(states_match, label + ": every final CPU tile state matches the latest complete snapshot")
	if can_read_rendered_slots:
		_rendered_slot_assertion_count += 1
		check(rendered_match, label + ": every actual rendered mask slot matches the latest complete snapshot")
	else:
		print("FOW_RENDERED_SLOTS_SKIPPED ", JSON.stringify({"case": label, "reason": "headless Dummy returns zero transforms/default colors; CPU state/counters remain checked", "rendered_evidence": false}))
	check(int(snapshot.get("fow_visible_tile_count", -1)) == counts["visible"] and int(snapshot.get("fow_known_dim_tile_count", -1)) == counts["known"] and int(snapshot.get("fow_explored_tile_count", -1)) == counts["explored"] and int(snapshot.get("fow_unknown_tile_count", -1)) == counts["unknown"] and int(snapshot.get("fow_overlay_tile_count", -1)) == ids.size() - int(counts["visible"]) and int(snapshot.get("fow_tile_total_count", -1)) == ids.size(), label + ": all aggregate counters equal the independently counted final states")
	check(int(snapshot.get("fow_overlay_visibility_revision", -1)) == int(state["visibility_revision"]), label + ": final mask revision equals the latest skipped producer revision")
