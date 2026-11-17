extends "res://scripts/tests/playtest_l03_right_click_boarding_verifier.gd"
## Nacharbeit 3a, Strang N3: Mit einem Liegenden am Boden muss der SPIELER den Rest des Trupps einsteigen lassen koennen.
## Die Tests des Pakets "Ausfall und Rueckzug" rufen request_campaign_crew_boarding direkt; hier laufen die drei Wege des Spielers
## ueber die echten Handler in einem echten Kampagneneinsatz (Aufbau und Hilfen aus playtest_l03_right_click_boarding_verifier):
##   1. Knopf "Einsteigen" der Schiffskarte: _on_campaign_extraction_pressed
##   2. Knopf "Aufsitzen" im Befehlsband: get_selected_team_boarding_snapshot und request_selected_team_boarding
##   3. Rechtsklick auf das eigene gelandete Schiff: echtes InputEventMouseButton
## Dazu die Rueckmeldung nach dem Einsteigen, der Abflug ("Abheben") danach, Pilot liegt, und die Gegenproben
## (niemand liegt, Schalter campaign_casualty_rules_enabled aus).
## Die Kampagne hat im Einsatz nur Truppfuehrer und Pilot: der Liegende ist der Truppfuehrer, der Pilot ist die einsatzfaehige Person.
## Ausgabe: PBINFO-Zeilen, PASS:/FAIL: und die Schlusszeile CAMPAIGN_CASUALTY_PLAYER_BOARDING passed=N failed=M.

const LEADER_ID: String = "campaign_leader"
const TEXT_ALL_ABOARD: String = "Alle an Bord. Rueckflug ist bereit."
const TEXT_OLD_REFUSAL: String = "Eine Bodenperson ist nicht einsatzfaehig"
const TEXT_OLD_SNAPSHOT_REFUSAL: String = "Nicht alle Truppmitglieder sind boardingbereit"
const TEXT_PILOT_DOWN: String = "Pilot ist nicht flugfaehig"
const TEXT_ABOARD_PREFIX: String = "An Bord. Am Boden: "
## Schlusssaetze der Rueckmeldung: mit weiterer einsatzfaehiger Bodenperson (Rettung nach Abstand) und im sicheren Totalverlust (nur der Pilot ist einsatzfaehig).
const TEXT_TAIL_RECOVERY: String = "Wer beim Abheben nicht nah am Schiff liegt, gilt als gefallen."
const TEXT_TAIL_TOTAL_LOSS: String = "Abheben wäre ein Totalverlust: Bodenteam ausgefallen."
## Bei erfuelltem Auftrag (mission_outcome "won" am Driver) werden alle Ausgefallenen gerettet (Vertrag Regel 3).
const TEXT_TAIL_WON: String = "Auftrag erfüllt: Beim Abheben werden alle gerettet."

var _driver: Node
var _leader: Node

func _run() -> void:
	if await _open_sortie():
		await _scene_pb0_nobody_down()
		await _scene_pb1_switch_off()
		await _scene_pb2_extraction_button()
		await _scene_pb3_board_button()
		await _scene_pb4_right_click()
		await _scene_pb5_departure()
	await _close_sortie()
	if await _open_sortie():
		await _scene_pb6_pilot_down()
	await _close_sortie()
	if await _open_sortie():
		await _scene_pb7_mission_won()
	await _close_sortie()
	print("CAMPAIGN_CASUALTY_PLAYER_BOARDING passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)

func _open_sortie() -> bool:
	_crew_ids.clear()
	if not await _setup_sortie():
		_check(false, "PB Aufbau: gelandeter Kampagneneinsatz steht")
		return false
	var mission: Node = _flow.get("_active_mission")
	_driver = mission.get_node("CombatLoopDriver")
	_leader = _controller.call("_get_campaign_sortie_unit", LEADER_ID)
	var ok: bool = _leader != null and bool(_driver.get("campaign_casualty_rules_enabled")) and _crew_ids.has(LEADER_ID) and _crew_ids.has(_pilot_id)
	_check(ok, "PB Aufbau: Truppfuehrer und Pilot im Einsatz, Schalter am Driver ist an (crew=%s)" % str(_crew_ids))
	return ok

func _close_sortie() -> void:
	if is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame

# ---------------------------------------------------------------- helpers

func _feedback() -> String:
	var card: Dictionary = _controller.call("_find_mission_dropship_card_entry", _craft_id)
	return String(_controller.call("_get_mission_dropship_card_feedback_text", card))

func _in_set(set_name: String, id: String) -> bool:
	return Dictionary(_controller.get(set_name)).has(id)

func _grid_of(id: String) -> Vector2i:
	var state: Dictionary = _simulation.get_hex_unit_state(id)
	return Vector2i(state.grid) if not state.is_empty() else Vector2i(-99999, -99999)

func _extraction_idle() -> bool:
	return String(_controller.get("_campaign_extraction_craft_id")).is_empty()

func _pilot_on_ground() -> bool:
	if _in_set("_embarked_unit_ids", _pilot_id):
		var deploy: Dictionary = _controller.request_campaign_crew_deployment(_craft_id)
		if not bool(deploy.get("ok", false)):
			print("PBINFO Pilot absetzen abgelehnt: ", _clean(str(deploy)))
			return false
		if await _wait_scene(func(): return _in_set("_deployed_unit_ids", _pilot_id), SETUP_LIMIT_SECONDS) < 0.0:
			return false
	_select_team()
	return await _wait_scene(_flags_clear, SETUP_LIMIT_SECONDS) >= 0.0

func _leader_down() -> bool:
	_leader.call("apply_damage", 10000)
	var flagged: float = await _wait_scene(func(): return bool(Dictionary(_driver.call("get_casualty_flags")).get(LEADER_ID, {}).get("was_downed", false)), 10.0)
	return flagged >= 0.0 and String(_leader.call("get_vital_state")) != "fit"

func _leader_name() -> String:
	return String(_leader.call("get_display_name")).strip_edges()

func _critical(unit: Node) -> bool:
	return String(unit.call("get_vital_state")) in ["bleedout", "respawning"]

## Der Knopf "Aufsitzen" steckt im Befehlsband; sein Handler ist request_selected_team_boarding. Nur zur Information, ob der Knopf da ist.
func _board_button_info() -> void:
	var button: Node = _flow.get("_active_mission").find_child("A5TeamBoard", true, false)
	print("PBINFO Knopf Aufsitzen: ", "nicht gefunden" if button == null else "gefunden, disabled=%s visible=%s" % [str(button.get("disabled")), str(button.get("visible"))])

func _ship_right_click_board() -> void:
	_select_team()
	_controller.set("_last_command_text", "")
	_controller.call("set_planning_enabled", false)
	await _wait_scene(Callable(self, "_never"), 2.0)
	await _right_click(_ship_screen())
	if not _request_open() and not _in_set("_embarked_unit_ids", _pilot_id) and String(_controller.get("_last_command_text")).is_empty() and not _use_direct_input:
		_use_direct_input = true
		print("PBINFO Rechtsklick ueber den Viewport kam nicht an, weiter mit controller._unhandled_input(event)")
		await _right_click(_ship_screen())

## Die Meldung des Aufsitzens steht in _last_command_text und auf der Schiffskarte; andere Meldungen koennen sie danach ueberschreiben.
func _player_text() -> String:
	var command: String = String(_controller.get("_last_command_text"))
	return command if command.begins_with(TEXT_ABOARD_PREFIX) else _feedback()

func _check_casualty_text(text: String, label: String) -> void:
	var state_label: String = " (kritisch)" if _critical(_leader) else ""
	_check(text.begins_with(TEXT_ABOARD_PREFIX) and text.contains(_leader_name() + state_label + "."), "%s: Text nennt den Liegenden mit Namen und Zustand (%s)" % [label, text])
	_check(text != TEXT_ALL_ABOARD and not text.contains("Rueckflug ist bereit"), "%s: nicht der Text 'Alle an Bord. Rueckflug ist bereit.'" % label)
	# Im echten Einsatz gibt es nur Truppfuehrer (liegt) und Pilot (an Bord): der Schluss ist der sichere Totalverlust.
	_check(text == "%s%s%s. %s" % [TEXT_ABOARD_PREFIX, _leader_name(), state_label, TEXT_TAIL_TOTAL_LOSS], "%s: genauer Text mit Totalverlust-Schluss (%s)" % [label, text])

# ---------------------------------------------------------------- scenes

## PB0: niemand liegt, die drei Wege und die Rueckmeldung wie bisher (gruene Gegenprobe).
func _scene_pb0_nobody_down() -> void:
	_begin_scene("PB0")
	if not await _prepare_ground():
		_check(false, "PB0 Vorbedingung: Trupp am Boden, Befehle frei")
		return
	_controller.call("_on_campaign_extraction_pressed", _craft_id)
	_check(String(_controller.get("_campaign_extraction_craft_id")) == _craft_id, "PB0 Einsteigen: Anfrage angenommen (%s)" % _clean(String(_controller.get("_last_command_text"))))
	await _wait_scene(_extraction_idle, BOARD_LIMIT_SECONDS)
	_check(_is_aboard(), "PB0 Einsteigen: alle an Bord")
	_check(_feedback() == TEXT_ALL_ABOARD, "PB0 Einsteigen: Rueckmeldung unveraendert '%s' (ist '%s')" % [TEXT_ALL_ABOARD, _feedback()])
	if not await _prepare_ground():
		_check(false, "PB0 Vorbedingung 2: Trupp wieder am Boden")
		return
	var snapshot: Dictionary = _controller.get_selected_team_boarding_snapshot()
	_check(bool(snapshot.get("can_board", false)), "PB0 Aufsitzen: Snapshot erlaubt (%s)" % _clean(String(snapshot.get("message", ""))))
	_board_button_info()
	var answer: Dictionary = _controller.request_selected_team_boarding()
	_check(bool(answer.get("ok", false)), "PB0 Aufsitzen: Anfrage angenommen (%s)" % _clean(String(answer.get("message", ""))))
	var card_before: String = _feedback()
	await _wait_scene(_aboard_or_dropped, BOARD_LIMIT_SECONDS)
	_check(_is_aboard() and not _request_open(), "PB0 Aufsitzen: alle an Bord, Anfrage geschlossen (Meldung jetzt '%s')" % _clean(String(_controller.get("_last_command_text"))))
	# Ohne Liegende bleibt die Rueckmeldung wie vor dem 16.11.: die Schiffskarte wird nicht angefasst und die Hilfsfunktion liefert keinen Text.
	# Die Befehlszeile ("<TRUPP> an Bord") ueberschreibt der Phasentext im selben Bild (_process, "P0 PRE COMPLETE"); sie ist von aussen nicht zu lesen.
	_check(_feedback() == card_before and not _feedback().begins_with(TEXT_ABOARD_PREFIX), "PB0 Aufsitzen: Schiffskarte unveraendert '%s' (ist '%s')" % [card_before, _feedback()])
	_check(String(_controller.call("_campaign_casualty_aboard_text", _craft_id, PackedStringArray())) == "", "PB0 Aufsitzen: Hilfsfunktion ohne Liegende liefert keinen Text")
	if not await _prepare_ground():
		_check(false, "PB0 Vorbedingung 3: Trupp wieder am Boden")
		return
	await _ship_right_click_board()
	_check(_request_open() or _is_aboard(), "PB0 Rechtsklick: Anfrage geoeffnet")
	await _wait_scene(_aboard_or_dropped, BOARD_LIMIT_SECONDS)
	_check(_is_aboard(), "PB0 Rechtsklick: alle an Bord")

## PB1: Schalter aus, Truppfuehrer liegt: Verhalten wie bisher (Ablehnung crew_unavailable).
func _scene_pb1_switch_off() -> void:
	_begin_scene("PB1")
	if not await _prepare_ground():
		_check(false, "PB1 Vorbedingung: Trupp am Boden")
		return
	# Der Trupp geht erst vier Felder vom Schiff weg: ein Liegender auf den Ausstiegsfeldern wuerde das Absetzen des Piloten blockieren ("Ausstieg wartet auf freie Felder").
	if not _check(_start_march(4.0), "PB1 Vorbereitung: Trupp marschiert vom Schiff weg"):
		return
	await _wait_scene(_settled_after_two_seconds.bind(_game_seconds), 60.0)
	if not _check(await _leader_down(), "PB1 Truppfuehrer liegt"):
		return
	_driver.set("campaign_casualty_rules_enabled", false)
	var answer: Dictionary = _controller.request_campaign_extraction(_craft_id)
	print("PBINFO PB1 Einsteigen ", answer)
	_check(not bool(answer.get("ok", true)) and String(answer.get("reason", "")) == "crew_unavailable" and String(answer.get("message", "")) == TEXT_OLD_REFUSAL, "PB1 Schalter aus, Einsteigen: crew_unavailable mit altem Text")
	_controller.call("_on_campaign_extraction_pressed", _craft_id)
	_check(String(_controller.get("_last_command_text")) == TEXT_OLD_REFUSAL and _extraction_idle(), "PB1 Schalter aus, Knopf: alter Text, keine Anfrage offen")
	var snapshot: Dictionary = _controller.get_selected_team_boarding_snapshot()
	_check(not bool(snapshot.get("can_board", true)) and String(snapshot.get("message", "")) == TEXT_OLD_SNAPSHOT_REFUSAL, "PB1 Schalter aus, Aufsitzen: Snapshot lehnt mit altem Text ab (%s)" % _clean(String(snapshot.get("message", ""))))
	var board: Dictionary = _controller.request_selected_team_boarding()
	_check(not bool(board.get("ok", true)) and not _request_open(), "PB1 Schalter aus, Aufsitzen: abgelehnt, keine Anfrage offen")
	_driver.set("campaign_casualty_rules_enabled", true)
	_check(not _in_set("_embarked_unit_ids", _pilot_id) and not _in_set("_embarked_unit_ids", LEADER_ID), "PB1 Schalter aus: niemand eingeschifft")

## PB2: Knopf "Einsteigen" der Schiffskarte mit einem Liegenden.
func _scene_pb2_extraction_button() -> void:
	_begin_scene("PB2")
	if not await _pilot_on_ground():
		_check(false, "PB2 Vorbedingung: Pilot am Boden")
		return
	var leader_grid: Vector2i = _grid_of(LEADER_ID)
	_controller.call("_on_campaign_extraction_pressed", _craft_id)
	var shown: String = String(_controller.get("_last_command_text"))
	print("PBINFO PB2 Knopf Einsteigen -> last_command_text='", _clean(shown), "' feedback='", _clean(_feedback()), "'")
	_check(String(_controller.get("_campaign_extraction_craft_id")) == _craft_id, "PB2 Einsteigen: Anfrage angenommen, nicht abgelehnt ('%s')" % _clean(shown))
	if String(_controller.get("_campaign_extraction_craft_id")) != _craft_id:
		return
	await _wait_scene(_extraction_idle, BOARD_LIMIT_SECONDS)
	_check(_in_set("_embarked_unit_ids", _pilot_id), "PB2 Einsteigen: der einsatzfaehige Pilot ist an Bord")
	_check(_in_set("_deployed_unit_ids", LEADER_ID) and not _in_set("_embarked_unit_ids", LEADER_ID), "PB2 Einsteigen: der Liegende bleibt am Boden, nicht eingeschifft")
	_check(_grid_of(LEADER_ID) == leader_grid, "PB2 Einsteigen: der Liegende wurde nicht bewegt")
	_check_casualty_text(_feedback(), "PB2 Einsteigen")

## PB3: Knopf "Aufsitzen" im Befehlsband mit einem Liegenden.
func _scene_pb3_board_button() -> void:
	_begin_scene("PB3")
	if not await _pilot_on_ground():
		_check(false, "PB3 Vorbedingung: Pilot am Boden")
		return
	var leader_grid: Vector2i = _grid_of(LEADER_ID)
	var snapshot: Dictionary = _controller.get_selected_team_boarding_snapshot()
	print("PBINFO PB3 Snapshot ", snapshot)
	_check(bool(snapshot.get("can_board", false)), "PB3 Aufsitzen: Snapshot erlaubt es fuer die Einsatzfaehigen (%s)" % _clean(String(snapshot.get("message", ""))))
	_board_button_info()
	var answer: Dictionary = _controller.request_selected_team_boarding()
	print("PBINFO PB3 Anfrage ", answer)
	_check(bool(answer.get("ok", false)), "PB3 Aufsitzen: Anfrage angenommen (%s)" % _clean(String(answer.get("message", ""))))
	if not bool(answer.get("ok", false)):
		return
	await _wait_scene(func(): return _in_set("_embarked_unit_ids", _pilot_id) or not _request_open(), BOARD_LIMIT_SECONDS)
	_check(_in_set("_embarked_unit_ids", _pilot_id), "PB3 Aufsitzen: der einsatzfaehige Pilot ist an Bord")
	_check(_in_set("_deployed_unit_ids", LEADER_ID) and not _in_set("_embarked_unit_ids", LEADER_ID) and _grid_of(LEADER_ID) == leader_grid, "PB3 Aufsitzen: der Liegende bleibt unbewegt am Boden")
	_check_casualty_text(_player_text(), "PB3 Aufsitzen")
	var after: Dictionary = _controller.get_selected_team_boarding_snapshot()
	_check(not bool(after.get("can_board", true)) and String(after.get("message", "")) == "Trupp an Bord", "PB3 Aufsitzen: danach 'Trupp an Bord' (%s)" % _clean(String(after.get("message", ""))))

## PB4: Rechtsklick auf das eigene gelandete Schiff mit einem Liegenden (echtes Mausereignis).
func _scene_pb4_right_click() -> void:
	_begin_scene("PB4")
	if not await _pilot_on_ground():
		_check(false, "PB4 Vorbedingung: Pilot am Boden")
		return
	var leader_grid: Vector2i = _grid_of(LEADER_ID)
	await _ship_right_click_board()
	print("PBINFO PB4 Rechtsklick -> request_open=", _request_open(), " last_command_text='", _clean(String(_controller.get("_last_command_text"))), "' direct_input=", _use_direct_input)
	_check(_request_open() or _in_set("_embarked_unit_ids", _pilot_id), "PB4 Rechtsklick: Anfrage geoeffnet ('%s')" % _clean(String(_controller.get("_last_command_text"))))
	if not (_request_open() or _in_set("_embarked_unit_ids", _pilot_id)):
		return
	await _wait_scene(func(): return _in_set("_embarked_unit_ids", _pilot_id) or not _request_open(), BOARD_LIMIT_SECONDS)
	_check(_in_set("_embarked_unit_ids", _pilot_id), "PB4 Rechtsklick: der einsatzfaehige Pilot ist an Bord")
	_check(_in_set("_deployed_unit_ids", LEADER_ID) and not _in_set("_embarked_unit_ids", LEADER_ID) and _grid_of(LEADER_ID) == leader_grid, "PB4 Rechtsklick: der Liegende bleibt unbewegt am Boden")
	_check_casualty_text(_player_text(), "PB4 Rechtsklick")
	# Nach Ablauf der Versorgungsfrist heisst der Zustand "kritisch"; der Text folgt dem Zustand (nur wenn er im Test erreicht wird).
	var critical: float = await _wait_scene(func(): return _critical(_leader), 100.0)
	print("PBINFO PB4 kritisch erreicht nach %.1f s, Zustand=%s" % [critical, String(_leader.call("get_vital_state"))])
	# Fehlt eine Voraussetzung, ist das ein Fehlschlag und kein stilles Ueberspringen.
	if not _check(critical >= 0.0, "PB4 kritisch: der Liegende erreicht den Zustand 'kritisch' (Zustand %s)" % String(_leader.call("get_vital_state"))):
		return
	if not _check(_controller.has_method("_campaign_casualty_aboard_text"), "PB4 Hilfsfunktion _campaign_casualty_aboard_text ist vorhanden"):
		return
	var text: String = String(_controller.call("_campaign_casualty_aboard_text", _craft_id, PackedStringArray([LEADER_ID])))
	_check(text == "%s%s (kritisch). %s" % [TEXT_ABOARD_PREFIX, _leader_name(), TEXT_TAIL_TOTAL_LOSS], "PB4 kritisch: genauer Text mit '(kritisch)' und Totalverlust-Schluss (%s)" % text)
	# Mit zwei Personen gibt es keine zweite einsatzfaehige Bodenperson. Die Satzvariante "bleibt eine Bodenperson fit" pruefe ich an der Hilfsfunktion:
	# eine Schiffs-ID ohne Karte hat keinen Piloten, der Pilot der Probe zaehlt dann als einsatzfaehige Bodenperson.
	var normal: String = String(_controller.call("_campaign_casualty_aboard_text", "no_such_craft", PackedStringArray([LEADER_ID])))
	_check(normal == "%s%s (kritisch). %s" % [TEXT_ABOARD_PREFIX, _leader_name(), TEXT_TAIL_RECOVERY], "PB4 Hilfsfunktion, mit weiterer einsatzfaehiger Person: genauer Normalsatz (%s)" % normal)
	_check(String(_controller.call("_campaign_casualty_aboard_text", _craft_id, PackedStringArray())) == "", "PB4 Hilfsfunktion: ohne Liegende kein Text")

## PB5: Abheben nach dem Einsteigen laeuft ueber das Gate. Mit nur zwei Personen ist der einzige Bodenmann der Liegende: Totalverlust.
func _scene_pb5_departure() -> void:
	_begin_scene("PB5")
	if not _in_set("_embarked_unit_ids", _pilot_id):
		_check(false, "PB5 Vorbedingung: Pilot ist an Bord (sonst nicht gebucht)")
		return
	_controller.call("_on_mission_dropship_return_pressed", _craft_id)
	print("PBINFO PB5 nach Abheben: last_command_text='", _clean(String(_controller.get("_last_command_text"))), "' feedback='", _clean(_feedback()), "'")
	var released: bool = await _wait(func(): return _flow.get("_active_mission") == null, 120000, "PB5: Einsatz wird nach Abheben ausgewertet und freigegeben")
	_check(released, "PB5 Abheben: das Gate wertet den Einsatz aus")
	if not released:
		return
	await process_frame
	var result: Dictionary = Dictionary(_flow.get("_last_mission_result"))
	print("PBINFO PB5 Ergebnis result=", result.get("result"), " total_loss=", result.get("casualty_total_loss"), " reason=", result.get("total_loss_reason"))
	_check(bool(result.get("casualty_total_loss", false)) and String(result.get("total_loss_reason", "")) == "ground_team_down", "PB5 Abheben: Totalverlust, Grund ground_team_down (einziger Bodenmann liegt)")

## PB6: Pilot liegt: "Einsteigen" und "Aufsitzen" lehnen ab, mit pilot_unavailable wie request_campaign_crew_boarding.
func _scene_pb6_pilot_down() -> void:
	_begin_scene("PB6")
	if not await _prepare_ground():
		_check(false, "PB6 Vorbedingung: Trupp am Boden")
		return
	var pilot: Node = _controller.call("_get_campaign_sortie_unit", _pilot_id)
	pilot.call("apply_damage", 10000)
	var flagged: float = await _wait_scene(func(): return bool(Dictionary(_driver.call("get_casualty_flags")).get(_pilot_id, {}).get("was_downed", false)), 10.0)
	if not _check(flagged >= 0.0 and String(pilot.call("get_vital_state")) != "fit", "PB6 Pilot liegt"):
		return
	var direct: Dictionary = _controller.call("request_campaign_crew_boarding", _craft_id)
	_check(String(direct.get("reason", "")) == "pilot_unavailable", "PB6 Vergleich: request_campaign_crew_boarding meldet pilot_unavailable")
	var answer: Dictionary = _controller.request_campaign_extraction(_craft_id)
	print("PBINFO PB6 Einsteigen ", answer)
	_check(not bool(answer.get("ok", true)) and String(answer.get("reason", "")) == "pilot_unavailable" and String(answer.get("message", "")) == String(direct.get("message", TEXT_PILOT_DOWN)), "PB6 Einsteigen: abgelehnt mit pilot_unavailable und demselben Text")
	_controller.call("_on_campaign_extraction_pressed", _craft_id)
	_check(String(_controller.get("_last_command_text")) == String(direct.get("message", TEXT_PILOT_DOWN)) and _extraction_idle(), "PB6 Knopf: Text gezeigt, keine Anfrage offen")
	_check(not _in_set("_embarked_unit_ids", LEADER_ID) and _in_set("_deployed_unit_ids", LEADER_ID), "PB6: der einsatzfaehige Truppfuehrer wurde nicht eingeschifft")
	_select_team()
	var snapshot: Dictionary = _controller.get_selected_team_boarding_snapshot()
	_check(not bool(snapshot.get("can_board", true)) and String(snapshot.get("message", "")) == String(direct.get("message", TEXT_PILOT_DOWN)), "PB6 Aufsitzen: Snapshot lehnt ab: %s" % _clean(String(snapshot.get("message", ""))))
	var board: Dictionary = _controller.request_selected_team_boarding()
	_check(not bool(board.get("ok", true)) and not _request_open(), "PB6 Aufsitzen: abgelehnt, keine Anfrage offen")

## PB7: Einsteigen mit Liegender bei erfuelltem Auftrag. Der Driver hat den Sieg aufgeloest (mission_outcome "won"): jeder Ausgefallene wird gerettet,
## der Satz darf nicht sagen, dass Fernliegende als gefallen gelten, und der Totalverlust-Zusatz entfaellt.
func _scene_pb7_mission_won() -> void:
	_begin_scene("PB7")
	if not await _prepare_ground():
		_check(false, "PB7 Vorbedingung: Trupp am Boden")
		return
	if not _check(_start_march(4.0), "PB7 Vorbereitung: Trupp marschiert vom Schiff weg"):
		return
	await _wait_scene(_settled_after_two_seconds.bind(_game_seconds), 60.0)
	if not _check(await _leader_down(), "PB7 Truppfuehrer liegt"):
		return
	if not _check(not bool(_driver.call("is_combat_finished")), "PB7 Vorbedingung: Auftrag noch nicht aufgeloest"):
		return
	_select_team()
	var state_label: String = " (kritisch)" if _critical(_leader) else ""
	var open_text: String = String(_controller.call("_campaign_casualty_aboard_text", _craft_id, PackedStringArray([LEADER_ID])))
	_check(open_text == "%s%s%s. %s" % [TEXT_ABOARD_PREFIX, _leader_name(), state_label, TEXT_TAIL_TOTAL_LOSS], "PB7 Auftrag offen: Text wie bisher mit Totalverlust-Schluss (%s)" % open_text)
	_driver.call("_resolve_combat", "victory", String(_driver.get("friendly_team_id")))
	var outcome: String = String(Dictionary(_driver.call("get_mission_result")).get("mission_outcome", ""))
	print("PBINFO PB7 Driver fertig=", _driver.call("is_combat_finished"), " mission_outcome=", outcome)
	if not _check(bool(_driver.call("is_combat_finished")) and outcome == "won", "PB7 Auftrag erfuellt: Driver meldet mission_outcome 'won' (%s)" % outcome):
		return
	await _wait_scene(Callable(self, "_never"), 1.0)
	if not _check(is_instance_valid(_controller) and is_instance_valid(_leader), "PB7 Controller und Truppfuehrer sind nach dem Sieg noch da"):
		return
	state_label = " (kritisch)" if _critical(_leader) else ""
	var won_text: String = String(_controller.call("_campaign_casualty_aboard_text", _craft_id, PackedStringArray([LEADER_ID])))
	_check(won_text == "%s%s%s. %s" % [TEXT_ABOARD_PREFIX, _leader_name(), state_label, TEXT_TAIL_WON], "PB7 Auftrag erfuellt: genauer Satz mit Rettung aller (%s)" % won_text)
	var won_other: String = String(_controller.call("_campaign_casualty_aboard_text", "no_such_craft", PackedStringArray([LEADER_ID])))
	_check(won_other == "%s%s%s. %s" % [TEXT_ABOARD_PREFIX, _leader_name(), state_label, TEXT_TAIL_WON], "PB7 Auftrag erfuellt, mit weiterer einsatzfaehiger Person: derselbe Satz (%s)" % won_other)
