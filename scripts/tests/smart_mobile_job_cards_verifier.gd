extends SceneTree
## Smart Mobile, Auftraege (Wunsch 24.11.): Jeder Auftrag und jeder Dauerauftrag ist ein eigenes Feld, das GANZE Feld ist anklickbar
## (Mitte und Ecken, echte Mausereignisse durch die Oberflaeche), Tastatur Fokus + Enter wirkt wie Klick, gesperrte Auftraege zeigen den Grund.
## Echte Tafel, echter Kampagnenstand, echter Dauerauftrags-Besitzer; die Tafel liest nur (Fixture wie standing_orders_board_verifier).
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
const BOARD = preload("res://scripts/meta/singleplayer_job_board_presenter.gd")
const STANDING = preload("res://scripts/core/standing_orders_state.gd")
const LOCK_REASON := "Sperrgrund-Test: Person und Kiste fehlen."
var passed := 0
var failed := 0


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
	if value:
		passed += 1
	else:
		failed += 1
	print(("PASS " if value else "FAIL ") + label)


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


## Maus bewegen (pressed == null), druecken (true) oder loslassen (false), mit Pause je Schritt.
func _mouse(point: Vector2, pressed) -> void:
	if pressed == null:
		var motion := InputEventMouseMotion.new()
		motion.position = point
		motion.global_position = point
		root.push_input(motion, true)
	else:
		var button := InputEventMouseButton.new()
		button.button_index = MOUSE_BUTTON_LEFT
		button.pressed = bool(pressed)
		button.position = point
		button.global_position = point
		button.button_mask = MOUSE_BUTTON_MASK_LEFT if bool(pressed) else 0
		root.push_input(button, true)
	await process_frame


func _reset(board: Control) -> void:
	board.set("_details_expanded", false)
	board.set("_standing_id", "")
	board.call("refresh")
	await process_frame
	await process_frame


func _opened_job(board: Control, id: String, title: String) -> bool:
	return String(board.get("_job_id")) == id and bool(board.get("_details_expanded")) and (board.get("_detail_card") as Control).visible and String((board.get("_dossier_heading") as Label).text) == title


func _opened_standing(board: Control, id: String, title: String) -> bool:
	return String(board.get("_standing_id")) == id and bool(board.get("_details_expanded")) and (board.get("_detail_card") as Control).visible and String((board.get("_dossier_heading") as Label).text) == title


func _run() -> void:
	root.size = Vector2i(1600, 1500)
	var campaign_owner := CAMPAIGN.new()
	var travel_owner := TRAVEL.new()
	_check(campaign_owner.configure().get("ok", false) and travel_owner.configure("ship").get("ok", false), "echte Kampagne und Reise konfigurieren")
	var standing := STANDING.new()
	_check(standing.configure(JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/standing_orders.json"))), "echte Dauerauftraege konfigurieren")
	standing.set_names(load("res://scripts/mission/campaign_display_catalog.gd").LOCATION_NAMES, load("res://scripts/ui/components/personnel_inventory_panel.gd").LABELS)
	var screen := SnapshotScreen.new()
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var board := BOARD.new()
	screen.add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.configure(screen)
	var campaign: Dictionary = campaign_owner.get_campaign_snapshot()
	campaign["job_availability"] = campaign_owner.get_job_availability(true)
	campaign["standing_orders"] = standing.get_snapshot({})
	# Ein gesperrter, sichtbarer Auftrag mit dem Grund im Wortlaut des Kampagnenstands (wie im Sperr-Pruefer).
	campaign.job_availability["benit_delivery"] = {"visible": true, "shown_as_locked": true, "can_accept": false, "reason": "outpost_preparation_required", "message": LOCK_REASON}
	screen.snapshot = {"mode": "campaign", "campaign": campaign, "space_travel": travel_owner.get_snapshot()}
	for i in 6:
		await process_frame
	board.call("refresh")
	for i in 6:
		await process_frame
	var jobs: Dictionary = campaign.jobs
	var cards: Dictionary = board.get("_card_buttons")
	_check(cards.has("satellite_recovery") and cards.has("benit_delivery"), "Tafel listet den offenen und den gesperrten Auftrag (beobachtet %s)" % str(cards.keys()))
	# --- Standing orders: eigene Felder
	var standing_box: Control = board.get("_standing_box")
	var standing_cards: Array = []
	for child: Node in standing_box.get_children():
		if child is Button:
			standing_cards.append(child)
	_check(standing_cards.size() == 6, "jeder der sechs Dauerauftraege ist ein eigenes Feld (Knopf) (beobachtet %d)" % standing_cards.size())
	var heading_ok := false
	for child: Node in standing_box.get_children():
		if child is Label and String(child.name) == "StandingOrdersHeading" and (child as Label).text == "Daueraufträge":
			heading_ok = true
	_check(heading_ok, "Zwischenueberschrift 'Daueraufträge' bleibt")
	# --- Felder ueber die ganze Breite der Liste und ohne Ueberlappung
	var list_width: float = (board.get("_job_cards") as Control).size.x
	var all_cards: Array = cards.values() + standing_cards
	var wide_ok := true
	var overlap := false
	for card: Control in all_cards:
		if card.get_global_rect().size.x < list_width - 2.0 or not card.is_visible_in_tree():
			wide_ok = false
		for other: Control in all_cards:
			if other != card and card.get_global_rect().grow(-1.0).intersects(other.get_global_rect().grow(-1.0)):
				overlap = true
	_check(wide_ok, "alle Felder sichtbar und ueber die ganze Breite der Liste (Liste %.0f px)" % list_width)
	_check(not overlap, "Felder liegen untereinander, ohne Ueberlappung")
	# --- Sichtbarer Zustand beim Ueberfahren, Zeiger
	var sample: Button = cards.satellite_recovery
	var normal_box := sample.get_theme_stylebox("normal") as StyleBoxFlat
	var hover_box := sample.get_theme_stylebox("hover") as StyleBoxFlat
	_check(normal_box != null and hover_box != null and hover_box.border_color.get_luminance() > normal_box.border_color.get_luminance() + 0.05, "Feld: Rahmen beim Ueberfahren heller")
	var standing_sample: Button = standing_cards[0] if not standing_cards.is_empty() else null
	var s_normal: StyleBoxFlat = standing_sample.get_theme_stylebox("normal") as StyleBoxFlat if standing_sample != null else null
	var s_hover: StyleBoxFlat = standing_sample.get_theme_stylebox("hover") as StyleBoxFlat if standing_sample != null else null
	_check(s_normal != null and s_hover != null and s_hover.border_color.get_luminance() > s_normal.border_color.get_luminance() + 0.05, "Dauerauftrag-Feld: Rahmen beim Ueberfahren heller")
	var locked_card: Button = cards.get("benit_delivery")
	var locked_box: StyleBoxFlat = locked_card.get_theme_stylebox("normal") as StyleBoxFlat if locked_card != null else null
	_check(locked_box != null and normal_box != null and locked_box.bg_color != normal_box.bg_color, "gesperrter Auftrag: Feld grau abgesetzt")
	_check(locked_card != null and locked_card.text.contains(LOCK_REASON), "gesperrter Auftrag nennt den Grund im Feld (beobachtet \"%s\")" % (locked_card.text if locked_card != null else "-"))
	# --- Mausklick: Mitte und beide Ecken oeffnen die grosse Ansicht dieses Auftrags
	for id: String in ["satellite_recovery", "benit_delivery"]:
		var title := String(jobs[id].title)
		for spot: String in ["Mitte", "oben links", "unten rechts"]:
			await _reset(board)
			var card: Control = (board.get("_card_buttons") as Dictionary).get(id)
			var rect: Rect2 = card.get_global_rect()
			var point: Vector2 = rect.get_center() if spot == "Mitte" else (rect.position + Vector2(4, 4) if spot == "oben links" else rect.end - Vector2(4, 4))
			await _click(point)
			_check(_opened_job(board, id, title), "Mausklick %s im Feld '%s' oeffnet die grosse Ansicht" % [spot, id])
	for entry: Dictionary in campaign.standing_orders:
		var sid := String(entry.id)
		var title := String(entry.title)
		for spot: String in ["Mitte", "oben links", "unten rechts"]:
			await _reset(board)
			var card: Control = standing_box.find_child("StandingOrder_" + sid.replace(":", "_"), true, false)
			if card == null:
				_check(false, "Feld fuer Dauerauftrag %s fehlt" % sid)
				continue
			var rect: Rect2 = card.get_global_rect()
			var point: Vector2 = rect.get_center() if spot == "Mitte" else (rect.position + Vector2(4, 4) if spot == "oben links" else rect.end - Vector2(4, 4))
			await _click(point)
			_check(_opened_standing(board, sid, title), "Mausklick %s im Feld des Dauerauftrags '%s' oeffnet die grosse Ansicht" % [spot, sid])
	# --- Gesperrter Auftrag: dieselbe grosse Ansicht mit Grund, nicht annehmbar, kein Befehl
	await _reset(board)
	(board.get("_card_buttons") as Dictionary).benit_delivery.pressed.emit()
	await process_frame
	var details: Label = board.get("_details")
	var accept: Button = board.get("_accept")
	_check(details.text.contains(LOCK_REASON), "gesperrt: grosse Ansicht nennt den Grund (beobachtet \"%s\")" % details.text)
	_check(accept.disabled and accept.tooltip_text == LOCK_REASON, "gesperrt: Annehmen deaktiviert und traegt den Grund")
	_check(screen.commands.is_empty(), "Klicks auf Felder geben keinen Befehl aus")
	# --- Gesperrter Dauerauftrag zeigt den Grund in der grossen Ansicht
	await _reset(board)
	var mining: Button = standing_box.find_child("StandingOrder_mining_satellite_crash_a_benit", true, false) as Button
	if mining != null:
		mining.pressed.emit()
		await process_frame
		_check(String((board.get("_summary") as Label).text).contains("Braucht: Hand-Mining-Tool"), "gesperrter Dauerauftrag: grosse Ansicht nennt den Sperrgrund (beobachtet \"%s\")" % (board.get("_summary") as Label).text)
	else:
		_check(false, "Mining-Dauerauftrag hat kein Feld")
	_check(screen.commands.is_empty(), "auch Dauerauftrag-Felder geben keinen Befehl aus (Annahme bleibt beim Haendler)")
	# --- Tastatur: Fokus + Enter wirkt wie Klick
	for target: String in ["job", "standing"]:
		await _reset(board)
		var key_card: Button = (board.get("_card_buttons") as Dictionary).get("satellite_recovery") if target == "job" else standing_box.find_child("StandingOrder_freight_trade_outpost_c_benit", true, false) as Button
		if key_card == null:
			_check(false, "Feld fuer den Tastaturtest (%s) fehlt" % target)
			continue
		key_card.grab_focus()
		await process_frame
		var enter := InputEventKey.new()
		enter.keycode = KEY_ENTER
		enter.physical_keycode = KEY_ENTER
		enter.pressed = true
		root.push_input(enter, true)
		await process_frame
		var enter_up := InputEventKey.new()
		enter_up.keycode = KEY_ENTER
		enter_up.physical_keycode = KEY_ENTER
		enter_up.pressed = false
		root.push_input(enter_up, true)
		await process_frame
		await process_frame
		var opened: bool = _opened_job(board, "satellite_recovery", String(jobs.satellite_recovery.title)) if target == "job" else String(board.get("_standing_id")) == "freight:trade_outpost:c_benit" and bool(board.get("_details_expanded"))
		_check(opened, "Fokus + Enter auf dem Feld (%s) wirkt wie ein Klick" % target)
	# --- Nachbesserung 1, W2: laufende Sperrzeit. Zwischen Druecken und Loslassen tickt die Zeit (Tafel wird neu gelesen);
	# die Knoten der Felder bleiben dieselben, der Klick geht nicht verloren.
	await _reset(board)
	var entries: Array = campaign.standing_orders
	var ticking: Dictionary = {}
	for entry: Dictionary in entries:
		if String(entry.get("status", "")) in ["locked", "unavailable"]:
			ticking = entry
			break
	_check(not ticking.is_empty(), "Testdaten: ein gesperrter Dauerauftrag fuer die laufende Sperrzeit")
	if not ticking.is_empty():
		var tid := String(ticking.id)
		var node_name := "StandingOrder_" + tid.replace(":", "_")
		ticking["message"] = "Sperrzeit laeuft: noch 3 s"
		board.call("refresh")
		await process_frame
		var field: Button = standing_box.find_child(node_name, true, false) as Button
		var field_id: int = field.get_instance_id() if field != null else 0
		var field_point: Vector2 = field.get_global_rect().get_center() if field != null else Vector2.ZERO
		await _mouse(field_point, null)
		await _mouse(field_point, true)
		var rebuilds_before := 0
		for second in 3:
			ticking["message"] = "Sperrzeit laeuft: noch %d s" % (2 - second)
			board.call("refresh")
			await process_frame
		var same: Button = standing_box.find_child(node_name, true, false) as Button
		_check(same != null and same.get_instance_id() == field_id, "Sperrzeit tickt: das Feld ist nach dem Tick derselbe Knoten (Instanz %d)" % field_id)
		_check(same != null and same.text.contains("noch 0 s"), "Sperrzeit tickt: Text des vorhandenen Felds ist aktualisiert (beobachtet \"%s\")" % (same.text if same != null else "-"))
		await _mouse(field_point, false)
		await process_frame
		_check(_opened_standing(board, tid, String(ticking.title)), "Druecken, zwei Sekunden Spielzeit, Loslassen: die grosse Ansicht oeffnet sich")
	# --- Nachbesserung 1, K3a: zweiter Klick auf dasselbe Dauerauftrag-Feld schliesst die grosse Ansicht
	await _reset(board)
	var toggle_field: Button = standing_box.find_child("StandingOrder_freight_trade_outpost_c_benit", true, false) as Button
	toggle_field.pressed.emit()
	await process_frame
	var first_open: bool = bool(board.get("_details_expanded")) and (board.get("_detail_card") as Control).visible
	toggle_field.pressed.emit()
	await process_frame
	_check(first_open and not bool(board.get("_details_expanded")) and not (board.get("_detail_card") as Control).visible, "zweiter Klick auf dasselbe Dauerauftrag-Feld schliesst die grosse Ansicht")
	# --- K3b: verschwindet der gewaehlte Eintrag, ist die Wahl zurueckgesetzt und die Auftragsfelder sind nicht grau
	await _reset(board)
	toggle_field = standing_box.find_child("StandingOrder_freight_trade_outpost_c_benit", true, false) as Button
	toggle_field.pressed.emit()
	await process_frame
	var kept: Array = []
	for entry: Dictionary in entries:
		if String(entry.id) != "freight:trade_outpost:c_benit":
			kept.append(entry)
	campaign["standing_orders"] = kept
	board.call("refresh")
	await process_frame
	var current_card: Button = (board.get("_card_buttons") as Dictionary).get(String(board.get("_job_id")))
	_check(String(board.get("_standing_id")).is_empty() and current_card != null and current_card.modulate == Color.WHITE, "gewaehlter Dauerauftrag verschwindet: Wahl zurueckgesetzt, Auftragsfeld nicht grau (Wahl \"%s\")" % String(board.get("_standing_id")))
	campaign["standing_orders"] = entries
	board.call("refresh")
	# --- K3c: schmale Ansicht, Dauerauftrag offen: im Auswahlfeld ist nichts gewaehlt, also ist jeder Auftrag (auch derselbe) wieder waehlbar
	root.size = Vector2i(560, 1500)
	root.content_scale_size = Vector2i(560, 1500)
	for i in 4:
		await process_frame
	await _reset(board)
	toggle_field = standing_box.find_child("StandingOrder_freight_trade_outpost_c_benit", true, false) as Button
	toggle_field.pressed.emit()
	await process_frame
	var chooser: OptionButton = board.get("_jobs")
	_check(chooser.visible and chooser.selected == -1, "schmale Ansicht, Dauerauftrag offen: Auswahlfeld sichtbar und ohne Auswahl (sichtbar %s, selected %d, Tafelbreite %.0f)" % [str(chooser.visible), chooser.selected, (board as Control).size.x])
	if chooser.item_count > 0:
		chooser.select(0)
		chooser.item_selected.emit(0)
		await process_frame
		_check(String(board.get("_standing_id")).is_empty() and String(board.get("_job_id")) == String(chooser.get_item_metadata(0)), "schmale Ansicht: Wahl im Auswahlfeld fuehrt aus dem Dauerauftrag zurueck zum Auftrag")
	root.size = Vector2i(1600, 1500)
	root.content_scale_size = Vector2i(1600, 1500)
	for i in 4:
		await process_frame
	screen.queue_free()
	await process_frame
	print("SMART_MOBILE_JOB_CARDS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
