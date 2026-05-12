extends SceneTree

const AUDIO_EVENT_BUS_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_bus.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MISSION_COMBAT_LOOP_DRIVER_SCRIPT: GDScript = preload("res://scripts/mission/mission_combat_loop_driver.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const MULTIPLAYER_LOBBY_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_244 Combat Movement UI SFX Integration Verifier ===")
	await _test_audio_event_bus_integration_api()
	await _test_main_menu_ui_sfx_hooks()
	await _test_multiplayer_lobby_ui_sfx_hooks()
	await _test_terrain_fire_and_movement_sfx_hooks()
	await _test_combat_impact_and_explosion_sfx_hooks()
	await _test_snapshot_audio_dedupe_and_visibility()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_audio_event_bus_integration_api() -> void:
	var bus = AUDIO_EVENT_BUS_SCRIPT.new()
	root.add_child(bus)
	await process_frame
	var ui_result: Dictionary = bus.call("emit_ui_action", "confirm", {"now_msec": 1000})
	_assert(bool(ui_result.get("played", false)) and String(ui_result.get("event_id", "")) == "ui_confirm", "UI action helper maps confirm to UI audio")
	bus.call("stop_all_for_tests")
	var smg_result: Dictionary = bus.call("emit_weapon_fire", "smg", {"position": Vector3(1.0, 0.0, 1.0), "now_msec": 2000})
	var sniper_result: Dictionary = bus.call("emit_weapon_fire", "sniper", {"position": Vector3(2.0, 0.0, 1.0), "now_msec": 2100})
	var rocket_result: Dictionary = bus.call("emit_weapon_fire", "rocket_launcher", {"position": Vector3(3.0, 0.0, 1.0), "now_msec": 2200})
	_assert(String(smg_result.get("event_id", "")) == "combat_smg_burst", "SMG maps to burst combat event")
	_assert(String(sniper_result.get("event_id", "")) == "combat_sniper_shot", "Sniper maps to sniper combat event")
	_assert(String(rocket_result.get("event_id", "")) == "combat_heavy_weapon", "Rocket launcher maps to heavy combat event")
	bus.call("stop_all_for_tests")
	var first_dedupe: Dictionary = bus.call("emit_weapon_fire", "rifle", {"dedupe_key": "fire_a", "cooldown_msec": 0, "now_msec": 3000})
	var second_dedupe: Dictionary = bus.call("emit_weapon_fire", "rifle", {"dedupe_key": "fire_a", "cooldown_msec": 0, "now_msec": 3001})
	_assert(bool(first_dedupe.get("played", false)), "Dedupe probe plays first event")
	_assert(not bool(second_dedupe.get("played", true)) and String(second_dedupe.get("reason", "")).contains("dedupe"), "Audio bus dedupes matching action events")
	bus.call("stop_all_for_tests")
	var step_result: Dictionary = bus.call("emit_movement_step", "sand", {"position": Vector3.ZERO, "now_msec": 4000})
	var impact_result: Dictionary = bus.call("emit_impact", "metal_heavy", {"position": Vector3.ZERO, "now_msec": 5000})
	var explosion_result: Dictionary = bus.call("emit_explosion", "large", {"position": Vector3.ZERO, "now_msec": 6000})
	_assert(String(step_result.get("event_id", "")) == "movement_footstep_sand_soft", "Surface helper maps sand movement")
	_assert(String(impact_result.get("event_id", "")) == "impact_metal_heavy", "Impact helper maps heavy metal impact")
	_assert(String(explosion_result.get("event_id", "")) == "explosion_large", "Explosion helper maps large explosion")
	bus.call("stop_all_for_tests")
	bus.call("apply_settings", {"master_volume": 80.0, "sfx_volume": 80.0, "combat_audio_enabled": false})
	var muted_combat: Dictionary = bus.call("emit_weapon_fire", "rifle", {"now_msec": 7000})
	_assert(not bool(muted_combat.get("played", true)) and String(muted_combat.get("reason", "")).contains("settings"), "Combat audio respects settings mute")
	bus.call("shutdown_for_tests")
	root.remove_child(bus)
	bus.free()
	await process_frame


func _test_main_menu_ui_sfx_hooks() -> void:
	var packed_scene := ResourceLoader.load(MAIN_MENU_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Main menu scene loads for UI SFX integration")
	if packed_scene == null:
		return
	var main_menu := packed_scene.instantiate()
	root.add_child(main_menu)
	await process_frame
	main_menu.call("set_settings_path_for_tests", "user://task_244_main_menu_settings.cfg")
	main_menu.call("set_start_roster_store_path_for_tests", "user://task_244_roster.json", "task_244_roster", true)
	main_menu.call("open_settings_panel")
	await process_frame
	var after_open: Dictionary = Dictionary(main_menu.call("get_audio_sfx_debug_snapshot"))
	var open_count: int = int(after_open.get("played_count", 0))
	_assert(open_count >= 1, "Opening settings emits a UI SFX event")
	main_menu.call("set_draft_audio_settings", 45.0, 35.0, 25.0)
	await process_frame
	var after_draft: Dictionary = Dictionary(main_menu.call("get_audio_sfx_debug_snapshot"))
	_assert(int(after_draft.get("played_count", 0)) == open_count, "Draft audio slider API does not spam SFX")
	_assert(int(main_menu.call("apply_settings")) == OK, "Main menu applies settings in UI SFX verifier")
	await process_frame
	var after_apply: Dictionary = Dictionary(main_menu.call("get_audio_sfx_debug_snapshot"))
	var category_counts: Dictionary = Dictionary(after_apply.get("played_count_by_category", {}))
	_assert(int(category_counts.get("ui", 0)) >= 2, "Main menu apply emits confirm UI SFX")
	main_menu.queue_free()
	await process_frame


func _test_multiplayer_lobby_ui_sfx_hooks() -> void:
	var packed_scene := ResourceLoader.load(MULTIPLAYER_LOBBY_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Multiplayer lobby scene loads for UI SFX integration")
	if packed_scene == null:
		return
	var lobby := packed_scene.instantiate()
	root.add_child(lobby)
	await process_frame
	lobby.call("configure_host_state_for_test", [1, 2])
	await process_frame
	lobby.call("set_roster_mode", "shared")
	lobby.call("set_ready", true)
	lobby.call("set_peer_ready_for_test", 1, true)
	lobby.call("set_peer_ready_for_test", 2, true)
	var started: bool = bool(lobby.call("start_mission"))
	await process_frame
	var snapshot: Dictionary = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	var audio_snapshot: Dictionary = Dictionary(snapshot.get("audio_sfx", {}))
	var category_counts: Dictionary = Dictionary(audio_snapshot.get("played_count_by_category", {}))
	_assert(started, "Lobby can start mission in UI SFX verifier after ready state")
	_assert(int(category_counts.get("ui", 0)) >= 2, "Lobby host/ready/start actions emit UI SFX")
	lobby.queue_free()
	await process_frame


func _test_terrain_fire_and_movement_sfx_hooks() -> void:
	var view = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	await process_frame
	view.call("set_order_visual_payload", {
		"fire_event_dicts": [
			{
				"event_id": "fire_visible_244",
				"event_type": "weapon_fire",
				"attacker_unit_id": "blue_a",
				"attacker_team_id": "team_alpha",
				"target_unit_id": "red_a",
				"target_team_id": "team_bravo",
				"weapon_id": "rifle",
				"attacker_position": Vector2(0.0, 0.0),
				"target_position": Vector2(96.0, 0.0),
			}
		]
	})
	await process_frame
	var render_snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	_assert(int(render_snapshot.get("weapon_fire_vfx_visual_count", 0)) >= 1, "Visible fire event creates muzzle flash VFX")
	_assert(int(render_snapshot.get("weapon_fire_sfx_count", 0)) >= 1, "Visible muzzle flash emits weapon fire SFX")
	var step_played: Dictionary = Dictionary(view.call("emit_movement_step_sfx_for_tests", "unit_step_244", "sand", true, true, 10000))
	var step_limited: Dictionary = Dictionary(view.call("emit_movement_step_sfx_for_tests", "unit_step_244", "sand", true, true, 10050))
	var step_hidden: Dictionary = Dictionary(view.call("emit_movement_step_sfx_for_tests", "unit_hidden_244", "rock", false, true, 11000))
	_assert(bool(step_played.get("played", false)), "Visible moving unit emits movement step SFX")
	_assert(not bool(step_limited.get("played", true)) and String(step_limited.get("reason", "")).contains("rate_limited"), "Movement steps are per-unit rate limited")
	_assert(not bool(step_hidden.get("played", true)) and String(step_hidden.get("reason", "")) == "hidden_unit", "Hidden units do not emit movement step SFX")
	view.queue_free()
	await process_frame


func _test_combat_impact_and_explosion_sfx_hooks() -> void:
	var simulation = SIMULATION_ROOT_SCRIPT.new()
	simulation.name = "SimulationRootForAudioTest"
	var driver = MISSION_COMBAT_LOOP_DRIVER_SCRIPT.new()
	driver.simulation_root_path = NodePath("../SimulationRootForAudioTest")
	root.add_child(simulation)
	root.add_child(driver)
	await process_frame
	var impact_result: Dictionary = Dictionary(driver.call("emit_impact_sfx_for_tests", {
		"weapon_id": "rocket_launcher",
		"unit_id": "red_rocket_target",
		"fire_event_id": "rocket_hit_244",
		"attacker_team_id": "team_alpha",
	}, null))
	var audio_snapshot: Dictionary = Dictionary(driver.call("get_audio_sfx_debug_snapshot"))
	var event_counts: Dictionary = Dictionary(audio_snapshot.get("played_count_by_event", {}))
	_assert(bool(impact_result.get("played", false)) and String(impact_result.get("event_id", "")) == "impact_metal_heavy", "Rocket damage emits heavy impact SFX")
	_assert(int(event_counts.get("explosion_large", 0)) >= 1, "Rocket damage emits large explosion SFX")
	driver.queue_free()
	simulation.queue_free()
	await process_frame


func _test_snapshot_audio_dedupe_and_visibility() -> void:
	var simulation = SIMULATION_ROOT_SCRIPT.new()
	var bus = AUDIO_EVENT_BUS_SCRIPT.new()
	bus.name = "AudioEventBus"
	simulation.add_child(bus)
	root.add_child(simulation)
	await process_frame
	var visible_snapshot: Dictionary = _build_snapshot(1, "snap_fire_244", true)
	var first_apply: Dictionary = Dictionary(simulation.call("apply_multiplayer_snapshot", visible_snapshot))
	var repeated_snapshot: Dictionary = _build_snapshot(2, "snap_fire_244", true)
	var second_apply: Dictionary = Dictionary(simulation.call("apply_multiplayer_snapshot", repeated_snapshot))
	var hidden_snapshot: Dictionary = _build_snapshot(3, "snap_fire_hidden_244", false)
	var hidden_apply: Dictionary = Dictionary(simulation.call("apply_multiplayer_snapshot", hidden_snapshot))
	var sim_audio: Dictionary = Dictionary(simulation.call("get_snapshot_audio_debug_snapshot"))
	var bus_audio: Dictionary = Dictionary(bus.call("get_diagnostic_snapshot"))
	_assert(bool(first_apply.get("accepted", false)) and bool(second_apply.get("accepted", false)) and bool(hidden_apply.get("accepted", false)), "Snapshot audio verifier snapshots are accepted")
	_assert(int(sim_audio.get("played_count", 0)) == 1, "Snapshot audio plays first visible fire event once")
	_assert(int(bus_audio.get("suppressed_dedupe_count", 0)) >= 1, "Snapshot audio dedupes repeated authoritative fire event")
	_assert(int(bus_audio.get("suppressed_visibility_count", 0)) >= 1, "Snapshot audio suppresses hidden FoW fire event")
	bus.call("shutdown_for_tests")
	simulation.queue_free()
	await process_frame


func _build_snapshot(tick: int, event_id: String, visible_to_local: bool) -> Dictionary:
	return {
		"schema_version": 1,
		"snapshot_type": "state",
		"tick": tick,
		"units": [],
		"objective": {},
		"fire_events": [
			{
				"event_id": event_id,
				"event_type": "weapon_fire",
				"attacker_unit_id": "red_snapshot",
				"attacker_team_id": "team_bravo",
				"target_unit_id": "blue_snapshot",
				"target_team_id": "team_alpha",
				"weapon_id": "smg",
				"attacker_position": Vector2(8.0, 8.0),
				"target_position": Vector2(80.0, 8.0),
				"visible_to_local": visible_to_local,
				"visibility_context": "snapshot_visible" if visible_to_local else "fog_hidden",
			}
		],
	}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
