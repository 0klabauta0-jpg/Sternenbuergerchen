extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_544_mission_fire_cover_visual_polish_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TERRAIN_VIEW_PATH: String = "res://scripts/terrain/terrain_map_3d_view.gd"

var _passed: int = 0
var _failed: int = 0


class DummyUnit extends Node2D:
	var unit_id: String = ""
	var fireteam_id: String = ""
	var team_id: String = "team_alpha"
	var weapon_id: String = "rifle"
	var contact_active: bool = false
	var health_points: int = 100

	func _init(next_unit_id: String, next_fireteam_id: String, next_team_id: String, next_position: Vector2, next_weapon_id: String = "rifle") -> void:
		unit_id = next_unit_id
		fireteam_id = next_fireteam_id
		team_id = next_team_id
		global_position = next_position
		weapon_id = next_weapon_id
		visible = true

	func get_unit_id() -> String:
		return unit_id

	func get_fireteam_id() -> String:
		return fireteam_id

	func get_team_id() -> String:
		return team_id

	func get_vital_state() -> String:
		return "fit"

	func get_health() -> int:
		return health_points

	func get_max_health_points() -> int:
		return 100

	func get_active_weapon_id() -> String:
		return weapon_id

	func get_weapon_1_id() -> String:
		return weapon_id

	func get_weapon_2_id() -> String:
		return "pistol"

	func is_in_contact() -> bool:
		return contact_active


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_544 Mission Fire And Cover Visual Polish Pass ===")
	_test_docs_and_wiring()
	await _test_fire_cover_visual_polish_render_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_544: FAILED")
		quit(1)
		return
	print("TASK_544: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_544 task file exists")
	_assert(_read_text(TASK_PATH).contains("Mission Fire And Cover Visual Polish Pass"), "TASK_544 task file names the task")
	_assert(_read_text(STATUS_PATH).contains("TASK_544 - Mission Fire And Cover Visual Polish Pass"), "Implementation status tracks TASK_544")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_544 - Mission Fire And Cover Visual Polish Pass (implementiert)"), "Roadmap marks TASK_544 implemented")
	_assert(_read_text(REPORT_PATH).contains("TASK_544 - Mission Fire And Cover Visual Polish Pass"), "Review workbench tracks TASK_544")
	_assert(_read_text(CONTRACT_PATH).contains("get_mission_fire_cover_visual_polish_snapshot"), "Mission command feedback contract documents TASK_544 snapshot")
	_assert(_read_text(CONTROLLER_PATH).contains("get_mission_fire_cover_visual_polish_snapshot"), "TacticalController exposes TASK_544 visual polish snapshot")
	_assert(_read_text(TERRAIN_VIEW_PATH).contains("target_focus_visible"), "TerrainMap3DView exposes target-focus fire VFX metadata")


func _test_fire_cover_visual_polish_render_snapshot() -> void:
	root.size = Vector2i(1280, 720)
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task544_visual_map", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	var friendly := DummyUnit.new("task544_alpha", "ft1", "team_alpha", Vector2(160.0, 160.0), "rifle")
	var enemy := DummyUnit.new("task544_enemy", "enemy", "team_enemy", Vector2(352.0, 160.0), "rifle")
	friendly.contact_active = true
	enemy.contact_active = true
	root.add_child(friendly)
	root.add_child(enemy)
	primary_view.call("set_unit_nodes", [friendly, enemy])
	await _wait_frames(8)
	primary_view.call(
		"set_order_visual_payload",
		{
			"selected_fireteam_ids": PackedStringArray(["ft1"]),
			"fire_event_dicts": [
				{
					"event_id": "task544_fire",
					"event_type": "weapon_fire",
					"attacker_unit_id": "task544_alpha",
					"target_unit_id": "task544_enemy",
					"attacker_team_id": "team_alpha",
					"weapon_id": "rifle",
					"attacker_position": friendly.global_position,
					"target_position": enemy.global_position,
					"combat_outcome": "hit",
					"damage_resolved": 18,
					"hit_chance_resolved": 0.72,
					"source": "task544_visual_test",
				},
			],
		}
	)
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var vfx_entry: Dictionary = _find_entry(Array(snapshot.get("weapon_fire_vfx_entries", [])), "event_id", "task544_fire")
	_assert(int(snapshot.get("weapon_fire_vfx_visual_count", 0)) == 1, "Primary3D renders one fire VFX entry")
	_assert(bool(vfx_entry.get("trace_visible", false)) and float(vfx_entry.get("trace_width", 0.0)) <= 0.035, "Fire trace stays visible and performance-friendly")
	_assert(not String(vfx_entry.get("trace_color_hex", "")).strip_edges().is_empty(), "Fire trace stores a color hex for visual audits")
	_assert(bool(vfx_entry.get("target_focus_visible", false)) and float(vfx_entry.get("target_focus_radius", 0.0)) > float(vfx_entry.get("impact_radius", 0.0)), "Fire target focus marker is larger than base impact")
	_assert(bool(vfx_entry.get("fire_status_label_visible", false)) and String(vfx_entry.get("fire_status_label_text", "")) == "HIT", "Fire status label summarizes hit outcome")
	_assert(bool(vfx_entry.get("impact_cross_visible", false)) and not String(vfx_entry.get("impact_color_hex", "")).strip_edges().is_empty(), "Impact cross and impact color metadata remain available")
	var proxy_states: Dictionary = Dictionary(snapshot.get("unit_proxy_state_by_id", {}))
	var friendly_proxy: Dictionary = Dictionary(proxy_states.get("task544_alpha", {}))
	_assert(bool(friendly_proxy.get("unit_status_badge_visible", false)), "Friendly contact badge is visible")
	_assert(String(friendly_proxy.get("unit_status_badge_text", "")) == "CONTACT", "Friendly contact badge keeps compact contact text")
	_assert(String(friendly_proxy.get("unit_status_badge_style", "")) == "engagement", "Friendly badge exposes engagement style")
	_assert(not String(friendly_proxy.get("unit_status_badge_color_hex", "")).strip_edges().is_empty(), "Friendly badge exposes color hex")
	primary_view.queue_free()
	friendly.queue_free()
	enemy.queue_free()
	await _wait_frames(2)


func _find_entry(entries: Array, key: String, expected_value: String) -> Dictionary:
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get(key, "")) == expected_value:
			return entry
	return {}


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
