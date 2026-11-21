extends "res://scripts/tests/campaign_casualty_recovery_flow_verifier.gd"
## R3a Respawn (Ausfall-Uhr und Sperre): "respawning" zaehlt in Echtzeit herunter, bei 0 "awaiting_pickup", nie von selbst "active".
## Rein: PersonnelRecoveryRuntime.advance/describe/is_blocked/format_clock.
## Spielablauf (echte Meta-Szene, Kampagne): _tick_personnel_recovery zaehlt, _sync_wound_lock sperrt beide Zustaende
## (Einschiffen abgelehnt, Text "Name: gestorben, Respawn in m:ss" bzw. "Name: wartet auf Polisa").
## Abschlusszeile: CAMPAIGN_RESPAWN_CLOCK passed=%d failed=%d

func _run() -> void:
	_configure_entry()
	_pure()
	await _flow_part()
	print("CAMPAIGN_RESPAWN_CLOCK passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _wounded(id: String, seconds: float, severity: String = "medium") -> Dictionary:
	return {"unit_id": id, "display_name": "Name " + id, "availability_status": "wounded", "status_text": "x",
		"recovery_state": {"severity": severity, "seconds_total": 1000.0, "seconds_remaining": seconds}}

func _respawner(id: String, seconds: float, pickup: String = "polisa") -> Dictionary:
	return {"unit_id": id, "display_name": "Name " + id, "availability_status": "respawning", "status_text": "respawning",
		"recovery_state": {"state": "respawning", "death_number": 1, "seconds_total": 3600.0, "seconds_remaining": seconds, "pickup_location_id": pickup, "source": "left_behind"}}

func _pure() -> void:
	var before: Array = [_respawner("r", 100.0)]
	var res: Dictionary = RECOVERY.advance(before, 30.0)
	_check(is_equal_approx(float(res.units[0].recovery_state.seconds_remaining), 70.0) and bool(res.changed), "advance: respawning 100 s minus 30 s ergibt 70 s")
	_check(res.units[0].availability_status == "respawning" and res.matured_unit_ids.is_empty() and res.recovered_unit_ids.is_empty(), "advance: noch respawning, niemand matured oder genesen")
	_check(is_equal_approx(float(before[0].recovery_state.seconds_remaining), 100.0), "advance: Eingabe bleibt unveraendert")
	_check(is_equal_approx(float(res.units[0].recovery_state.death_number), 1.0) and String(res.units[0].recovery_state.source) == "left_behind", "advance: death_number und source bleiben")
	res = RECOVERY.advance([_respawner("r", 10.0, "polisa")], 10.0)
	_check(res.units[0].availability_status == "awaiting_pickup" and res.units[0].status_text == "awaiting_pickup", "advance: Rest 0 macht awaiting_pickup (nicht active)")
	_check(res.units[0].recovery_state == {"state": "awaiting_pickup", "pickup_location_id": "polisa"}, "advance: awaiting_pickup traegt genau state und pickup_location_id")
	_check(res.matured_unit_ids == PackedStringArray(["r"]) and res.recovered_unit_ids.is_empty() and bool(res.changed), "advance: matured_unit_ids nennt die Person, recovered_unit_ids nicht")
	res = RECOVERY.advance([_respawner("r", 5.0, "ort_x")], 600.0)
	_check(String(res.units[0].recovery_state.pickup_location_id) == "ort_x", "advance: pickup_location_id bleibt (nicht fest polisa)")
	var waiting: Dictionary = {"unit_id": "w", "availability_status": "awaiting_pickup", "status_text": "awaiting_pickup", "recovery_state": {"state": "awaiting_pickup", "pickup_location_id": "polisa"}}
	res = RECOVERY.advance([waiting], 100000.0)
	_check(res.units[0] == waiting and not bool(res.changed), "advance: awaiting_pickup bleibt unveraendert, wird nie von selbst active")
	res = RECOVERY.advance([{"unit_id": "bad", "availability_status": "respawning"}, {"unit_id": "bad2", "availability_status": "respawning", "recovery_state": "kaputt"}, _respawner("zero", 0.0)], 1.0)
	_check(res.units[0].availability_status == "awaiting_pickup" and res.units[1].availability_status == "awaiting_pickup" and res.units[2].availability_status == "awaiting_pickup", "advance: respawning ohne/mit kaputter/leerer Restzeit gilt als abgelaufen, nie als active")
	_check(res.units[0].recovery_state.pickup_location_id == "polisa" and res.matured_unit_ids.size() == 3, "advance: Standardort polisa, drei matured")
	res = RECOVERY.advance([_respawner("r", 50.0)], 0.0)
	_check(not bool(res.changed) and is_equal_approx(float(res.units[0].recovery_state.seconds_remaining), 50.0), "advance: delta 0 aendert nichts (auch bei respawning)")
	res = RECOVERY.advance([_respawner("r", 50.0), _wounded("w", 30.0), {"unit_id": "a", "availability_status": "active"}], 60.0)
	_check(res.units[0].availability_status == "awaiting_pickup" and res.units[1].availability_status == "active" and res.units[2].availability_status == "active", "advance: gemischt: respawning -> awaiting_pickup, wounded -> active, active bleibt")
	_check(res.recovered_unit_ids == PackedStringArray(["w"]) and res.matured_unit_ids == PackedStringArray(["r"]), "advance: recovered nur der Verwundete, matured nur der Respawnende")
	# Texte
	_check(RECOVERY.describe(_respawner("r", 125.0)) == "gestorben, Respawn in 2:05", "describe: respawning 125 s -> 'gestorben, Respawn in 2:05'")
	_check(RECOVERY.describe(_respawner("r", 5400.0)) == "gestorben, Respawn in 1:30:00", "describe: ab einer Stunde h:mm:ss (5400 s)")
	_check(RECOVERY.describe(_respawner("r", 3599.0)) == "gestorben, Respawn in 59:59", "describe: 3599 s -> 59:59")
	_check(RECOVERY.describe(_respawner("r", 3600.0)) == "gestorben, Respawn in 1:00:00", "describe: 3600 s -> 1:00:00")
	_check(RECOVERY.describe(waiting) == "wartet auf Polisa", "describe: awaiting_pickup -> 'wartet auf Polisa'")
	_check(RECOVERY.describe(_wounded("w", 65.0, "medium")) == "Verwundet (mittel), noch 1:05", "describe: Verwundete unveraendert")
	_check(RECOVERY.describe({"availability_status": "active"}) == "", "describe: aktive Person leer")
	# Sperr-Auskunft
	_check(RECOVERY.is_blocked(_respawner("r", 5.0)) and RECOVERY.is_blocked(_respawner("r", 0.0)) and RECOVERY.is_blocked(waiting) and RECOVERY.is_blocked(_wounded("w", 10.0)), "is_blocked: respawning, awaiting_pickup und Verwundete mit Restzeit gesperrt")
	_check(not RECOVERY.is_blocked({"availability_status": "active"}) and not RECOVERY.is_blocked(_wounded("w", 0.0)) and not RECOVERY.is_blocked({"availability_status": "recovering"}), "is_blocked: active, abgelaufene Verwundung und recovering nicht gesperrt (wie bisher)")
	_check(not RECOVERY.is_wounded(_respawner("r", 5.0)) and not RECOVERY.is_wounded(waiting), "is_wounded: bleibt nur fuer Verwundete wahr")

func _set_state(unit_id: String, status: String, recovery_state: Dictionary) -> void:
	var units: Array = Array(_flow.get("_all_team_units")).duplicate(true)
	for unit: Dictionary in units:
		if String(unit.get("unit_id", "")) == unit_id:
			unit["availability_status"] = status
			unit["status_text"] = status
			unit["recovery_state"] = recovery_state
	_flow.call("_replace_roster_units", units)
	_feed()

func _flow_part() -> void:
	if not await _open("campaign", "new"): return
	_set_state(LEADER, "respawning", {"state": "respawning", "death_number": 1, "seconds_total": 3600.0, "seconds_remaining": 125.0, "pickup_location_id": "polisa", "source": "left_behind"})
	var lock: Dictionary = _lock()
	_check(lock.has(LEADER) and String(lock[LEADER]) == _name(LEADER) + ": gestorben, Respawn in 2:05", "Flow: Sperre fuer respawning '<Name>: gestorben, Respawn in 2:05' (%s)" % lock)
	var single: Dictionary = _board_one(LEADER)
	_check(not bool(single.get("ok", true)) and String(single.get("reason", "")) == "unit_wounded" and String(single.get("message", "")).contains("gestorben, Respawn in 2:05"), "Flow: Einschiffen des Gestorbenen abgelehnt, Meldung nennt Namen und Zeit (%s)" % single)
	var team: Dictionary = _board_team()
	_check(not bool(team.get("ok", true)), "Flow: Trupp mit dem Gestorbenen wird nicht eingeschifft (%s)" % team)
	_check(_nobody_embarking(), "Flow: niemand ist eingeschifft")
	# Takt: zwei Sekunden Echtzeit (je Frame bis 2,0 s gedeckelt).
	_flow.call("_tick_personnel_recovery", 2.0)
	_check(is_equal_approx(_remaining(LEADER), 123.0) and String(_roster_unit(LEADER).get("availability_status", "")) == "respawning", "Flow: Takt zieht 2 s ab (123 s, weiter respawning)")
	var lock_after: Dictionary = _lock()
	_check(lock_after.has(LEADER) and String(lock_after[LEADER]).ends_with("gestorben, Respawn in 2:03"), "Flow: Sperrtext zeigt die neue Restzeit (%s)" % lock_after)
	# Ablauf: awaiting_pickup, weiter gesperrt, nie active.
	_set_state(LEADER, "respawning", {"state": "respawning", "death_number": 1, "seconds_total": 3600.0, "seconds_remaining": 1.5, "pickup_location_id": "polisa", "source": "left_behind"})
	_flow.call("_tick_personnel_recovery", 2.0)
	var waiting: Dictionary = _roster_unit(LEADER)
	_check(String(waiting.get("availability_status", "")) == "awaiting_pickup" and Dictionary(waiting.get("recovery_state", {})) == {"state": "awaiting_pickup", "pickup_location_id": "polisa"}, "Flow: Ablauf: awaiting_pickup mit pickup_location_id polisa (%s)" % waiting)
	var lock_wait: Dictionary = _lock()
	_check(lock_wait.has(LEADER) and String(lock_wait[LEADER]) == _name(LEADER) + ": wartet auf Polisa", "Flow: Sperre fuer awaiting_pickup '<Name>: wartet auf Polisa' (%s)" % lock_wait)
	var single_wait: Dictionary = _board_one(LEADER)
	_check(not bool(single_wait.get("ok", true)) and String(single_wait.get("reason", "")) == "unit_wounded" and String(single_wait.get("message", "")).contains("wartet auf Polisa"), "Flow: Einschiffen des Wartenden abgelehnt (%s)" % single_wait)
	for i in range(5):
		_flow.call("_tick_personnel_recovery", 2.0)
	_check(String(_roster_unit(LEADER).get("availability_status", "")) == "awaiting_pickup" and _lock().has(LEADER), "Flow: nach weiteren Takten weiter awaiting_pickup und gesperrt (nie von selbst active)")
	# Wieder aktiv (Abholen ist R4): die Sperre faellt weg, sobald der Eintrag active ist.
	_set_state(LEADER, "active", {})
	_check(not _lock().has(LEADER), "Flow: active -> keine Sperre")
	await _close()
