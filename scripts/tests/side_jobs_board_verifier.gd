extends SceneTree
## Nebenauftraege N1, Anzeige im Smart Mobile: eigener Abschnitt "Nebenauftraege" zwischen Kampagnen- und Dauerauftraegen,
## Rufzeile je Fraktion, Karten mit Auftraggeber/Ort/Belohnung/Zustand, gesperrte Karten nicht annehmbar,
## Annehmen ueber accept_job. Echte Tafel und echter Kampagnenstand (zwei Kampagnenauftraege wirklich abgeschlossen,
## damit die Nebenauftraege wirklich sichtbar werden); Ruf, Restlandungen, Abschluesse und Sperre werden im
## Schnappschuss-Abzug gesetzt (die Tafel liest nur). Prueft auch Groesse, Sichtbarkeit und Klickbarkeit bei 1280x720 und 1920x1080.
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
const COMMAND = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const BOARD = preload("res://scripts/meta/singleplayer_job_board_presenter.gd")
const RELAY := "side_relay_silence"
const FARM := "side_farm_night_watch"
const LAB := "side_lab_cold_samples"
const TEMPLER := "side_templer_volunteer"
const REP_NEED := "Braucht Ruf 0 bei Templer."
var passed := 0
var failed := 0
var sequence := 0
var owner: RefCounted

class SnapshotScreen extends Control:
	var snapshot: Dictionary = {}
	var commands: Array = []
	func get_operations_snapshot() -> Dictionary: return {"singleplayer": snapshot}
	func request_operation(operation: String, payload: Dictionary) -> Dictionary:
		commands.append([operation, payload])
		return {"ok": false, "reason": "read_only_fixture"}

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func _settle() -> void:
	for i in 4:
		await process_frame

func _command(operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	sequence += 1
	return owner.apply_command(COMMAND.build_command(operation, payload, "side-board:%d" % sequence), context)

func _finish_job(id: String) -> void:
	var job: Dictionary = owner.get_campaign_snapshot().jobs[id]
	var ok := bool(_command("accept_job", {"job_id": id}).get("ok", false))
	ok = ok and bool(_command("bind_departure", {"craft_id": "ship", "origin_location_id": "homebase", "destination_location_id": job.location_id, "landing_pad_id": "homebase_pad_01", "job_id": id}, {"departure_authorized": true}).get("ok", false))
	ok = ok and bool(_command("activate_job", {"craft_id": "ship", "job_id": id}, {"departure_authorized": true}).get("ok", false))
	ok = ok and bool(_command("complete_job", {"craft_id": "ship", "job_id": id}, {"runtime_evidence": {"scenario_id": job.scenario_id, "result": "victory", "mission_scenario_runtime_gates": {"all_gates_complete": true, "completed_step_ids": job.required_step_ids}}}).get("ok", false))
	if bool(job.home_upload): ok = ok and bool(_command("upload_job", {"job_id": id}, {"at_home": true}).get("ok", false))
	_check(ok, "echter Abschluss " + id)

func _projection(travel_owner: RefCounted) -> Dictionary:
	var campaign: Dictionary = owner.get_campaign_snapshot()
	campaign["job_availability"] = owner.get_job_availability(true)
	return {"mode": "campaign", "campaign": campaign, "space_travel": travel_owner.get_snapshot()}

func _names(container: Node) -> Array:
	var result: Array = []
	for child: Node in container.get_children():
		result.append(String(child.name))
	return result

func _click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await process_frame
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = point
	down.global_position = point
	down.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(down, true)
	await process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = point
	up.global_position = point
	root.push_input(up, true)
	await process_frame
	await process_frame

func _text(board: Control, id: String) -> String:
	var cards: Dictionary = board.get("_card_buttons")
	return String((cards[id] as Button).text) if cards.has(id) else ""

func _layout(board: Control, label: String) -> void:
	# Alle Karten (Kampagne und Neben): Mindestgroesse, innerhalb der Tafel, durch Scrollen erreichbar, ohne Ueberlappung.
	var cards: Dictionary = board.get("_card_buttons")
	var scroll: ScrollContainer = board.find_children("*", "ScrollContainer", true, false)[0] as ScrollContainer
	var board_rect: Rect2 = board.get_global_rect()
	var size_ok := true
	var inside_ok := true
	var reachable := true
	var fits := true
	var overlap := false
	for id: String in cards:
		var card: Button = cards[id]
		var side: bool = String(card.name).begins_with("SideJobCard_")
		if card.size.x < 200.0 or card.size.y < (130.0 if side else 60.0): size_ok = false
		if side and card.get_minimum_size().y > card.size.y + 1.0: fits = false
		var rect: Rect2 = card.get_global_rect()
		if rect.position.x < board_rect.position.x - 0.5 or rect.end.x > board_rect.end.x + 0.5: inside_ok = false
		# Die Karte muss in IHREM ScrollContainer (naechster Vorfahr) erreichbar sein, nicht im ersten der Tafel.
		var own_scroll: ScrollContainer = scroll
		var parent: Node = card.get_parent()
		while parent != null and parent != board:
			if parent is ScrollContainer:
				own_scroll = parent as ScrollContainer
				break
			parent = parent.get_parent()
		own_scroll.ensure_control_visible(card)
		await process_frame
		var view: Rect2 = own_scroll.get_global_rect().grow(1.0)
		if not (view.encloses(card.get_global_rect()) or (card.get_global_rect().size.y > view.size.y and view.intersects(card.get_global_rect()))):
			reachable = false
			print("DIAG %s nicht im Blick: karte=%s blick=%s h=%d vbar=%s inhalt_min=%s" % [card.name, card.get_global_rect(), view, own_scroll.scroll_horizontal, own_scroll.get_v_scroll_bar().visible, (own_scroll.get_child(0) as Control).get_combined_minimum_size()])
			var walker: Node = card
			while walker != own_scroll and walker != null:
				if walker is Control: print("DIAG   %s min=%s groesse=%s" % [walker.name, (walker as Control).get_combined_minimum_size(), (walker as Control).size])
				walker = walker.get_parent()
		if not card.is_visible_in_tree() or card.focus_mode != Control.FOCUS_ALL or card.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			reachable = false
			print("DIAG %s sichtbar=%s fokus=%d maus=%d" % [card.name, card.is_visible_in_tree(), card.focus_mode, card.mouse_filter])
		for other_id: String in cards:
			if other_id != id and rect.grow(-1.0).intersects((cards[other_id] as Control).get_global_rect().grow(-1.0)): overlap = true
	_check(not cards.is_empty() and size_ok, "%s: alle Karten haben Mindestgroesse (Nebenkarten >= 130 hoch, >= 200 breit)" % label)
	_check(fits, "%s: der Text der Nebenkarten passt in die Karte (Mindesthoehe <= Hoehe)" % label)
	_check(inside_ok, "%s: alle Karten liegen in der Breite der Tafel" % label)
	_check(reachable, "%s: alle Karten sind sichtbar, fokussierbar und per Scrollen erreichbar" % label)
	_check(not overlap, "%s: keine Karte ueberlappt eine andere" % label)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	owner = CAMPAIGN.new()
	var travel_owner := TRAVEL.new()
	_check(owner.configure().get("ok", false) and travel_owner.configure("ship").get("ok", false), "echte Kampagne und Reise konfigurieren")
	var screen := SnapshotScreen.new()
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var board := BOARD.new()
	screen.add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.configure(screen)
	var side_box: Control = board.get("_side_box")
	var side_cards: Control = board.get("_side_cards")
	var job_cards: Control = board.get("_job_cards")
	var standing_box: Control = board.get("_standing_box")

	# --- Anfang: Nebenauftraege sind definiert, aber noch nichts sichtbar (Vorgaenger offen)
	screen.snapshot = _projection(travel_owner)
	board.refresh()
	await _settle()
	_check(side_box.visible and (board.get("_side_empty") as Label).visible and (board.get("_side_empty") as Label).text == "Gerade keine Nebenaufträge.", "Anfang: Abschnitt steht da mit dem Leertext (beobachtet %s)" % str(_names(side_cards)))
	_check(side_cards.get_child_count() == 0 and not side_cards.visible, "Anfang: keine Nebenkarten")

	# --- Zwei Kampagnenauftraege wirklich abgeschlossen: relay, farm und templer werden angeboten, lab (Vorgaenger benit_delivery) nicht
	_finish_job("satellite_recovery")
	_finish_job("outpost_recovery")
	var real: Dictionary = _projection(travel_owner)
	_check(bool(real.campaign.jobs[RELAY].get("side", false)) and String(real.campaign.job_availability[RELAY].get("faction", "")) == "verwaltung", "Schnappschuss traegt side und faction (Teil 1)")
	screen.snapshot = real
	board.refresh()
	await _settle()
	_check(_names(side_cards).has("SideJobCard_" + RELAY) and _names(side_cards).has("SideJobCard_" + FARM) and _names(side_cards).has("SideJobCard_" + TEMPLER), "sichtbare Nebenauftraege haben Karten SideJobCard_<id> (beobachtet %s)" % str(_names(side_cards)))
	_check(not _names(side_cards).has("SideJobCard_" + LAB) and side_cards.get_child_count() == 3, "nicht sichtbarer Nebenauftrag (Vorgaenger offen) hat keine Karte")
	var campaign_names: Array = _names(job_cards)
	var any_side_in_campaign := false
	for node_name: String in campaign_names:
		if node_name.contains("side_"): any_side_in_campaign = true
	_check(not any_side_in_campaign and campaign_names.has("JobCard_outpost_recovery"), "Kampagnenabschnitt enthaelt keinen Nebenauftrag (beobachtet %s)" % str(campaign_names))
	var selector: Node = job_cards.get_parent()
	_check(side_box.get_parent() == selector and job_cards.get_index() < side_box.get_index() and side_box.get_index() < standing_box.get_index(), "Reihenfolge: Kampagne, Nebenauftraege, Dauerauftraege (Index %d < %d < %d)" % [job_cards.get_index(), side_box.get_index(), standing_box.get_index()])
	_check((board.get("_side_heading") as Label).text == "Nebenaufträge" and not (board.get("_side_empty") as Label).visible, "Abschnittsueberschrift 'Nebenaufträge', Leertext aus")
	_check((board.get("_side_reputation") as Label).text == "Ruf: Verwaltung 0 · Müllers Hof 0 · Templer 0 · Shady Lab 0", "Rufzeile ohne Ruf: alle Fraktionen auf 0 in der Reihenfolge der Fraktionen (beobachtet \"%s\")" % (board.get("_side_reputation") as Label).text)

	# --- Abzug mit Ruf, Restlandungen, Abschluessen, Sperre und abgelaufenem Angebot
	var variant: Dictionary = real.duplicate(true)
	variant.campaign["reputation"] = {"verwaltung": 5, "mueller": 0, "templer": -3, "labor": 10}
	variant.campaign.job_availability[RELAY]["landings_left"] = 2
	variant.campaign.jobs[RELAY]["completions"] = 2
	variant.campaign.job_availability[TEMPLER].merge({"shown_as_locked": true, "can_accept": false, "reason": "reputation_required", "message": REP_NEED}, true)
	variant.campaign.jobs[TEMPLER]["locked"] = true
	variant.campaign.job_availability[FARM]["landings_left"] = 1
	screen.snapshot = variant
	board.refresh()
	await _settle()
	_check((board.get("_side_reputation") as Label).text == "Ruf: Verwaltung 5 · Müllers Hof 0 · Templer −3 · Shady Lab 10", "Rufzeile mit Zahlen, auch negativ (beobachtet \"%s\")" % (board.get("_side_reputation") as Label).text)
	var relay_text := _text(board, RELAY)
	_check(relay_text.contains("Funkstille") and relay_text.contains("Verwaltung") and relay_text.contains("100 Cr") and relay_text.contains("Ruf Verwaltung +5"), "Karte Funkstille: Titel, Auftraggeber, Credits, Ruf (beobachtet \"%s\")" % relay_text)
	var farm_text := _text(board, FARM)
	_check(farm_text.contains("Müllers Hof") and farm_text.contains("80 Cr") and farm_text.contains("Leichte Rüstung") and farm_text.contains("Ruf Müllers Hof +5") and farm_text.contains("Ruf Templer +2"), "Karte Nachtwache: Gegenstand mit Anzeigenamen, zwei Rufgewinne (beobachtet \"%s\")" % farm_text)
	var templer_text := _text(board, TEMPLER)
	_check(templer_text.contains("60 Cr") and templer_text.contains("1 neue Person") and templer_text.contains("Ruf Templer +5") and templer_text.contains("Ruf Shady Lab −2"), "Karte Freiwilliger: Person und negativer Ruf (beobachtet \"%s\")" % templer_text)
	_check(relay_text.contains("Angebot noch 2 Heimlandungen"), "Zustandszeile: 'Angebot noch 2 Heimlandungen'")
	_check(farm_text.contains("Angebot noch 1 Heimlandung") and not farm_text.contains("1 Heimlandungen"), "Zustandszeile: Einzahl bei einer Landung")
	_check(relay_text.contains("Schon 2× erledigt") and not farm_text.contains("erledigt"), "Zustandszeile: 'Schon 2× erledigt' nur beim Auftrag mit Abschluessen")
	_check(templer_text.contains("Gesperrt: " + REP_NEED), "gesperrte Karte nennt den Grund im Wortlaut des Kampagnenstands")
	var locked_card: Button = (board.get("_card_buttons") as Dictionary)[TEMPLER]
	var open_card: Button = (board.get("_card_buttons") as Dictionary)[RELAY]
	var locked_box := locked_card.get_theme_stylebox("normal") as StyleBoxFlat
	var open_box := open_card.get_theme_stylebox("normal") as StyleBoxFlat
	_check(bool(locked_card.get_meta("locked", false)) and not bool(open_card.get_meta("locked", true)) and locked_box != null and open_box != null and locked_box.bg_color != open_box.bg_color, "gesperrte Karte ist grau abgesetzt, die freie nicht")

	# --- Auswahl und Annehmen
	locked_card.pressed.emit()
	await process_frame
	var accept: Button = board.get("_accept")
	var details: Label = board.get("_details")
	_check(String(board.get("_job_id")) == TEMPLER and accept.disabled and accept.tooltip_text == REP_NEED, "gesperrte Karte: gewaehlt, Annehmen aus, Tooltip nennt den Grund (Tooltip \"%s\")" % accept.tooltip_text)
	_check(details.text.contains("Auftraggeber: Templer") and details.text.contains("Zielort:") and details.text.contains(REP_NEED) and details.text.contains("Belohnung: 60 Cr"), "gesperrte Karte: Einzelheiten zeigen Auftraggeber, Ort, Grund, Belohnung (beobachtet \"%s\")" % details.text)
	_check(screen.commands.is_empty(), "Auswaehlen gibt keinen Befehl aus")
	open_card.pressed.emit()
	await process_frame
	_check(String(board.get("_job_id")) == RELAY and not accept.disabled and (board.get("_dossier_heading") as Label).text == "Funkstille", "freie Karte: gewaehlt, Annehmen frei, Titel in der grossen Ansicht")
	_check(details.text.contains("Auftraggeber: Verwaltung") and details.text.contains("Belohnung: 100 Cr") and details.text.contains("Ruf Verwaltung +5"), "freie Karte: Einzelheiten zeigen dieselben Angaben wie die Karte (beobachtet \"%s\")" % details.text)
	accept.pressed.emit()
	await process_frame
	_check(screen.commands.size() == 1 and String(screen.commands[0][0]) == "accept_job" and String(Dictionary(screen.commands[0][1]).get("job_id", "")) == RELAY, "Annehmen sendet accept_job mit der Kennung des Nebenauftrags (beobachtet %s)" % str(screen.commands))

	# --- Neu-Aufbau nur bei Signaturwechsel
	var rebuilds: int = int(board.get("_job_list_rebuilds"))
	var node_id: int = open_card.get_instance_id()
	board.refresh()
	board.refresh()
	_check(int(board.get("_job_list_rebuilds")) == rebuilds and ((board.get("_card_buttons") as Dictionary)[RELAY] as Button).get_instance_id() == node_id, "unveraenderter Schnappschuss: keine neue Karte, kein Neu-Aufbau")
	variant.campaign["reputation"]["templer"] = 0
	board.refresh()
	_check(int(board.get("_job_list_rebuilds")) == rebuilds + 1 and (board.get("_side_reputation") as Label).text.contains("Templer 0 ·"), "Ruf aendert sich: genau ein Neu-Aufbau, Rufzeile neu")

	# --- Abgelaufenes Angebot: unsichtbar, keine Karte
	variant.campaign.job_availability[FARM]["visible"] = false
	board.refresh()
	await _settle()
	_check(not _names(side_cards).has("SideJobCard_" + FARM) and side_cards.get_child_count() == 2, "abgelaufenes Angebot (visible=false) hat keine Karte")

	# --- Abstand zu Kampagnenaufgaben: Leertext der Kampagne gilt nur der Kampagne
	var only_side: Dictionary = variant.duplicate(true)
	for id: String in only_side.campaign.job_availability:
		if not bool(only_side.campaign.jobs[id].get("side", false)): only_side.campaign.job_availability[id]["visible"] = false
	screen.snapshot = only_side
	board.refresh()
	await _settle()
	_check((board.get("_empty") as Label).visible and side_cards.get_child_count() == 2, "nur Nebenauftraege sichtbar: Kampagnen-Leertext bleibt, Nebenkarten bleiben")

	# --- Alle Nebenangebote weg: Abschnitt bleibt mit Leertext, ohne Karten
	var none_side: Dictionary = variant.duplicate(true)
	for id: String in none_side.campaign.job_availability:
		if bool(none_side.campaign.jobs[id].get("side", false)): none_side.campaign.job_availability[id]["visible"] = false
	screen.snapshot = none_side
	board.refresh()
	await _settle()
	_check(side_box.visible and (board.get("_side_empty") as Label).visible and side_cards.get_child_count() == 0, "kein Nebenangebot: 'Gerade keine Nebenaufträge.' statt Karten")
	_check(not String(board.get("_job_id")).begins_with("side_"), "die Auswahl bleibt nicht an einem verschwundenen Nebenauftrag haengen (Wahl \"%s\")" % String(board.get("_job_id")))

	# --- Alter Stand ohne Nebenauftraege: Abschnitt ganz weg
	var legacy: Dictionary = variant.duplicate(true)
	for id: String in legacy.campaign.jobs.keys():
		if bool(legacy.campaign.jobs[id].get("side", false)):
			legacy.campaign.jobs.erase(id)
			legacy.campaign.job_availability.erase(id)
	legacy.campaign.erase("reputation")
	legacy.campaign.erase("factions")
	screen.snapshot = legacy
	board.refresh()
	await _settle()
	_check(not side_box.visible and side_cards.get_child_count() == 0, "Stand ohne Nebenauftraege: Abschnitt ausgeblendet")

	# --- Layout und Klick: 1280x720 und 1920x1080 mit drei sichtbaren Nebenkarten
	var layout_variant: Dictionary = real.duplicate(true)
	layout_variant.campaign["reputation"] = {"verwaltung": 5, "mueller": 0, "templer": -3, "labor": 10}
	layout_variant.campaign.job_availability[TEMPLER].merge({"shown_as_locked": true, "can_accept": false, "reason": "reputation_required", "message": REP_NEED}, true)
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = size
		root.content_scale_size = size
		screen.snapshot = layout_variant
		board.set("_details_expanded", false)
		board.refresh()
		await _settle()
		board.refresh()
		await _layout(board, "%dx%d" % [size.x, size.y])
		_check(side_cards.get_child_count() == 3, "%dx%d: drei Nebenkarten stehen" % [size.x, size.y])
	# Echte Mausklicks auf Mitte und Ecken einer Nebenkarte oeffnen die grosse Ansicht dieses Auftrags (1920x1080, nichts wird verschluckt).
	var scroll: ScrollContainer = board.find_children("*", "ScrollContainer", true, false)[0] as ScrollContainer
	for spot: String in ["Mitte", "oben links", "unten rechts"]:
		board.set("_details_expanded", false)
		board.set("_job_id", "")
		board.refresh()
		await _settle()
		var card: Button = (board.get("_card_buttons") as Dictionary)[FARM]
		scroll.ensure_control_visible(card)
		await _settle()
		var rect: Rect2 = card.get_global_rect()
		var point: Vector2 = rect.get_center() if spot == "Mitte" else (rect.position + Vector2(4, 4) if spot == "oben links" else rect.end - Vector2(4, 4))
		await _click(point)
		_check(String(board.get("_job_id")) == FARM and bool(board.get("_details_expanded")) and (board.get("_detail_card") as Control).visible, "Mausklick %s auf die Nebenkarte oeffnet die grosse Ansicht" % spot)
	_check(screen.commands.size() == 1, "Klicks auf Karten geben keinen weiteren Befehl aus (nur das Annehmen von oben)")
	var footer_accept: Button = board.get("_accept")
	_check(footer_accept.is_visible_in_tree() and footer_accept.size.y >= 30.0 and footer_accept.size.x >= 100.0, "Annehmen-Knopf ist bei offener Nebenkarte sichtbar und gross genug (%s)" % str(footer_accept.size))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	screen.queue_free()
	await process_frame
	print("SIDE_JOBS_BOARD passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
