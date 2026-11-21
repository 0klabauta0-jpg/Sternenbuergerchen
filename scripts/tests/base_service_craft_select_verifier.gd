extends SceneTree
## Tankfenster der Basis (Navigationsknopf "Tankservice"): Das Serviceschiff laesst sich ueber die Auswahl IM Fenster waehlen
## (nicht nur durch Anklicken des Schiffs in der Basiswelt). Danach ist "Auftanken" bedienbar und bucht.
## Abschlusszeile: BASE_SERVICE_CRAFT_SELECT passed=%d failed=%d
## Braucht ein Wegwerfprofil (SB_REVIEW2_USER_DIR), sonst Abbruch ohne Schreiben.

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const START = preload("res://scripts/meta/game_start_contract.gd")
const FLOW: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var verdict: Dictionary = GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("BASE_SERVICE_CRAFT_SELECT refused: needs a throwaway profile (SB_REVIEW2_USER_DIR). Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	root.size = Vector2i(1920, 1080)
	START.request_start(self, "campaign", "new")
	var flow: Node = FLOW.instantiate()
	root.add_child(flow)
	for i in 12:
		await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	var adapter: Node = flow.get("_singleplayer_runtime")
	var craft := String(flow.get_meta("singleplayer_bootstrap_craft_id"))
	screen.find_child("OpenBaseServices", true, false).pressed.emit()
	for i in 40:
		await process_frame
	var services: Node = screen.find_child("BaseServices", true, false)
	var chooser := services.find_child("ServiceCraftSelector", true, false) as OptionButton
	var refuel := services.find_child("RefuelCraft", true, false) as Button
	_check(chooser != null and refuel != null, "Tankfenster hat Schiffswahl und Auftanken-Knopf")
	_check(chooser.selected == 0 and refuel.disabled, "Anfangs ist kein Serviceschiff gewaehlt und Auftanken gesperrt")
	var fuel_before: float = float(adapter.call("get_snapshot").supply.fuel_by_craft_id[craft])
	chooser.select(1)
	chooser.item_selected.emit(1)
	for i in 30:
		await process_frame
	_check(String(adapter.call("get_snapshot").location_view.get("craft_id", "")) == craft, "Die Wahl im Fenster setzt das Serviceschiff der Ansicht: " + str(adapter.call("get_snapshot").location_view))
	_check(chooser.selected == 1, "Die Auswahl bleibt auf dem Schiff stehen")
	_check(not refuel.disabled, "Auftanken ist nach der Wahl bedienbar: " + refuel.tooltip_text)
	refuel.pressed.emit()
	for i in 30:
		await process_frame
	var fuel_after: float = float(adapter.call("get_snapshot").supply.fuel_by_craft_id[craft])
	_check(fuel_after > fuel_before, "Tanken bucht (%s -> %s)" % [str(fuel_before), str(fuel_after)])
	flow.queue_free()
	await process_frame
	print("BASE_SERVICE_CRAFT_SELECT passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)


func _check(value: bool, label: String) -> bool:
	if value:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		printerr("FAIL: ", label)
	return value
