extends "res://scripts/tests/campaign_casualty_apply_verifier.gd"
## Task 7b (Ausfall und Rueckzug): Ausfallzeit laeuft im Spielablauf in Echtzeit, die Einsatzsperre wird aus dem Kader gefuettert.
## Echte Meta-Szene (Kampagne bzw. Skirmish), Aufbau wie campaign_retreat_reopen_at_home_verifier.
## Z1: Restzeit sinkt in Echtzeit (5 s), total bleibt.   Z2: Einschiffen der Verwundeten (Person und Trupp) wird abgelehnt.
## Z3: Genesung (Rest laeuft ab): Sperre weg, Einschiffen gelingt bis an Bord.
## Z4: Verwundete an Bord des an der Heimatbasis gelandeten Schiffs: authorize_departure sperrt, nach dem Absetzen nicht mehr.
## Z5: Speichern, Meta-Szene neu aufbauen, Fortsetzen: Restzeit bleibt, Sperre gilt sofort wieder.
## Z6: Skirmish zaehlt nichts und sperrt nichts.   Z7: Niemand verwundet: nichts aendert sich.   Z8: zwei Verwundete, kuerzere Zeit genest zuerst.
## Z13: Sichtbare Basisansicht: die Statuszeile der Verwundeten zeigt die laufende Restzeit, ohne Neuaufbau (gleiche Karte, Marker, Auswahl).
## Z14: Ablauf der Zeit: Karte zeigt den normalen Zustand, die Person ist einschiffbar.   Z15: Unsichtbare Ansicht: keine Auffrischung.
## Einzeln starten: Umgebungsvariable T7B_ONLY (zum Beispiel "Z5") oder Kommandozeilenargument nach "--" (zum Beispiel "-- Z5"); ohne Angabe laufen alle.

const RECOVERY = preload("res://scripts/core/personnel_recovery_runtime.gd")
const LEADER := "campaign_leader"
const PILOT := "campaign_pilot"

func _run() -> void:
	_configure_entry()
	var selected: Array = _selected_scenarios()
	for scenario: String in ["Z1", "Z2", "Z3", "Z4", "Z5", "Z6", "Z7", "Z8", "Z9", "Z10", "Z11", "Z12", "Z13", "Z14", "Z15"]:
		if not selected.is_empty() and not selected.has(scenario):
			continue
		print("--- ", scenario)
		await call("_" + scenario.to_lower())
		await _close()
	print("CAMPAIGN_CASUALTY_RECOVERY_FLOW passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _selected_scenarios() -> Array:
	var result: Array = []
	var env: String = OS.get_environment("T7B_ONLY").strip_edges().to_upper()
	if not env.is_empty():
		result.append(env)
	for arg: String in OS.get_cmdline_user_args():
		var upper: String = arg.strip_edges().to_upper()
		if upper.begins_with("Z"):
			result.append(upper)
	return result

# ---------- Hilfen ----------

func _open(mode: String, action: String) -> bool:
	START.request_start(self, mode, action)
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	if mode != "campaign":
		return true
	var operations: Dictionary = _screen.call("get_operations_snapshot")
	_craft_id = String(Dictionary(operations.get("selected_craft", {})).get("id", ""))
	_team_id = ""
	for team: Dictionary in Array(operations.get("fireteams", [])):
		if not Array(team.get("members", [])).is_empty():
			_team_id = String(team.id)
			break
	return _check(not _craft_id.is_empty() and not _team_id.is_empty() and _base() != null, "%s/%s: Schiff, Trupp und Basis-Runtime sind da" % [mode, action])

func _close() -> void:
	if _flow != null and is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame

func _base() -> Node:
	return _runtime.call("get_base_personnel_runtime") if _runtime != null else null

func _lock() -> Dictionary:
	var base: Node = _base()
	return Dictionary(base.get("_unavailable_unit_reasons")).duplicate(true) if base != null else {}

## Fuettert die Sperre ueber den Weg des Spielablaufs (gemeinsame Funktion im Flow).
func _feed() -> void:
	if _flow.has_method("_sync_wound_lock"):
		_flow.call("_sync_wound_lock")

func _wound(unit_id: String, severity: String, total: float, remaining: float) -> void:
	_set_wounded(unit_id, severity, total, remaining)
	_feed()

func _remaining(unit_id: String) -> float:
	return float(Dictionary(_roster_unit(unit_id).get("recovery_state", {})).get("seconds_remaining", -1.0))

func _name(unit_id: String) -> String:
	return String(_roster_unit(unit_id).get("display_name", unit_id))

func _people() -> Array:
	return Array(Dictionary(_base().call("get_snapshot")).get("units", [])).duplicate(true)

func _person(unit_id: String) -> Dictionary:
	for person: Dictionary in _people():
		if String(person.get("unit_id", "")) == unit_id:
			return person
	return {}

func _without_idle_clock(people: Array) -> Array:
	var result: Array = []
	for person: Dictionary in people:
		var copy: Dictionary = person.duplicate(true)
		copy.erase("idle_seconds")
		result.append(copy)
	return result

func _nobody_embarking() -> bool:
	for person: Dictionary in _people():
		if String(person.get("status", "")) in ["aboard", "boarding"]:
			return false
	return not bool(_base().call("is_pilot_aboard", _craft_id))

func _board_one(unit_id: String) -> Dictionary:
	return _screen.call("request_operation", "base_board", {"craft_id": _craft_id, "unit_id": unit_id})

func _board_team() -> Dictionary:
	return _screen.call("request_operation", "base_board", {"craft_id": _craft_id, "fireteam_id": _team_id, "whole_fireteam": true})

# ---------- Szenarien ----------

func _z1() -> void:
	if not await _open("campaign", "new"): return
	_wound(LEADER, "medium", 900.0, 900.0)
	var lock: Dictionary = _lock()
	_check(lock.has(LEADER) and String(lock[LEADER]).begins_with(_name(LEADER) + ": Verwundet (mittel), noch "), "Z1: Sperre gefuettert, Meldung '<Name>: Verwundet (mittel), noch ...' (%s)" % lock)
	await create_timer(5.0).timeout
	var remaining: float = _remaining(LEADER)
	var state: Dictionary = Dictionary(_roster_unit(LEADER).get("recovery_state", {}))
	print("Z1_REMAINING ", remaining, " state=", state)
	_check(remaining >= 894.0 and remaining <= 896.0, "Z1: Restzeit nach 5 s um 4 bis 6 s gesunken (%.2f)" % remaining)
	_check(is_equal_approx(float(state.get("seconds_total", -1.0)), 900.0) and String(state.get("severity", "")) == "medium", "Z1: total 900 und Stufe mittel unveraendert")
	_check(String(_roster_unit(LEADER).get("availability_status", "")) == "wounded", "Z1: Person ist weiter wounded")
	var after: Dictionary = _lock()
	_check(after.has(LEADER) and lock.has(LEADER) and String(after[LEADER]) != String(lock[LEADER]), "Z1: Meldung der Sperre zeigt die laufende Restzeit (%s)" % after)

func _z2() -> void:
	if not await _open("campaign", "new"): return
	_wound(LEADER, "medium", 900.0, 900.0)
	var before: Array = _people()
	var roster_before: Dictionary = _roster_unit(LEADER).duplicate(true)
	var single: Dictionary = _board_one(LEADER)
	print("Z2_SINGLE ", single)
	var message: String = String(single.get("message", ""))
	_check(not bool(single.get("ok", true)) and String(single.get("reason", "")) == "unit_wounded", "Z2: Einschiffen der Verwundeten abgelehnt: unit_wounded")
	_check(message.contains(_name(LEADER)) and message.contains("Verwundet (mittel)") and message.contains("noch "), "Z2: Meldung nennt Namen, Stufe und Zeit (%s)" % message)
	var after_single: Dictionary = _person(LEADER)
	var before_single: Dictionary = {}
	for person: Dictionary in before:
		if String(person.get("unit_id", "")) == LEADER:
			before_single = person
	after_single.erase("idle_seconds")
	before_single = before_single.duplicate(true)
	before_single.erase("idle_seconds")
	_check(after_single == before_single, "Z2: Position und Status der Person unveraendert")
	_check(String(_roster_unit(LEADER).get("availability_status", "")) == "wounded" and _remaining(LEADER) > 0.0 and String(roster_before.get("unit_id", "")) == LEADER, "Z2: Kader unveraendert wounded")
	var team: Dictionary = _board_team()
	print("Z2_TEAM ", team)
	_check(not bool(team.get("ok", true)) and String(team.get("reason", "")) == "unit_wounded", "Z2: Einschiffen des Trupps mit der Verwundeten abgelehnt: unit_wounded")
	_check(String(team.get("message", "")).contains(_name(LEADER)), "Z2: Trupp-Meldung nennt den Namen")
	await create_timer(0.5).timeout
	_check(_nobody_embarking(), "Z2: niemand ist danach an Bord oder unterwegs")
	# idle_seconds ist ein Leerlaufzaehler der Basis und tickt von selbst weiter; alles andere (Position, Status, Schiff, Aktion) muss gleich bleiben.
	var people_after: Array = _people()
	_check(_without_idle_clock(people_after) == _without_idle_clock(before), "Z2: alle Personen unveraendert (Position, Status, Schiff, Aktion), keiner unterwegs zum Schiff")

func _z3() -> void:
	if not await _open("campaign", "new"): return
	_wound(LEADER, "medium", 900.0, 2.0)
	_check(_lock().has(LEADER), "Z3: vor Ablauf ist die Sperre gesetzt")
	await create_timer(4.0).timeout
	var unit: Dictionary = _roster_unit(LEADER)
	_check(String(unit.get("availability_status", "")) == "active" and Dictionary(unit.get("recovery_state", {"x": 1})).is_empty() and String(unit.get("status_text", "x")).is_empty(), "Z3: Person ist active, recovery_state leer, status_text leer (%s)" % unit.get("availability_status"))
	_check(_lock().is_empty(), "Z3: Sperre ist leer (%s)" % _lock())
	var single: Dictionary = _board_one(LEADER)
	print("Z3_SINGLE ", single)
	_check(String(single.get("reason", "")) != "unit_wounded" and bool(single.get("ok", false)), "Z3: Einschiffen der Person gelingt (%s)" % single)
	var team: Dictionary = _board_team()
	print("Z3_TEAM ", team)
	_check(String(team.get("reason", "")) != "unit_wounded" and bool(team.get("ok", false)), "Z3: Einschiffen des Trupps gelingt (%s)" % team)
	_check(await _wait(_base_crew_ready, 60000, "Z3: beide Personen sind wirklich an Bord, Nutzlast bereit"), "Z3: Einschiffen laeuft bis an Bord durch")

func _z4() -> void:
	if not await _open("campaign", "new"): return
	# Vorbereitung wie vor einem echten Abflug: Auftrag angenommen, Ziel gewaehlt, Besatzung an Bord.
	_check(_screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false), "Z4: Auftrag angenommen")
	_check(_screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}).get("ok", false), "Z4: Ziel gewaehlt")
	if not await _board_actual_base_crew(): return
	_check(String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(_craft_id, "")) == "homebase", "Z4: Schiff steht mit der Besatzung an der Heimatbasis")
	_check(String(_person(LEADER).get("status", "")) == "aboard", "Z4: Fixture: Truppfuehrer ist an Bord")
	var open_departure: Dictionary = _runtime.call("authorize_departure", _craft_id)
	print("Z4_OPEN ", open_departure)
	_check(String(open_departure.get("reason", "")) != "unit_wounded", "Z4: ohne Verwundung ist der Abflug nicht wegen Verwundung gesperrt")
	# Zustand nach einer Heimkehr mit einer im Einsatz Verwundeten: Person ist an Bord des gelandeten Schiffs und verwundet.
	_wound(LEADER, "medium", 600.0, 600.0)
	var blocked: Dictionary = _runtime.call("authorize_departure", _craft_id)
	print("Z4_BLOCKED ", blocked)
	_check(not bool(blocked.get("ok", true)) and String(blocked.get("reason", "")) == "unit_wounded", "Z4: authorize_departure mit Verwundeter an Bord: unit_wounded")
	_check(String(blocked.get("message", "")).contains(_name(LEADER)), "Z4: Meldung nennt den Namen")
	var unboard: Dictionary = _screen.call("request_operation", "base_unboard", {"craft_id": _craft_id, "unit_id": LEADER})
	print("Z4_UNBOARD ", unboard)
	_check(bool(unboard.get("ok", false)), "Z4: Absetzen der Person wird angenommen")
	await _wait(func(): return String(_person(LEADER).get("status", "")) != "aboard", 30000, "Z4: Person ist abgesetzt")
	_check(_lock().has(LEADER), "Z4: die Sperre der Person gilt weiter")
	var released: Dictionary = _runtime.call("authorize_departure", _craft_id)
	print("Z4_RELEASED ", released)
	_check(String(released.get("reason", "")) != "unit_wounded", "Z4: nach dem Absetzen ist dieser Sperrgrund weg (%s)" % released.get("reason", "ok"))

func _z5() -> void:
	if not await _open("campaign", "new"): return
	var wounded_at: int = Time.get_ticks_msec()
	_wound(LEADER, "medium", 600.0, 600.0)
	await create_timer(3.0).timeout
	var saved: Dictionary = _flow.call("request_campaign_save")
	var ran: float = float(Time.get_ticks_msec() - wounded_at) / 1000.0
	var at_save: float = _remaining(LEADER)
	print("Z5_SAVE ok=", saved.get("ok", false), " reason=", saved.get("reason", ""), " ran=", ran, " remaining_at_save=", at_save)
	if not _check(bool(saved.get("ok", false)), "Z5: Speichern gelingt"): return
	await _close()
	# Zeit, in der das Spiel nicht laeuft, zaehlt nicht.
	await create_timer(3.0).timeout
	if not await _open("campaign", "continue"): return
	var resumed: float = _remaining(LEADER)
	print("Z5_RESUMED ", resumed)
	_check(String(_roster_unit(LEADER).get("availability_status", "")) == "wounded", "Z5: nach dem Fortsetzen ist die Person weiter wounded")
	_check(resumed >= at_save - 2.0 and resumed <= at_save + 0.5, "Z5: Restzeit nach Fortsetzen = gespeicherter Wert +-2 s (gespeichert %.2f, fortgesetzt %.2f; 3 s Stillstand zaehlen nicht)" % [at_save, resumed])
	_check(resumed >= 598.0 - ran and resumed <= 602.0 - ran, "Z5: Restzeit liegt bei 600 minus gelaufene Sekunden (%.2f s) +-2 s (%.2f)" % [ran, resumed])
	var lock: Dictionary = _lock()
	_check(lock.has(LEADER) and String(lock[LEADER]).contains("Verwundet (mittel)"), "Z5: Sperre gilt sofort wieder (%s)" % lock)
	var board: Dictionary = _board_one(LEADER)
	_check(not bool(board.get("ok", true)) and String(board.get("reason", "")) == "unit_wounded", "Z5: Einschiffen -> unit_wounded (%s)" % board)

func _z6() -> void:
	if not await _open("skirmish", "new"): return
	var roster: Array = Array(_flow.get("_all_team_units"))
	if not _check(not roster.is_empty(), "Z6: Skirmish-Kader ist nicht leer"): return
	var unit_id: String = String(Dictionary(roster[0]).get("unit_id", ""))
	_set_wounded(unit_id, "medium", 600.0, 600.0)
	_feed()
	await create_timer(3.0).timeout
	_check(is_equal_approx(_remaining(unit_id), 600.0) and String(_roster_unit(unit_id).get("availability_status", "")) == "wounded", "Z6: Skirmish zaehlt nichts (Rest %.2f)" % _remaining(unit_id))
	_check(_lock().is_empty(), "Z6: Skirmish sperrt nichts (%s)" % _lock())

func _z7() -> void:
	if not await _open("campaign", "new"): return
	var before: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	var available_before: Array = Array(_flow.get("_available_team_units")).duplicate(true)
	await create_timer(3.0).timeout
	_check(Array(_flow.get("_all_team_units")) == before and Array(_flow.get("_available_team_units")) == available_before, "Z7: Kader nach 3 s identisch")
	_check(_lock().is_empty(), "Z7: Sperre leer")
	# Niemand verwundet: nach einem vollen Takt steht die Uhr auf 0 (der erste Takt nach einer Verwundung zieht nicht zu viel ab).
	_flow.set("_recovery_clock", 0.9)
	_flow.call("_tick_personnel_recovery", 0.2)
	_check(is_zero_approx(float(_flow.get("_recovery_clock"))), "Z7: ohne Verwundete steht die Uhr nach dem Takt auf 0 (%s)" % _flow.get("_recovery_clock"))
	_check(Array(_flow.get("_all_team_units")) == before and _lock().is_empty(), "Z7: Kader weiter identisch, Sperre leer")

func _z8() -> void:
	if not await _open("campaign", "new"): return
	_wound(LEADER, "medium", 600.0, 2.0)
	_wound(PILOT, "medium", 600.0, 600.0)
	_check(_lock().has(LEADER) and _lock().has(PILOT), "Z8: beide gesperrt")
	await create_timer(4.0).timeout
	var leader: Dictionary = _roster_unit(LEADER)
	var pilot_rest: float = _remaining(PILOT)
	print("Z8_PILOT_REMAINING ", pilot_rest)
	_check(String(leader.get("availability_status", "")) == "active" and Dictionary(leader.get("recovery_state", {"x": 1})).is_empty(), "Z8: die mit der kuerzeren Zeit ist genesen")
	_check(pilot_rest >= 594.0 and pilot_rest <= 597.5 and String(_roster_unit(PILOT).get("availability_status", "")) == "wounded", "Z8: die andere zaehlt weiter und ist noch verwundet (%.2f)" % pilot_rest)
	var lock: Dictionary = _lock()
	_check(lock.size() == 1 and lock.has(PILOT) and not lock.has(LEADER) and String(lock[PILOT]).contains(_name(PILOT)), "Z8: Sperre enthaelt nur noch die andere (%s)" % lock)

## Z9: Verluste ueber den echten Weg _apply_campaign_casualties; die Sperre steht sofort, ohne Wartezeit und ohne eigenen Aufruf des Tests.
func _z9() -> void:
	if not await _open("campaign", "new"): return
	_set_roster()
	_check(_lock().is_empty(), "Z9: vor den Verlusten ist die Sperre leer")
	var won: Dictionary = _built_result([_state("t_pilot", "fit", false), _state("t_leader", "fit", false), _state("t_c", "down", false)], "won")
	var applied: Dictionary = _flow.call("_apply_campaign_casualties", won)
	var lock: Dictionary = _lock()
	print("Z9_LOCK ", lock)
	_check(String(_roster_unit("t_c").get("availability_status", "")) == "wounded" and not applied.is_empty(), "Z9: Verlust angewendet, Person ist wounded")
	_check(lock.size() == 1 and lock.has("t_c"), "Z9: direkt nach dem Aufruf enthaelt die Sperre genau die Verwundete (%s)" % lock)
	_check(String(lock.get("t_c", "")).begins_with("Carl Cobalt: Verwundet (mittel), noch "), "Z9: Meldung mit Namen und 'Verwundet (mittel)'")

## Z10: Die Ausfallzeit zaehlt auch, waehrend ein echter Kampagneneinsatz laeuft (zu Hause gebliebene dritte Person).
func _z10() -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	_check(_flow.get("_active_mission") != null, "Z10: Einsatz laeuft")
	var units: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	var home_unit: Dictionary = Dictionary(units[0]).duplicate(true)
	home_unit["unit_id"] = "t7b_home_unit"
	home_unit["display_name"] = "Hanna Heim"
	home_unit["availability_status"] = "wounded"
	home_unit["status_text"] = "wounded"
	home_unit["recovery_state"] = {"state": "wounded", "severity": "medium", "seconds_total": 900.0, "seconds_remaining": 900.0, "source": "campaign_casualty"}
	units.append(home_unit)
	_flow.call("_replace_roster_units", units)
	_feed()
	_check(_lock().has("t7b_home_unit"), "Z10: Sperre kennt die Zuhausegebliebene")
	await create_timer(5.0).timeout
	var remaining: float = _remaining("t7b_home_unit")
	print("Z10_REMAINING ", remaining)
	_check(_flow.get("_active_mission") != null, "Z10: Einsatz laeuft weiter")
	_check(remaining >= 894.0 and remaining <= 896.0, "Z10: Restzeit sank waehrend des Einsatzes um die gelaufenen Sekunden (%.2f)" % remaining)

## Z11: Altdaten: "wounded" ohne recovery_state, niemand sonst verwundet -> nach 2 s active, Sperre leer.
func _z11() -> void:
	if not await _open("campaign", "new"): return
	var units: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	for unit: Dictionary in units:
		if String(unit.get("unit_id", "")) == LEADER:
			unit["availability_status"] = "wounded"
			unit["status_text"] = "wounded"
			unit["recovery_state"] = {}
	_flow.call("_replace_roster_units", units)
	_feed()
	_check(String(_roster_unit(LEADER).get("availability_status", "")) == "wounded" and _lock().is_empty(), "Z11: Fixture: wounded ohne recovery_state, keine Sperre")
	await create_timer(2.5).timeout
	var unit: Dictionary = _roster_unit(LEADER)
	_check(String(unit.get("availability_status", "")) == "active" and Dictionary(unit.get("recovery_state", {"x": 1})).is_empty() and String(unit.get("status_text", "x")).is_empty(), "Z11: Altdatenperson ist active, recovery_state und status_text leer (%s)" % unit.get("availability_status"))
	_check(_lock().is_empty(), "Z11: Sperre leer")

## Z12: Ein Haenger zaehlt hoechstens 2 s; die Uhr beginnt bei der ersten Verwundung bei 0.
func _z12() -> void:
	if not await _open("campaign", "new"): return
	_flow.set("_recovery_clock", 0.9)
	_wound(LEADER, "medium", 900.0, 900.0)
	_check(is_zero_approx(float(_flow.get("_recovery_clock"))), "Z12: bei der ersten Verwundung steht die Uhr auf 0 (%s)" % _flow.get("_recovery_clock"))
	_flow.call("_tick_personnel_recovery", 600.0)
	var drop: float = 900.0 - _remaining(LEADER)
	print("Z12_DROP ", drop)
	_check(drop > 0.5 and drop <= 2.05, "Z12: Delta 600 senkt die Restzeit um hoechstens 2 s (%.3f)" % drop)

# ---------- Restzeit auf der Personenkarte (Nacharbeit 3a) ----------

func _card_for(unit_id: String) -> Node:
	for field: String in ["_staged_cards_by_unit_id", "_roster_cards_by_unit_id"]:
		var cards: Dictionary = Dictionary(_screen.get(field))
		if cards.has(unit_id) and is_instance_valid(cards[unit_id]):
			return cards[unit_id]
	return null

## Statuszeile der Karte, gelesen ueber die oeffentliche Auskunft der Karte (der Text, den sie anzeigt).
func _card_status(unit_id: String) -> String:
	var card: Node = _card_for(unit_id)
	return String(Dictionary(card.call("get_profile_reference_contract_snapshot")).get("secondary_text_override", "<keine Karte>")) if card != null else "<keine Karte>"

## Eine volle Sekunde Spielzeit ueber den echten Takt des Flows.
func _tick_seconds(count: int) -> void:
	for _i in range(count):
		_flow.set("_recovery_clock", 0.0)
		_flow.call("_tick_personnel_recovery", 1.0)

func _view_state() -> Array:
	return [PackedStringArray(_screen.call("get_selected_unit_ids")), PackedStringArray(_screen.call("get_selected_fireteam_ids")), _screen.get("_focused_unit_id"), _screen.get("_focused_fireteam_id")]

func _z13() -> void:
	if not await _open("campaign", "new"): return
	_wound(LEADER, "medium", 900.0, 900.0)
	_flow.call("_refresh_homebase_screen")
	_check(_screen.is_visible_in_tree(), "Z13: Fixture: Basisansicht ist sichtbar")
	var card: Node = _card_for(LEADER)
	if not _check(card != null, "Z13: Fixture: Karte der Verwundeten ist da"): return
	var before_text: String = _card_status(LEADER)
	_check(before_text.begins_with("Verwundet (mittel), noch 15:00"), "Z13: Fixture: Karte zeigt 'Verwundet (mittel), noch 15:00' (%s)" % before_text)
	_screen.set("_team_feedback_text", "z13-marker")
	var view_before: Array = _view_state()
	var card_id: int = card.get_instance_id()
	_tick_seconds(2)
	var after_text: String = _card_status(LEADER)
	print("Z13_TEXT ", before_text, " -> ", after_text)
	_check(after_text.begins_with("Verwundet (mittel), noch 14:58"), "Z13: nach zwei gezaehlten Sekunden zeigt die Karte 14:58 (%s)" % after_text)
	_check(is_equal_approx(_remaining(LEADER), 898.0), "Z13: Kader zaehlt weiter (Wahrheit beim Kader): %.2f" % _remaining(LEADER))
	_check(_card_for(LEADER) != null and _card_for(LEADER).get_instance_id() == card_id, "Z13: dieselbe Karten-Instanz vorher und nachher")
	_check(String(_screen.get("_team_feedback_text")) == "z13-marker", "Z13: Ansicht wurde nicht neu aufgebaut (Marker blieb, setup_roster lief nicht)")
	_check(_view_state() == view_before, "Z13: Auswahl und Fokus unveraendert")
	_check(after_text.get_slice(" | ", 1) == before_text.get_slice(" | ", 1), "Z13: nur der Statusteil der Zeile aendert sich, der Ortsteil bleibt")

func _z14() -> void:
	if not await _open("campaign", "new"): return
	_wound(LEADER, "medium", 900.0, 2.0)
	_flow.call("_refresh_homebase_screen")
	var fit_status: String = _card_status(PILOT).get_slice(" | ", 0)
	_check(_card_status(LEADER).begins_with("Verwundet (mittel), noch 0:02"), "Z14: Fixture: Karte zeigt 0:02 (%s)" % _card_status(LEADER))
	_tick_seconds(1)
	_check(_card_status(LEADER).begins_with("Verwundet (mittel), noch 0:01"), "Z14: nach einer Sekunde 0:01 (%s)" % _card_status(LEADER))
	_tick_seconds(1)
	var text: String = _card_status(LEADER)
	print("Z14_TEXT ", text, " fit=", fit_status)
	_check(String(_roster_unit(LEADER).get("availability_status", "")) == "active", "Z14: Kader: Person ist active")
	_check(not text.contains("Verwundet") and not text.contains("noch ") and text.get_slice(" | ", 0) == fit_status, "Z14: Karte zeigt sofort den normalen Zustand wie eine gesunde Person (%s / %s)" % [text, fit_status])
	_check(_lock().is_empty(), "Z14: Sperre leer")
	var single: Dictionary = _board_one(LEADER)
	_check(bool(single.get("ok", false)) and String(single.get("reason", "")) != "unit_wounded", "Z14: Person ist ohne weiteres Zutun einschiffbar (%s)" % single)

func _z15() -> void:
	if not await _open("campaign", "new"): return
	_wound(LEADER, "medium", 900.0, 900.0)
	_flow.call("_refresh_homebase_screen")
	var shown: String = _card_status(LEADER)
	_screen.visible = false
	_check(not _screen.is_visible_in_tree(), "Z15: Fixture: Basisansicht ist unsichtbar")
	_tick_seconds(2)
	_check(_card_status(LEADER) == shown, "Z15: bei unsichtbarer Ansicht wird keine Karte beschrieben (%s)" % _card_status(LEADER))
	_check(is_equal_approx(_remaining(LEADER), 898.0), "Z15: der Kader zaehlt trotzdem weiter (%.2f)" % _remaining(LEADER))
	_screen.visible = true
	_tick_seconds(1)
	_check(_card_status(LEADER).begins_with("Verwundet (mittel), noch 14:57"), "Z15: wieder sichtbar: spaetestens der naechste Takt zeigt die aktuelle Restzeit (%s)" % _card_status(LEADER))
	# Niemand verwundet: nichts aendert sich an der Karte.
	var healed: Array = []
	for unit: Dictionary in Array(_flow.get("_all_team_units")):
		var copy: Dictionary = unit.duplicate(true)
		copy["availability_status"] = "active"
		copy["recovery_state"] = {}
		copy["status_text"] = ""
		healed.append(copy)
	_flow.call("_replace_roster_units", healed)
	_flow.call("_refresh_homebase_screen")
	var healthy: String = _card_status(LEADER)
	_screen.set("_team_feedback_text", "z15-marker")
	_tick_seconds(2)
	_check(_card_status(LEADER) == healthy and String(_screen.get("_team_feedback_text")) == "z15-marker", "Z15: ohne Verwundete bleibt die Ansicht unberuehrt (%s)" % _card_status(LEADER))
