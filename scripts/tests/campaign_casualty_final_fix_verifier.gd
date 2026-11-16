extends "res://scripts/tests/campaign_casualty_departure_verifier.gd"
## Gesamtpruefung Ausfall und Rueckzug: Befunde, die in keinen vorhandenen Test passen.
## I2: Wer einen Einsatz-Autosave fortsetzt, spielt den Rest des Einsatzes mit den Ausfallregeln: Der Schalter am Driver ist gesetzt,
##     das Aufricht-Fenster ist das der Regeln (nicht der Vorgabewert 3 s), der Controller hat das Abflug-Gate, und ein Ausfall
##     erzeugt den Merker was_downed. Echter Kampagneneinsatz, Speichern ueber den Besitzer, Szene neu aufbauen, Fortsetzen.
## Nicht abgedeckt (bekannte Luecke): Die Merker was_downed selbst stehen nicht im Autosave.

const DEFAULT_WINDOW := 3.0

func _run() -> void:
	_configure_entry()
	await _i2_resume_keeps_rules()
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
