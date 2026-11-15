extends SceneTree
## Task 9 Anzeige: Verwundung, Gefallene und Rueckzug in Debrief, Charakterblatt,
## Personenkarte der Heimatbasis und Auftragstafel. Nur Textpruefungen; die Anzeige
## liest Daten und schreibt nichts zurueck.

const DEBRIEF := preload("res://scenes/meta/debrief_test_screen.tscn")
const AUTHORITY := preload("res://scripts/mission/mission_combat_authority_contract.gd")
const RULES := preload("res://scripts/core/campaign_casualty_rules.gd")
const RECOVERY := preload("res://scripts/core/personnel_recovery_runtime.gd")
const FORMATTER := preload("res://scripts/meta/character_sheet_formatter.gd")
const PROFILE := preload("res://scripts/meta/meta_unit_profile.gd")
const BOARD := preload("res://scripts/meta/singleplayer_job_board_presenter.gd")

const RETREAT_HEADING := "Rückzug · Auftrag bleibt offen"
const OLD_ABORT_HEADING := "Einsatz abgebrochen"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_debrief_heading()
	await _check_debrief_people()
	_check_character_sheet()
	await _check_homebase_and_board()
	print("CAMPAIGN_CASUALTY_DISPLAY passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


# ---------------------------------------------------------------- Debrief

func _base_report(result_code: String, condition: String) -> Dictionary:
	return AUTHORITY.build_mission_result(result_code, "", "team_alpha", condition, false, 42.0, [])


func _campaign_report(result_code: String, condition: String) -> Dictionary:
	var report := _base_report(result_code, condition)
	report["casualty_total_loss"] = false
	report["casualties"] = []
	report["fatality_unit_ids"] = PackedStringArray()
	return report


func _open_debrief(report: Dictionary) -> Control:
	var holder := SubViewport.new()
	holder.size = Vector2i(1920, 1080)
	holder.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(holder)
	var screen := DEBRIEF.instantiate() as Control
	screen.visible = true
	holder.add_child(screen)
	screen.call("set_mission_result", report)
	await _frames(6)
	return screen


func _close_debrief(screen: Control) -> void:
	screen.get_parent().queue_free()
	await _frames(2)


func _heading(screen: Control) -> String:
	var label := screen.find_child("OutcomeHeading", true, false) as Label
	return label.text if label != null else "<fehlt>"


func _check_debrief_heading() -> void:
	var cases := [
		["Kampagne, aborted + evacuation", _campaign_report("aborted", "evacuation"), RETREAT_HEADING],
		["Kampagne, aborted + departure", _campaign_report("aborted", "departure"), RETREAT_HEADING],
		["Skirmish, aborted + evacuation (kein Kampagnenmerkmal)", _base_report("aborted", "evacuation"), OLD_ABORT_HEADING],
		["Skirmish, aborted + departure", _base_report("aborted", "departure"), OLD_ABORT_HEADING],
		["Kampagne, aborted + anderes Auftragsziel", _campaign_report("aborted", "objective_capture"), OLD_ABORT_HEADING],
		["Kampagne, victory", _campaign_report("victory", "objective_capture"), "Einsatz abgeschlossen"],
		["Kampagne, defeat + evacuation", _campaign_report("defeat", "evacuation"), "Einsatz abgeschlossen"],
	]
	for entry in cases:
		var report: Dictionary = entry[1]
		var original := report.duplicate(true)
		var screen := await _open_debrief(report)
		_check(_heading(screen) == String(entry[2]), "Debrief-Überschrift: %s -> '%s' (ist '%s')" % [entry[0], entry[2], _heading(screen)])
		_check(Dictionary(screen.call("get_mission_result")) == original and report == original, "Debrief liest nur: Ergebnis unverändert (%s)" % entry[0])
		await _close_debrief(screen)
	# Totalverlust behaelt die heutige Anzeige, auch wenn die Kennungen nach Rueckzug aussehen.
	var total_loss := _campaign_report("aborted", "evacuation")
	total_loss["casualty_total_loss"] = true
	total_loss["total_loss_reason"] = "pilot_down"
	total_loss["campaign_checkpoint_retry_required"] = true
	var screen := await _open_debrief(total_loss)
	_check(_heading(screen) == OLD_ABORT_HEADING, "Totalverlust zeigt nie die Rückzug-Überschrift")
	var button := screen.find_child("ReturnToHomebaseButton", true, false) as Button
	_check(button != null and button.text == "Letzten sicheren Checkpoint fortsetzen", "Totalverlust: Checkpoint-Rücksprung wie bisher")
	await _close_debrief(screen)


func _member(unit_id: String, name: String, vital: String) -> Dictionary:
	return {"unit_id": unit_id, "display_name": name, "vital_state": vital, "health_points": 0 if vital == "dead" else 40, "fireteam_id": "alpha"}


func _people_report(with_campaign: bool, severity: String) -> Dictionary:
	var report := _campaign_report("victory", "objective_capture") if with_campaign else _base_report("victory", "objective_capture")
	report["team_states"] = [_member("u_ok", "Ida", "fit"), _member("u_hurt", "Hanna", "fit"), _member("u_dead", "Karl", "dead")]
	if with_campaign:
		report["casualties"] = [
			{"unit_id": "u_hurt", "outcome": "wounded", "severity": severity, "display_name": "Hanna"},
			{"unit_id": "u_dead", "outcome": "dead", "severity": "", "display_name": "Karl"},
		]
		report["fatality_unit_ids"] = PackedStringArray(["u_dead"])
	return report


func _status_text(screen: Control, unit_id: String) -> String:
	for card in screen.find_children("PersonCard_*", "PanelContainer", true, false):
		if String(card.get_meta("debrief_member_id", "")) == unit_id:
			var label := card.find_child("StatusLabel", true, false) as Label
			return label.text if label != null else "<ohne StatusLabel>"
	return "<keine Karte>"


func _m_ss(seconds: float) -> String:
	var whole := int(seconds)
	return "%d:%02d" % [whole / 60, whole % 60]


func _check_debrief_people() -> void:
	var rules: Dictionary = RULES.load_rules()
	_check(not rules.is_empty(), "Regeldatei lädt für den Zeitvergleich")
	var literal := {"light": ["leicht", "3:00"], "medium": ["mittel", "15:00"], "severe": ["schwer", "40:00"]}
	for severity in ["light", "medium", "severe"]:
		var word: String = literal[severity][0]
		var expected_time: String = literal[severity][1]
		_check(_m_ss(float(Dictionary(rules.get("recovery_seconds", {})).get(severity, -1.0))) == expected_time, "Regeldaten: %s dauert %s" % [severity, expected_time])
		var report := _people_report(true, severity)
		var original := report.duplicate(true)
		var screen := await _open_debrief(report)
		var hurt := _status_text(screen, "u_hurt")
		_check(hurt.contains("Verwundet (%s)" % word) and hurt.contains(expected_time), "Debrief-Zeile Verwundete (%s) nennt Stufe und %s: '%s'" % [severity, expected_time, hurt])
		_check(not hurt.contains("Einsatzfähig") and not hurt.to_lower().contains("erholt") and not hurt.to_lower().contains("recovering"), "Debrief-Zeile Verwundete (%s) widerspricht sich nicht" % severity)
		if severity == "medium":
			var dead := _status_text(screen, "u_dead")
			_check(dead.contains("Gefallen · zurückgelassen"), "Debrief-Zeile Gefallene nennt 'Gefallen · zurückgelassen': '%s'" % dead)
			_check(not dead.contains("Verstorben"), "Debrief-Zeile Gefallene zeigt nicht zusätzlich 'Verstorben'")
			_check(_status_text(screen, "u_ok") == "Einsatzfähig · ALPHA", "Unversehrte Person: Zeile wie bisher")
			var counts := screen.find_child("TeamStateLabel", true, false) as Label
			_check(counts != null and counts.text.contains("1 verwundet") and counts.text.contains("1 gefallen") and counts.text.contains("1 einsatzfähig"), "Zählzeile nennt verwundet und gefallen: '%s'" % (counts.text if counts != null else "<fehlt>"))
		_check(Dictionary(screen.call("get_mission_result")) == original, "Debrief liest nur: Personenergebnis unverändert (%s)" % severity)
		await _close_debrief(screen)
	# Gegenprobe: dieselben Personen ohne Kampagnenmerkmal (Skirmish) zeigen den alten Text.
	var skirmish := _people_report(false, "medium")
	skirmish["team_states"][2]["vital_state"] = "dead"
	var screen := await _open_debrief(skirmish)
	_check(_status_text(screen, "u_hurt") == "Einsatzfähig · ALPHA", "Skirmish: Zeile der Person unverändert")
	_check(_status_text(screen, "u_dead") == "Verstorben · ALPHA", "Skirmish: Zeile der Toten unverändert")
	var skirmish_counts := screen.find_child("TeamStateLabel", true, false) as Label
	_check(skirmish_counts != null and not skirmish_counts.text.contains("verwundet") and not skirmish_counts.text.contains("gefallen"), "Skirmish: Zählzeile ohne neue Wörter")
	await _close_debrief(screen)
	# Kampagne ohne Verwundung: keine neue Anzeige.
	var clean := _campaign_report("victory", "objective_capture")
	clean["team_states"] = [_member("u_ok", "Ida", "fit"), _member("u_two", "Jan", "fit")]
	screen = await _open_debrief(clean)
	_check(_status_text(screen, "u_ok") == "Einsatzfähig · ALPHA" and _status_text(screen, "u_two") == "Einsatzfähig · ALPHA", "Kampagne ohne Verwundung: Zeilen wie bisher")
	await _close_debrief(screen)
	# Totalverlust: keine Verwundeten- oder Gefallenenzeilen aus casualties.
	var total_loss := _people_report(true, "medium")
	total_loss["casualty_total_loss"] = true
	total_loss["casualties"] = []
	screen = await _open_debrief(total_loss)
	_check(_status_text(screen, "u_hurt") == "Einsatzfähig · ALPHA", "Totalverlust: Personenzeile bleibt wie bisher")
	await _close_debrief(screen)


# ---------------------------------------------------------------- Charakterblatt

func _wounded_profile(severity: String, remaining: float) -> Object:
	return PROFILE.new({"unit_id": "fixture_hurt", "display_name": "Hanna", "availability_status": "wounded", "status_text": "wounded", "recovery_state": {"state": "wounded", "severity": severity, "seconds_total": 900.0, "seconds_remaining": remaining, "source": "campaign_casualty"}})


func _check_character_sheet() -> void:
	var profile := _wounded_profile("medium", 750.0)
	var expected := "Verwundet (mittel), noch 12:30"
	_check(RECOVERY.describe(profile.to_dict()) == expected, "describe liefert den Vergleichstext")
	_check(FORMATTER.format_status_text("wounded", profile) == expected, "format_status_text (Profil) zeigt den Text aus describe")
	_check(FORMATTER.format_status_text("wounded", profile.to_dict()) == expected, "format_status_text (Kader-Eintrag) zeigt den Text aus describe")
	var model: Dictionary = FORMATTER.build_sheet_view_model(profile)
	_check(String(model.get("overview_status_text", "")) == expected, "Charakterblatt: Übersicht zeigt den Text aus describe: '%s'" % model.get("overview_status_text", ""))
	var status_row := ""
	for row in Array(model.get("status_rows", [])):
		if String(Dictionary(row).get("label", "")) == "Status":
			status_row = String(Dictionary(row).get("value_text", ""))
	_check(status_row == expected, "Charakterblatt: Statuszeile zeigt den Text aus describe: '%s'" % status_row)
	_check(status_row != "wounded" and not String(model.get("overview_status_text", "")).to_lower() == "wounded", "Charakterblatt zeigt nicht den rohen Wert 'wounded'")
	# Gegenproben: alles andere Zeichen fuer Zeichen wie bisher.
	var fit = PROFILE.new({"unit_id": "fixture_fit", "display_name": "Ida"})
	var fit_model: Dictionary = FORMATTER.build_sheet_view_model(fit)
	_check(String(fit_model.get("overview_status_text", "")) == FORMATTER.format_status_text(String(fit.availability_status)), "Charakterblatt ohne Verwundung: Übersicht wie bisher")
	for text in ["active", "recovering", "wounded", "", "In Transit", "unbekannt_xyz"]:
		_check(FORMATTER.format_status_text(text) == FORMATTER.format_status_text(text, null), "format_status_text ohne Person ist gleich mit und ohne Zusatzargument ('%s')" % text)
	var healed := _wounded_profile("medium", 0.0)
	_check(FORMATTER.format_status_text("wounded", healed) == FORMATTER.format_status_text("wounded"), "Abgelaufene Verwundung fällt auf den alten Text zurück")
	var recovering = PROFILE.new({"unit_id": "fixture_rec", "availability_status": "recovering", "status_text": "recovering", "recovery_state": {"state": "recovering", "turns_remaining": 2}})
	_check(FORMATTER.format_status_text("recovering", recovering) == FORMATTER.format_status_text("recovering"), "Anderer Zustand (recovering) bleibt wie bisher")
	var before: Dictionary = profile.to_dict()
	FORMATTER.build_sheet_view_model(profile)
	_check(profile.to_dict() == before, "Charakterblatt schreibt nichts ins Profil")


# ---------------------------------------------------------------- Personenkarte und Auftragstafel

const STUB_SOURCE := "extends Control\nvar snap: Dictionary = {}\nfunc get_operations_snapshot() -> Dictionary:\n\treturn snap\nfunc request_operation(_operation, _payload) -> Dictionary:\n\treturn {\"ok\": true}\n"


func _check_homebase_and_board() -> void:
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Control = flow.get_node("HomebaseScreen")
	var wounded := _wounded_profile("medium", 750.0)
	var card_text := String(screen.call("_build_roster_card_secondary_text", "fixture_hurt", wounded))
	_check(card_text.begins_with("Verwundet (mittel), noch 12:30 | "), "Personenkarte zeigt den Text aus describe: '%s'" % card_text)
	_check(not card_text.begins_with("wounded") and not card_text.begins_with("Verwundet |"), "Personenkarte zeigt nicht den rohen Wert")
	var fit = PROFILE.new({"unit_id": "fixture_fit", "display_name": "Ida"})
	var fit_text := String(screen.call("_build_roster_card_secondary_text", "fixture_fit", fit))
	var fit_status := fit_text.get_slice(" | ", 0)
	_check(fit_status == "Einsatzbereit" or fit_status == FORMATTER.format_status_text(String(fit.availability_status)), "Personenkarte ohne Verwundung: Status wie bisher ('%s')" % fit_status)
	var plain_text := String(screen.call("_build_roster_card_secondary_text", "fixture_none", null))
	_check(plain_text.begins_with("Einsatzbereit | "), "Personenkarte ohne Profil: 'Einsatzbereit' wie bisher")
	await _check_board(screen)
	flow.queue_free()
	await process_frame


func _snapshot_with(job: Dictionary) -> Dictionary:
	return {"singleplayer": {"mode": "campaign", "campaign": {"jobs": {"satellite_recovery": job}, "job_availability": {"satellite_recovery": {"visible": true, "can_accept": true, "message": ""}}, "locations": {}}, "space_travel": {}}}


func _job(status: String, extra: Dictionary = {}) -> Dictionary:
	var job := {"title": "Satellitenbergung", "description": "", "status": status, "location_id": "satellite_crash", "reward": {"credits": 100}}
	job.merge(extra, true)
	return job


func _board_texts(stub: Control, board: Control, job: Dictionary) -> Dictionary:
	stub.set("snap", _snapshot_with(job))
	board.call("refresh")
	await _frames(2)
	var cards: Dictionary = board.get("_card_buttons")
	var card := cards.get("satellite_recovery") as Button
	var details := board.get("_details") as Label
	return {"card": card.text if card != null else "<keine Karte>", "details": details.text if details != null else "<kein Text>"}


func _check_board(screen: Control) -> void:
	var script := GDScript.new()
	script.source_code = STUB_SOURCE
	script.reload()
	var stub := Control.new()
	stub.set_script(script)
	root.add_child(stub)
	var board: Control = BOARD.new()
	board.call("configure", stub)
	root.add_child(board)
	board.size = Vector2(1100, 600)
	var base := await _board_texts(stub, board, _job("failed"))
	_check(String(base.card).contains("Erneut verfügbar") and not String(base.card).contains("Offen ·") and not String(base.card).contains("Rückzug"), "Auftragstafel ohne retreat_count: heutiger Text ('%s')" % String(base.card).replace("\n", "/"))
	var zero := await _board_texts(stub, board, _job("failed", {"retreat_count": 0}))
	_check(zero.card == base.card and zero.details == base.details, "Auftragstafel mit retreat_count 0: Text exakt wie ohne das Feld")
	var one := await _board_texts(stub, board, _job("failed", {"retreat_count": 1, "reopen_at_home": false}))
	_check(String(one.card).contains("Offen · 1 Rückzug") and not String(one.card).contains("Rückzüge") and not String(one.card).contains("Erneut verfügbar"), "Auftragstafel retreat_count 1: 'Offen · 1 Rückzug' ('%s')" % String(one.card).replace("\n", "/"))
	_check(String(one.details).contains("Offen · 1 Rückzug"), "Auftragsdossier retreat_count 1: 'Offen · 1 Rückzug'")
	var two := await _board_texts(stub, board, _job("failed", {"retreat_count": 2, "reopen_at_home": false}))
	_check(String(two.card).contains("Offen · 2 Rückzüge") and String(two.details).contains("Offen · 2 Rückzüge"), "Auftragstafel retreat_count 2: 'Offen · 2 Rückzüge' ('%s')" % String(two.card).replace("\n", "/"))
	var pending := await _board_texts(stub, board, _job("failed", {"retreat_count": 1, "reopen_at_home": true}))
	_check(String(pending.card).contains("Rückzug · wird an der Basis wieder geöffnet") and not String(pending.card).contains("Offen · 1 Rückzug"), "Auftragstafel vor dem Wiederöffnen: 'Rückzug · wird an der Basis wieder geöffnet' ('%s')" % String(pending.card).replace("\n", "/"))
	_check(String(pending.details).contains("Rückzug · wird an der Basis wieder geöffnet"), "Auftragsdossier vor dem Wiederöffnen nennt denselben Text")
	var reopened := await _board_texts(stub, board, _job("accepted", {"retreat_count": 1, "reopen_at_home": false}))
	_check(String(reopened.card).contains("Offen · 1 Rückzug"), "Wiedergeöffneter Auftrag (accepted, 1 Rückzug): 'Offen · 1 Rückzug' ('%s')" % String(reopened.card).replace("\n", "/"))
	var accepted_plain := await _board_texts(stub, board, _job("accepted"))
	_check(String(accepted_plain.card).contains("Angenommen") and not String(accepted_plain.card).contains("Rückzug"), "Angenommener Auftrag ohne Rückzug: heutiger Text")
	var active := await _board_texts(stub, board, _job("active", {"retreat_count": 1}))
	_check(String(active.card).contains("Im Einsatz") and not String(active.card).contains("Offen ·"), "Auftrag im Einsatz behält 'Im Einsatz'")
	var done := await _board_texts(stub, board, _job("completed", {"retreat_count": 1}))
	_check(String(done.card).contains("Abgeschlossen") and not String(done.card).contains("Offen ·"), "Abgeschlossener Auftrag behält 'Abgeschlossen'")
	var offered := await _board_texts(stub, board, _job("offered"))
	_check(String(offered.card).contains("Verfügbar"), "Neuer Auftrag: 'Verfügbar' wie bisher")
	var snapshot_before := JSON.stringify(stub.get("snap"))
	board.call("refresh")
	_check(JSON.stringify(stub.get("snap")) == snapshot_before, "Auftragstafel schreibt nichts in den Stand")
	board.queue_free()
	stub.queue_free()
	await _frames(2)


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _check(ok: bool, message: String) -> void:
	if ok:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		push_error("FAIL: " + message)
		print("FAIL: " + message)
