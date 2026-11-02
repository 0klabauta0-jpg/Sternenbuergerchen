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
	# The break: a normal contact refresh must not reveal cached density cells
	# from before a FoW delta when aggregation is still throttled. Both keeping
	# the layer hidden and synchronously rebuilding safe cells are valid.
	for topology in ["square8", "hex_axial_v1"]:
		await _test_normal_refresh_keeps_fow_density_safe(topology)
	print("REVIEW_CYCLES_DENSITY_FOW_REFRESH_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_normal_refresh_keeps_fow_density_safe(topology: String) -> void:
	var map = MAP.create_empty("density_fow_refresh", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3, topology)
	var view = VIEW.new()
	root.add_child(view)
	view.set_process(false)
	view.configure_from_map(map)
	var contacts: Array = [
		_contact("enemy_visible", map.get_tile_at_grid(Vector2i(3, 3)).world_position),
		_contact("enemy_hidden", map.get_tile_at_grid(Vector2i(6, 5)).world_position),
	]
	view.set_contact_density_heatmap_enabled(true)
	view.set_contact_entries(contacts)
	var visual_root: Node3D = view.get("_contact_density_root")
	var before: Dictionary = view.get_contact_density_heatmap_snapshot()
	_check(visual_root.visible and visual_root.get_child_count() > 0 and _source_ids(before).has("enemy_hidden"), "%s fixture initially renders a real density source that will become hidden" % topology)
	var fow: Dictionary = {
		"mode": "known_terrain",
		"team_id": "blue",
		"visibility_revision": 1,
		"current_visibility": {
			"visible_target_ids": PackedStringArray(["enemy_visible"]),
			"visible_event_ids": PackedStringArray(),
		},
		"last_known_contacts": [{
			"target_id": "enemy_last_known",
			"last_known_position": map.get_tile_at_grid(Vector2i(2, 6)).world_position,
			"last_seen_tick": 10,
			"detection_state": "lost",
		}],
	}
	view.set_fog_of_war_state(fow)
	_check(not visual_root.visible, "%s FoW delta suppresses the old density meshes immediately" % topology)
	view.set_contact_entries(contacts)
	var immediate: Dictionary = view.get_contact_density_heatmap_snapshot()
	_check(not visual_root.visible or _has_exact_safe_sources(immediate), "%s immediate normal contact refresh never exposes old forbidden density cells" % topology)
	print("DENSITY_FOW_IMMEDIATE ", JSON.stringify({"topology": topology, "visible": visual_root.visible, "source_ids": Array(_source_ids(immediate)), "rebuild_count": immediate.rebuild_count, "skipped_interval_count": immediate.skipped_interval_count}))

	# Let the production interval elapse; do not bypass its throttle or call the
	# force-rebuild helper. A normal consumer refresh must make progress again.
	var refresh_deadline_msec: int = Time.get_ticks_msec() + 350
	while Time.get_ticks_msec() < refresh_deadline_msec:
		await process_frame
	view.set_contact_entries(contacts)
	var ready: Dictionary = view.get_contact_density_heatmap_snapshot()
	_check(visual_root.visible and visual_root.get_child_count() > 0, "%s normal refresh restores actual allowed density meshes after the interval" % topology)
	_check(_has_exact_safe_sources(ready), "%s restored density contains only the visible and last-known sources" % topology)
	_check(int(ready.current_source_count) == 1 and int(ready.last_known_source_count) == 1 and int(ready.fow_hidden_count) == 1, "%s restored density retains current/last-known/hidden accounting" % topology)
	var rebuild_count: int = int(ready.rebuild_count)
	view.set_contact_entries(contacts)
	_check(visual_root.visible and _has_exact_safe_sources(view.get_contact_density_heatmap_snapshot()) and int(view.get_contact_density_heatmap_snapshot().rebuild_count) == rebuild_count, "%s unchanged safe contact refresh keeps meshes visible without reaggregation" % topology)

	# Terrain visibility can change while allowed density sources stay identical.
	# The cached allowed signature can be shown again without another build.
	fow["visibility_revision"] = 2
	view.set_fog_of_war_state(fow)
	_check(not visual_root.visible, "%s another FoW delta suppresses the layer until its sources are checked" % topology)
	view.set_contact_entries(contacts)
	var unchanged: Dictionary = view.get_contact_density_heatmap_snapshot()
	_check(visual_root.visible and _has_exact_safe_sources(unchanged) and int(unchanged.rebuild_count) == rebuild_count, "%s an unchanged allowed signature restores safe cached meshes after a FoW delta" % topology)
	view.set_contact_entries([])
	# The recorded last-known source intentionally remains, even when current
	# contacts clear; a final disabled toggle must still remove every mesh.
	view.set_contact_density_heatmap_enabled(false)
	_check(visual_root.get_child_count() == 0 and int(view.get_contact_density_heatmap_snapshot().heat_cell_count) == 0, "%s disabling density clears all current and last-known meshes" % topology)
	view.free()


func _contact(id: String, position: Vector2) -> Dictionary:
	return {"target_id": id, "unit_id": id, "fireteam_id": "blue", "last_known_position": position, "detection_state": "confirmed", "last_seen_tick": 10, "last_updated_tick": 10}


func _source_ids(snapshot: Dictionary) -> PackedStringArray:
	var result: PackedStringArray = []
	for cell in Array(snapshot.get("heat_cells", [])):
		for source_id in PackedStringArray(Dictionary(cell).get("source_target_ids", PackedStringArray())):
			if not result.has(source_id):
				result.append(source_id)
	result.sort()
	return result


func _has_exact_safe_sources(snapshot: Dictionary) -> bool:
	return _source_ids(snapshot) == PackedStringArray(["enemy_last_known", "enemy_visible"])


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		print("FAIL: ", label)
