extends "res://scripts/tests/campaign_intro_loop_smoke.gd"
## Speichern, erster Teil, Fix-Runde 1 (W3): Besuch am Handelsaussenposten (trade_outpost, ohne Auftrag) und der Besuch davor (satellite_recovery,
## mit Auftrag, nach dem Abschluss). Gefahren wird der echte Zwei-Ausflug-Treiber der Einfuehrungsschleife (campaign_intro_loop_smoke); dazu
## schreibt dieser Pruefer bei jedem Bild mit, welche Zeilen der Flow dem Spieler am Bildschirmrand zeigt (Meta campaign_save_feedback und
## campaign_save_feedback_count). Der Treiber prueft selbst: Ortsinstanz nach der Heimkehr frei, gueltiger Heimstand gespeichert, Fortsetzen
## laedt denselben Kader. Hier kommt hinzu: nach jeder Heimlandung loest das Spiel von selbst ein Speichern aus und sagt es ("Gespeichert.");
## kommt es erst nach Vormerkungen zustande, sind diese Zeilen ehrliche Saetze (kein leerer Text).
## Nicht abgedeckt: ein Besuch mit LAUFENDEM Auftrag (benit_delivery mit geladener Kiste) braucht vier abgeschlossene Auftraege davor (rund
## eine halbe Stunde echter Lauf); die Regel dazu prueft Szenario T in campaign_save_first_part_verifier gegen den echten Auftragsstand.
## Abschlusszeile: CAMPAIGN_SAVE_FIRST_PART_TRADE passed=%d failed=%d (danach die Zeile des Treibers SINGLEPLAYER_LOOP_RESULTS ...).

var _fpt_events: Array = []
var _fpt_last_count: int = -1
var _fpt_last_flow_id: int = 0
var _fpt_trade_marker: int = -1

func _run() -> void:
	process_frame.connect(_fpt_record)
	await super._run()

func _fpt_record() -> void:
	if not is_instance_valid(_flow) or not _flow.is_inside_tree():
		return
	var flow_id: int = _flow.get_instance_id()
	var count: int = int(_flow.get_meta("campaign_save_feedback_count", 0))
	if flow_id != _fpt_last_flow_id:
		_fpt_last_flow_id = flow_id
		_fpt_last_count = 0
	if count != _fpt_last_count:
		_fpt_last_count = count
		var text: String = String(_flow.get_meta("campaign_save_feedback", ""))
		_fpt_events.append({"text": text, "ret": _return_number, "successes": int(_flow.get_meta("campaign_save_successes", 0))})
		print("FPT_FEEDBACK ret=%d flow=%d count=%d text=%s" % [_return_number, flow_id, count, text])

## Der Treiber speichert nach der Freigabe der Ortsinstanz sofort von Hand und laedt neu; die automatische Landungs-Speicherung (Takt: jede
## Sekunde) kaeme dabei nie zum Zug. Hier wartet der Pruefer nach der Freigabe, bis das Spiel von selbst gespeichert und es gesagt hat.
func _wait(predicate: Callable, milliseconds: int, label: String) -> bool:
	var released: bool = await super._wait(predicate, milliseconds, label)
	if released and label.begins_with("Visit location instance is released"):
		var count_at_release: int = int(_flow.get_meta("campaign_save_feedback_count", 0))
		print("FPT_RELEASE ret=%d flow=%d count=%d text=%s successes=%d" % [_return_number, _flow.get_instance_id(), count_at_release, _flow.get_meta("campaign_save_feedback", ""), int(_flow.get_meta("campaign_save_successes", 0))])
		var told: Callable = func() -> bool: return int(_flow.get_meta("campaign_save_feedback_count", 0)) > count_at_release and String(_flow.get_meta("campaign_save_feedback", "")) == "Gespeichert."
		var landing_told: bool = await super._wait(told, 15000, "Trade: nach der Heimlandung (Rueckkehr %d) speichert das Spiel von selbst und sagt 'Gespeichert.'" % _return_number)
		# Der Bild-Mitschnitt sieht Aenderungen nicht, die ganz innerhalb dieser Warteschleife (nur physics_frame) geschehen und vor dem Neuladen des Treibers enden:
		# das Ergebnis der Wartezeit wird hier selbst in die Liste uebernommen.
		var count_now: int = int(_flow.get_meta("campaign_save_feedback_count", 0))
		if count_now != _fpt_last_count or _flow.get_instance_id() != _fpt_last_flow_id:
			_fpt_last_count = count_now
			_fpt_last_flow_id = _flow.get_instance_id()
			_fpt_events.append({"text": String(_flow.get_meta("campaign_save_feedback", "")), "ret": _return_number, "successes": int(_flow.get_meta("campaign_save_successes", 0))})
			print("FPT_FEEDBACK ret=%d flow=%d count=%d text=%s (nach der Wartezeit)" % [_return_number, _fpt_last_flow_id, count_now, _flow.get_meta("campaign_save_feedback", "")])
	return released

func _launch_and_land(scenario_id: String, map_path: String) -> bool:
	if scenario_id == "outpost_recovery" and _fpt_trade_marker < 0:
		_fpt_trade_marker = _fpt_events.size()
	return await super._launch_and_land(scenario_id, map_path)

func _fpt_line_ok(text: String) -> bool:
	return text == "Gespeichert." or text.begins_with("Speichern vorgemerkt: ") or text.begins_with("Vor dem Abheben nicht gespeichert: ")

func _finish() -> void:
	var before_trade: Array = _fpt_events.slice(0, _fpt_trade_marker) if _fpt_trade_marker >= 0 else _fpt_events
	var trade_events: Array = _fpt_events.slice(_fpt_trade_marker) if _fpt_trade_marker >= 0 else []
	if _failed == 0:
		_check(_fpt_trade_marker >= 0, "Trade: der Handelsposten-Ausflug wurde erreicht")
		# Je Ausflug zweimal "Gespeichert.": einmal beim Abheben von der Basis, einmal nach der Heimlandung (der Rueckflug vom Ort ist kein Abheben von der Basis).
		var saved_before: int = before_trade.filter(func(entry: Dictionary) -> bool: return String(entry.text) == "Gespeichert.").size()
		var saved_trade: int = trade_events.filter(func(entry: Dictionary) -> bool: return String(entry.text) == "Gespeichert.").size()
		_check(saved_before >= 2, "Trade: der Auftrags-Ausflug (satellite_recovery) meldet beim Abheben und nach der Landung 'Gespeichert.' (%d Mal: %s)" % [saved_before, before_trade])
		_check(saved_trade >= 2, "Trade: der Handelsposten-Ausflug meldet beim Abheben und nach der Heimkehr 'Gespeichert.' (%d Mal: %s)" % [saved_trade, trade_events])
		_check(_fpt_events.all(func(entry: Dictionary) -> bool: return _fpt_line_ok(String(entry.text))), "Trade: jede gezeigte Zeile ist 'Gespeichert.', eine Vormerkung oder eine Abhebe-Meldung (%s)" % [_fpt_events])
		var last_trade: Dictionary = trade_events[trade_events.size() - 1] if not trade_events.is_empty() else {}
		_check(String(last_trade.get("text", "")) == "Gespeichert.", "Trade: die letzte Zeile nach dem Handelsposten ist 'Gespeichert.', keine offene Vormerkung (%s)" % [last_trade])
	print("CAMPAIGN_SAVE_FIRST_PART_TRADE passed=%d failed=%d" % [_passed, _failed])
	await super._finish()
