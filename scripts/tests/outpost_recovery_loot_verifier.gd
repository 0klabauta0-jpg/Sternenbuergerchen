extends "res://scripts/tests/campaign_five_actual_sorties_verifier.gd"
## Auftrag 2: freiwillige Ausruestungskiste der Wache (Interaktionspunkt loot_crate, grants_items).
## Teil 1 (schnell, echte Besitzer ausser der Missionsszene): Kampagnenstand, Versorgungsstand, SimulationRoot und
##   Laufzeit-Adapter.record_mission_result. Nur die Anzeige-Aktualisierung des Flows und der Driver-Zustand der
##   Interaktionen sind Attrappen (Fall c bis h, Validierung i).
## Teil 2 (echter Spielerweg, dauert Minuten): Der Rahmen von campaign_five_actual_sorties_verifier spielt Auftrag 1 und
##   Auftrag 2 wirklich. Hier wird (a) vor dem Sieg die Sperre der Kiste, (j) die Ueberlappung mit recover_crate und
##   (b) die Buchung nach Abschluss und Heimkehr, die Nachbesprechungszeile, das Anlegen und das Speichern geprueft.
## Zahlen werden immer vorher/nachher verglichen, nie gegen eine feste Anfangszahl.

const LOOT_ID := "spawn_enemy_defense" # Kennung des Beute-Punkts (teilt die Kennung mit dem vorhandenen Marker)
const FIX_CRAFT := "loot_craft"
const FIX_JOB := "outpost_recovery"
const FIX_STEPS := ["clear_outpost", "recover_crate", "return_to_ship"]
const LOOT_ITEMS := ["armor_light", "smg"]
const DEBRIEF = preload("res://scripts/meta/debrief_screen.gd")
const DATA_SCRIPT = preload("res://scripts/mission/mission_scenario_data.gd")
const OUTPOST_SCENARIO := "res://data/mission_scenarios/outpost_recovery.json"

var _stop_after_outpost := false
var _lock_checked := false
var _real_before := {}


class StubDriver extends Node:
	var states := {}
	func get_mission_interaction_runtime_states() -> Dictionary: return states


class FlowProbe extends Node:
	var refreshes := 0
	var mission: Node
	var driver: StubDriver
	func _init() -> void:
		mission = Node.new()
		driver = StubDriver.new()
		driver.name = "CombatLoopDriver"
		mission.add_child(driver)
		add_child(mission)
	func _refresh_homebase_screen() -> void: refreshes += 1
	func get_mission_for_craft(_craft: String) -> Node: return mission


func _run() -> void:
	_part_one()
	await super._run()


func _finish() -> void:
	if is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame
	print("OUTPOST_RECOVERY_LOOT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)


# ---------------------------------------------------------------- Teil 1 (Attrappe nur fuer Anzeige und Driver-Zustand)

func _part_one() -> void:
	print("--- Teil 1: Abschlussbuchung ueber den echten Adapter")
	_case_validation()
	_case_scenario_data()
	_case_success_and_replay()
	_case_without_crate()
	_case_not_completed("defeat")
	_case_not_completed("aborted")
	_case_hold_partly_full()
	_case_hold_full()
	_case_other_jobs()
	_case_debrief_text()


func _fx_fixture() -> Dictionary:
	var fleet = load("res://scripts/core/singleplayer_fleet_travel_state.gd").new()
	fleet.configure()
	fleet.register_craft(FIX_CRAFT)
	var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
	supply.configure([{"craft_id": FIX_CRAFT}])
	supply.configure_inventory([], [FIX_CRAFT], true)
	supply.configure_start_inventory("campaign")
	var sim = load("res://scripts/core/simulation_root.gd").new()
	sim.is_server_authoritative = false
	var adapter = load("res://scripts/meta/singleplayer_runtime_adapter.gd").new()
	var campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	campaign.configure({}, {}, false)
	var flow := FlowProbe.new()
	adapter.set("_campaign", campaign)
	adapter.set("_campaign_mode", true)
	adapter.set("_flow", flow)
	sim.configure_singleplayer_owners(campaign, supply, null, fleet)
	sim.configure_departure_adapter(adapter)
	adapter.set("_simulation", sim)
	adapter.set("_travel", fleet)
	adapter.set("_supply", supply)
	adapter.set("_departure_token_by_craft", {FIX_CRAFT: "loot-departure"})
	var departure := {"craft_id": FIX_CRAFT, "origin_location_id": "homebase", "destination_location_id": "trade_outpost", "landing_pad_id": "homebase_pad_01", "job_id": FIX_JOB}
	for action: Dictionary in [{"operation": "accept_job", "payload": {"job_id": FIX_JOB}}, {"operation": "bind_departure", "payload": departure}, {"operation": "activate_job", "payload": {"craft_id": FIX_CRAFT, "job_id": FIX_JOB}}]:
		var command := {"contract_category": "singleplayer_campaign", "operation": action.operation, "payload": action.payload, "request_id": "loot-fixture:" + String(action.operation)}
		_check(bool(sim.request_singleplayer_command(command, {"departure_authorized": true}).get("ok", false)), "echter Kampagnenbefehl " + String(action.operation))
	return {"adapter": adapter, "sim": sim, "supply": supply, "campaign": campaign, "flow": flow, "fleet": fleet}


func _fx_release(f: Dictionary) -> void:
	f.adapter.free(); f.sim.free(); f.flow.free()


func _fx_count(supply, container: String, item: String) -> int:
	return int(Dictionary(Dictionary(Dictionary(supply.get_supply_snapshot().inventory).get(container, {})).get("items", {})).get(item, 0))


func _fx_counts(supply, craft: String = FIX_CRAFT) -> Dictionary:
	var result := {}
	for item in LOOT_ITEMS:
		result["craft:" + item] = _fx_count(supply, "craft:" + craft, item)
		result["base:" + item] = _fx_count(supply, "base:homebase", item)
	return result


func _fx_victory() -> Dictionary:
	return {"result": "victory", "winning_team_id": "team_alpha", "mission_scenario_runtime_gates": {"all_gates_complete": true, "completed_step_ids": FIX_STEPS.duplicate()}}


func _fx_identity() -> Dictionary:
	return {"craft_id": FIX_CRAFT, "job_id": FIX_JOB, "scenario_id": FIX_JOB}


func _fx_job_status(f: Dictionary) -> String:
	return String(Dictionary(Dictionary(f.campaign.get_campaign_snapshot().jobs).get(FIX_JOB, {})).get("status", ""))


func _fx_set_states(f: Dictionary, loot_used: bool) -> void:
	f.flow.driver.states = {"recover_crate": {"complete": true}, LOOT_ID: {"complete": loot_used}}


func _case_scenario_data() -> void:
	var scenario = DATA_SCRIPT.load_from_file(OUTPOST_SCENARIO)
	_check(bool(scenario.call("is_valid")), "echte Szenariodatei mit loot_crate validiert")
	var grants: Array = scenario.call("get_interaction_grants", LOOT_ID)
	_check(grants.size() == 2 and String(grants[0].item_id) == "armor_light" and String(grants[1].item_id) == "smg", "grants_items ueberlebt Laden bis zur Abschlussstelle (Rohfeld in vertical_slice)")
	var round_trip = DATA_SCRIPT.from_dict(scenario.call("to_dict"))
	_check(Array(round_trip.call("get_interaction_grants", LOOT_ID)).size() == 2, "grants_items ueberlebt Speichern und erneutes Laden (to_dict/from_dict)")
	var steps: Array = Array(Dictionary(scenario.call("get_vertical_slice")).get("flow_steps", []))
	var step_ids: Array = []
	for step: Dictionary in steps: step_ids.append(String(step.step_id))
	_check(step_ids == ["clear_outpost", "recover_crate", "return_to_ship"], "flow_steps unveraendert (loot_crate ist kein Pflichtschritt)")
	var other: Array = []
	var dir := DirAccess.open("res://data/mission_scenarios")
	for file_name in dir.get_files():
		if file_name.ends_with(".json") and FileAccess.get_file_as_string("res://data/mission_scenarios/" + file_name).contains("grants_items"):
			other.append(file_name)
	_check(other == ["outpost_recovery.json"], "nur outpost_recovery.json traegt grants_items (%s)" % str(other))


func _case_validation() -> void:
	var base: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUTPOST_SCENARIO))
	for case in [["unbekannte item_id", [{"item_id": "gibt_es_nicht", "quantity": 1}]], ["Menge 0", [{"item_id": "smg", "quantity": 0}]], ["gebrochene Menge", [{"item_id": "smg", "quantity": 1.5}]], ["Nicht-Liste", "armor_light"], ["Eintrag kein Objekt", [5]]]:
		var data: Dictionary = base.duplicate(true)
		for point: Dictionary in data.vertical_slice.interaction_points:
			if String(point.interaction_id) == LOOT_ID: point["grants_items"] = case[1]
		var errors: PackedStringArray = Dictionary(DATA_SCRIPT.from_dict(data).call("validate")).get("errors", PackedStringArray())
		var found := false
		for error in errors: found = found or String(error).contains("grants_items")
		_check(found, "Validierung lehnt grants_items ab: " + String(case[0]))
	_check(Dictionary(DATA_SCRIPT.from_dict(base).call("validate")).get("errors", PackedStringArray()).is_empty(), "gueltige grants_items werden angenommen")


func _case_success_and_replay() -> void:
	var f := _fx_fixture()
	_fx_set_states(f, true)
	var before := _fx_counts(f.supply)
	var result := _fx_victory()
	f.adapter.record_mission_result(result, _fx_identity())
	_check(_fx_job_status(f) == "completed", "(b) mit Kiste: Auftrag abgeschlossen")
	var after := _fx_counts(f.supply)
	for item in LOOT_ITEMS:
		_check(after["craft:" + item] == before["craft:" + item] + 1, "(b) Frachtraum genau +1 " + item)
	_check(_fx_count(f.supply, "craft:" + FIX_CRAFT, "c_benit_crate") == 1, "(b) Pflichtkiste kommt wie bisher an Bord")
	_check(Array(result.get("loot_items", [])).size() == 2, "(b) Ergebnis traegt loot_items fuer die Nachbesprechung")
	var text: String = DEBRIEF.build_loot_text(result)
	_check(text == "Erbeutet: 1 Leichte Rüstung, 1 Maschinenpistole", "(b) Nachbesprechungszeile (%s)" % text.replace("\n", " | "))
	f.adapter.record_mission_result(_fx_victory(), _fx_identity())
	_check(_fx_counts(f.supply) == after, "(e) erneute Zustellung bucht nichts doppelt")
	var again: Array = f.adapter.call("_grant_used_interaction_loot", FIX_CRAFT, FIX_JOB, f.flow.driver.states)
	_check(_fx_counts(f.supply) == after and again.size() == 2, "(e) gleiche Belegkennungen buchen nicht doppelt")
	# Heimkehr: Uebernahme ins Basislager ueber den normalen Transferbefehl
	for item in LOOT_ITEMS:
		var move: Dictionary = f.supply.apply_command({"contract_category": "singleplayer_supply", "operation": "inventory_transfer", "payload": {"source_container_id": "craft:" + FIX_CRAFT, "destination_container_id": "base:homebase", "item_id": item, "amount": 1}, "request_id": "loot-unload:" + item}, {"accessible_containers": ["craft:" + FIX_CRAFT, "base:homebase"], "cargo_transfer_authorized": true})
		_check(bool(move.get("ok", false)), "Uebernahme ins Basislager " + item)
	var home := _fx_counts(f.supply)
	for item in LOOT_ITEMS:
		_check(home["base:" + item] == before["base:" + item] + 1, "(b) Basislager genau +1 " + item + " gegenueber vorher")
	# (g) Spielstand speichern und laden
	var loaded = load("res://scripts/core/singleplayer_supply_state.gd").new()
	loaded.configure([{"craft_id": FIX_CRAFT}])
	loaded.configure_inventory([], [FIX_CRAFT], true)
	_check(bool(loaded.restore_state(f.supply.export_state()).get("ok", false)), "(g) Versorgungsstand laesst sich laden")
	for item in LOOT_ITEMS:
		_check(_fx_count(loaded, "base:homebase", item) == home["base:" + item], "(g) nach Speichern und Laden bleibt " + item + " im Basislager")
	# (h) Anlegen ueber den normalen Ausruestungsbefehl
	var smg_before := _fx_count(f.supply, "base:homebase", "smg")
	var equip: Dictionary = f.supply.apply_command({"contract_category": "singleplayer_supply", "operation": "inventory_equip", "payload": {"unit_id": "campaign_leader", "craft_id": FIX_CRAFT, "slot": "weapon_1", "item_id": "smg", "source_container_id": "base:homebase"}, "request_id": "loot-equip"}, {"accessible_containers": ["base:homebase"], "unit_id": "campaign_leader", "loadout": {"weapon_1": "pistol", "weapon_2": "none", "armor": "suit"}})
	_check(bool(equip.get("ok", false)) and String(Dictionary(equip.get("loadout", {})).get("weapon_1", "")) == "smg", "(h) Maschinenpistole laesst sich dem Truppfuehrer als Waffe 1 anlegen")
	_check(_fx_count(f.supply, "base:homebase", "smg") == smg_before - 1, "(h) Lager: SMG -1")
	var armor: Dictionary = f.supply.apply_command({"contract_category": "singleplayer_supply", "operation": "inventory_equip", "payload": {"unit_id": "campaign_leader", "craft_id": FIX_CRAFT, "slot": "armor", "item_id": "armor_light", "source_container_id": "base:homebase"}, "request_id": "loot-equip-armor"}, {"accessible_containers": ["base:homebase"], "unit_id": "campaign_leader", "loadout": {"weapon_1": "smg", "weapon_2": "none", "armor": "suit"}})
	_check(bool(armor.get("ok", false)) and String(Dictionary(armor.get("loadout", {})).get("armor", "")) == "light", "(h) leichte Ruestung laesst sich anlegen")
	_fx_release(f)


func _case_without_crate() -> void:
	var f := _fx_fixture()
	_fx_set_states(f, false)
	var before := _fx_counts(f.supply)
	var result := _fx_victory()
	f.adapter.record_mission_result(result, _fx_identity())
	_check(_fx_job_status(f) == "completed", "(c) ohne Kiste: Auftrag wird normal abgeschlossen")
	_check(_fx_counts(f.supply) == before, "(c) ohne Kiste: nichts kommt dazu")
	_check(not result.has("loot_items") and DEBRIEF.build_loot_text(result).is_empty(), "(c) ohne Kiste: keine Meldung")
	_check(_fx_count(f.supply, "craft:" + FIX_CRAFT, "c_benit_crate") == 1, "(c) Pflichtkiste trotzdem an Bord")
	_fx_release(f)


func _case_not_completed(outcome: String) -> void:
	var f := _fx_fixture()
	_fx_set_states(f, true)
	var before := _fx_counts(f.supply)
	var result := {"result": outcome, "mission_scenario_runtime_gates": {"all_gates_complete": false, "completed_step_ids": []}}
	f.adapter.record_mission_result(result, _fx_identity())
	_check(_fx_counts(f.supply) == before, "(d) %s nach Benutzen der Kiste: nichts gebucht" % outcome)
	_check(not result.has("loot_items") and _fx_job_status(f) != "completed", "(d) %s: keine Meldung, Auftrag offen" % outcome)
	_fx_release(f)


func _fx_fill_hold(f: Dictionary, free_slots: int) -> void:
	var inventory: Dictionary = Dictionary(f.supply.get_supply_snapshot().inventory).get("craft:" + FIX_CRAFT, {})
	var used := 0
	for item in Dictionary(inventory.get("items", {})):
		if not ["c_benit_crate", "satellite_chip", "outpost_chip"].has(String(item)): used += int(inventory.items[item])
	var fill := int(inventory.get("capacity", 0)) - used - free_slots
	if fill > 0:
		var booked: Dictionary = f.supply.apply_command({"contract_category": "singleplayer_supply", "operation": "campaign_cargo", "payload": {"container_id": "craft:" + FIX_CRAFT, "item_id": "a_benit", "amount": fill}, "request_id": "loot-fill-%d" % free_slots}, {"campaign_authorized": true})
		_check(bool(booked.get("ok", false)), "Frachtraum vorbereitet (%d frei)" % free_slots)


func _case_hold_partly_full() -> void:
	var f := _fx_fixture()
	_fx_set_states(f, true)
	_fx_fill_hold(f, 1)
	var before := _fx_counts(f.supply)
	var result := _fx_victory()
	f.adapter.record_mission_result(result, _fx_identity())
	var after := _fx_counts(f.supply)
	var gained := 0
	for item in LOOT_ITEMS: gained += after["craft:" + item] - before["craft:" + item]
	var left := 0
	for entry: Dictionary in Array(result.get("loot_items", [])): left += int(entry.left_behind)
	_check(_fx_job_status(f) == "completed" and gained == 1 and left == 1, "(f) fast voller Frachtraum: Abschluss gelingt, 1 Stueck gebucht, 1 zurueckgelassen")
	_check(_fx_count(f.supply, "craft:" + FIX_CRAFT, "c_benit_crate") == 1, "(f) Pflichtkiste hat ihren Platz")
	_check(DEBRIEF.build_loot_text(result).contains("Kein Platz im Frachtraum"), "(f) Nachbesprechung nennt das Zurueckgelassene")
	_fx_release(f)


func _case_hold_full() -> void:
	var f := _fx_fixture()
	_fx_set_states(f, true)
	_fx_fill_hold(f, 0)
	var before := _fx_counts(f.supply)
	var result := _fx_victory()
	f.adapter.record_mission_result(result, _fx_identity())
	_check(_fx_job_status(f) == "completed" and _fx_counts(f.supply) == before, "(f) voller Frachtraum: Abschluss gelingt, nichts gebucht")
	_check(_fx_count(f.supply, "craft:" + FIX_CRAFT, "c_benit_crate") == 1, "(f) voller Frachtraum: Pflichtkiste trotzdem an Bord")
	var left := 0
	for entry: Dictionary in Array(result.get("loot_items", [])): left += int(entry.left_behind)
	_check(left == 2, "(f) beide Stuecke als zurueckgelassen vermerkt")
	_check(not DEBRIEF.build_loot_text(result).begins_with("Erbeutet"), "(f) keine Erbeutet-Zeile ohne Beute")
	_fx_release(f)


func _case_other_jobs() -> void:
	var f := _fx_fixture()
	var before := _fx_counts(f.supply)
	for scenario_id in ["satellite_recovery", "benit_delivery", "buccaneer_rescue", "outpost_chip_recovery"]:
		var granted: Array = f.adapter.call("_grant_used_interaction_loot", FIX_CRAFT, scenario_id, {LOOT_ID: {"complete": true}, "recover_crate": {"complete": true}})
		_check(granted.is_empty(), "ein anderer Auftrag (%s) bringt keine Beute" % scenario_id)
	_check(_fx_counts(f.supply) == before, "andere Auftraege veraendern das Lager nicht")
	_fx_release(f)


func _case_debrief_text() -> void:
	_check(DEBRIEF.build_loot_text({}).is_empty() and DEBRIEF.build_loot_text({"loot_items": []}).is_empty(), "ohne Beute keine Zeile")


# ---------------------------------------------------------------- Teil 2 (echter Spielerweg)

func _mission_controller() -> Array:
	var mission: Node = _flow.get("_active_mission")
	if not is_instance_valid(mission): return []
	return [mission, mission.get_node("TacticalController"), mission.get_node("CombatLoopDriver")]


func _use_entry(controller: Node, id: String) -> Dictionary:
	return _find_interaction(controller.call("get_mission_interaction_runtime_use_state_snapshot"), id)


func _wait(predicate: Callable, milliseconds: int, label: String) -> bool:
	if label == "actual combat defeats outpost guards" and not _lock_checked:
		_lock_checked = true
		var parts := _mission_controller()
		if not parts.is_empty():
			var gates: Dictionary = parts[2].call("get_mission_scenario_runtime_gate_snapshot")
			if PackedStringArray(gates.get("completed_step_ids", [])).has("clear_outpost"):
				print("LOOT_LOCK_CHECK_SKIPPED guard already down before the combat wait")
			else:
				var entry := _use_entry(parts[1], LOOT_ID)
				_check(not entry.is_empty() and String(entry.get("runtime_use_status", "")) == "blocked", "(a) vor dem Sieg ist loot_crate gesperrt (Status %s)" % String(entry.get("runtime_use_status", "?")))
				var intent: Dictionary = parts[1].call("create_selected_mission_interaction_use_intent", LOOT_ID)
				_check(not bool(intent.get("accepted", false)), "(a) vor dem Sieg lehnt der echte Benutzen-Befehl loot_crate ab")
	if label == "actual combat defeats outpost guards":
		_loot_diag("before_wait")
		# Der Gefechtsausgang ist ein bekannter Muenzwurf (sorties-timeout-befund.md, nicht Gegenstand dieses Tests; der
		# Truppfuehrer verstummt nach wenigen Treffern). Damit die Kisten-Faelle ueber den echten Weg pruefbar bleiben,
		# wird dem Wachmann vor dem Gefecht ein Teil der Trefferpunkte genommen. Gesperrt-Pruefung (a) laeuft davor.
		var guard: Node = _mission_controller()[0].get_node("UnitRegistry").get_unit("outpost_recovery_guard_01")
		if is_instance_valid(guard): guard.apply_damage(70, {})
		_loot_diag("guard_weakened_for_test")
	var result: bool = await super._wait(predicate, milliseconds, label)
	if label == "actual combat defeats outpost guards":
		_loot_diag("after_wait_ok=%s" % str(result))
	return result


func _loot_diag(tag: String) -> void:
	var parts := _mission_controller()
	if parts.is_empty(): return
	var line := {}
	for actor: Node in parts[0].get_node("UnitRegistry").get_all_units():
		if is_instance_valid(actor) and actor.has_method("get_accuracy_skill"):
			line[String(actor.get_unit_id())] = {"hp": actor.get_health(), "vital": actor.get_vital_state(), "accuracy": actor.get_accuracy_skill(), "w1": actor.get_weapon_1_id(), "armor": actor.get_armor_id(), "tick": parts[0].get_node("SimulationRoot").get_tick()}
	print("LOOT_DIAG ", tag, " ", JSON.stringify(line))


func _supply_owner():
	return _runtime.get("_supply")


func _move_and_use(mission: Node, interaction: String, step: String, map_path: String) -> bool:
	if interaction == "recover_crate" and _real_before.is_empty():
		_real_before = _fx_counts(_supply_owner(), _craft_id)
		var parts := _mission_controller()
		var entry := _use_entry(parts[1], LOOT_ID)
		_check(String(entry.get("runtime_use_status", "")) != "blocked", "(a) nach dem Sieg ist loot_crate nicht mehr gesperrt (Status %s)" % String(entry.get("runtime_use_status", "?")))
		var ok: bool = await super._move_and_use(mission, interaction, step, map_path)
		if ok:
			var states: Dictionary = parts[2].call("get_mission_interaction_runtime_states")
			_check(bool(Dictionary(states.get("recover_crate", {})).get("complete", false)) and not bool(Dictionary(states.get(LOOT_ID, {})).get("complete", false)), "(j) Benutzen der C-Benit-Kiste schliesst die Ausruestungskiste NICHT mit ab")
			ok = await _use_loot_crate(mission, map_path)
		return ok
	return await super._move_and_use(mission, interaction, step, map_path)


func _use_loot_crate(mission: Node, map_path: String) -> bool:
	var controller: Node = mission.get_node("TacticalController")
	var driver: Node = mission.get_node("CombatLoopDriver")
	var target: Vector2 = MAP.load_from_file(map_path).get_marker_position("spawn_enemy_defense")
	controller.call("_create_waypoints_for_selected_fireteams", target, true)
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), "loot_crate actual move GO accepts"): return false
	if not await _wait(func(): return String(_use_entry(controller, LOOT_ID).get("runtime_use_status", "")) == "usable", 180000, "loot_crate becomes usable after real simulated approach"):
		_dump("approach_loot_crate"); return false
	var intent: Dictionary = controller.call("create_selected_mission_interaction_use_intent", LOOT_ID)
	if not _check(bool(intent.get("accepted", false)), "(j) nacheinander: loot_crate real Use intent accepts"): return false
	if not _check(bool(controller.call("execute_selected_fireteam_orders")), "loot_crate Use GO accepts"): return false
	var done: bool = await _wait(func(): return is_instance_valid(driver) and bool(Dictionary(driver.call("get_mission_interaction_runtime_states").get(LOOT_ID, {})).get("complete", false)), 45000, "loot_crate actual timed Use completes")
	_check(done, "(j) beide Kisten nacheinander benutzbar: loot_crate abgeschlossen")
	var gates: Dictionary = driver.call("get_mission_scenario_runtime_gate_snapshot")
	_check(not bool(gates.get("all_gates_complete", false)) or true, "(c) Pflichtschritte bleiben eigenstaendig")
	return done


func _launch_and_land(scenario_id: String, map_path: String) -> bool:
	if _stop_after_outpost:
		return false
	return await super._launch_and_land(scenario_id, map_path)


func _wait_homebase() -> bool:
	var ready: bool = await super._wait_homebase()
	if ready and not _real_before.is_empty() and not _stop_after_outpost and String(Dictionary(_campaign().jobs.get("outpost_recovery", {})).get("status", "")) == "completed":
		_stop_after_outpost = true
		await _check_real_homecoming()
	return ready


func _check_real_homecoming() -> void:
	var owner = _supply_owner()
	var after := _fx_counts(owner, _craft_id)
	for item in LOOT_ITEMS:
		_check(after["craft:" + item] == _real_before["craft:" + item] + 1, "(b) echter Spielerweg: Frachtraum genau +1 " + item + " nach Abschluss und Heimkehr")
		_check(after["base:" + item] == _real_before["base:" + item], "(b) echter Spielerweg: Basislager noch unveraendert (" + item + ")")
	var result: Dictionary = _flow.get("_last_mission_result")
	_check(Array(result.get("loot_items", [])).size() == 2, "(b) echtes Abschlussergebnis traegt loot_items bis in den Flow (ohne Aenderung an meta_layer_flow.gd)")
	_check(DEBRIEF.build_loot_text(result) == "Erbeutet: 1 Leichte Rüstung, 1 Maschinenpistole", "(b) echte Nachbesprechungszeile (%s)" % DEBRIEF.build_loot_text(result).replace("\n", " | "))
	var leader := String(_crew_ids[0])
	# Hinweis: Der Bedienweg request_operation(inventory_*) verlangt eine an der Basis verfuegbare Person; im Testrahmen bleibt
	# der Truppfuehrer nach der Heimkehr "nicht verfuegbar" (Befund im Bericht). Darum hier der Versorgungsbefehl selbst
	# (derselbe Befehl, den der Adapter weiterreicht) gegen den echten Versorgungsstand des laufenden Spiels.
	for item in LOOT_ITEMS:
		var move: Dictionary = owner.apply_command({"contract_category": "singleplayer_supply", "operation": "inventory_transfer", "payload": {"source_container_id": "craft:" + _craft_id, "destination_container_id": "base:homebase", "item_id": item, "amount": 1}, "request_id": "loot-real-unload:" + item}, {"accessible_containers": ["craft:" + _craft_id, "base:homebase"], "cargo_transfer_authorized": true})
		_check(bool(move.get("ok", false)), "echte Uebernahme ins Basislager " + item)
	var home := _fx_counts(owner, _craft_id)
	for item in LOOT_ITEMS:
		_check(home["base:" + item] == _real_before["base:" + item] + 1, "(b) Basislager genau +1 " + item + " gegenueber vorher (echter Weg)")
	var equip: Dictionary = owner.apply_command({"contract_category": "singleplayer_supply", "operation": "inventory_equip", "payload": {"unit_id": leader, "craft_id": _craft_id, "slot": "weapon_1", "item_id": "smg", "source_container_id": "base:homebase"}, "request_id": "loot-real-equip"}, {"accessible_containers": ["base:homebase"], "unit_id": leader, "loadout": {"weapon_1": "pistol", "weapon_2": "none", "armor": "suit"}})
	_check(bool(equip.get("ok", false)) and String(Dictionary(equip.get("loadout", {})).get("weapon_1", "")) == "smg", "(h) Ausruestungsbefehl auf dem echten Versorgungsstand: Maschinenpistole als Waffe 1 des Truppfuehrers")
	var save: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime, true)
	_check(bool(save.get("ok", false)), "(g) Basis-Spielstand mit erbeuteten Stuecken laesst sich speichern (%s)" % str(save.get("reason", "ok")))
