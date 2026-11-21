extends "res://scripts/tests/campaign_respawn_pickup_verifier.gd"
## R4e Respawn (Punkt 9 und M3): Eine alte Verlustmeldung wird nicht doppelt gezaehlt. Echte Meta-Szene mit vier Personen
## (A Truppfuehrer Platz 0, Pilot Platz 1, B Truppfuehrer in ft1 mit A, C Schuetze allein in ft2).
## D1 Vor dem Abholen: B ist gestorben (erst respawning, dann awaiting_pickup). Eine zweite Zustellung desselben Ergebnisses ueber den echten
##    Eingang _on_mission_combat_resolved nach dem Ende des Einsatzes (_active_mission == null) bewirkt nichts: kein zweiter Zaehlerschritt,
##    kein endgueltiger Tod, Zustand, Loadout, Gefallenenliste unveraendert.
## D2 Nach dem Abholen (B wieder active, in einem neuen Trupp, mit Grundausstattung): dieselbe zweite Zustellung aendert weder Zaehler noch Status
##    NOCH nimmt sie B den Trupp oder die neue Grundausstattung (M3).
## Gebaut: das Ergebnis (aus den echten Regeln, resolve_mission) und das Abholen ueber die Besitzer-Aufrufe mark_recruit_remote und complete_campaign_pickup
##    (wie campaign_respawn_pickup_verifier P4); der echte Flug nach Polisa steht in campaign_respawn_pickup_verifier P1 und campaign_respawn_no_dead_end_verifier.
## NICHT ABGEDECKT (Absicht, nicht vergessen): Der Fall einer Orts-Instanz, in der _run_location_callback (meta_layer_flow.gd) _active_mission vor dem Aufruf
##    von _on_mission_combat_resolved wieder setzt, sodass die Null-Pruefung nicht schuetzt (r4-respawn-report.md Abschnitt f, Vermutung: die Verluste werden bei jedem
##    Ende neu aus den Merkern des Treibers berechnet, die nach dem Ende geloescht sind). Ein echter Ablauf braeuchte zwei Einsaetze am selben Ort mit einer Abholung dazwischen
##    (zwei volle Missionsfluege, je mehrere Minuten) und ist hier nicht gebaut.
## NICHT ABGEDECKT (Absicht): ein direkter zweiter Aufruf von _apply_campaign_casualties mit dem alten Ergebnis NACH dem Abholen. Der Schutz dort (already_booked)
##    haengt am Status respawning; eine active gewordene Person wird nicht durch ein Merkmal am Ergebnis geschuetzt. D2 misst das nur (RDE_R_DIRECT), ohne Erwartung.
## Abschlusszeile: CAMPAIGN_RESPAWN_REDELIVERY passed=%d failed=%d
## Einzeln starten: Kommandozeilenargument nach "--" (zum Beispiel "-- D1").

const REDELIVERY_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")

func _run() -> void:
	var verdict: Dictionary = REDELIVERY_GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_RESPAWN_REDELIVERY refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	_configure_entry()
	var selected: Array = []
	for arg: String in OS.get_cmdline_user_args():
		if not arg.strip_edges().is_empty():
			selected.append(arg.strip_edges().to_upper())
	for scenario: String in ["D1", "D2"]:
		if not selected.is_empty() and not selected.has(scenario):
			continue
		print("--- ", scenario)
		await call("_rd_" + scenario.to_lower())
		await _end_sortie()
	print("CAMPAIGN_RESPAWN_REDELIVERY passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _rd_status(unit_id: String) -> String:
	var status: Variant = _roster_unit(unit_id).get("availability_status")
	return "" if status == null else String(status)

## Alles, was eine zweite Zustellung nicht anfassen darf, als ein Vergleichswert.
func _rd_picture(unit_id: String) -> String:
	return JSON.stringify({
		"unit": _roster_unit(unit_id),
		"roster_ids": _t6b_roster_ids(),
		"fallen": _runtime.call("get_fallen"),
		"loadout": _rg_loadouts().get(unit_id, {}),
		"backpack": _rg_inventory().get("unit:%s:backpack" % unit_id, {}),
		"places": _rg_definition_places(unit_id),
		"base": _ra_base_status(unit_id),
	}, "", true)

## Zweite Zustellung desselben Ergebnisses ueber den echten Eingang; der Einsatz ist zu Ende (_active_mission == null).
func _rd_redeliver(result: Dictionary, tag: String, unit_id: String) -> void:
	if not _check(_flow.get("_active_mission") == null, "%s: Fixture: der Einsatz ist zu Ende (_active_mission ist null)" % tag): return
	var before: String = _rd_picture(unit_id)
	var used_before: int = int(_roster_unit(unit_id).get("respawns_used", -1))
	var status_before: String = _rd_status(unit_id)
	_flow.call("_on_mission_combat_resolved", result.duplicate(true))
	_check(int(_roster_unit(unit_id).get("respawns_used", -2)) == used_before, "%s: kein zweiter Zaehlerschritt (respawns_used %d bleibt, ist %s)" % [tag, used_before, _roster_unit(unit_id).get("respawns_used")])
	_check(_rd_status(unit_id) == status_before and _ra_fallen(unit_id).is_empty() and _t6b_roster_ids().has(unit_id), "%s: kein endgueltiger Tod, Status bleibt %s und %s steht im Kader" % [tag, status_before, unit_id])
	_check(_rd_picture(unit_id) == before, "%s: Eintrag, Kader, Gefallenenliste, Loadout, Rucksack, Trupp-Plaetze und Basis-Zustand von %s sind unveraendert" % [tag, unit_id])

func _rd_d1() -> void:
	if not await _t6b_new_four(): return
	_flow.set("_active_singleplayer_identity", {})
	var result: Dictionary = _ra_result(_t6b_states({LEAD_B: "down"}), "aborted", 3)
	_check(not bool(result.get("casualty_total_loss", true)) and PackedStringArray(result.get("respawn_unit_ids", PackedStringArray())) == PackedStringArray([LEAD_B]), "D1: Aufbau: das Ergebnis (aus den echten Regeln) macht B zum Wiederkehrer")
	_flow.call("_apply_campaign_casualties", result)
	_check(_rd_status(LEAD_B) == "respawning" and int(_roster_unit(LEAD_B).get("respawns_used", -1)) == 1, "D1: B ist respawning, respawns_used 1")
	_rd_redeliver(result, "D1 (respawning)", LEAD_B)
	_pk_mature(LEAD_B)
	_check(_rd_status(LEAD_B) == "awaiting_pickup", "D1: nach Ablauf der Uhr wartet B")
	_rd_redeliver(result, "D1 (awaiting_pickup)", LEAD_B)

func _rd_d2() -> void:
	if not await _t6b_new_four(): return
	_flow.set("_active_singleplayer_identity", {})
	_craft_id = String(Dictionary(Array(_flow.get("_homebase_aircraft_definitions"))[0]).get("craft_id", ""))
	var result: Dictionary = _ra_result(_t6b_states({LEAD_B: "down"}), "aborted", 3)
	_flow.call("_apply_campaign_casualties", result)
	var respawns_used: int = int(_roster_unit(LEAD_B).get("respawns_used", -1))
	_pk_mature(LEAD_B)
	if not _check(_rd_status(LEAD_B) == "awaiting_pickup" and _ra_base_status(LEAD_B) == "station", "D2: Aufbau: B wartet auf Abholung (station)"): return
	var boarded: Dictionary = _t6b_base().call("mark_recruit_remote", LEAD_B, _craft_id)
	if not _check(bool(boarded.get("ok", false)) and _ra_base_status(LEAD_B) == "aboard", "D2: Aufbau: B ist an Bord des Heimschiffs (%s)" % [boarded]): return
	var done: Dictionary = _flow.call("complete_campaign_pickup", LEAD_B)
	if not _check(bool(done.get("ok", false)) and _rd_status(LEAD_B) == "active", "D2: B ist abgeholt (active) (%s)" % [done]): return
	var out: Dictionary = _t6b_base().call("request_operation", "base_unboard", {"unit_id": LEAD_B, "craft_id": _craft_id})
	await _pk_wait(func(): return _ra_base_status(LEAD_B) == "outside", 60000)
	if not _check(bool(out.get("ok", false)) and _ra_base_status(LEAD_B) == "outside", "D2: B steht an der Basis (%s)" % [out]): return
	# B bekommt nach dem Abholen einen Trupp (neu eingeteilt) und eine eigene Ausruestung ueber die Grundausstattung.
	var known: Array = _rg_team_ids()
	var added: Dictionary = _screen.call("request_operation", "add_fireteam", {})
	var new_team: String = ""
	for team_id: String in _rg_team_ids():
		if not known.has(team_id):
			new_team = team_id
	var assigned: Dictionary = _screen.call("request_operation", "assign", {"unit_id": LEAD_B, "fireteam_id": new_team})
	if not _check(bool(added.get("ok", false)) and bool(assigned.get("ok", false)) and _rg_team_members(new_team).has(LEAD_B), "D2: Aufbau: B steht im neuen Trupp %s (%s / %s)" % [new_team, added, assigned]): return
	var expected: Dictionary = _pk_recruit_loadout("operator")
	_check(not expected.is_empty() and Dictionary(_rg_loadouts().get(LEAD_B, {})) == expected, "D2: Aufbau: B hat die Grundausstattung der Abgeholten (%s gegen %s)" % [_rg_loadouts().get(LEAD_B), expected])
	var before_team: Array = _rg_team_members(new_team)
	_rd_redeliver(result, "D2 (nach dem Abholen)", LEAD_B)
	_check(_rg_team_members(new_team) == before_team and _rg_team_members(new_team).has(LEAD_B), "D2 (M3): B behaelt den Trupp %s (%s)" % [new_team, _rg_team_members(new_team)])
	_check(Dictionary(_rg_loadouts().get(LEAD_B, {})) == expected, "D2 (M3): B behaelt die neue Grundausstattung (%s)" % [_rg_loadouts().get(LEAD_B)])
	_check(_rd_status(LEAD_B) == "active" and Dictionary(_roster_unit(LEAD_B).get("recovery_state", {})).is_empty() and int(_roster_unit(LEAD_B).get("respawns_used", -1)) == respawns_used, "D2: B bleibt active, ohne Ausfalldaten, respawns_used %d" % respawns_used)
	# Messung ohne Erwartung: ein direkter zweiter Aufruf von _apply_campaign_casualties (kein Weg des Spiels, siehe Kopf).
	var applied: Dictionary = _flow.call("_apply_campaign_casualties", result.duplicate(true))
	print("RDE_R_DIRECT status_after=", _rd_status(LEAD_B), " respawns_used_after=", _roster_unit(LEAD_B).get("respawns_used"), " respawn_unit_ids=", applied.get("respawn_unit_ids"))
