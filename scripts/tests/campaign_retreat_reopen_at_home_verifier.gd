extends "res://scripts/tests/campaign_casualty_departure_verifier.gd"
## Task 8b (Ausfall und Rueckzug): Ein Rueckzug laesst den Auftrag offen, und zwar im echten Spielablauf:
## Rueckzug im echten Kampagneneinsatz, Rueckflug ueber Orbit und Mondflug, ECHTE Landung des Schiffs zu Hause
## (der Ort des Schiffs wird nie von Hand gesetzt). Wieder geoeffnet wird ohne Zutun des Tests: durch den
## periodischen Speicherpunkt von MetaLayerFlow, der vor dem Basis-Checkpoint reopen_retreated_jobs() aufruft.
## R1: Rueckzug ueber Abflug (aborted / departure): vor der Heimkehr failed + reopen_at_home + retreat_count 1,
##     nach der Landung accepted, reopen_at_home false, retreat_count 1, Auftragstafel waehlbar, Truppfuehrer wounded/light.
## R2: gespeicherter Stand enthaelt den offenen Auftrag; Meta-Szene neu aufbauen und Kampagne fortsetzen.
## R3: Rueckzug ueber "Evakuieren" (Treiber-Weg des Knopfs: request_mission_evacuation): derselbe Ausgang.
## R4: kein Rueckzug: Hin- und Rueckflug ohne Ausfaelle, nichts wird wieder geoeffnet.
## R5: Totalverlust: nach dem Ruecksprung zum Checkpoint ist nichts wieder geoeffnet.
## Mit der Umgebungsvariable T8B_ONLY (zum Beispiel "R1") laeuft nur dieser Teil.

const JOB := "satellite_recovery"
const HOME_ORBIT := "moon_orbit"

func _run() -> void:
	_configure_entry()
	var only: String = OS.get_environment("T8B_ONLY").strip_edges().to_upper()
	if only.is_empty() or only == "R1":
		await _retreat_to_home("R1", "departure", true)
	if only.is_empty() or only == "R3":
		await _retreat_to_home("R3", "evacuation", false)
	if only.is_empty() or only == "R4":
		await _r4_no_retreat()
	if only.is_empty() or only == "R5":
		await _r5_total_loss()
	print("CAMPAIGN_RETREAT_REOPEN passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _job() -> Dictionary:
	return Dictionary(Dictionary(_campaign().jobs).get(JOB, {}))

func _job_line() -> String:
	var job: Dictionary = _job()
	return "status=%s retreat_count=%s reopen_at_home=%s" % [job.get("status"), job.get("retreat_count", "none"), job.get("reopen_at_home", "none")]

## Wie der Heimflug im Zwei-Monde-Test: Orbit des Einsatzorts, Quantensprung zum Mondorbit, echte Landung zu Hause.
func _return_to_home(location_id: String) -> bool:
	var orbit := String(Dictionary(_space().get("location_orbits", {})).get(location_id, ""))
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == orbit, 120000, "Schiff erreicht den Orbit des Einsatzorts"): return false
	var jump: Dictionary = _screen.call("request_operation", "space_start_quantum", {"craft_id": _craft_id, "target_orbit_id": HOME_ORBIT})
	if not _check(jump.get("ok", false), "Quantensprung zum Heimatorbit wird angenommen"):
		print("HOME_WARP ", jump)
		return false
	if not await _wait(func(): return String(_space().get("phase", "")) == "orbit" and String(_space().get("orbit_id", "")) == HOME_ORBIT, 180000, "Schiff erreicht den Heimatorbit"): return false
	var land: Dictionary = _screen.call("request_operation", "space_land_homebase", {"craft_id": _craft_id})
	if not _check(land.get("ok", false), "Landung auf der Heimatbasis wird angenommen"):
		print("HOME_LAND ", land)
		return false
	return await _wait(func():
		var ship: Dictionary = _craft(_flow.call("get_singleplayer_snapshot"))
		return String(ship.get("location_id", "")) == "homebase" and not bool(ship.get("busy", true)), 120000, "das Schiff ist wirklich zu Hause gelandet")

func _stand_leader_up(s: Dictionary, tag: String) -> bool:
	var leader: Node2D = s.leader
	var driver: Node = s.driver
	leader.call("apply_damage", 10000)
	if not await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)), 5000, tag + ": Treiber merkt sich die ausgefallene Person"): return false
	return _check(bool(leader.call("apply_heal", 10, {})) and String(leader.call("get_vital_state")) == "fit", tag + ": Truppfuehrer innerhalb der Frist aufgerichtet")

func _availability() -> Dictionary:
	var snapshot: Dictionary = _runtime.call("get_snapshot")
	return Dictionary(Dictionary(snapshot.get("campaign", {})).get("job_availability", {})).get(JOB, {})

func _checkpoint_job() -> Dictionary:
	var loaded: Dictionary = STORE.load_checkpoint()
	if not bool(loaded.get("ok", false)):
		return {}
	return Dictionary(Dictionary(Dictionary(Dictionary(loaded.get("payload", {})).get("campaign", {})).get("jobs", {})).get(JOB, {}))

## R1 (via departure) und R3 (via evacuation): derselbe Ausgang.
func _retreat_to_home(tag: String, via: String, with_save_and_continue: bool) -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	if not await _stand_leader_up(s, tag): return
	if not _seat_crew(s): return
	_check(_job_status() == "active", tag + ": Auftrag war aktiv")
	if via == "departure":
		var departure: Dictionary = _press_return(true, s)
		_check(bool(departure.get("ok", false)), tag + ": Abflug ueber den HUD-Weg wird angenommen")
	else:
		var evacuation: Dictionary = s.driver.call("request_mission_evacuation")
		print(tag, "_EVAC ", evacuation)
		_check(bool(evacuation.get("accepted", false)), tag + ": Evakuieren (Treiber-Weg des Knopfs) wird angenommen")
	if not await _wait(func(): return _flow.get("_active_mission") == null, 120000, tag + ": Einsatz wird freigegeben"): return
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result")).duplicate(true)
	_check(String(result.get("result", "")) == "aborted" and String(result.get("win_condition_type", "")) == ("departure" if via == "departure" else "evacuation"), tag + ": Ergebnis aborted / " + via)
	var casualty: Dictionary = _casualty_entry(result, "campaign_leader")
	_check(String(casualty.get("recovery_severity", "")) == "light" and is_equal_approx(float(casualty.get("recovery_seconds_remaining", -1.0)), 180.0) and is_equal_approx(float(casualty.get("recovery_seconds_total", -1.0)), 180.0), tag + ": Ergebnis traegt die angewendete Verwundung (light, 180.0, 180.0)")
	var before: Dictionary = _job()
	print(tag, "_BEFORE_HOME ", _job_line(), " location=", _craft_location(), " space=", _space().get("phase"))
	_check(String(before.get("status", "")) == "failed" and bool(before.get("reopen_at_home", false)) and int(before.get("retreat_count", 0)) == 1, tag + ": vor der Heimkehr: failed, reopen_at_home true, retreat_count 1")
	if via == "departure":
		_check(await _wait_departure_settled(tag), tag + ": das Schiff fliegt ab und erreicht den Orbit")
	else:
		await _evacuation_to_orbit(tag)
	_check(_job_status() == "failed" and bool(_job().get("reopen_at_home", false)), tag + ": im Orbit, noch nicht zu Hause: Auftrag bleibt failed mit gesetztem Merker (%s)" % _job_line())
	if not await _return_to_home("satellite_crash"): return
	print(tag, "_LANDED ", _job_line(), " location=", _craft_location())
	# Wieder geoeffnet wird vom periodischen Speicherpunkt (0,25 s), ohne dass der Test etwas aufruft.
	if not await _wait(func(): return _job_status() == "accepted", 15000, tag + ": Auftrag steht nach der Landung von allein wieder auf accepted"): return
	var after: Dictionary = _job()
	_check(String(after.get("status", "")) == "accepted" and not bool(after.get("reopen_at_home", true)) and int(after.get("retreat_count", 0)) == 1, tag + ": nach der Landung: accepted, reopen_at_home false, retreat_count 1 (%s)" % _job_line())
	var availability: Dictionary = _availability()
	var snapshot: Dictionary = _runtime.call("get_snapshot")
	var location: Dictionary = Dictionary(Dictionary(Dictionary(snapshot.get("campaign", {})).get("location_availability", {})).get("satellite_crash", {}))
	print(tag, "_AVAILABILITY job=", availability, " location=", location)
	_check(bool(availability.get("visible", false)) and not bool(availability.get("can_accept", true)), tag + ": Auftragstafel: sichtbar, ohne Erneut annehmen (can_accept false, weil schon angenommen)")
	_check(bool(location.get("ok", false)), tag + ": Einsatzort ist anfliegbar (location_availability ok)")
	var unit: Dictionary = _roster_unit("campaign_leader")
	_check(String(unit.get("availability_status", "")) == "wounded" and String(Dictionary(unit.get("recovery_state", {})).get("severity", "")) == "light", tag + ": Truppfuehrer ist wounded mit light")
	# Der gespeicherte Stand enthaelt den offenen Auftrag.
	var saved: Dictionary = _flow.call("request_campaign_save")
	_check(bool(saved.get("ok", false)), tag + ": Speichern zu Hause gelingt")
	var stored: Dictionary = _checkpoint_job()
	_check(String(stored.get("status", "")) == "accepted" and int(stored.get("retreat_count", 0)) == 1 and not bool(stored.get("reopen_at_home", false)), tag + ": gespeicherter Stand: Auftrag accepted, retreat_count 1, reopen_at_home false")
	if with_save_and_continue:
		_flow.queue_free()
		await process_frame
		START.request_start(self, "campaign", "continue")
		_flow = FLOW.instantiate()
		root.add_child(_flow)
		current_scene = _flow
		await process_frame
		_screen = _flow.get_node("HomebaseScreen")
		_runtime = _flow.get("_singleplayer_runtime")
		var resumed: Dictionary = _job()
		print("R2_RESUMED ", _job_line())
		_check(String(resumed.get("status", "")) == "accepted" and int(resumed.get("retreat_count", 0)) == 1 and not bool(resumed.get("reopen_at_home", false)), "R2: nach Neuaufbau und Fortsetzen: Auftrag accepted, retreat_count 1")
		await create_timer(1.0).timeout
		_check(String(_job().get("status", "")) == "accepted" and int(_job().get("retreat_count", 0)) == 1, "R2: auch nach einer Sekunde Spielzeit unveraendert (%s)" % _job_line())
		_check(_screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": JOB}).get("ok", false), "R2: Ziel waehlbar ohne Erneut annehmen")
	await _end_sortie()

## Evakuieren beendet den Einsatz wie der Abflug; wohin das Schiff danach kommt, wird hier nur beobachtet.
func _evacuation_to_orbit(tag: String) -> void:
	var reached: bool = await _wait(func(): return String(_space().get("phase", "")) == "orbit", 60000, tag + ": Schiff erreicht nach Evakuieren den Orbit")
	print(tag, "_EVAC_STATE reached=", reached, " location=", _craft_location(), " space=", _space().get("phase"), " transfer=", _transfer_phase(), " view=", _flow.get("_current_meta_view"))

## R4: kein Rueckzug. Hin- und Rueckflug ohne Ausfaelle: Auftragsstatus wie vor der Aenderung (failed, retreat_count 0).
func _r4_no_retreat() -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	if not _seat_crew(s): return
	var departure: Dictionary = _request_return()
	_check(bool(departure.get("ok", false)), "R4: Rueckflug ohne Ausfaelle wird angenommen")
	if not await _wait_departure_settled("R4"): return
	print("R4_BEFORE_HOME ", _job_line())
	if not await _return_to_home("satellite_crash"): return
	await create_timer(2.0).timeout
	var job: Dictionary = _job()
	print("R4_OBSERVED ", _job_line(), " location=", _craft_location(), " history=", job.keys())
	_check(String(job.get("status", "")) == "failed", "R4: Auftragsstatus nach der Heimkehr wie vor der Aenderung: failed (%s)" % _job_line())
	_check(int(job.get("retreat_count", 0)) == 0 and not bool(job.get("reopen_at_home", false)), "R4: retreat_count 0, kein reopen_at_home")
	_check(not bool(_availability().get("can_accept", false)) or String(_job().get("status", "")) == "failed", "R4: Auftragstafel unveraendert zur Vergleichsbasis (%s)" % _availability())
	await _end_sortie()

## R5: Totalverlust (Truppfuehrer liegt, Abflugversuch): nach dem Ruecksprung zum Checkpoint ist nichts wieder geoeffnet.
func _r5_total_loss() -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	var leader: Node2D = s.leader
	var driver: Node = s.driver
	leader.call("apply_damage", 10000)
	if not await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)), 5000, "R5: Treiber merkt sich die ausgefallene Person"): return
	_check(String(leader.call("get_vital_state")) != "fit", "R5: Truppfuehrer liegt")
	if not _seat_crew(s): return
	_press_return(true, s)
	if not await _wait(func(): return _flow.get("_active_mission") == null, 120000, "R5: Einsatz wird freigegeben"): return
	await process_frame
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result")).duplicate(true)
	_check(bool(result.get("casualty_total_loss", false)) and String(result.get("result", "")) == "defeat", "R5: Totalverlust, defeat")
	await create_timer(1.5).timeout
	var lost: Dictionary = _job()
	print("R5_AFTER_LOSS ", _job_line())
	_check(String(lost.get("status", "")) == "failed" and int(lost.get("retreat_count", 0)) == 0 and not bool(lost.get("reopen_at_home", false)), "R5: nach dem Totalverlust: failed, retreat_count 0, kein reopen_at_home (%s)" % _job_line())
	var button: Button = _flow.get_node("DebriefScreen/Panel/Margin/VBox/ButtonRow/ReturnToHomebaseButton")
	_check(not button.disabled, "R5: Debrief bietet den Ruecksprung zum Checkpoint an")
	button.pressed.emit()
	await process_frame
	await process_frame
	_flow = current_scene
	_runtime = _flow.get("_singleplayer_runtime")
	_screen = _flow.get_node("HomebaseScreen")
	await create_timer(1.5).timeout
	var jumped: Dictionary = _job()
	print("R5_AFTER_JUMP ", _job_line())
	_check(String(jumped.get("status", "")) != "failed" and int(jumped.get("retreat_count", 0)) == 0 and not bool(jumped.get("reopen_at_home", false)), "R5: nach dem Ruecksprung: retreat_count 0, kein reopen_at_home, nichts wieder geoeffnet (%s)" % _job_line())
	await _end_sortie()
