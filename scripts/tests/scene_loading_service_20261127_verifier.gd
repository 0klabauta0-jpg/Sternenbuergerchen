extends SceneTree
## Paket Z (27.11.2026): zentraler Ladedienst SceneLoadingService.
## Geprueft: Dienst vorhanden; Wechsel mit force_threaded auf eine kleine Szene; Fortschritt steigt bis 100; ERR_BUSY bei Doppelaufruf;
## Rueckfall bei falschem Pfad; kein Ladebildschirm bei Laden unter 0,3 s; kopflos ohne force_threaded der alte direkte Weg; Tipp-Auswahl.
const TARGET_PATH: String = "user://scene_loading_service_20261127_target.tscn"
const TARGET_NAME: String = "SceneLoadingVerifierTarget"
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


func _wait_until_idle(service: Node, progress_samples: Array, overlay_flags: Array) -> bool:
	for i in range(MAX_WAIT_FRAMES):
		await process_frame
		progress_samples.append(float(service.call("get_progress_percent")))
		overlay_flags.append(bool(service.call("is_overlay_visible")))
		if not bool(service.call("is_loading")):
			return true
	return false


func _run() -> void:
	var service: Node = root.get_node_or_null("SceneLoadingService")
	_check(service != null, "Autoload SceneLoadingService vorhanden")
	if service == null:
		print("scene_loading_service_20261127_verifier: PASS %d / FAIL %d" % [passed, failed])
		quit(1)
		return
	for method_name in ["change_scene", "is_loading"]:
		_check(service.has_method(method_name), "Dienst hat " + method_name)
	_check(service.has_signal("loading_finished"), "Dienst hat Signal loading_finished")
	_check(not bool(service.call("is_loading")), "Zu Beginn laedt der Dienst nichts")
	service.connect("loading_finished", _on_finished)

	# Kleine Zielszene bauen.
	var target := Node.new()
	target.name = TARGET_NAME
	var packed := PackedScene.new()
	_check(packed.pack(target) == OK, "Zielszene gepackt")
	_check(ResourceSaver.save(packed, TARGET_PATH) == OK, "Zielszene gespeichert")
	target.free()

	# 1) Hintergrundladen erzwungen: kleine Szene.
	var samples: Array = []
	var overlay_flags: Array = []
	var started_msec: int = Time.get_ticks_msec()
	var err: int = int(service.call("change_scene", TARGET_PATH, {"force_threaded": true, "tip_context": "main_menu"}))
	_check(err == OK, "change_scene (force_threaded) liefert OK (war %d)" % err)
	_check(bool(service.call("is_loading")), "Waehrend des Ladens is_loading() == true")
	var busy: int = int(service.call("change_scene", TARGET_PATH, {"force_threaded": true}))
	_check(busy == ERR_BUSY, "Doppelaufruf waehrend des Ladens liefert ERR_BUSY (war %d)" % busy)
	var idle: bool = await _wait_until_idle(service, samples, overlay_flags)
	var elapsed: int = Time.get_ticks_msec() - started_msec
	_check(idle, "Laden endet innerhalb von %d Bildern" % MAX_WAIT_FRAMES)
	_check(_finished_calls.size() == 1 and String(_finished_calls[0][0]) == TARGET_PATH and int(_finished_calls[0][1]) == OK, "loading_finished genau einmal mit OK (%s)" % str(_finished_calls))
	var monotonic := true
	for i in range(1, samples.size()):
		if float(samples[i]) < float(samples[i - 1]) and not (i == samples.size() - 1):
			monotonic = false
	_check(monotonic, "Fortschritt faellt nie (Proben %s)" % str(samples))
	_check(not samples.is_empty() and float(samples.max()) >= 100.0, "Fortschritt erreicht 100 (Maximum %s)" % str(samples.max() if not samples.is_empty() else "keine"))
	print("INFO Ladezeit der kleinen Szene: %d ms" % elapsed)
	if elapsed < 300:
		_check(not overlay_flags.has(true), "Kein Ladebildschirm bei Laden unter 0,3 s")
	else:
		print("INFO Laden dauerte %d ms (>= 300): Ladebildschirmpruefung uebersprungen" % elapsed)
	_check(not bool(service.call("is_overlay_visible")), "Nach dem Laden ist der Ladebildschirm weg")
	await process_frame
	_check(current_scene != null and current_scene.name == TARGET_NAME, "Zielszene ist die aktuelle Szene (%s)" % (current_scene.name if current_scene != null else "keine"))

	# 2) Falscher Pfad: Rueckfall auf den alten Weg, Fehler, kein haengender Ladevorgang.
	_finished_calls.clear()
	var bad: int = int(service.call("change_scene", "res://nicht_vorhanden/keine_szene_20261127.tscn", {"force_threaded": true}))
	_check(bad != OK, "Falscher Pfad liefert einen Fehler (war %d)" % bad)
	_check(not bool(service.call("is_loading")), "Nach falschem Pfad laedt der Dienst nichts")
	_check(_finished_calls.size() == 1 and int(_finished_calls[0][1]) != OK, "loading_finished meldet den Fehler")
	var after_bad: int = int(service.call("change_scene", TARGET_PATH, {"force_threaded": true}))
	_check(after_bad == OK, "Nach dem Fehler ist der Dienst wieder frei (war %d)" % after_bad)
	await _wait_until_idle(service, [], [])

	# 3) Kopflos ohne force_threaded: alter direkter Weg.
	if DisplayServer.get_name() == "headless":
		_finished_calls.clear()
		var direct: int = int(service.call("change_scene", TARGET_PATH, {}))
		_check(direct == OK and not bool(service.call("is_loading")), "Kopflos ohne force_threaded: direkter Wechsel, kein Hintergrundladen")
		await process_frame
		await process_frame
		_check(current_scene != null and current_scene.name == TARGET_NAME, "Direkter Wechsel hat die Zielszene geladen")
	else:
		print("INFO nicht kopflos: Pruefung des direkten Weges uebersprungen")

	# 4) Tipp aus dem Hilfekatalog bzw. fester Liste.
	var tip: String = String(service.call("_pick_tip", "main_menu"))
	_check(tip.begins_with("Tipp: ") and tip.length() > 10, "Tipp vorhanden: " + tip)
	var tip_any: String = String(service.call("_pick_tip", ""))
	_check(tip_any.begins_with("Tipp: ") and tip_any.length() > 10, "Zufallstipp ohne Zusammenhang vorhanden")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(TARGET_PATH))
	print("scene_loading_service_20261127_verifier: PASS %d / FAIL %d" % [passed, failed])
	quit(1 if failed > 0 else 0)
