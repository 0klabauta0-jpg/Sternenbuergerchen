extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA := preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW := preload("res://scripts/terrain/terrain_map_3d_view.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1122 Connected Mission World Camera Exposure Contact Cluster Readability ===")
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	for _frame in range(10):
		await process_frame
	var controller: Node = mission.get_node("TacticalController")
	var view: Node = mission.get_node_or_null("Primary3DView")
	_assert(view != null, "Product mission exposes Primary3DView")
	if view != null:
		var before: Dictionary = Dictionary(view.call("get_render_snapshot"))
		var light: Dictionary = Dictionary(before.get("editor_light", {}))
		_assert(bool(before.get("frontier_art_enabled", false)) and String(before.get("frontier_art_profile_id", "")) == "frontier_illustrated_v1", "Default GM01 selects the Frontier visual profile")
		_assert(bool(light.get("tonemap_enabled", false)), "Primary3D environment enables explicit tonemapping")
		_assert(String(light.get("tonemap_mode", "")) == "aces", "Default Frontier mission uses ACES tonemapping")
		_assert(is_equal_approx(float(light.get("adjustment_brightness", 0.0)), 1.0), "Default Frontier mission keeps neutral brightness")
		_assert(view.has_method("frame_world_positions"), "Primary3D exposes bounds-based tactical framing")
		if view.has_method("frame_world_positions"):
			var framed: Dictionary = Dictionary(view.call("frame_world_positions", [Vector2(120.0, 230.0), Vector2(228.0, 230.0)], 6.0, 18.0, 28.0))
			var after: Dictionary = Dictionary(view.call("get_render_snapshot"))
			_assert(bool(framed.get("framed", false)) and float(after.get("camera_size", 99.0)) <= 28.0, "First Contact framing uses a closer bounded camera size")

	_assert(controller.has_method("_select_connected_first_contact_fire_visual_events"), "Controller exposes read-only local Fire visual selection")
	if controller.has_method("_select_connected_first_contact_fire_visual_events"):
		var selected_events: Array = Array(controller.call("_select_connected_first_contact_fire_visual_events", [
			_fire_event("blue_old", "blue", 1000),
			_fire_event("gold_old", "gold", 2000),
			_fire_event("gold_new", "gold", 3000),
		], PackedStringArray(["gold"]), true))
		_assert(selected_events.size() == 1 and String(Dictionary(selected_events[0]).get("event_id", "")) == "gold_new", "Connected GOLD world keeps only its newest Fire event")
		var offline_events: Array = Array(controller.call("_select_connected_first_contact_fire_visual_events", [_fire_event("blue_old", "blue", 1000), _fire_event("gold_new", "gold", 3000)], PackedStringArray(["gold"]), false))
		_assert(offline_events.size() == 2, "Offline and spectator-style world paths retain bounded global events")

	var boundary_dedupe: Dictionary = Dictionary(controller.call("_dedupe_release_first_contact_display_entries", [
		_contact_event("contact_chain_start", 0),
		_contact_event("contact_before", 4900),
		_contact_event("contact_after", 5100),
	]))
	var deduped_entries: Array = Array(boundary_dedupe.get("entries", []))
	_assert(deduped_entries.size() == 1 and int(Dictionary(deduped_entries[0]).get("repeat_count", 0)) == 3, "Contact dedupe follows a continuous sliding chain across fixed bucket boundaries")
	_assert(controller.has_method("_focus_connected_first_contact_world"), "Controller owns a one-shot connected Contact framing hook")

	mission.queue_free()
	await process_frame
	_check_unthemed_map_lighting()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check_unthemed_map_lighting() -> void:
	var view := TERRAIN_MAP_3D_VIEW.new()
	root.add_child(view)
	view.configure_from_map(TERRAIN_MAP_DATA.create_empty("task_1122_unthemed", Vector2i(4, 4), Vector2.ZERO))
	var snapshot: Dictionary = view.get_render_snapshot()
	var light: Dictionary = Dictionary(snapshot.get("editor_light", {}))
	_assert(not bool(snapshot.get("frontier_art_enabled", true)) and bool(light.get("tonemap_enabled", false)) and String(light.get("tonemap_mode", "")) == "filmic", "Unthemed map retains explicit Filmic tonemapping")
	var brightness: float = float(light.get("adjustment_brightness", 0.0))
	_assert(brightness >= 0.65 and brightness < 1.0, "Unthemed map retains bounded brightness correction")
	view.queue_free()


func _fire_event(event_id: String, fireteam_id: String, created_msec: int) -> Dictionary:
	return {"event_id": event_id, "attacker_fireteam_id": fireteam_id, "created_msec": created_msec, "attacker_position": Vector2.ZERO, "target_position": Vector2.ONE}


func _contact_event(event_id: String, created_msec: int) -> Dictionary:
	return {"event_id": event_id, "event_type": "contact_report", "fireteam_id": "gold", "unit_id": "enemy_delta", "created_msec": created_msec, "short_text": "GOLD 1 Kontakt"}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
