extends SceneTree
## Bedienung (Wunsch 24.11., Teil E): Ein Knopf ist auf seiner ganzen sichtbaren Flaeche klickbar.
## Kopflos, echte Mausereignisse durch die Oberflaeche (druecken + loslassen). Geprueft werden: Fussleiste der Smart-Mobile-Tafel,
## Hauptknopf-Stil (hover/pressed/disabled im Farbton des Knopfes), Schiffskarte im Flugdeck, Rottenblock (keine rohe Kennung, Druckzustand, Einklappen).
## Die Sternkarte (Aktionsknoepfe rechts) gehoert zu einem anderen Auftrag und wird hier nicht geprueft.
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
const BOARD = preload("res://scripts/meta/singleplayer_job_board_presenter.gd")
const SKIN = preload("res://scripts/ui/smart_mobile_theme.gd")
const WING_PANEL = preload("res://scripts/ui/space_wing_panel.gd")
const HOME: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
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


func _event(point: Vector2, pressed: bool) -> InputEventMouseButton:
	var button := InputEventMouseButton.new()
	button.button_index = MOUSE_BUTTON_LEFT
	button.pressed = pressed
	button.position = point
	button.global_position = point
	button.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	return button


func _move(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await process_frame


func _press(point: Vector2) -> void:
	await _move(point)
	root.push_input(_event(point, true), true)
	await process_frame


func _release(point: Vector2) -> void:
	root.push_input(_event(point, false), true)
	await process_frame
	await process_frame


func _click(point: Vector2) -> void:
	await _press(point)
	await _release(point)


func _rgb_hue(color: Color) -> float:
	return color.h


func _fill(control: Control, state: String) -> Color:
	var box := control.get_theme_stylebox(state) as StyleBoxFlat
	return box.bg_color if box != null else Color(0, 0, 0, 0)


func _run() -> void:
	root.size = Vector2i(1600, 1500)
	await _job_board()
	await _ship_card()
	await _wing_block()
	print("BUTTON_HIT_AREA passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)


# ---------------------------------------------------------------- Smart Mobile: Fussleiste und Hauptknopf
func _job_board() -> void:
	var campaign_owner := CAMPAIGN.new()
	var travel_owner := TRAVEL.new()
	_check(campaign_owner.configure().get("ok", false) and travel_owner.configure("ship").get("ok", false), "echte Kampagne und Reise konfigurieren")
	var screen := SnapshotScreen.new()
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var board := BOARD.new()
	screen.add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.configure(screen)
	var campaign: Dictionary = campaign_owner.get_campaign_snapshot()
	campaign["job_availability"] = campaign_owner.get_job_availability(true)
	campaign["standing_orders"] = []
	screen.snapshot = {"mode": "campaign", "campaign": campaign, "space_travel": travel_owner.get_snapshot()}
	for i in 6:
		await process_frame
	board.set("_job_id", "satellite_recovery")
	board.set("_standing_id", "")
	board.set("_details_expanded", true)
	board.call("refresh")
	for i in 6:
		await process_frame
	var accept: Button = board.get("_accept")
	var footer: Control = board.get("_footer")
	var actions: Control = board.get("_actions")
	_check(footer.is_visible_in_tree() and actions.is_visible_in_tree() and accept.is_visible_in_tree(), "Fussleiste mit Knoepfen ist sichtbar")
	_check(not accept.disabled, "Annehmen ist fuer den offenen Auftrag freigegeben")
	var row: Rect2 = actions.get_global_rect()
	var buttons: Array = []
	for child: Node in actions.get_children():
		if child is Button and (child as Button).is_visible_in_tree():
			buttons.append(child)
	_check(buttons.size() >= 1, "Fussleiste zeigt Knoepfe (beobachtet %d)" % buttons.size())
	buttons.sort_custom(func(a: Control, b: Control) -> bool: return a.get_global_rect().position.x < b.get_global_rect().position.x)
	var first: Rect2 = (buttons[0] as Control).get_global_rect()
	var last: Rect2 = (buttons[buttons.size() - 1] as Control).get_global_rect()
	_check(absf(first.position.x - row.position.x) <= 2.0, "erster Knopf beginnt am linken inneren Rand der Fussleiste (%.0f / %.0f)" % [first.position.x, row.position.x])
	_check(absf(last.end.x - row.end.x) <= 2.0, "letzter Knopf endet am rechten inneren Rand der Fussleiste (%.0f / %.0f)" % [last.end.x, row.end.x])
	var sum_width := 0.0
	var same_line := true
	for button: Control in buttons:
		sum_width += button.get_global_rect().size.x
		if absf(button.get_global_rect().position.y - first.position.y) > 2.0: same_line = false
	if same_line:
		_check(sum_width + 8.0 * (buttons.size() - 1) >= row.size.x - 2.0, "die Knoepfe teilen sich die ganze innere Breite der Fussleiste (Summe %.0f von %.0f)" % [sum_width, row.size.x])
	else:
		_check(first.size.x >= row.size.x - 2.0, "Knopf fuellt die Breite seiner Zeile (%.0f von %.0f)" % [first.size.x, row.size.x])
	# Klick links, Mitte und rechts im Annehmen-Knopf; ausserdem trifft ein Klick 6 px innerhalb des rechten Rands der Leiste einen Knopf.
	var accept_rect: Rect2 = accept.get_global_rect()
	var y := accept_rect.get_center().y
	for spot: Array in [["links", Vector2(accept_rect.position.x + 6.0, y)], ["Mitte", accept_rect.get_center()], ["rechts", Vector2(accept_rect.end.x - 6.0, y)]]:
		screen.commands.clear()
		await _click(spot[1])
		var got := false
		for command: Array in screen.commands:
			if command[0] == "accept_job": got = true
		_check(got, "Mausklick %s im Annehmen-Knopf loest die Annahme aus" % spot[0])
	var edge := Vector2(row.end.x - 6.0, row.get_center().y)
	var edge_hit := false
	for button: Control in buttons:
		if button.get_global_rect().has_point(edge): edge_hit = true
	_check(edge_hit, "6 px innerhalb des rechten Rands der Fussleiste liegt auf einem Knopf, nicht auf leerer Flaeche")
	# Hauptknopf-Stil: hover, pressed, disabled im selben Farbton wie normal (nicht das graublaue Standardfeld).
	var normal := _fill(accept, "normal")
	for state: String in ["hover", "pressed"]:
		var fill := _fill(accept, state)
		_check(fill != normal and absf(fill.h - normal.h) < 0.04 and fill.s > 0.3, "Hauptknopf '%s': gleicher Farbton wie normal, nicht grau (h %.2f/%.2f, s %.2f)" % [state, fill.h, normal.h, fill.s])
	var disabled_fill := _fill(accept, "disabled")
	_check(absf(disabled_fill.h - normal.h) < 0.04 and disabled_fill.s < normal.s and disabled_fill != normal, "Hauptknopf 'disabled': entsaettigter Ton desselben Knopfes (h %.2f/%.2f, s %.2f/%.2f)" % [disabled_fill.h, normal.h, disabled_fill.s, normal.s])
	_check(accept.get_theme_stylebox("focus") != SKIN.box("focus"), "Hauptknopf 'focus' ist eigens gesetzt")
	var hover_font := accept.get_theme_color("font_hover_color")
	_check(hover_font.get_luminance() < 0.3, "Hauptknopf: Schrift bleibt beim Ueberfahren dunkel lesbar")
	screen.queue_free()
	await process_frame
	await process_frame


# ---------------------------------------------------------------- Flugdeck: ganze Schiffskarte waehlt das Schiff
func _crafts(count: int) -> Array:
	var result: Array = []
	for index in range(count):
		result.append({"craft_id": "hit_ship_%d" % index, "craft_type": "dropship", "display_name": "Dropship %d" % (index + 1), "supports_cargo": false, "cargo_options": []})
	return result


func _card_for(screen: Node, craft_id: String) -> Control:
	var stack: Array = [screen]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is Control and bool(node.get_meta("homebase_shipcard", false)) and String(node.get_meta("craft_id", "")) == craft_id:
			return node as Control
		stack.append_array(node.get_children())
	return null


## Schiff 1 waehlen, Karten neu bauen lassen und das Altfeld sichtbar halten (es versteckt sich bei jedem Neuaufbau). Gibt Karte 2 zurueck.
func _select_first(screen: Control) -> Control:
	screen.call("_set_selected_aircraft_id", "hit_ship_0")
	screen.call("_update_aircraft_panel")
	(screen.get_node("Panel") as Control).show()
	for i in 5:
		await process_frame
	return _card_for(screen, "hit_ship_1")


func _ship_card() -> void:
	root.size = Vector2i(1920, 1080)
	var screen := HOME.instantiate() as Control
	root.add_child(screen)
	screen.show()
	# In der Kampagne bleibt dieses Altfeld unter der neuen Oberflaeche verborgen; hier wird es sichtbar gemacht, um die Karte selbst zu pruefen.
	(screen.get_node("Panel") as Control).show()
	screen.call("setup_roster", [])
	screen.call("set_transport_state", _crafts(2), {}, [], [])
	for i in 8:
		await process_frame
	var first := _card_for(screen, "hit_ship_0")
	var second := _card_for(screen, "hit_ship_1")
	_check(first != null and second != null, "Flugdeck zeigt beide Schiffskarten")
	if first == null or second == null:
		screen.queue_free()
		return
	second = await _select_first(screen)
	var rect: Rect2 = second.get_global_rect()
	_check(String(screen.call("_get_selected_aircraft_id")) == "hit_ship_0" and second.is_visible_in_tree(), "Ausgangslage: Schiff 1 ist gewaehlt, Karte 2 sichtbar")
	await _click(rect.end - Vector2(6, 6))
	for i in 3:
		await process_frame
	_check(String(screen.call("_get_selected_aircraft_id")) == "hit_ship_1", "Klick in die rechte untere Ecke der Karte waehlt das Schiff (gewaehlt: %s)" % String(screen.call("_get_selected_aircraft_id")))
	second = await _select_first(screen)
	var label := second.find_child("ShipPayloadSummaryLabel", true, false) as Control
	await _click(label.get_global_rect().get_center())
	for i in 3:
		await process_frame
	_check(String(screen.call("_get_selected_aircraft_id")) == "hit_ship_1", "Klick auf den Text in der Karte waehlt das Schiff (gewaehlt: %s)" % String(screen.call("_get_selected_aircraft_id")))
	# Ein Knopf in der Karte tut das Seine und waehlt nicht um.
	second = await _select_first(screen)
	var toggle := second.find_child("ShipDestinationToggle", true, false) as CheckBox
	var before: bool = toggle.button_pressed
	var target_before := String(screen.call("_get_homebase_dispatch_target", "hit_ship_1"))
	var other_before := String(screen.call("_get_homebase_dispatch_target", "hit_ship_0"))
	await _click(toggle.get_global_rect().get_center())
	for i in 3:
		await process_frame
	_check(String(screen.call("_get_homebase_dispatch_target", "hit_ship_1")) != target_before and before == (not (_card_for(screen, "hit_ship_1").find_child("ShipDestinationToggle", true, false) as CheckBox).button_pressed), "Knopf in der Karte (Einsatz-Schalter) tut das Seine")
	# Jeder Knopf der Karte wirkt auf das Schiff SEINER Karte (auch der Einsatz-Schalter waehlt es selbst): hier wird nur geprueft, dass die Karte darunter nichts Zweites ausloest.
	_check(String(screen.call("_get_selected_aircraft_id")) == "hit_ship_1" and String(screen.call("_get_homebase_dispatch_target", "hit_ship_0")) == other_before, "Knopf in der Karte wirkt nur auf das Schiff seiner eigenen Karte (gewaehlt: %s)" % String(screen.call("_get_selected_aircraft_id")))
	screen.queue_free()
	await process_frame
	await process_frame


# ---------------------------------------------------------------- Rottenblock: Schiffsgruppen statt solo-Kennung
func _runtime(ship_count: int) -> Dictionary:
	var names := ["Cutlass", "Bravo"]
	var crafts: Array = []
	var wings := {}
	for index in ship_count:
		var craft_id := "cutlass_%d" % (index + 1)
		crafts.append({"craft_id": craft_id, "display_name": names[index]})
		wings["solo:" + craft_id] = {"wing_id": "solo:" + craft_id, "name": "solo:" + craft_id, "craft_ids": [craft_id], "leader_craft_id": craft_id}
	return {"crafts": crafts, "space_wings": {"revision": 1, "wings": wings}}


func _texts(node: Node, result: Array) -> void:
	if node is Label: result.append((node as Label).text)
	if node is OptionButton:
		for index in (node as OptionButton).item_count:
			result.append((node as OptionButton).get_item_text(index))
	elif node is Button: result.append((node as Button).text)
	if node is LineEdit: result.append((node as LineEdit).text)
	for child: Node in node.get_children():
		_texts(child, result)


func _wing_block() -> void:
	root.size = Vector2i(1600, 1500)
	for ship_count in [1, 2]:
		var runtime := _runtime(ship_count)
		var panel: Control = WING_PANEL.new()
		root.add_child(panel)
		panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.configure(func(): return runtime, func(_op, _payload): return {"ok": true})
		for i in 4:
			await process_frame
		var texts: Array = []
		_texts(panel, texts)
		var raw := false
		var heading := false
		for text in texts:
			if String(text).begins_with("solo:") or String(text).contains("◇ solo:") or String(text).contains("◆ solo:") or String(text).contains("solo:"): raw = true
			if String(text).begins_with("SCHIFFSGRUPPEN"): heading = true
		_check(not raw, "%d Schiff(e): kein Text mit der rohen Kennung 'solo:' (%s)" % [ship_count, str(texts)])
		_check(heading, "%d Schiff(e): Ueberschrift heisst SCHIFFSGRUPPEN" % ship_count)
		var body := panel.find_child("WingBody", true, false) as Control
		_check(body != null, "%d Schiff(e): Block hat einen einklappbaren Rumpf" % ship_count)
		if body != null:
			if ship_count == 1:
				_check(not body.is_visible_in_tree(), "mit einem Schiff ist der Block eingeklappt")
				var toggle := panel.find_child("WingHeading", true, false) as Button
				if toggle != null:
					toggle.pressed.emit()
					await process_frame
					_check(body.is_visible_in_tree(), "die Ueberschrift klappt den Block auf")
			else:
				_check(body.is_visible_in_tree(), "mit zwei Schiffen ist der Block offen")
				var tabs: Array = panel.find_children("WingTab_*", "Button", true, false)
				var joined := ""
				for tab: Button in tabs: joined += tab.text + "|"
				_check(tabs.size() == 2 and joined.contains("Cutlass") and joined.contains("Bravo"), "Reiter zeigen die Schiffsnamen (beobachtet %s)" % joined)
				if tabs.size() > 0:
					var tab: Button = tabs[0]
					var before := tab.get_theme_stylebox("normal") == tab.get_theme_stylebox("pressed")
					var point := tab.get_global_rect().get_center()
					await _press(point)
					var shown := (tabs[0] as Button).get_theme_stylebox("normal") == (tabs[0] as Button).get_theme_stylebox("pressed")
					_check(not before and shown, "Reiter zeigt beim Druck den Druckzustand")
					await _release(point)
		panel.queue_free()
		await process_frame
		await process_frame
