extends "res://scripts/tests/campaign_respawn_no_dead_end_verifier.gd"
## Speichern, erster Teil / 21.11. ("Speichern soll immer moeglich sein", Teil 1: Heimatbasis).
## Echte Meta-Szene mit vier Personen, echter Flug; gelesen wird die Platte (campaign_checkpoint_store) und die Zaehler des Flows
## (campaign_save_attempts / campaign_save_successes, gesetzt von request_campaign_save; der periodische Basis-Speicherpunkt zaehlt nicht).
## P  (S1 a, c) Polisa-Besuch ohne Anwerben, Heimkehr: die Ortsinstanz ist frei, die Landung loest von selbst ein Speichern aus,
##    Speichern klappt, Fortsetzen laedt den Stand nach der Heimkehr.
## D  (S1 d) Ausruesten in der ersten Minute, Abheben, Programm "stirbt" (ohne Speichern verlassen), Fortsetzen hat die Ausruestung.
## E  (S3 e) Speichern im Flug: vorgemerkt, nach der Landung gespeichert, genau ein Wunsch.
## F  (S3 f) F5 loest denselben Weg aus wie der Menuepunkt; in einer Texteingabe nicht.
## G  (S0 g) Jeder Ablehnungsgrund hat einen eigenen Satz; "Schiff im Flug" und "Schiff an anderem Ort" unterscheiden sich.
## Abschlusszeile: CAMPAIGN_SAVE_FIRST_PART passed=%d failed=%d
## Einzeln starten: Kommandozeilenargument nach "--" (zum Beispiel "-- P").

const FP_STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const FP_PROJECTION = preload("res://scripts/meta/campaign_save_projection.gd")
const FP_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")

func _run() -> void:
	var verdict: Dictionary = FP_GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_SAVE_FIRST_PART refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	_configure_entry()
	var selected: Array = []
	for arg: String in OS.get_cmdline_user_args():
		if not arg.strip_edges().is_empty():
			selected.append(arg.strip_edges().to_upper())
	for scenario: String in ["P", "D", "E", "F", "G"]:
		if not selected.is_empty() and not selected.has(scenario):
			continue
		if not has_method("_fp_" + scenario.to_lower()):
			continue
		print("--- ", scenario)
		_nd = {}
		await call("_fp_" + scenario.to_lower())
		await _end_sortie()
	print("CAMPAIGN_SAVE_FIRST_PART passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

# ---------- Hilfen ----------

func _fp_attempts() -> int:
	return int(_flow.get_meta("campaign_save_attempts", 0))

func _fp_successes() -> int:
	return int(_flow.get_meta("campaign_save_successes", 0))

func _fp_disk_text() -> String:
	if not FileAccess.file_exists(FP_STORE.DEFAULT_PATH):
		return ""
	return FileAccess.get_file_as_string(FP_STORE.DEFAULT_PATH)

func _fp_disk_chips() -> int:
	return _fp_disk_text().count("satellite_chip")

## Eine Aenderung am Basislager (zaehlt als "Ausruestung" der ersten Minute): ein Chip mehr im Lager.
func _fp_grant_chip(request_id: String) -> bool:
	var grant: Dictionary = _runtime.call("_commit", "singleplayer_supply", "campaign_cargo", {"container_id": "base:homebase", "item_id": "satellite_chip", "amount": 1}, request_id, {"campaign_authorized": true})
	return bool(grant.get("ok", false))

func _fp_snapshot_chips() -> int:
	return JSON.stringify(_t6b_payload()).count("satellite_chip")

## Schiff daheim und nicht mehr beschaeftigt.
func _fp_craft_home() -> bool:
	for craft: Dictionary in Array(Dictionary(_runtime.call("get_snapshot")).get("crafts", [])):
		if String(craft.get("craft_id", "")) == _craft_id:
			return String(craft.get("location_id", "")) == "homebase" and not bool(craft.get("busy", true))
	return false

## Abflug von der Basis bis in den Mondorbit (ohne Ort zu besuchen). Rueckgabe: "" oder Grund.
func _fp_launch_to_moon_orbit(tag: String) -> String:
	var result: Dictionary = _pk_op("select_destination", {"location_id": "polisa", "job_id": ""})
	if not _check(bool(result.get("ok", false)), "%s: Polisa als Besuch ohne Auftrag gewaehlt (%s)" % [tag, result]): return "select_destination"
	result = _pk_op("start")
	if not _check(bool(result.get("ok", false)), "%s: das Schiff hebt ab (%s)" % [tag, result]): return "start:%s" % result.get("reason", "")
	return ""

## Kampagnenstart mit Besatzung an Bord, bereit zum Abheben. Rueckgabe: "" oder Grund.
func _fp_ready_to_launch(tag: String) -> String:
	if not await _t6b_new_four(): return "new_four"
	_flow.set("_active_singleplayer_identity", {})
	_nd_craft()
	if not _nd_ensure_team_for(LEAD_A): return "team"
	return await _nd_board_crew(tag, LEAD_A, PILOT_ID)

# ---------- P: Polisa-Besuch ohne Anwerben ----------

func _fp_p() -> void:
	if await _fp_ready_to_launch("P") != "": return
	var roster_before: Array = _t6b_roster_ids()
	if await _nd_to_polisa("P") != "": return
	var visit: Node = _flow.get("_active_mission")
	_check(is_instance_valid(visit) and String(visit.get_meta("location_id", "")) == "polisa", "P: Fixture: die Polisa-Instanz ist der fokussierte Ort")
	var refused: Dictionary = _flow.call("request_campaign_save")
	_check(not bool(refused.get("ok", true)), "P: Fixture: waehrend des Besuchs wird nicht gespeichert (Grund %s)" % refused.get("reason", ""))
	var place_guard: Dictionary = _flow.get("_campaign_start").call("get_home_checkpoint_guard", _flow, _runtime)
	print("FP_P_GUARD_AT_PLACE ", place_guard)
	# S0: waehrend des Besuchs ist ein Schiff an einem anderen Ort; nie "Reise": entweder meldet der Welt-Schutz (world_active) oder der Basis-Schutz mit detail place.
	_check(String(place_guard.get("reason", "")) == "world_active" or (String(place_guard.get("reason", "")) == "away_from_checkpoint" and String(place_guard.get("detail", "")) == "place"), "P S0: waehrend des Besuchs nennt der Schutz einen Grund mit eigenem Satz (%s)" % [place_guard])
	var successes_before := _fp_successes()
	if not await _nd_return("P", [], {}, {}): return
	_check(await _pk_wait(func(): return _flow.get("_active_mission") == null, 8000), "P a: nach der Heimlandung ist die Ortsinstanz nicht mehr der aktive Einsatz")
	_check(_flow.call("get_location_runtime_snapshot").size() >= 1, "P a: die Polisa-Instanz bleibt in der Registry (nur nicht mehr fokussiert)")
	# c: ohne jeden Handgriff des Spielers loest die Landung ein Speichern aus (Wiederholung jede Sekunde, bis es klappt).
	var auto_saved: bool = await _pk_wait(func(): return _fp_successes() > successes_before, 30000)
	_check(auto_saved, "P c: die Heimlandung loest von selbst ein erzwungenes Speichern aus (gelungen +%d)" % (_fp_successes() - successes_before))
	var disk_time_before := FileAccess.get_modified_time(FP_STORE.DEFAULT_PATH)
	await _nd_unboard_all("P", [])
	var saved: Dictionary = {}
	var deadline := Time.get_ticks_msec() + 10000
	while not bool(saved.get("ok", false)) and Time.get_ticks_msec() < deadline:
		saved = _flow.call("request_campaign_save")
		if not bool(saved.get("ok", false)):
			await _pk_wait(func(): return false, 1000)
	# Speichern, erster Teil / 21.11.: war bis hierher als BEFUND festgehalten (mission_identity_mismatch), jetzt muss es klappen.
	_check(bool(saved.get("ok", false)), "P a: Speichern an der Basis nach dem Polisa-Besuch klappt (Grund: %s)" % saved.get("reason", ""))
	_check(disk_time_before > 0 or FileAccess.file_exists(FP_STORE.DEFAULT_PATH), "P a: die Datei liegt auf der Platte")
	_check(_t6b_roster_ids() == roster_before, "P a: Kader nach der Heimkehr unveraendert")
	# Fortsetzen laedt den Stand nach der Heimkehr.
	var base_ids_before: Array = _t6b_base_ids()
	await _end_sortie()
	await create_timer(0.5).timeout
	if not await _t6b_open("campaign", "continue"): return
	_nd_craft()
	_check(_t6b_roster_ids() == roster_before, "P a: Fortsetzen: gleicher Kader (%s)" % [_t6b_roster_ids()])
	_check(_t6b_base_ids() == base_ids_before, "P a: Fortsetzen: gleiche Basisleute")
	_check(_fp_craft_home() or String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(_craft_id, "")) == "homebase", "P a: Fortsetzen: das Schiff steht an der Basis")
	_check(_flow.get("_active_mission") == null, "P a: Fortsetzen: kein aktiver Einsatz")

# ---------- D: Ausruesten, Abheben, Programm stirbt ----------

func _fp_d() -> void:
	if await _fp_ready_to_launch("D") != "": return
	var chips_on_disk := _fp_disk_chips()
	_check(_fp_grant_chip("fp:d:chip"), "D: Fixture: Ausruestung der ersten Minute (ein Chip mehr im Lager)")
	_check(_fp_disk_chips() == chips_on_disk, "D: Fixture: die Aenderung ist noch nicht auf der Platte (Drossel)")
	var attempts_before := _fp_attempts()
	if await _fp_launch_to_moon_orbit("D") != "": return
	var launch_save: Dictionary = Dictionary(_flow.get_meta("campaign_launch_save_result", {}))
	_check(bool(launch_save.get("ok", false)), "D: vor dem Abheben wurde gespeichert (%s)" % [launch_save])
	_check(_fp_attempts() - attempts_before == 1, "D: genau ein Speicherversuch beim Abheben (+%d)" % (_fp_attempts() - attempts_before))
	_check(_fp_disk_chips() > chips_on_disk, "D: die Platte enthaelt die Ausruestung (Chips %d gegen %d)" % [_fp_disk_chips(), chips_on_disk])
	# Das Programm "stirbt": die Kampagne wird ohne Speichern verlassen.
	await _end_sortie()
	await create_timer(0.5).timeout
	if not await _t6b_open("campaign", "continue"): return
	_check(_fp_snapshot_chips() == _fp_disk_chips() and _fp_snapshot_chips() > chips_on_disk, "D: Fortsetzen hat die Ausruestung (Chips im Stand %d)" % _fp_snapshot_chips())

# ---------- E: Speichern im Flug wird vorgemerkt ----------

func _fp_e() -> void:
	if await _fp_ready_to_launch("E") != "": return
	if await _fp_launch_to_moon_orbit("E") != "": return
	var guard: Dictionary = _flow.get("_campaign_start").call("get_home_checkpoint_guard", _flow, _runtime)
	print("FP_E_GUARD_IN_FLIGHT ", guard)
	# Im Flug meldet zuerst der Welt-Schutz (world_active, "Waehrend der Reise"); kommt der Basis-Schutz an die Reihe, nennt er den Flug.
	_check(String(guard.get("reason", "")) == "world_active" or (String(guard.get("reason", "")) == "away_from_checkpoint" and String(guard.get("detail", "")) == "flight"), "E S0: im Flug nennt der Schutz die Reise bzw. den Flug (%s)" % [guard])
	var successes_before := _fp_successes()
	var plain: Dictionary = _flow.call("request_campaign_save")
	_check(not bool(plain.get("ok", true)) and not bool(plain.get("pending", false)), "E: Fixture: der einfache Speicherruf im Flug merkt nichts vor (Grund %s)" % plain.get("reason", ""))
	_check(Dictionary(_flow.call("get_pending_save_wish")).is_empty(), "E: Fixture: noch kein Speicherwunsch")
	var wished: Dictionary = _flow.call("request_player_save")
	_check(not bool(wished.get("ok", true)) and bool(wished.get("pending", false)), "E: Speichern im Flug: nicht gespeichert, aber vorgemerkt (%s)" % [wished])
	_check(String(wished.get("message", "")).begins_with("Speichern vorgemerkt: "), "E: die Antwort sagt 'Speichern vorgemerkt: ...' (%s)" % wished.get("message", ""))
	_check(String(_flow.get_meta("campaign_save_feedback", "")) == String(wished.get("message", "")), "E: die sichtbare Rueckmeldung zeigt denselben Satz")
	_check(not Dictionary(_flow.call("get_pending_save_wish")).is_empty(), "E: der Wunsch ist gemerkt")
	var again: Dictionary = _flow.call("request_player_save")
	_check(bool(again.get("pending", false)), "E: ein zweiter Druck merkt denselben Wunsch, ohne einen zweiten anzulegen")
	if not _check(await _pk_wait(func(): return String(_pk_space().get("phase", "")) == "orbit" and String(_pk_space().get("orbit_id", "")) == "moon_orbit", 120000), "E: Ankunft im Mondorbit"): return
	_check(_fp_successes() == successes_before, "E: waehrend des Fluges wurde nichts gespeichert")
	var result: Dictionary = _pk_op("space_land_homebase")
	if not _check(bool(result.get("ok", false)), "E: Landung an der Heimatbasis angefordert (%s)" % [result]): return
	if not _check(await _pk_wait(func(): return _fp_craft_home(), 90000), "E: das Schiff ist wieder daheim"): return
	_check(await _pk_wait(func(): return _fp_successes() > successes_before, 30000), "E: nach der Landung wird gespeichert (gelungen +%d)" % (_fp_successes() - successes_before))
	_check(await _pk_wait(func(): return Dictionary(_flow.call("get_pending_save_wish")).is_empty(), 5000), "E: der Wunsch ist erledigt")
	await _pk_wait(func(): return false, 3000)
	_check(_fp_successes() - successes_before == 1, "E: genau ein Schreibvorgang fuer Landung und Wunsch zusammen (+%d)" % (_fp_successes() - successes_before))
	_check(String(_flow.get_meta("campaign_save_feedback", "")) == "Kampagne gespeichert.", "E: danach erscheint 'Kampagne gespeichert.' (%s)" % _flow.get_meta("campaign_save_feedback", ""))
	# Der Wunsch verfaellt beim Laden: ein neu geoeffneter Flow hat keinen.
	var flight_wish: Dictionary = _flow.call("request_player_save")
	_check(bool(flight_wish.get("ok", false)) and Dictionary(_flow.call("get_pending_save_wish")).is_empty(), "E: Gegenprobe daheim: Speichern klappt sofort und merkt nichts vor")

# ---------- F: Taste F5 ----------

func _fp_f_event(echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_F5
	event.physical_keycode = KEY_F5
	event.pressed = true
	event.echo = echo
	return event

func _fp_f() -> void:
	if not await _t6b_open("campaign", "new"): return
	var menu: Node = root.get_node_or_null("GlobalEscapeMenu")
	if not _check(menu != null, "F: Menue-Autoload vorhanden"): return
	menu.call("set_test_mode", true)
	_check(InputMap.has_action("campaign_quick_save") and InputMap.action_get_events("campaign_quick_save").any(func(event: InputEvent) -> bool: return event is InputEventKey and (event as InputEventKey).keycode == KEY_F5), "F: es gibt eine Eingabeaktion campaign_quick_save auf F5")
	var disk_before := FileAccess.get_sha256(FP_STORE.DEFAULT_PATH)
	_check(_fp_grant_chip("fp:f:chip"), "F: Fixture: Aenderung seit dem letzten Speichern")
	_check(FileAccess.get_sha256(FP_STORE.DEFAULT_PATH) == disk_before, "F: Fixture: die Aenderung ist noch nicht auf der Platte")
	var attempts_before := _fp_attempts()
	menu.call("_input", _fp_f_event())
	var f5_attempts := _fp_attempts() - attempts_before
	_check(f5_attempts == 1, "F: F5 loest genau einen Speicherversuch aus (+%d)" % f5_attempts)
	_check(FileAccess.get_sha256(FP_STORE.DEFAULT_PATH) != disk_before, "F: F5 hat die Aenderung auf die Platte gespeichert")
	# Derselbe Weg wie der Menuepunkt: _on_save_pressed ruft ebenfalls genau einmal request_player_save.
	attempts_before = _fp_attempts()
	menu.call("_on_save_pressed")
	_check(_fp_attempts() - attempts_before == f5_attempts, "F: der Menuepunkt loest dieselbe Zahl von Versuchen aus wie F5 (+%d)" % (_fp_attempts() - attempts_before))
	_check(String(_flow.get_meta("campaign_save_feedback", "")) == "Kampagne gespeichert.", "F: ohne offenes Menue kommt die Zeile 'Kampagne gespeichert.' (%s)" % _flow.get_meta("campaign_save_feedback", ""))
	var toast: Node = _flow.get_node_or_null("CampaignSaveToast")
	_check(toast != null and bool(toast.call("is_showing")) and String(toast.call("get_text")) == "Kampagne gespeichert.", "F: die Rueckmeldung steht am Bildschirmrand")
	_check(toast != null and toast.call("fangt_keine_eingabe"), "F: die Zeile faengt keine Eingabe (alle Steuerelemente ignorieren die Maus)")
	# Wiederholte Tastenmeldung (echo) loest nichts aus.
	attempts_before = _fp_attempts()
	menu.call("_input", _fp_f_event(true))
	_check(_fp_attempts() == attempts_before, "F: eine Tastenwiederholung (echo) speichert nicht")
	# In einer Texteingabe nicht.
	var edit := LineEdit.new()
	root.add_child(edit)
	edit.grab_focus()
	await process_frame
	menu.call("_input", _fp_f_event())
	_check(_fp_attempts() == attempts_before, "F: in einer Texteingabe loest F5 nichts aus")
	edit.queue_free()
	await process_frame
	# Der Toast verschwindet nach einigen Sekunden von selbst.
	if toast != null:
		_check(await _pk_wait(func(): return not bool(toast.call("is_showing")), 12000), "F: die Zeile verschwindet nach einigen Sekunden")

# ---------- G: Saetze ----------

func _fp_g() -> void:
	var generic := "Dieser Zustand kann momentan nicht sicher gespeichert werden."
	var cases: Array = [
		["active_restore_pending", ""], ["campaign_load_failed", ""], ["cargo_transfer_active", ""], ["recruitment_pending", ""],
		["shuttle_pending", ""], ["shuttle_active", ""], ["world_active", ""],
		["checkpoint_clock_unsynced", ""], ["checkpoint_pending_work", ""], ["checkpoint_pending_selection", ""], ["checkpoint_pending_setup", ""],
		["checkpoint_pending_respawn", ""], ["checkpoint_owner_unavailable", ""],
		["ground_save_not_configured", ""], ["ground_save_terrain_revalidation_pending", ""], ["ground_save_pending_admission", ""], ["ground_save_topology_pending", ""],
		["base_checkpoint_transport_pending", ""], ["base_checkpoint_admission_pending", ""], ["movement_save_pending_stop", ""],
		["away_from_checkpoint", "flight"], ["away_from_checkpoint", "place"], ["preparation_in_progress", ""], ["campaign_craft_count", ""],
		["runtime_unavailable", ""], ["base_checkpoint_aboard_context", "home"], ["checkpoint_recruit_presence_missing", ""],
		["home_hex_checkpoint_unsupported", ""], ["hex_checkpoint_api_unavailable", ""],
		["base_checkpoint_station_context", ""], ["base_checkpoint_invalid_unit", ""], ["base_checkpoint_ground_presence", ""], ["base_checkpoint_bed_pose", ""],
		["mission_identity_mismatch", ""], ["mission_scenario_mismatch", ""], ["mission_crew_not_deployed", ""], ["multiple_locations_unsupported", ""],
	]
	var seen := {}
	for entry: Array in cases:
		var reason := String(entry[0])
		var detail := String(entry[1])
		var text: String = FP_PROJECTION.blocked_text(reason, detail)
		var label := "%s%s" % [reason, (" (" + detail + ")") if not detail.is_empty() else ""]
		_check(not text.is_empty() and text != generic, "G: %s hat einen eigenen Satz" % label)
		_check(text.length() <= 160, "G: %s: Satz hoechstens 160 Zeichen (%d)" % [label, text.length()])
		seen[text] = int(seen.get(text, 0)) + 1
	_check(seen.size() == cases.size(), "G: alle %d Faelle haben verschiedene Saetze (%d verschiedene)" % [cases.size(), seen.size()])
	var flight: String = FP_PROJECTION.blocked_text("away_from_checkpoint", "flight")
	var place: String = FP_PROJECTION.blocked_text("away_from_checkpoint", "place")
	_check(flight != place, "G S0: 'Schiff im Flug' und 'Schiff an anderem Ort' haben verschiedene Saetze")
	_check(not place.contains("Reise") and not place.contains("Flug") and not place.contains("unterwegs"), "G S0: der Satz fuer 'an anderem Ort' spricht nicht von Reise oder Flug (%s)" % place)
	_check(flight.contains("unterwegs") and flight.contains("gelandet"), "G S0: der Flug-Satz sagt, dass das Schiff unterwegs ist und wann gespeichert wird (%s)" % flight)
	_check(not FP_PROJECTION.blocked_text("base_checkpoint_aboard_context", "home").contains("Einsatz"), "G S0: an der Basis sagt base_checkpoint_aboard_context nicht 'Einsatz'")
	_check(FP_PROJECTION.blocked_text("base_checkpoint_aboard_context") == FP_PROJECTION.blocked_text("base_checkpoint_aboard_context", "mission"), "G: im Einsatz bleibt der bisherige Satz")
	_check(FP_PROJECTION.blocked_text("away_from_checkpoint") != generic, "G: auch ohne Zusatz kein Allerweltssatz fuer away_from_checkpoint")
	# Vormerken nur fuer Uebergangsgruende.
	for reason: String in ["away_from_checkpoint", "world_active", "preparation_in_progress", "cargo_transfer_active", "shuttle_active", "base_checkpoint_transport_pending", "movement_save_pending_stop", "checkpoint_pending_work", "active_restore_pending"]:
		_check(FP_PROJECTION.is_transient(reason), "G: %s ist ein Uebergangsgrund (wird vorgemerkt)" % reason)
		var pending: String = FP_PROJECTION.pending_text(reason, "flight")
		_check(pending.begins_with("Speichern vorgemerkt: ") and pending.length() <= 160, "G: %s: Vormerk-Satz (%s)" % [reason, pending])
	for reason: String in ["mission_lifecycle_unsupported", "mission_combat_unsupported", "home_personnel_unsupported", "mission_fleet_unsupported", "campaign_load_failed", "runtime_unavailable", "mission_identity_mismatch", "unbekannter_grund"]:
		_check(not FP_PROJECTION.is_transient(reason), "G: %s ist kein Uebergangsgrund (keine Vormerkung, es gilt der zuletzt gespeicherte Stand)" % reason)
