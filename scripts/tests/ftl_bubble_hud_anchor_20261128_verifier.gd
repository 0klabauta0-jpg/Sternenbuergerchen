extends SceneTree
## Paket 1 (Funk): Die Truppfuehrer-Blase sitzt rechts neben der Fireteam-Karte im HUD, ueberdeckt nichts,
## steht nie ueber der Figur, hat je Trupp hoechstens eine Blase und liest verstaendliche deutsche Saetze.

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const COPY_PATH: String = "res://data/tactical_communication_copy.json"
const COMMS_PATH: String = "res://data/comms_lines.json"
const MINI_CARDS_PATH: String = "TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox"
const AVOID_PATHS: PackedStringArray = [
	"TacticalUI/TopNavPanel",
	"TacticalUI/MissionIdentityPanel",
	"TacticalUI/MissionDropshipPanel",
	"TacticalUI/TacticalEventLogPanel",
	"TacticalUI/A5TargetOrderPanel",
	"TacticalUI/BottomDock/A5InstrumentSurface",
]
## Ersatzschreibung (ae/oe/ue/ss statt Umlaut), Kuerzel und englische Funkwoerter, die im Spiel nicht mehr stehen duerfen.
const FORBIDDEN_FRAGMENTS: PackedStringArray = [
	"bestaetigt", "ausfuehr", "naechst", "fuer ", "Ruecke", "rueck", "moeglich", "laeuft", "zerstort", "Sued", "koennen",
	"muessen", "gehoert", "waehle", "noetig", "Flaeche", "Verstaerk", "Fuehrung", "fuehr", "Pruef", "pruef", "Ueber", "ueber",
	"Haelt", "haelt", "geschuetzt", "Gefaehr", "Raeum", "Ziel eingenommen!!",
]
const FORBIDDEN_WORD_PATTERNS: PackedStringArray = [
	"\\bQ\\d+\\b", "\\bP\\d+\\b", "\\bACK\\b", "\\bBLOCK\\b", "\\bORDERS?\\b", "\\bOBJ\\b", "\\bLZ\\b", "\\bContacts?\\b",
	"\\bObjective\\b", "\\bAir Asset\\b", "\\bRecovery\\b", "\\bRoger\\b", "\\bWilco\\b", "\\bCopy\\b", "\\bOverwatch\\b",
	"\\bsuppressed\\b", "\\bpinned\\b", "\\bTaking fire\\b", "\\bFlanking\\b", "\\bcontested\\b", "\\bclear\\b", "\\bAll clear\\b",
	"\\bcommand\\b", "\\bplan\\b.*\\bbounding\\b", "\\bBound\\b", "\\bswitch\\b", "\\bleader down\\b", "\\bman down\\b",
]

var _passed: int = 0
var _failed: int = 0
var _skip_detail: bool = false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== FTL-Blase an der Fireteam-Karte (Funk Paket 1) ===")
	_check_text_catalogs()
	await _check_mission(Vector2i(1280, 720))
	await _check_mission(Vector2i(1920, 1080))
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check_text_catalogs() -> void:
	var copy_texts: PackedStringArray = PackedStringArray()
	var copy_catalog: Dictionary = _read_json(COPY_PATH)
	_assert(not copy_catalog.is_empty(), "Satzdatei tactical_communication_copy.json ist lesbar")
	_collect_copy_strings(copy_catalog, copy_texts)
	_assert(copy_texts.size() > 60, "Satzdatei enthaelt die Saetze fuer Ereignisse, Anlaesse, Befehle und Pruefmeldungen (%d)" % copy_texts.size())
	var comms_texts: PackedStringArray = PackedStringArray()
	for line_variant in Array(_read_json(COMMS_PATH).get("lines", [])):
		var line: Dictionary = Dictionary(line_variant)
		for variant_variant in Array(line.get("variants", [])):
			comms_texts.append(String(Dictionary(variant_variant).get("text", "")))
		for override_variant in Dictionary(line.get("trait_overrides", {})).values():
			for variant_variant in Array(Dictionary(override_variant).get("variants", [])):
				comms_texts.append(String(Dictionary(variant_variant).get("text", "")))
	_assert(comms_texts.size() > 150, "comms_lines.json enthaelt die Funksaetze (%d)" % comms_texts.size())
	var bad: PackedStringArray = PackedStringArray()
	for text in copy_texts:
		_collect_text_problems(text, bad)
	for text in comms_texts:
		_collect_text_problems(text, bad)
	_assert(bad.is_empty(), "Saetze ohne Ersatzumlaute, Q/P-Kuerzel und englische Funkwoerter (Funde: %s)" % ", ".join(bad))
	var too_long: PackedStringArray = PackedStringArray()
	var bubble_texts: PackedStringArray = PackedStringArray()
	_skip_detail = true
	_collect_copy_strings(copy_catalog, bubble_texts)
	_skip_detail = false
	for text in bubble_texts:
		if text.split(" ", false).size() > 9 or text.length() > 56:
			too_long.append(text)
	_assert(too_long.is_empty(), "Saetze der Blase sind kurz (hoechstens 9 Woerter, Funde: %s)" % " | ".join(too_long))
	var comms_too_long: PackedStringArray = PackedStringArray()
	for text in comms_texts:
		if text.split(" ", false).size() > 14:
			comms_too_long.append(text)
	_assert(comms_too_long.is_empty(), "Funksaetze der Kameraden bleiben unter 15 Woertern (Funde: %s)" % " | ".join(comms_too_long))


func _collect_copy_strings(node: Variant, result: PackedStringArray) -> void:
	if typeof(node) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(node)
		for key in dict.keys():
			var skip_group: bool = String(key) == "purpose" or String(key) == "direction_words" or String(key) == "timing"
			if skip_group or (_skip_detail and String(key) == "detail"):
				continue
			var value: Variant = dict[key]
			if typeof(value) == TYPE_STRING and (String(key) in ["short", "detail", "map_label", "low", "neutral", "high"] or _is_validation_key(String(key))):
				result.append(String(value))
			else:
				_collect_copy_strings(value, result)


func _is_validation_key(key: String) -> bool:
	return key in ["select_tile_first", "observer_mode", "wait_for_insertion", "blocked_route", "no_los", "too_far", "no_orders", "no_contact", "select_fireteam_first", "set_lz_first", "drop_cooldown", "dropship_unavailable", "default"]


func _collect_text_problems(text: String, result: PackedStringArray) -> void:
	for fragment in FORBIDDEN_FRAGMENTS:
		if text.contains(fragment):
			result.append("%s [%s]" % [text, fragment])
			return
	for pattern in FORBIDDEN_WORD_PATTERNS:
		var regex := RegEx.new()
		regex.compile(pattern)
		if regex.search(text) != null:
			result.append("%s [%s]" % [text, pattern])
			return
	if text.contains("{quality}") or text.contains("{skill_tier}"):
		result.append("%s [Platzhalter]" % text)


func _check_mission(window_size: Vector2i) -> void:
	var prefix := "%dx%d: " % [window_size.x, window_size.y]
	root.size = window_size
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	for _frame in range(14):
		await process_frame
	var controller: Node = mission.get_node("TacticalController")
	var primary_view: Node = mission.get_node("Primary3DView")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	controller.call("create_area_order_for_fireteams_from_world_rect", PackedStringArray(["blue", "gold"]), Vector2(880.0, 880.0), Vector2(1020.0, 1000.0), "take")
	controller.call("_refresh_order_visuals")
	for _frame in range(10):
		await process_frame

	# Ein Befehl an FT1/FT2: Blase an der Karte, lesbarer deutscher Satz.
	var bubbles: Array = Array(controller.call("get_fireteamleader_feedback_bubble_snapshot"))
	_assert(not bubbles.is_empty(), prefix + "Befehl erzeugt eine Truppfuehrer-Blase")
	var per_team: Dictionary = {}
	for bubble_variant in bubbles:
		var bubble: Dictionary = Dictionary(bubble_variant)
		var team: String = String(bubble.get("fireteam_id", ""))
		per_team[team] = int(per_team.get(team, 0)) + 1
		_assert(String(bubble.get("anchor_space", "")) == "hud" and String(bubble.get("hud_anchor_source", "")) == "fireteam_mini_card", prefix + "Blase von %s ist an die Fireteam-Karte gebunden" % team)
		var duration: float = float(bubble.get("duration_seconds", 0.0))
		_assert(duration >= 2.0 and duration <= 4.0, prefix + "Blase von %s steht 2 bis 4 Sekunden (%.2f)" % [team, duration])
		var text: String = String(bubble.get("text", ""))
		var problems: PackedStringArray = PackedStringArray()
		_collect_text_problems(text, problems)
		_assert(problems.is_empty() and not text.strip_edges().is_empty(), prefix + "Satz '%s' ist verstaendlich deutsch" % text)
		_assert(String(bubble.get("text_source", "")) in ["tactical_communication_copy", "command_validation"], prefix + "Satzquelle ist die Satzdatei (%s)" % String(bubble.get("text_source", "")))
	for team in per_team.keys():
		_assert(int(per_team[team]) == 1, prefix + "%s hat hoechstens eine Blase" % team)

	# Lage im Bild: rechts neben der Karte, ueberdeckt nichts, nichts ueber der Figur.
	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var entries: Array = Array(render_snapshot.get("feedback_bubble_entries", []))
	_assert(not entries.is_empty(), prefix + "Die Blase wird im HUD gezeichnet")
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(window_size))
	var cards: Dictionary = _collect_cards(mission)
	var avoid_rects: Array = []
	for path in AVOID_PATHS:
		var control := mission.get_node_or_null(path) as Control
		if control != null and control.is_visible_in_tree() and control.get_global_rect().size.x > 0.0:
			avoid_rects.append([path, control.get_global_rect()])
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		_assert(String(entry.get("anchor_space", "")) == "hud", prefix + "Eintrag %s ist HUD-verankert, nicht an der Figur" % String(entry.get("fireteam_id", "")))
		var team_id: String = String(entry.get("fireteam_id", ""))
		var rect := Rect2(Vector2(entry.get("hud_bubble_position", Vector2.ZERO)), Vector2(entry.get("hud_bubble_size", Vector2.ZERO)))
		_assert(viewport_rect.encloses(rect), prefix + "Blase %s liegt ganz im Bild (%s)" % [team_id, str(rect)])
		_assert(rect.size.x <= 160.0 and rect.size.y <= 80.0, prefix + "Blase %s ist kompakt (%s)" % [team_id, str(rect.size)])
		if cards.has(team_id):
			var own_card: Rect2 = cards[team_id]
			_assert(rect.position.x >= own_card.end.x, prefix + "Blase %s sitzt rechts neben ihrer Karte (x %.0f >= %.0f)" % [team_id, rect.position.x, own_card.end.x])
			var center_y: float = rect.position.y + rect.size.y * 0.5
			_assert(center_y >= own_card.position.y - 8.0 and center_y <= own_card.end.y + 8.0, prefix + "Blase %s steht auf Hoehe ihrer Karte" % team_id)
		for card_team in cards.keys():
			_assert(not rect.intersects(cards[card_team]), prefix + "Blase %s ueberdeckt nicht die Karte %s" % [team_id, card_team])
		for avoid in avoid_rects:
			_assert(not rect.intersects(Rect2(avoid[1])), prefix + "Blase %s ueberdeckt nicht %s" % [team_id, avoid[0]])
		_assert(bool(entry.get("hud_avoid_clear", false)), prefix + "Blase %s meldet freie Lage" % team_id)

	# Je Trupp eine Blase: Kontakt (wichtig) wird von einer Bestaetigung nicht verdraengt.
	controller.call("record_tactical_communication_event", "contact_report", {"fireteam_id": "blue", "direction_label": "Nordost", "communication_clarity": 0.9, "event_id": "verifier_contact_blue"}, {"cooldown_msec": 0, "now_msec": Time.get_ticks_msec()})
	var leader = controller.call("_resolve_fireteam_leader_for_behavior", "blue")
	controller.call("record_fireteamleader_feedback_bubble_for_unit", "move", "accepted", leader, "blue", "accepted")
	var after: Array = Array(controller.call("get_fireteamleader_feedback_bubble_snapshot"))
	var blue_texts: PackedStringArray = PackedStringArray()
	for bubble_variant in after:
		if String(Dictionary(bubble_variant).get("fireteam_id", "")) == "blue":
			blue_texts.append(String(Dictionary(bubble_variant).get("text", "")))
	_assert(blue_texts.size() == 1, prefix + "BLUE hat nach Kontakt und Bestaetigung genau eine Blase (%d)" % blue_texts.size())
	_assert(blue_texts.size() == 1 and blue_texts[0].begins_with("Kontakt Nordost") or blue_texts.size() == 1 and blue_texts[0].begins_with("Feindkontakt"), prefix + "Die wichtige Kontaktmeldung bleibt stehen ('%s')" % ", ".join(blue_texts))

	# Eine Blase im Weltraum (ueber der Figur) wird nicht mehr gezeichnet.
	var world_bubble: Dictionary = Dictionary(after[0]).duplicate(true) if not after.is_empty() else {}
	world_bubble["anchor_space"] = "world"
	world_bubble.erase("hud_anchor_position")
	world_bubble["anchor_position"] = Vector2(900.0, 900.0)
	primary_view.call("set_order_visual_payload", {"phase_index": 1, "feedback_bubble_dicts": [world_bubble]})
	for _frame in range(6):
		await process_frame
	var world_entries: Array = Array(Dictionary(primary_view.call("get_render_snapshot")).get("feedback_bubble_entries", []))
	_assert(world_entries.is_empty(), prefix + "Keine Truppfuehrer-Blase ueber der Figur auf der Karte (%d)" % world_entries.size())

	mission.queue_free()
	await process_frame


func _collect_cards(mission: Node) -> Dictionary:
	var result: Dictionary = {}
	var host := mission.get_node_or_null(MINI_CARDS_PATH) as VBoxContainer
	if host == null:
		return result
	for child in host.get_children():
		var card := child as Control
		if card == null or not card.is_visible_in_tree():
			continue
		var team_id: String = String(card.get_meta("fireteam_id", "")).strip_edges().to_lower()
		if not team_id.is_empty():
			result[team_id] = card.get_global_rect()
	return result


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	print("FAIL: %s" % message)
