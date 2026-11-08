extends SceneTree
const MISSION: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
class Probe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var boot_parses := 0
	var explicit_parses := 0
	func build_review_session_identity_snapshot(args: Array = []) -> Dictionary:
		if args.is_empty():
			boot_parses += 1
		else:
			explicit_parses += 1
		return super.build_review_session_identity_snapshot(args)
	func _ready() -> void:
		super._ready()
		set_process(false)
		set_physics_process(false)
	func original_identity_oracle(args: Array = []) -> Dictionary:
		var raw_args: Array = args.duplicate()
		var source := "provided_args"
		if raw_args.is_empty():
			raw_args = OS.get_cmdline_user_args()
			source = "OS.get_cmdline_user_args"
		var role := ""
		var team_id := ""
		var peer_id := 0
		for arg_variant in raw_args:
			var arg := String(arg_variant).strip_edges()
			if arg.begins_with("--review-role="):
				role = arg.substr("--review-role=".length()).strip_edges().to_lower()
			elif arg.begins_with("--peer-id="):
				var peer_text := arg.substr("--peer-id=".length()).strip_edges()
				if peer_text.is_valid_int():
					peer_id = int(peer_text)
			elif arg.begins_with("--team="):
				team_id = arg.substr("--team=".length()).strip_edges().to_lower()
		var team_label := _build_review_session_team_label(team_id)
		var display_tokens := PackedStringArray()
		if not role.is_empty():
			display_tokens.append(role.to_upper())
		if peer_id > 0:
			display_tokens.append("P%d" % peer_id)
		if not team_label.is_empty():
			display_tokens.append(team_label)
		var badge_text := " ".join(display_tokens)
		return {
			"active": not badge_text.is_empty(),
			"style_id": REVIEW_SESSION_BADGE_STYLE_ID,
			"source": source,
			"role": role,
			"role_label": role.to_upper(),
			"peer_id": peer_id,
			"peer_label": "P%d" % peer_id if peer_id > 0 else "",
			"team_id": team_id,
			"team_label": team_label,
			"badge_text": badge_text,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		}
var passed := 0
var failed := 0
func _initialize() -> void:
	call_deferred("_run")
func check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		print("FAIL: ", label)
func _run() -> void:
	var cold := Probe.new()
	var expected := cold.original_identity_oracle()
	for iteration in range(20):
		check(cold.call("_get_review_session_identity_snapshot") == expected, "Boot identity matches frozen parser oracle %d" % iteration)
	check(cold.boot_parses == 1, "Immutable boot args are parsed exactly once per controller lifetime")
	var returned: Dictionary = cold.call("_get_review_session_identity_snapshot")
	returned["role"] = "external-write"
	returned["active"] = not bool(expected.active)
	check(cold.call("_get_review_session_identity_snapshot") == expected, "Returned identity cannot mutate the next read")
	for args in [["--review-role=host", "--peer-id=17", "--team=team_bravo"], ["--review-role=client", "--peer-id=invalid", "--team=team_alpha"], ["--review-role=observer", "--team=custom_team"], []]:
		check(cold.build_review_session_identity_snapshot(args) == cold.original_identity_oracle(args), "Explicit parser preserves all supplied/default argument semantics")
	check(cold.explicit_parses == 3, "Explicit argument parsing remains independent")
	check(cold.call("_get_review_session_identity_snapshot") == expected, "Explicit roles never replace process identity")
	cold.free()
	var scene := MISSION.instantiate()
	var original := scene.get_node("TacticalController")
	var probe := Probe.new()
	for property in original.get_property_list():
		var usage := int(property.usage)
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and (usage & PROPERTY_USAGE_EDITOR) != 0:
			probe.set(String(property.name), original.get(String(property.name)))
	scene.remove_child(original)
	original.free()
	probe.name = "TacticalController"
	scene.add_child(probe)
	root.add_child(scene)
	for frame in range(16):
		await process_frame
	var sim := scene.get_node("SimulationRoot")
	var before := _owner_state(sim)
	probe.boot_parses = 0
	for heavy in [false, true, false, true]:
		probe.call("_update_ui", heavy, true)
		check(probe.get_local_command_team_id() == probe.FRIENDLY_TEAM_ID, "Offline team ownership preserved")
	check(probe.boot_parses == 0, "Real Full and Light HUD refreshes do not reparse immutable process config")
	check(_owner_state(sim) == before, "Presentation leaves synchronous simulation tick and queues unchanged")
	check(int(probe.get_mission_hud_read_model_snapshot().get("projection_scope_depth", -1)) == 0, "Projection scope closes after Full/Light work")
	print("R5_IDENTITY_COUNTER ", JSON.stringify({"hud_boot_parses": probe.boot_parses}))
	scene.queue_free()
	await process_frame
	print("R5_IDENTITY_DONE ", JSON.stringify({"passed": passed, "failed": failed}))
	quit(0 if failed == 0 else 1)
func _owner_state(sim: Node) -> Dictionary:
	return {"tick": sim.call("get_tick"), "commands": str(sim.get("command_queue")), "effects": str(sim.get("effect_queue"))}
