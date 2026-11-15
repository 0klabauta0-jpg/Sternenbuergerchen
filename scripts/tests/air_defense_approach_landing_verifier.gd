extends SceneTree
## Integration: the real mission controller on GM02 rolls the air defence at the
## landing commit point (_try_start_drop_sequence).
## Task: docs/tasks/FLUGABWEHR_ANSCHLUSS_2026_11_14.md
const MISSION = preload("res://scenes/tests/mission_reactivity_test.tscn")
const MP_CONTRACT = preload("res://scripts/multiplayer/multiplayer_command_contract.gd")
const MAP_PATH := "res://maps/Ground_Mission02_128x128.json"
const SCENARIO_PATH := "res://data/mission_scenarios/ground_mission02_128x128.json"
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func _run() -> void:
	var mission: Node = MISSION.instantiate()
	var setup: Node = mission.get_node("MissionSetup")
	setup.set("map_file_path", MAP_PATH)
	setup.set("scenario_file_path", SCENARIO_PATH)
	setup.set("selected_team_unit_ids", PackedStringArray(["unit_alpha", "unit_bravo"]))
	setup.set("selected_team_fireteam_ids", PackedStringArray(["ft1", "ft2"]))
	setup.set("defer_friendly_runtime_activation", true)
	root.add_child(mission)
	for _frame in range(3):
		await process_frame
	var controller: Node = mission.get_node("TacticalController")
	controller.set_process(false)
	var driver: Node = controller.call("_get_combat_loop_driver")
	var fit: Dictionary = driver.call("get_enemy_group_fit_counts") if driver != null else {}
	print("fit counts: ", fit)
	check(int(fit.get("red_air_defense", 0)) > 0, "the scenario's air-defence group is known and crewed when the first craft lands")
	var teams: PackedStringArray = controller.call("_get_available_fireteam_ids")
	check(teams.size() >= 2, "scenario exposes two fireteams")
	if teams.size() < 2:
		_finish(mission)
		return
	var first_ids: Array = _unit_ids(controller.call("_get_fireteam_units", String(teams[0]), true))
	var second_ids: Array = _unit_ids(controller.call("_get_fireteam_units", String(teams[1]), true))
	var registry: Node = controller.call("_get_terrain_registry")
	var hot_lz: Vector2 = registry.call("grid_to_world", Vector2i(90, 85)) # flat open ground 7 cells from the Hagel
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file(MAP_PATH)
	var quiet_lz: Vector2 = map.get_marker_position("spawn_alpha")
	var state: Dictionary = controller.call("get_planning_state")
	state.merge({"mission_drop_source": "homebase_direct", "mission_drop_craft_id": "craft_a", "mission_drop_state": "waiting", "drop_ship_staged": true,
		"embarked_unit_ids": first_ids + second_ids, "deployed_unit_ids": [], "has_lz_position": true, "lz_position": hot_lz, "selected_fireteams": [teams[0]],
		"mission_drop_cards": [_card("craft_a", String(teams[0]), first_ids, hot_lz), _card("craft_b", String(teams[1]), second_ids, quiet_lz)]}, true)
	controller.call("set_planning_state", state)
	controller.call("_select_mission_dropship_craft", "craft_a", false)
	controller.call("_set_selected_fireteams", PackedStringArray([teams[0]]), false)
	var started: bool = bool(controller.call("_try_start_drop_sequence", true))
	var text: String = String(controller.get("_last_command_text"))
	print("hot approach: started=", started, " text=", text)
	check(not started and text.begins_with("Flugabwehr: Anflug abgebrochen") and text.ends_with(" %"), "an approach beside the battery is broken off with a German message: " + text)
	check(String(controller.get("_drop_sequence_phase")) != "inbound", "the broken-off craft does not start its inbound flight")
	check(String(_find_card(controller, "craft_a").get("card_feedback_text", "")) == text, "the craft card shows the same one-line message")
	check(String(_find_card(controller, "craft_a").get("state", "")) == "waiting", "the craft stays available for another attempt")
	for _frame in range(3):
		await physics_frame
	var simulation_root: Node = mission.get_node("SimulationRoot")
	var status: Dictionary = simulation_root.call("get_air_asset_status_snapshot", "craft_a")
	print("stored status: ", status.get("state"), " integrity=", status.get("integrity"))
	check(not status.is_empty() and str(int(status.get("integrity", -1))) + " %" == text.get_slice("Rumpf ", 1), "SimulationRoot stores the hull as the craft's air asset integrity")
	var retried: bool = bool(controller.call("_try_start_drop_sequence", true))
	var retry_text: String = String(controller.get("_last_command_text"))
	print("retry: started=", retried, " text=", retry_text)
	check(not retried and retry_text.begins_with("Flugabwehr:") and int(retry_text.get_slice("Rumpf ", 1).to_int()) <= int(status.get("integrity", 100)), "a second attempt starts from the stored hull, not from a fresh ship: " + retry_text)
	controller.call("_select_mission_dropship_craft", "craft_b", false)
	controller.call("_set_selected_fireteams", PackedStringArray([teams[1]]), false)
	var quiet_started: bool = bool(controller.call("_try_start_drop_sequence", true))
	var quiet_text: String = String(controller.get("_last_command_text"))
	print("quiet approach: started=", quiet_started, " text=", quiet_text)
	check(quiet_started and String(controller.get("_air_defense_feedback_text")).is_empty() and not quiet_text.begins_with("Flugabwehr"), "an approach to the west landing field starts exactly as before, without air-defence message")
	check(simulation_root.call("get_air_asset_status_snapshot", "craft_b").is_empty(), "no air asset status is written for an approach no vehicle could track")
	await _style_checks(mission, controller, simulation_root, String(teams[0]), hot_lz)
	_finish(mission)


## Task docs/tasks/FLUGABWEHR_ANFLUGSTIL_REPARATUR_2026_11_15.md
func _style_checks(mission: Node, controller: Node, simulation_root: Node, team: String, hot_lz: Vector2) -> void:
	controller.call("_select_mission_dropship_craft", "craft_a", false)
	controller.call("_set_selected_fireteams", PackedStringArray([team]), false)
	check(String(controller.get("_current_approach_style")) == "normal" and String(_find_card(controller, "craft_a").get("approach_style", "")) == "normal" and String(Dictionary(controller.call("get_planning_state")).get("approach_style", "")) == "normal", "a craft without a stored approach style uses normal; card and planning state carry it")
	var reject: Dictionary = MP_CONTRACT.new().validate({"contract_category": "dropship_command", "command_type": "set_dropship_approach_style", "team_id": "team_alpha", "fireteam_id": team, "craft_id": "craft_a", "approach_style": "kamikaze"})
	var accept: Dictionary = MP_CONTRACT.new().validate({"contract_category": "dropship_command", "command_type": "set_dropship_approach_style", "team_id": "team_alpha", "fireteam_id": team, "craft_id": "craft_a", "approach_style": "aggressiv"})
	check(String(reject.get("reason", "")) == "dropship_approach_style_invalid" and not String(accept.get("reason", "")).begins_with("dropship_approach_style"), "the network contract rejects an unknown approach style and passes a known one: " + String(accept.get("reason", "accepted")))
	var bad: bool = bool(controller.call("apply_authoritative_dropship_command", {"command_type": "set_dropship_approach_style", "craft_id": "craft_a", "fireteam_id": team, "approach_style": "kamikaze"}))
	check(not bad and String(controller.get("_current_approach_style")) == "normal", "the controller rejects an unknown approach style and keeps the stored one")
	var good: bool = bool(controller.call("apply_authoritative_dropship_command", {"command_type": "set_dropship_approach_style", "craft_id": "craft_a", "fireteam_id": team, "approach_style": "vorsichtig"}))
	check(good and String(_find_card(controller, "craft_a").get("approach_style", "")) == "vorsichtig" and String(_find_card(controller, "craft_b").get("approach_style", "normal")) == "normal", "the command stores vorsichtig on this craft's card only")
	var saved: Dictionary = controller.call("get_planning_state")
	controller.call("_select_approach_style", "aggressiv")
	controller.call("set_planning_state", saved)
	check(String(controller.get("_current_approach_style")) == "vorsichtig" and String(_find_card(controller, "craft_a").get("approach_style", "")) == "vorsichtig", "the stored style survives the planning-state round trip like the approach angle")

	# Landing scatter: x1.5 only for vorsichtig, at the campaign field LZ resolution.
	controller.set("_lz_position", hot_lz)
	var cautious_lz: Dictionary = controller.call("_resolve_campaign_field_lz")
	controller.call("_select_approach_style", "normal")
	var normal_lz: Dictionary = controller.call("_resolve_campaign_field_lz")
	print("field lz radius normal=", normal_lz.get("lz_accuracy_radius"), " vorsichtig=", cautious_lz.get("lz_accuracy_radius"))
	check(bool(normal_lz.get("ok", false)) and bool(cautious_lz.get("ok", false)) and is_equal_approx(float(cautious_lz.lz_accuracy_radius), float(normal_lz.lz_accuracy_radius) * 1.5), "the campaign field LZ scatter radius is 1.5 times larger for vorsichtig")

	# Repair restores the craft's integrity (helper on the service repair path).
	for _frame in range(3):
		await physics_frame
	var before: Dictionary = simulation_root.call("get_air_asset_status_snapshot", "craft_a")
	var repair_result: Dictionary = {}
	simulation_root.call("_repair_air_asset_status_at_service", "craft_a", repair_result)
	var repaired: Dictionary = simulation_root.call("get_air_asset_status_snapshot", "craft_a")
	print("repair: before=", before.get("integrity"), "/", before.get("state"), " after=", repaired.get("integrity"), "/", repaired.get("state"))
	check(int(before.get("integrity", 100)) < 100 and int(repaired.get("integrity", 0)) == 100 and String(repaired.get("state", "")) == "intact" and int(repair_result.get("air_asset_integrity_after", 0)) == 100, "the service repair sets the damaged craft back to integrity 100 / intact")

	for style in ["normal", "vorsichtig"]:
		controller.call("_select_approach_style", style)
		var started: bool = bool(controller.call("_try_start_drop_sequence", true))
		var text: String = String(controller.get("_last_command_text"))
		print(style, " approach: started=", started, " text=", text)
		check(not started and text.begins_with("Flugabwehr: Anflug abgebrochen"), style + " breaks off beside the battery: " + text)
		for _frame in range(3):
			await physics_frame
		simulation_root.call("_repair_air_asset_status_at_service", "craft_a", {})

	# Aggressiv: the landing proceeds despite hits and writes the damage.
	_open_dropship_details(mission, controller)
	for _frame in range(4):
		await process_frame
	var style_button: Button = _find_style_button(mission, "craft_a", "aggressiv")
	check(style_button != null and style_button.text == "Aggressiv" and not style_button.tooltip_text.is_empty() and _find_style_button(mission, "craft_a", "vorsichtig") != null and _find_style_button(mission, "craft_a", "normal") != null, "the dropship card shows the three approach style buttons with German labels and tooltips")
	if style_button != null:
		style_button.pressed.emit()
	check(String(controller.get("_current_approach_style")) == "aggressiv" and String(_find_card(controller, "craft_a").get("approach_style", "")) == "aggressiv", "pressing Aggressiv on the card stores the style for this craft")
	controller.call("_update_ui")
	var refreshed: Button = _find_style_button(mission, "craft_a", "aggressiv")
	check(refreshed == null or bool(refreshed.get_meta("mission_dropship_card_command_active", false)), "the card shows Aggressiv as the active style")
	# Free footprint found by scanning GM02 with the NW approach: two hits, hull stays above the 35 % auto break-off.
	var press_registry: Node = controller.call("_get_terrain_registry")
	var press_lz: Vector2 = press_registry.call("grid_to_world", Vector2i(81, 86))
	controller.set("_lz_position", press_lz)
	controller.set("_has_lz_position", true)
	var pressed_on: bool = bool(controller.call("_try_start_drop_sequence", true))
	var on_text: String = String(controller.get("_last_command_text"))
	print("aggressiv approach: started=", pressed_on, " text=", on_text)
	check(pressed_on and on_text.begins_with("Flugabwehr: ") and on_text.contains(" Treffer, Rumpf ") and on_text.get_slice(" Treffer", 0).get_slice(": ", 1).to_int() > 0, "aggressiv lands inside the battery's reach despite hits and reports them: " + on_text)
	check(String(controller.get("_drop_sequence_phase")) == "inbound", "the pressed-on craft starts its inbound flight")
	for _frame in range(3):
		await physics_frame
	var after: Dictionary = simulation_root.call("get_air_asset_status_snapshot", "craft_a")
	check(str(int(after.get("integrity", -1))) + " %" == on_text.get_slice("Rumpf ", 1) and String(after.get("state", "")) in ["hit", "damaged"] if int(after.get("integrity", 100)) < 100 else String(after.get("state", "")) in ["hit", "threatened"], "the pressed-on damage is stored as the craft's integrity: %s / %s" % [str(after.get("integrity")), str(after.get("state"))])


func _open_dropship_details(mission: Node, controller: Node) -> void:
	controller.call("_update_ui")
	var details := mission.get_node_or_null("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Header/DetailsButton") as Button
	if details != null:
		details.pressed.emit()


func _find_style_button(node: Node, craft_id: String, style: String) -> Button:
	if node is Button and String(node.get_meta("mission_dropship_approach_style", "")) == style and String(node.get_meta("mission_dropship_craft_id", "")) == craft_id:
		return node
	for child in node.get_children():
		var found: Button = _find_style_button(child, craft_id, style)
		if found != null:
			return found
	return null

func _finish(mission: Node) -> void:
	mission.queue_free()
	await process_frame
	print("AIR_DEFENSE_APPROACH_LANDING passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

func _card(id: String, team: String, units: Array, lz: Vector2) -> Dictionary:
	return {"craft_id": id, "model_id": "cutlass", "display_name": id, "payload_source": "homebase_direct", "state": "waiting", "progress": 0.0, "passenger_count": units.size(), "embarked_unit_ids": units, "boarded_fireteam_ids": [team], "has_lz_position": true, "lz_position": lz, "approach_angle": "NW"}

func _find_card(controller: Node, id: String) -> Dictionary:
	for card in Array(Dictionary(controller.call("get_planning_state")).get("mission_drop_cards", [])):
		if String(card.get("craft_id", "")) == id:
			return card
	return {}

func _unit_ids(units: Array) -> Array:
	var ids: Array = []
	for unit in units:
		ids.append(String(unit.call("get_unit_id")))
	return ids
