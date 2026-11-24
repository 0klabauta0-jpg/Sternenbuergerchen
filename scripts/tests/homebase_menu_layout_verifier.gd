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
	if host != null:
		host.grab_focus()
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	# Der Handler der Basisansicht wird direkt gerufen: Im echten Spiel nimmt der Autoload GlobalEscapeMenu Esc (in _input) vor der
	# Basisansicht an und oeffnet das Spielmenue; das war schon vor diesem Umbau so und ist hier nicht Gegenstand.
	base.call("_unhandled_key_input", esc)
	_check(exits[0] == 1, "Esc-Handler der Basisansicht loest weiter den Wechsel aus der Basisansicht aus (Zaehler %d)" % exits[0])
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
		if bool(unit.get("busy", false)):
			people_out += 1
		else:
			people_in += 1
	var crafts_in := 0
	var crafts_out := 0
	for craft: Dictionary in snapshot.get("crafts", []):
		if bool(craft.get("busy", false)):
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
	presenter.call("refresh")
	for i in 20:
		await process_frame
	status = presenter.find_child("HomebaseStatus", true, false) as Label
	_check(status != null and status.text.contains("Credits 4321"), "Statuszeile aktualisiert sich nach Aenderung des Guthabens (beobachtet \"%s\")" % (status.text if status != null else "-"))
	flow.queue_free()
	await process_frame
	print("HOMEBASE_MENU_LAYOUT passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
