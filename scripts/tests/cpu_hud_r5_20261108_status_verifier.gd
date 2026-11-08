extends SceneTree
const MISSION: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
class Probe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var observe := false
	var fallback_fixture := false
	var counts: Dictionary = {}
	var costs: Dictionary = {}
	func _ready() -> void:
		super._ready()
		set_process(false)
		set_physics_process(false)
	func note(key: String, started: int) -> void:
		if observe:
			counts[key] = int(counts.get(key, 0)) + 1
			costs[key] = int(costs.get(key, 0)) + Time.get_ticks_usec() - started
	func _build_selected_fireteam_player_decision_snapshot(raw_decision_line: String, raw_loop_line: String = "", raw_polish_line: String = "", raw_combat_line: String = "") -> Dictionary:
		var result := super._build_selected_fireteam_player_decision_snapshot(raw_decision_line, raw_loop_line, raw_polish_line, raw_combat_line)
		if fallback_fixture:
			result["visible_lines"] = PackedStringArray()
		return result
	func _build_release_fire_exchange_contact_fire_primary_hud_line(density: Dictionary) -> String:
		return "" if fallback_fixture else super._build_release_fire_exchange_contact_fire_primary_hud_line(density)
	func _build_selected_execution_quality_text() -> String:
		var started := Time.get_ticks_usec()
		var result := super._build_selected_execution_quality_text()
		note("_build_selected_execution_quality_text", started)
		return result
	func _build_selected_movement_text() -> String:
		var started := Time.get_ticks_usec()
		var result := super._build_selected_movement_text()
		note("_build_selected_movement_text", started)
		return result
	func _build_selected_security_display_text() -> String:
		var started := Time.get_ticks_usec()
		var result := super._build_selected_security_display_text()
		note("_build_selected_security_display_text", started)
		return result
	func _build_selected_flank_display_text() -> String:
		var started := Time.get_ticks_usec()
		var result := super._build_selected_flank_display_text()
		note("_build_selected_flank_display_text", started)
		return result
	func original_status_oracle() -> String:
		_note_hud_projection_build_call("_build_fireteam_status_text")
		_selected_fireteam_player_decision_snapshot = {}
		if _selected_fireteam_ids.is_empty():
			var no_selection_loop_line: String = _build_release_first_decision_loop_two_hud_line()
			var no_selection_polish_line: String = _build_release_first_decision_loop_two_polish_hud_line()
			if not no_selection_loop_line.is_empty():
				if not no_selection_polish_line.is_empty():
					return "NO SELECTION | 0 Karten | Click unit or drag leaders\n%s\n%s" % [no_selection_loop_line, no_selection_polish_line]
				return "NO SELECTION | 0 Karten | Click unit or drag leaders\n%s" % no_selection_loop_line
			return "NO SELECTION | 0 Karten | Click unit or drag leaders"

		var units: Array = _get_selected_friendly_units(not _use_visible_units_for_fireteam_ui())
		if units.is_empty():
			var selected_cards_fireteam_id: String = _get_selected_member_cards_fireteam_id()
			if not selected_cards_fireteam_id.is_empty():
				units = _filter_ground_fireteam_card_units(_get_fireteam_units(selected_cards_fireteam_id, true))
		var planned_waypoint_count: int = _count_selected_phase_waypoints()
		var planned_area_count: int = _count_selected_area_orders()
		if units.is_empty():
			var insertion_cue: Dictionary = _build_mission_insertion_next_step_cue_snapshot()
			var cue_line: String = String(insertion_cue.get("status_line", "")).strip_edges()
			if not cue_line.is_empty():
				return "%s | %d Wegpunkte | %d Gebiete\n%s" % [_get_fireteam_name(), planned_waypoint_count, planned_area_count, cue_line]
			return "%s | %d Wegpunkte | %d Gebiete | keine Einheiten aktiv" % [_get_fireteam_name(), planned_waypoint_count, planned_area_count]

		var lead_name: String = "-"
		var embarked_count: int = 0
		var deployed_count: int = 0
		for unit in units:
			var unit_id: String = String(unit.call("get_unit_id"))
			if _embarked_unit_ids.has(unit_id):
				embarked_count += 1
			elif _deployed_unit_ids.has(unit_id):
				deployed_count += 1
			if lead_name == "-" and _is_unit_current_fireteam_lead(unit):
				lead_name = String(unit.call("get_display_name"))
		if lead_name == "-":
			lead_name = String((units[0] as Node).call("get_display_name"))
		var drop_state_text: String = "Lead %s" % lead_name
		if embarked_count > 0:
			drop_state_text = "%d embarked | %d deployed | Lead %s" % [embarked_count, deployed_count, lead_name]
		elif deployed_count > 0:
			drop_state_text = "%d deployed | Lead %s" % [deployed_count, lead_name]
		var mode_text: String = "PREVIEW - START MISSION FOR GO | " if preview_mode else ""
		var decision_text: String = _build_selected_decision_status_text()
		var command_text: String = "kein aktiver Befehl" if decision_text == "-" else _format_selected_status_segment(decision_text)
		var combat_hud_density: Dictionary = _build_mission_combat_hud_density_snapshot()
		var combat_hud_line: String = String(combat_hud_density.get("selected_fireteam_line", "")).strip_edges()
		var contact_fire_primary_line: String = _build_release_fire_exchange_contact_fire_primary_hud_line(combat_hud_density)
		var firefight_decision_line: String = _build_release_candidate_firefight_decision_line()
		var loop_two_line: String = _build_release_first_decision_loop_two_hud_line()
		var loop_two_polish_line: String = _build_release_first_decision_loop_two_polish_hud_line()
		var player_decision: Dictionary = _build_selected_fireteam_player_decision_snapshot(
			firefight_decision_line,
			loop_two_line,
			loop_two_polish_line,
			combat_hud_line
		)
		_selected_fireteam_player_decision_snapshot = player_decision.duplicate(true)
		var player_decision_lines: PackedStringArray = PackedStringArray(player_decision.get("visible_lines", PackedStringArray()))
		var first_line: String = "%s%s | Karten %d | Wegpunkte %d | Gebiete %d | Stance %s | Ausfuehrung %s" % [
			mode_text,
			_get_fireteam_name(),
			units.size(),
			planned_waypoint_count,
			planned_area_count,
			_build_selected_tactical_stance_display_text(),
			_format_selected_status_segment(_build_selected_execution_quality_text()),
		]
		var second_line: String = "Befehl %s | Bewegung %s | Sicherung %s | Flank %s | %s" % [
			command_text,
			_format_selected_status_segment(_build_selected_movement_text()),
			_build_selected_security_display_text(),
			_build_selected_flank_display_text(),
			drop_state_text,
		]
		if not contact_fire_primary_line.is_empty():
			var firefight_lines: PackedStringArray = PackedStringArray([
				_compact_release_first_exchange_contact_fire_line(contact_fire_primary_line),
			])
			if not firefight_decision_line.is_empty():
				firefight_lines.append(_compact_release_first_exchange_contact_fire_secondary_line(firefight_decision_line))
			return "\n".join(firefight_lines)
		if not player_decision_lines.is_empty():
			return "\n".join(player_decision_lines)
		if not firefight_decision_line.is_empty():
			if not loop_two_line.is_empty() and loop_two_line != firefight_decision_line:
				if not combat_hud_line.is_empty():
					if not loop_two_polish_line.is_empty():
						return "%s\n%s\n%s\n%s\n%s\n%s" % [firefight_decision_line, loop_two_line, loop_two_polish_line, combat_hud_line, first_line, second_line]
					return "%s\n%s\n%s\n%s\n%s" % [firefight_decision_line, loop_two_line, combat_hud_line, first_line, second_line]
				if not loop_two_polish_line.is_empty():
					return "%s\n%s\n%s\n%s\n%s" % [firefight_decision_line, loop_two_line, loop_two_polish_line, first_line, second_line]
				return "%s\n%s\n%s\n%s" % [firefight_decision_line, loop_two_line, first_line, second_line]
			if not combat_hud_line.is_empty():
				return "%s\n%s\n%s\n%s" % [firefight_decision_line, combat_hud_line, first_line, second_line]
			return "%s\n%s\n%s" % [firefight_decision_line, first_line, second_line]
		if not loop_two_line.is_empty():
			if not combat_hud_line.is_empty():
				if not loop_two_polish_line.is_empty():
					return "%s\n%s\n%s\n%s\n%s" % [loop_two_line, loop_two_polish_line, first_line, second_line, combat_hud_line]
				return "%s\n%s\n%s\n%s" % [loop_two_line, first_line, second_line, combat_hud_line]
			if not loop_two_polish_line.is_empty():
				return "%s\n%s\n%s\n%s" % [loop_two_line, loop_two_polish_line, first_line, second_line]
			return "%s\n%s\n%s" % [loop_two_line, first_line, second_line]
		if not combat_hud_line.is_empty():
			return "%s\n%s\n%s" % [first_line, second_line, combat_hud_line]
		return "%s\n%s" % [first_line, second_line]
var passed := 0
var failed := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		print("FAIL: ", label)
func _run() -> void:
	var scene := MISSION.instantiate()
	var original := scene.get_node("TacticalController")
	var probe := Probe.new()
	for property in original.get_property_list():
		var usage := int(property.usage)
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and (usage & PROPERTY_USAGE_EDITOR) != 0:
			probe.set(String(property.name), original.get(String(property.name)))
	scene.remove_child(original)
	original.free()
	probe.name = "TacticalController"
	scene.add_child(probe)
	root.add_child(scene)
	for frame in range(16):
		await process_frame
	var sim := scene.get_node("SimulationRoot")
	var selected := probe.get_selected_fireteam_ids()
	check(not selected.is_empty(), "Actual authored selection is populated")
	for context in ["selected", "public_move", "fallback", "empty"]:
		if context == "public_move":
			var target := (scene.get_node("TargetMarker") as Node2D).global_position
			check(probe.issue_right_click_command_for_test(target, "move", false), "Public Move supplies real current planning")
		probe.fallback_fixture = context == "fallback"
		if context == "empty":
			probe.call("_set_selected_fireteams", PackedStringArray(), false)
		var owner_before := owner_state(sim)
		var oracle := probe.original_status_oracle()
		var oracle_decision: Dictionary = probe.get("_selected_fireteam_player_decision_snapshot").duplicate(true)
		probe.counts.clear()
		probe.costs.clear()
		probe.observe = true
		var actual: String = probe.call("_build_fireteam_status_text")
		probe.observe = false
		check(actual == oracle, context + ": full RAW status matches original oracle")
		check(probe.get("_selected_fireteam_player_decision_snapshot") == oracle_decision, context + ": decision metadata remains identical")
		check(owner_state(sim) == owner_before, context + ": synchronous tick/queues/actors unchanged")
		if context in ["selected", "public_move"]:
			check(not PackedStringArray(oracle_decision.get("visible_lines", PackedStringArray())).is_empty(), context + ": actual compact decision branch is active")
			check(probe.counts.is_empty(), context + ": discarded fallback formatters are never evaluated")
		elif context == "fallback":
			check(probe.counts.size() == 4, "Fallback still evaluates all four original formatters")
		else:
			check(probe.counts.is_empty(), "No selection preserves the original fast path")
		print("R5_FALLBACK_COUNTER ", JSON.stringify({"context": context, "counts": probe.counts, "cost_usec": probe.costs}))
	scene.queue_free()
	await process_frame
	print("R5_STATUS_DONE ", JSON.stringify({"passed": passed, "failed": failed}))
	quit(0 if failed == 0 else 1)
func owner_state(sim: Node) -> Dictionary:
	var actors: Array = []
	for child in sim.get_parent().get_children():
		if child.has_method("get_unit_id") and child.has_method("get_health"):
			actors.append([child.call("get_unit_id"), child.call("get_health"), str(child.position), str(child.call("get_current_unit_command"))])
	return {"tick": sim.call("get_tick"), "commands": str(sim.get("command_queue")), "effects": str(sim.get("effect_queue")), "actors": actors}
