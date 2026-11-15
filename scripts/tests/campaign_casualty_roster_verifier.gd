extends "res://scripts/tests/campaign_casualty_apply_verifier.gd"
## Task 6b (Ausfall und Rueckzug): Gefallene verlassen den Kader, ein Truppfuehrer rueckt nach, die Gefallenenliste bekommt den Eintrag.
## Echte Meta-Szene (Kampagne bzw. Skirmish) mit einem Kader aus vier Personen, die auch die Basis-Personalliste, die Trupps,
## die Ausruestung und das Inventar kennen: A (Truppfuehrer, Platz 0, Lead von ft1), Pilot (Platz 1), B (Truppfuehrer, ft1), C (Schuetze, allein in ft2).
## Z1: Schuetze C stirbt: fehlt ueberall, ft2 ist aufgeloest, Stand gueltig, Eintrag in der Liste.
## Z2: A (Platz 0, Lead) stirbt: B rueckt auf Platz 0, der Pilot bleibt auf Platz 1, B ist Lead von ft1.
## Z3: Einmaligkeit: dasselbe Ergebnis noch zweimal angewendet aendert nichts.
## Z4: Speichern, Meta-Szene neu aufbauen, Fortsetzen: Tote bleiben weg, die Liste am neuen Adapter ist erhalten, niemand doppelt.
## Z5: Absicherung: Tote wuerden den Kader ungueltig machen (beide Truppfuehrer bzw. der Pilot): nichts wird entfernt.
## Z6: Verwundete und Tote im selben Ergebnis.   Z7: Totalverlust und Skirmish: niemand entfernt.   Z8: keine Toten: nichts aendert sich.
## Z9: Nachruecken ueberspringt Personen ohne Fuehrung, die vor dem Truppfuehrer im Kader stehen.
## Einzeln starten: Umgebungsvariable T6B_ONLY (zum Beispiel "Z4") oder Kommandozeilenargument nach "--" (zum Beispiel "-- Z4"); ohne Angabe laufen alle.

const STORE_6B = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const LEAD_A := "campaign_leader"
const PILOT_ID := "campaign_pilot"
const LEAD_B := "t6b_lead_b"
const SHOOTER_C := "t6b_shooter_c"
const NAME_B := "Berta Brandt"
const NAME_C := "Cora Conrad"
const JOB_6B := "satellite_recovery"
const LOCATION_6B := "satellite_crash"

func _run() -> void:
	_configure_entry()
	var selected: Array = _t6b_selected()
	for scenario: String in ["Z1", "Z2", "Z3", "Z4", "Z5", "Z6", "Z7", "Z8", "Z9"]:
		if not selected.is_empty() and not selected.has(scenario):
			continue
		print("--- ", scenario)
		await call("_t6b_" + scenario.to_lower())
		await _end_sortie()
	print("CAMPAIGN_CASUALTY_ROSTER passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _t6b_selected() -> Array:
	var result: Array = []
	var env: String = OS.get_environment("T6B_ONLY").strip_edges().to_upper()
	if not env.is_empty():
		result.append(env)
	for arg: String in OS.get_cmdline_user_args():
		var upper: String = arg.strip_edges().to_upper()
		if upper.begins_with("Z"):
			result.append(upper)
	return result

# ---------- Aufbau ----------

func _t6b_open(mode: String, action: String) -> bool:
	START.request_start(self, mode, action)
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	return _check(_flow != null and _screen != null and _runtime != null, "%s/%s: Szene, Basisansicht und Laufzeit sind da" % [mode, action])

func _t6b_base() -> Node:
	return _runtime.call("get_base_personnel_runtime") if _runtime != null else null

func _t6b_base_ids() -> Array:
	var ids: Array = []
	var base: Node = _t6b_base()
	if base != null:
		for person: Dictionary in Array(Dictionary(base.call("get_snapshot")).get("units", [])):
			ids.append(String(person.get("unit_id", "")))
	ids.sort()
	return ids

func _t6b_roster_ids() -> Array:
	var ids: Array = []
	for unit: Dictionary in Array(_flow.get("_all_team_units")):
		ids.append(String(unit.get("unit_id", "")))
	return ids

## Kampagnenstart mit vier Personen (A, Pilot, B, C), alle auch in Basis, Trupps, Ausruestung und Inventar.
func _t6b_new_four() -> bool:
	if not await _t6b_open("campaign", "new"):
		return false
	var template: Dictionary = _roster_unit(LEAD_A).duplicate(true)
	if not _check(not template.is_empty(), "Aufbau: Truppfuehrer A ist im Kader"):
		return false
	for spec: Array in [[LEAD_B, NAME_B, true], [SHOOTER_C, NAME_C, false]]:
		var profile: Dictionary = template.duplicate(true)
		profile["unit_id"] = spec[0]
		profile["display_name"] = spec[1]
		profile["fireteam_id"] = ""
		profile["roster_role_category"] = "operator"
		profile["role_name"] = "Fireteam Leader" if bool(spec[2]) else "Rifleman"
		if not bool(spec[2]):
			# Der Schuetze fuehrt nicht: er kommt als Nachfolger auf Platz 0 nie in Frage.
			profile["skill_leadership"] = 0.0
			if typeof(profile.get("skill_values")) == TYPE_DICTIONARY:
				profile["skill_values"]["leadership"] = 0.0
		var added: Dictionary = _flow.call("register_campaign_recruit", profile)
		if not _check(bool(added.get("ok", false)), "Aufbau: %s kommt in den Kader (%s)" % [spec[1], added]):
			return false
		var simulation: Node = _runtime.get("_simulation")
		simulation.call("request_personnel_loadout_command", "configure_roster", {"roster": [profile]})
		simulation.call("request_personnel_loadout_command", "set_loadout", {"unit_id": spec[0], "loadout": {"armor": "suit", "weapon_1": "pistol", "weapon_2": "medictool"}})
	# Inventar: jede neue Person hat einen Rucksack, der von C ist nicht leer.
	var supply: RefCounted = _runtime.get("_supply")
	supply.call("configure_inventory", [LEAD_B, SHOOTER_C], [], true)
	var bag: Dictionary = Dictionary(supply.get("_inventory"))["unit:%s:backpack" % SHOOTER_C]
	bag["capacity"] = 12
	Dictionary(bag["items"])["mining_tool"] = 1
	# Trupps: ft1 = A (Lead) + B, ft2 = C allein.
	var added_team: Dictionary = _screen.call("request_operation", "add_fireteam", {})
	if not _check(bool(added_team.get("ok", false)), "Aufbau: zweiter Trupp angelegt (%s)" % added_team):
		return false
	var team_one: String = ""
	for team: Dictionary in Array(Dictionary(_screen.call("get_operations_snapshot")).get("fireteams", [])):
		if team_one.is_empty() and Array(team.get("members", [])).has(LEAD_A) or (team_one.is_empty() and not Array(team.get("members", [])).is_empty()):
			team_one = String(team.id)
	_team_id = team_one
	var team_two: String = ""
	for team: Dictionary in Array(Dictionary(_screen.call("get_operations_snapshot")).get("fireteams", [])):
		if String(team.id) != team_one:
			team_two = String(team.id)
	if not _check(not team_one.is_empty() and not team_two.is_empty(), "Aufbau: zwei Trupps (%s, %s)" % [team_one, team_two]):
		return false
	var to_one: Dictionary = _screen.call("request_operation", "assign", {"unit_id": LEAD_B, "fireteam_id": team_one})
	var to_two: Dictionary = _screen.call("request_operation", "assign", {"unit_id": SHOOTER_C, "fireteam_id": team_two})
	if not _check(bool(to_one.get("ok", false)) and bool(to_two.get("ok", false)), "Aufbau: B in den ersten, C in den zweiten Trupp (%s / %s)" % [to_one, to_two]):
		return false
	_flow.set("_active_singleplayer_identity", {"job_id": JOB_6B, "location_id": LOCATION_6B, "craft_id": String(Dictionary(Array(_flow.get("_homebase_aircraft_definitions"))[0]).get("craft_id", ""))})
	_flow.call("_sync_wound_lock")
	return true

func _t6b_payload() -> Dictionary:
	var captured: Dictionary = Dictionary(_flow.get("_campaign_start").call("capture_home_checkpoint", _flow, _runtime))
	if not bool(captured.get("ok", false)):
		print("T6B_CAPTURE_FAILED ", captured)
		return {}
	return Dictionary(captured.get("payload", {}))

func _t6b_payload_base_ids(payload: Dictionary) -> Array:
	var base: Dictionary = Dictionary(payload.get("base_personnel", Dictionary(payload.get("hex_tactical", {})).get("base_personnel", {})))
	var ids: Array = Dictionary(base.get("units", {})).keys()
	ids.sort()
	return ids

## Alle Stellen im Kampagnenstand und im Spiel, an denen die Person noch haengt (leer = ueberall weg).
func _t6b_where(payload: Dictionary, unit_id: String) -> Array:
	var found: Array = []
	for unit: Dictionary in Array(payload.get("roster", [])):
		if String(unit.get("unit_id", "")) == unit_id: found.append("roster")
	if _t6b_payload_base_ids(payload).has(unit_id): found.append("base_personnel")
	var craft: Dictionary = Dictionary(payload.get("craft", {}))
	if Array(craft.get("staged_unit_ids", [])).has(unit_id): found.append("craft.staged_unit_ids")
	if Dictionary(craft.get("member_loadouts", {})).has(unit_id): found.append("craft.member_loadouts")
	if String(craft.get("pilot_id", "")) == unit_id: found.append("craft.pilot_id")
	for definition: Dictionary in Array(craft.get("fireteam_definitions", [])):
		for field: String in ["member_unit_ids", "members"]:
			if Array(definition.get(field, [])).has(unit_id): found.append("fireteam %s.%s" % [definition.get("id"), field])
		if String(definition.get("lead_unit_id", "")) == unit_id: found.append("fireteam %s.lead_unit_id" % definition.get("id"))
		if Dictionary(definition.get("member_loadouts", {})).has(unit_id): found.append("fireteam %s.member_loadouts" % definition.get("id"))
	if Dictionary(Dictionary(payload.get("supply", {})).get("inventory", {})).has("unit:%s:backpack" % unit_id): found.append("supply.inventory")
	# Der laufende Flow, nicht nur der gebaute Stand.
	for unit: Dictionary in Array(_flow.get("_available_team_units")):
		if String(unit.get("unit_id", "")) == unit_id: found.append("flow._available_team_units")
	if _t6b_base_ids().has(unit_id): found.append("base runtime")
	if PackedStringArray(_flow.get("_homebase_staged_unit_ids")).has(unit_id): found.append("flow._homebase_staged_unit_ids")
	if PackedStringArray(_flow.get("_selected_unit_ids")).has(unit_id): found.append("flow._selected_unit_ids")
	if Dictionary(_runtime.get("_simulation").call("get_personnel_loadout_state").call("get_snapshot")).has(unit_id): found.append("loadout state")
	if Dictionary(_flow.get("_assigned_aircraft_pilot_by_craft")).values().has(unit_id): found.append("flow pilot assignment")
	return found

func _t6b_team(payload: Dictionary, team_id: String) -> Dictionary:
	for definition: Dictionary in Array(Dictionary(payload.get("craft", {})).get("fireteam_definitions", [])):
		if String(definition.get("id", "")) == team_id:
			return definition
	return {}

func _t6b_team_ids(payload: Dictionary) -> Array:
	var ids: Array = []
	for definition: Dictionary in Array(Dictionary(payload.get("craft", {})).get("fireteam_definitions", [])):
		ids.append(String(definition.get("id", "")))
	return ids

## Ein Ergebnis wie am Missionsende, gebaut aus den echten Regeln und dem Kader des Flows.
func _t6b_result(states: Array, outcome: String) -> Dictionary:
	var rules: Dictionary = CASUALTY_RULES.load_rules()
	var pilot_id: String = String(Dictionary(_flow.get("_assigned_aircraft_pilot_by_craft")).values()[0])
	var resolved: Dictionary = CASUALTY_RULES.resolve_mission(states, outcome, Array(_flow.get("_all_team_units")), pilot_id, rules)
	return {"mission_outcome": outcome, "result": "victory" if outcome == "won" else outcome, "team_states": states, "casualties": resolved.casualties, "fatality_unit_ids": resolved.fatality_unit_ids, "casualty_total_loss": resolved.total_loss}

func _t6b_states(vitals: Dictionary) -> Array:
	var states: Array = []
	for unit_id: String in [LEAD_A, PILOT_ID, LEAD_B, SHOOTER_C]:
		var vital: String = String(vitals.get(unit_id, "fit"))
		states.append(_state(unit_id, vital, vital == "bleedout"))
	return states

func _t6b_lock() -> Dictionary:
	var base: Node = _t6b_base()
	return Dictionary(base.get("_unavailable_unit_reasons")).duplicate(true) if base != null else {}

# ---------- Szenarien ----------

func _t6b_z1() -> void:
	if not await _t6b_new_four(): return
	var before: Dictionary = _t6b_payload()
	if not _check(not before.is_empty() and bool(STORE_6B.validate_payload(before).get("ok", false)), "Z1: Fixture: Stand mit vier Personen ist gueltig"): return
	_check(_t6b_roster_ids() == [LEAD_A, PILOT_ID, LEAD_B, SHOOTER_C], "Z1: Fixture: Kader A, Pilot, B, C (%s)" % [_t6b_roster_ids()])
	_check(_t6b_payload_base_ids(before).size() == 4 and _t6b_base_ids().size() == 4, "Z1: Fixture: die Basis kennt alle vier (%s)" % [_t6b_base_ids()])
	_check(not _t6b_where(before, SHOOTER_C).is_empty() and _t6b_where(before, SHOOTER_C).size() >= 8, "Z1: Fixture: C haengt an vielen Stellen (%s)" % [_t6b_where(before, SHOOTER_C)])
	_check(Array(_t6b_team(before, _t6b_team_ids(before)[-1]).get("member_unit_ids", [])) == [SHOOTER_C], "Z1: Fixture: der zweite Trupp besteht nur aus C")
	var states: Array = _t6b_states({SHOOTER_C: "down"})
	var result: Dictionary = _t6b_result(states, "aborted")
	_check(PackedStringArray(result.fatality_unit_ids) == PackedStringArray([SHOOTER_C]) and not bool(result.casualty_total_loss), "Z1: Fixture: die Regeln melden C als tot, kein Totalverlust")
	var applied: Dictionary = _flow.call("_apply_campaign_casualties", result)
	var after: Dictionary = _t6b_payload()
	if not _check(not after.is_empty(), "Z1: Stand nach dem Entfernen laesst sich bauen"): return
	var verdict: Dictionary = STORE_6B.validate_payload(after)
	_check(bool(verdict.get("ok", false)), "Z1: validate_payload des neu gebauten Stands ist ok (%s)" % [verdict])
	var left: Array = _t6b_where(after, SHOOTER_C)
	_check(left.is_empty(), "Z1: C fehlt in Kader, Basis, staged_unit_ids, Trupps, Schiffsausruestung, Inventar und Flow (noch da: %s)" % [left])
	_check(_t6b_roster_ids() == [LEAD_A, PILOT_ID, LEAD_B], "Z1: Kader nun A, Pilot, B (%s)" % [_t6b_roster_ids()])
	_check(_t6b_payload_base_ids(after).size() == 3 and _t6b_payload_base_ids(after) == _t6b_base_ids(), "Z1: Basis-Personalliste hat drei Personen und gleicht dem Stand")
	_check(not _t6b_team_ids(after).has(_t6b_team_ids(before)[-1]) and _t6b_team_ids(after).size() == _t6b_team_ids(before).size() - 1, "Z1: der leere zweite Trupp ist aufgeloest (%s -> %s)" % [_t6b_team_ids(before), _t6b_team_ids(after)])
	var first_team: Dictionary = _t6b_team(after, _t6b_team_ids(before)[0])
	_check(Array(first_team.get("member_unit_ids", [])) == [LEAD_A, LEAD_B] and String(first_team.get("lead_unit_id", "")) == LEAD_A, "Z1: erster Trupp unveraendert A (Lead) und B")
	_check(Array(Array(after.get("craft", {}).get("staged_fireteam_ids", [])).filter(func(id): return not _t6b_team_ids(after).has(id))).is_empty(), "Z1: staged_fireteam_ids nennen nur vorhandene Trupps")
	_check(not Dictionary(Dictionary(_runtime.get("_supply").call("export_state")).get("inventory", {})).has("unit:%s:backpack" % SHOOTER_C), "Z1: der Rucksack mit dem Bergungsgut von C liegt nicht mehr im Spiel (nicht im Basislager)")
	_check(not Dictionary(Dictionary(_runtime.get("_supply").call("export_state")).get("item_quantities", {})).has("mining_tool"), "Z1: kein Uebertrag ins Basislager (item_quantities ohne mining_tool)")
	var fallen: Array = _runtime.call("get_fallen")
	_check(fallen.size() == 1 and fallen[0] == {"unit_id": SHOOTER_C, "display_name": NAME_C, "job_id": JOB_6B, "location_id": LOCATION_6B}, "Z1: genau ein Eintrag mit Name, Auftrag und Ort (%s)" % [fallen])
	_check(Array(after.get("fallen", [])) == fallen, "Z1: der Stand traegt dieselbe Liste")
	_check(PackedStringArray(applied.get("fatality_unit_ids", PackedStringArray())) == PackedStringArray([SHOOTER_C]), "Z1: Ergebnis behaelt fatality_unit_ids")
	var entry: Dictionary = _casualty_entry(applied, SHOOTER_C)
	_check(String(entry.get("outcome", "")) == "dead" and String(entry.get("display_name", "")) == NAME_C, "Z1: Ergebnis behaelt den Namen der Toten in casualties")
	_check(_t6b_lock().is_empty(), "Z1: Einsatzsperre ohne die Tote (%s)" % [_t6b_lock()])

func _t6b_z2() -> void:
	if not await _t6b_new_four(): return
	var before: Dictionary = _t6b_payload()
	var first_id: String = _t6b_team_ids(before)[0]
	_check(String(_t6b_team(before, first_id).get("lead_unit_id", "")) == LEAD_A, "Z2: Fixture: A ist Lead des ersten Trupps")
	var result: Dictionary = _t6b_result(_t6b_states({LEAD_A: "down"}), "aborted")
	_check(PackedStringArray(result.fatality_unit_ids) == PackedStringArray([LEAD_A]) and not bool(result.casualty_total_loss), "Z2: Fixture: die Regeln melden A als tot, kein Totalverlust")
	_flow.call("_apply_campaign_casualties", result)
	var after: Dictionary = _t6b_payload()
	if not _check(not after.is_empty(), "Z2: Stand nach dem Entfernen laesst sich bauen"): return
	var verdict: Dictionary = STORE_6B.validate_payload(after)
	_check(bool(verdict.get("ok", false)), "Z2: validate_payload ist ok (%s)" % [verdict])
	var left: Array = _t6b_where(after, LEAD_A)
	_check(left.is_empty(), "Z2: A fehlt ueberall (noch da: %s)" % [left])
	_check(_t6b_roster_ids() == [LEAD_B, PILOT_ID, SHOOTER_C], "Z2: B auf Platz 0, Pilot auf Platz 1, C danach (%s)" % [_t6b_roster_ids()])
	_check(String(Dictionary(Array(after.roster)[0]).get("unit_id", "")) == LEAD_B and String(Dictionary(Array(after.roster)[1]).get("unit_id", "")) == PILOT_ID, "Z2: im Stand steht B auf Platz 0 und der Pilot auf Platz 1")
	var team: Dictionary = _t6b_team(after, first_id)
	_check(String(team.get("lead_unit_id", "")) == LEAD_B and Array(team.get("member_unit_ids", [])) == [LEAD_B], "Z2: Lead von ft1 ist jetzt das lebende Mitglied B (Lead %s, Mitglieder %s)" % [team.get("lead_unit_id"), team.get("member_unit_ids")])
	var fallen: Array = _runtime.call("get_fallen")
	var entry: Dictionary = Dictionary(fallen[0]) if fallen.size() == 1 else {}
	_check(String(entry.get("unit_id", "")) == LEAD_A and String(entry.get("display_name", "")) == "Anja Voss", "Z2: A steht mit Namen in der Gefallenenliste (%s)" % [fallen])
	_check(String(entry.get("job_id", "")) == JOB_6B and String(entry.get("location_id", "")) == LOCATION_6B, "Z2: Eintrag traegt Auftrag und Ort")

func _t6b_z3() -> void:
	if not await _t6b_new_four(): return
	var result: Dictionary = _t6b_result(_t6b_states({SHOOTER_C: "down"}), "aborted")
	var first: Dictionary = _flow.call("_apply_campaign_casualties", result)
	var roster_once: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	var available_once: Array = Array(_flow.get("_available_team_units")).duplicate(true)
	var base_once: Array = _t6b_base_ids()
	var payload_once: Dictionary = _t6b_payload()
	var fallen_once: Array = _runtime.call("get_fallen")
	var second: Dictionary = _flow.call("_apply_campaign_casualties", result)
	var third: Dictionary = _flow.call("_apply_campaign_casualties", result)
	_check(Array(_flow.get("_all_team_units")) == roster_once and Array(_flow.get("_available_team_units")) == available_once, "Z3: zweite und dritte Anwendung aendern den Kader nicht")
	_check(_t6b_base_ids() == base_once, "Z3: Basis-Personalliste bleibt")
	var payload_thrice: Dictionary = _t6b_payload()
	_check(JSON.stringify(Dictionary(payload_once.get("craft", {})), "", true) == JSON.stringify(Dictionary(payload_thrice.get("craft", {})), "", true) and Array(payload_once.get("roster", [])) == Array(payload_thrice.get("roster", [])), "Z3: Trupps, Schiffsausruestung und Kader im Stand bleiben")
	var fallen: Array = _runtime.call("get_fallen")
	_check(fallen.size() == 1 and fallen == fallen_once, "Z3: get_fallen hat weiter genau einen Eintrag je Toter (%s)" % [fallen])
	_check(PackedStringArray(first.get("fatality_unit_ids", PackedStringArray())) == PackedStringArray(second.get("fatality_unit_ids", PackedStringArray())) and PackedStringArray(third.get("fatality_unit_ids", PackedStringArray())) == PackedStringArray([SHOOTER_C]), "Z3: das Ergebnis meldet bei jeder Anwendung dieselbe Tote")
	_check(String(_casualty_entry(third, SHOOTER_C).get("outcome", "")) == "dead", "Z3: casualties der dritten Anwendung nennen die Tote weiter")
	_check(bool(STORE_6B.validate_payload(payload_thrice).get("ok", false)), "Z3: Stand weiter gueltig")

func _t6b_z4() -> void:
	if not await _t6b_new_four(): return
	# A (Platz 0, Lead) und C (allein in ft2) sterben im selben Ergebnis; B bleibt als einziger Truppfuehrer.
	var result: Dictionary = _t6b_result(_t6b_states({LEAD_A: "down", SHOOTER_C: "down"}), "aborted")
	_check(PackedStringArray(result.fatality_unit_ids).size() == 2 and not bool(result.casualty_total_loss), "Z4: Fixture: zwei Tote, kein Totalverlust (%s)" % [result.fatality_unit_ids])
	_flow.call("_apply_campaign_casualties", result)
	var before_save: Dictionary = _t6b_payload()
	var team_ids_before: Array = _t6b_team_ids(before_save)
	var fallen_before: Array = _runtime.call("get_fallen")
	_check(fallen_before.size() == 2, "Z4: vor dem Speichern zwei Eintraege (%s)" % [fallen_before])
	var saved: Dictionary = _flow.call("request_campaign_save")
	print("Z4_SAVE ok=", saved.get("ok", false), " reason=", saved.get("reason", ""))
	if not _check(bool(saved.get("ok", false)), "Z4: Speichern gelingt (%s)" % [saved.get("reason", "")]): return
	await _end_sortie()
	await create_timer(0.5).timeout
	if not await _t6b_open("campaign", "continue"): return
	var after: Dictionary = _t6b_payload()
	if not _check(not after.is_empty(), "Z4: Stand nach dem Fortsetzen laesst sich bauen"): return
	var roster_ids: Array = _t6b_roster_ids()
	_check(roster_ids == [LEAD_B, PILOT_ID], "Z4: nach dem Fortsetzen Kader B, Pilot (%s)" % [roster_ids])
	for gone: String in [LEAD_A, SHOOTER_C]:
		var left: Array = _t6b_where(after, gone)
		_check(left.is_empty(), "Z4: %s ist nach dem Fortsetzen weiter weg (noch da: %s)" % [gone, left])
	var distinct: Dictionary = {}
	for id: String in roster_ids:
		distinct[id] = true
	_check(distinct.size() == roster_ids.size() and _t6b_base_ids().size() == 2 and _t6b_payload_base_ids(after).size() == 2, "Z4: niemand doppelt, Basis hat zwei Personen (%s)" % [_t6b_base_ids()])
	_check(_t6b_team_ids(after) == team_ids_before and String(_t6b_team(after, team_ids_before[0]).get("lead_unit_id", "")) == LEAD_B, "Z4: Trupps und Lead B bleiben (%s)" % [_t6b_team_ids(after)])
	var fallen: Array = _runtime.call("get_fallen")
	var by_id: Dictionary = {}
	for entry: Dictionary in fallen:
		by_id[String(entry.get("unit_id", ""))] = entry
	_check(fallen.size() == 2 and by_id.has(LEAD_A) and by_id.has(SHOOTER_C), "Z4: get_fallen am neuen Adapter hat beide Eintraege (%s)" % [fallen])
	_check(String(Dictionary(by_id.get(SHOOTER_C, {})).get("display_name", "")) == NAME_C and String(Dictionary(by_id.get(SHOOTER_C, {})).get("job_id", "")) == JOB_6B and String(Dictionary(by_id.get(SHOOTER_C, {})).get("location_id", "")) == LOCATION_6B, "Z4: Eintrag von C mit Name, Auftrag und Ort")
	_check(not String(Dictionary(by_id.get(LEAD_A, {})).get("display_name", "")).is_empty() and String(Dictionary(by_id.get(LEAD_A, {})).get("job_id", "")) == JOB_6B and String(Dictionary(by_id.get(LEAD_A, {})).get("location_id", "")) == LOCATION_6B, "Z4: Eintrag von A mit Name, Auftrag und Ort")
	_check(fallen == fallen_before, "Z4: Liste nach dem Fortsetzen == Liste vor dem Speichern")
	_check(bool(STORE_6B.validate_payload(after).get("ok", false)), "Z4: Stand nach dem Fortsetzen ist gueltig")

func _t6b_z5() -> void:
	if not await _t6b_new_four(): return
	var roster_before: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	var available_before: Array = Array(_flow.get("_available_team_units")).duplicate(true)
	var base_before: Array = _t6b_base_ids()
	var payload_before: Dictionary = _t6b_payload()
	# Beide Truppfuehrer tot: kein Truppfuehrer bliebe.
	var both: Dictionary = _t6b_result(_t6b_states({}), "aborted")
	both["fatality_unit_ids"] = PackedStringArray([LEAD_A, LEAD_B])
	both["casualties"] = [{"unit_id": LEAD_A, "outcome": "dead"}, {"unit_id": LEAD_B, "outcome": "dead"}]
	var applied: Dictionary = _flow.call("_apply_campaign_casualties", both)
	_check(Array(_flow.get("_all_team_units")) == roster_before and Array(_flow.get("_available_team_units")) == available_before, "Z5: beide Truppfuehrer tot: Kader unveraendert")
	_check(_t6b_base_ids() == base_before and Array(_runtime.call("get_fallen")).is_empty(), "Z5: Basis unveraendert, get_fallen unveraendert (leer)")
	var payload_after: Dictionary = _t6b_payload()
	_check(JSON.stringify(Dictionary(payload_before.get("craft", {})), "", true) == JSON.stringify(Dictionary(payload_after.get("craft", {})), "", true) and bool(STORE_6B.validate_payload(payload_after).get("ok", false)), "Z5: Trupps und Schiffsausruestung unveraendert, Stand gueltig")
	_check(PackedStringArray(applied.get("fatality_unit_ids", PackedStringArray())) == PackedStringArray([LEAD_A, LEAD_B]), "Z5: das Ergebnis meldet weiter beide")
	# Der Pilot tot: Platz 1 darf nicht frei werden.
	var pilot_dead: Dictionary = _t6b_result(_t6b_states({}), "aborted")
	pilot_dead["fatality_unit_ids"] = PackedStringArray([PILOT_ID])
	pilot_dead["casualties"] = [{"unit_id": PILOT_ID, "outcome": "dead"}]
	_flow.call("_apply_campaign_casualties", pilot_dead)
	_check(Array(_flow.get("_all_team_units")) == roster_before and Array(_runtime.call("get_fallen")).is_empty(), "Z5: Pilot tot: Kader und Liste unveraendert")
	_check(_t6b_lock().is_empty(), "Z5: keine Sperre fuer jemanden, der nicht entfernt wurde")
	# Kader aus nur zwei Personen: der Tod von A liesse unter zwei Personen fallen.
	await _end_sortie()
	if not await _t6b_open("campaign", "new"): return
	var pair_before: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	var lone: Dictionary = {"mission_outcome": "aborted", "result": "aborted", "team_states": [], "casualties": [{"unit_id": LEAD_A, "outcome": "dead"}], "fatality_unit_ids": PackedStringArray([LEAD_A]), "casualty_total_loss": false}
	_flow.call("_apply_campaign_casualties", lone)
	_check(pair_before.size() == 2 and Array(_flow.get("_all_team_units")) == pair_before and _t6b_base_ids().size() == 2 and Array(_runtime.call("get_fallen")).is_empty(), "Z5: Kader aus zwei Personen: Tod von A entfernt niemanden")

func _t6b_z6() -> void:
	if not await _t6b_new_four(): return
	# B ist bewusstlos, aber am Schiff (geborgen: schwer verwundet); C liegt fern vom Schiff (tot).
	var result: Dictionary = _t6b_result(_t6b_states({LEAD_B: "bleedout", SHOOTER_C: "down"}), "aborted")
	_check(PackedStringArray(result.fatality_unit_ids) == PackedStringArray([SHOOTER_C]), "Z6: Fixture: nur C ist tot (%s)" % [result.fatality_unit_ids])
	var applied: Dictionary = _flow.call("_apply_campaign_casualties", result)
	var wounded: Dictionary = _roster_unit(LEAD_B)
	_check(String(wounded.get("availability_status", "")) == "wounded" and String(Dictionary(wounded.get("recovery_state", {})).get("severity", "")) == "severe", "Z6: B ist wounded (schwer)")
	var lock: Dictionary = _t6b_lock()
	_check(lock.size() == 1 and lock.has(LEAD_B) and not lock.has(SHOOTER_C), "Z6: die Sperre enthaelt B und nicht C (%s)" % [lock])
	_check(String(lock.get(LEAD_B, "")).begins_with(NAME_B + ": Verwundet (schwer), noch "), "Z6: Meldung der Sperre nennt Namen und Stufe")
	var after: Dictionary = _t6b_payload()
	_check(_t6b_where(after, SHOOTER_C).is_empty() and bool(STORE_6B.validate_payload(after).get("ok", false)), "Z6: C ist weg, Stand gueltig")
	_check(String(_casualty_entry(applied, LEAD_B).get("outcome", "")) == "wounded" and String(_casualty_entry(applied, SHOOTER_C).get("outcome", "")) == "dead", "Z6: Ergebnis nennt B als verwundet und C als tot")
	_check(Array(_runtime.call("get_fallen")).size() == 1, "Z6: genau eine Tote in der Liste")
	_check(String(_roster_unit(LEAD_A).get("availability_status", "")) != "wounded", "Z6: Unversehrte bleiben unversehrt")

func _t6b_z7() -> void:
	if not await _t6b_new_four(): return
	var roster_before: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	var base_before: Array = _t6b_base_ids()
	# Totalverlust: der Pilot liegt (die Regeln melden Totalverlust statt Toter).
	var loss: Dictionary = _t6b_result(_t6b_states({PILOT_ID: "down", SHOOTER_C: "down"}), "aborted")
	_check(bool(loss.casualty_total_loss), "Z7: Fixture: Totalverlust")
	_flow.call("_apply_campaign_casualties", loss)
	_check(Array(_flow.get("_all_team_units")) == roster_before and _t6b_base_ids() == base_before and Array(_runtime.call("get_fallen")).is_empty(), "Z7: Totalverlust: niemand entfernt, Liste leer")
	var forced: Dictionary = loss.duplicate(true)
	forced["fatality_unit_ids"] = PackedStringArray([SHOOTER_C])
	_flow.call("_apply_campaign_casualties", forced)
	_check(Array(_flow.get("_all_team_units")) == roster_before and Array(_runtime.call("get_fallen")).is_empty(), "Z7: Totalverlust-Ergebnis mit Toten-Feld: weiter niemand entfernt")
	await _end_sortie()
	# Skirmish.
	if not await _t6b_open("skirmish", "new"): return
	var skirmish_roster: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	if not _check(not skirmish_roster.is_empty(), "Z7: Skirmish-Kader ist nicht leer"): return
	var someone: String = String(Dictionary(skirmish_roster[0]).get("unit_id", ""))
	var fake: Dictionary = {"mission_outcome": "aborted", "casualties": [{"unit_id": someone, "outcome": "dead"}], "fatality_unit_ids": PackedStringArray([someone]), "team_states": []}
	var out: Dictionary = _flow.call("_apply_campaign_casualties", fake)
	_check(out == fake and Array(_flow.get("_all_team_units")) == skirmish_roster, "Z7: Skirmish: Ergebnis und Kader unveraendert")
	_flow.call("_remove_campaign_fatalities", PackedStringArray([someone]), fake)
	_check(Array(_flow.get("_all_team_units")) == skirmish_roster, "Z7: Skirmish: auch der direkte Aufruf entfernt niemanden")
	var skirmish_runtime: Node = _flow.get("_singleplayer_runtime")
	_check(skirmish_runtime == null or not skirmish_runtime.has_method("get_fallen") or Array(skirmish_runtime.call("get_fallen")).is_empty(), "Z7: Skirmish: keine Gefallenenliste gefuellt")

func _t6b_z8() -> void:
	if not await _t6b_new_four(): return
	var roster_before: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	var base_before: Array = _t6b_base_ids()
	var payload_before: Dictionary = _t6b_payload()
	var won: Dictionary = _t6b_result(_t6b_states({}), "won")
	_check(PackedStringArray(won.fatality_unit_ids).is_empty(), "Z8: Fixture: Sieg ohne Tote")
	var applied: Dictionary = _flow.call("_apply_campaign_casualties", won)
	var payload_after: Dictionary = _t6b_payload()
	_check(Array(_flow.get("_all_team_units")) == roster_before and _t6b_base_ids() == base_before, "Z8: Kader und Basis unveraendert")
	_check(JSON.stringify(payload_before.get("craft", {}), "", true) == JSON.stringify(payload_after.get("craft", {}), "", true) and Array(_runtime.call("get_fallen")).is_empty(), "Z8: Trupps und Ausruestung unveraendert, Liste leer")
	_check(PackedStringArray(applied.get("fatality_unit_ids", PackedStringArray(["x"]))).is_empty(), "Z8: Ergebnis ohne Tote")
	# Verwundete (leicht) ohne Tote: nur die Verwundung.
	var downed: Dictionary = _t6b_result(_t6b_states({LEAD_B: "down"}), "won")
	_flow.call("_apply_campaign_casualties", downed)
	_check(String(_roster_unit(LEAD_B).get("availability_status", "")) == "wounded" and _t6b_roster_ids() == [LEAD_A, PILOT_ID, LEAD_B, SHOOTER_C] and Array(_runtime.call("get_fallen")).is_empty(), "Z8: Sieg mit liegender Person: nur wounded, niemand entfernt")

func _t6b_z9() -> void:
	if not await _t6b_new_four(): return
	# Reihenfolge A, Pilot, C (ohne Fuehrung), B: der Nachfolger von A ist B, nicht der Erste hinter dem Piloten.
	var by_id: Dictionary = {}
	for unit: Dictionary in Array(_flow.get("_all_team_units")):
		by_id[String(unit.get("unit_id", ""))] = unit
	_flow.set("_all_team_units", [by_id[LEAD_A], by_id[PILOT_ID], by_id[SHOOTER_C], by_id[LEAD_B]])
	_check(_t6b_roster_ids() == [LEAD_A, PILOT_ID, SHOOTER_C, LEAD_B], "Z9: Fixture: Reihenfolge A, Pilot, C, B")
	var result: Dictionary = _t6b_result(_t6b_states({LEAD_A: "down"}), "aborted")
	_check(PackedStringArray(result.fatality_unit_ids) == PackedStringArray([LEAD_A]) and not bool(result.casualty_total_loss), "Z9: Fixture: A ist tot, B fuehrt weiter")
	_flow.call("_apply_campaign_casualties", result)
	_check(_t6b_roster_ids() == [LEAD_B, PILOT_ID, SHOOTER_C], "Z9: B (Fuehrung > 0) auf Platz 0, Pilot Platz 1, C uebersprungen (%s)" % [_t6b_roster_ids()])
	var after: Dictionary = _t6b_payload()
	_check(not after.is_empty() and bool(STORE_6B.validate_payload(after).get("ok", false)), "Z9: Stand gueltig")
