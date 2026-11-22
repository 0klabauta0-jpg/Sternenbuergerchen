extends "res://scripts/tests/tanker_emergency_flow_verifier.gd"
## Abschnitt P, Nachbesserung 1 (W2, W4): Pleite im Orbit mit dem echten Nottankdienst. Echte Szene, echter Flug zum Orbit eines Ortes,
## echter Versorgungsstand, echte Bestellung ueber den Befehlsweg (Zeiten wie in tanker_emergency_flow_verifier verkuerzt).
## B1: Schiff im Ortsorbit ohne Treibstoff. Bei -1450 wuerde der Tanker (280 Cr) ueber den Rahmen fuehren: pleite. Bei +10 liefert er auf Kredit: nicht pleite.
## B2: echte offene Bestellung: nicht pleite, solange sie offen ist; nach dem Storno (Erstattung) und nach der Lieferung neu bewertet.
## Abschlusszeile: CAMPAIGN_BANKRUPTCY_FLOW passed=%d failed=%d

const BF_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const BF_SCREEN := "CampaignBankruptcyScreen"

func _run() -> void:
	var verdict: Dictionary = BF_GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_BANKRUPTCY_FLOW refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	await _b1_band()
	await _b2_real_order()
	paused = false
	print("CAMPAIGN_BANKRUPTCY_FLOW passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _bf_screens(s: Dictionary) -> int:
	var count := 0
	for child: Node in s.flow.get_children():
		if child.name == BF_SCREEN: count += 1
	return count

func _bf_orbit_session() -> Dictionary:
	var s: Dictionary = await _session(25.0)
	var launch: Dictionary = _launch(s)
	if not _check(launch.get("ok", false) and _phase(s) == "orbit", "Sitzung: Abheben angenommen, Mondorbit: " + str(launch)): return {}
	var jump: Dictionary = _jump(s)
	if not _check(bool(jump.get("ok", false)), "Sitzung: Sprung zum Ortsorbit angenommen: " + str(jump)): return {}
	var arrived: bool = await _wait_for(s, func() -> bool: return _phase(s) == "orbit" and String(s.runtime.get_space_travel_snapshot(s.craft_id).get("orbit_id", "")) == _site_orbit(s), 40000)
	if not _check(arrived, "Sitzung: das Schiff ist im Orbit des Ortes angekommen (Phase %s)" % _phase(s)): return {}
	return s

func _bf_set(s: Dictionary, credits: int, fuel: float) -> void:
	var now: int = s.supply.get_credits()
	if now > credits: s.runtime.charge_campaign_rescue_fee(now - credits)
	s.supply.get("_fuel_by_craft_id")[s.craft_id] = fuel

func _b1_band() -> void:
	var s: Dictionary = await _bf_orbit_session()
	if s.is_empty(): return
	_bf_set(s, -1450, 0.0)
	var status: Dictionary = s.runtime.get_fuel_status(s.craft_id)
	_check(bool(status.get("stranded", false)) and bool(status.get("fuel_problem", false)), "B1: Fixture: das Schiff liegt im Ortsorbit fest und der Tanker waere zustaendig (%s)" % [status])
	var offer: Dictionary = s.runtime.preview_emergency_tanker(s.craft_id)
	_check(String(offer.get("reason", "")) == "debt_limit_reached", "B1: Fixture: der echte Tanker lehnt bei -1450 wegen des Rahmens ab (%s)" % [offer.get("reason", "")])
	s.flow.call("_check_bankruptcy")
	await process_frame
	_check(_bf_screens(s) == 1 and paused, "B1 W2: -1450 im Orbit ohne Treibstoff, Tanker wuerde ablehnen: pleite (Bildschirm, Zeit steht)")
	await _close(s)
	paused = false
	var t: Dictionary = await _bf_orbit_session()
	if t.is_empty(): return
	_bf_set(t, 10, 0.0)
	var on_credit: Dictionary = t.runtime.preview_emergency_tanker(t.craft_id)
	_check(bool(on_credit.get("ok", false)), "B1: Fixture: bei +10 liefert der Tanker auf Kredit (%s)" % [on_credit])
	t.flow.call("_check_bankruptcy")
	await process_frame
	_check(_bf_screens(t) == 0 and not paused, "B1 W2: +10 und festliegend: nicht pleite, der Tanker liefert auf Kredit")
	await _close(t)

func _b2_real_order() -> void:
	var s: Dictionary = await _bf_orbit_session()
	if s.is_empty(): return
	_bf_set(s, -1220, 0.0)
	var ordered: Dictionary = _order_request(s, "bf:order:1")
	_check(bool(ordered.get("ok", false)) and s.supply.get_credits() == -1500, "B2: Fixture: echte Bestellung bis genau -1500 angenommen (%s)" % [ordered])
	s.flow.call("_check_bankruptcy")
	await process_frame
	_check(_bf_screens(s) == 0 and not paused, "B2 W4: mit offenem Nottanker-Auftrag nicht pleite, obwohl das Konto bei -1500 steht und das Schiff leer liegt")
	_check(s.supply.get_open_tanker_orders().size() == 1, "B2: der Auftrag ist im Versorgungsstand offen")
	# Storno vor der Abfahrt: Erstattung, danach neu bewertet (-1220: der Tanker liefert wieder, nicht pleite).
	var cancel: Dictionary = _cancel_request(s)
	_check(bool(cancel.get("ok", false)) and s.supply.get_credits() == -1220, "B2: Storno erstattet voll (-1220) (%s)" % [cancel])
	s.flow.call("_check_bankruptcy")
	await process_frame
	_check(_bf_screens(s) == 0, "B2 W4: nach dem Storno neu bewertet: bei -1220 liefert der Tanker wieder, nicht pleite")
	# Erneut bestellen, liefern lassen: danach Tank voll genug, nicht pleite; leer gemacht bei -1500: der Tanker wuerde ablehnen, pleite.
	_check(bool(_order_request(s, "bf:order:2").get("ok", false)), "B2: zweite Bestellung angenommen")
	_check(await _wait_finished(s, "completed"), "B2: der Auftrag wird geliefert (Zustand %s)" % _finished_state(s))
	s.flow.call("_check_bankruptcy")
	await process_frame
	_check(_bf_screens(s) == 0 and s.supply.get_fuel(s.craft_id) >= 30.0, "B2 W4: nach der Lieferung nicht pleite (Tank %s)" % s.supply.get_fuel(s.craft_id))
	_bf_set(s, -1500, 0.0)
	s.flow.call("_check_bankruptcy")
	await process_frame
	_check(_bf_screens(s) == 1 and paused, "B2 W4: wieder leer bei -1500, kein Auftrag offen, Tanker wuerde ablehnen: pleite")
	await _close(s)
	paused = false
