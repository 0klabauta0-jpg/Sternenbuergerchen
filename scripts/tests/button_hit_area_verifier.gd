extends SceneTree
## Bedienung (Wunsch 24.11., Teil E, Nachbesserung 1): Ein Knopf ist auf seiner ganzen sichtbaren Flaeche klickbar.
## Kopflos, echte Mausereignisse durch die Oberflaeche (druecken + loslassen). Geprueft werden: Fussleiste der Smart-Mobile-Tafel
## (ohne eigenen Rahmen, gleich breite Knoepfe, buendig mit der Karte, Klick 3 px innerhalb jeder Kante, Luecken tot; breit und schmal),
## Hauptknopf-Stil (Farbton, Kontrast gesperrt/gedrueckt rechnerisch >= 4,5), Schiffsgruppen-Block (keine Kennung, kein "Rotte", Einklappen, Druckzustand)
## und der echte Aufbauweg der Namen (echte Basis -> echter Schnappschuss -> echte Sternkarte).
## Die Sternkarte (Aktionsknoepfe rechts) gehoert zu einem anderen Auftrag und wird hier nicht geprueft.
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
const BOARD = preload("res://scripts/meta/singleplayer_job_board_presenter.gd")
const SKIN = preload("res://scripts/ui/smart_mobile_theme.gd")
const WING_PANEL = preload("res://scripts/ui/space_wing_panel.gd")
const WING_STATE = preload("res://scripts/core/space_wing_state.gd")
const STAR = preload("res://scripts/ui/star_map_screen.gd")
const START = preload("res://scripts/meta/game_start_contract.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const FLOW: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const MIN_CONTRAST := 4.5
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


func _fill(control: Control, state: String) -> Color:
	var box := control.get_theme_stylebox(state) as StyleBoxFlat
	return box.bg_color if box != null else Color(0, 0, 0, 0)


## Relative Leuchtdichte nach WCAG 2.x aus sRGB-Werten.
func _luminance(color: Color) -> float:
	var channels: Array = []
	for value: float in [color.r, color.g, color.b]:
		channels.append(value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4))
	return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]


func _contrast(a: Color, b: Color) -> float:
	var high := maxf(_luminance(a), _luminance(b))
	var low := minf(_luminance(a), _luminance(b))
	return (high + 0.05) / (low + 0.05)


func _run() -> void:
	await _job_board(1600)
	await _job_board(560)
	await _wing_block()
	await _real_wing_names()
	print("BUTTON_HIT_AREA passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)


# ---------------------------------------------------------------- Smart Mobile: Fussleiste und Hauptknopf
func _board_fixture(width: int) -> Dictionary:
	root.size = Vector2i(1920, 1600)
	var campaign_owner := CAMPAIGN.new()
	var travel_owner := TRAVEL.new()
	_check(campaign_owner.configure().get("ok", false) and travel_owner.configure("ship").get("ok", false), "[%d] echte Kampagne und Reise konfigurieren" % width)
	var screen := SnapshotScreen.new()
	root.add_child(screen)
	# Die Breite der Ansicht wird am Wurzelknoten der Tafel gesetzt (das Fenster selbst bleibt gross und gestreckt).
	screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
	screen.position = Vector2.ZERO
	screen.size = Vector2(width, 1000)
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
	for i in 8:
		await process_frame
	return {"screen": screen, "board": board}


func _visible_buttons(actions: Control) -> Array:
	var buttons: Array = []
	for child: Node in actions.get_children():
		if child is Button and (child as Button).is_visible_in_tree():
			buttons.append(child)
	buttons.sort_custom(func(a: Control, b: Control) -> bool:
		var ra: Rect2 = a.get_global_rect()
		var rb: Rect2 = b.get_global_rect()
		return ra.position.y < rb.position.y - 2.0 or (absf(ra.position.y - rb.position.y) <= 2.0 and ra.position.x < rb.position.x))
	return buttons


func _footer_style_invisible(footer: Control) -> bool:
	var style := footer.get_theme_stylebox("panel")
	if style is StyleBoxEmpty:
		return style.get_margin(SIDE_LEFT) == 0 and style.get_margin(SIDE_RIGHT) == 0
	var flat := style as StyleBoxFlat
	if flat == null:
		return false
	return flat.bg_color.a <= 0.0 and flat.border_width_left == 0 and flat.border_width_right == 0 and flat.border_width_top == 0 and flat.border_width_bottom == 0 and flat.get_margin(SIDE_LEFT) == 0 and flat.get_margin(SIDE_RIGHT) == 0


## Klick 3 px innerhalb jeder der vier Kanten jedes sichtbaren Knopfes und in jeder Luecke zwischen zwei Knoepfen.
func _footer_clicks(screen: SnapshotScreen, buttons: Array, label: String) -> void:
	var expected := {"AcceptJob": "accept_job", "ShowOnMap": "select_destination", "AbandonJob": "abandon_job"}
	var enabled_count := 0
	for button: Button in buttons:
		var rect: Rect2 = button.get_global_rect()
		var spots := {
			"links": Vector2(rect.position.x + 3.0, rect.get_center().y),
			"rechts": Vector2(rect.end.x - 3.0, rect.get_center().y),
			"oben": Vector2(rect.get_center().x, rect.position.y + 3.0),
			"unten": Vector2(rect.get_center().x, rect.end.y - 3.0)}
		if not button.disabled: enabled_count += 1
		for edge: String in spots:
			screen.commands.clear()
			await _click(spots[edge])
			var ops: Array = []
			for command: Array in screen.commands: ops.append(command[0])
			if button.disabled:
				_check(ops.is_empty(), "%s: Klick 3 px innen (%s) im gesperrten Knopf %s loest nichts aus (%s)" % [label, edge, button.name, str(ops)])
			else:
				_check(ops == [expected.get(String(button.name), "?")], "%s: Klick 3 px innen (%s) im Knopf %s loest genau diesen aus (%s)" % [label, edge, button.name, str(ops)])
	_check(enabled_count >= 1, "%s: mindestens ein Knopf ist freigegeben (%d)" % [label, enabled_count])
	for index in range(buttons.size() - 1):
		var a: Rect2 = (buttons[index] as Control).get_global_rect()
		var b: Rect2 = (buttons[index + 1] as Control).get_global_rect()
		var gap := Vector2.ZERO
		if absf(a.position.y - b.position.y) <= 2.0:
			_check(absf((b.position.x - a.end.x) - 8.0) <= 1.0, "%s: Abstand zwischen den Knoepfen bleibt 8 px (%.1f)" % [label, b.position.x - a.end.x])
			gap = Vector2((a.end.x + b.position.x) * 0.5, a.get_center().y)
		else:
			gap = Vector2(a.get_center().x, (a.end.y + b.position.y) * 0.5)
		screen.commands.clear()
		await _click(gap)
		_check(screen.commands.is_empty(), "%s: Klick in die Luecke %d loest nichts aus (%s)" % [label, index, str(screen.commands)])


func _job_board(width: int) -> void:
	var fixture := await _board_fixture(width)
	var screen: SnapshotScreen = fixture.screen
	var board: Control = fixture.board
	var tag := "Breite %d" % width
	var accept: Button = board.get("_accept")
	var footer: Control = board.get("_footer")
	var actions: Control = board.get("_actions")
	var card: Control = board.get("_detail_card")
	_check(footer.is_visible_in_tree() and actions.is_visible_in_tree() and accept.is_visible_in_tree(), "%s: Fussleiste mit Knoepfen ist sichtbar" % tag)
	_check(_footer_style_invisible(footer), "%s: Fussleiste hat keine sichtbare Fuellung, keinen Rand, keinen seitlichen Innenabstand (%s)" % [tag, footer.get_theme_stylebox("panel").get_class()])
	for state in ["available", "accepted"]:
		if state == "accepted":
			var jobs: Dictionary = screen.snapshot.campaign.jobs
			jobs["satellite_recovery"]["status"] = "accepted"
			board.set("_signature", "")
			board.call("refresh")
			for i in 6:
				await process_frame
		var label := "%s/%s" % [tag, state]
		var buttons := _visible_buttons(actions)
		_check(buttons.size() == 3, "%s: drei sichtbare Fussleisten-Knoepfe (beobachtet %d)" % [label, buttons.size()])
		if buttons.is_empty(): continue
		var first: Rect2 = (buttons[0] as Control).get_global_rect()
		var last: Rect2 = (buttons[buttons.size() - 1] as Control).get_global_rect()
		var min_width := 100000.0
		var max_width := 0.0
		for button: Control in buttons:
			min_width = minf(min_width, button.get_global_rect().size.x)
			max_width = maxf(max_width, button.get_global_rect().size.x)
		_check(max_width - min_width <= 1.0, "%s: alle Knoepfe gleich breit (%.1f bis %.1f)" % [label, min_width, max_width])
		var style := card.get_theme_stylebox("panel")
		var card_rect: Rect2 = card.get_global_rect()
		var inner_left := card_rect.position.x + style.get_margin(SIDE_LEFT)
		var inner_right := card_rect.end.x - style.get_margin(SIDE_RIGHT)
		_check(absf(first.position.x - inner_left) <= 1.0, "%s: erster Knopf beginnt buendig mit dem Inhalt der Karte (%.1f / %.1f)" % [label, first.position.x, inner_left])
		_check(absf(last.end.x - inner_right) <= 1.0, "%s: letzter Knopf endet buendig mit dem Inhalt der Karte (%.1f / %.1f)" % [label, last.end.x, inner_right])
		await _footer_clicks(screen, buttons, label)
	# Hauptknopf-Stil: Farbton bleibt, Kontrast gesperrt und gedrueckt rechnerisch mindestens 4,5.
	var normal := _fill(accept, "normal")
	for state: String in ["hover", "pressed"]:
		var fill := _fill(accept, state)
		_check(fill != normal and absf(fill.h - normal.h) < 0.04 and fill.s > 0.3, "%s: Hauptknopf '%s': gleicher Farbton wie normal, nicht grau (h %.2f/%.2f, s %.2f)" % [tag, state, fill.h, normal.h, fill.s])
	var disabled_fill := _fill(accept, "disabled")
	_check(absf(disabled_fill.h - normal.h) < 0.04 and disabled_fill.s < normal.s and disabled_fill != normal, "%s: Hauptknopf 'disabled': entsaettigter Ton desselben Knopfes (h %.2f/%.2f, s %.2f/%.2f)" % [tag, disabled_fill.h, normal.h, disabled_fill.s, normal.s])
	_check(accept.get_theme_stylebox("focus") != SKIN.box("focus"), "%s: Hauptknopf 'focus' ist eigens gesetzt" % tag)
	if width == 1600:
		var pairs := {"normal": "font_color", "hover": "font_hover_color", "pressed": "font_pressed_color", "hover_pressed": "font_hover_pressed_color", "disabled": "font_disabled_color"}
		for state: String in pairs:
			var ratio := _contrast(_fill(accept, state), accept.get_theme_color(pairs[state]))
			_check(ratio >= MIN_CONTRAST, "Kontrast Hauptknopf '%s': %.2f : 1 (Soll >= %.1f)" % [state, ratio, MIN_CONTRAST])
			print("KONTRAST %s %.2f" % [state, ratio])
	screen.queue_free()
	await process_frame
	await process_frame


# ---------------------------------------------------------------- Schiffsgruppen-Block
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
	if node is LineEdit:
		result.append((node as LineEdit).text)
		result.append((node as LineEdit).placeholder_text)
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
		var rotte := false
		var heading := false
		for text in texts:
			if String(text).contains("solo:"): raw = true
			if String(text).to_lower().contains("rotte"): rotte = true
			if String(text).begins_with("SCHIFFSGRUPPEN"): heading = true
		_check(not raw, "%d Schiff(e): kein Text mit der rohen Kennung 'solo:' (%s)" % [ship_count, str(texts)])
		_check(not rotte, "%d Schiff(e): kein sichtbarer Text enthaelt 'Rotte' (%s)" % [ship_count, str(texts)])
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


# ---------------------------------------------------------------- Echter Aufbauweg der Schiffsnamen
## Echte Basis (Spielstart Kampagne) -> echter Schnappschuss des Laufzeit-Adapters (Feld "crafts" aus den Flugzeugdefinitionen)
## -> echte Wing-Zustandsklasse (Einzelgruppen "solo:...") -> echte Sternkarte mit ihrem Schiffsgruppen-Block.
func _real_wing_names() -> void:
	var isolation: Dictionary = GUARD.verdict_from_environment()
	if not bool(isolation.get("ok", false)):
		_check(false, "echter Aufbauweg braucht ein Wegwerfprofil (SB_REVIEW2_USER_DIR): %s" % str(isolation.get("reason", "")))
		return
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	root.size = Vector2i(1920, 1080)
	START.request_start(self, "campaign", "new")
	var flow: Node = FLOW.instantiate()
	root.add_child(flow)
	for i in 12:
		await process_frame
	var real: Dictionary = flow.call("_get_star_map_snapshot")
	var crafts: Array = Array(real.get("crafts", []))
	_check(real.has("crafts") and crafts.size() == 1, "echter Sternkarten-Schnappschuss enthaelt das Feld crafts mit dem Startschiff (%d)" % crafts.size())
	if crafts.is_empty():
		flow.queue_free()
		await process_frame
		return
	var start_name := String(Dictionary(crafts[0]).get("display_name", ""))
	var start_id := String(Dictionary(crafts[0]).get("craft_id", ""))
	_check(not start_name.is_empty() and not start_name.begins_with("solo:") and start_name != start_id, "Startschiff hat einen Anzeigenamen (%s / %s)" % [start_name, start_id])
	for ship_count in [1, 2]:
		if ship_count == 2:
			flow.call("_on_homebase_aircraft_add_requested", "dropship")
			for i in 6:
				await process_frame
		real = flow.call("_get_star_map_snapshot")
		crafts = Array(real.get("crafts", []))
		_check(crafts.size() == ship_count, "echter Schnappschuss fuehrt %d Schiff(e) (%d)" % [ship_count, crafts.size()])
		var ids: Array = []
		for craft: Dictionary in crafts: ids.append(String(craft.get("craft_id", "")))
		var wing_state := WING_STATE.new()
		var pilots: Dictionary = Dictionary(flow.get("_assigned_aircraft_pilot_by_craft")).duplicate(true)
		var reconciled: Dictionary = wing_state.reconcile_flying_wings("singleplayer", [start_id], ids, pilots)
		_check(bool(reconciled.get("ok", false)), "echter Wing-Zustand legt die Einzelgruppe des fliegenden Startschiffs an (%s)" % str(reconciled))
		var snapshot: Dictionary = real.duplicate(true)
		snapshot["space_wings"] = wing_state.get_snapshot()
		var host := Control.new()
		root.add_child(host)
		host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var star := STAR.new()
		host.add_child(star)
		star.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		star.configure(func(): return snapshot, func(_op, _payload = {}): return {"ok": true})
		for i in 6:
			await process_frame
		var panel := star.find_child("SpaceWingPanel", true, false) as Control
		_check(panel != null, "%d Schiff(e): Sternkarte baut den Schiffsgruppen-Block" % ship_count)
		if panel != null:
			var tabs: Array = panel.find_children("WingTab_*", "Button", true, false)
			var joined := ""
			for tab: Button in tabs: joined += tab.text + "|"
			_check(tabs.size() == 1 and joined.contains(start_name) and not joined.contains("Einzelschiff") and not joined.contains("solo:"), "%d Schiff(e): Reiter zeigt den Anzeigenamen '%s' (beobachtet %s)" % [ship_count, start_name, joined])
			var body := panel.find_child("WingBody", true, false) as Control
			if ship_count == 1:
				_check(body != null and not body.is_visible_in_tree(), "mit dem Startschiff allein ist der Block eingeklappt")
			else:
				_check(body != null and body.is_visible_in_tree(), "mit zwei Schiffen ist der Block offen")
		host.queue_free()
		await process_frame
	flow.queue_free()
	await process_frame
	await process_frame
