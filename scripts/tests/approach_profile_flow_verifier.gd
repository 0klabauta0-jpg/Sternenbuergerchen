extends SceneTree
## Abschnitt LA, Spielerweg: die Anflugart (Steil / Normal / Tief) an der Schiffskarte waehlen,
## zur Landung anfliegen, Ergebnis-Satz und Rumpfwert pruefen. Echter Missionscontroller auf GM02.
const MISSION = preload("res://scenes/tests/mission_reactivity_test.tscn")
const MP_CONTRACT = preload("res://scripts/multiplayer/multiplayer_command_contract.gd")
const PLAN = preload("res://scripts/mission/air_defense_approach_plan.gd")
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

func _open_mission() -> Dictionary:
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
	var teams: PackedStringArray = controller.call("_get_available_fireteam_ids")
	var env := {"mission": mission, "controller": controller, "teams": teams, "ok": teams.size() >= 2}
	if teams.size() < 2:
		return env
	var first_ids: Array = _unit_ids(controller.call("_get_fireteam_units", String(teams[0]), true))
	var second_ids: Array = _unit_ids(controller.call("_get_fireteam_units", String(teams[1]), true))
	var registry: Node = controller.call("_get_terrain_registry")
	var hot_lz: Vector2 = registry.call("grid_to_world", Vector2i(90, 85))
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file(MAP_PATH)
	var quiet_lz: Vector2 = map.get_marker_position("spawn_alpha")
	var state: Dictionary = controller.call("get_planning_state")
	var cards: Array = [_card("craft_a", String(teams[0]), first_ids, hot_lz, "cutlass", ""), _card("craft_b", String(teams[1]), second_ids, quiet_lz, "cutlass", "")]
	state.merge({"mission_drop_source": "homebase_direct", "mission_drop_craft_id": "craft_a", "mission_drop_state": "waiting", "drop_ship_staged": true,
		"embarked_unit_ids": first_ids + second_ids, "deployed_unit_ids": [], "has_lz_position": true, "lz_position": hot_lz, "selected_fireteams": [teams[0]],
		"mission_drop_cards": cards}, true)
	state.erase("approach_path")
	controller.call("set_planning_state", state)
	controller.call("_select_mission_dropship_craft", "craft_a", false)
	controller.call("_set_selected_fireteams", PackedStringArray([teams[0]]), false)
	env.merge({"first_ids": first_ids, "second_ids": second_ids, "hot_lz": hot_lz, "quiet_lz": quiet_lz, "registry": registry}, true)
	return env

func _run() -> void:
	await _ui_and_commands()
	await _accident_run("tief")
	await _accident_run("steil")
	await _hot_tief_run()
	print("APPROACH_PROFILE_FLOW passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

func _close(env: Dictionary) -> void:
	(env.mission as Node).queue_free()
	await process_frame

func _ui_and_commands() -> void:
	var env: Dictionary = await _open_mission()
	check(bool(env.ok), "scenario exposes two fireteams")
	if not bool(env.ok):
		await _close(env)
		return
	var mission: Node = env.mission
	var controller: Node = env.controller
	var team: String = String(env.teams[0])
	# A state without the field starts with Normal.
	check(String(controller.get("_current_approach_path")) == "normal" and String(_find_card(controller, "craft_a").get("approach_path", "")) == "normal" and String(Dictionary(controller.call("get_planning_state")).get("approach_path", "")) == "normal", "a planning state without the approach path starts every craft with normal; card and planning state carry it")
	# Network contract.
	var reject: Dictionary = MP_CONTRACT.new().validate({"contract_category": "dropship_command", "command_type": "set_dropship_approach_path", "team_id": "team_alpha", "fireteam_id": team, "craft_id": "craft_a", "approach_path": "senkrecht"})
	var missing: Dictionary = MP_CONTRACT.new().validate({"contract_category": "dropship_command", "command_type": "set_dropship_approach_path", "team_id": "team_alpha", "fireteam_id": team, "craft_id": "craft_a"})
	var accept: Dictionary = MP_CONTRACT.new().validate({"contract_category": "dropship_command", "command_type": "set_dropship_approach_path", "team_id": "team_alpha", "fireteam_id": team, "craft_id": "craft_a", "approach_path": "tief"})
	check(String(reject.get("reason", "")) == "dropship_approach_path_invalid" and String(missing.get("reason", "")) == "dropship_approach_path_missing" and not String(accept.get("reason", "")).begins_with("dropship_approach_path") and not String(accept.get("reason", "")).contains("whitelisted"), "the network contract rejects an unknown or missing approach path and passes a known one: " + String(accept.get("reason", "accepted")))
	# Command path.
	var bad: bool = bool(controller.call("apply_authoritative_dropship_command", {"command_type": "set_dropship_approach_path", "craft_id": "craft_a", "fireteam_id": team, "approach_path": "senkrecht"}))
	check(not bad and String(controller.get("_current_approach_path")) == "normal", "the controller rejects an unknown approach path and keeps the stored one")
	var good: bool = bool(controller.call("apply_authoritative_dropship_command", {"command_type": "set_dropship_approach_path", "craft_id": "craft_a", "fireteam_id": team, "approach_path": "steil"}))
	check(good and String(_find_card(controller, "craft_a").get("approach_path", "")) == "steil" and String(_find_card(controller, "craft_b").get("approach_path", "normal")) == "normal", "the command stores steil on this craft's card only")
	var saved: Dictionary = controller.call("get_planning_state")
	controller.call("_select_approach_path", "tief")
	controller.call("set_planning_state", saved)
	check(String(controller.get("_current_approach_path")) == "steil" and String(_find_card(controller, "craft_a").get("approach_path", "")) == "steil", "the stored path survives the planning-state round trip like the approach style")
	controller.call("_select_approach_path", "normal")
	# The pilot value belongs to the ship (fighter vs dropship), read through the controller.
	var pilot_id: String = String(env.first_ids[0])
	var pilot: Node = controller.call("_get_campaign_sortie_unit", pilot_id)
	check(pilot != null, "a pilot unit exists in the scenario")
	if pilot != null:
		pilot.set("dropship_piloting", 0.9)
		pilot.set("fighter_piloting", 0.1)
		var state: Dictionary = controller.call("get_planning_state")
		var cards: Array = Array(state.get("mission_drop_cards", []))
		cards[0]["pilot_unit_id"] = pilot_id
		cards.append(_card("craft_j", String(env.teams[0]), env.first_ids, env.hot_lz, "buccaneer", pilot_id))
		state["mission_drop_cards"] = cards
		controller.call("set_planning_state", state)
		controller.call("_select_mission_dropship_craft", "craft_a", false)
		var dropship_skill: float = float(controller.call("_mission_drop_pilot_skill"))
		controller.call("_select_mission_dropship_craft", "craft_j", false)
		var fighter_skill: float = float(controller.call("_mission_drop_pilot_skill"))
		check(is_equal_approx(dropship_skill, 0.9) and is_equal_approx(fighter_skill, 0.1), "the dropship flies with dropship_piloting, the fighter with fighter_piloting: %.2f / %.2f" % [dropship_skill, fighter_skill])
		controller.call("_select_mission_dropship_craft", "craft_a", false)
		controller.call("_set_selected_fireteams", PackedStringArray([team]), false)
	# Card buttons.
	_open_dropship_details(mission, controller)
	for _frame in range(4):
		await process_frame
	var steil_button: Button = _find_path_button(mission, "craft_a", "steil")
	var normal_button: Button = _find_path_button(mission, "craft_a", "normal")
	var tief_button: Button = _find_path_button(mission, "craft_a", "tief")
	check(steil_button != null and normal_button != null and tief_button != null, "the dropship card shows a second row with the three approach path buttons")
	if steil_button != null and normal_button != null and tief_button != null:
		check(steil_button.text == "Steil" and normal_button.text == "Normal" and tief_button.text == "Tief", "the buttons read Steil / Normal / Tief")
		var skill: float = float(controller.call("_mission_drop_pilot_skill_for_craft", "craft_a"))
		check(steil_button.tooltip_text == PLAN.path_tooltip("steil", skill) and tief_button.tooltip_text == PLAN.path_tooltip("tief", skill) and normal_button.tooltip_text == PLAN.path_tooltip("normal", skill), "each button tooltip is built from the data and this ship's pilot")
		check(steil_button.tooltip_text.contains("15 %") and tief_button.tooltip_text.contains("25 %") and tief_button.tooltip_text.contains("Gelände"), "the tooltips name the price in numbers from the data: " + tief_button.tooltip_text)
		tief_button.pressed.emit()
		check(String(controller.get("_current_approach_path")) == "tief" and String(_find_card(controller, "craft_a").get("approach_path", "")) == "tief" and String(_find_card(controller, "craft_b").get("approach_path", "normal")) == "normal", "pressing Tief on the card stores the path for this craft only")
		controller.call("_update_ui")
		var refreshed: Button = _find_path_button(mission, "craft_a", "tief")
		check(refreshed != null and bool(refreshed.get_meta("mission_dropship_card_command_active", false)), "the card shows Tief as the active path")
	await _close(env)

func _accident_run(path: String) -> void:
	var env: Dictionary = await _open_mission()
	if not bool(env.ok):
		check(false, path + ": scenario exposes two fireteams")
		await _close(env)
		return
	var mission: Node = env.mission
	var controller: Node = env.controller
	var registry: Node = env.registry
	var team: String = String(env.teams[1])
	controller.call("_select_mission_dropship_craft", "craft_b", false)
	controller.call("_set_selected_fireteams", PackedStringArray([team]), false)
	var chosen: bool = bool(controller.call("apply_authoritative_dropship_command", {"command_type": "set_dropship_approach_path", "craft_id": "craft_b", "fireteam_id": team, "approach_path": path}))
	check(chosen and String(controller.get("_current_approach_path")) == path, path + ": the path is chosen through the command path")
	var base_grid: Vector2i = registry.call("world_to_grid", env.quiet_lz)
	var simulation_root: Node = mission.get_node("SimulationRoot")
	var done := false
	var control_checked := false
	for dx in range(-5, 6):
		for dy in range(-5, 6):
			if done:
				break
			var lz: Vector2 = registry.call("grid_to_world", base_grid + Vector2i(dx, dy))
			controller.set("_lz_position", lz)
			controller.set("_has_lz_position", true)
			# The air defence seed is craft id + the LZ the approach flies to: the field-resolved LZ in a
			# campaign mission, the set LZ itself in a plain mission like this scene.
			var landing_lz: Vector2 = lz
			if bool(controller.call("_should_keep_campaign_dropship_landed")):
				var resolved: Dictionary = controller.call("_resolve_campaign_field_lz")
				if not bool(resolved.get("ok", false)):
					continue
				landing_lz = Vector2(resolved.resolved_lz_position)
			var seed_text: String = "craft_b" + str(landing_lz) + ":air_defense"
			var expected: Dictionary = PLAN.accident_check(path, 0.5, seed_text)
			if not bool(expected.occurred):
				continue
			if not control_checked:
				# Same LZ, path Normal: no roll, no message, no stored status.
				controller.call("_select_approach_path", "normal")
				var calm: bool = bool(controller.call("_resolve_air_defense_on_approach", landing_lz))
				check(calm and String(controller.get("_air_defense_feedback_text")).is_empty(), path + ": the same approach with Normal does not roll an accident")
				controller.call("_select_approach_path", path)
				control_checked = true
			var started: bool = bool(controller.call("_try_start_drop_sequence", true))
			if not started:
				continue
			var text: String = String(controller.get("_last_command_text"))
			var label: String = "Steilflug" if path == "steil" else "Tiefflug"
			print(path, " accident approach: lz=", lz, " text=", text, " expected loss=", expected.hull_loss)
			check(text == "Unfall im %s: Rumpf -%d %%." % [label, int(expected.hull_loss)], path + ": the card sentence names the accident and the hull loss: " + text)
			check(String(_find_card(controller, "craft_b").get("card_feedback_text", "")) == text, path + ": the craft card shows the same sentence")
			check(String(controller.get("_drop_sequence_phase")) == "inbound", path + ": the craft still flies on to its landing after the accident")
			for _frame in range(3):
				await physics_frame
			var status: Dictionary = simulation_root.call("get_air_asset_status_snapshot", "craft_b")
			check(not status.is_empty() and int(status.get("integrity", -1)) == 100 - int(expected.hull_loss), path + ": SimulationRoot stores the hull value 100 - %d: %s" % [int(expected.hull_loss), str(status.get("integrity"))])
			done = true
	check(done, path + ": an LZ with a fixed-seed accident was found and flown")
	await _close(env)

## Tief beside the battery on open ground: nothing hides the Hagel, so the air defence still breaks the approach off.
func _hot_tief_run() -> void:
	var env: Dictionary = await _open_mission()
	if not bool(env.ok):
		check(false, "hot tief: scenario exposes two fireteams")
		await _close(env)
		return
	var controller: Node = env.controller
	var team: String = String(env.teams[0])
	var chosen: bool = bool(controller.call("apply_authoritative_dropship_command", {"command_type": "set_dropship_approach_path", "craft_id": "craft_a", "fireteam_id": team, "approach_path": "tief"}))
	var started: bool = bool(controller.call("_try_start_drop_sequence", true))
	var text: String = String(controller.get("_last_command_text"))
	print("hot tief approach: started=", started, " text=", text)
	check(chosen and not started and text.begins_with("Flugabwehr: Anflug abgebrochen"), "tief on open ground beside the battery is still broken off by the air defence: " + text)
	check(String(_find_card(controller, "craft_a").get("card_feedback_text", "")) == text, "hot tief: the craft card shows the same sentence")
	await _close(env)

func _open_dropship_details(mission: Node, controller: Node) -> void:
	controller.call("_update_ui")
	var details := mission.get_node_or_null("TacticalUI/MissionDropshipPanel/CompactCard/Contents/Header/DetailsButton") as Button
	if details != null:
		details.pressed.emit()

func _find_path_button(node: Node, craft_id: String, path: String, key: String = "mission_dropship_approach_path") -> Button:
	if node is Button and String(node.get_meta(key, "")) == path and String(node.get_meta("mission_dropship_craft_id", "")) == craft_id:
		return node
	for child in node.get_children():
		var found: Button = _find_path_button(child, craft_id, path, key)
		if found != null:
			return found
	return null

func _card(id: String, team: String, units: Array, lz: Vector2, model: String, pilot: String) -> Dictionary:
	var card := {"craft_id": id, "model_id": model, "display_name": id, "payload_source": "homebase_direct", "state": "waiting", "progress": 0.0, "passenger_count": units.size(), "embarked_unit_ids": units, "boarded_fireteam_ids": [team], "has_lz_position": true, "lz_position": lz, "approach_angle": "NW"}
	if not pilot.is_empty():
		card["pilot_unit_id"] = pilot
	return card

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
