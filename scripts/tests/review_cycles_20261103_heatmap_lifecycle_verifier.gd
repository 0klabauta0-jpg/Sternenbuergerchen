extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	# The break: a map/streaming rebuild frees density meshes while leaving the
	# unchanged heat-cell signature cached, so ordinary contact refresh cannot
	# restore the visible overlay. Keep real map, contact, FoW and mesh paths.
	for topology in ["square8", "hex_axial_v1"]:
		_test_heatmap_survives_visual_rebuild(topology)
	print("REVIEW_CYCLES_HEATMAP_LIFECYCLE_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_heatmap_survives_visual_rebuild(topology: String) -> void:
	var map = MAP.create_empty("heatmap_lifecycle", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3, topology)
	var view = VIEW.new()
	root.add_child(view)
	view.set_process(false)
	view.configure_from_map(map)
	var contact_position: Vector2 = map.get_tile_at_grid(Vector2i(3, 3)).world_position
	var contacts: Array = [
		_contact("enemy_visible", contact_position),
		_contact("enemy_hidden", map.get_tile_at_grid(Vector2i(6, 5)).world_position),
	]
	view.set_contact_density_heatmap_enabled(true)
	view.set_contact_entries(contacts, PackedStringArray(["blue"]))
	var before: Dictionary = view.get_contact_density_heatmap_snapshot()
	var visual_root: Node = view.get("_contact_density_root")
	_check(int(before.source_contact_count) == 2 and int(before.heat_cell_count) > 0, "%s real contacts populate heat cells" % topology)
	_check(visual_root.visible and visual_root.get_child_count() > 0, "%s heat cells have actual visible rendered mesh nodes" % topology)
	var heat_cells: Array = before.heat_cells.duplicate(true)
	view.render_map()
	_check(view.get_contact_density_heatmap_snapshot().heat_cells == heat_cells, "%s visual rebuild preserves read-only contact density facts" % topology)
	_check(visual_root.visible and visual_root.get_child_count() > 0, "%s map rebuild restores the visible heatmap without new contact data" % topology)
	view.set_contact_entries(contacts, PackedStringArray(["blue"]))
	_check(visual_root.visible and visual_root.get_child_count() > 0, "%s identical ordinary contact refresh cannot leave the heatmap missing" % topology)
	view.render_map(map)
	_check(visual_root.visible and visual_root.get_child_count() > 0, "%s explicit map refresh retains the enabled heatmap" % topology)

	# Start the FoW preservation case with no cached sources. A FoW delta alone
	# intentionally suppresses the old mesh until the ordinary contact refresh;
	# it does not synchronously reaggregate metadata inside the update interval.
	view.set_contact_entries([], PackedStringArray(["blue"]))
	view.set_fog_of_war_state({
		"mode": "known_terrain",
		"team_id": "blue",
		"current_visibility": {
			"visible_target_ids": PackedStringArray(["enemy_visible"]),
			"visible_event_ids": PackedStringArray(),
		},
		"last_known_contacts": [],
	})
	view.set_contact_entries(contacts, PackedStringArray(["blue"]))
	var filtered: Dictionary = view.get_contact_density_heatmap_snapshot()
	_check(int(filtered.source_contact_count) == 1 and int(filtered.fow_hidden_count) == 1, "%s FoW filters the hidden density source" % topology)
	view.render_map()
	var after_fow_rebuild: Dictionary = view.get_contact_density_heatmap_snapshot()
	_check(int(after_fow_rebuild.source_contact_count) == 1 and int(after_fow_rebuild.fow_hidden_count) == 1, "%s restoring density after a map rebuild keeps the FoW filter" % topology)
	_check(visual_root.visible and visual_root.get_child_count() > 0, "%s allowed heatmap remains visible after a FoW-aware map rebuild" % topology)
	view.set_contact_entries([], PackedStringArray(["blue"]))
	_check(visual_root.get_child_count() == 0 and int(view.get_contact_density_heatmap_snapshot().heat_cell_count) == 0, "%s removing contacts clears both density data and meshes" % topology)
	view.set_contact_density_heatmap_enabled(false)
	view.render_map()
	_check(visual_root.get_child_count() == 0 and not bool(view.get_contact_density_heatmap_snapshot().enabled), "%s rebuilding a disabled heatmap leaves it disabled and empty" % topology)
	view.free()


func _contact(id: String, position: Vector2) -> Dictionary:
	return {
		"target_id": id,
		"unit_id": id,
		"fireteam_id": "blue",
		"last_known_position": position,
		"detection_state": "confirmed",
		"last_seen_tick": 10,
		"last_updated_tick": 10,
	}


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		print("FAIL: ", label)
