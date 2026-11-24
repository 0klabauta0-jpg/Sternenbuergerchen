extends SceneTree
## Heimatbasis, Bedienung (Wunsch 24.11.): linke Leiste neu geordnet und einheitlich, Kopfzeile mit Stand, zwei schwebende Knoepfe weg.
## Echter Bildschirm, echter Kampagnenstand, kopflos. Es wird nur gelesen und eine Anzeigezahl (Guthaben) im Besitzer veraendert.
const EXPECTED_ORDER: Array = ["Smart Mobile", "Basis", "Bauen", "Werkstatt", "Lager", "Datenterminal", "Personal", "Trupp", "Flugdeck", "RRR-Service", "Sternkarte", "Charakterdetails"]
var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
	print(("PASS " if value else "FAIL ") + label)


func _collect_buttons(node: Node, result: Array) -> void:
	for child: Node in node.get_children():
		if child is Button and not String(child.name).begins_with("Toggle") and (child as Button).is_visible_in_tree():
			result.append(child)
		else:
			_collect_buttons(child, result)


func _find_labels(node: Node, result: Array) -> void:
	for child: Node in node.get_children():
		if child is Label:
			result.append(child)
		_find_labels(child, result)


## Taste druecken und loslassen ueber die echte Eingabe des Fensters. Gibt zurueck, ob der Druck von jemandem angenommen wurde.
func _key(code: Key) -> bool:
	var down := InputEventKey.new()
	down.keycode = code
	down.physical_keycode = code
	down.pressed = true
	root.push_input(down)
	var handled: bool = root.is_input_handled()
	await process_frame
	var up := InputEventKey.new()
	up.keycode = code
	up.physical_keycode = code
	up.pressed = false
	root.push_input(up)
	await process_frame
	return handled


## Echter Mausklick (Bewegung, Druck, Loslassen) an einem Punkt des Fensters.
func _click_at(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion)
	await process_frame
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		event.global_position = point
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		root.push_input(event)
		await process_frame


func _settle(frames: int = 10) -> void:
	for i in frames:
		await process_frame


func _bar_state(presenter: Control) -> Dictionary:
	var scroll: Node = presenter.find_child("NavigationScroll", true, false)
	var bar_buttons: Array = []
	_collect_buttons(scroll, bar_buttons)
	var bar_labels: Array = []
	_find_labels(presenter.find_child("NavigationColumn", true, false), bar_labels)
	var visible_labels := 0
	for label: Label in bar_labels:
		if label.is_visible_in_tree() and not label.text.is_empty():
			visible_labels += 1
	var workspace: Control = presenter.find_child("Workspace", true, false)
	return {"buttons": bar_buttons, "labels": visible_labels, "width": (presenter.find_child("NavigationColumn", true, false) as Control).size.x, "workspace": workspace.size.x}


func _check_collapsible_bar(screen: Node, presenter: Control) -> void:
	screen.call("request_operation", "navigate", {"mode": "base"})
	await _settle(12)
	var toggle: Button = presenter.find_child("ToggleNavigation", true, false) as Button
	_check(toggle != null and toggle.is_visible_in_tree(), "Umschalter der linken Leiste (ToggleNavigation) ist da und sichtbar")
	if toggle == null:
		return
	var open_state: Dictionary = _bar_state(presenter)
	var open_texts: Array = Array(open_state.buttons).map(func(b: Button) -> String: return b.text)
	_check(open_texts == EXPECTED_ORDER, "ausgeklappt (Vorgabe): Beschriftungen wie bisher (beobachtet %s)" % str(open_texts))
	# Klick auf die Ecke des Umschalters (ganze Flaeche klickbar), nicht nur auf die Mitte.
	var rect: Rect2 = toggle.get_global_rect()
	await _click_at(rect.position + Vector2(3, 3))
	await _settle()
	var closed: Dictionary = _bar_state(presenter)
	_check(float(closed.width) < float(open_state.width) * 0.4, "eingeklappt: Leiste schmal (%.0f px statt %.0f px, unter 40 Prozent)" % [closed.width, open_state.width])
	_check(int(closed.labels) == 0, "eingeklappt: kein Beschriftungs-Label sichtbar (%d)" % int(closed.labels))
	_check(Array(closed.buttons).size() == EXPECTED_ORDER.size(), "eingeklappt: Anzahl der Knoepfe unveraendert (%d statt %d)" % [Array(closed.buttons).size(), EXPECTED_ORDER.size()])
	var all_ok := true
	var order_ok := true
	var bad := ""
	var index := 0
	for b: Button in closed.buttons:
		var size_ok: bool = b.get_global_rect().size.x >= 43.5 and b.get_global_rect().size.y >= 43.5
		var tip_ok: bool = not b.tooltip_text.strip_edges().is_empty()
		var text_ok: bool = b.text.is_empty() and b.icon != null
		if not (size_ok and tip_ok and text_ok):
			all_ok = false
			bad += " [%d: %s %s tip='%s' text='%s']" % [index, str(b.get_global_rect().size), str(b.icon != null), b.tooltip_text, b.text]
		if index < EXPECTED_ORDER.size() and not b.tooltip_text.begins_with(String(EXPECTED_ORDER[index])):
			order_ok = false
		index += 1
	_check(all_ok, "eingeklappt: jeder Knopf mindestens 44 x 44, mit Icon, ohne Text, mit Tooltip%s" % bad)
	_check(order_ok, "eingeklappt: Reihenfolge der Knoepfe unveraendert (Tooltips beginnen mit den Namen)")
	_check(toggle.get_global_rect().size.x >= 43.5 and toggle.get_global_rect().size.y >= 43.5 and not toggle.tooltip_text.is_empty(), "eingeklappt: auch der Umschalter ist mindestens 44 x 44 und hat einen Tooltip")
	_check(float(closed.workspace) > float(open_state.workspace) + 50.0, "eingeklappt: Inhalt rechts ist breiter geworden (%.0f px statt %.0f px)" % [closed.workspace, open_state.workspace])
	# Zustand bleibt beim Ansichtswechsel (Basis -> Lager -> Basis) und ueber refresh().
	screen.call("request_operation", "navigate", {"mode": "squad"})
	await _settle()
	var squad_state: Dictionary = _bar_state(presenter)
	_check(float(squad_state.width) < float(open_state.width) * 0.4 and int(squad_state.labels) == 0, "eingeklappt bleibt in der Trupp-Ansicht (%.0f px)" % squad_state.width)
	screen.call("request_operation", "navigate", {"mode": "base"})
	await _settle()
	presenter.call("refresh")
	await _settle()
	var back: Dictionary = _bar_state(presenter)
	var back_ok := true
	for b: Button in back.buttons:
		if not b.text.is_empty() or b.tooltip_text.is_empty():
			back_ok = false
	_check(float(back.width) < float(open_state.width) * 0.4 and back_ok, "eingeklappt bleibt nach Basis -> Trupp -> Basis und refresh() (%.0f px)" % back.width)
	# Zweiter Klick (Mitte): wieder ausgeklappt.
	await _click_at(toggle.get_global_rect().get_center())
	await _settle()
	var reopened: Dictionary = _bar_state(presenter)
	var reopened_texts: Array = Array(reopened.buttons).map(func(b: Button) -> String: return b.text)
	_check(absf(float(reopened.width) - float(open_state.width)) < 1.0, "zweiter Klick: Ausgangsbreite (%.0f px, vorher %.0f px)" % [reopened.width, open_state.width])
	_check(reopened_texts == EXPECTED_ORDER, "zweiter Klick: Beschriftungen und Reihenfolge wie vorher (beobachtet %s)" % str(reopened_texts))
	_check(absf(float(reopened.workspace) - float(open_state.workspace)) < 1.0, "zweiter Klick: Inhalt wieder so breit wie vorher")
	var tip_restored := true
	for b: Button in reopened.buttons:
		if b.text == "RRR-Service" and b.tooltip_text != "Tanken · Reparieren · Aufmunitionieren":
			tip_restored = false
	_check(tip_restored, "zweiter Klick: Hilfetext des RRR-Service wieder wie vorher")


func _by_text(buttons: Array) -> Dictionary:
	var result: Dictionary = {}
	for button: Button in buttons:
		result[button.text] = button
	return result


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	for i in 8:
		await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	var presenter: Control = screen.get("_operations_presenter")
	presenter.call("set_interface_settings_path_for_tests", "user://nav_groups_fixture_hb_layout.cfg")
	presenter.call("set_nav_group_open", "base", true)
	presenter.call("set_nav_group_open", "mission", true)
	screen.call("request_operation", "navigate", {"mode": "base"})
	for i in 14:
		await process_frame
	# --- Reihenfolge und Texte
	var scroll: Node = presenter.find_child("NavigationScroll", true, false)
	var buttons: Array = []
	_collect_buttons(scroll, buttons)
	var texts: Array = buttons.map(func(b: Button) -> String: return b.text)
	_check(texts == EXPECTED_ORDER, "Leiste von oben: %s (beobachtet %s)" % [str(EXPECTED_ORDER), str(texts)])
	var by_text: Dictionary = _by_text(buttons)
	var main_names: Array = ["Smart Mobile", "Personal", "Trupp", "Flugdeck", "Sternkarte"]
	var sub_names: Array = ["Bauen", "Werkstatt", "Lager", "Datenterminal"]
	var all_names: Array = ["Smart Mobile", "Basis", "Bauen", "Werkstatt", "Lager", "Datenterminal", "Personal", "Trupp", "Flugdeck", "RRR-Service", "Sternkarte"]
	if not by_text.has("Basis") or not by_text.has("Smart Mobile") or not by_text.has("RRR-Service") or not by_text.has("Bauen"):
		_check(false, "Leistenknoepfe fehlen, Rest nicht pruefbar")
		print("HOMEBASE_MENU_LAYOUT passed=%d failed=%d" % [passed, failed])
		quit(1)
		return
	# --- Einheitliche Schrift, Groesse, einzeilig, Icon
	var ref: Button = by_text["Personal"]
	var same_font := true
	var same_size := true
	var one_line := true
	var all_icons := true
	var rounded_same := true
	for name: String in all_names:
		var b: Button = by_text[name]
		if b.get_theme_font("font") != ref.get_theme_font("font"):
			same_font = false
		if b.get_theme_font_size("font_size") != ref.get_theme_font_size("font_size"):
			same_size = false
		if b.text.contains("\n") or b.autowrap_mode != TextServer.AUTOWRAP_OFF:
			one_line = false
		if b.icon == null:
			all_icons = false
		if b.alignment != HORIZONTAL_ALIGNMENT_LEFT:
			rounded_same = false
	_check(same_font, "alle Leistenknoepfe: dieselbe Schrift")
	_check(same_size, "alle Leistenknoepfe: dieselbe Schriftgroesse")
	_check(one_line, "alle Leistenknoepfe: einzeilig (kein Zeilenumbruch, kein Autowrap)")
	_check(all_icons, "alle Leistenknoepfe haben ein Icon")
	_check(rounded_same, "alle Leistenknoepfe: linksbuendig")
	var same_box := true
	var ref_box: StyleBox = ref.get_theme_stylebox("normal")
	for name: String in all_names:
		var box: StyleBox = (by_text[name] as Button).get_theme_stylebox("normal")
		if box == null or ref_box == null or box.get_class() != ref_box.get_class():
			same_box = false
		elif box is StyleBoxFlat and ref_box is StyleBoxFlat:
			if (box as StyleBoxFlat).corner_radius_top_left != (ref_box as StyleBoxFlat).corner_radius_top_left or (box as StyleBoxFlat).border_width_left != (ref_box as StyleBoxFlat).border_width_left:
				same_box = false
	_check(same_box, "alle Leistenknoepfe: dieselbe Rahmenform (Ecken, Rahmenbreite)")
	# --- Groessen
	var base_h: float = (by_text["Basis"] as Button).get_global_rect().size.y
	var main_h: float = (by_text["Smart Mobile"] as Button).get_global_rect().size.y
	_check(base_h >= main_h * 1.2 and base_h <= main_h * 1.35, "Basis ist etwa 25 Prozent hoeher (Basis %.1f, Haupt %.1f)" % [base_h, main_h])
	var mains_equal := true
	for name: String in main_names:
		if not is_equal_approx((by_text[name] as Button).get_global_rect().size.y, main_h):
			mains_equal = false
	_check(mains_equal, "Smart Mobile, Personal, Trupp, Flugdeck, Sternkarte sind gleich gross")
	var sub_h: float = (by_text["Bauen"] as Button).get_global_rect().size.y
	var sub_w: float = (by_text["Bauen"] as Button).get_global_rect().size.x
	var subs_equal := true
	for name: String in sub_names + ["RRR-Service"]:
		var r: Rect2 = (by_text[name] as Button).get_global_rect()
		if not is_equal_approx(r.size.y, sub_h) or not is_equal_approx(r.size.x, sub_w):
			subs_equal = false
	_check(subs_equal, "Bauen, Werkstatt, Lager, Datenterminal und RRR-Service sind genau gleich gross")
	_check(sub_h < base_h, "Unterpunkte sind kleiner als Basis (%.1f < %.1f)" % [sub_h, base_h])
	var base_x: float = (by_text["Basis"] as Button).get_global_rect().position.x
	var flight_x: float = (by_text["Flugdeck"] as Button).get_global_rect().position.x
	_check((by_text["Bauen"] as Button).get_global_rect().position.x > base_x + 4.0, "Basis-Unterpunkte sind eingerueckt")
	_check((by_text["RRR-Service"] as Button).get_global_rect().position.x > flight_x + 4.0, "RRR-Service ist unter dem Flugdeck eingerueckt")
	_check((by_text["RRR-Service"] as Button).tooltip_text == "Tanken · Reparieren · Aufmunitionieren", "RRR-Service traegt den Hilfetext (beobachtet \"%s\")" % (by_text["RRR-Service"] as Button).tooltip_text)
	# --- Namen der Knoten bleiben (Wegweiser, Pruefer)
	_check(presenter.find_child("OpenBaseServices", true, false) == by_text["RRR-Service"], "Knotenname OpenBaseServices bleibt am RRR-Service")
	_check(presenter.find_child("Navigate_jobs", true, false) == by_text["Smart Mobile"] and presenter.find_child("Navigate_base", true, false) == by_text["Basis"], "Knotennamen Navigate_jobs/Navigate_base bleiben")
	# --- Zwei schwebende Knoepfe weg, Tasten wirken noch
	var base: Control = presenter.get("_base")
	_check(base.find_child("ExitExploration", true, false) == null, "Knopf 'Uebersicht · Esc' gibt es nicht mehr")
	_check(base.find_child("InteractTerminal", true, false) == null, "Knopf 'E · Personal' gibt es nicht mehr")
	var floating_texts := true
	var base_buttons: Array = []
	_collect_buttons(base, base_buttons)
	for b: Button in base_buttons:
		if b.text.begins_with("E · ") or b.text.begins_with("Übersicht") or b.text == "Konsole aufsuchen":
			floating_texts = false
	_check(floating_texts, "kein schwebender Knopf mit 'E · …', 'Übersicht · Esc' oder 'Konsole aufsuchen'")
	_check(base.find_child("ExplorationHelp", true, false) != null, "das kleine Fragezeichen (ExplorationHelp) bleibt")
	var source: String = FileAccess.get_file_as_string("res://scripts/meta/explorable_homebase.gd")
	_check(source.contains("key == KEY_E") and source.contains("request_terminal(_nearby_terminal)"), "Taste E ruft weiter request_terminal auf")
	var exits := [0]
	var host: Control = base.get("_host")
	base.connect("exploration_exit_requested", func(): exits[0] += 1)
	# Esc und E ueber ECHTE Eingabe (root.push_input durch Oberflaeche, Fokus-Weitergabe und Autoload), mit dem Fokus auf dem
	# Basisbild und auf Leistenknoepfen (nach einem Klick auf Bauen/Lager hat der Knopf den Fokus). Wirkung wie vorher die zwei Knoepfe.
	var menu: Node = root.get_node_or_null("GlobalEscapeMenu")
	_check(menu != null, "Autoload GlobalEscapeMenu ist im Baum (Esc geht durch denselben Weg wie im Spiel)")
	for focus_case: String in ["Basisbild", "Bauen", "Lager"]:
		if menu != null and bool(menu.call("is_overlay_open")):
			menu.call("close_menu")
		# Jeder Fall beginnt frisch auf dem Basisbild ohne Seitenfenster (Esc oeffnet dort das Spielmenue).
		screen.call("request_operation", "navigate", {"mode": "base"})
		for i in 12:
			await process_frame
		if focus_case == "Basisbild":
			if host != null:
				host.grab_focus()
		else:
			(by_text[focus_case] as Button).grab_focus()
		await process_frame
		var e_handled: bool = await _key(KEY_E)
		_check(e_handled, "E mit Fokus auf %s: erreicht die Basisansicht (Konsole aufsuchen)" % focus_case)
		var before: int = exits[0]
		await _key(KEY_ESCAPE)
		for i in 4:
			await process_frame
		var menu_opened: bool = menu != null and bool(menu.call("is_overlay_open"))
		_check(menu_opened, "Esc mit Fokus auf %s (leeres Basisbild): Spielmenue ist offen" % focus_case)
		_check(String(presenter.get("_mode")) == "base" and exits[0] == before, "Esc mit Fokus auf %s: Modus weiter 'base', Trupp-Seite NICHT offen (Modus '%s', Wechsel %d)" % [focus_case, String(presenter.get("_mode")), exits[0] - before])
		if menu_opened:
			menu.call("close_menu")
	# N1: Esc bei offenem Seitenfenster (Smart Mobile, Bauen, Lager) schliesst NUR das Fenster, wie das "x"; erst das zweite Esc wirkt wie ohne Fenster.
	for window_case: String in ["Smart Mobile", "Bauen", "Lager"]:
		if menu != null and bool(menu.call("is_overlay_open")):
			menu.call("close_menu")
		screen.call("request_operation", "navigate", {"mode": "base"})
		for i in 12:
			await process_frame
		(by_text[window_case] as Button).pressed.emit()
		for i in 12:
			await process_frame
		_check(bool(presenter.call("is_workspace_flyout_open")), "Seitenfenster %s: ist offen (Testlage)" % window_case)
		(by_text[window_case] as Button).grab_focus()
		await process_frame
		var exits_win: int = exits[0]
		await _key(KEY_ESCAPE)
		for i in 4:
			await process_frame
		var win_menu: bool = menu != null and bool(menu.call("is_overlay_open"))
		_check(not bool(presenter.call("is_workspace_flyout_open")), "Esc bei offenem %s: Seitenfenster ist zu" % window_case)
		_check(String(presenter.get("_mode")) == "base", "Esc bei offenem %s: Modus ist weiter 'base' (beobachtet '%s')" % [window_case, String(presenter.get("_mode"))])
		_check(not win_menu, "Esc bei offenem %s: Spielmenue ist NICHT offen" % window_case)
		_check(exits[0] == exits_win, "Esc bei offenem %s: Trupp-Seite ist NICHT offen (Wechsel %d)" % [window_case, exits[0] - exits_win])
		await _key(KEY_ESCAPE)
		for i in 4:
			await process_frame
		win_menu = menu != null and bool(menu.call("is_overlay_open"))
		_check(win_menu and exits[0] == exits_win and String(presenter.get("_mode")) == "base", "Zweites Esc nach %s: oeffnet das Spielmenue, Trupp-Seite bleibt zu (Wechsel %d, Menue offen %s)" % [window_case, exits[0] - exits_win, str(win_menu)])
		if win_menu:
			menu.call("close_menu")
	# Ausserhalb der Basisansicht (Uebersicht Trupp) bleibt Esc beim Spielmenue wie bisher.
	screen.call("request_operation", "navigate", {"mode": "squad"})
	for i in 10:
		await process_frame
	var exits_before_squad: int = exits[0]
	await _key(KEY_ESCAPE)
	var squad_menu: bool = menu != null and bool(menu.call("is_overlay_open"))
	_check(squad_menu and exits[0] == exits_before_squad, "Esc ausserhalb der Basisansicht oeffnet weiter das Spielmenue (Menue offen %s, Wechsel %d)" % [str(squad_menu), exits[0] - exits_before_squad])
	if squad_menu:
		menu.call("close_menu")
		await process_frame
	# --- Teil F: linke Leiste ein- und ausklappbar
	await _check_collapsible_bar(screen, presenter)
	# --- Kopfzeile
	screen.call("request_operation", "navigate", {"mode": "base"})
	for i in 6:
		await process_frame
	var labels: Array = []
	_find_labels(presenter, labels)
	var has_old := false
	for label: Label in labels:
		if label.text.contains("STERNENBÜRGERCHEN"):
			has_old = true
	_check(not has_old, "kein Text 'STERNENBÜRGERCHEN' auf dem Bildschirm")
	var title: Label = presenter.find_child("HomebaseTitle", true, false) as Label
	var title_text: String = title.text if title != null else ""
	# Namen nicht fest verdrahtet: System = Koerper ohne parent_id, Himmelskoerper = Koerper mit surface_location_id "homebase",
	# beide so, wie der Katalog sie dem Spieler zeigt (campaign_display_catalog.gd; auch Sternkarte und "Standort"-Zeile).
	var display_catalog = load("res://scripts/mission/campaign_display_catalog.gd")
	var bodies: Dictionary = Dictionary(Dictionary(Dictionary(screen.call("get_operations_snapshot").get("singleplayer", {})).get("space_travel", {})).get("bodies", {}))
	var expected_system := ""
	var expected_place := ""
	for body_id in bodies:
		var record: Dictionary = Dictionary(bodies[body_id])
		if String(record.get("parent_id", "x")).is_empty():
			expected_system = String(display_catalog.body_name(String(body_id), record)).to_upper()
		if String(record.get("surface_location_id", "")) == "homebase":
			expected_place = String(display_catalog.body_name(String(body_id), record)).split(" · ")[0].strip_edges().to_upper()
	_check(not expected_system.is_empty() and not expected_place.is_empty(), "Testdaten: System und Heimatkoerper im Reisestand gefunden (%s / %s)" % [expected_system, expected_place])
	_check(title_text == "%s  /  %s  /  HEIMATBASIS" % [expected_system, expected_place], "Kopfzeile: System / Himmelskoerper / HEIMATBASIS (beobachtet \"%s\", erwartet \"%s  /  %s  /  HEIMATBASIS\")" % [title_text, expected_system, expected_place])
	_check(title_text.contains("BÖRNER") and title_text.ends_with("HEIMATBASIS") and title_text.count("HEIMATBASIS") == 1, "Kopfzeile nennt BÖRNER und die Heimatbasis nur einmal (beobachtet \"%s\")" % title_text)
	var status: Label = presenter.find_child("HomebaseStatus", true, false) as Label
	_check(status != null and title != null and status.get_parent() == title.get_parent(), "Statuszeile steht in derselben Kopfzeile")
	var snapshot: Dictionary = screen.call("get_operations_snapshot")
	var supply: Dictionary = Dictionary(Dictionary(snapshot.get("singleplayer", {})).get("supply", {}))
	var people_in := 0
	var people_out := 0
	for unit: Dictionary in snapshot.get("roster", []):
		if bool(unit.get("away", false)):
			people_out += 1
		else:
			people_in += 1
	var crafts_in := 0
	var crafts_out := 0
	for craft: Dictionary in snapshot.get("crafts", []):
		if bool(craft.get("away", false)):
			crafts_out += 1
		else:
			crafts_in += 1
	var status_text: String = status.text if status != null else ""
	_check(status_text.contains("Credits %d" % int(supply.get("credits", -1))), "Statuszeile: Credits aus dem Kampagnenstand (beobachtet \"%s\")" % status_text)
	_check(status_text.contains("Personal %d in der Basis, %d unterwegs" % [people_in, people_out]), "Statuszeile: Personal in der Basis/unterwegs (erwartet %d/%d)" % [people_in, people_out])
	_check(status_text.contains("Schiffe %d in der Basis, %d unterwegs" % [crafts_in, crafts_out]), "Statuszeile: Schiffe in der Basis/unterwegs (erwartet %d/%d)" % [crafts_in, crafts_out])
	_check(status_text.contains("Treibstoff "), "Statuszeile: Treibstoff (beobachtet \"%s\")" % status_text)
	var owner_supply: RefCounted = flow.get("_singleplayer_runtime").get("_supply")
	owner_supply.set("_credits", 4321)
	owner_supply.set("_revision", int(owner_supply.get("_revision")) + 1)
	# W1: KEIN refresh() von aussen. Auf dem Basisbild muss sich die Kopfzeile von selbst nachfuehren (Takt der Anzeige).
	_check(String(presenter.get("_mode")) == "base", "Testlage: Modus 'base' (Kopfzeile laeuft ueber den eigenen Takt)")
	await create_timer(1.3).timeout
	status = presenter.find_child("HomebaseStatus", true, false) as Label
	_check(status != null and status.text.contains("Credits 4321"), "Statuszeile aktualisiert sich von selbst auf dem Basisbild, ohne refresh() (beobachtet \"%s\")" % (status.text if status != null else "-"))
	# K1: Ein Schiff, das die Basis verlassen hat (Orbit), zaehlt als unterwegs; das Anzeigen geschieht ebenfalls ohne refresh().
	var craft_list: Array = snapshot.get("crafts", [])
	var away_craft_id := String(Dictionary(craft_list[0]).get("id", "")) if not craft_list.is_empty() else ""
	# Ortsangabe der Schiffe kommt vom Ablauf (flow) in den Bildschirm; so wie der Ablauf es tut, mit dem Schiff im Orbit.
	var locations: Dictionary = Dictionary(flow.get("_aircraft_location_by_craft")).duplicate(true)
	locations[away_craft_id] = "orbit"
	screen.call("set_transport_state", flow.get("_homebase_aircraft_definitions"), flow.get("_assigned_aircraft_pilot_by_craft"), [], [], locations, {}, {}, [])
	await create_timer(1.3).timeout
	status = presenter.find_child("HomebaseStatus", true, false) as Label
	_check(not away_craft_id.is_empty() and status.text.contains("Schiffe %d in der Basis, %d unterwegs" % [crafts_in - 1, crafts_out + 1]), "Schiff im Orbit zaehlt als unterwegs (erwartet %d/%d, beobachtet \"%s\")" % [crafts_in - 1, crafts_out + 1, status.text])
	locations[away_craft_id] = "homebase"
	screen.call("set_transport_state", flow.get("_homebase_aircraft_definitions"), flow.get("_assigned_aircraft_pilot_by_craft"), [], [], locations, {}, {}, [])
	# K1: an Bord eines Schiffs, das noch am Pad steht, ist in der Basis (Besetzung ist 'busy', aber nicht 'away'); Schiff mit Beladung am Pad ebenso.
	var fake: Dictionary = {"roster": [{"id": "a", "busy": true, "away": false}, {"id": "b", "busy": true, "away": true}, {"id": "c", "busy": false, "away": false}],
		"crafts": [{"id": "x", "busy": true, "away": false}, {"id": "y", "busy": true, "away": true}]}
	presenter.call("_update_header", fake, Dictionary(snapshot.get("singleplayer", {})))
	status = presenter.find_child("HomebaseStatus", true, false) as Label
	_check(status.text.contains("Personal 2 in der Basis, 1 unterwegs") and status.text.contains("Schiffe 1 in der Basis, 1 unterwegs"), "an Bord am Pad = in der Basis; nur wer weg ist, zaehlt unterwegs (beobachtet \"%s\")" % status.text)
	# N2: dieselbe Regel mit ECHTEN Besitzern (Eintraege aus dem Bildschirm, nicht von Hand): Person an Bord (Truppe der Nutzlast) eines Schiffs
	# am Heimatpad = in der Basis; dasselbe Schiff im Orbit = Person und Schiff unterwegs; Summe in der Basis + unterwegs = Gesamtzahl.
	# Gegen den alten Kopf (8ee95cb20, zaehlte 'busy' als unterwegs) ist der Pad-Fall rot; der Orbit-Fall allein waere es nicht.
	var payload_team := ""
	var payload_unit := ""
	for unit: Dictionary in Array(screen.call("get_operations_snapshot").get("roster", [])):
		if not String(unit.get("fireteam_id", "")).is_empty() and not bool(unit.get("away", false)):
			payload_team = String(unit.get("fireteam_id", ""))
			payload_unit = String(unit.get("id", ""))
			break
	# Mit dem Schiff reisen die Truppe der Nutzlast und der eingeteilte Pilot des Schiffs.
	var team_n := 0
	var assigned_pilot := String(Dictionary(flow.get("_assigned_aircraft_pilot_by_craft")).get(away_craft_id, ""))
	for unit: Dictionary in Array(screen.call("get_operations_snapshot").get("roster", [])):
		if String(unit.get("fireteam_id", "")) == payload_team or String(unit.get("id", "")) == assigned_pilot:
			team_n += 1
	_check(not payload_team.is_empty() and not away_craft_id.is_empty(), "N2 Testlage: ein Truppmitglied (%s, Truppe %s) und ein Schiff (%s) sind vorhanden" % [payload_unit, payload_team, away_craft_id])
	screen.set("_homebase_dropship_staged_fireteam_ids_by_craft", {away_craft_id: PackedStringArray([payload_team])})
	locations[away_craft_id] = "homebase"
	screen.call("set_transport_state", flow.get("_homebase_aircraft_definitions"), flow.get("_assigned_aircraft_pilot_by_craft"), [], [], locations, {}, {}, [])
	await create_timer(1.3).timeout
	var n2_snapshot: Dictionary = screen.call("get_operations_snapshot")
	var n2_unit: Dictionary = {}
	for unit: Dictionary in Array(n2_snapshot.get("roster", [])):
		if String(unit.get("id", "")) == payload_unit:
			n2_unit = unit
	_check(bool(n2_unit.get("busy", false)) and not bool(n2_unit.get("away", true)), "N2: Person an Bord am Pad ist 'busy', aber nicht 'away' (Eintrag busy=%s away=%s)" % [str(n2_unit.get("busy")), str(n2_unit.get("away"))])
	status = presenter.find_child("HomebaseStatus", true, false) as Label
	_check(status.text.contains("Personal %d in der Basis, %d unterwegs" % [people_in, people_out]) and status.text.contains("Schiffe %d in der Basis, %d unterwegs" % [crafts_in, crafts_out]), "N2: Person an Bord am Pad zaehlt in der Basis, Schiff ebenso (erwartet %d/%d und %d/%d, beobachtet \"%s\")" % [people_in, people_out, crafts_in, crafts_out, status.text])
	locations[away_craft_id] = "orbit"
	screen.call("set_transport_state", flow.get("_homebase_aircraft_definitions"), flow.get("_assigned_aircraft_pilot_by_craft"), [], [], locations, {}, {}, [])
	await create_timer(1.3).timeout
	n2_snapshot = screen.call("get_operations_snapshot")
	n2_unit = {}
	for unit: Dictionary in Array(n2_snapshot.get("roster", [])):
		if String(unit.get("id", "")) == payload_unit:
			n2_unit = unit
	_check(bool(n2_unit.get("away", false)), "N2: dasselbe Schiff im Orbit: die Person an Bord ist 'away'")
	status = presenter.find_child("HomebaseStatus", true, false) as Label
	_check(status.text.contains("Personal %d in der Basis, %d unterwegs" % [people_in - team_n, people_out + team_n]) and status.text.contains("Schiffe %d in der Basis, %d unterwegs" % [crafts_in - 1, crafts_out + 1]), "N2: im Orbit sind Truppe (%d) und Schiff unterwegs (erwartet %d/%d und %d/%d, beobachtet \"%s\")" % [team_n, people_in - team_n, people_out + team_n, crafts_in - 1, crafts_out + 1, status.text])
	_check((people_in - team_n) + (people_out + team_n) == Array(n2_snapshot.get("roster", [])).size() and (crafts_in - 1) + (crafts_out + 1) == Array(n2_snapshot.get("crafts", [])).size(), "N2: in der Basis + unterwegs = Gesamtzahl (Personal %d, Schiffe %d)" % [Array(n2_snapshot.get("roster", [])).size(), Array(n2_snapshot.get("crafts", [])).size()])
	locations[away_craft_id] = "homebase"
	screen.set("_homebase_dropship_staged_fireteam_ids_by_craft", {})
	screen.call("set_transport_state", flow.get("_homebase_aircraft_definitions"), flow.get("_assigned_aircraft_pilot_by_craft"), [], [], locations, {}, {}, [])
	var real_entry_keys: bool = true
	for unit: Dictionary in snapshot.get("roster", []):
		real_entry_keys = real_entry_keys and unit.has("away")
	for craft: Dictionary in snapshot.get("crafts", []):
		real_entry_keys = real_entry_keys and craft.has("away")
	_check(real_entry_keys, "Besitzer-Eintraege von Personal und Schiffen tragen das Feld 'away'")
	# K2: Standort-Zeile ist im Kopf weg; alle vier Angaben passen vollstaendig in die Statuszeile bei 1920 und bei 1280.
	for resolution: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.size = resolution
		root.content_scale_size = resolution
		presenter.call("refresh")
		for i in 8:
			await process_frame
		status = presenter.find_child("HomebaseStatus", true, false) as Label
		var location_label: Label = presenter.find_child("HomebaseLocation", true, false) as Label
		_check(location_label != null and not location_label.visible, "%s: Standort-Zeile nimmt im Kopf keinen Platz" % str(resolution))
		var font: Font = status.get_theme_font("font")
		var text_width: float = font.get_string_size(status.text, HORIZONTAL_ALIGNMENT_LEFT, -1, status.get_theme_font_size("font_size")).x
		_check(text_width <= status.size.x + 0.5, "%s: Statuszeile ist ganz lesbar (Text %.0f px, Feld %.0f px, \"%s\")" % [str(resolution), text_width, status.size.x, status.text])
		_check(status.text.contains("Credits ") and status.text.contains("Personal ") and status.text.contains("Schiffe ") and (status.text.contains("Treibstoff") or status.text.contains("Tank")), "%s: Credits, Personal, Schiffe und Treibstoff stehen in der Zeile" % str(resolution))
		_check(status.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS, "%s: zu lange Zeile wird mit Auslassungspunkten gekuerzt" % str(resolution))
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	flow.queue_free()
	await process_frame
	print("HOMEBASE_MENU_LAYOUT passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
