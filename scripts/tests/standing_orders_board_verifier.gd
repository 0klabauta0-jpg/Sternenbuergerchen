extends SceneTree
## Auftragstafel (Handel H3, Aufgabe A): Die Dauerauftraege stehen unter den normalen Auftraegen. Echte Tafel, echter Kampagnenstand,
## echter Dauerauftrags-Besitzer; die Tafel liest nur. Gesperrte und nicht verfuegbare Zeilen tragen "Gesperrt: ".
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
const BOARD = preload("res://scripts/meta/singleplayer_job_board_presenter.gd")
const STANDING = preload("res://scripts/core/standing_orders_state.gd")
const FA := "freight:trade_outpost:c_benit"
var passed := 0
var failed := 0

class SnapshotScreen extends Control:
	var snapshot: Dictionary = {}
	var commands: Array = []
	func get_operations_snapshot() -> Dictionary: return {"singleplayer":snapshot}
	func request_operation(operation: String, payload: Dictionary) -> Dictionary:
		commands.append([operation, payload])
		return {"ok":false, "reason":"read_only_fixture"}

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func _texts(board: Control) -> Dictionary:
	var result: Dictionary = {}
	var box: Node = board.get("_standing_box")
	for child: Node in box.get_children():
		if child is Label: result[String(child.name)] = String(child.text)
	return result

func _run() -> void:
	var campaign_owner := CAMPAIGN.new()
	var travel_owner := TRAVEL.new()
	_check(campaign_owner.configure().get("ok", false) and travel_owner.configure("ship").get("ok", false), "echte Kampagne und Reise konfigurieren")
	var standing := STANDING.new()
	_check(standing.configure(JSON.parse_string(FileAccess.get_file_as_string("res://data/singleplayer/standing_orders.json"))), "echte Daueraufträge konfigurieren")
	# Namen aus den echten Katalogen (wie im Adapter), keine eigenen.
	standing.set_names(load("res://scripts/mission/campaign_display_catalog.gd").LOCATION_NAMES, load("res://scripts/ui/components/personnel_inventory_panel.gd").LABELS)
	var screen := SnapshotScreen.new()
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var board := BOARD.new()
	screen.add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.configure(screen)
	var project := func(with_standing: bool) -> Dictionary:
		var campaign: Dictionary = campaign_owner.get_campaign_snapshot()
		campaign["job_availability"] = campaign_owner.get_job_availability(true)
		if with_standing: campaign["standing_orders"] = standing.get_snapshot({})
		return {"mode": "campaign", "campaign": campaign, "space_travel": travel_owner.get_snapshot()}
	# Skirmish und alter Stand: kein Schluessel, keine Zeilen.
	screen.snapshot = project.call(false)
	board.refresh()
	_check(_texts(board).is_empty(), "ohne Schluessel steht kein Dauerauftrag auf der Tafel")
	# Die Pruefungen haengen an der Anzeigezeile: leere Liste = kein Block (Gegenfall), mit Daten stehen die Zeilen (Fall unten).
	var empty_projection: Dictionary = project.call(false)
	empty_projection.campaign["standing_orders"] = []
	screen.snapshot = empty_projection
	board.refresh()
	_check(_texts(board).is_empty() and board.get("_standing_box").get_child_count() == 0, "leere Liste: kein Block, keine Ueberschrift")
	# Kampagne: fuenf Zeilen unter den normalen Auftraegen.
	screen.snapshot = project.call(true)
	board.refresh()
	var texts: Dictionary = _texts(board)
	_check(texts.has("StandingOrdersHeading") and String(texts.get("StandingOrdersHeading", "")) == "Daueraufträge", "mit Daten: Ueberschrift steht (Gegenprobe zum leeren Fall)")
	_check(texts.size() == 6, "Ueberschrift und fuenf Zeilen (beobachtet %d)" % texts.size())
	_check(String(texts.get("StandingOrder_freight_trade_outpost_c_benit", "")) == "Fracht: 4 Kisten C-Benit nach Aschental · 30 Cr\nAnnahme beim Händler in Kestrel.", "Fracht offen: Titel und Satz (beobachtet \"%s\")" % texts.get("StandingOrder_freight_trade_outpost_c_benit", "-"))
	_check(String(texts.get("StandingOrder_mining_satellite_crash_a_benit", "")) == "Mining: A-Benit (Aschental) · 8 Cr je Stück\nGesperrt: Braucht: Hand-Mining-Tool. Ein Mining-Schiff gibt es noch nicht.", "Mining: Gesperrt mit Grund (beobachtet \"%s\")" % texts.get("StandingOrder_mining_satellite_crash_a_benit", "-"))
	_check(String(texts.get("StandingOrder_salvage_satellite_crash_salvage", "")) == "Bergung: Bergungsgut (Aschental) · 8 Cr je Stück\nGesperrt: Braucht: Bergungswerkzeug.", "Bergung: Gesperrt mit Grund (beobachtet \"%s\")" % texts.get("StandingOrder_salvage_satellite_crash_salvage", "-"))
	var parent: Node = board.get("_standing_box").get_parent()
	_check(parent.get_children().find(board.get("_standing_box")) > parent.get_children().find(board.get("_job_cards")), "Dauerauftraege stehen unter den normalen Auftraegen")
	# Sperrzeit: Annahme und Abgabe, dann steht "Gesperrt: Wieder verfuegbar in 8:00."
	standing.accept(FA)
	screen.snapshot = project.call(true)
	board.refresh()
	_check(String(_texts(board).get("StandingOrder_freight_trade_outpost_c_benit", "")).ends_with("\nUnterwegs: 4 Kisten nach Aschental."), "laufend: Unterwegs-Satz ohne Sperrvorsatz")
	standing.finish(FA, true)
	standing.advance_clock(1.0)
	screen.snapshot = project.call(true)
	board.refresh()
	_check(String(_texts(board).get("StandingOrder_freight_trade_outpost_c_benit", "")).ends_with("\nGesperrt: Wieder verfügbar in 7:59."), "gesperrt: Text mit Restzeit (beobachtet \"%s\")" % _texts(board).get("StandingOrder_freight_trade_outpost_c_benit", "-"))
	standing.advance_clock(479.0)
	screen.snapshot = project.call(true)
	board.refresh()
	_check(String(_texts(board).get("StandingOrder_freight_trade_outpost_c_benit", "")).ends_with("\nAnnahme beim Händler in Kestrel."), "nach der Sperrzeit wieder offen")
	_check(screen.commands.is_empty(), "die Tafel gibt keinen Befehl aus und hat keinen Annehmen-Knopf fuer Dauerauftraege")
	screen.queue_free()
	await process_frame
	print("STANDING_ORDERS_BOARD passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
