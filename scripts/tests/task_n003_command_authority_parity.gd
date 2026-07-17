extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")

const COMMANDER_ORDER_INTENT_PATH: String = "res://scripts/mission/commander_order_intent.gd"
const COMMAND_SUBMISSION_RESULT_PATH: String = "res://scripts/mission/command_submission_result.gd"
const MISSION_COMMAND_ENTRY_ADAPTER_PATH: String = "res://scripts/mission/mission_command_entry_adapter.gd"
const FIRETEAM_COMMAND_GATEWAY_PATH: String = "res://scripts/tactical/fireteam_command_gateway.gd"
const TACTICAL_CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const ENET_PORT_START: int = 19920
const ENET_PORT_END: int = 19930

var _passed: int = 0
var _failed: int = 0


class UnitStub:
	extends Node2D

	var unit_id: String = ""
	var team_id: String = "team_alpha"
	var current_command: Dictionary = {}

	func get_unit_id() -> String:
		return unit_id

	func get_team_id() -> String:
		return team_id

	func get_current_unit_command() -> Dictionary:
		return current_command.duplicate(true)

	func assign_unit_command(command) -> void:
		if command != null and command.has_method("to_dict"):
			current_command = Dictionary(command.call("to_dict")).duplicate(true)
		elif typeof(command) == TYPE_DICTIONARY:
			current_command = Dictionary(command).duplicate(true)

	func get_speed_skill() -> float:
		return 0.5

	func get_accuracy_skill() -> float:
		return 0.5

	func get_trait_ids() -> PackedStringArray:
		return PackedStringArray()

	func refresh_terrain_readability() -> void:
		pass


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_N003 Command Authority and Parity ===")
	_test_movement_command_does_not_mutate_unit_before_authoritative_tick()
	_test_command_authority_contract_modules_exist()
	_test_commander_order_intent_normalizes_visible_command_input()
	_test_submission_result_distinguishes_pending_commit_from_rejection()
	_test_adapter_normalizes_button_hotkey_and_rmb_into_plans()
	_test_go_submits_only_to_simulationroot_and_commits_on_tick()
	_test_move_defend_flank_take_share_the_plan_then_go_contract()
	_test_rmb_area_order_payload_uses_the_same_plan_and_go_contract()
	_test_rejected_and_stale_go_leave_authority_state_unchanged()
	_test_gateway_recreation_uses_authority_revision_floor()
	await _test_real_client_rpc_resolves_pending_and_keeps_peer_namespaces_distinct()
	_test_visible_controller_routes_only_through_n003_plan_and_go()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_movement_command_does_not_mutate_unit_before_authoritative_tick() -> void:
	var context: Dictionary = _make_context()
	var unit: UnitStub = context["unit"]
	var simulation_root: Node = context["simulation_root"]
	var movement_controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()
	var result: Dictionary = Dictionary(movement_controller.call(
		"start_execution",
		"blue",
		"move",
		0,
		Vector2(64.0, 0.0),
		null,
		[unit],
		unit,
		simulation_root,
		null
	))
	_assert(bool(result.get("started", false)), "Movement creates an authoritative runtime command")
	_assert(unit.get_current_unit_command().is_empty(), "Movement leaves UnitCommand unchanged before SimulationRoot ticks")
	_assert(not Array(simulation_root.command_queue).is_empty(), "Movement queues the runtime command for SimulationRoot")
	simulation_root.call("_physics_process", 0.1)
	_assert(not unit.get_current_unit_command().is_empty(), "SimulationRoot applies UnitCommand during the authoritative tick")
	_cleanup_context(context)


func _test_command_authority_contract_modules_exist() -> void:
	for script_path in [
		COMMANDER_ORDER_INTENT_PATH,
		COMMAND_SUBMISSION_RESULT_PATH,
		MISSION_COMMAND_ENTRY_ADAPTER_PATH,
		FIRETEAM_COMMAND_GATEWAY_PATH,
	]:
		_assert(ResourceLoader.exists(script_path), "%s exists as a productive N003 module" % script_path.get_file())


func _test_commander_order_intent_normalizes_visible_command_input() -> void:
	var script_ref: GDScript = load(COMMANDER_ORDER_INTENT_PATH)
	_assert(script_ref.has_method("from_dict"), "CommanderOrderIntent exposes a normalized construction boundary")
	if not script_ref.has_method("from_dict"):
		return
	var intent = script_ref.call("from_dict", {
		"command_type": " MOVE ",
		"selected_fireteam_ids": ["Blue", "gold", "blue", ""],
		"target_position": Vector2(96.0, 64.0),
		"phase": 2,
		"source_peer_id": 7,
		"entry_source": "hotkey",
		"plan_id": "n003_plan_hotkey",
		"team_id": "team_alpha",
	})
	_assert(intent != null and intent.has_method("is_valid") and bool(intent.call("is_valid")), "CommanderOrderIntent accepts a valid visible command plan")
	if intent == null or not intent.has_method("to_dict"):
		return
	var intent_dict: Dictionary = Dictionary(intent.call("to_dict"))
	_assert(String(intent_dict.get("command_type", "")) == "move", "CommanderOrderIntent normalizes command type")
	_assert(PackedStringArray(intent_dict.get("selected_fireteam_ids", PackedStringArray())) == PackedStringArray(["blue", "gold"]), "CommanderOrderIntent keeps a stable unique Fireteam selection")
	_assert(int(intent_dict.get("phase", -1)) == 2 and int(intent_dict.get("source_peer_id", -1)) == 7, "CommanderOrderIntent keeps phase and requesting peer")


func _test_submission_result_distinguishes_pending_commit_from_rejection() -> void:
	var script_ref: GDScript = load(COMMAND_SUBMISSION_RESULT_PATH)
	_assert(script_ref.has_method("accepted_pending"), "CommandSubmissionResult exposes accepted-pending construction")
	if not script_ref.has_method("accepted_pending"):
		return
	var pending = script_ref.call("accepted_pending", "n003_plan_go", "n003_token_blue")
	_assert(pending != null and pending.has_method("to_dict"), "CommandSubmissionResult is serializable")
	if pending == null or not pending.has_method("to_dict"):
		return
	var pending_dict: Dictionary = Dictionary(pending.call("to_dict"))
	_assert(bool(pending_dict.get("accepted", false)) and bool(pending_dict.get("pending", false)) and not bool(pending_dict.get("committed", true)), "Accepted GO remains pending until SimulationRoot commits it")
	_assert(script_ref.has_method("rejected"), "CommandSubmissionResult exposes rejection construction")
	if not script_ref.has_method("rejected"):
		return
	var rejected = script_ref.call("rejected", "n003_plan_go", "stale_command_token", "n003_token_old")
	var rejected_dict: Dictionary = Dictionary(rejected.call("to_dict")) if rejected != null and rejected.has_method("to_dict") else {}
	_assert(not bool(rejected_dict.get("accepted", true)) and String(rejected_dict.get("reason", "")) == "stale_command_token", "Rejected GO keeps a stable reason without claiming a commit")


func _test_adapter_normalizes_button_hotkey_and_rmb_into_plans() -> void:
	var gateway_script: GDScript = load(FIRETEAM_COMMAND_GATEWAY_PATH)
	var adapter_script: GDScript = load(MISSION_COMMAND_ENTRY_ADAPTER_PATH)
	_assert(gateway_script.has_method("new") and adapter_script.has_method("new"), "Gateway and entry adapter are constructible")
	var context: Dictionary = _make_context()
	var gateway = gateway_script.new()
	var adapter = adapter_script.new()
	_assert(gateway.has_method("configure"), "FireteamCommandGateway accepts an injected SimulationRoot transport")
	_assert(adapter.has_method("configure"), "MissionCommandEntryAdapter accepts an injected FireteamCommandGateway")
	if not gateway.has_method("configure") or not adapter.has_method("configure"):
		_cleanup_context(context)
		return
	gateway.call("configure", context["simulation_root"])
	adapter.call("configure", gateway)
	_assert(adapter.has_method("plan_from_button"), "MissionCommandEntryAdapter exposes the Button plan entry")
	_assert(adapter.has_method("plan_from_hotkey"), "MissionCommandEntryAdapter exposes the Hotkey plan entry")
	_assert(adapter.has_method("plan_from_rmb"), "MissionCommandEntryAdapter exposes the RMB plan entry")
	if not adapter.has_method("plan_from_button") or not adapter.has_method("plan_from_hotkey") or not adapter.has_method("plan_from_rmb"):
		_cleanup_context(context)
		return
	var plans: Array = [
		adapter.call("plan_from_button", "move", PackedStringArray(["blue", "gold"]), Vector2(128.0, 96.0), 1, 1, "team_alpha"),
		adapter.call("plan_from_hotkey", "move", PackedStringArray(["blue", "gold"]), Vector2(128.0, 96.0), 1, 1, "team_alpha"),
		adapter.call("plan_from_rmb", "move", PackedStringArray(["blue", "gold"]), Vector2(128.0, 96.0), 1, 1, "team_alpha"),
	]
	var semantic_payloads: Array = []
	for plan_result in plans:
		var result_dict: Dictionary = Dictionary(plan_result.call("to_dict")) if plan_result != null and plan_result.has_method("to_dict") else {}
		_assert(bool(result_dict.get("accepted", false)) and not bool(result_dict.get("pending", true)), "Visible entry creates a plan without submitting GO")
		var plan_id: String = String(result_dict.get("plan_id", ""))
		var intent = gateway.call("get_planned_intent", plan_id) if gateway.has_method("get_planned_intent") else null
		semantic_payloads.append(Dictionary(intent.call("to_dict")) if intent != null and intent.has_method("to_dict") else {})
	_assert(Array(context["simulation_root"].command_queue).is_empty(), "Planning from Button, Hotkey and RMB queues no gameplay command")
	if semantic_payloads.size() == 3:
		for payload in semantic_payloads:
			_assert(String(payload.get("command_type", "")) == "move" and PackedStringArray(payload.get("selected_fireteam_ids", PackedStringArray())) == PackedStringArray(["blue", "gold"]) and Vector2(payload.get("target_position", Vector2.ZERO)) == Vector2(128.0, 96.0), "Visible entries share canonical command semantics")
	_cleanup_context(context)


func _test_go_submits_only_to_simulationroot_and_commits_on_tick() -> void:
	var gateway_script: GDScript = load(FIRETEAM_COMMAND_GATEWAY_PATH)
	var adapter_script: GDScript = load(MISSION_COMMAND_ENTRY_ADAPTER_PATH)
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	var unit: UnitStub = context["unit"]
	var gateway = gateway_script.new()
	var adapter = adapter_script.new()
	gateway.call("configure", simulation_root)
	adapter.call("configure", gateway)
	var plan_result = adapter.call("plan_from_button", "move", PackedStringArray(["blue", "gold"]), Vector2(160.0, 96.0), 2, 1, "team_alpha")
	var plan_dict: Dictionary = Dictionary(plan_result.call("to_dict")) if plan_result != null and plan_result.has_method("to_dict") else {}
	var plan_id: String = String(plan_dict.get("plan_id", ""))
	_assert(adapter.has_method("submit_go"), "MissionCommandEntryAdapter exposes the GO submission boundary")
	_assert(gateway.has_method("get_submission_result"), "FireteamCommandGateway exposes GO result state")
	_assert(simulation_root.has_method("submit_commander_order_intent_for_peer"), "SimulationRoot owns the CommanderOrder GO commit boundary")
	if not adapter.has_method("submit_go") or not gateway.has_method("get_submission_result") or not simulation_root.has_method("submit_commander_order_intent_for_peer"):
		_cleanup_context(context)
		return
	var go_result = adapter.call("submit_go", plan_id)
	var go_dict: Dictionary = Dictionary(go_result.call("to_dict")) if go_result != null and go_result.has_method("to_dict") else {}
	_assert(bool(go_dict.get("accepted", false)) and bool(go_dict.get("pending", false)) and not bool(go_dict.get("committed", true)), "GO is accepted as pending before the authority tick")
	_assert(Array(simulation_root.command_queue).size() == 2, "GO enqueues one authoritative CommanderIntent per selected Fireteam")
	_assert(unit.get_current_unit_command().is_empty(), "GO leaves UnitCommand unchanged before SimulationRoot commits")
	simulation_root.call("_physics_process", 0.1)
	var committed_result = gateway.call("get_submission_result", plan_id)
	var committed_dict: Dictionary = Dictionary(committed_result.call("to_dict")) if committed_result != null and committed_result.has_method("to_dict") else {}
	_assert(bool(committed_dict.get("committed", false)) and not bool(committed_dict.get("pending", true)), "Gateway records the authoritative commander-intent tick commit")
	var fireteam_results: Array = Array(go_dict.get("fireteam_results", []))
	_assert(fireteam_results.size() == 2 and String(Dictionary(fireteam_results[0]).get("command_token", "")) != String(Dictionary(fireteam_results[1]).get("command_token", "")), "Multi-Fireteam GO uses distinct per-Fireteam command tokens")
	var receipt_origin_by_token: Dictionary = Dictionary(simulation_root.get("_n003_commander_order_origin_peer_by_token"))
	var first_token: String = String(Dictionary(fireteam_results[0]).get("command_token", "")) if not fireteam_results.is_empty() else ""
	var second_token: String = String(Dictionary(fireteam_results[1]).get("command_token", "")) if fireteam_results.size() > 1 else ""
	_assert(not receipt_origin_by_token.has(first_token) and not receipt_origin_by_token.has(second_token), "Committed local N003 tokens release their one-shot receipt origin entries")
	var repeated_go = adapter.call("submit_go", plan_id)
	var repeated_dict: Dictionary = Dictionary(repeated_go.call("to_dict")) if repeated_go != null and repeated_go.has_method("to_dict") else {}
	_assert(not bool(repeated_dict.get("accepted", true)) and Array(simulation_root.command_queue).is_empty() and unit.get_current_unit_command().is_empty(), "Repeated GO is rejected without a local UnitCommand mutation")
	_cleanup_context(context)


func _test_move_defend_flank_take_share_the_plan_then_go_contract() -> void:
	var gateway_script: GDScript = load(FIRETEAM_COMMAND_GATEWAY_PATH)
	var adapter_script: GDScript = load(MISSION_COMMAND_ENTRY_ADAPTER_PATH)
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	var gateway = gateway_script.new()
	var adapter = adapter_script.new()
	gateway.call("configure", simulation_root)
	adapter.call("configure", gateway)
	for command_type in ["move", "defend", "flank", "take"]:
		var plan = adapter.call("plan_from_button", command_type, PackedStringArray(["blue", "gold"]), Vector2(224.0, 96.0), 3, 1, "team_alpha")
		var plan_dict: Dictionary = Dictionary(plan.call("to_dict")) if plan != null and plan.has_method("to_dict") else {}
		var plan_id: String = String(plan_dict.get("plan_id", ""))
		var intent = gateway.call("get_planned_intent", plan_id)
		var intent_dict: Dictionary = Dictionary(intent.call("to_dict")) if intent != null and intent.has_method("to_dict") else {}
		_assert(String(intent_dict.get("command_type", "")) == command_type, "%s keeps its command doctrine in the shared plan contract" % command_type.capitalize())
		var go = adapter.call("submit_go", plan_id)
		var go_dict: Dictionary = Dictionary(go.call("to_dict")) if go != null and go.has_method("to_dict") else {}
		_assert(bool(go_dict.get("accepted", false)) and bool(go_dict.get("pending", false)), "%s crosses the same pending GO boundary" % command_type.capitalize())
		simulation_root.call("_physics_process", 0.1)
		var committed = gateway.call("get_submission_result", plan_id)
		var committed_dict: Dictionary = Dictionary(committed.call("to_dict")) if committed != null and committed.has_method("to_dict") else {}
		_assert(bool(committed_dict.get("committed", false)), "%s commits only after SimulationRoot processes it" % command_type.capitalize())
	_cleanup_context(context)


func _test_rmb_area_order_payload_uses_the_same_plan_and_go_contract() -> void:
	var gateway_script: GDScript = load(FIRETEAM_COMMAND_GATEWAY_PATH)
	var adapter_script: GDScript = load(MISSION_COMMAND_ENTRY_ADAPTER_PATH)
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	simulation_root.is_server_authoritative = true
	simulation_root.call("set_peer_team", 2, "team_alpha")
	simulation_root.call("set_peer_role", 2, "commander")
	simulation_root.call("set_peer_fireteams", 2, PackedStringArray(["blue"]))
	var gateway = gateway_script.new()
	var adapter = adapter_script.new()
	gateway.call("configure", simulation_root)
	adapter.call("configure", gateway)
	var plan = adapter.call("plan_from_rmb", "defend", PackedStringArray(["blue"]), Vector2(160.0, 128.0), 4, 2, "team_alpha", "area_0042", {
		"n003_order_kind": "area",
		"area_order_id": "area_0042",
		"area_order_payload": {"area_order_id": "area_0042", "fireteam_id": "blue"},
	})
	var plan_dict: Dictionary = Dictionary(plan.call("to_dict")) if plan != null and plan.has_method("to_dict") else {}
	var intent = gateway.call("get_planned_intent", String(plan_dict.get("plan_id", "")))
	var intent_dict: Dictionary = Dictionary(intent.call("to_dict")) if intent != null and intent.has_method("to_dict") else {}
	_assert(String(intent_dict.get("target_area_id", "")) == "area_0042" and String(Dictionary(intent_dict.get("metadata", {})).get("n003_order_kind", "")) == "area", "RMB area order keeps target-area semantics in the normalized plan")
	var go = adapter.call("submit_go", String(plan_dict.get("plan_id", "")))
	var go_dict: Dictionary = Dictionary(go.call("to_dict")) if go != null and go.has_method("to_dict") else {}
	var queued_command: Dictionary = Dictionary(Array(simulation_root.command_queue)[0]) if Array(simulation_root.command_queue).size() == 1 else {}
	_assert(bool(go_dict.get("accepted", false)) and String(queued_command.get("target_area_id", "")) == "area_0042" and String(Dictionary(queued_command.get("metadata", {})).get("n003_order_kind", "")) == "area", "RMB area GO reaches SimulationRoot as the same authoritative envelope")
	_cleanup_context(context)


func _test_rejected_and_stale_go_leave_authority_state_unchanged() -> void:
	var gateway_script: GDScript = load(FIRETEAM_COMMAND_GATEWAY_PATH)
	var adapter_script: GDScript = load(MISSION_COMMAND_ENTRY_ADAPTER_PATH)
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	var unit: UnitStub = context["unit"]
	simulation_root.is_server_authoritative = true
	simulation_root.call("set_peer_team", 2, "team_alpha")
	simulation_root.call("set_peer_role", 2, "commander")
	simulation_root.call("set_peer_fireteams", 2, PackedStringArray(["blue"]))
	var gateway = gateway_script.new()
	var adapter = adapter_script.new()
	gateway.call("configure", simulation_root)
	adapter.call("configure", gateway)

	var foreign_plan = adapter.call("plan_from_button", "move", PackedStringArray(["gold"]), Vector2(128.0, 64.0), 4, 2, "team_alpha")
	var foreign_plan_dict: Dictionary = Dictionary(foreign_plan.call("to_dict")) if foreign_plan != null and foreign_plan.has_method("to_dict") else {}
	var foreign_go = adapter.call("submit_go", String(foreign_plan_dict.get("plan_id", "")))
	var foreign_go_dict: Dictionary = Dictionary(foreign_go.call("to_dict")) if foreign_go != null and foreign_go.has_method("to_dict") else {}
	_assert(not bool(foreign_go_dict.get("accepted", true)) and String(foreign_go_dict.get("reason", "")) == "fireteam_not_assigned_to_peer", "Rejected foreign Fireteam GO fails before any authoritative queue mutation")
	_assert(Array(simulation_root.command_queue).is_empty() and unit.get_current_unit_command().is_empty(), "Rejected GO leaves UnitCommand and authority queue unchanged")

	var accepted_plan = adapter.call("plan_from_button", "move", PackedStringArray(["blue"]), Vector2(128.0, 64.0), 4, 2, "team_alpha")
	var accepted_plan_dict: Dictionary = Dictionary(accepted_plan.call("to_dict")) if accepted_plan != null and accepted_plan.has_method("to_dict") else {}
	var accepted_go = adapter.call("submit_go", String(accepted_plan_dict.get("plan_id", "")))
	var accepted_go_dict: Dictionary = Dictionary(accepted_go.call("to_dict")) if accepted_go != null and accepted_go.has_method("to_dict") else {}
	_assert(bool(accepted_go_dict.get("accepted", false)) and Array(simulation_root.command_queue).size() == 1, "Assigned Fireteam GO is accepted by the authoritative server contract")
	simulation_root.call("_physics_process", 0.1)
	var stale_result: Dictionary = Dictionary(simulation_root.call("submit_commander_order_intent_for_peer", {
		"contract_category": "commander_intent",
		"source_context": "mission_n003_fireteam_go",
		"command_id": "n003_stale:blue",
		"command_token": "n003_stale:blue:r1",
		"plan_id": "n003_stale",
		"plan_revision": 1,
		"verb": "move",
		"command_type": "move",
		"fireteam_id": "blue",
		"selected_fireteam_ids": PackedStringArray(["blue"]),
		"coordinated_fireteam_ids": PackedStringArray(["blue"]),
		"team_id": "team_alpha",
		"target_position": Vector2(192.0, 64.0),
		"phase": 4,
		"source_peer_id": 2,
		"entry_source": "go",
	}, 2))
	_assert(not bool(stale_result.get("accepted", true)) and String(stale_result.get("reason", "")) == "stale_commander_order_revision", "Stale GO revision is rejected at the SimulationRoot boundary")
	_assert(Array(simulation_root.command_queue).is_empty() and unit.get_current_unit_command().is_empty(), "Stale GO leaves UnitCommand and runtime status unchanged")
	_cleanup_context(context)


func _test_gateway_recreation_uses_authority_revision_floor() -> void:
	var gateway_script: GDScript = load(FIRETEAM_COMMAND_GATEWAY_PATH)
	var adapter_script: GDScript = load(MISSION_COMMAND_ENTRY_ADAPTER_PATH)
	var context: Dictionary = _make_context()
	var simulation_root: Node = context["simulation_root"]
	simulation_root.is_server_authoritative = true
	simulation_root.call("set_peer_team", 2, "team_alpha")
	simulation_root.call("set_peer_role", 2, "commander")
	simulation_root.call("set_peer_fireteams", 2, PackedStringArray(["blue"]))
	var first_gateway = gateway_script.new()
	var first_adapter = adapter_script.new()
	first_gateway.call("configure", simulation_root)
	first_adapter.call("configure", first_gateway)
	var first_plan = first_adapter.call("plan_from_button", "move", PackedStringArray(["blue"]), Vector2(96.0, 64.0), 5, 2, "team_alpha")
	var first_plan_dict: Dictionary = Dictionary(first_plan.call("to_dict")) if first_plan != null and first_plan.has_method("to_dict") else {}
	var first_go = first_adapter.call("submit_go", String(first_plan_dict.get("plan_id", "")))
	var first_go_dict: Dictionary = Dictionary(first_go.call("to_dict")) if first_go != null and first_go.has_method("to_dict") else {}
	_assert(bool(first_go_dict.get("accepted", false)), "First peer plan is accepted through the authority revision boundary")
	simulation_root.call("_physics_process", 0.1)
	var first_intent = first_gateway.call("get_planned_intent", String(first_plan_dict.get("plan_id", "")))
	var first_revision: int = int(Dictionary(first_intent.call("to_dict")).get("plan_revision", 0)) if first_intent != null and first_intent.has_method("to_dict") else 0

	var recreated_gateway = gateway_script.new()
	var recreated_adapter = adapter_script.new()
	recreated_gateway.call("configure", simulation_root)
	recreated_adapter.call("configure", recreated_gateway)
	var recreated_plan = recreated_adapter.call("plan_from_button", "move", PackedStringArray(["blue"]), Vector2(128.0, 64.0), 5, 2, "team_alpha")
	var recreated_plan_dict: Dictionary = Dictionary(recreated_plan.call("to_dict")) if recreated_plan != null and recreated_plan.has_method("to_dict") else {}
	var recreated_intent = recreated_gateway.call("get_planned_intent", String(recreated_plan_dict.get("plan_id", "")))
	var recreated_revision: int = int(Dictionary(recreated_intent.call("to_dict")).get("plan_revision", 0)) if recreated_intent != null and recreated_intent.has_method("to_dict") else 0
	var recreated_go = recreated_adapter.call("submit_go", String(recreated_plan_dict.get("plan_id", "")))
	var recreated_go_dict: Dictionary = Dictionary(recreated_go.call("to_dict")) if recreated_go != null and recreated_go.has_method("to_dict") else {}
	_assert(recreated_revision > first_revision and bool(recreated_go_dict.get("accepted", false)), "Recreated gateway asks SimulationRoot for a revision above the accepted peer/Fireteam floor")
	_cleanup_context(context)


func _test_real_client_rpc_resolves_pending_and_keeps_peer_namespaces_distinct() -> void:
	var pair: Dictionary = await _create_multiplayer_api_pair()
	_assert(bool(pair.get("connected", false)), "Loopback ENet host and client connect for N003 command parity")
	if not bool(pair.get("connected", false)):
		return
	var host_api: MultiplayerAPI = pair["host_api"]
	var client_api: MultiplayerAPI = pair["client_api"]
	var host_peer: ENetMultiplayerPeer = pair["host_peer"]
	var client_peer: ENetMultiplayerPeer = pair["client_peer"]
	var client_peer_id: int = client_api.get_unique_id()
	var host_root := Node.new()
	host_root.name = "TaskN003Host"
	root.add_child(host_root)
	var client_root := Node.new()
	client_root.name = "TaskN003Client"
	root.add_child(client_root)
	set_multiplayer(host_api, host_root.get_path())
	set_multiplayer(client_api, client_root.get_path())
	var host_context: Dictionary = _make_context_under(host_root)
	var client_context: Dictionary = _make_context_under(client_root)
	var host_simulation: Node = host_context["simulation_root"]
	var client_simulation: Node = client_context["simulation_root"]
	for simulation_root in [host_simulation, client_simulation]:
		simulation_root.is_server_authoritative = true
		simulation_root.set_physics_process(false)
		simulation_root.call("set_peer_team", 1, "team_alpha")
		simulation_root.call("set_peer_role", 1, "host")
		simulation_root.call("set_peer_fireteams", 1, PackedStringArray(["blue"]))
		simulation_root.call("set_peer_team", client_peer_id, "team_alpha")
		simulation_root.call("set_peer_role", client_peer_id, "commander")
		simulation_root.call("set_peer_fireteams", client_peer_id, PackedStringArray(["blue"]))
	var gateway_script: GDScript = load(FIRETEAM_COMMAND_GATEWAY_PATH)
	var adapter_script: GDScript = load(MISSION_COMMAND_ENTRY_ADAPTER_PATH)
	var host_gateway = gateway_script.new()
	var host_adapter = adapter_script.new()
	host_gateway.call("configure", host_simulation)
	host_adapter.call("configure", host_gateway)
	var client_gateway = gateway_script.new()
	var client_adapter = adapter_script.new()
	client_gateway.call("configure", client_simulation)
	client_adapter.call("configure", client_gateway)
	client_simulation.network_command_result_received.connect(Callable(self, "_on_connected_n003_network_result").bind(client_gateway))

	var host_plan = host_adapter.call("plan_from_button", "move", PackedStringArray(["blue"]), Vector2(64.0, 64.0), 6, 1, "team_alpha")
	var host_plan_dict: Dictionary = Dictionary(host_plan.call("to_dict")) if host_plan != null and host_plan.has_method("to_dict") else {}
	var client_plan = client_adapter.call("plan_from_button", "move", PackedStringArray(["blue"]), Vector2(128.0, 64.0), 6, client_peer_id, "team_alpha")
	var client_plan_dict: Dictionary = Dictionary(client_plan.call("to_dict")) if client_plan != null and client_plan.has_method("to_dict") else {}
	_assert(String(host_plan_dict.get("plan_id", "")) != String(client_plan_dict.get("plan_id", "")), "Host and client use distinct peer-scoped plan namespaces")
	var client_go = client_adapter.call("submit_go", String(client_plan_dict.get("plan_id", "")))
	var client_go_dict: Dictionary = Dictionary(client_go.call("to_dict")) if client_go != null and client_go.has_method("to_dict") else {}
	_assert(bool(client_go_dict.get("accepted", false)) and bool(client_go_dict.get("pending", false)), "Connected client GO starts pending before the authority tick")
	_assert(Array(client_simulation.command_queue).is_empty(), "Connected client GO does not enqueue local gameplay work")
	await _poll_pair(host_api, client_api, 20)
	_assert(Array(host_simulation.command_queue).size() == 1, "Real client RPC reaches the host authority queue")
	var pending_result = client_gateway.call("get_submission_result", String(client_plan_dict.get("plan_id", "")))
	var pending_dict: Dictionary = Dictionary(pending_result.call("to_dict")) if pending_result != null and pending_result.has_method("to_dict") else {}
	_assert(bool(pending_dict.get("pending", false)) and not bool(pending_dict.get("committed", true)), "Host queue acknowledgement leaves client state pending until the authority tick")
	host_simulation.call("_physics_process", 0.1)
	await _poll_pair(host_api, client_api, 20)
	var committed_result = client_gateway.call("get_submission_result", String(client_plan_dict.get("plan_id", "")))
	var committed_dict: Dictionary = Dictionary(committed_result.call("to_dict")) if committed_result != null and committed_result.has_method("to_dict") else {}
	_assert(bool(committed_dict.get("accepted", false)) and bool(committed_dict.get("committed", false)) and not bool(committed_dict.get("pending", true)), "Committed authority feedback resolves the connected client gateway")
	var client_intent = client_gateway.call("get_planned_intent", String(client_plan_dict.get("plan_id", "")))
	var first_client_revision: int = int(Dictionary(client_intent.call("to_dict")).get("plan_revision", 0)) if client_intent != null and client_intent.has_method("to_dict") else 0
	var delayed_command: Dictionary = {
		"contract_category": "commander_intent",
		"source_context": "mission_n003_fireteam_go",
		"command_id": "n003_delayed_r1_blue",
		"command_token": "n003_delayed_r1_blue_token",
		"plan_id": "n003_p%d_delayed_r1" % client_peer_id,
		"plan_revision": first_client_revision,
		"verb": "move",
		"command_type": "move",
		"fireteam_id": "blue",
		"selected_fireteam_ids": PackedStringArray(["blue"]),
		"coordinated_fireteam_ids": PackedStringArray(["blue"]),
		"team_id": "team_alpha",
		"target_position": Vector2(160.0, 64.0),
		"phase": 6,
		"source_peer_id": client_peer_id,
		"entry_source": "go",
	}
	var delayed_result: Dictionary = Dictionary(host_simulation.call("submit_network_command_for_peer", delayed_command, client_peer_id))
	_assert(not bool(delayed_result.get("accepted", true)) and String(delayed_result.get("reason", "")) == "stale_commander_order_revision" and Array(host_simulation.command_queue).is_empty(), "Delayed older client revision is rejected without creating host gameplay work")
	var recreated_client_gateway = gateway_script.new()
	var recreated_client_adapter = adapter_script.new()
	recreated_client_gateway.call("configure", client_simulation)
	recreated_client_adapter.call("configure", recreated_client_gateway)
	var recreated_client_plan = recreated_client_adapter.call("plan_from_button", "move", PackedStringArray(["blue"]), Vector2(192.0, 64.0), 6, client_peer_id, "team_alpha")
	var recreated_client_plan_dict: Dictionary = Dictionary(recreated_client_plan.call("to_dict")) if recreated_client_plan != null and recreated_client_plan.has_method("to_dict") else {}
	var recreated_client_intent = recreated_client_gateway.call("get_planned_intent", String(recreated_client_plan_dict.get("plan_id", "")))
	var recreated_client_revision: int = int(Dictionary(recreated_client_intent.call("to_dict")).get("plan_revision", 0)) if recreated_client_intent != null and recreated_client_intent.has_method("to_dict") else 0
	var recreated_client_go = recreated_client_adapter.call("submit_go", String(recreated_client_plan_dict.get("plan_id", "")))
	var recreated_client_go_dict: Dictionary = Dictionary(recreated_client_go.call("to_dict")) if recreated_client_go != null and recreated_client_go.has_method("to_dict") else {}
	_assert(recreated_client_revision > first_client_revision and bool(recreated_client_go_dict.get("accepted", false)), "Recreated connected gateway uses the replicated SimulationRoot revision floor")
	await _poll_pair(host_api, client_api, 20)
	_assert(Array(host_simulation.command_queue).size() == 1, "Recreated connected gateway reaches the host with its new revision")
	host_simulation.call("_physics_process", 0.1)
	await _poll_pair(host_api, client_api, 20)
	var recreated_committed_result = recreated_client_gateway.call("get_submission_result", String(recreated_client_plan_dict.get("plan_id", "")))
	var recreated_committed_dict: Dictionary = Dictionary(recreated_committed_result.call("to_dict")) if recreated_committed_result != null and recreated_committed_result.has_method("to_dict") else {}
	_assert(bool(recreated_committed_dict.get("committed", false)), "Recreated connected gateway receives its authoritative commit receipt")

	var spoofed: Dictionary = {
		"contract_category": "commander_intent",
		"source_context": "mission_n003_fireteam_go",
		"command_id": "spoofed_peer_command",
		"command_token": "spoofed_peer_token",
		"plan_id": "n003_p999_spoof_1",
		"plan_revision": 1,
		"verb": "move",
		"command_type": "move",
		"fireteam_id": "blue",
		"selected_fireteam_ids": PackedStringArray(["blue"]),
		"coordinated_fireteam_ids": PackedStringArray(["blue"]),
		"team_id": "team_alpha",
		"target_position": Vector2(192.0, 64.0),
		"phase": 6,
		"source_peer_id": 999,
		"entry_source": "go",
	}
	var spoof_result: Dictionary = Dictionary(host_simulation.call("submit_network_command_for_peer", spoofed, client_peer_id))
	_assert(not bool(spoof_result.get("accepted", true)) and String(spoof_result.get("reason", "")) == "commander_order_source_peer_mismatch", "Authority rejects a CommanderOrderIntent whose claimed peer differs from the transport peer")
	_close_multiplayer_api_pair(host_peer, client_peer)
	host_root.queue_free()
	client_root.queue_free()
	await process_frame


func _on_connected_n003_network_result(result: Dictionary, gateway) -> void:
	if gateway != null and gateway.has_method("resolve_network_result"):
		gateway.call("resolve_network_result", result)


func _test_visible_controller_routes_only_through_n003_plan_and_go() -> void:
	var controller_text: String = FileAccess.get_file_as_string(TACTICAL_CONTROLLER_PATH)
	var movement_text: String = FileAccess.get_file_as_string("res://scripts/tactical/fireteam_movement_controller.gd")
	_assert(not controller_text.is_empty(), "Mission tactical controller source is available for visible-entry contract inspection")
	if controller_text.is_empty():
		return
	_assert(controller_text.contains("MISSION_COMMAND_ENTRY_ADAPTER_SCRIPT") and controller_text.contains("FIRETEAM_COMMAND_GATEWAY_SCRIPT"), "Visible mission controller composes the N003 entry adapter and gateway")
	_assert(controller_text.contains("_issue_command_from_entry(\"hotkey\"") and controller_text.contains("_issue_command_from_entry(\"button\""), "Hotkeys and buttons enter the same normalized command boundary")
	var visible_issue_start: int = controller_text.find("func _issue_command_from_entry")
	var visible_issue_end: int = controller_text.find("func _plan_connected_client_fireteam_command", visible_issue_start)
	var visible_issue_block: String = controller_text.substr(visible_issue_start, visible_issue_end - visible_issue_start) if visible_issue_start >= 0 and visible_issue_end > visible_issue_start else ""
	_assert(visible_issue_block.contains("plan_from_entry") and not visible_issue_block.contains("_get_active_flow_drivers"), "Visible button and hotkey orders create N003 plans instead of invoking flow drivers")
	_assert(visible_issue_block.contains("_mark_n003_waypoints_blocked"), "A rejected visible button or hotkey plan stays explicitly blocked instead of becoming an untagged compatibility order")
	var rmb_start: int = controller_text.find("func _set_waypoint_command_for_targets")
	var rmb_end: int = controller_text.find("func _set_area_order_command_for_targets", rmb_start)
	var rmb_block: String = controller_text.substr(rmb_start, rmb_end - rmb_start) if rmb_start >= 0 and rmb_end > rmb_start else ""
	_assert(rmb_block.contains("_plan_n003_rmb_waypoints"), "RMB waypoint commands create N003 plans before GO")
	_assert(rmb_block.contains("_mark_n003_waypoints_blocked"), "A rejected RMB plan stays explicitly blocked instead of becoming an untagged compatibility order")
	var area_start: int = controller_text.find("func _set_area_order_command_for_targets")
	var area_end: int = controller_text.find("func _update_waypoint_targets", area_start)
	var area_block: String = controller_text.substr(area_start, area_end - area_start) if area_start >= 0 and area_end > area_start else ""
	_assert(area_block.contains("_plan_n003_area_orders") and area_block.contains("plan_from_rmb") and area_block.contains("target_area_id"), "RMB area orders create target-area N003 plans before GO")
	var go_start: int = controller_text.find("func execute_selected_fireteam_orders")
	var n003_go_index: int = controller_text.find("_try_submit_n003_fireteam_orders", go_start)
	var legacy_go_index: int = controller_text.find("_try_submit_connected_client_fireteam_orders", go_start)
	_assert(n003_go_index > go_start and legacy_go_index > n003_go_index, "GO uses the N003 gateway before any compatibility client bridge")
	var n003_go_start: int = controller_text.find("func _try_submit_n003_fireteam_orders")
	var n003_go_end: int = controller_text.find("func _change_fireteam", n003_go_start)
	var n003_go_block: String = controller_text.substr(n003_go_start, n003_go_end - n003_go_start) if n003_go_start >= 0 and n003_go_end > n003_go_start else ""
	_assert(n003_go_block.contains("_collect_n003_area_plan_ids"), "GO collects tagged RMB area plans before compatibility handling")
	_assert(n003_go_block.contains("_get_n003_blocked_plan_reason"), "GO handles a rejected visible plan before it can reach compatibility handling")
	_assert(controller_text.contains("commander_intent_commit_received") and controller_text.contains("_on_n003_authoritative_commit_received"), "Visible controller turns the authoritative client commit receipt into read-only command feedback")
	_assert(not controller_text.contains("assign_unit_command") and not movement_text.contains("assign_unit_command"), "Mission command producers do not assign UnitCommands before SimulationRoot commits")
	_assert(not controller_text.contains("driver.call(\"issue_command"), "Visible mission execution retains flow drivers only as read-only mirrors")


func _make_context() -> Dictionary:
	var scene := Node.new()
	scene.name = "TaskN003Scene"
	root.add_child(scene)
	return _make_context_under(scene)


func _make_context_under(scene: Node) -> Dictionary:
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	scene.add_child(simulation_root)
	var unit := UnitStub.new()
	unit.name = "BlueLeader"
	unit.unit_id = "blue_leader"
	scene.add_child(unit)
	unit_registry.call("register_unit", unit.unit_id, unit)
	return {
		"scene": scene,
		"unit": unit,
		"simulation_root": simulation_root,
	}


func _create_multiplayer_api_pair() -> Dictionary:
	for port in range(ENET_PORT_START, ENET_PORT_END + 1):
		var host_peer := ENetMultiplayerPeer.new()
		if host_peer.create_server(port, 2) != OK:
			host_peer.close()
			continue
		var client_peer := ENetMultiplayerPeer.new()
		if client_peer.create_client("127.0.0.1", port) != OK:
			client_peer.close()
			host_peer.close()
			continue
		var host_api: MultiplayerAPI = MultiplayerAPI.create_default_interface()
		var client_api: MultiplayerAPI = MultiplayerAPI.create_default_interface()
		host_api.multiplayer_peer = host_peer
		client_api.multiplayer_peer = client_peer
		for _index in range(180):
			host_api.poll()
			client_api.poll()
			if client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				return {
					"connected": true,
					"host_api": host_api,
					"client_api": client_api,
					"host_peer": host_peer,
					"client_peer": client_peer,
				}
			await process_frame
		client_peer.close()
		host_peer.close()
	return {"connected": false}


func _poll_pair(host_api: MultiplayerAPI, client_api: MultiplayerAPI, frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		host_api.poll()
		client_api.poll()
		await process_frame


func _close_multiplayer_api_pair(host_peer: ENetMultiplayerPeer, client_peer: ENetMultiplayerPeer) -> void:
	client_peer.close()
	host_peer.close()


func _cleanup_context(context: Dictionary) -> void:
	var scene = context.get("scene", null)
	if scene != null and is_instance_valid(scene):
		scene.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
