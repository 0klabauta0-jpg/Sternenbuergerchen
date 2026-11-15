extends "res://scripts/tests/campaign_casualty_apply_verifier.gd"
## Task 7b (Ausfall und Rueckzug): Ausfallzeit laeuft im Spielablauf in Echtzeit, die Einsatzsperre wird aus dem Kader gefuettert.
## Echte Meta-Szene (Kampagne bzw. Skirmish), Aufbau wie campaign_retreat_reopen_at_home_verifier.
## Z1: Restzeit sinkt in Echtzeit (5 s), total bleibt.   Z2: Einschiffen der Verwundeten (Person und Trupp) wird abgelehnt.
## Z3: Genesung (Rest laeuft ab): Sperre weg, Einschiffen gelingt bis an Bord.
## Z4: Verwundete an Bord des an der Heimatbasis gelandeten Schiffs: authorize_departure sperrt, nach dem Absetzen nicht mehr.
## Z5: Speichern, Meta-Szene neu aufbauen, Fortsetzen: Restzeit bleibt, Sperre gilt sofort wieder.
## Z6: Skirmish zaehlt nichts und sperrt nichts.   Z7: Niemand verwundet: nichts aendert sich.   Z8: zwei Verwundete, kuerzere Zeit genest zuerst.
## Einzeln starten: Umgebungsvariable T7B_ONLY (zum Beispiel "Z5") oder Kommandozeilenargument nach "--" (zum Beispiel "-- Z5"); ohne Angabe laufen alle.

const RECOVERY = preload("res://scripts/core/personnel_recovery_runtime.gd")
const LEADER := "campaign_leader"
const PILOT := "campaign_pilot"

func _run() -> void:
	_configure_entry()
	var selected: Array = _selected_scenarios()
	for scenario: String in ["Z1", "Z2", "Z3", "Z4", "Z5", "Z6", "Z7", "Z8"]:
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
	var advances: Variant = _flow.get("_recovery_advance_count")
	_check(advances != null and int(advances) == 0, "Z7: im Tick wurde nichts berechnet (advance-Zaehler %s)" % advances)

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
