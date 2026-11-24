extends SceneTree
## Knopf "Aufgeben" an der Truppkarte (24.11.2026): erscheint nur an einer liegenden eigenen Person (nicht in der Kampagne),
## erster Klick bewaffnet 4 s ("Wirklich aufgeben?"), zweiter Klick ruft request_unit_give_up. Echte Einsatzszene, echter Treiber.
## Schlusszeile: GIVE_UP_BUTTON passed=N failed=M
const MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const ROW_PATH: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow"
const BUTTON_NAME: String = "GiveUpButton"
const IDLE_TEXT: String = "Aufgeben"
const ARMED_TEXT: String = "Wirklich aufgeben?"

var _passed := 0
var _failed := 0


class Probe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)
	func _refresh_fireteam_mini_cards() -> void:
		pass
	func _refresh_ad_hoc_panel_visibility() -> void:
		pass
	func _update_character_overlay() -> void:
		pass
	func _refresh_mission_control_craft_summary() -> void:
		pass
	func _refresh_mission_evacuation_button() -> void:
		pass
	func _refresh_dynamic_button_styles() -> void:
		pass
	func _apply_drop_light_hud_button_labels() -> void:
		pass
	func _apply_command_hierarchy_metadata() -> void:
		pass
	func _enforce_drop_light_fixed_hud_layout() -> void:
		pass
	func _refresh_world_overlays() -> void:
		pass
	func _sync_primary_3d_mission_status_visuals() -> void:
		pass
	func _suppress_legacy_2d_readability_overlays(_use_cached_unit_suppression: bool = false) -> void:
		pass
	func configure_selection(ids: PackedStringArray) -> void:
		_selected_fireteam_ids = ids.duplicate()
		_character_overlay_open = true


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := MISSION_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(12):
		await process_frame
	var owner := scene.get_node_or_null("TacticalController")
	var driver := scene.get_node_or_null("CombatLoopDriver")
	var row := scene.get_node_or_null(ROW_PATH) as HBoxContainer
	_check(owner != null and driver != null and row != null, "Einsatzszene hat Controller, Treiber und Kartenzeile")
	if owner == null or driver == null or row == null:
		scene.queue_free()
		await process_frame
		_finish()
		return
	var probe := Probe.new()
	probe.name = "GiveUpProbe"
	scene.add_child(probe)
	var ids := PackedStringArray(owner.get("_selected_fireteam_ids"))
	_check(not ids.is_empty(), "Die Szene hat ein gewaehltes Fireteam")
	probe.configure_selection(ids)
	_rebuild(probe)
	var units: Array = []
	for card in _cards(row):
		var found = driver.call("_find_unit_by_id", driver.call("_get_units", driver.get("friendly_unit_paths")), String(card.call("get_unit_id")))
		if found != null:
			units.append(found)
	_check(units.size() >= 2, "Mindestens zwei eigene Personen auf den Karten (%d)" % units.size())
	if units.size() < 2:
		scene.queue_free()
		await process_frame
		_finish()
		return
	# Der Sanitaeter der Szene heilt Liegende; er selbst ist A (liegt er, heilt niemand dazwischen).
	var a = units[0]
	for candidate in units:
		if String(candidate.call("get_role_name")) == "Combat Medic":
			a = candidate
	var b = units[1] if units[1] != a else units[0]
	var c = null
	for candidate in units:
		if candidate != a and candidate != b:
			c = candidate
	var a_id := String(a.call("get_unit_id"))
	var b_id := String(b.call("get_unit_id"))

	_check(_buttons(row).is_empty(), "Kampffaehige Personen: kein Knopf")

	a.call("apply_damage", 1000, {})
	_check(String(a.call("get_vital_state")) == "down", "Person A liegt (%s)" % String(a.call("get_vital_state")))
	_rebuild(probe)
	_check(_text(_button(row, a_id)) == IDLE_TEXT, "Liegende eigene Person: Knopf 'Aufgeben' (Text '%s')" % _text(_button(row, a_id)))
	_check(_button(row, b_id) == null, "Kampffaehige Nachbarin hat weiter keinen Knopf")
	var enemies: Array = driver.call("_get_units", driver.get("enemy_unit_paths"))
	if enemies.is_empty():
		_check(false, "Die Szene hat einen Gegner fuer den Fremd-Fall")
	else:
		var enemy_card = _card(row, a_id)
		if enemy_card != null:
			var own_button = _button(row, a_id)
			if own_button != null:
				own_button.free()
			enemies[0].call("apply_damage", 1000, {})
			if probe.has_method("_append_give_up_button"):
				probe.call("_append_give_up_button", enemy_card, enemies[0])
			_check(probe.has_method("_append_give_up_button") and enemy_card.find_child(BUTTON_NAME, true, false) == null, "Liegende gegnerische Einheit: kein Knopf")
	driver.set("campaign_casualty_rules_enabled", true)
	_rebuild(probe)
	_check(_buttons(row).is_empty(), "Kampagnen-Einsatz: kein Knopf")
	driver.set("campaign_casualty_rules_enabled", false)
	driver.set("_combat_finished", true)
	_rebuild(probe)
	_check(_buttons(row).is_empty(), "Gefecht beendet: kein Knopf")
	driver.set("_combat_finished", false)
	_rebuild(probe)
	_check(_button(row, a_id) != null, "Ausserhalb der Kampagne ist der Knopf wieder da")

	b.call("apply_damage", 1000, {})
	_rebuild(probe)
	_check(_text(_button(row, a_id)) == IDLE_TEXT and _text(_button(row, b_id)) == IDLE_TEXT, "Zwei Liegende: beide Knoepfe 'Aufgeben'")
	_press(_button(row, a_id))
	_check(_text(_button(row, a_id)) == ARMED_TEXT, "Ein Klick: Text '%s'" % ARMED_TEXT)
	_press(_button(row, b_id))
	_check(_text(_button(row, b_id)) == ARMED_TEXT and _text(_button(row, a_id)) == ARMED_TEXT, "Klick bei A, dann bei B: B bewaffnet, A bleibt bewaffnet")
	_check(not _queued(driver, a_id) and not _queued(driver, b_id), "Erste Klicks loesen nichts aus (Merker leer)")
	_check(String(a.call("get_vital_state")) == "down" and String(b.call("get_vital_state")) == "down", "Beide liegen weiter")

	_rebuild(probe)
	_check(_text(_button(row, a_id)) == ARMED_TEXT and _text(_button(row, b_id)) == ARMED_TEXT, "Neuaufbau nach dem Klick: beide neuen Knoepfe zeigen weiter '%s'" % ARMED_TEXT)
	_check(not _queued(driver, a_id) and not _queued(driver, b_id) and String(a.call("get_vital_state")) == "down", "Neuaufbau loest nichts aus")

	paused = true
	await create_timer(4.3, true, false, true).timeout
	paused = false
	_check(_text(_button(row, a_id)) == IDLE_TEXT and _text(_button(row, b_id)) == IDLE_TEXT, "Nach 4,3 s ohne zweiten Klick (Baum pausiert): Text wieder 'Aufgeben'")
	_rebuild(probe)
	_check(_text(_button(row, a_id)) == IDLE_TEXT and _text(_button(row, b_id)) == IDLE_TEXT, "Nach Ablauf und Neuaufbau: wieder 'Aufgeben'")
	_check(not _queued(driver, a_id) and not _queued(driver, b_id) and String(a.call("get_vital_state")) == "down" and String(b.call("get_vital_state")) == "down", "Ablauf der Frist loest nichts aus")

	_press(_button(row, a_id))
	_press(_button(row, a_id))
	_check(not _queued(driver, a_id) and _text(_button(row, a_id)) == ARMED_TEXT and String(a.call("get_vital_state")) == "down", "Zweiter Klick unter 400 ms wird ignoriert, Knopf bleibt bewaffnet")
	await create_timer(0.45, true, false, true).timeout
	var old_button = _button(row, a_id)
	var old_id: int = old_button.get_instance_id() if old_button != null else 0
	if c != null:
		c.call("apply_damage", 5, {})
	probe.call("_refresh_selected_fireteam_cards")
	var new_button = _button(row, a_id)
	_check(new_button != null and new_button.get_instance_id() != old_id, "Aenderung bei einer ANDEREN Person baut die Karten von selbst neu (neuer Knopf)")
	_check(_text(new_button) == ARMED_TEXT, "Neuer Knopf derselben Person zeigt weiter '%s'" % ARMED_TEXT)
	_check(_text(_button(row, b_id)) == IDLE_TEXT, "Zwei Liegende: B blieb unbewaffnet")
	_press(_button(row, b_id))
	_check(_text(_button(row, b_id)) == ARMED_TEXT and not _queued(driver, b_id), "Erster Klick bei B bewaffnet nur B")
	_press(_button(row, a_id))
	_check(_queued(driver, a_id), "Zweiter Klick nach dem Neuaufbau gibt A auf (beim Treiber eingereiht)")
	_check(not _queued(driver, b_id) and String(b.call("get_vital_state")) == "down", "B bleibt unberuehrt")
	var start_ms: int = Time.get_ticks_msec()
	while Time.get_ticks_msec() - start_ms < 8000 and not String(a.call("get_vital_state")) in ["bleedout", "respawning"]:
		await process_frame
	_check(String(a.call("get_vital_state")) in ["bleedout", "respawning"], "Person A verblutet von selbst, ohne advance_bleedout (%s)" % String(a.call("get_vital_state")))
	b.call("apply_heal", 1000, {})
	_check(String(b.call("get_vital_state")) == "fit", "B steht wieder auf (%s)" % String(b.call("get_vital_state")))
	_rebuild(probe)
	_check(_button(row, a_id) == null and _button(row, b_id) == null, "Nach Aufgeben und Heilen: kein Knopf mehr")
	_check(not Dictionary(probe.get("_give_up_armed_until")).has(b_id), "Geheilte Person: Eintrag ist weg")

	probe.free()
	scene.queue_free()
	for _frame in range(3):
		await process_frame
	_finish()


func _rebuild(probe: Node) -> void:
	probe.set("_last_selected_fireteam_cards_runtime_signature", "")
	probe.call("_refresh_selected_fireteam_cards")


func _cards(row: Node) -> Array:
	var result: Array = []
	for child in row.get_children():
		if not child.is_queued_for_deletion() and child.has_method("get_unit_id"):
			result.append(child)
	return result


func _card(row: Node, unit_id: String):
	for card in _cards(row):
		if String(card.call("get_unit_id")) == unit_id:
			return card
	return null


func _button(row: Node, unit_id: String):
	var card = _card(row, unit_id)
	return card.find_child(BUTTON_NAME, true, false) if card != null else null


func _buttons(row: Node) -> Array:
	var result: Array = []
	for card in _cards(row):
		var button = card.find_child(BUTTON_NAME, true, false)
		if button != null:
			result.append(button)
	return result


func _text(button) -> String:
	return String(button.text) if button != null else "<kein Knopf>"


func _press(button) -> void:
	if button != null:
		button.emit_signal("pressed")
	else:
		_check(false, "Klick ohne Knopf")


func _queued(driver: Node, unit_id: String) -> bool:
	return Dictionary(driver.get("_queued_bleedout_by_unit_id")).has(unit_id)


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
	else:
		_failed += 1
		print("FAIL ", label)


func _finish() -> void:
	print("GIVE_UP_BUTTON passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
