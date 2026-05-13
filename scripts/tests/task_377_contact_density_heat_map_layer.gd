extends SceneTree

const CONTACT_DENSITY_OVERLAY_SCRIPT: GDScript = preload("res://scripts/tactical/visuals/contact_density_overlay.gd")
const FOG_OF_WAR_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_system.gd")
const FOG_OF_WAR_MODE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_mode_contract.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_377_contact_density_heat_map_layer.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_377 Contact Density Heat Map Layer ===")
	_test_overlay_aggregates_two_clusters()
	_test_fog_of_war_filters_density_sources()
	await _test_primary_view_heatmap_toggle_and_interval()
	await _test_primary_view_respects_fow_last_known_only()
	_test_docs()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_overlay_aggregates_two_clusters() -> void:
	var overlay = CONTACT_DENSITY_OVERLAY_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(overlay.call("build_heat_cells", [
		_contact("enemy_a", "blue", Vector2(24.0, 24.0), "confirmed"),
		_contact("enemy_b", "blue", Vector2(72.0, 48.0), "spotted"),
		_contact("enemy_c", "blue", Vector2(318.0, 304.0), "confirmed"),
		_contact("enemy_d", "blue", Vector2(352.0, 336.0), "lost"),
	], {"cell_size_world": 128.0, "max_heat_cells": 8}))
	var cells: Array = Array(snapshot.get("heat_cells", []))
	_assert(int(snapshot.get("heat_cell_count", 0)) == 2, "Overlay aggregates contacts into two heat clusters")
	_assert(cells.size() == 2, "Heat cells are returned in snapshot")
	_assert(int(Dictionary(cells[0]).get("contact_count", 0)) == 2 and int(Dictionary(cells[1]).get("contact_count", 0)) == 2, "Each cluster contains two contacts")
	_assert(bool(snapshot.get("visual_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Overlay snapshot is visual-only and non-authoritative")


func _test_fog_of_war_filters_density_sources() -> void:
	var fow = FOG_OF_WAR_SYSTEM_SCRIPT.new()
	fow.call("set_mode_for_team", "blue", FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_KNOWN_TERRAIN)
	fow.call("set_visible", "blue", "enemy_visible", true)
	fow.call("record_last_known_contact", "blue", {
		"target_id": "enemy_last_known",
		"last_known_position": Vector2(320.0, 320.0),
		"last_seen_tick": 8,
	})
	var filtered: Dictionary = Dictionary(fow.call("filter_contact_density_sources_for_team", "blue", [
		_contact("enemy_visible", "blue", Vector2(40.0, 40.0), "confirmed"),
		_contact("enemy_hidden", "blue", Vector2(90.0, 90.0), "confirmed"),
	]))
	var source_ids: PackedStringArray = _source_target_ids(Array(filtered.get("source_entries", [])))
	_assert(int(filtered.get("source_count", 0)) == 2, "FoW density filter keeps visible current and recorded last-known contacts")
	_assert(int(filtered.get("hidden_count", 0)) == 1, "FoW density filter counts hidden contacts")
	_assert(source_ids.has("enemy_visible") and source_ids.has("enemy_last_known"), "FoW density source list includes visible and last-known IDs")
	_assert(not source_ids.has("enemy_hidden"), "FoW density source list does not expose hidden enemy IDs")


func _test_primary_view_heatmap_toggle_and_interval() -> void:
	var primary_view: Node = _make_primary_view()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", _make_map_data())
	await _wait_frames(4)

	primary_view.call("set_order_visual_payload", {"contact_density_heatmap_enabled": true})
	primary_view.call("set_contact_entries", [
		_contact("enemy_a", "blue", Vector2(24.0, 24.0), "confirmed"),
		_contact("enemy_b", "blue", Vector2(72.0, 48.0), "spotted"),
		_contact("enemy_c", "blue", Vector2(318.0, 304.0), "confirmed"),
		_contact("enemy_d", "blue", Vector2(352.0, 336.0), "lost"),
	], PackedStringArray(["blue"]))
	await _wait_frames(2)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(bool(snapshot.get("contact_density_heatmap_enabled", false)), "Primary view toggles contact density heatmap on")
	_assert(int(snapshot.get("contact_density_heat_cell_count", 0)) == 2, "Primary view reports two heat cells")
	_assert(int(snapshot.get("contact_density_source_contact_count", 0)) == 4, "Primary view heatmap uses four allowed source contacts")
	var rebuild_count: int = int(snapshot.get("contact_density_rebuild_count", 0))

	primary_view.call("set_contact_entries", [
		_contact("enemy_a", "blue", Vector2(24.0, 24.0), "confirmed"),
		_contact("enemy_b", "blue", Vector2(72.0, 48.0), "spotted"),
		_contact("enemy_c", "blue", Vector2(318.0, 304.0), "confirmed"),
		_contact("enemy_d", "blue", Vector2(352.0, 336.0), "lost"),
		_contact("enemy_e", "blue", Vector2(360.0, 344.0), "spotted"),
	], PackedStringArray(["blue"]))
	var interval_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(interval_snapshot.get("contact_density_rebuild_count", 0)) == rebuild_count, "Heatmap aggregation does not rebuild again inside the update interval")
	_assert(int(interval_snapshot.get("contact_density_skipped_interval_count", 0)) >= 1, "Heatmap reports interval-skipped updates")

	primary_view.call("set_contact_density_heatmap_enabled", false)
	var disabled_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(not bool(disabled_snapshot.get("contact_density_heatmap_enabled", true)), "Primary view toggles contact density heatmap off")
	_assert(int(disabled_snapshot.get("contact_density_heat_cell_count", -1)) == 0, "Disabled heatmap exposes zero heat cells")

	primary_view.queue_free()
	await _wait_frames(2)


func _test_primary_view_respects_fow_last_known_only() -> void:
	var primary_view: Node = _make_primary_view()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", _make_map_data())
	await _wait_frames(4)

	primary_view.call("set_order_visual_payload", {"contact_density_heatmap_enabled": true})
	primary_view.call("set_contact_entries", [
		_contact("enemy_visible_a", "blue", Vector2(24.0, 24.0), "confirmed"),
		_contact("enemy_visible_b", "blue", Vector2(72.0, 48.0), "spotted"),
		_contact("enemy_hidden", "blue", Vector2(92.0, 92.0), "confirmed"),
	], PackedStringArray())
	primary_view.call("set_fog_of_war_state", {
		"mode": FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_KNOWN_TERRAIN,
		"team_id": "blue",
		"current_visibility": {
			"visible_target_ids": PackedStringArray(["enemy_visible_a", "enemy_visible_b"]),
			"visible_event_ids": PackedStringArray(),
		},
		"last_known_contacts": [
			{
				"target_id": "enemy_last_known",
				"last_known_position": Vector2(330.0, 324.0),
				"last_seen_tick": 12,
				"detection_state": "lost",
			},
		],
	})
	await _wait_frames(2)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var heat_cells: Array = Array(snapshot.get("contact_density_heat_cells", []))
	var source_ids: PackedStringArray = _heat_cell_source_ids(heat_cells)
	_assert(int(snapshot.get("contact_density_fow_hidden_count", 0)) == 1, "Heatmap counts the hidden FoW contact")
	_assert(int(snapshot.get("contact_density_source_contact_count", 0)) == 3, "Heatmap uses two visible contacts plus one last-known contact")
	_assert(source_ids.has("enemy_visible_a") and source_ids.has("enemy_visible_b") and source_ids.has("enemy_last_known"), "Heatmap source IDs include visible and last-known contacts")
	_assert(not source_ids.has("enemy_hidden"), "Heatmap does not reveal hidden enemy IDs")

	primary_view.queue_free()
	await _wait_frames(2)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_377 task file exists")
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_377 is marked implemented")
	_assert(status_text.contains("TASK_377") and status_text.to_lower().contains("implementiert"), "Implementation status mentions TASK_377")
	_assert(roadmap_text.contains("TASK_377") and roadmap_text.to_lower().contains("implementiert"), "Roadmap mentions TASK_377")


func _make_primary_view() -> Node:
	return TERRAIN_MAP_3D_VIEW_SCRIPT.new()


func _make_map_data():
	return TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_377_contact_density", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3)


func _contact(target_id: String, fireteam_id: String, position: Vector2, detection_state: String) -> Dictionary:
	return {
		"target_id": target_id,
		"unit_id": target_id,
		"fireteam_id": fireteam_id,
		"last_known_position": position,
		"detection_state": detection_state,
		"last_seen_tick": 10,
		"last_updated_tick": 10,
	}


func _source_target_ids(source_entries: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for entry_variant in source_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var target_id: String = String(Dictionary(entry_variant).get("target_id", Dictionary(entry_variant).get("unit_id", ""))).strip_edges()
		if not target_id.is_empty() and not result.has(target_id):
			result.append(target_id)
	result.sort()
	return result


func _heat_cell_source_ids(heat_cells: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for cell_variant in heat_cells:
		if typeof(cell_variant) != TYPE_DICTIONARY:
			continue
		for source_id in PackedStringArray(Dictionary(cell_variant).get("source_target_ids", PackedStringArray())):
			if not result.has(source_id):
				result.append(source_id)
	result.sort()
	return result


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
