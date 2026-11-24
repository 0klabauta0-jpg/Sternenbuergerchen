extends SceneTree
## Prüft den Kampagnenschalter am Combat-Driver: ohne Schalter Skirmish-Verhalten
## (Bleedout, Respawn), mit Schalter kein Respawn eigener Einheiten, Versorgungsfrist
## und das Merkmal was_downed. Echter Driver, echte TestUnit, echter RespawnManager.

const FRIEND_ID := "friend_01"
const ENEMY_ID := "enemy_01"

var passed := 0
var failed := 0
var _ran := false


func _process(_delta: float) -> bool:
	# Erst im laufenden Baum (nicht in _initialize), damit Audio und Multiplayer des Drivers bereitstehen.
	if _ran:
		return true
	_ran = true
	_case_switch_off_skirmish_respawns()
	_case_switch_on_no_respawn_inside_window()
	_case_switch_on_medic_revive_flagged()
	_case_switch_on_window_zero_bleedout_no_respawn()
	_case_switch_on_enemy_still_respawns()
	_case_unconnected_unit_flagged_by_tick()
	_case_unconnected_unit_heal_resets_window()
	_case_switch_off_unconnected_unit_not_flagged()
	print("CAMPAIGN_CASUALTY_DRIVER passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
	return true


func _build(campaign_on: bool, window_seconds: float, unconnected_friend: bool = false) -> Dictionary:
	var fixture := Node.new()
	var driver = load("res://scripts/tests/mission_combat_loop_driver.gd").new()
	var friend = load("res://scripts/npc/test_unit.gd").new()
	var enemy = load("res://scripts/npc/test_unit.gd").new()
	var respawn = load("res://scripts/core/respawn_manager.gd").new()
	var registry := _make_stub("extends Node\nvar units := {}\nfunc get_unit(id):\n\treturn units.get(id)\n")
	var sim := _make_stub("extends Node\nvar effects := []\nfunc enqueue_effect(e):\n\teffects.append(e)\n")
	driver.name = "Driver"
	friend.name = "Friend"
	enemy.name = "Enemy"
	respawn.name = "Respawn"
	registry.name = "Registry"
	sim.name = "Sim"
	for node in [driver, friend, enemy, respawn, registry, sim]:
		fixture.add_child(node)
	# Im Baum, damit der Driver sein Multiplayer-Objekt hat (Event-Broadcast prüft den Peer).
	root.add_child(fixture)
	friend.set("unit_id", FRIEND_ID)
	friend.set("team_id", "team_alpha")
	enemy.set("unit_id", ENEMY_ID)
	enemy.set("team_id", "team_bravo")
	registry.units[FRIEND_ID] = friend
	registry.units[ENEMY_ID] = enemy
	respawn.set("unit_registry_path", NodePath("../Registry"))
	driver.set("respawn_manager_path", NodePath("../Respawn"))
	var friendly_paths: Array[NodePath] = [NodePath("../Friend")]
	var enemy_paths: Array[NodePath] = [NodePath("../Enemy")]
	driver.set("friendly_unit_paths", friendly_paths)
	driver.set("enemy_unit_paths", enemy_paths)
	driver.set("_hotpath_unit_cache_active", true)
	driver.set("_hotpath_friendly_units", [friend])
	driver.set("_hotpath_enemy_units", [enemy])
	if campaign_on:
		driver.set("campaign_casualty_rules_enabled", true)
		driver.set("down_revive_window_seconds", window_seconds)
	driver.call("_connect_unit_signals")
	if unconnected_friend:
		# Wie im Kampagneneinsatz: Einheit wurde nach _ready() registriert, der Driver hat keine Verbindung.
		for signal_name in ["vital_status_changed", "damage_applied", "healed_applied"]:
			for connection in friend.get_signal_connection_list(signal_name):
				if connection["callable"].get_object() == driver:
					friend.disconnect(signal_name, connection["callable"])
	return {"fixture": fixture, "driver": driver, "friend": friend, "enemy": enemy, "respawn": respawn, "sim": sim}


func _make_stub(source: String) -> Node:
	var script := GDScript.new()
	script.source_code = source
	script.reload()
	return script.new()


func _age_down_state(driver, unit_id: String, seconds: float) -> void:
	var started: Dictionary = driver.get("_down_state_started_tick_by_unit_id")
	started[unit_id] = int(driver.get("_current_tick")) - int(seconds * 60.0) # Spielzeit: 60 Ticks je Sekunde


func _bleedout_effects(sim) -> int:
	var count := 0
	for effect in sim.effects:
		if String(effect.get("effect_type", "")) == "bleedout":
			count += 1
	return count


func _case_switch_off_skirmish_respawns() -> void:
	var env := _build(false, 60.0)
	var driver = env.driver
	var friend = env.friend
	friend.call("apply_damage", 1000, {})
	_check(friend.call("get_vital_state") == "down", "switch off: unit at 0 HP is down")
	driver.call("_queue_bleedout_for_downed_friendly", env.sim)
	_check(_bleedout_effects(env.sim) == 0, "switch off: no bleedout right after going down")
	_age_down_state(driver, FRIEND_ID, 3.5)
	driver.call("_queue_bleedout_for_downed_friendly", env.sim)
	_check(_bleedout_effects(env.sim) == 0, "switch off: still no bleedout after 3.5 s (the old 3 s constant is gone; stages start at 180 s)")
	_age_down_state(driver, FRIEND_ID, 390.5)
	driver.call("_queue_bleedout_for_downed_friendly", env.sim)
	_check(_bleedout_effects(env.sim) == 1, "switch off: bleedout queued after 390 s at the latest (last stage is certain)")
	friend.call("advance_bleedout")
	_check(env.respawn.call("has_pending_respawn", FRIEND_ID), "skirmish still respawns")
	# Björn 21.11.: Wiederkehr-Zeiten verlängert (Rover 60, FOB 240, Homebase 420 Sekunden; vorher 30/150/270).
	_check(is_equal_approx(float(env.respawn.call("get_respawn_time", "rover")), 60.0) and is_equal_approx(float(env.respawn.call("get_respawn_time", "fob")), 240.0) and is_equal_approx(float(env.respawn.call("get_respawn_time", "homebase")), 420.0), "skirmish respawn times are 60/240/420 s")
	_check(float(env.respawn.call("get_remaining_time", FRIEND_ID)) > 30.0, "skirmish rover respawn countdown is longer than the old 30 s")
	_check(friend.call("get_vital_state") == "respawning", "switch off: unit enters respawning")
	var states: Array = driver.call("_build_team_states", driver.get("friendly_unit_paths"))
	_check(states.size() == 1 and not Dictionary(states[0]).has("was_downed"), "switch off: team state has no was_downed key")
	_check(Dictionary(states[0]).keys().size() == 4, "switch off: team state keeps the four old fields")
	env.fixture.free()


func _case_switch_on_no_respawn_inside_window() -> void:
	var env := _build(true, 60.0)
	var driver = env.driver
	var friend = env.friend
	friend.call("apply_damage", 1000, {})
	_age_down_state(driver, FRIEND_ID, 5.0)
	driver.call("_queue_bleedout_for_downed_friendly", env.sim)
	_check(friend.call("get_vital_state") == "down", "campaign: still down after 5 s (first stage only at 180 s)")
	_check(_bleedout_effects(env.sim) == 0, "campaign: no bleedout queued before the first stage")
	driver.call("_request_respawn_for_unit", friend, FRIEND_ID)
	_check(not env.respawn.call("has_pending_respawn", FRIEND_ID), "no respawn in campaign")
	_check(friend.call("get_vital_state") == "down", "campaign: respawn request does not touch the unit")
	env.fixture.free()


func _case_switch_on_medic_revive_flagged() -> void:
	var env := _build(true, 60.0)
	var driver = env.driver
	var friend = env.friend
	var flags_before: Dictionary = driver.call("get_casualty_flags")
	_check(flags_before.has(FRIEND_ID) and flags_before[FRIEND_ID].was_downed == false, "campaign: fit unit not flagged")
	friend.call("apply_damage", 1000, {})
	_age_down_state(driver, FRIEND_ID, 5.0)
	_check(friend.call("apply_heal", 10, {}), "campaign: heal on downed unit accepted")
	_check(friend.call("get_vital_state") == "fit", "medic revive inside the window: fit again")
	var flags: Dictionary = driver.call("get_casualty_flags")
	_check(flags.has(FRIEND_ID) and flags[FRIEND_ID].was_downed == true, "medic revive inside the window, flagged")
	var states: Array = driver.call("_build_team_states", driver.get("friendly_unit_paths"))
	_check(states.size() == 1 and Dictionary(states[0]).get("was_downed", false) == true, "campaign: team state carries was_downed true")
	env.fixture.free()


func _case_switch_on_window_zero_bleedout_no_respawn() -> void:
	var env := _build(true, 0.0)
	var driver = env.driver
	var friend = env.friend
	friend.call("apply_damage", 1000, {})
	driver.call("_queue_bleedout_for_downed_friendly", env.sim)
	_check(_bleedout_effects(env.sim) == 0, "window 0: the old window no longer decides, nothing queued at once")
	_age_down_state(driver, FRIEND_ID, 390.5)
	driver.call("_queue_bleedout_for_downed_friendly", env.sim)
	_check(_bleedout_effects(env.sim) == 1, "window 0: bleedout queued at 390 s at the latest")
	friend.call("advance_bleedout")
	_check(friend.call("get_vital_state") == "bleedout", "window 0: unit is bleedout")
	_check(not env.respawn.call("has_pending_respawn", FRIEND_ID), "window 0: no respawn")
	driver.call("_queue_bleedout_for_downed_friendly", env.sim)
	_check(friend.call("get_vital_state") == "bleedout", "window 0: stays bleedout")
	_check(not env.respawn.call("has_pending_respawn", FRIEND_ID), "window 0: still no respawn")
	var states: Array = driver.call("_build_team_states", driver.get("friendly_unit_paths"))
	_check(states.size() == 1 and Dictionary(states[0]).get("was_downed", false) == true, "window 0: team state was_downed true")
	_check(Dictionary(states[0]).get("vital_state", "") == "bleedout", "window 0: team state shows bleedout")
	env.fixture.free()


func _case_switch_on_enemy_still_respawns() -> void:
	var env := _build(true, 60.0)
	var driver = env.driver
	var enemy = env.enemy
	enemy.call("apply_damage", 1000, {})
	_check(enemy.call("get_vital_state") == "down", "campaign: enemy at 0 HP is down")
	_age_down_state(driver, ENEMY_ID, 3.5)
	driver.call("_queue_bleedout_for_downed_enemy", env.sim)
	_check(_bleedout_effects(env.sim) == 0, "campaign: enemy follows the same stages, no bleedout after 3.5 s")
	_age_down_state(driver, ENEMY_ID, 390.5)
	driver.call("_queue_bleedout_for_downed_enemy", env.sim)
	_check(_bleedout_effects(env.sim) == 1, "campaign: enemy bleedout queued at 390 s at the latest")
	enemy.call("advance_bleedout")
	_check(env.respawn.call("has_pending_respawn", ENEMY_ID), "campaign: enemy respawns as before")
	var flags: Dictionary = driver.call("get_casualty_flags")
	_check(not flags.has(ENEMY_ID), "campaign: enemies are not part of casualty flags")
	env.fixture.free()


func _case_unconnected_unit_flagged_by_tick() -> void:
	var env := _build(true, 60.0, true)
	var driver = env.driver
	var friend = env.friend
	_check(friend.get_signal_connection_list("vital_status_changed").is_empty(), "unconnected: driver has no vital_status_changed connection")
	friend.call("apply_damage", 1000, {})
	_check(not Dictionary(driver.call("get_casualty_flags"))[FRIEND_ID].was_downed, "unconnected: signal path alone does not flag")
	driver.call("_queue_bleedout_for_downed_friendly", env.sim)
	var flags: Dictionary = driver.call("get_casualty_flags")
	_check(flags.has(FRIEND_ID) and flags[FRIEND_ID].was_downed == true, "unconnected: tick flags was_downed")
	env.fixture.free()


func _case_unconnected_unit_heal_resets_window() -> void:
	var env := _build(true, 60.0, true)
	var driver = env.driver
	var friend = env.friend
	friend.call("apply_damage", 1000, {})
	driver.call("_queue_bleedout_for_downed_friendly", env.sim)
	_age_down_state(driver, FRIEND_ID, 5.0)
	_check(friend.call("apply_heal", 10, {}), "unconnected: heal inside window accepted")
	driver.call("_queue_bleedout_for_downed_friendly", env.sim)
	var started: Dictionary = driver.get("_down_state_started_tick_by_unit_id")
	_check(not started.has(FRIEND_ID), "unconnected: tick clears the linger timestamp of a revived unit")
	friend.call("apply_damage", 1000, {})
	driver.call("_queue_bleedout_for_downed_friendly", env.sim)
	_check(friend.call("get_vital_state") == "down", "unconnected: downed again, still down")
	_check(_bleedout_effects(env.sim) == 0, "unconnected: no bleedout, the clock starts anew")
	env.fixture.free()


func _case_switch_off_unconnected_unit_not_flagged() -> void:
	var env := _build(false, 60.0, true)
	var driver = env.driver
	env.friend.call("apply_damage", 1000, {})
	driver.call("_queue_bleedout_for_downed_friendly", env.sim)
	_check(Dictionary(driver.get("_was_downed_unit_ids")).is_empty(), "switch off: tick flags nothing")
	var states: Array = driver.call("_build_team_states", driver.get("friendly_unit_paths"))
	_check(states.size() == 1 and Dictionary(states[0]).keys().size() == 4 and not Dictionary(states[0]).has("was_downed"), "switch off, unconnected: team state keeps four old fields")
	env.fixture.free()


func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		printerr("FAIL: ", label)
