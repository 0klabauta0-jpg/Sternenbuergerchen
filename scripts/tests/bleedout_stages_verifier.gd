extends SceneTree
## Verbluten in Stufen (24.11.2026): Wer liegt, wird bei 3:00 / 5:00 / 6:00 mit 5 / 25 / 50 % ausgewuerfelt, bei 6:30 sicher
## (data/combat/bleedout_stages.json). Gilt fuer ALLE Einheiten (eigene, spielergefuehrte, KI-Gegner). Der Wurf ist
## zustandslos (Einsatz-Seed + Einheitenkennung + Stufe). Echter Treiber, echte TestUnit; die Ticks setzt der Test direkt
## (_current_tick), wie _on_tick_processed es je Physik-Tick tut. Schlusszeile: BLEEDOUT_STAGES passed=N failed=M
const STAGES = preload("res://scripts/combat/bleedout_stages.gd")
const CHECKPOINT = preload("res://scripts/mission/stable_mission_lifecycle_checkpoint.gd")
const DRIVER_SCRIPT := preload("res://scripts/tests/mission_combat_loop_driver.gd")
const FRIEND_ID := "friend_01"
const ENEMY_ID := "enemy_01"
const T0 := 1000
const SURVIVE_TEXT := "hält durch – Zustand kritisch."

class FakeController extends Node:
	var events: Array = []
	func record_tactical_communication_event(event_type: String, context: Dictionary = {}, _options: Dictionary = {}) -> Dictionary:
		events.append({"type": event_type, "text": String(context.get("short_text", "")), "unit_id": String(context.get("unit_id", ""))})
		return {}

var passed := 0
var failed := 0
var _ran := false


func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("FAIL ", label)


func _process(_delta: float) -> bool:
	if _ran:
		return true
	_ran = true
	_case_data_file()
	_case_malformed_files_fall_back()
	_case_roll_is_stateless()
	_case_stage_one_share()
	_case_friend_timeline()
	_case_hit_on_first_stage()
	_case_enemy_follows_same_stages()
	_case_campaign_window_has_no_effect()
	_case_same_seed_same_course()
	_case_heal_ends_clock()
	_case_tick_path_queues_one_bleedout()
	_case_save_and_load()
	_case_checkpoint_blocking_list()
	_case_downed_enemies_count_as_eliminated()
	print("BLEEDOUT_STAGES passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
	return true


# ---- Hilfen ------------------------------------------------------------------------------------------------------

func _make_stub(source: String) -> Node:
	var script := GDScript.new()
	script.source_code = source
	script.reload()
	return script.new()


## Eigene Einheit (team_alpha) und Gegner (team_bravo) mit echtem Treiber; Einsatz-Seed im Stub des SimulationRoot.
func _build(mission_seed: int = 1, campaign_on: bool = false) -> Dictionary:
	var fixture := Node.new()
	var driver = DRIVER_SCRIPT.new()
	var friend = load("res://scripts/npc/test_unit.gd").new()
	var enemy = load("res://scripts/npc/test_unit.gd").new()
	var sim := _make_stub("extends Node\nvar effects := []\nvar combat_rng_seed := 1\nfunc enqueue_effect(e):\n\teffects.append(e)\n")
	var ctl := FakeController.new()
	driver.name = "Driver"
	friend.name = "Friend"
	enemy.name = "Enemy"
	sim.name = "Sim"
	ctl.name = "TacticalController"
	for node in [driver, friend, enemy, sim, ctl]:
		fixture.add_child(node)
	root.add_child(fixture)
	friend.set("unit_id", FRIEND_ID)
	friend.set("team_id", "team_alpha")
	enemy.set("unit_id", ENEMY_ID)
	enemy.set("team_id", "team_bravo")
	sim.set("combat_rng_seed", mission_seed)
	driver.set("simulation_root_path", NodePath("../Sim"))
	var friendly_paths: Array[NodePath] = [NodePath("../Friend")]
	var enemy_paths: Array[NodePath] = [NodePath("../Enemy")]
	driver.set("friendly_unit_paths", friendly_paths)
	driver.set("enemy_unit_paths", enemy_paths)
	driver.set("_hotpath_unit_cache_active", true)
	driver.set("_hotpath_friendly_units", [friend])
	driver.set("_hotpath_enemy_units", [enemy])
	if campaign_on:
		driver.set("campaign_casualty_rules_enabled", true)
	driver.set("_current_tick", T0)
	driver.call("_connect_unit_signals")
	return {"fixture": fixture, "driver": driver, "friend": friend, "enemy": enemy, "sim": sim, "ctl": ctl}


func _tick_at(seconds: float) -> int:
	return T0 + int(round(seconds * 60.0))


## Setzt die Spielzeit auf "seconds seit dem Ausfall" und fragt die Stufenentscheidung.
func _elapsed_at(env: Dictionary, unit_id: String, unit, seconds: float) -> bool:
	env.driver.set("_current_tick", _tick_at(seconds))
	return bool(env.driver.call("_has_down_state_linger_elapsed", unit_id, unit))


func _bleedout_effects(env: Dictionary) -> int:
	var count := 0
	for effect in env.sim.effects:
		if String(effect.get("effect_type", "")) == "bleedout":
			count += 1
	return count


func _survive_messages(env: Dictionary) -> Array:
	var texts: Array = []
	for event in env.ctl.events:
		if String(event.text).ends_with(SURVIVE_TEXT):
			texts.append(event)
	return texts


## Kleinster Seed (ab 1), bei dem die Stufen 0..survive_until-1 die Person NICHT erwischen und Stufe `hit_stage` trifft (-1: keine trifft bis zur letzten).
func _find_seed(unit_id: String, survive_stages: int) -> int:
	var stage_list: Array = STAGES.stages()
	for candidate in range(1, 20000):
		var ok := true
		for stage_index in range(survive_stages):
			if STAGES.stage_hits(stage_list, stage_index, candidate, unit_id):
				ok = false
				break
		if ok:
			return candidate
	return -1


func _find_hit_seed(unit_id: String) -> int:
	var stage_list: Array = STAGES.stages()
	for candidate in range(1, 20000):
		if STAGES.stage_hits(stage_list, 0, candidate, unit_id):
			return candidate
	return -1


## Sekunde (ganzzahlig) seit dem Ausfall, in der die Person verblutet; -1 wenn bis 400 s nicht.
func _bleed_second(seed_value: int, unit_id: String, enemy_side: bool = false) -> int:
	var env := _build(seed_value)
	var unit = env.enemy if enemy_side else env.friend
	unit.call("apply_damage", 1000, {})
	env.driver.set("_current_tick", T0)
	env.driver.call("_has_down_state_linger_elapsed", unit_id, unit)
	for second in range(1, 401):
		if _elapsed_at(env, unit_id, unit, float(second)):
			env.fixture.free()
			return second
	env.fixture.free()
	return -1


# ---- Datei und Pruefung ------------------------------------------------------------------------------------------

func _case_data_file() -> void:
	var stage_list: Array = STAGES.stages()
	var expected := [[180.0, 0.05], [300.0, 0.25], [360.0, 0.5], [390.0, 1.0]]
	var same: bool = stage_list.size() == expected.size()
	for index in range(mini(stage_list.size(), expected.size())):
		same = same and is_equal_approx(float(stage_list[index].at_seconds), expected[index][0]) and is_equal_approx(float(stage_list[index].chance), expected[index][1])
	_check(same, "Datei: vier Stufen 180/300/360/390 s mit 5/25/50/100 % (%s)" % str(stage_list))
	_check(STAGES.stage_ticks(stage_list[0]) == 10800 and STAGES.stage_ticks(stage_list[3]) == 23400, "Datei: 180 s = 10800 Ticks, 390 s = 23400 Ticks")


func _case_malformed_files_fall_back() -> void:
	var good := {"version": 1, "stages": [{"at_seconds": 180, "chance": 0.05}, {"at_seconds": 390, "chance": 1.0}]}
	_check(STAGES.parse_stages(good).size() == 2, "Pruefung: eine brauchbare Datei wird angenommen")
	var bad_cases := {
		"kein Dictionary": [1, 2],
		"ohne stages": {"version": 1},
		"leere stages": {"version": 1, "stages": []},
		"falsche Version": {"version": 2, "stages": [{"at_seconds": 390, "chance": 1.0}]},
		"Zeiten fallen": {"version": 1, "stages": [{"at_seconds": 300, "chance": 0.1}, {"at_seconds": 200, "chance": 1.0}]},
		"gleiche Zeiten": {"version": 1, "stages": [{"at_seconds": 300, "chance": 0.1}, {"at_seconds": 300, "chance": 1.0}]},
		"Zeit null": {"version": 1, "stages": [{"at_seconds": 0, "chance": 1.0}]},
		"Chance ueber 1": {"version": 1, "stages": [{"at_seconds": 100, "chance": 1.5}, {"at_seconds": 390, "chance": 1.0}]},
		"Chance unter 0": {"version": 1, "stages": [{"at_seconds": 100, "chance": -0.1}, {"at_seconds": 390, "chance": 1.0}]},
		"letzte Stufe nicht sicher": {"version": 1, "stages": [{"at_seconds": 100, "chance": 0.5}, {"at_seconds": 390, "chance": 0.9}]},
		"Zeit als Text": {"version": 1, "stages": [{"at_seconds": "390", "chance": 1.0}]},
		"Stufe ohne Chance": {"version": 1, "stages": [{"at_seconds": 390}]},
	}
	for label in bad_cases:
		_check(STAGES.parse_stages(bad_cases[label]).is_empty(), "Pruefung: Fehlform '%s' wird abgelehnt" % label)
	var fallback: Array = STAGES.load_stages("res://data/combat/gibt_es_nicht.json")
	_check(fallback.size() == 1 and is_equal_approx(float(fallback[0].at_seconds), 390.0) and is_equal_approx(float(fallback[0].chance), 1.0), "Rueckfall: fehlende Datei -> eine Stufe {390 s, 1.0}")
	var path := "user://bleedout_stages_bad.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{kaputt")
	file.close()
	var broken: Array = STAGES.load_stages(path)
	_check(broken.size() == 1 and is_equal_approx(float(broken[0].at_seconds), 390.0), "Rueckfall: unlesbare Datei -> eine Stufe {390 s, 1.0}")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _case_roll_is_stateless() -> void:
	var first: float = STAGES.roll(5, "u1", 0)
	_check(first >= 0.0 and first < 1.0 and first == STAGES.roll(5, "u1", 0), "Wurf: im Bereich [0,1) und bei gleichen Angaben gleich")
	var varied := false
	for stage_index in range(1, 6):
		varied = varied or STAGES.roll(5, "u1", stage_index) != first
	_check(varied and STAGES.roll(6, "u1", 0) != first and STAGES.roll(5, "u2", 0) != first, "Wurf: andere Stufe, anderer Seed oder andere Kennung geben andere Werte")
	var stage_list: Array = STAGES.stages()
	_check(STAGES.stage_hits(stage_list, 3, 1, "x") and STAGES.stage_hits(stage_list, 3, 999, "y"), "Wurf: die letzte Stufe (100 %) trifft immer")


func _case_stage_one_share() -> void:
	var stage_list: Array = STAGES.stages()
	var hits := 0
	for index in range(200):
		if STAGES.stage_hits(stage_list, 0, 3, "unit_%d" % index):
			hits += 1
	_check(hits >= 2 and hits <= 24, "Verteilung: bei 200 Kennungen verbluten in Stufe 1 zwischen 1 %% und 12 %% (%d)" % hits)


# ---- Verlauf im Treiber ------------------------------------------------------------------------------------------

## Eigene Person, Seed ueberlebt die Stufen 1-3: liegt bei 179 s noch, Stufe 1 genau bei 180 s (einmal gemeldet), liegt bis 300 s
## weiter, jede ueberstandene Stufe meldet genau einmal, bei 390 s verblutet sie sicher.
func _case_friend_timeline() -> void:
	var seed_value: int = _find_seed(FRIEND_ID, 3)
	_check(seed_value > 0, "Verlauf: Seed gefunden, bei dem die Stufen 1-3 ueberstanden werden (%d)" % seed_value)
	var env := _build(seed_value)
	var friend = env.friend
	friend.call("apply_damage", 1000, {})
	_check(friend.call("get_vital_state") == "down", "Verlauf: 0 Leben -> down")
	_check(not _elapsed_at(env, FRIEND_ID, friend, 0.0), "Verlauf: der erste Aufruf startet nur die Uhr")
	_check(not _elapsed_at(env, FRIEND_ID, friend, 3.0), "Verlauf: nach 3 s (altes Fenster) liegt sie noch")
	_check(not _elapsed_at(env, FRIEND_ID, friend, 179.0), "Verlauf: bei 179 s liegt sie noch")
	env.driver.set("_current_tick", _tick_at(180.0) - 1)
	_check(not bool(env.driver.call("_has_down_state_linger_elapsed", FRIEND_ID, friend)) and _survive_messages(env).is_empty(), "Verlauf: einen Tick vor 180 s ist Stufe 1 noch nicht ausgewertet (keine Meldung)")
	_check(not _elapsed_at(env, FRIEND_ID, friend, 180.0), "Verlauf: Stufe 1 bei genau 180 s ueberstanden")
	var messages: Array = _survive_messages(env)
	_check(messages.size() == 1 and String(messages[0].type) == "bleedout_report" and String(messages[0].unit_id) == FRIEND_ID, "Verlauf: genau eine Meldung 'hält durch' nach Stufe 1 (%s)" % str(env.ctl.events))
	var expected_name: String = String(env.driver.call("_ammo_unit_name", friend, FRIEND_ID))
	_check(not messages.is_empty() and String(messages[0].text) == "%s %s" % [expected_name, SURVIVE_TEXT], "Verlauf: Wortlaut '<Name> hält durch – Zustand kritisch.'")
	_check(not _elapsed_at(env, FRIEND_ID, friend, 180.5) and not _elapsed_at(env, FRIEND_ID, friend, 181.0) and _survive_messages(env).size() == 1, "Verlauf: dieselbe Stufe wird nicht zweimal ausgewertet oder gemeldet")
	_check(not _elapsed_at(env, FRIEND_ID, friend, 299.0) and _survive_messages(env).size() == 1, "Verlauf: bis 299 s liegt sie weiter, keine neue Meldung")
	_check(not _elapsed_at(env, FRIEND_ID, friend, 300.0) and _survive_messages(env).size() == 2, "Verlauf: Stufe 2 bei 300 s ueberstanden, zweite Meldung")
	_check(not _elapsed_at(env, FRIEND_ID, friend, 360.0) and _survive_messages(env).size() == 3, "Verlauf: Stufe 3 bei 360 s ueberstanden, dritte Meldung")
	_check(not _elapsed_at(env, FRIEND_ID, friend, 389.0), "Verlauf: bei 389 s liegt sie noch")
	_check(_elapsed_at(env, FRIEND_ID, friend, 390.0) and _survive_messages(env).size() == 3, "Verlauf: bei 390 s verblutet sie sicher (keine vierte Meldung)")
	env.fixture.free()


func _case_hit_on_first_stage() -> void:
	var seed_value: int = _find_hit_seed(FRIEND_ID)
	_check(seed_value > 0, "Treffer: Seed gefunden, bei dem Stufe 1 trifft (%d)" % seed_value)
	var env := _build(seed_value)
	env.friend.call("apply_damage", 1000, {})
	_elapsed_at(env, FRIEND_ID, env.friend, 0.0)
	_check(not _elapsed_at(env, FRIEND_ID, env.friend, 179.0), "Treffer: bei 179 s liegt sie noch")
	_check(_elapsed_at(env, FRIEND_ID, env.friend, 180.0) and _survive_messages(env).is_empty(), "Treffer: Stufe 1 trifft bei 180 s, keine 'hält durch'-Meldung")
	env.fixture.free()


func _case_enemy_follows_same_stages() -> void:
	var seed_value: int = _find_seed(ENEMY_ID, 3)
	var env := _build(seed_value)
	var enemy = env.enemy
	enemy.call("apply_damage", 1000, {})
	_elapsed_at(env, ENEMY_ID, enemy, 0.0)
	_check(not _elapsed_at(env, ENEMY_ID, enemy, 3.5) and not _elapsed_at(env, ENEMY_ID, enemy, 179.0), "KI-Gegner: nach 3,5 s und bei 179 s liegt er noch (die alten 180 Ticks gelten nicht mehr)")
	_check(not _elapsed_at(env, ENEMY_ID, enemy, 180.0) and not _elapsed_at(env, ENEMY_ID, enemy, 360.0), "KI-Gegner: ueberlebt dieselben Stufen wie eigene Leute (Seed mit drei ueberstandenen Stufen)")
	_check(env.ctl.events.is_empty(), "KI-Gegner: keine Funkmeldung fuer Gegner")
	_check(_elapsed_at(env, ENEMY_ID, enemy, 390.0), "KI-Gegner: bei 390 s verblutet er sicher")
	env.fixture.free()
	var hit_seed: int = _find_hit_seed(ENEMY_ID)
	_check(_bleed_second(hit_seed, ENEMY_ID, true) == 180, "KI-Gegner: trifft Stufe 1, verblutet er bei 180 s")


func _case_campaign_window_has_no_effect() -> void:
	var seed_value: int = _find_seed(FRIEND_ID, 3)
	var env := _build(seed_value, true)
	env.driver.set("down_revive_window_seconds", 0.0)
	env.friend.call("apply_damage", 1000, {})
	_elapsed_at(env, FRIEND_ID, env.friend, 0.0)
	_check(not _elapsed_at(env, FRIEND_ID, env.friend, 5.0) and not _elapsed_at(env, FRIEND_ID, env.friend, 179.0), "Kampagne: das alte Fenster (hier 0 s) hat keine Wirkung mehr, bei 179 s liegt sie noch")
	_check(_elapsed_at(env, FRIEND_ID, env.friend, 390.0), "Kampagne: bei 390 s verblutet sie sicher")
	env.fixture.free()


func _case_same_seed_same_course() -> void:
	var first: int = _bleed_second(77, FRIEND_ID)
	var second: int = _bleed_second(77, FRIEND_ID)
	_check(first > 0 and first == second, "Wiederholbar: gleicher Seed, gleiche Person -> gleicher Verlauf (%d s, %d s)" % [first, second])
	var every_second_ok := true
	for candidate in range(1, 30):
		var second_of_bleed: int = _bleed_second(candidate, "unit_%d" % candidate)
		every_second_ok = every_second_ok and (second_of_bleed == 180 or second_of_bleed == 300 or second_of_bleed == 360 or second_of_bleed == 390)
	_check(every_second_ok, "Wiederholbar: bei 29 Seeds verblutet jede Person genau in einer der vier Stufen (nie dazwischen, nie spaeter als 390 s)")


func _case_heal_ends_clock() -> void:
	var seed_value: int = _find_hit_seed(FRIEND_ID)
	var env := _build(seed_value)
	var friend = env.friend
	friend.call("apply_damage", 1000, {})
	_elapsed_at(env, FRIEND_ID, friend, 0.0)
	env.driver.set("_current_tick", _tick_at(100.0))
	_check(friend.call("apply_heal", 10, {}) and friend.call("get_vital_state") == "fit", "Heilung: vor der ersten Stufe geheilt -> wieder einsatzfaehig")
	_check(not Dictionary(env.driver.get("_down_state_started_tick_by_unit_id")).has(FRIEND_ID), "Heilung: die Uhr der Person ist beendet")
	friend.call("apply_damage", 1000, {})
	_check(Dictionary(env.driver.get("_down_state_started_tick_by_unit_id")).get(FRIEND_ID, -1) == _tick_at(100.0), "Heilung: faellt sie erneut aus, beginnt die Uhr neu (Tick 100 s)")
	_check(not _elapsed_at(env, FRIEND_ID, friend, 180.0), "Heilung: beim alten 180 s (nur 80 s seit dem neuen Ausfall) liegt sie noch")
	_check(not _elapsed_at(env, FRIEND_ID, friend, 279.0) and _elapsed_at(env, FRIEND_ID, friend, 280.0), "Heilung: Stufe 1 gilt 180 s nach dem NEUEN Ausfall")
	env.fixture.free()


func _case_tick_path_queues_one_bleedout() -> void:
	var seed_value: int = _find_hit_seed(FRIEND_ID)
	var env := _build(seed_value)
	env.friend.call("apply_damage", 1000, {})
	env.driver.set("_current_tick", _tick_at(179.0))
	env.driver.call("_queue_bleedout_for_downed_friendly", env.sim)
	_check(_bleedout_effects(env) == 0, "Tick-Weg: bei 179 s wird nichts eingereiht")
	env.driver.set("_current_tick", _tick_at(180.0))
	env.driver.call("_queue_bleedout_for_downed_friendly", env.sim)
	env.driver.call("_queue_bleedout_for_downed_friendly", env.sim)
	_check(_bleedout_effects(env) == 1, "Tick-Weg: bei 180 s wird das Verbluten genau einmal eingereiht (%d)" % _bleedout_effects(env))
	env.fixture.free()
	var survive_env := _build(_find_seed(FRIEND_ID, 3))
	survive_env.friend.call("apply_damage", 1000, {})
	survive_env.driver.call("_queue_bleedout_for_downed_friendly", survive_env.sim)
	survive_env.driver.set("_current_tick", _tick_at(300.0))
	survive_env.driver.call("_queue_bleedout_for_downed_friendly", survive_env.sim)
	_check(_bleedout_effects(survive_env) == 0 and survive_env.friend.call("get_vital_state") == "down", "Tick-Weg: bei ueberstandenen Stufen bleibt die Person down, nichts eingereiht")
	survive_env.fixture.free()


func _case_save_and_load() -> void:
	var seed_value: int = _find_seed(FRIEND_ID, 3)
	var allowed: Array = [FRIEND_ID, ENEMY_ID]
	var env := _build(seed_value)
	_check(env.driver.call("export_casualty_state") == {"was_downed_unit_ids": []}, "Speichern: ohne Liegende bleibt der Stand wie bisher (ein Schluessel)")
	env.friend.call("apply_damage", 1000, {})
	var state: Dictionary = env.driver.call("export_casualty_state")
	_check(state.has("down_started_ticks") and state["down_started_ticks"] == {FRIEND_ID: T0}, "Speichern: mit einer Liegenden steht ihr Ausfall-Tick im Stand (%s)" % str(state))
	_check(bool(env.driver.call("validate_casualty_state", state, allowed).get("ok", false)), "Speichern: der Stand besteht die Pruefung")
	var env2 := _build(seed_value)
	env2.driver.set("_current_tick", _tick_at(200.0))
	var restored: Dictionary = env2.driver.call("restore_casualty_state", state, allowed)
	_check(bool(restored.get("ok", false)) and Dictionary(env2.driver.get("_down_state_started_tick_by_unit_id")).get(FRIEND_ID, -1) == T0, "Laden: der Ausfall-Tick ist wieder da, dieselbe Uhr")
	_check(not bool(env2.driver.call("_has_down_state_linger_elapsed", FRIEND_ID, env2.friend)) and _survive_messages(env2).is_empty(), "Laden: die schon vergangene Stufe 1 wird still nachgerechnet, keine zweite Meldung")
	env2.driver.set("_current_tick", _tick_at(300.0))
	_check(not bool(env2.driver.call("_has_down_state_linger_elapsed", FRIEND_ID, env2.friend)) and _survive_messages(env2).size() == 1, "Laden: Stufe 2 bei 300 s laeuft normal weiter und meldet einmal")
	env2.driver.set("_current_tick", _tick_at(390.0))
	_check(bool(env2.driver.call("_has_down_state_linger_elapsed", FRIEND_ID, env2.friend)), "Laden: bei 390 s verblutet sie sicher")
	env2.fixture.free()
	var old_env := _build(seed_value)
	_check(bool(old_env.driver.call("restore_casualty_state", {"was_downed_unit_ids": []}, allowed).get("ok", false)) and Dictionary(old_env.driver.get("_down_state_started_tick_by_unit_id")).is_empty(), "Laden: ein alter Stand ohne den Schluessel laedt wie bisher")
	var bad_states := {
		"Schluessel kein Dictionary": {"was_downed_unit_ids": [], "down_started_ticks": [1, 2]},
		"Tick als Text": {"was_downed_unit_ids": [], "down_started_ticks": {FRIEND_ID: "5"}},
		"Tick negativ": {"was_downed_unit_ids": [], "down_started_ticks": {FRIEND_ID: -5}},
		"Tick Kommazahl": {"was_downed_unit_ids": [], "down_started_ticks": {FRIEND_ID: 5.5}},
		"leere Kennung": {"was_downed_unit_ids": [], "down_started_ticks": {"": 5}},
		"fremder Schluessel": {"was_downed_unit_ids": [], "other": 1},
	}
	for label in bad_states:
		_check(not bool(old_env.driver.call("validate_casualty_state", bad_states[label], allowed).get("ok", true)), "Laden: Fehlform '%s' wird abgelehnt" % label)
	var with_ghost := {"was_downed_unit_ids": [], "down_started_ticks": {FRIEND_ID: 5, "ghost_unit": 7}}
	_check(bool(old_env.driver.call("restore_casualty_state", with_ghost, allowed).get("ok", false)) and Dictionary(old_env.driver.get("_down_state_started_tick_by_unit_id")) == {FRIEND_ID: 5}, "Laden: unbekannte Einheiten werden still verworfen")
	old_env.fixture.free()


func _case_checkpoint_blocking_list() -> void:
	var blocking: Array = CHECKPOINT.BLOCKING_DICTS
	_check(not blocking.has("_down_state_started_tick_by_unit_id"), "Sperrliste: das Liege-Dictionary sperrt das Speichern nicht mehr")
	_check(blocking.has("_queued_bleedout_by_unit_id") and blocking.size() == 8, "Sperrliste: der einen Tick lange Verbluten-Merker sperrt weiter, die uebrigen sieben bleiben (%d)" % blocking.size())


## Gefechtsende: nur kampffaehige (fit) Gegner zaehlen; liegende gelten als ausgeschaltet, das Ende wird sofort erkannt.
func _case_downed_enemies_count_as_eliminated() -> void:
	var env := _build(1)
	_check(not bool(env.driver.call("_is_enemy_team_eliminated")), "Gefechtsende: ein einsatzfaehiger Gegner -> nicht ausgeschaltet")
	env.enemy.call("apply_damage", 1000, {})
	_check(env.enemy.call("get_vital_state") == "down" and bool(env.driver.call("_is_enemy_team_eliminated")), "Gefechtsende: der letzte Gegner liegt (down) -> sofort ausgeschaltet, ohne Verbluten abzuwarten")
	env.fixture.free()
