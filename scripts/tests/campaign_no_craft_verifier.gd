extends "res://scripts/tests/campaign_craft_loss_second_verifier.gd"
## LC2g Punkt 3: Leere Flotte ist keine stumme Sackgasse, sondern ein Kampagnenende wie die Pleite (Regel: campaign_bankruptcy_rules.gd,
## Grund "no_craft"; Bildschirm: campaign_bankruptcy_screen.gd). Echter Fluss: letztes Schiff im Einsatz abgeschossen -> Notrettung -> der
## Pleite-Bildschirm mit dem Satz "Kein Schiff mehr ...". Gegenprobe: bleibt ein Schiff, erscheint er nicht.
const RULES: GDScript = preload("res://scripts/core/campaign_bankruptcy_rules.gd")
const SCREEN_NAME: String = "CampaignBankruptcyScreen"
const TEXT_NO_CRAFT: String = "Kein Schiff mehr: Ohne Schiff kommst du nicht mehr von der Basis weg."

func _run() -> void:
	_configure_entry()
	_bankruptcy_off = false # hier soll die Pleite-Pruefung laufen
	_rules_part()
	await _n1_last_craft_lost()
	await _n2_other_craft_remains()
	paused = false
	print("CAMPAIGN_NO_CRAFT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

func _rules_part() -> void:
	var empty: Dictionary = RULES.is_bankrupt(-100, 1500, [])
	_check(bool(empty.get("bankrupt", false)) and String(empty.get("cause", "")) == "no_craft", "Regel: leere Flotte ist pleite mit Grund no_craft (%s)" % str(empty))
	_check(bool(RULES.is_bankrupt(500, 0, []).get("bankrupt", false)), "Regel: leere Flotte ist auch ohne Kreditrahmen und mit Guthaben ein Ende")
	_check(not bool(RULES.is_bankrupt(-2000, 1500, [null, "x", 3]).get("bankrupt", true)), "Regel: nur ungueltige Eintraege sind keine leere Flotte (nicht pleite, kein Absturz)")
	_check(not bool(RULES.is_bankrupt(-1500, 1500, [{"craft_id": "f", "phase": "grounded", "next_legs": [{"leg": "launch", "cost": 12.0, "affordable": true}], "refuel_affordable": false}]).get("bankrupt", true)), "Regel: ein flugfaehiges Schiff: nicht pleite")

func _pleite_screen() -> Node:
	return _flow.get_node_or_null(SCREEN_NAME) if _flow != null and is_instance_valid(_flow) else null

func _message() -> String:
	var screen: Node = _pleite_screen()
	var label: Label = screen.find_child("BankruptMessage", true, false) as Label if screen != null else null
	return label.text if label != null else "(kein Bildschirm)"

func _n1_last_craft_lost() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	_lose_craft(s)
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("N1: Einsatz wird freigegeben"): return
	_check(_fleet_ids().is_empty(), "N1: das letzte Schiff ist verloren, die Flotte ist leer (%s)" % str(_fleet_ids()))
	_flow.call("_check_bankruptcy")
	await process_frame
	_check(_pleite_screen() != null and bool(_flow.call("is_campaign_bankrupt")), "N1: der Pleite-Bildschirm erscheint")
	_check(_message() == TEXT_NO_CRAFT, "N1: der Satz nennt das fehlende Schiff (%s)" % _message())
	var screen: Node = _pleite_screen()
	for button_name in ["BankruptLoad", "BankruptNewCampaign", "BankruptMainMenu"]:
		_check(screen != null and screen.find_child(button_name, true, false) is Button, "N1: Knopf %s ist da" % button_name)
	var debt: Label = screen.find_child("BankruptDebt", true, false) as Label if screen != null else null
	_check(debt != null and debt.text.begins_with("Kontostand"), "N1: die Kontostand-Zeile bleibt (%s)" % (debt.text if debt != null else "-"))
	_check(not bool(Dictionary(_flow.call("request_campaign_save")).get("ok", true)), "N1: Speichern ist gesperrt wie bei der Pleite")
	paused = false
	await _close()

func _n2_other_craft_remains() -> void:
	var s: Dictionary = await _begin_funded_sortie(500)
	if s.is_empty(): return
	var second := _inject_bought_ship()
	_lose_craft(s)
	s.driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("N2: Einsatz wird freigegeben"): return
	_check(_fleet_ids() == [second], "N2: das Einsatzschiff ist verloren, das zweite bleibt (%s)" % str(_fleet_ids()))
	var verdict: Dictionary = _runtime.call("get_bankruptcy_check")
	_check(String(verdict.get("cause", "")) != "no_craft", "N2: mit einem verbliebenen Schiff gilt nicht no_craft (%s)" % str(verdict))
	_flow.call("_check_bankruptcy")
	await process_frame
	_check(_message() != TEXT_NO_CRAFT, "N2: der Satz 'Kein Schiff mehr' erscheint nicht (%s)" % _message())
	paused = false
	await _close()
