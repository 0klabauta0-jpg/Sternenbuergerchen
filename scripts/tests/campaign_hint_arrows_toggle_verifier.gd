extends SceneTree
## Steuerung der Hinweispfeile: Auswahl, Ziel-Suche, Schalter ueber die Kontext-Hilfe.
## Einstellungen werden nur in eine eigene Testdatei unter user:// geschrieben (umgeleitetes Profil),
## nie in die echte Einstellungsdatei.

const PRESENTER_PATH: String = "res://scripts/meta/campaign_tutorial_presenter.gd"
const SETTINGS: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const TEST_CFG: String = "user://campaign_hint_arrows_toggle_settings.cfg"

class RuntimeProbe:
	extends Node
	var snapshot: Dictionary = {"mode": "campaign", "onboarding": {"stage_index": 0, "next_step_id": "base_ready", "facts": {"ready": true}, "completed": false}}
	func get_snapshot() -> Dictionary:
		return snapshot.duplicate(true)

class FlowProbe:
	extends Node
	var _current_meta_view: String = "homebase"
	var _active_mission: Node = null

class OperationsProbe:
	extends Control
	func get_launch_action_rects() -> Array[Rect2]:
		return []

class HomebaseProbe:
	extends Control
	var _operations_mode: String = "base"
	var _operations_presenter: Control = OperationsProbe.new()

var _passed: int = 0
var _failed: int = 0
var _homebase: Control = null


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("FAIL " + message)


func _hint(id: String, order: int, target: String, show_when: Array, done_when: Array) -> Dictionary:
	return {"id": id, "text": "Hier " + id, "target": {"node": target}, "show_when": show_when, "done_when": done_when, "order": order}


func _make_button(button_name: String, rect: Rect2) -> Button:
	var button: Button = Button.new()
	button.name = button_name
	_homebase.add_child(button)
	button.position = rect.position
	button.size = rect.size
	return button


func _set_mode(mode: String) -> void:
	_check(SETTINGS.save_settings({"contextual_help_mode": mode}, TEST_CFG) == OK, "Testeinstellung speichern: " + mode)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_set_mode("compact")
	var runtime: RuntimeProbe = RuntimeProbe.new()
	root.add_child(runtime)
	var flow: FlowProbe = FlowProbe.new()
	root.add_child(flow)
	_homebase = HomebaseProbe.new()
	_homebase.name = "HomebaseScreen"
	flow.add_child(_homebase)
	_homebase.size = Vector2(1280.0, 720.0)
	var target_rect: Rect2 = Rect2(300.0, 200.0, 140.0, 44.0)
	var button: Button = _make_button("TargetButton", target_rect)
	var other: Button = _make_button("OtherButton", Rect2(800.0, 400.0, 120.0, 40.0))

	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "CampaignTutorialLayer"
	root.add_child(layer)
	var presenter: Control = load(PRESENTER_PATH).new()
	layer.add_child(presenter)
	presenter.call("configure", runtime, flow)
	var arrow: Control = presenter.call("get_hint_arrow")
	var arrows: RefCounted = presenter.call("get_hint_arrows")
	arrow.set("pulse_enabled", false)
	arrows.set("settings_path", TEST_CFG)
	arrows.set("poll_interval_msec", 0)
	await process_frame

	# Leere Liste: nichts geschieht.
	arrows.call("configure", [])
	presenter.call("refresh")
	_check(not arrow.call("is_showing"), "Leere Liste: kein Pfeil")
	_check(String(arrows.call("get_active_hint_id")) == "", "Leere Liste: keine aktive Kennung")
	# Die ausgelieferte Datenliste ist leer.
	var shipped: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign_hint_arrows.json"))
	_check(shipped is Dictionary and Array((shipped as Dictionary).get("hints", [1])).is_empty(), "Datei data/campaign_hint_arrows.json hat leere Liste")

	# Aufbau: Pfeil ist Geschwister, nicht Kind der Karte.
	_check(arrow.get_parent() == presenter.get_parent(), "Pfeil ist Geschwister der Karte")
	_check(not presenter.is_ancestor_of(arrow), "Pfeil ist nicht Kind der Karte")

	var hint_a: Dictionary = _hint("a", 10, "TargetButton", ["stage:0", "view:base", "fact:ready"], ["fact:a_done"])
	arrows.call("configure", [hint_a])
	presenter.call("refresh")
	_check(bool(arrow.call("is_showing")), "Modus compact: Pfeil sichtbar")
	_check(String(arrows.call("get_active_hint_id")) == "a", "Aktive Kennung a")
	_check(arrow.visible, "Pfeilknoten sichtbar")
	var shown: Rect2 = arrow.call("get_arrow_rect")
	_check(not shown.intersects(button.get_global_rect()), "Pfeil verdeckt das Ziel nicht")

	# Modus off (Aenderung im laufenden Spiel ueber die Einstellungsdatei).
	_set_mode("off")
	presenter.call("refresh")
	_check(not bool(arrow.call("is_showing")), "Modus off: Pfeil unsichtbar")
	_check(not arrow.visible, "Modus off: Knoten unsichtbar")
	_set_mode("expanded")
	presenter.call("refresh")
	_check(bool(arrow.call("is_showing")), "Modus expanded: Pfeil wieder sichtbar")
	_set_mode("compact")

	# "Hinweise aus" und "?".
	presenter.call("hide_hints")
	presenter.call("refresh")
	_check(not bool(arrow.call("is_showing")), "Hinweise aus: Pfeil unsichtbar")
	presenter.call("reopen_help")
	presenter.call("refresh")
	_check(bool(arrow.call("is_showing")), "Fragezeichen: Pfeil wieder sichtbar")
	_set_mode("off")
	presenter.call("hide_hints")
	presenter.call("reopen_help")
	presenter.call("refresh")
	_check(not bool(arrow.call("is_showing")), "Fragezeichen bei Modus off: Pfeil bleibt aus")
	_set_mode("compact")
	presenter.call("refresh")
	_check(bool(arrow.call("is_showing")), "Zurueck auf compact: Pfeil sichtbar")

	# Ziel unsichtbar / Ziel neu gebaut.
	button.visible = false
	presenter.call("refresh")
	_check(not bool(arrow.call("is_showing")), "Ziel unsichtbar: kein Pfeil")
	button.visible = true
	presenter.call("refresh")
	_check(bool(arrow.call("is_showing")), "Ziel wieder sichtbar: Pfeil")
	var old_rect: Rect2 = arrow.call("get_arrow_rect")
	button.free()
	presenter.call("refresh")
	_check(not bool(arrow.call("is_showing")), "Ziel gelöscht: kein Pfeil")
	var new_target: Rect2 = Rect2(700.0, 350.0, 140.0, 44.0)
	button = _make_button("TargetButton", new_target)
	presenter.call("refresh")
	var new_rect: Rect2 = arrow.call("get_arrow_rect")
	_check(bool(arrow.call("is_showing")), "Ziel neu gebaut: Pfeil zeigt wieder")
	_check(new_rect != old_rect and not new_rect.intersects(new_target), "Pfeil folgt dem neuen Knoten")
	var tip: Vector2 = Dictionary(arrow.call("get_layout_snapshot")).get("tip", Vector2.ZERO)
	_check(new_target.grow(8.0).has_point(tip), "Pfeilspitze liegt am neuen Ziel: " + str(tip))
	# Das Ziel bewegt sich (Seitenfenster faehrt ein): Rechteck wird neu gelesen.
	button.position = Vector2(500.0, 100.0)
	presenter.call("refresh")
	var moved_tip: Vector2 = Dictionary(arrow.call("get_layout_snapshot")).get("tip", Vector2.ZERO)
	_check(moved_tip != tip, "Bewegtes Ziel: Pfeil wandert mit")
	button.position = new_target.position

	# Zwei passende Hinweise: kleinere Reihenfolge gewinnt; dann done_when.
	var hint_b: Dictionary = _hint("b", 5, "OtherButton", ["stage:0"], ["fact:b_done"])
	arrows.call("configure", [hint_a, hint_b])
	presenter.call("refresh")
	_check(String(arrows.call("get_active_hint_id")) == "b", "Zwei Hinweise: kleinere order gewinnt")
	runtime.snapshot["onboarding"]["facts"]["b_done"] = true
	presenter.call("refresh")
	_check(String(arrows.call("get_active_hint_id")) == "a", "done_when gilt: der naechste Hinweis")
	runtime.snapshot["onboarding"]["facts"]["a_done"] = true
	presenter.call("refresh")
	_check(String(arrows.call("get_active_hint_id")) == "" and not bool(arrow.call("is_showing")), "Alle erledigt: kein Pfeil")
	runtime.snapshot["onboarding"]["facts"].erase("a_done")
	runtime.snapshot["onboarding"]["facts"].erase("b_done")

	# Bedingungen.
	arrows.call("configure", [_hint("c", 1, "TargetButton", ["stage:1"], [])])
	presenter.call("refresh")
	_check(not bool(arrow.call("is_showing")), "stage:1 bei Stufe 0: kein Pfeil")
	runtime.snapshot["onboarding"]["stage_index"] = 1
	presenter.call("refresh")
	_check(bool(arrow.call("is_showing")), "stage:1 bei Stufe 1: Pfeil")
	runtime.snapshot["onboarding"]["stage_index"] = 0
	arrows.call("configure", [_hint("d", 1, "TargetButton", ["fact:gibt_es_nicht"], [])])
	presenter.call("refresh")
	_check(not bool(arrow.call("is_showing")), "fact: fehlender Schluessel ist falsch")
	arrows.call("configure", [_hint("e", 1, "TargetButton", ["unbekannt:1"], [])])
	presenter.call("refresh")
	_check(not bool(arrow.call("is_showing")), "Unbekanntes Wort ist falsch")
	arrows.call("configure", [_hint("f", 1, "TargetButton", ["view:squad"], [])])
	presenter.call("refresh")
	_check(not bool(arrow.call("is_showing")), "view:squad in Ansicht base: kein Pfeil")
	_homebase.set("_operations_mode", "squad")
	presenter.call("refresh")
	_check(bool(arrow.call("is_showing")), "view:squad in Ansicht squad: Pfeil")
	_homebase.set("_operations_mode", "base")

	# Pfeil lebt weiter, wenn die Karte sich ausblendet (Tank- und Auftragsfenster).
	arrows.call("configure", [_hint("g", 10, "TargetButton", ["stage:0", "fact:ready"], [])])
	_homebase.set("_operations_mode", "services")
	presenter.call("refresh")
	_check(not presenter.visible, "Karte blendet sich im Servicefenster aus")
	_check(bool(arrow.call("is_showing")), "Pfeil bleibt trotz ausgeblendeter Karte")
	_homebase.set("_operations_mode", "base")
	presenter.call("refresh")

	# Kein Pfeil ausserhalb der Kampagne.
	runtime.snapshot["mode"] = "skirmish"
	presenter.call("refresh")
	_check(not bool(arrow.call("is_showing")), "Skirmish: kein Pfeil")
	runtime.snapshot["mode"] = "campaign"

	# Aufraeumen.
	_check(other != null, "Testaufbau vollstaendig")
	var absolute: String = ProjectSettings.globalize_path(TEST_CFG)
	if FileAccess.file_exists(TEST_CFG):
		DirAccess.remove_absolute(absolute)
	presenter.free()
	layer.free()
	flow.free()
	runtime.free()
	print("CAMPAIGN_HINT_ARROWS_TOGGLE passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
