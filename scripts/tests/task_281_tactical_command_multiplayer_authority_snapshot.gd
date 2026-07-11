extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")


class MockAudioEventBus:
	extends Node

	var call_count: int = 0
	var event_ids: PackedStringArray = PackedStringArray()

	func emit_weapon_fire(_weapon_id: String, context: Dictionary = {}) -> Dictionary:
		call_count += 1
		var dedupe_key: String = String(context.get("dedupe_key", "")).strip_edges()
		if not dedupe_key.is_empty():
			event_ids.append(dedupe_key)
		return {
			"played": true,
			"dedupe_key": dedupe_key,
			"from_multiplayer_snapshot": bool(context.get("from_multiplayer_snapshot", false)),
		}


var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_281 Tactical Command Multiplayer Authority Snapshot ===")
	await _test_tactical_command_whitelist_and_rejects()
	await _test_snapshot_contract_normalizes_tactical_authority_state()
	await _test_simulation_root_mirrors_tactical_snapshot_without_client_truth()
	_test_docs_mark_task_implemented()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_tactical_command_whitelist_and_rejects() -> void:
	var context: Dictionary = _make_context("Task281Commands")
	var simulation_root: Node = context["simulation_root"]
	simulation_root.set("is_server_authoritative", true)
	simulation_root.call("set_peer_team", 2, "team_bravo")
	simulation_root.call("set_peer_role", 2, "commander")
	simulation_root.call("set_peer_fireteams", 2, ["red"])
	simulation_root.call("set_peer_team", 1, "team_alpha")
	simulation_root.call("set_peer_role", 1, "host")

	var intent_result: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", {
		"contract_category": "commander_intent",
		"command_id": "intent_red_take_lz",
		"verb": "take",
		"team_id": "team_bravo",
		"fireteam_id": "red",
		"target_position": Vector2(96.0, 32.0),
		"tempo": "rapid",
		"fire_rule": "return",
		"contact_response": "report",
	}, 2))
	_assert(bool(intent_result.get("accepted", false)), "CommanderIntent is whitelisted for the owning commander peer")
	_assert(String(intent_result.get("category", "")) == "commander_intent", "CommanderIntent validation reports its category")
	var foreign_intent_result: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", {
		"contract_category": "commander_intent",
		"command_id": "intent_blue_foreign",
		"verb": "move",
		"team_id": "team_bravo",
		"fireteam_id": "blue",
		"target_position": Vector2(128.0, 64.0),
	}, 2))
	_assert(String(foreign_intent_result.get("reason", "")) == "fireteam_not_assigned_to_peer", "CommanderIntent rejects a foreign Fireteam for the commander peer")

	var breakout_result: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", {
		"command_type": "breakout_confirm",
		"team_id": "team_bravo",
		"fireteam_id": "red",
		"breakout_id": "breakout:contact:red:plan_1:0",
	}, 2))
	_assert(bool(breakout_result.get("accepted", false)), "Breakout confirm is whitelisted with fireteam ownership")

	var air_result: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", {
		"command_type": "air_asset_guard_lz",
		"team_id": "team_bravo",
		"fireteam_id": "red",
		"lz_position": Vector2(120.0, 64.0),
	}, 2))
	_assert(bool(air_result.get("accepted", false)), "Air/LZ tactical command is whitelisted for the owning team")

	var role_rejected: Dictionary = Dictionary(simulation_root.call("validate_network_command_for_peer", {
		"command_type": "role_override",
		"target_peer_id": 2,
		"role_id": "fireteam",
	}, 2))
	var role_allowed: Dictionary = Dictionary(simulation_root.call("validate_network_command_for_peer", {
		"command_type": "role_override",
		"target_peer_id": 2,
		"role_id": "fireteam",
	}, 1))
	_assert(String(role_rejected.get("reason", "")) == "host_required", "Role override is rejected for non-host peers")
	_assert(bool(role_allowed.get("accepted", false)), "Role override is allowed for host authority")

	var state_rejected: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", {
		"command_type": "breakout_confirm",
		"team_id": "team_bravo",
		"fireteam_id": "red",
		"breakout_id": "breakout:contact:red:plan_1:0",
		"air_asset_status": {"state": "destroyed"},
	}, 2))
	var lz_rejected: Dictionary = Dictionary(simulation_root.call("validate_network_command_for_peer", {
		"command_type": "air_asset_guard_lz",
		"team_id": "team_bravo",
		"fireteam_id": "red",
		"lz_position": Vector2(120.0, 64.0),
		"source_context": "editor",
	}, 2))
	_assert(String(state_rejected.get("reason", "")).begins_with("state_mutation_key:air_asset_status"), "Client tactical state mutation is rejected")
	_assert(String(lz_rejected.get("reason", "")) == "lz_from_forbidden_source", "Editor/scenario LZ source is rejected for air commands")
	_assert(simulation_root.command_queue.size() == 3, "Only accepted tactical commands are queued on the authority")
	_cleanup_context(context)
	await process_frame


func _test_snapshot_contract_normalizes_tactical_authority_state() -> void:
	var contract = MULTIPLAYER_SNAPSHOT_CONTRACT_SCRIPT.new()
	var snapshot: Dictionary = Dictionary(contract.call("build_state_snapshot", _build_tactical_snapshot_payload()))
	_assert(Array(snapshot.get("commander_intents", [])).size() == 2, "Snapshot carries commander intents as read-only display data")
	_assert(String(Dictionary(Array(snapshot.get("commander_intents", []))[0]).get("command_id", "")) == "intent_a", "Commander intents are sorted deterministically")
	_assert(Array(snapshot.get("fireteam_plan_status", [])).size() == 1, "Snapshot carries fireteam plan status")
	var plan_status: Dictionary = Dictionary(Array(snapshot.get("fireteam_plan_status", []))[0])
	_assert(not plan_status.has("ftl_skill_factors") and not plan_status.has("metadata"), "Plan status strips private/raw skill and metadata payloads")
	_assert(Array(snapshot.get("communication_events", [])).size() == 1, "Communication events are deduplicated by event ID")
	_assert(Array(snapshot.get("tactical_rules", [])).size() == 1, "Tactical rules are mirrored as compact fireteam entries")
	_assert(Array(snapshot.get("breakout_states", [])).size() == 1, "Breakout states are deduplicated by breakout ID")
	var air_status: Dictionary = Dictionary(Array(snapshot.get("air_asset_status", []))[0])
	_assert(String(air_status.get("runtime_authority", "")) == "SimulationRoot" and not bool(air_status.get("ui_sets_gameplay_truth", true)), "AirAssetStatus remains SimulationRoot-authoritative")
	_assert(Array(air_status.get("vfx_events", [])).size() == 1 and Array(air_status.get("sfx_events", [])).size() == 1, "AirAsset VFX/SFX events are deduplicated")
	var metrics: Dictionary = Dictionary(contract.call("build_serialization_metrics", snapshot))
	_assert(int(metrics.get("json_bytes", 999999)) < 9000, "Tactical snapshot payload remains compact")
	_assert(Array(metrics.get("large_payload_offenders", [])).is_empty(), "Snapshot contains no raw asset/path payload offenders")
	var canonical_a: String = String(contract.call("build_canonical_payload_string", snapshot))
	var canonical_b: String = String(contract.call("build_canonical_payload_string", contract.call("build_state_snapshot", _build_tactical_snapshot_payload_reordered())))
	_assert(canonical_a == canonical_b, "Snapshot canonical payload is stable despite input ordering")


func _test_simulation_root_mirrors_tactical_snapshot_without_client_truth() -> void:
	var host_context: Dictionary = _make_context("Task281Host")
	var client_context: Dictionary = _make_context("Task281Client", true)
	var host: Node = host_context["simulation_root"]
	var client: Node = client_context["simulation_root"]
	host.set("tick_counter", 21)
	host.call("_apply_air_asset_status_update_effect", {
		"asset_id": "mission_dropship",
		"asset_type": "dropship",
		"state": "crashed",
		"event_id": "air_loss_1",
		"vfx_events": [{"event_id": "air_vfx_1", "event_type": "explosion"}],
		"sfx_events": [{"event_id": "air_sfx_1", "event_type": "explosion"}],
	})
	host.call("set_multiplayer_snapshot_context", _build_tactical_snapshot_payload())
	var snapshot: Dictionary = Dictionary(host.call("build_multiplayer_snapshot"))
	_assert(Array(snapshot.get("fire_events", [])).size() == 1, "Fire events are deduplicated before network apply")
	_assert(Array(snapshot.get("air_asset_status", [])).size() == 1, "SimulationRoot publishes authoritative AirAssetStatus")

	var apply_result: Dictionary = Dictionary(client.call("apply_multiplayer_snapshot", snapshot))
	var last_state: Dictionary = Dictionary(client.call("get_last_server_state"))
	var audio_debug: Dictionary = Dictionary(client.call("get_snapshot_audio_debug_snapshot"))
	var audio_bus: MockAudioEventBus = client_context["audio_bus"]
	_assert(bool(apply_result.get("accepted", false)), "Client accepts tactical authority snapshot")
	_assert(client.command_queue.is_empty() and client.effects_queue.is_empty(), "Applying tactical snapshot enqueues no client commands or effects")
	_assert(Array(last_state.get("breakout_states", [])).size() == 1, "Client mirrors BreakoutState as server state")
	_assert(Array(last_state.get("air_asset_status", [])).size() == 1, "Client mirrors AirAssetStatus as server state")
	_assert(audio_bus.call_count == 1 and int(audio_debug.get("played_count", 0)) == 1, "Snapshot fire SFX/VFX are emitted once through event IDs")
	_cleanup_context(host_context)
	_cleanup_context(client_context)
	await process_frame


func _test_docs_mark_task_implemented() -> void:
	var task_text: String = FileAccess.get_file_as_string("res://docs/tasks/TASK_281_tactical_command_multiplayer_authority_snapshot.md")
	var status_text: String = FileAccess.get_file_as_string("res://docs/IMPLEMENTATION_STATUS.md")
	var roadmap_text: String = FileAccess.get_file_as_string("res://docs/TASK_ROADMAP.md")
	var dev_text: String = FileAccess.get_file_as_string("res://docs/dev/tactical_multiplayer_authority_snapshot.md")
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "Task file marks TASK_281 implemented")
	_assert(not task_text.contains("- [ ]"), "Task checklist is complete")
	_assert(status_text.contains("### TASK_281 - Tactical Command Multiplayer Authority Snapshot") and status_text.contains("- Status: implementiert"), "Implementation status has implemented TASK_281 section")
	_assert(roadmap_text.contains("TASK_281 - Tactical Command Multiplayer Authority Snapshot (implementiert)"), "Roadmap marks TASK_281 implemented")
	_assert(dev_text.contains("SimulationRoot") and dev_text.contains("ui_sets_gameplay_truth = false"), "Dev contract documents authority boundary")


func _build_tactical_snapshot_payload() -> Dictionary:
	return {
		"tick": 21,
		"commander_intents": [
			{"command_id": "intent_b", "verb": "defend", "team_id": "team_bravo", "fireteam_id": "red", "target_area_id": "lz_risky"},
			{"command_id": "intent_a", "verb": "take", "team_id": "team_bravo", "fireteam_id": "red", "target_position": Vector2(96.0, 32.0), "metadata": {"private_note": "strip"}},
		],
		"fireteam_plan_status": [
			{
				"plan_id": "plan_red_1",
				"command_id": "intent_a",
				"fireteam_id": "red",
				"team_id": "team_bravo",
				"phase": 1,
				"ftl_response": "copy",
				"movement_style": "bounding",
				"security_mode": "sector",
				"planning_quality": 0.72,
				"communication_clarity": 0.81,
				"breakout_judgement": 0.63,
				"allowed_breakout_classes": ["auto_adapt", "hold_and_report"],
				"ftl_skill_factors": {"leadership": 0.9},
				"metadata": {"private_character_sheet": true},
			},
		],
		"communication_events": [
			{"event_id": "comm_1", "event_type": "contact_report", "fireteam_id": "red", "team_id": "team_bravo", "channels": ["map_marker", "map_marker"], "metadata": {"raw": "strip"}},
			{"event_id": "comm_1", "event_type": "contact_report", "fireteam_id": "red", "team_id": "team_bravo", "channels": ["map_marker"]},
		],
		"tactical_rules": {
			"red": {"tempo": "rapid", "fire_rule": "return", "contact_response": "report", "cover_priority": "normal", "security_mode": "sector", "warnings": ["ok", "ok"]},
		},
		"breakout_states": [
			{"breakout_id": "breakout:contact:red:plan_red_1:0", "event_id": "comm_1", "plan_id": "plan_red_1", "command_id": "intent_a", "fireteam_id": "red", "trigger": "contact", "breakout_class": "hold_and_report", "status": "holding", "player_options": ["confirm", "abort", "confirm"]},
			{"breakout_id": "breakout:contact:red:plan_red_1:0", "event_id": "comm_1", "plan_id": "plan_red_1", "command_id": "intent_a", "fireteam_id": "red", "trigger": "contact", "breakout_class": "hold_and_report", "status": "holding"},
		],
		"air_asset_status": [
			{
				"asset_id": "mission_dropship",
				"asset_type": "dropship",
				"state": "crashed",
				"integrity": 0,
				"max_integrity": 100,
				"last_event_id": "air_loss_1",
				"vfx_events": [{"event_id": "air_vfx_1", "event_type": "explosion"}, {"event_id": "air_vfx_1", "event_type": "explosion"}],
				"sfx_events": [{"event_id": "air_sfx_1", "event_type": "explosion"}, {"event_id": "air_sfx_1", "event_type": "explosion"}],
			},
		],
		"fire_events": [
			{"event_id": "fire_1", "event_type": "weapon_fire", "attacker_unit_id": "red_1", "attacker_team_id": "team_bravo", "target_unit_id": "blue_1", "weapon_id": "rifle", "muzzle_position": Vector2(10.0, 8.0)},
			{"event_id": "fire_1", "event_type": "weapon_fire", "attacker_unit_id": "red_1", "attacker_team_id": "team_bravo", "target_unit_id": "blue_1", "weapon_id": "rifle", "muzzle_position": Vector2(10.0, 8.0)},
		],
	}


func _build_tactical_snapshot_payload_reordered() -> Dictionary:
	var payload: Dictionary = _build_tactical_snapshot_payload()
	payload["commander_intents"] = Array(payload.get("commander_intents", [])).duplicate(true)
	payload["commander_intents"].reverse()
	payload["communication_events"] = Array(payload.get("communication_events", [])).duplicate(true)
	payload["communication_events"].reverse()
	payload["breakout_states"] = Array(payload.get("breakout_states", [])).duplicate(true)
	payload["breakout_states"].reverse()
	payload["fire_events"] = Array(payload.get("fire_events", [])).duplicate(true)
	payload["fire_events"].reverse()
	return payload


func _make_context(name: String, with_audio_bus: bool = false) -> Dictionary:
	var root := Node.new()
	root.name = name
	get_root().add_child(root)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	root.add_child(unit_registry)
	var audio_bus: MockAudioEventBus = null
	if with_audio_bus:
		audio_bus = MockAudioEventBus.new()
		audio_bus.name = "AudioEventBus"
		root.add_child(audio_bus)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	if with_audio_bus:
		simulation_root.audio_event_bus_path = NodePath("../AudioEventBus")
	root.add_child(simulation_root)
	return {
		"root": root,
		"unit_registry": unit_registry,
		"simulation_root": simulation_root,
		"audio_bus": audio_bus,
	}


func _cleanup_context(context: Dictionary) -> void:
	var root: Node = context.get("root", null)
	if root != null:
		root.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
