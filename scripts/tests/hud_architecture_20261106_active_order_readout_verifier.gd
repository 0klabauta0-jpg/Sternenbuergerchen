extends SceneTree
## Readout fixtures only. Synthetic execution inputs are not physical proof.
## The real Move/GO case uses public commands without actor or timer writes.

const HUD: GDScript = preload("res://scripts/ui/mission_a5_hud_layout.gd")
const SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

class ReadoutProbe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var fixture_movement: Dictionary = {}
	var fixture_profiles: Dictionary = {}
	var movement_reads: PackedStringArray = []
	var profile_reads: PackedStringArray = []

	func _ready() -> void:
		set_process(false)
		set_physics_process(false)

	func get_fireteam_movement_state(fireteam_id: String) -> Dictionary:
		movement_reads.append(fireteam_id)
		return Dictionary(fixture_movement.get(fireteam_id, {})).duplicate(true)

	func get_active_behavior_profile(fireteam_id: String) -> Dictionary:
		profile_reads.append(fireteam_id)
		return Dictionary(fixture_profiles.get(fireteam_id, {})).duplicate(true)

	func set_fixture(selected: PackedStringArray, executing: PackedStringArray, movement: Dictionary, profiles: Dictionary, defense: Dictionary = {}, attack: Dictionary = {}) -> void:
		_selected_fireteam_ids = selected
		_phase_execution_by_fireteam.clear()
		for id in executing:
			_phase_execution_by_fireteam[id] = {"fixture_execution": true}
		_area_defense_execution_by_fireteam = defense.duplicate(true)
		_area_attack_execution_by_fireteam = attack.duplicate(true)
		fixture_movement = movement.duplicate(true)
		fixture_profiles = profiles.duplicate(true)
		movement_reads.clear()
		profile_reads.clear()

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("HUD_ACTIVE_ORDER_READOUT_VERIFY_BEGIN")
	_check_projection()
	var scene: Node = SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(12):
		await process_frame
	var owner: Node = scene.get_node("TacticalController")
	owner.set_process(false)
	var simulation: Node = scene.get_node("SimulationRoot")
	var probe := ReadoutProbe.new()
	probe.name = "ActiveOrderReadoutProbe"
	scene.add_child(probe)
	_check_context_sources(probe)
	_check_public_move(scene, owner, simulation)
	scene.queue_free()
	for _frame in range(2):
		await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	print("HUD_ACTIVE_ORDER_READOUT_VERIFY_PASS" if _failed == 0 else "HUD_ACTIVE_ORDER_READOUT_VERIFY_FAIL")
	quit(0 if _failed == 0 else 1)


func _check_projection() -> void:
	var cases: Array[Dictionary] = [
		{"id": "move", "selected": 1, "executing": 1, "labels": ["MOVE"], "expected": "Auftrag: Bewegen"},
		{"id": "stationary_defend", "selected": 1, "executing": 1, "labels": ["DEFEND"], "expected": "Auftrag: Halten"},
		{"id": "same_take", "selected": 2, "executing": 2, "labels": ["TAKE", "TAKE"], "expected": "Auftrag: Nehmen"},
		{"id": "mixed", "selected": 2, "executing": 2, "labels": ["MOVE", "DEFEND"], "expected": "Auftrag: Verschiedene Befehle"},
		{"id": "partial", "selected": 2, "executing": 1, "labels": ["MOVE"], "expected": "Auftrag: 1 von 2 Teams aktiv"},
		{"id": "unknown", "selected": 2, "executing": 2, "labels": ["MOVE", ""], "expected": "Auftrag: Wird ausgeführt"},
		{"id": "legacy_missing_labels", "selected": 1, "executing": 1, "labels": [], "expected": "Auftrag: Wird ausgeführt"},
		{"id": "no_selection", "selected": 0, "executing": 0, "labels": ["MOVE"], "expected": "Auftrag: Fireteam auswählen"}
	]
	for entry in cases:
		var context: Dictionary = {"selection_count": entry.selected, "executing_count": entry.executing, "active_order_labels": entry.labels, "feedback": "GO BLUE"}
		var before: PackedByteArray = var_to_bytes(context)
		var model: Dictionary = HUD.build_player_readout(context)
		_assert(String(model.get("order", "")) == String(entry.expected), "%s has a concrete, mixed or appropriately incomplete order" % entry.id)
		_assert(var_to_bytes(context) == before and bool(model.get("read_only", false)) and not bool(model.get("ui_sets_gameplay_truth", true)), "%s projection preserves input and has no gameplay authority" % entry.id)
	var focused: Dictionary = {"selection_count": 1, "executing_count": 1, "active_order_labels": ["MOVE"], "focused_order_label": "TAKE", "feedback": "GO BLUE"}
	var future: Dictionary = HUD.build_player_readout(focused)
	_assert(String(future.get("order", "")) == "Auftrag: Nehmen" and String(future.get("feedback", "")) == "Team führt Befehle aus", "Focused future command keeps its separate priority over the running Move")
	var feedback_cases: Dictionary = {"GO BLUE": "Ausführung läuft", "FIRE HOLD REQUEST": "Anfrage wird geprüft", "FIRE HOLD REQUEST REJECTED": "Aktion blockiert · Details", "HOST TIMEOUT": "Keine Bestätigung · Details", "OBSERVER MODE": "Beobachten · keine Befehlsfreigabe"}
	for raw in feedback_cases:
		var context: Dictionary = {"selection_count": 1, "executing_count": 1, "active_order_labels": ["MOVE"], "feedback": raw}
		_assert(String(HUD.build_player_readout(context).get("feedback", "")) == String(feedback_cases[raw]), "%s keeps its existing feedback text" % raw)


func _check_context_sources(probe: ReadoutProbe) -> void:
	var cases: Array[Dictionary] = [
		{"id": "movement_wins", "selected": ["blue"], "executing": ["blue"], "movement": {"blue": {"command_type": "move"}}, "profiles": {"blue": {"metadata": {"origin_command_type": "take"}}}, "expected": ["MOVE"]},
		{"id": "profile_fallback", "selected": ["blue"], "executing": ["blue"], "movement": {}, "profiles": {"blue": {"metadata": {"origin_command_type": "defend"}}}, "expected": ["DEFEND"]},
		{"id": "area_fallback", "selected": ["blue"], "executing": ["blue"], "movement": {}, "profiles": {}, "attack": {"blue": {"command_type": "take"}}, "expected": ["TAKE"]},
		{"id": "unknown_no_move_default", "selected": ["blue"], "executing": ["blue"], "movement": {"blue": {"command_type": "unknown"}}, "profiles": {}, "expected": [""]},
		{"id": "idle_profile_not_execution", "selected": ["blue"], "executing": [], "movement": {}, "profiles": {"blue": {"metadata": {"origin_command_type": "move"}}}, "expected": []},
		{"id": "unselected_ignored", "selected": ["blue"], "executing": ["blue", "red"], "movement": {"blue": {"command_type": "move"}, "red": {"command_type": "take"}}, "profiles": {}, "expected": ["MOVE"]}
	]
	for entry in cases:
		probe.set_fixture(PackedStringArray(entry.selected), PackedStringArray(entry.executing), Dictionary(entry.movement), Dictionary(entry.profiles), Dictionary(entry.get("defense", {})), Dictionary(entry.get("attack", {})))
		var before: PackedByteArray = var_to_bytes([probe.get("_phase_execution_by_fireteam"), probe.get("_area_defense_execution_by_fireteam"), probe.get("_area_attack_execution_by_fireteam"), probe.fixture_movement, probe.fixture_profiles])
		var context: Dictionary = probe.call("_build_native_player_readout_context")
		_assert(Array(context.get("active_order_labels", [])) == Array(entry.expected), "%s projects only the existing selected execution sources" % entry.id)
		_assert(var_to_bytes([probe.get("_phase_execution_by_fireteam"), probe.get("_area_defense_execution_by_fireteam"), probe.get("_area_attack_execution_by_fireteam"), probe.fixture_movement, probe.fixture_profiles]) == before, "%s readout leaves all synthetic owner sources unchanged" % entry.id)
		_assert(not probe.movement_reads.has("red") and not probe.profile_reads.has("red"), "%s never reads an unselected team's active order" % entry.id)


func _check_public_move(scene: Node, owner: Node, simulation: Node) -> void:
	var selected: PackedStringArray = PackedStringArray(owner.call("get_selected_fireteam_ids"))
	_assert(not selected.is_empty(), "Real mission fixture has a normally selected team")
	if selected.is_empty():
		return
	owner.call("_set_selected_fireteams", PackedStringArray([selected[0]]), false)
	var marker: Node2D = scene.get_node("TargetMarker") as Node2D
	_assert(bool(owner.call("issue_right_click_command_for_test", marker.global_position + Vector2(128.0, 0.0), "move", false)), "Public Move plans an actual waypoint")
	_assert(bool(owner.call("execute_selected_fireteam_orders")), "Public GO starts that actual plan")
	var before: PackedByteArray = var_to_bytes([owner.call("get_order_plans_snapshot"), owner.call("get_fireteam_movement_state", selected[0]), simulation.get("command_queue")])
	var context: Dictionary = owner.call("_build_native_player_readout_context")
	_assert(int(context.get("executing_count", 0)) == 1 and Array(context.get("active_order_labels", [])) == ["MOVE"], "Real Move execution exports the existing movement command type")
	var model: Dictionary = HUD.build_player_readout(context)
	_assert(String(model.get("order", "")) == "Auftrag: Bewegen" and String(model.get("feedback", "")) == "Ausführung läuft", "Real Move and GO produce concrete order plus unchanged running feedback")
	_assert(var_to_bytes([owner.call("get_order_plans_snapshot"), owner.call("get_fireteam_movement_state", selected[0]), simulation.get("command_queue")]) == before, "Real readout creates no command and changes no plan or movement state")


func _assert(ok: bool, message: String) -> void:
	if ok:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
