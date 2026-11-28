extends SceneTree
## Paket RL (28.11.2026), Punkt 1/3/5/6: Ladedienst in der Nachlaufphase.
## Geprueft: (A) Anfrage in der Nachlaufphase wird angenommen (nicht ERR_BUSY) und die zweite Szene wird die aktuelle;
## waehrend des Hintergrundladens bleibt es bei ERR_BUSY; der Baum ist waehrenddessen angehalten und danach wieder frei;
## Esc/Schnellspeichern-Sperre meldet "laedt"; Titel und Tipp je Ziel.
## (B) Scheitert "Fortsetzen" (kein Stand), landet der Spieler im Hauptmenue MIT Meldung statt in einer leeren Basis.
const TARGET_A: String = "user://scene_loading_busy_20261128_a.tscn"
const TARGET_B: String = "user://scene_loading_busy_20261128_b.tscn"
const FLOW_SCENE: String = "res://scenes/meta/meta_layer_test.tscn"
const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const MAX_WAIT_FRAMES: int = 900
var passed := 0
var failed := 0
var _finished_calls: Array = []


func _init() -> void:
	call_deferred("_run")


func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
	print(("PASS " if value else "FAIL ") + label)


func _on_finished(path: String, error: int) -> void:
	_finished_calls.append([path, error])


func _make_target(path: String, node_name: String) -> bool:
	var node := Node.new()
	node.name = node_name
	var packed := PackedScene.new()
	var ok: bool = packed.pack(node) == OK and ResourceSaver.save(packed, path) == OK
	node.free()
	return ok


func _wait_idle(service: Node) -> bool:
	for i in range(MAX_WAIT_FRAMES):
		await process_frame
		if not bool(service.call("is_loading")):
			return true
	return false


func _finish() -> void:
	print("scene_loading_busy_20261128_verifier: passed=%d FAIL=%d RESULTS" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _run() -> void:
	var service: Node = root.get_node_or_null("SceneLoadingService")
	_check(service != null, "Autoload SceneLoadingService vorhanden")
	if service == null:
		_finish()
		return
	service.connect("loading_finished", _on_finished)
	_check(_make_target(TARGET_A, "BusyTargetA") and _make_target(TARGET_B, "BusyTargetB"), "Zielszenen gespeichert")

	# 1) Waehrend des Hintergrundladens: ERR_BUSY, Baum angehalten, Esc-Sperre meldet "laedt".
	var first: int = int(service.call("change_scene", TARGET_A, {"force_threaded": true, "tip_context": "gefecht"}))
	_check(first == OK, "Erste Anfrage angenommen (war %d)" % first)
	_check(paused, "Waehrend des Ladens ist der Baum angehalten (alte Szene steht)")
	var busy: int = int(service.call("change_scene", TARGET_B, {"force_threaded": true}))
	_check(busy == ERR_BUSY, "Zweite Anfrage waehrend des Hintergrundladens: ERR_BUSY (war %d)" % busy)
	var escape: Node = root.get_node_or_null("GlobalEscapeMenu")
	if escape != null and escape.has_method("_is_scene_loading"):
		_check(bool(escape.call("_is_scene_loading")), "Esc/F5-Sperre meldet: Szenenwechsel laeuft")
	else:
		print("INFO GlobalEscapeMenu nicht vorhanden: Sperrpruefung uebersprungen")

	# 2) Nachlaufphase: Anfrage wird angenommen und ausgefuehrt.
	var in_after: bool = false
	for i in range(MAX_WAIT_FRAMES):
		await process_frame
		if String(service.get("_phase")) == "after":
			in_after = true
			break
		if not bool(service.call("is_loading")):
			break
	_check(in_after, "Nachlaufphase wurde erreicht")
	_check(not paused, "Nach dem Umschalten ist der Baum nicht mehr angehalten")
	_finished_calls.clear()
	var late: int = int(service.call("change_scene", TARGET_B, {"force_threaded": true, "tip_context": "main_menu"}))
	_check(late == OK, "Anfrage in der Nachlaufphase angenommen (war %d)" % late)
	_check(await _wait_idle(service), "Danach endet das Laden")
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene.name == "BusyTargetB", "Zweite Szene ist aktuell (%s)" % (current_scene.name if current_scene != null else "keine"))
	_check(_finished_calls.size() == 2 and int(_finished_calls[0][1]) == OK and int(_finished_calls[1][1]) == OK, "loading_finished fuer beide Wechsel mit OK (%s)" % str(_finished_calls))
	_check(not paused, "Am Ende ist der Baum nicht angehalten")

	# 3) Titel und Tipps je Ziel.
	var titles := {"kampagne": "Kampagne wird geladen", "gefecht": "Gefecht wird vorbereitet", "frei": "Freies Spiel wird vorbereitet", "main_menu": "Hauptmenü wird geladen"}
	for key: String in titles.keys():
		var text: String = String(service.call("_title_for", {"tip_context": key}))
		_check(text == String(titles[key]), "Titel fuer %s: %s" % [key, text])
	_check(String(service.call("_title_for", {"tip_context": "x", "title_text": "Eigener Titel"})) == "Eigener Titel", "title_text gewinnt")
	var tip: String = String(service.call("_pick_tip", "gefecht"))
	_check(tip.begins_with("Tipp: ") and tip.length() > 10, "Tipp fuer Gefecht: " + tip)

	# 4) Fortsetzen scheitert (kein Stand im Wegwerf-Profil): sichtbar im Hauptmenue mit Meldung.
	var contract: GDScript = load("res://scripts/meta/game_start_contract.gd")
	_check(bool(contract.request_start(self, "campaign", "continue").get("ok", false)), "Fortsetzen-Anfrage gestellt")
	_finished_calls.clear()
	var flow_err: int = int(service.call("change_scene", FLOW_SCENE, {"force_threaded": true, "tip_context": "kampagne"}))
	_check(flow_err == OK, "Wechsel in die Kampagnenszene gestartet (war %d)" % flow_err)
	var reached_menu: bool = false
	for i in range(MAX_WAIT_FRAMES):
		await process_frame
		if current_scene != null and String(current_scene.scene_file_path) == MAIN_MENU_SCENE:
			reached_menu = true
			break
	_check(reached_menu, "Nach gescheitertem Fortsetzen ist das Hauptmenue die aktuelle Szene")
	if reached_menu:
		await process_frame
		await process_frame
		var status: Label = current_scene.get("_status_label") as Label
		var message: String = status.text if status != null else ""
		_check(message.contains("Kampagnenstand"), "Hauptmenue zeigt die Fehlermeldung: " + message)
		_check(not root.has_meta("campaign_start_error"), "Fehlermeldung wurde vom Hauptmenue abgeholt")
	_check(not bool(service.call("is_loading")), "Der Dienst haengt nicht")
	_check(not paused, "Der Baum ist nicht angehalten")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TARGET_A))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TARGET_B))
	_finish()
