extends "res://scripts/tests/campaign_casualty_departure_verifier.gd"
## Abgebrochener Besuch und Rueckflug in der Kampagne, Ende zu Ende mit echtem Einschiffen (Aufbau und Hilfen aus
## campaign_casualty_departure_verifier / campaign_casualty_apply_verifier).
## Der Auftrag ist angenommen, die Besatzung ist am Ort gelandet und hat nichts erledigt. Sie steigt wieder ein und das Schiff fliegt heim:
## Nach Regel 8 (docs/dev/campaign_casualty_retreat_contract.md) ist das ein Rueckzug. Der Auftrag steht danach auf failed mit
## reopen_at_home und retreat_count 1; der Heim-Speicherpunkt (alle 0,25 s an der Basis) oeffnet ihn wieder als accepted.
## Weiter wie schon vor der Umstellung: Orbit des Orts nach dem Abflug, Mondorbit, Landung an der Basis, Ort geschlossen,
## kein Ertrag und keine Belege.
## Entfallen ist der Rueckflug "solange das Schiff noch wartet" (Besatzung noch nicht gelandet): In der Kampagne verlangt
## return_homebase ein gelandetes Schiff (craft_not_landed), und der Orbit des Orts ist nicht mehr "planet_orbit".

func _run() -> void:
	_configure_entry()
	var s: Dictionary = await _begin_sortie()
	if s.is_empty():
		await _finish_aborted_visit()
		return
	var credits_before: int = int(_supply().get("credits", -1))
	var job_before: Dictionary = Dictionary(_campaign().jobs.satellite_recovery)
	_check(String(job_before.get("status", "")) == "active" and not bool(job_before.get("reopen_at_home", false)) and int(job_before.get("retreat_count", 0)) == 0, "Vor dem Rueckflug: Auftrag aktiv, ohne Rueckzug (%s)" % [job_before])
	_check(Dictionary(_campaign().get("completion_receipts", {})).is_empty() and credits_before > 0, "Vor dem Rueckflug: keine Belege, Guthaben vorhanden")
	# Die Besatzung hat nichts erledigt und steigt am Schiffszugang wieder ein.
	if not _seat_crew(s):
		await _finish_aborted_visit()
		return
	var retreat: Dictionary = _request_return()
	if not _check(bool(retreat.get("ok", false)), "Gelandetes Schiff mit Besatzung am Zugang nimmt den Rueckflug an (%s)" % [retreat]):
		await _finish_aborted_visit()
		return
	if not await _wait_departure_settled("Rueckzug"):
		print("DEPARTURE_ERROR ", _screen.get_meta("singleplayer_departure_error", {}))
		await _finish_aborted_visit()
		return
	await process_frame
	# Der Orbit des Orts kommt aus dem Reisestand, nicht aus einer festen Kennung (satellite_crash liegt seit 21c7c23b8 in glut_1a_orbit).
	var location_orbit: String = String(Dictionary(Dictionary(_runtime.call("get_space_travel_snapshot", _craft_id)).get("location_orbits", {})).get("satellite_crash", ""))
	var remote: bool = not location_orbit.is_empty() and location_orbit != "moon_orbit" and String(_space().get("orbit_id", "")) == location_orbit
	_check(remote, "Nach dem Abflug steht das Schiff im Orbit des Orts (%s), nicht im Mondorbit" % [location_orbit])
	var job_retreat: Dictionary = Dictionary(_campaign().jobs.satellite_recovery)
	_check(String(job_retreat.get("status", "")) == "failed" and bool(job_retreat.get("reopen_at_home", false)) and int(job_retreat.get("retreat_count", 0)) == 1, "Abflug ohne erledigten Auftrag ist ein Rueckzug: failed, reopen_at_home true, retreat_count 1 (%s)" % [job_retreat])
	_screen.call("request_operation", "space_start_quantum", {"craft_id": _craft_id, "target_orbit_id": "moon_orbit"})
	if not await _wait(func(): return String(_space().get("orbit_id", "")) == "moon_orbit", 60000, "Schiff erreicht den Mondorbit"):
		await _finish_aborted_visit()
		return
	var landed: Dictionary = _screen.call("request_operation", "space_land_homebase", {"craft_id": _craft_id})
	_check(bool(landed.get("ok", false)), "Landung an der Basis wird angenommen (%s)" % [landed])
	var closed: bool = _flow.get("_active_mission") == null
	_check(closed, "Nach der Heimkehr ist der Ort geschlossen")
	# Der Heim-Speicherpunkt laeuft an der Basis alle 0,25 s und oeffnet den Auftrag wieder.
	var reopened: bool = await _wait(func(): return String(Dictionary(_campaign().jobs.satellite_recovery).get("status", "")) == "accepted", 10000, "Heim-Speicherpunkt oeffnet den zurueckgezogenen Auftrag wieder")
	var job_home: Dictionary = Dictionary(_campaign().jobs.satellite_recovery)
	_check(reopened and not bool(job_home.get("reopen_at_home", true)) and int(job_home.get("retreat_count", 0)) == 1, "Wieder angenommen: reopen_at_home false, retreat_count weiter 1 (%s)" % [job_home])
	var snapshot: Dictionary = _flow.get_singleplayer_snapshot()
	var no_reward: bool = Dictionary(snapshot.campaign.get("completion_receipts", {})).is_empty() and int(snapshot.supply.credits) == credits_before
	_check(no_reward, "Kein Ertrag und keine Belege nach dem Rueckzug (Guthaben %s, vorher %s)" % [snapshot.supply.credits, credits_before])
	print("ABORTED_VISIT_RETURN closed=%s failed_then_reopened=%s no_reward=%s" % [closed, reopened, no_reward])
	await _finish_aborted_visit()

func _finish_aborted_visit() -> void:
	await _end_sortie()
	print("ABORTED_VISIT_RETURN_RESULTS passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)
