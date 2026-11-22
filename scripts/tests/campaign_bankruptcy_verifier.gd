extends "res://scripts/tests/campaign_casualty_recovery_flow_verifier.gd"
## Abschnitt P (22.11.2026): Pleite-Bildschirm. Pleite ist man, wenn die Schulden den Kreditrahmen erreicht haben UND kein Schiff mehr
## starten oder weiterfliegen kann (Regel: scripts/core/campaign_bankruptcy_rules.gd). Teil 1: die reine Regel. Teil 2: der echte
## Kampagnen-Ablauf (Bildschirm genau einmal, Zeit steht, drei Knoepfe, Speichern gesperrt, Vorwarnung, geladener Pleite-Stand).
## Abschlusszeile: CAMPAIGN_BANKRUPTCY passed=%d failed=%d

const RULES: GDScript = preload("res://scripts/core/campaign_bankruptcy_rules.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const STORE_PATH: String = "user://campaigns/introduction/checkpoint_v1.json"
const WARNING_TEXT: String = "Kreditrahmen ausgeschöpft. Sitzt du jetzt ohne Treibstoff fest, bist du pleite."
const SCREEN_NAME: String = "CampaignBankruptcyScreen"

func _run() -> void:
	var verdict: Dictionary = GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_BANKRUPTCY refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	_configure_entry()
	_rules_part()
	await _screen_part()
	await _save_part()
	await _warning_part()
	await _timing_part()
	await _buttons_part()
	await _loaded_part()
	await _skirmish_part()
	paused = false
	print("CAMPAIGN_BANKRUPTCY passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

# ---------- Hilfen ----------

## Schiffszustand wie ihn get_fuel_status des Adapters liefert (nur die Felder, die die Regel braucht).
func _grounded_stuck(id: String = "g") -> Dictionary:
	return {"craft_id": id, "phase": "grounded", "next_legs": [{"leg": "launch", "cost": 12.0, "affordable": false}], "stranded": false, "refuel_affordable": false}

func _orbit_stuck(id: String = "o") -> Dictionary:
	return {"craft_id": id, "phase": "orbit", "next_legs": [{"leg": "approach", "cost": 30.0, "affordable": false}], "stranded": true, "refuel_affordable": false}

func _can_fly(id: String = "f") -> Dictionary:
	return {"craft_id": id, "phase": "grounded", "next_legs": [{"leg": "launch", "cost": 12.0, "affordable": true}], "stranded": false, "refuel_affordable": false}

func _bankrupt(credits: int, states: Array, limit: int = 1500) -> Dictionary:
	return RULES.is_bankrupt(credits, limit, states)

func _screen_node() -> Node:
	return _flow.get_node_or_null(SCREEN_NAME) if _flow != null and is_instance_valid(_flow) else null

func _screens_count() -> int:
	var count := 0
	if _flow != null and is_instance_valid(_flow):
		for child: Node in _flow.get_children():
			if child.name == SCREEN_NAME: count += 1
	return count

## Neue Kampagne, alle Tanks leer, Konto auf -(rahmen) gedrueckt. Die Rettungsgebuehr bucht voll (auch ins Minus).
func _bankrupt_setup(debt: int = 1600, drain: bool = true) -> bool:
	if not await _open("campaign", "new"): return false
	if drain:
		var supply: Object = _runtime.get("_supply")
		var tanks: Dictionary = supply.get("_fuel_by_craft_id")
		for tank_id: String in tanks.keys(): tanks[tank_id] = 0.0
	var start: int = int(_runtime.call("get_campaign_credits"))
	_runtime.call("charge_campaign_rescue_fee", start + debt)
	return _check(int(_runtime.call("get_campaign_credits")) == -debt, "Aufbau: Konto steht bei -%d" % debt)

func _press(button_name: String) -> void:
	var screen: Node = _screen_node()
	var button: Button = screen.find_child(button_name, true, false) as Button if screen != null else null
	if button == null:
		_check(false, "Knopf %s nicht gefunden" % button_name)
		return
	button.pressed.emit()

# ---------- Teil 1: die Regel ----------

func _rules_part() -> void:
	var r: Dictionary = _bankrupt(500, [_grounded_stuck(), _orbit_stuck()])
	_check(not bool(r.get("bankrupt", true)) and String(r.get("reason", "")) != "", "Regel: mit Guthaben nicht pleite, auch wenn alle Schiffe festliegen (%s)" % [r])
	r = _bankrupt(-1500, [_can_fly()])
	_check(not bool(r.get("bankrupt", true)), "Regel: -1500 mit einem flugfaehigen Schiff nicht pleite")
	r = _bankrupt(-1500, [_grounded_stuck(), _orbit_stuck()])
	_check(bool(r.get("bankrupt", false)) and String(r.get("reason", "")) != "", "Regel: -1500 und alle Schiffe liegen fest: pleite (%s)" % [r])
	r = _bankrupt(-1500, [_grounded_stuck()])
	_check(bool(r.get("bankrupt", false)), "Regel: ein Schiff am Boden ohne Treibstoff und ohne Geld zum Tanken zaehlt als festliegend")
	r = _bankrupt(-1499, [_grounded_stuck(), _orbit_stuck()])
	_check(not bool(r.get("bankrupt", true)), "Regel: -1499 und festliegend: nicht pleite (der Nottanker greift noch)")
	var with_tanker: Dictionary = _orbit_stuck()
	with_tanker["tanker_order_open"] = true
	r = _bankrupt(-1500, [with_tanker, _grounded_stuck()])
	_check(not bool(r.get("bankrupt", true)), "Regel: solange ein Nottanker bestellt und unterwegs ist: nicht pleite")
	r = _bankrupt(-2000, [_grounded_stuck(), _orbit_stuck()])
	_check(bool(r.get("bankrupt", false)), "Regel: -2000 (Rettungsgebuehr ueber die Grenze) und festliegend: pleite")
	r = _bankrupt(-2000, [_grounded_stuck(), _can_fly()])
	_check(not bool(r.get("bankrupt", true)), "Regel: zwei Schiffe, eines flugfaehig: nicht pleite")
	r = _bankrupt(-2000, [])
	_check(not bool(r.get("bankrupt", true)), "Regel: leere Schiffsliste: nicht pleite (kein Absturz)")
	var refuel: Dictionary = _grounded_stuck()
	refuel["refuel_affordable"] = true
	_check(not bool(_bankrupt(-1500, [refuel]).get("bankrupt", true)), "Regel: Tanken ist bezahlbar: nicht pleite")
	var transit: Dictionary = {"craft_id": "q", "phase": "quantum", "next_legs": [], "stranded": false, "refuel_affordable": false}
	_check(not bool(_bankrupt(-1500, [transit, _orbit_stuck()]).get("bankrupt", true)), "Regel: ein Schiff im Sprung ist unterwegs: nicht pleite")
	_check(not bool(_bankrupt(-5000, [_grounded_stuck()], 0).get("bankrupt", true)), "Regel: ohne Kreditrahmen in den Daten (0) gibt es keine Pleite")
	_check(not bool(RULES.is_bankrupt(-2000, 1500, [null, "x", 3]).get("bankrupt", true)), "Regel: ungueltige Eintraege in der Liste: kein Absturz, nicht pleite")

# ---------- Teil 2: Bildschirm, Zeit, Knoepfe ----------

func _screen_part() -> void:
	if not await _bankrupt_setup(): return
	_check(_screen_node() == null and not paused and not bool(_flow.call("is_campaign_bankrupt")), "Bildschirm: vor der Pruefung nichts zu sehen, die Zeit laeuft")
	for _i in range(3): _flow.call("_check_bankruptcy")
	await process_frame
	_check(_screens_count() == 1, "Bildschirm: erscheint genau einmal (%d)" % _screens_count())
	_check(int(_flow.get_meta("campaign_bankruptcy_shown_count", 0)) == 1, "Bildschirm: Zaehler steht auf 1")
	_check(paused and bool(_flow.call("is_campaign_bankrupt")), "Bildschirm: die Kampagnenzeit steht (Baum angehalten)")
	var screen: Node = _screen_node()
	_check(screen != null and screen.process_mode == Node.PROCESS_MODE_ALWAYS, "Bildschirm: laeuft auch bei angehaltener Zeit")
	var title: Label = screen.find_child("BankruptTitle", true, false) as Label if screen != null else null
	var message: Label = screen.find_child("BankruptMessage", true, false) as Label if screen != null else null
	var debt: Label = screen.find_child("BankruptDebt", true, false) as Label if screen != null else null
	_check(title != null and title.text == "Pleite", "Bildschirm: Ueberschrift Pleite")
	_check(message != null and message.text == "Die Schulden haben den Kreditrahmen erreicht, und kein Schiff kann mehr starten.", "Bildschirm: der Satz steht woertlich")
	_check(debt != null and debt.text.contains("-1600 Cr Schulden"), "Bildschirm: Zeile mit dem Schuldenstand ueber credit_text (%s)" % [debt.text if debt != null else "fehlt"])
	for pair: Array in [["BankruptLoad", "Spielstand laden"], ["BankruptNewCampaign", "Neue Kampagne"], ["BankruptMainMenu", "Zum Hauptmenü"]]:
		var button: Button = screen.find_child(String(pair[0]), true, false) as Button if screen != null else null
		_check(button != null and button.text == String(pair[1]), "Bildschirm: Knopf %s mit Text %s" % [pair[0], pair[1]])
	# Escape oeffnet das Spielmenue nicht hinter dem Bildschirm.
	var escape: Node = root.get_node_or_null("GlobalEscapeMenu")
	if escape != null:
		var event := InputEventKey.new()
		event.keycode = KEY_ESCAPE
		event.physical_keycode = KEY_ESCAPE
		event.pressed = true
		root.push_input(event)
		await process_frame
		_check(not bool(escape.call("is_menu_visible")), "Bildschirm: Escape oeffnet kein Spielmenue dahinter")
	else:
		print("HINWEIS: kein GlobalEscapeMenu im Test-Baum, Escape-Pruefung ausgelassen")
	await _close()
	_check(not paused, "Bildschirm: beim Schliessen der Szene laeuft die Zeit wieder")

func _save_part() -> void:
	if not await _bankrupt_setup(): return
	var before: String = FileAccess.get_sha256(STORE_PATH)
	_flow.call("_check_bankruptcy")
	var manual: Dictionary = _flow.call("request_campaign_save")
	_check(not bool(manual.get("ok", true)) and String(manual.get("reason", "")) == "campaign_bankrupt" and not String(manual.get("message", "")).is_empty(), "Speichern: abgelehnt mit Grund und Satz (%s)" % [manual])
	var player: Dictionary = _flow.call("request_player_save")
	_check(not bool(player.get("ok", true)) and not bool(player.get("pending", false)) and _flow.call("get_pending_save_wish").is_empty(), "Speichern: F5/Menue ohne Vormerkung abgelehnt")
	var direct: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime, true)
	_check(not bool(direct.get("ok", true)), "Speichern: auch der Basisspeicherpunkt selbst ist gesperrt (%s)" % [direct])
	var timed: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime)
	_check(not bool(timed.get("ok", true)), "Speichern: der regelmaessige Speicherpunkt ist gesperrt")
	_check(FileAccess.get_sha256(STORE_PATH) == before, "Speichern: die Spielstanddatei blieb unveraendert")
	await _close()

func _warning_part() -> void:
	# Genau am Rahmen, aber das Schiff hat Treibstoff: Vorwarnung einmal, kein Bildschirm.
	if not await _bankrupt_setup(1500, false): return
	var count_before: int = int(_flow.get_meta("campaign_save_feedback_count", 0))
	for _i in range(3): _flow.call("_check_bankruptcy")
	_check(_screen_node() == null and not paused, "Vorwarnung: mit flugfaehigem Schiff kein Bildschirm, Zeit laeuft")
	_check(int(_flow.get_meta("campaign_save_feedback_count", 0)) == count_before + 1 and String(_flow.get_meta("campaign_save_feedback", "")) == WARNING_TEXT, "Vorwarnung: genau einmal, woertlich (%s)" % String(_flow.get_meta("campaign_save_feedback", "")))
	# Jetzt setzt sich das Schiff fest: der Bildschirm erscheint (zusaetzlich zur Vorwarnung, die nicht noch einmal kommt).
	var tanks: Dictionary = _runtime.get("_supply").get("_fuel_by_craft_id")
	for tank_id: String in tanks.keys(): tanks[tank_id] = 0.0
	_flow.call("_check_bankruptcy")
	_check(_screens_count() == 1 and int(_flow.get_meta("campaign_save_feedback_count", 0)) == count_before + 1, "Vorwarnung: danach Bildschirm, aber keine zweite Warnung")
	await _close()
	# Unter dem Rahmen: keine Warnung.
	if not await _bankrupt_setup(1000, false): return
	count_before = int(_flow.get_meta("campaign_save_feedback_count", 0))
	_flow.call("_check_bankruptcy")
	_check(int(_flow.get_meta("campaign_save_feedback_count", 0)) == count_before and _screen_node() == null, "Vorwarnung: bei -1000 keine Meldung")
	await _close()

func _timing_part() -> void:
	if not await _bankrupt_setup(): return
	# Im laufenden Einsatz am Boden wird nicht geprueft.
	_flow.get("_location_contexts")["testort"] = {}
	_flow.call("_check_bankruptcy")
	_check(_screen_node() == null and not paused, "Zeitpunkt: mit offenem Einsatzort wird nicht geprueft")
	_flow.get("_location_contexts").erase("testort")
	var pending: Dictionary = {"job_id": "x"}
	_flow.set("_pending_campaign_mission_result", pending)
	_flow.call("_check_bankruptcy")
	_check(_screen_node() == null, "Zeitpunkt: mit ungebuchtem Einsatzergebnis wird nicht geprueft")
	_flow.set("_pending_campaign_mission_result", {})
	_flow.call("_check_bankruptcy")
	_check(_screens_count() == 1, "Zeitpunkt: nach der Buchung wird geprueft, Bildschirm erscheint")
	await _close()

func _buttons_part() -> void:
	# Spielstand laden
	if not await _bankrupt_setup(): return
	_flow.set_meta("campaign_bankruptcy_no_scene_change", true)
	_flow.call("_check_bankruptcy")
	_press("BankruptLoad")
	var exit_load: Dictionary = Dictionary(_flow.get_meta("campaign_bankruptcy_exit", {}))
	var request: Dictionary = Dictionary(root.get_meta(START.META_KEY, {}))
	_check(String(exit_load.get("action", "")) == "load" and String(request.get("mode", "")) == "campaign" and String(request.get("action", "")) == "continue", "Knoepfe: Spielstand laden fordert den Start 'continue' der Kampagne an (%s / %s)" % [exit_load, request])
	_check(not paused, "Knoepfe: beim Verlassen laeuft die Zeit wieder")
	START.clear_start(self)
	await _close()
	# Neue Kampagne: zwei Schritte (der vorhandene Stand wird ersetzt)
	if not await _bankrupt_setup(): return
	_flow.set_meta("campaign_bankruptcy_no_scene_change", true)
	_flow.call("_check_bankruptcy")
	_press("BankruptNewCampaign")
	_check(not _flow.has_meta("campaign_bankruptcy_exit") and not root.has_meta(START.META_KEY) and paused, "Knoepfe: Neue Kampagne verlangt zuerst eine Bestaetigung")
	var hint: Label = _screen_node().find_child("BankruptHint", true, false) as Label
	_check(hint != null and hint.visible and hint.text.contains("ersetzt"), "Knoepfe: der Hinweis nennt, dass der vorhandene Stand ersetzt wird")
	_press("BankruptNewCampaign")
	var exit_new: Dictionary = Dictionary(_flow.get_meta("campaign_bankruptcy_exit", {}))
	request = Dictionary(root.get_meta(START.META_KEY, {}))
	_check(String(exit_new.get("action", "")) == "new" and String(request.get("action", "")) == "new" and String(request.get("mode", "")) == "campaign" and not paused, "Knoepfe: zweiter Druck startet eine neue Kampagne (%s / %s)" % [exit_new, request])
	START.clear_start(self)
	await _close()
	# Hauptmenue
	if not await _bankrupt_setup(): return
	_flow.set_meta("campaign_bankruptcy_no_scene_change", true)
	_flow.call("_check_bankruptcy")
	_press("BankruptMainMenu")
	var exit_menu: Dictionary = Dictionary(_flow.get_meta("campaign_bankruptcy_exit", {}))
	_check(String(exit_menu.get("action", "")) == "main_menu" and String(exit_menu.get("scene", "")) == "res://scenes/ui/main_menu.tscn" and not paused, "Knoepfe: Zum Hauptmenue (%s)" % [exit_menu])
	await _close()

func _loaded_part() -> void:
	# Ein Stand, der schon pleite ist (etwa aus einer Zeit vor dieser Regel): gespeichert in dem Augenblick, bevor die Pruefung lief.
	if not await _bankrupt_setup(): return
	var saved: Dictionary = _flow.call("request_campaign_save")
	_check(bool(saved.get("ok", false)), "Laden: der Pleite-Stand liess sich vor der Pruefung schreiben (Grund: %s)" % [saved.get("reason", "")])
	await _close()
	if not await _open("campaign", "continue"): return
	_check(int(_runtime.call("get_campaign_credits")) == -1600, "Laden: der Stand kommt mit -1600 zurueck")
	var deadline: int = Time.get_ticks_msec() + 5000
	while _screen_node() == null and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(_screens_count() == 1 and paused, "Laden: der Pleite-Stand zeigt den Bildschirm wieder, einmal, Zeit steht")
	var shown: int = int(_flow.get_meta("campaign_bankruptcy_shown_count", 0))
	for _i in range(5): await process_frame
	_check(int(_flow.get_meta("campaign_bankruptcy_shown_count", 0)) == shown and _screens_count() == 1, "Laden: keine Schleife von Meldungen")
	await _close()

func _skirmish_part() -> void:
	if not await _open("skirmish", "new"): return
	_flow.call("_check_bankruptcy")
	_check(_screen_node() == null and not paused and not bool(_flow.call("is_campaign_bankrupt")), "Skirmish: unberuehrt, kein Bildschirm")
	await _close()
