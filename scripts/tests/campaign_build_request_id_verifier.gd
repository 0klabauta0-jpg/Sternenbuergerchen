extends SceneTree
## Kaufkennung der Baumenue-Knoepfe (singleplayer_services_presenter.gd): je Programmlauf eindeutig.
## Zwei Presenter (= zwei Programmlaeufe) mit gleichem Zaehler erzeugen verschiedene Ids; ein Kauf nach einem
## "Neustart" mit geladenem Beleg wird wirklich gebaut und abgebucht (nicht als Wiederholung gemeldet).
const SUPPLY := "res://scripts/core/singleplayer_supply_state.gd"
const PRESENTER := "res://scripts/meta/singleplayer_services_presenter.gd"
var passed := 0
var failed := 0
var built := 0
var seen: Array = []

func check(condition: bool, text: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		print("FAIL: " + text)

func _init() -> void: call_deferred("_run")

func _build(count: int) -> Dictionary:
	built = count
	return {"ok":true,"housing_count":count}

func _record(_operation: String, payload: Dictionary) -> Dictionary:
	seen.append(String(payload.get("request_id", "")))
	return {"ok":true}

func _ctx() -> Dictionary:
	return {"at_home":true,"campaign_authorized":true,"campaign_housing_builder":Callable(self, "_build"),"campaign_housing_container":true,"campaign_housing_limit":4}

func _command(id: String) -> Dictionary:
	return load("res://scripts/mission/singleplayer_supply_command_contract.gd").build_command("campaign_build_housing", {}, id)

func _supply(credits: int):
	var owner = load(SUPPLY).new()
	owner.configure()
	owner._credits = credits
	return owner

## Ein frischer Presenter (= ein Programmlauf, Zaehler bei 0) drueckt den Wohncontainer-Knopf; Rueckgabe: die Request-Id.
func _press() -> Array:
	var presenter: Control = load(PRESENTER).new()
	root.add_child(presenter)
	presenter.call("configure", Callable(), Callable(self, "_record"))
	await process_frame
	var buttons: Dictionary = presenter.get("_campaign_buttons")
	var key := ""
	for candidate in buttons:
		if String(buttons[candidate].operation) == "campaign_build_housing": key = String(candidate)
	check(not key.is_empty(), "Presenter hat den Knopf campaign_build_housing")
	if key.is_empty(): presenter.queue_free(); return ["", presenter.get_instance_id(), ""]
	seen.clear()
	buttons[key].button.disabled = false
	presenter.call("_submit_campaign", key)
	var id: String = seen[0] if seen.size() == 1 else ""
	var result: Array = [id, presenter.get_instance_id(), String(presenter.get("_request_session"))]
	presenter.queue_free()
	await process_frame
	return result

func _run() -> void:
	# Zwei Programmlaeufe: gleicher Zaehler (je 1), Instanz-Id in der Id herausgerechnet -> trotzdem verschiedene Ids.
	var run_a: Array = await _press()
	var run_b: Array = await _press()
	check(not String(run_a[0]).is_empty() and not String(run_b[0]).is_empty(), "beide Laeufe geben eine Request-Id aus")
	check(String(run_a[0]) != String(run_b[0]), "gleicher Zaehler, verschiedene Laeufe: verschiedene Ids (%s | %s)" % [run_a[0], run_b[0]])
	check(not String(run_a[2]).is_empty() and String(run_a[2]) != String(run_b[2]), "Sitzungskennzeichen je Lauf verschieden")
	check(String(run_a[0]) == "campaign-service:%d:%s:1" % [run_a[1], run_a[2]], "Id = campaign-service:<Instanz>:<Sitzung>:<Zaehler> (%s)" % run_a[0])
	var stripped_a: String = String(run_a[0]).replace(str(run_a[1]), "X")
	var stripped_b: String = String(run_b[0]).replace(str(run_b[1]), "X")
	check(stripped_a != stripped_b, "auch bei gleicher Instanz-Id waeren die Ids verschieden")
	# Kauf, Speichern, "Neustart" (neue Versorgung aus dem Stand), zweiter Kauf mit der Id des neuen Laufs.
	var first = _supply(3000)
	var bought: Dictionary = first.apply_command(_command(run_a[0]), _ctx())
	check(bought.get("ok", false) and built == 1 and first.get_supply_snapshot().credits == 2000, "erster Kauf: gebaut, -1000 Credits")
	var restarted = _supply(0)
	check(restarted.restore_state(first.export_state()).get("ok", false) and restarted.get_supply_snapshot().credits == 2000 and restarted.get_campaign_housing_count() == 1, "Neustart: Beleg und Guthaben geladen")
	var second: Dictionary = restarted.apply_command(_command(run_b[0]), _ctx())
	check(second.get("ok", false) and not second.get("replayed", false) and built == 2 and restarted.get_supply_snapshot().credits == 1000 and restarted.get_campaign_housing_count() == 2, "Kauf nach Neustart: wirklich gebaut und abgebucht (Beleg zwei)")
	# Der Fehler der alten Id: gleiche Instanz-Id und gleicher Zaehler -> gespeicherter Beleg, "ok" als Wiederholung, nichts gebaut.
	var old_id := "campaign-service:%d:1" % run_a[1]
	var old_first = _supply(3000)
	built = 0
	old_first.apply_command(_command(old_id), _ctx())
	var old_restarted = _supply(0)
	old_restarted.restore_state(old_first.export_state())
	var old_again: Dictionary = old_restarted.apply_command(_command(old_id), _ctx())
	check(old_again.get("ok", false) and old_again.get("replayed", false) and built == 1 and old_restarted.get_supply_snapshot().credits == 2000, "Dokumentation des alten Fehlers: gleiche Id nach Neustart = Wiederholung, nichts gebaut")
	print("CAMPAIGN_BUILD_REQUEST_ID passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
