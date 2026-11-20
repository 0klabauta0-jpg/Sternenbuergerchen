extends SceneTree
## Auftragstafel: Ein gesperrter Auftrag (Vorgaenger fertig, nur die Vorbedingung am Handelsposten fehlt)
## bleibt sichtbar und zeigt den Grund der Sperre. Annehmen und Anfliegen bleiben gesperrt.
## Echte Kampagnen- und Reise-Besitzer, echte Tafel; die Tafel liest nur und gibt keine Befehle.
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const TRAVEL = preload("res://scripts/core/singleplayer_space_travel_state.gd")
const COMMAND = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const BOARD = preload("res://scripts/meta/singleplayer_job_board_presenter.gd")
const REASON_TEXT := "Zuerst die Person am Handelsposten aufnehmen und die Kiste bergen"
const EMPTY_TEXT := "Zurzeit keine verfügbaren Aufträge"
var passed := 0
var failed := 0
var sequence := 0
var owner: RefCounted

class SnapshotScreen extends Control:
	var snapshot: Dictionary = {}
	var commands: Array = []
	func get_operations_snapshot() -> Dictionary: return {"singleplayer":snapshot}
	func request_operation(operation: String, payload: Dictionary) -> Dictionary:
		commands.append([operation, payload])
		return {"ok":false, "reason":"read_only_fixture"}

func _init() -> void:
	# Reine Speicher-Besitzer, kein Speicherstand: Der Lauf braucht nur das umgeleitete APPDATA.
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)

func _command(operation: String, payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	sequence += 1
	return owner.apply_command(COMMAND.build_command(operation, payload, "board-locked:%d" % sequence), context)

func _finish_job(id: String) -> void:
	var job: Dictionary = owner.get_campaign_snapshot().jobs[id]
	var ok := bool(_command("accept_job", {"job_id":id}).get("ok", false))
	ok = ok and bool(_command("bind_departure", {"craft_id":"ship", "origin_location_id":"homebase", "destination_location_id":job.location_id, "landing_pad_id":"homebase_pad_01", "job_id":id}, {"departure_authorized":true}).get("ok", false))
	ok = ok and bool(_command("activate_job", {"craft_id":"ship", "job_id":id}, {"departure_authorized":true}).get("ok", false))
	ok = ok and bool(_command("complete_job", {"craft_id":"ship", "job_id":id}, {"runtime_evidence":{"scenario_id":job.scenario_id, "result":"victory", "mission_scenario_runtime_gates":{"all_gates_complete":true, "completed_step_ids":job.required_step_ids}}}).get("ok", false))
	if bool(job.home_upload): ok = ok and bool(_command("upload_job", {"job_id":id}, {"at_home":true}).get("ok", false))
	_check(ok, "echter Abschluss " + id)

func _projection(travel_owner: RefCounted) -> Dictionary:
	var campaign: Dictionary = owner.get_campaign_snapshot()
	campaign["job_availability"] = owner.get_job_availability(true)
	return {"mode":"campaign", "campaign":campaign, "space_travel":travel_owner.get_snapshot()}

func _listed(board: Control) -> Array:
	return Array(board.get("_card_buttons").keys())

func _run() -> void:
	owner = CAMPAIGN.new()
	var travel_owner := TRAVEL.new()
	_check(owner.configure().get("ok", false) and travel_owner.configure("ship").get("ok", false), "echte Kampagne und Reise konfigurieren")
	var screen := SnapshotScreen.new()
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var board := BOARD.new()
	screen.add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.configure(screen)
	# Anfang: nur der erste Auftrag. Aufträge mit offenem Vorgänger bleiben unsichtbar (Punkt 5).
	screen.snapshot = _projection(travel_owner)
	board.refresh()
	_check(_listed(board) == ["satellite_recovery"], "Anfang: nur der erste Auftrag steht auf der Tafel (beobachtet %s)" % str(_listed(board)))
	var start_avail: Dictionary = owner.get_job_availability(true)
	_check(not bool(start_avail.benit_delivery.visible) and not bool(start_avail.benit_delivery.get("locked", false)), "Anfang: benit_delivery ist unsichtbar und nicht als gesperrt gelistet")
	_finish_job("satellite_recovery")
	screen.snapshot = _projection(travel_owner)
	board.refresh()
	_check(not _listed(board).has("benit_delivery") and not _listed(board).has("outpost_chip_recovery") and not _listed(board).has("buccaneer_rescue"), "nach Auftrag 1: Auftraege mit offenem Vorgaenger bleiben unsichtbar (beobachtet %s)" % str(_listed(board)))
	_check(_listed(board).has("outpost_recovery"), "nach Auftrag 1: Auftrag 2 ist sichtbar")
	_finish_job("outpost_recovery")
	# Auftrag 3: Vorgaenger fertig, aber Person und Kiste fehlen.
	var avail: Dictionary = owner.get_job_availability(true)
	var benit: Dictionary = avail.benit_delivery
	_check(bool(benit.visible) and bool(benit.get("locked", false)) and not bool(benit.can_accept), "benit_delivery ist sichtbar, gesperrt und nicht annehmbar (beobachtet %s)" % str(benit))
	_check(String(benit.reason) == "outpost_preparation_required" and String(benit.message) == REASON_TEXT, "Grund der Sperre bleibt der vorhandene Wortlaut (beobachtet \"%s\")" % String(benit.message))
	_check(not bool(avail.outpost_chip_recovery.visible) and not bool(avail.buccaneer_rescue.visible), "Auftraege 4 und 5 bleiben unsichtbar (Vorgaenger offen)")
	var accept_try: Dictionary = _command("accept_job", {"job_id":"benit_delivery"})
	_check(not bool(accept_try.get("ok", true)) and String(accept_try.get("reason", "")) == "outpost_preparation_required" and String(accept_try.get("message", "")) == REASON_TEXT, "Annehmen bleibt abgelehnt, Antwort unveraendert (beobachtet %s)" % str(accept_try))
	_check(String(owner.get_campaign_snapshot().jobs.benit_delivery.status) == "offered", "benit_delivery bleibt offen, nicht angenommen")
	# Anfliegen: der Ort darf nicht wegen des gesperrten Auftrags freigeschaltet werden.
	var benit_location := String(owner.get_campaign_snapshot().jobs.benit_delivery.location_id)
	var other_open := false
	for id: String in owner.get_campaign_snapshot().jobs:
		if id != "benit_delivery" and String(owner.get_campaign_snapshot().jobs[id].location_id) == benit_location and bool(avail[id].visible):
			other_open = true
	var location_free := bool(owner.get_campaign_snapshot().locations[benit_location].get("free_visit", false))
	_check(bool(owner.validate_location_visit(benit_location, true).get("ok", false)) == (other_open or location_free), "Ort des gesperrten Auftrags wird durch ihn nicht anfliegbar (Ort %s, anderer offener Auftrag dort: %s)" % [benit_location, str(other_open)])
	# Tafel mit allen Auftraegen.
	screen.snapshot = _projection(travel_owner)
	board.refresh()
	var buttons: Dictionary = board.get("_card_buttons")
	_check(buttons.has("benit_delivery"), "Tafel listet den gesperrten Auftrag (beobachtet %s)" % str(_listed(board)))
	_check(buttons.has("benit_delivery") and String(buttons.benit_delivery.text).contains(REASON_TEXT), "Kartenzeile nennt den Grund (beobachtet \"%s\")" % (String(buttons.benit_delivery.text) if buttons.has("benit_delivery") else "-"))
	if buttons.has("benit_delivery"): buttons.benit_delivery.pressed.emit()
	var details: Label = board.get("_details")
	var accept_button: Button = board.get("_accept")
	_check(details.text.contains(REASON_TEXT), "Einzelheiten nennen den Grund (beobachtet \"%s\")" % details.text)
	_check(accept_button.disabled and accept_button.tooltip_text == REASON_TEXT, "Annehmen-Knopf ist deaktiviert und traegt den Grund (disabled=%s, Tooltip \"%s\")" % [str(accept_button.disabled), accept_button.tooltip_text])
	_check(screen.commands.is_empty(), "die Tafel gibt beim Anzeigen keinen Befehl aus")
	# Leertext: Nur der gesperrte Auftrag ist sichtbar -> kein Leertext.
	var only_locked: Dictionary = _projection(travel_owner)
	for id: String in only_locked.campaign.job_availability:
		if id != "benit_delivery":
			only_locked.campaign.job_availability[id]["visible"] = false
	screen.snapshot = only_locked
	board.refresh()
	var empty_label: Label = board.get("_empty")
	_check(not empty_label.visible, "mit nur dem gesperrten Auftrag erscheint der Leertext nicht (Leertext sichtbar=%s)" % str(empty_label.visible))
	_check(_listed(board) == ["benit_delivery"], "mit nur dem gesperrten Auftrag steht genau dieser auf der Tafel (beobachtet %s)" % str(_listed(board)))
	# Ohne jeden sichtbaren Auftrag bleibt der Leertext.
	var none_visible: Dictionary = _projection(travel_owner)
	for id: String in none_visible.campaign.job_availability:
		none_visible.campaign.job_availability[id]["visible"] = false
		none_visible.campaign.job_availability[id]["locked"] = false
	screen.snapshot = none_visible
	board.refresh()
	_check(empty_label.visible and empty_label.text.contains(EMPTY_TEXT), "ohne sichtbare Auftraege bleibt der Leertext")
	# Vorbedingung erfuellt: Person und Kiste -> annehmbar, nicht mehr gesperrt.
	_check(bool(_command("claim_recruit", {"kind":"outpost"}, {"runtime_authorized":true}).get("ok", false)), "echte Person aufgenommen")
	var half: Dictionary = owner.get_job_availability(true).benit_delivery
	_check(bool(half.visible) and bool(half.get("locked", false)) and not bool(half.can_accept), "Person allein: weiter sichtbar und gesperrt")
	_check(bool(_command("load_crate", {}, {"runtime_authorized":true}).get("ok", false)), "echte Kiste geladen")
	var ready: Dictionary = owner.get_job_availability(true).benit_delivery
	_check(bool(ready.visible) and not bool(ready.get("locked", true)) and bool(ready.can_accept), "Person und Kiste: sichtbar, nicht mehr gesperrt, annehmbar")
	screen.snapshot = _projection(travel_owner)
	board.refresh()
	if board.get("_card_buttons").has("benit_delivery"): board.get("_card_buttons").benit_delivery.pressed.emit()
	_check(not accept_button.disabled and not details.text.contains("Gesperrt"), "Tafel: nach der Vorbereitung ist Annehmen frei, kein Sperrtext")
	screen.queue_free()
	await process_frame
	print("SINGLEPLAYER_JOB_BOARD_LOCKED_JOB passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
