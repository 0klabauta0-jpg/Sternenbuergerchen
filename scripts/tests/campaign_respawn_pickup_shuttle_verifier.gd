extends "res://scripts/tests/hex_base_boarding_verifier.gd"
## R4c Respawn (Abholen auf Polisa), Punkt 6: Der Stationsshuttle-Weg (admit_polisa_shuttle_home) bleibt Anwerbungen vorbehalten.
## Wer nach einem Ausfall wartet (respawning oder awaiting_pickup), kommt dort nicht heim: abgelehnt, Basis-Zustand bleibt station,
## kein Bodenplatz, keine Veroeffentlichung durch den Shuttle. Die Kontrolle (Anwerbung ohne Ausfall) wird wie bisher aufgenommen.
## Gleiche Vorrichtung wie hex_base_boarding_verifier (Scope, FakeShuttle). Abschlusszeile: CAMPAIGN_RESPAWN_PICKUP_SHUTTLE passed=%d failed=%d

const PICKUP_SHUTTLE_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")

## Erste Anweisung: die Schutzpruefung des Wegwerfprofils, bevor die Vorlage irgendetwas aufbaut oder schreibt.
func _run() -> void:
	var verdict: Dictionary = PICKUP_SHUTTLE_GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_RESPAWN_PICKUP_SHUTTLE refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	await super._run()

func _finish() -> void:
	if failed == 0:
		_shuttle_case("respawning", false)
		_shuttle_case("awaiting_pickup", false)
		_shuttle_case("active", true)
	print("CAMPAIGN_RESPAWN_PICKUP_SHUTTLE passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _shuttle_case(status: String, expect_admitted: bool) -> void:
	var rig: Dictionary = _base_rig()
	rig.scene.set_script(Scope)
	var shuttle := FakeShuttle.new()
	rig.scene._polisa_shuttle = shuttle
	rig.base._navigation_graph = null
	var profile: Dictionary = {"unit_id": "polisa_recruit_station", "display_name": "Recruit", "recruit_location": "polisa"}
	if status != "active":
		profile["availability_status"] = status
		profile["recovery_state"] = {"state": status, "pickup_location_id": "polisa"}
	else:
		profile["availability_status"] = "active"
	rig.base._flow._all_team_units.append(profile)
	rig.base.sync_roster()
	rig.base._navigation_graph = Navigation.new()
	rig.base._navigation_graph.terrain = rig.terrain
	var result: Dictionary = rig.base.admit_polisa_shuttle_home("polisa_recruit_station", {"verified": true}, Vector2i(1, 0))
	var base_status: String = String(rig.base._states.polisa_recruit_station.status)
	if expect_admitted:
		_check(bool(result.get("ok", false)) and shuttle.published and base_status == "outside" and not rig.sim.get_hex_unit_state("polisa_recruit_station").is_empty(), "Kontrolle: eine Anwerbung (%s) wird ueber den Shuttle aufgenommen (%s)" % [status, result])
	else:
		_check(not bool(result.get("ok", false)), "%s: der Shuttleweg lehnt ab (%s)" % [status, result])
		_check(base_status == "station" and rig.sim.get_hex_unit_state("polisa_recruit_station").is_empty() and not shuttle.published and rig.sim.get_hex_ground_planning_snapshot().admission_slots_by_grid.is_empty(), "%s: Basis-Zustand bleibt station, kein Bodenplatz, nichts veroeffentlicht (%s)" % [status, base_status])
	rig.scene.free()
