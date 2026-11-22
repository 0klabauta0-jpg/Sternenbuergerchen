extends "res://scripts/tests/campaign_save_first_part_verifier.gd"
## Abschnitt P, Nachbesserung 1: Pleite an echten Einsatzorten (K1) und Verkaufserloes (W1), ohne _location_contexts von Hand zu setzen.
## V1: echter Polisa-Besuch ohne Auftrag (Schiff parkt dort, Besuch ist Leerlauf): kein Treibstoff, Schulden am Rahmen -> Bildschirm.
##     Mit verkaufbarer Ware im Schiffslager (erreichbarer Kontostand im Plus) nicht pleite, ohne sie pleite.
## V2: echter Einsatz (Auftrag aktiv, Gefecht laeuft): keine Pruefung; nach der Buchung des Ergebnisses und der Heimkehr schon.
## Abschlusszeile: CAMPAIGN_BANKRUPTCY_VISIT passed=%d failed=%d

const BV_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const BV_SCREEN := "CampaignBankruptcyScreen"

func _run() -> void:
	var verdict: Dictionary = BV_GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_BANKRUPTCY_VISIT refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	_configure_entry()
	await _v1_visit()
	await _v2_mission()
	paused = false
	print("CAMPAIGN_BANKRUPTCY_VISIT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _bv_screens() -> int:
	var count := 0
	if _flow != null and is_instance_valid(_flow):
		for child: Node in _flow.get_children():
			if child.name == BV_SCREEN: count += 1
	return count

func _bv_fuel(value: float) -> void:
	var tanks: Dictionary = _runtime.get("_supply").get("_fuel_by_craft_id")
	for tank_id: String in tanks.keys(): tanks[tank_id] = value

func _bv_debt(debt: int) -> void:
	var now: int = int(_runtime.call("get_campaign_credits"))
	_runtime.call("charge_campaign_rescue_fee", now + debt)

func _v1_visit() -> void:
	if await _fp_ready_to_launch("V1") != "": return
	if await _nd_to_polisa("V1") != "": return
	var visit: Node = _flow.get("_active_mission")
	_check(is_instance_valid(visit) and String(visit.get_meta("location_id", "")) == "polisa", "V1: Fixture: echter Polisa-Besuch, die Instanz ist der aktive Ort")
	_check(not Dictionary(_flow.get("_location_contexts")).is_empty() and bool(_flow.call("_campaign_location_visit_idle", visit)), "V1: Fixture: der Ort steht in den Kontexten und der Besuch ist Leerlauf (kein Auftrag)")
	_bv_fuel(0.0)
	_bv_debt(1600)
	_check(int(_runtime.call("get_campaign_credits")) == -1600, "V1: Fixture: Konto -1600, Tank leer")
	# W1: 300 Erz im Schiffslager (je 6 Cr beim Haendler von Polisa) = 1800 Cr: der erreichbare Kontostand ist im Plus.
	var items: Dictionary = Dictionary(_runtime.get("_supply").get("_inventory")["craft:" + _craft_id].items)
	items["ore"] = 300
	var with_ore: Dictionary = _runtime.call("get_bankruptcy_check")
	_check(not bool(with_ore.get("bankrupt", true)), "V1 W1: mit verkaufbarem Erz im Schiffslager wird nicht fuer pleite erklaert (%s)" % [with_ore])
	_flow.call("_check_bankruptcy")
	await process_frame
	_check(_bv_screens() == 0 and not paused, "V1 W1: kein Pleite-Bildschirm, solange der Verkauf noch hilft")
	# Ohne die Ware: der Besuch ist Leerlauf, das Schiff liegt fest -> der Bildschirm erscheint (K1).
	items.erase("ore")
	_flow.call("_check_bankruptcy")
	await process_frame
	_check(_bv_screens() == 1 and paused and bool(_flow.call("is_campaign_bankrupt")), "V1 K1: Schiff liegt nach einem echten Ortsbesuch fest: der Bildschirm erscheint, die Zeit steht")
	await _end_sortie()
	paused = false

func _v2_mission() -> void:
	var s: Dictionary = await _begin_sortie()
	if s.is_empty(): return
	var job_status: String = _bv_job_status("satellite_recovery")
	_check(job_status == "active", "V2: Fixture: der Auftrag laeuft (Status %s)" % job_status)
	_bv_debt(1600)
	_bv_fuel(0.0)
	_flow.call("_check_bankruptcy")
	await process_frame
	_check(_bv_screens() == 0 and not paused, "V2: waehrend des laufenden Bodeneinsatzes wird nicht geprueft")
	# Einsatz beenden (Rueckzug zum Schiff und Heimkehr wie in campaign_casualty_apply_verifier), Ergebnis wird gebucht.
	_bv_fuel(60.0)
	var driver: Node = s.driver
	if not _place_at(s.simulation, s.access, "campaign_leader", Vector2.ZERO): return
	if not _place_at(s.simulation, s.access, "campaign_pilot", Vector2.ZERO): return
	driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("V2: Einsatz wird freigegeben"): return
	await process_frame
	_check(_bv_screens() == 0, "V2: die Freigabe allein loest noch keinen Bildschirm aus (die Pruefung lief nicht)")
	_bv_fuel(0.0)
	_flow.call("_check_bankruptcy")
	await process_frame
	_check(_bv_screens() == 1 and paused, "V2: nach dem Buchen des Ergebnisses und der Heimkehr erscheint der Bildschirm (Orte bleiben in den Kontexten: %d)" % Dictionary(_flow.get("_location_contexts")).size())
	await _end_sortie()
	paused = false

func _bv_job_status(job_id: String) -> String:
	var campaign_owner: Object = _runtime.get("_campaign")
	return String(Dictionary(Dictionary(campaign_owner.call("get_campaign_snapshot")).get("jobs", {})).get(job_id, {}).get("status", ""))
