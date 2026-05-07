extends SceneTree

const AUDIO_EVENT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_contract.gd")
const AUDIO_EVENT_BUS_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_bus.gd")
const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const DOC_PATH: String = "res://docs/dev/audio_event_contract.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_243 Audio Event Contract and Bus Setup Verifier ===")
	var contract = AUDIO_EVENT_CONTRACT_SCRIPT.new()
	contract.load_catalog()
	_test_contract_loads_catalog(contract)
	_test_settings_contract_audio_extensions()
	await _test_audio_event_bus_runtime(contract)
	_test_contract_documentation()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_contract_loads_catalog(contract) -> void:
	var snapshot: Dictionary = contract.build_contract_snapshot()
	_assert(bool(snapshot.get("loaded", false)), "Audio event contract loads the curated SFX catalog")
	_assert(int(snapshot.get("entry_count", 0)) >= 25, "Audio event contract exposes curated entries")
	var coverage: Dictionary = Dictionary(snapshot.get("required_event_coverage", {}))
	for event_id in ["ui_click", "combat_blaster", "movement_footstep_neutral", "impact_generic_light", "explosion_small"]:
		_assert(bool(coverage.get(event_id, false)), "Contract covers stable event %s" % event_id)
	var ui_entry: Dictionary = contract.get_entry("ui_click_soft_01")
	var combat_entry: Dictionary = contract.get_entry("combat_blaster_small_01")
	var step_entry: Dictionary = contract.get_entry("movement_step_neutral_01")
	_assert(String(ui_entry.get("bus_name", "")) == "UI" and not bool(ui_entry.get("spatial", true)), "UI entries route to UI bus as non-spatial one-shots")
	_assert(String(combat_entry.get("bus_name", "")) == "Combat" and bool(combat_entry.get("spatial", false)), "Combat entries route to Combat bus as spatial events")
	_assert(String(step_entry.get("bus_name", "")) == "Movement" and bool(step_entry.get("spatial", false)), "Movement entries route to Movement bus as spatial events")
	_assert(Array(snapshot.get("missing_resource_ids", [])).is_empty(), "Contract sees no missing imported audio resources")
	_assert(not bool(snapshot.get("audio_sets_gameplay_state", true)), "Contract states that audio never sets gameplay state")


func _test_settings_contract_audio_extensions() -> void:
	var settings: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("normalize_settings", {
		"master_volume": 55.0,
		"sfx_volume": 33.0,
		"ui_volume": 66.0,
		"combat_volume": 44.0,
		"movement_volume": 22.0,
		"ambient_volume": 11.0,
	}))
	_assert(is_equal_approx(float(settings.get("ui_volume", 0.0)), 66.0), "Settings contract normalizes UI audio volume")
	_assert(is_equal_approx(float(settings.get("combat_volume", 0.0)), 44.0), "Settings contract normalizes combat audio volume")
	_assert(is_equal_approx(float(settings.get("movement_volume", 0.0)), 22.0), "Settings contract normalizes movement audio volume")
	var snapshot: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("build_snapshot", settings))
	var audio_snapshot: Dictionary = Dictionary(snapshot.get("audio", {}))
	_assert(audio_snapshot.has("ui_volume") and audio_snapshot.has("combat_volume") and audio_snapshot.has("movement_volume"), "Settings snapshot exposes category audio volumes")


func _test_audio_event_bus_runtime(_contract) -> void:
	var bus = AUDIO_EVENT_BUS_SCRIPT.new()
	root.add_child(bus)
	await process_frame
	bus.player_pool.configure(4, 2)
	bus.apply_settings({
		"master_volume": 80.0,
		"sfx_volume": 70.0,
		"ui_volume": 60.0,
		"combat_volume": 50.0,
		"movement_volume": 40.0,
		"ambient_volume": 30.0,
	})
	var diagnostic: Dictionary = bus.get_diagnostic_snapshot()
	var buses: Dictionary = Dictionary(diagnostic.get("buses", {}))
	for bus_name in ["Master", "SFX", "UI", "Combat", "Movement", "Ambient"]:
		_assert(bool(Dictionary(buses.get(bus_name, {})).get("exists", false)), "Audio bus exists: %s" % bus_name)
	_assert(String(Dictionary(buses.get("UI", {})).get("send", "")) == "SFX", "UI bus routes into SFX")
	_assert(String(Dictionary(buses.get("Combat", {})).get("send", "")) == "SFX", "Combat bus routes into SFX")
	_assert(String(Dictionary(buses.get("Movement", {})).get("send", "")) == "SFX", "Movement bus routes into SFX")

	var ui_result: Dictionary = bus.emit_audio_event("ui_click", {"now_msec": 1000})
	_assert(bool(ui_result.get("played", false)), "Audio bus plays a UI event through the catalog")
	_assert(String(ui_result.get("bus_name", "")) == "UI", "UI event reports UI bus routing")
	var cooldown_result: Dictionary = bus.emit_audio_event("ui_click", {"now_msec": 1005})
	_assert(not bool(cooldown_result.get("played", true)) and String(cooldown_result.get("reason", "")).contains("cooldown"), "Audio bus suppresses event cooldown spam")

	var combat_result: Dictionary = bus.emit_audio_event("combat_blaster", {"position": Vector3(1.0, 0.0, 2.0), "now_msec": 2000})
	_assert(bool(combat_result.get("played", false)) and bool(combat_result.get("spatial", false)), "Audio bus plays spatial combat events")
	_assert(String(combat_result.get("bus_name", "")) == "Combat", "Combat event reports Combat bus routing")

	bus.stop_all_for_tests()
	var first_explosion: Dictionary = bus.emit_audio_event("explosion_large", {"cooldown_msec": 0, "polyphony_limit": 1, "now_msec": 3000})
	var blocked_explosion: Dictionary = bus.emit_audio_event("explosion_large", {"cooldown_msec": 0, "polyphony_limit": 1, "now_msec": 3001})
	_assert(bool(first_explosion.get("played", false)), "Audio bus plays first bounded-polyphony event")
	_assert(not bool(blocked_explosion.get("played", true)) and String(blocked_explosion.get("reason", "")).contains("polyphony"), "Audio bus suppresses over-polyphony")

	var missing_result: Dictionary = bus.emit_audio_event("missing_audio_contract_probe", {"now_msec": 4000})
	_assert(not bool(missing_result.get("played", true)) and String(missing_result.get("reason", "")) == "missing_audio_id", "Audio bus reports missing IDs without aborting")

	bus.stop_all_for_tests()
	bus.apply_settings({"master_volume": 80.0, "sfx_volume": 80.0, "ui_audio_enabled": false})
	var muted_ui_result: Dictionary = bus.emit_audio_event("ui_hover", {"now_msec": 5000})
	_assert(not bool(muted_ui_result.get("played", true)) and String(muted_ui_result.get("reason", "")).contains("settings"), "Audio bus respects UI audio settings")

	bus.apply_settings({"master_volume": 80.0, "sfx_volume": 80.0})
	var hidden_snapshot_result: Dictionary = bus.emit_multiplayer_snapshot_audio_event({
		"event_id": "combat_blaster",
		"visible_to_local": false,
		"unit_id": "enemy_delta",
		"team_id": "team_enemy",
		"now_msec": 6000,
	})
	_assert(not bool(hidden_snapshot_result.get("played", true)) and String(hidden_snapshot_result.get("reason", "")).contains("visibility"), "Snapshot audio respects local visibility")
	_assert(bool(hidden_snapshot_result.get("from_multiplayer_snapshot", false)), "Snapshot audio result carries multiplayer source")
	_assert(not bool(hidden_snapshot_result.get("mutates_simulation_state", true)), "Snapshot audio result does not mutate simulation state")

	diagnostic = bus.get_diagnostic_snapshot()
	var pool_snapshot: Dictionary = Dictionary(diagnostic.get("pool", {}))
	_assert(bool(pool_snapshot.get("bounded_pool", false)), "Audio player pool is bounded")
	_assert(int(diagnostic.get("missing_id_count", 0)) >= 1, "Diagnostics count missing IDs")
	_assert(int(diagnostic.get("suppressed_cooldown_count", 0)) >= 1, "Diagnostics count cooldown suppression")
	_assert(int(diagnostic.get("suppressed_polyphony_count", 0)) >= 1, "Diagnostics count polyphony suppression")
	_assert(int(diagnostic.get("suppressed_settings_count", 0)) >= 1, "Diagnostics count settings suppression")
	_assert(int(diagnostic.get("suppressed_visibility_count", 0)) >= 1, "Diagnostics count visibility suppression")
	_assert(root.find_child("SimulationRoot", true, false) == null, "Audio verifier does not create gameplay SimulationRoot state")
	bus.call("shutdown_for_tests")
	root.remove_child(bus)
	bus.free()
	await process_frame


func _test_contract_documentation() -> void:
	var text: String = _read_text(DOC_PATH)
	_assert(text.contains("Audio ist eine lokale Darstellungsschicht"), "Audio contract documentation states local presentation boundary")
	_assert(text.contains("UI`, `Combat`, `Movement`, `Ambient -> SFX"), "Audio contract documentation states bus routing")
	_assert(text.contains("visible_to_local"), "Audio contract documentation covers multiplayer visibility")
	_assert(text.contains("Fehlende IDs"), "Audio contract documentation covers diagnostics")


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
