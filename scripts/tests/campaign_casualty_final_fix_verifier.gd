extends "res://scripts/tests/campaign_casualty_departure_verifier.gd"
## Gesamtpruefung Ausfall und Rueckzug: Befunde, die in keinen vorhandenen Test passen.
## I2: Wer einen Einsatz-Autosave fortsetzt, spielt den Rest des Einsatzes mit den Ausfallregeln: Der Schalter am Driver ist gesetzt,
##     das Aufricht-Fenster ist das der Regeln (nicht der Vorgabewert 3 s), der Controller hat das Abflug-Gate, und ein Ausfall
##     erzeugt den Merker was_downed. Echter Kampagneneinsatz, Speichern ueber den Besitzer, Szene neu aufbauen, Fortsetzen.
## I3: Die Merker was_downed stehen im Autosave. Wer ausfiel und aufgerichtet wurde, hat nach Speichern/Fortsetzen denselben
##     Merker (und wer nie am Boden lag, keinen); das Einsatzende wertet ihn als leicht verwundet mit der Zeit aus den Regeln.
## I4: Zustand des Lifecycle-Eintrags: alter Stand ohne das Feld laedt (Merker leer), Unsinn im Feld wird abgelehnt,
##     Export und Import des Drivers sind verlustfrei. Dazu eine Messung (ohne Anspruch): was der Autosave bei einer Liegenden tut.

const DEFAULT_WINDOW := 3.0
const LIFECYCLE_SCRIPT := "res://scripts/mission/stable_mission_lifecycle_checkpoint.gd"

func _run() -> void:
	_configure_entry()
	await _i2_resume_keeps_rules()
	await _i3_flags_survive_resume()
	await _i4_lifecycle_flag_field()
	print("CAMPAIGN_CASUALTY_FINAL_FIX passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)

## Wie _begin_sortie, aber mit einem erzwungenen Basis-Speicherpunkt vor dem Start: Der Einsatz-Autosave wird gegen den
## gespeicherten Basisstand geprueft (Ausruestung, Trupps) und braucht deshalb einen aktuellen.
func _begin_saveable_sortie() -> Dictionary:
	START.request_start(self, "campaign", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	if not await _prepare_initial_base(): return {}
	_crew_ids = ["campaign_leader"]
	_pilot_id = "campaign_pilot"
	var home_saved: Dictionary = _flow.get("_campaign_start").call("save_home_checkpoint", _flow, _runtime, true)
	if not _check(bool(home_saved.get("ok", false)), "Aufbau: Basis-Speicherpunkt vor dem Start (%s)" % [home_saved.get("reason", "")]): return {}
	_check(_screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false), "Accept actual job")
	_check(_screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}).get("ok", false), "Choose actual location")
	if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"): return {}
	var mission: Node = _flow.get("_active_mission")
	var controller: Node = mission.get_node("TacticalController")
	var sortie: Dictionary = {"mission": mission, "controller": controller, "driver": mission.get_node("CombatLoopDriver")}
	if not _check(controller.call("_get_campaign_sortie_unit", "campaign_leader") != null, "Der Truppfuehrer ist im Einsatz"): return {}
	return sortie

func _i2_resume_keeps_rules() -> void:
	var s: Dictionary = await _begin_saveable_sortie()
	if s.is_empty(): return
	var rules: Dictionary = Dictionary(_flow.call("_get_campaign_casualty_rules"))
	var window: float = float(rules.get("down_revive_window_seconds", 0.0))
	if not _check(window > DEFAULT_WINDOW, "I2: Fixture: die Regeln kennen ein Aufricht-Fenster ueber dem Vorgabewert (%s s)" % [window]): return
	_check(bool(s.driver.get("campaign_casualty_rules_enabled")) and is_equal_approx(float(s.driver.get("down_revive_window_seconds")), window) and Callable(s.controller.get("_campaign_departure_gate")).is_valid(), "I2: vor dem Speichern: Schalter, Fenster und Gate sind am frischen Einsatz gesetzt")
	var capture = load("res://scripts/mission/campaign_active_mission_capture.gd")
	var ready: Dictionary = capture.capture_components(_flow, _runtime)
	var deadline := Time.get_ticks_msec() + 30000
	while not ready.get("ok", false) and Time.get_ticks_msec() < deadline and String(ready.get("reason", "")) in ["checkpoint_pending_work", "checkpoint_clock_unsynced", "checkpoint_pending_setup", "mission_lifecycle_busy", "mission_movement_pending", "transport_transition_pending"]:
		await create_timer(0.1).timeout
		ready = capture.capture_components(_flow, _runtime)
	if not _check(ready.get("ok", false), "I2: der Einsatz erreicht einen speicherbaren Zustand"):
		print("I2_CAPTURE_FAILURE ", ready)
		return
	var saved: Dictionary = _flow.call("request_campaign_save")
	if not _check(bool(saved.get("ok", false)), "I2: Einsatz-Autosave wird ueber den Besitzer geschrieben"):
		print("I2_SAVE_FAILURE ", saved)
		return
	_flow.queue_free()
	await process_frame
	START.request_start(self, "campaign", "continue")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	if not await _wait(func(): return bool(_flow.get_meta("campaign_active_restore_complete", false)) or _flow.has_meta("campaign_active_restore_error"), 60000, "I2: das Fortsetzen erreicht ein Ergebnis"): return
	if not _check(bool(_flow.get_meta("campaign_active_restore_complete", false)) and is_instance_valid(_flow.get("_active_mission")), "I2: der Einsatz ist wiederhergestellt"):
		print("I2_RESTORE_FAILURE ", _flow.get_meta("campaign_active_restore_error", {}))
		return
	var restored: Node = _flow.get("_active_mission")
	var driver: Node = restored.get_node("CombatLoopDriver")
	var controller: Node = restored.get_node("TacticalController")
	var resumed_rules: Dictionary = Dictionary(_flow.call("_get_campaign_casualty_rules"))
	var resumed_window: float = float(resumed_rules.get("down_revive_window_seconds", 0.0))
	print("I2_RESTORED enabled=", driver.get("campaign_casualty_rules_enabled"), " window=", driver.get("down_revive_window_seconds"), " gate_valid=", Callable(controller.get("_campaign_departure_gate")).is_valid())
	_check(bool(driver.get("campaign_casualty_rules_enabled")), "I2: nach dem Fortsetzen ist der Schalter am Driver gesetzt")
	_check(is_equal_approx(float(driver.get("down_revive_window_seconds")), resumed_window) and resumed_window > DEFAULT_WINDOW, "I2: nach dem Fortsetzen gilt das Aufricht-Fenster der Regeln (%s s), nicht der Vorgabewert" % [resumed_window])
	_check(Callable(controller.get("_campaign_departure_gate")).is_valid(), "I2: nach dem Fortsetzen hat der Controller das Abflug-Gate")
	# Wirkung: ein Ausfall erzeugt den Merker was_downed (ohne den Schalter entsteht er nicht).
	var leader: Node2D = controller.call("_get_campaign_sortie_unit", "campaign_leader")
	if not _check(leader != null, "I2: der Truppfuehrer ist im wiederhergestellten Einsatz"): return
	leader.call("apply_damage", 10000)
	_check(await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)), 5000, "I2: ein Ausfall nach dem Fortsetzen erzeugt was_downed"), "I2: was_downed entsteht nach dem Fortsetzen")
	await _end_sortie()


const CAPTURE_RETRY_REASONS := ["checkpoint_pending_work", "checkpoint_clock_unsynced", "checkpoint_pending_setup", "mission_lifecycle_busy", "mission_movement_pending", "transport_transition_pending"]

## Wartet, bis der Einsatz speicherbar ist (wie in I2); liefert das Ergebnis von capture_components.
func _capture_ready(tag: String) -> Dictionary:
	var capture = load("res://scripts/mission/campaign_active_mission_capture.gd")
	var ready: Dictionary = capture.capture_components(_flow, _runtime)
	var deadline := Time.get_ticks_msec() + 30000
	while not ready.get("ok", false) and Time.get_ticks_msec() < deadline and String(ready.get("reason", "")) in CAPTURE_RETRY_REASONS:
		await create_timer(0.1).timeout
		ready = capture.capture_components(_flow, _runtime)
	if not _check(ready.get("ok", false), "%s: der Einsatz erreicht einen speicherbaren Zustand" % tag):
		print(tag, "_CAPTURE_FAILURE ", ready)
	return ready

## Truppfuehrer faellt aus und wird aufgerichtet; wartet, bis der Driver die Frist des Liegens abgeraeumt hat (sonst ist der Einsatz nicht speicherbar).
func _down_and_revive_leader(tag: String, s: Dictionary) -> bool:
	var leader: Node2D = s.controller.call("_get_campaign_sortie_unit", "campaign_leader")
	var driver: Node = s.driver
	leader.call("apply_damage", 10000)
	if not await _wait(func(): return bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)), 5000, tag + ": Treiber merkt sich die ausgefallene Person"): return false
	_check(String(leader.call("get_vital_state")) != "fit", tag + ": Truppfuehrer liegt")
	_check(bool(leader.call("apply_heal", 10, {})) and String(leader.call("get_vital_state")) == "fit", tag + ": innerhalb der Frist aufgerichtet")
	return await _wait(func(): return Dictionary(driver.get("_down_state_started_msec_by_unit_id")).is_empty() and Dictionary(driver.get("_queued_bleedout_by_unit_id")).is_empty(), 5000, tag + ": der Driver hat das Liegen abgeraeumt")

func _i3_flags_survive_resume() -> void:
	var s: Dictionary = await _begin_saveable_sortie()
	if s.is_empty(): return
	if not await _down_and_revive_leader("I3", s): return
	var before: Dictionary = Dictionary(s.driver.call("get_casualty_flags")).duplicate(true)
	_check(bool(before.get("campaign_leader", {}).get("was_downed", false)) and not bool(before.get("campaign_pilot", {}).get("was_downed", true)), "I3: vor dem Speichern: Truppfuehrer hat den Merker, der Pilot (nie am Boden) nicht")
	var ready: Dictionary = await _capture_ready("I3")
	if not ready.get("ok", false): return
	var saved: Dictionary = _flow.call("request_campaign_save")
	if not _check(bool(saved.get("ok", false)), "I3: Einsatz-Autosave wird ueber den Besitzer geschrieben"):
		print("I3_SAVE_FAILURE ", saved)
		return
	_flow.queue_free()
	await process_frame
	START.request_start(self, "campaign", "continue")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	current_scene = _flow
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	if not await _wait(func(): return bool(_flow.get_meta("campaign_active_restore_complete", false)) or _flow.has_meta("campaign_active_restore_error"), 60000, "I3: das Fortsetzen erreicht ein Ergebnis"): return
	if not _check(bool(_flow.get_meta("campaign_active_restore_complete", false)) and is_instance_valid(_flow.get("_active_mission")), "I3: der Einsatz ist wiederhergestellt"):
		print("I3_RESTORE_FAILURE ", _flow.get_meta("campaign_active_restore_error", {}))
		return
	var mission: Node = _flow.get("_active_mission")
	var driver: Node = mission.get_node("CombatLoopDriver")
	var controller: Node = mission.get_node("TacticalController")
	var after: Dictionary = Dictionary(driver.call("get_casualty_flags"))
	print("I3_FLAGS before=", before, " after=", after)
	_check(after == before, "I3: nach dem Fortsetzen liefert get_casualty_flags dasselbe wie vor dem Speichern")
	_check(bool(after.get("campaign_leader", {}).get("was_downed", false)), "I3: der aufgerichtete Truppfuehrer hat den Merker noch")
	_check(not bool(after.get("campaign_pilot", {}).get("was_downed", true)), "I3: Gegenprobe: der Pilot, der nie am Boden lag, hat keinen Merker")
	var simulation: Node = mission.get_node("SimulationRoot")
	var access: Dictionary = controller.call("get_campaign_ground_ship_access", _craft_id)
	if not _check(bool(access.get("ok", false)), "I3: Schiffszugang im fortgesetzten Einsatz"): return
	if not _place_at(simulation, access, "campaign_leader", Vector2.ZERO): return
	if not _place_at(simulation, access, "campaign_pilot", Vector2.ZERO): return
	driver.call("_resolve_combat", "aborted", "", "evacuation")
	if not await _wait_released("I3: Einsatz wird freigegeben"): return
	var result: Dictionary = _flow.get("_last_mission_result")
	var entry: Dictionary = _casualty_entry(result, "campaign_leader")
	print("I3_RESULT casualties=", result.get("casualties"))
	var rules: Dictionary = Dictionary(_flow.call("_get_campaign_casualty_rules"))
	var light_seconds: float = float(Dictionary(rules.get("recovery_seconds", {})).get("light", -1.0))
	_check(light_seconds > 0.0, "I3: Fixture: die Regeln kennen eine Ausfallzeit fuer leicht (%s s)" % [light_seconds])
	_check(String(entry.get("severity", "")) == "light" and String(entry.get("outcome", "")) == "wounded", "I3: Einsatzende: Truppfuehrer ist leicht verwundet")
	_check(is_equal_approx(float(entry.get("recovery_seconds_total", -1.0)), light_seconds), "I3: Ausfallzeit stammt aus data/singleplayer/casualty_rules.json (%s s)" % [light_seconds])
	_check(Array(result.get("casualties", [])).size() == 1 and _casualty_entry(result, "campaign_pilot").is_empty(), "I3: nur der Truppfuehrer ist verwundet, der Pilot nicht")
	var unit: Dictionary = _roster_unit("campaign_leader")
	_check(String(unit.get("availability_status", "")) == "wounded" and is_equal_approx(float(Dictionary(unit.get("recovery_state", {})).get("seconds_remaining", -1.0)), light_seconds), "I3: Kader: wounded mit der vollen Ausfallzeit")
	_check(String(_roster_unit("campaign_pilot").get("availability_status", "")) != "wounded", "I3: Kader: der Pilot ist nicht verwundet")
	await _end_sortie()

func _lifecycle_variant(life: Dictionary, mutate: Callable) -> Dictionary:
	var codec = load("res://scripts/mission/checkpoint_value_codec.gd")
	var fields: Dictionary = Dictionary(codec.decode_value(life.payload).value).duplicate(true)
	mutate.call(fields)
	var out: Dictionary = life.duplicate(true)
	out["payload"] = codec.encode_value(fields).value
	return out

func _i4_lifecycle_flag_field() -> void:
	var s: Dictionary = await _begin_saveable_sortie()
	if s.is_empty(): return
	var driver: Node = s.driver
	var sim: Node = s.mission.get_node("SimulationRoot")
	if not await _down_and_revive_leader("I4", s): return
	var ready: Dictionary = await _capture_ready("I4")
	if not ready.get("ok", false): return
	var life: Dictionary = ready.components.lifecycle
	var codec = load("res://scripts/mission/checkpoint_value_codec.gd")
	var fields: Dictionary = Dictionary(codec.decode_value(life.payload).value)
	_check(fields.has("casualty_flags") and Dictionary(fields.get("casualty_flags", {})).get("was_downed_unit_ids", []) == ["campaign_leader"], "I4: der Lifecycle-Eintrag traegt die Merker des Drivers")
	var junk_cases: Dictionary = {
		"kein Dictionary": func(f): f["casualty_flags"] = "campaign_leader",
		"Liste statt Array": func(f): f["casualty_flags"] = {"was_downed_unit_ids": "campaign_leader"},
		"fremde ID": func(f): f["casualty_flags"] = {"was_downed_unit_ids": ["ghost_unit"]},
		"leere ID": func(f): f["casualty_flags"] = {"was_downed_unit_ids": [""]},
		"keine Zeichenkette": func(f): f["casualty_flags"] = {"was_downed_unit_ids": [5]},
		"doppelte ID": func(f): f["casualty_flags"] = {"was_downed_unit_ids": ["campaign_leader", "campaign_leader"]},
		"zusaetzlicher Schluessel": func(f): f["casualty_flags"] = {"was_downed_unit_ids": [], "extra": 1},
		"fehlender Schluessel": func(f): f["casualty_flags"] = {},
	}
	for label: String in junk_cases:
		var bad: Dictionary = _lifecycle_variant(life, junk_cases[label])
		var prepared: Dictionary = load(LIFECYCLE_SCRIPT).new().prepare_restore(sim, driver, bad)
		_check(not bool(prepared.get("ok", false)), "I4: Unsinn im Feld wird abgelehnt (%s) [%s]" % [label, prepared.get("reason", "")])
	_check(bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)), "I4: abgelehnter Unsinn aendert die Merker nicht")
	# Alter Stand ohne das Feld: laedt, und die Merker sind danach leer.
	var old_form: Dictionary = _lifecycle_variant(life, func(f): f.erase("casualty_flags"))
	var lifecycle = load(LIFECYCLE_SCRIPT).new()
	var prepared_old: Dictionary = lifecycle.prepare_restore(sim, driver, old_form)
	if not _check(bool(prepared_old.get("ok", false)), "I4: alter Stand ohne das Feld laedt [%s]" % [prepared_old.get("reason", "")]): return
	_check(bool(lifecycle.validate_restore(prepared_old.prepared).get("ok", false)), "I4: alter Stand besteht die Pruefung vor dem Veroeffentlichen")
	lifecycle._publish_restore(prepared_old.prepared)
	_check(not bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", true)), "I4: alter Stand ohne das Feld: Merker leer")
	# Voller Stand: die Merker kommen zurueck.
	var lifecycle_new = load(LIFECYCLE_SCRIPT).new()
	var prepared_new: Dictionary = lifecycle_new.prepare_restore(sim, driver, life)
	if not _check(bool(prepared_new.get("ok", false)), "I4: Stand mit Feld laedt [%s]" % [prepared_new.get("reason", "")]): return
	lifecycle_new._publish_restore(prepared_new.prepared)
	_check(bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", false)) and not bool(Dictionary(driver.call("get_casualty_flags")).get("campaign_pilot", {}).get("was_downed", true)), "I4: Stand mit Feld: Merker des Truppfuehrers wieder da, Pilot ohne")
	# Driver-Schnittstelle selbst.
	var exported: Dictionary = driver.call("export_casualty_state")
	_check(exported == {"was_downed_unit_ids": ["campaign_leader"]}, "I4: export_casualty_state liefert die sortierte ID-Liste")
	var rejected: Dictionary = driver.call("restore_casualty_state", {"was_downed_unit_ids": ["ghost_unit"]})
	_check(not bool(rejected.get("ok", false)) and driver.call("export_casualty_state") == exported, "I4: restore_casualty_state lehnt fremde IDs ab und aendert nichts")
	_check(bool(driver.call("restore_casualty_state", {"was_downed_unit_ids": []}).get("ok", false)) and Dictionary(driver.call("get_casualty_flags")).get("campaign_leader", {}).get("was_downed", true) == false, "I4: restore_casualty_state mit leerer Liste leert die Merker")
	driver.call("restore_casualty_state", exported)
	driver.call("clear_casualty_flags")
	_check(driver.call("export_casualty_state") == {"was_downed_unit_ids": []}, "I4: clear_casualty_flags leert weiter auch den Export")
	await _probe_lying_unit(s)
	await _end_sortie()

## Messung ohne Anspruch auf ein Sollverhalten: Was tut der Einsatz-Autosave, solange jemand am Boden liegt oder kritisch ist?
func _probe_lying_unit(s: Dictionary) -> void:
	var driver: Node = s.driver
	var capture = load("res://scripts/mission/campaign_active_mission_capture.gd")
	var pilot: Node2D = s.controller.call("_get_campaign_sortie_unit", "campaign_pilot")
	driver.set("down_revive_window_seconds", 600.0)
	pilot.call("apply_damage", 10000)
	if not await _wait(func(): return Dictionary(driver.get("_down_state_started_msec_by_unit_id")).has("campaign_pilot"), 5000, "I4 Messung: der Pilot liegt (Fristbeginn gemerkt)"): return
	var lying: Dictionary = capture.capture_components(_flow, _runtime)
	print("I4_PROBE lying hp=", pilot.call("get_health"), " vital=", pilot.call("get_vital_state"), " capture_ok=", lying.get("ok"), " reason=", lying.get("reason"))
	_check(not bool(lying.get("ok", false)), "I4 Messung: solange jemand am Boden liegt, ist der Einsatz nicht speicherbar [%s]" % [lying.get("reason", "")])
	driver.set("down_revive_window_seconds", 0.3)
	if not await _wait(func(): return Dictionary(driver.get("_queued_bleedout_by_unit_id")).has("campaign_pilot"), 5000, "I4 Messung: Ablauf der Frist stoesst das Verbluten an"): return
	await create_timer(0.5).timeout
	var critical: Dictionary = capture.capture_components(_flow, _runtime)
	print("I4_PROBE critical hp=", pilot.call("get_health"), " vital=", pilot.call("get_vital_state"), " queued=", driver.get("_queued_bleedout_by_unit_id"), " capture_ok=", critical.get("ok"), " reason=", critical.get("reason"))
	_check(not bool(critical.get("ok", false)), "I4 Messung: auch eine Kritische macht den Einsatz nicht speicherbar [%s]" % [critical.get("reason", "")])
