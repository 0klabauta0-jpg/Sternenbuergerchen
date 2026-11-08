extends SceneTree
const MISSION: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
class Probe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var observe := false
	var counts: Dictionary = {}
	var usec: Dictionary = {}
	func _ready() -> void:
		super._ready()
		set_process(false)
		set_physics_process(false)
	func note(key: String, start: int) -> void:
		if observe:
			counts[key] = int(counts.get(key, 0)) + 1
			usec[key] = int(usec.get(key, 0)) + Time.get_ticks_usec() - start
	func _get_review_session_identity_snapshot() -> Dictionary:
		var started := Time.get_ticks_usec()
		var result: Dictionary = super._get_review_session_identity_snapshot()
		note("_get_review_session_identity_snapshot", started)
		return result
	func get_mission_interaction_point_binding_snapshot() -> Dictionary:
		var started := Time.get_ticks_usec()
		var result: Dictionary = super.get_mission_interaction_point_binding_snapshot()
		note("get_mission_interaction_point_binding_snapshot", started)
		return result
	func get_mission_interaction_runtime_use_state_snapshot() -> Dictionary:
		var started := Time.get_ticks_usec()
		var result: Dictionary = super.get_mission_interaction_runtime_use_state_snapshot()
		note("get_mission_interaction_runtime_use_state_snapshot", started)
		return result
	func get_mission_interaction_objective_gate_snapshot() -> Dictionary:
		var started := Time.get_ticks_usec()
		var result: Dictionary = super.get_mission_interaction_objective_gate_snapshot()
		note("get_mission_interaction_objective_gate_snapshot", started)
		return result
	func get_station_scenario_route_cue_polish_snapshot() -> Dictionary:
		var started := Time.get_ticks_usec()
		var result: Dictionary = super.get_station_scenario_route_cue_polish_snapshot()
		note("get_station_scenario_route_cue_polish_snapshot", started)
		return result
	func get_cover_effectiveness_readout_snapshot() -> Dictionary:
		var started := Time.get_ticks_usec()
		var result: Dictionary = super.get_cover_effectiveness_readout_snapshot()
		note("get_cover_effectiveness_readout_snapshot", started)
		return result
	func get_contact_decision_diagnostics_snapshot() -> Dictionary:
		var started := Time.get_ticks_usec()
		var result: Dictionary = super.get_contact_decision_diagnostics_snapshot()
		note("get_contact_decision_diagnostics_snapshot", started)
		return result
	func _build_fireteam_status_text() -> String:
		var started := Time.get_ticks_usec()
		var result: String = super._build_fireteam_status_text()
		note("_build_fireteam_status_text", started)
		return result
	func _build_strategic_status_text() -> String:
		var started := Time.get_ticks_usec()
		var result: String = super._build_strategic_status_text()
		note("_build_strategic_status_text", started)
		return result
	func _build_fireteam_mini_cards_runtime_signature() -> String:
		var started := Time.get_ticks_usec()
		var result: String = super._build_fireteam_mini_cards_runtime_signature()
		note("_build_fireteam_mini_cards_runtime_signature", started)
		return result
	func _get_fireteam_units(fireteam_id: String, include_hidden: bool = true) -> Array:
		var started := Time.get_ticks_usec()
		var result: Array = super._get_fireteam_units(fireteam_id, include_hidden)
		note("_get_fireteam_units", started)
		return result

	func _ensure_mission_runtime_read_models() -> void:
		var started := Time.get_ticks_usec()
		super._ensure_mission_runtime_read_models()
		note("_ensure_mission_runtime_read_models", started)
	func _object_has_property(object: Object, property_name: String) -> bool:
		var started := Time.get_ticks_usec()
		var result: bool = super._object_has_property(object, property_name)
		note("_object_has_property", started)
		return result
	func _get_available_fireteam_ids() -> PackedStringArray:
		var started := Time.get_ticks_usec()
		var result: PackedStringArray = super._get_available_fireteam_ids()
		note("_get_available_fireteam_ids", started)
		return result
	func _build_mission_interaction_runtime_use_context_for_readability() -> Dictionary:
		var started := Time.get_ticks_usec()
		var result: Dictionary = super._build_mission_interaction_runtime_use_context_for_readability()
		note("_build_mission_interaction_runtime_use_context_for_readability", started)
		return result
	func _is_fireteam_runtime_active(fireteam_id: String) -> bool:
		var started := Time.get_ticks_usec()
		var result: bool = super._is_fireteam_runtime_active(fireteam_id)
		note("_is_fireteam_runtime_active", started)
		return result
	func _resolve_fireteam_visual_anchor_position(fireteam_id: String) -> Variant:
		var started := Time.get_ticks_usec()
		var result: Variant = super._resolve_fireteam_visual_anchor_position(fireteam_id)
		note("_resolve_fireteam_visual_anchor_position", started)
		return result
	func get_local_command_team_id(args: Array = []) -> String:
		var started := Time.get_ticks_usec()
		var result: String = super.get_local_command_team_id(args)
		note("get_local_command_team_id", started)
		return result

	func _apply_native_a5_hud_layout() -> void:
		var started := Time.get_ticks_usec()
		super._apply_native_a5_hud_layout()
		note("_apply_native_a5_hud_layout", started)
	func _refresh_order_visuals() -> void:
		var started := Time.get_ticks_usec()
		super._refresh_order_visuals()
		note("_refresh_order_visuals", started)
		if observe:
			print("R8_VISUAL_CALLER ", JSON.stringify(get_stack()))
	func _refresh_button_state() -> void:
		var started := Time.get_ticks_usec()
		super._refresh_button_state()
		note("_refresh_button_state", started)
	func _refresh_order_command_feedback() -> void:
		var started := Time.get_ticks_usec()
		super._refresh_order_command_feedback()
		note("_refresh_order_command_feedback", started)
	func _emit_planning_state_changed() -> void:
		var started := Time.get_ticks_usec()
		super._emit_planning_state_changed()
		note("_emit_planning_state_changed", started)
	func _build_order_visual_sources() -> Dictionary:
		var started := Time.get_ticks_usec()
		var result: Dictionary = super._build_order_visual_sources()
		note("_build_order_visual_sources", started)
		return result
	func _build_native_player_readout_context() -> Dictionary:
		var started := Time.get_ticks_usec()
		var result: Dictionary = super._build_native_player_readout_context()
		note("_build_native_player_readout_context", started)
		return result
	func get_planning_state() -> Dictionary:
		var started := Time.get_ticks_usec()
		var result: Dictionary = super.get_planning_state()
		note("get_planning_state", started)
		return result

	func _get_release_fire_exchange_focused_visual_polish_enabled(world_label_density_mode: String = "") -> bool:
		var started := Time.get_ticks_usec()
		var result: bool = super._get_release_fire_exchange_focused_visual_polish_enabled(world_label_density_mode)
		note("_get_release_fire_exchange_focused_visual_polish_enabled", started)
		return result
	func _get_release_first_exchange_fire_visual_polish_enabled(world_label_density_mode: String = "") -> bool:
		var started := Time.get_ticks_usec()
		var result: bool = super._get_release_first_exchange_fire_visual_polish_enabled(world_label_density_mode)
		note("_get_release_first_exchange_fire_visual_polish_enabled", started)
		return result
	func _sync_primary_3d_order_visuals_from_sources(sources: Dictionary) -> void:
		var started := Time.get_ticks_usec()
		super._sync_primary_3d_order_visuals_from_sources(sources)
		note("_sync_primary_3d_order_visuals_from_sources", started)

func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := MISSION.instantiate()
	if "--audit-default-scenario" in OS.get_cmdline_user_args():
		scene.get_node("MissionSetup").set("scenario_file_path", "res://data/mission_scenarios/ground_mission01_default.json")
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
	for heavy in [false, true]:
		probe.counts.clear()
		probe.usec.clear()
		probe.observe = true
		var start := Time.get_ticks_usec()
		for iteration in range(5):
			probe.call("_update_ui", heavy, true)
		probe.observe = false
		print("R8_CPU_AUDIT ", JSON.stringify({"heavy": heavy, "iterations": 5, "total_usec": Time.get_ticks_usec() - start, "counts": probe.counts, "inclusive_usec_not_additive": probe.usec}))
	var marker := scene.get_node("TargetMarker") as Node2D
	for iteration in range(3):
		probe.counts.clear()
		probe.usec.clear()
		probe.observe = true
		var started := Time.get_ticks_usec()
		var move: bool = probe.issue_right_click_command_for_test(marker.global_position + Vector2(64.0 + iteration * 16.0, 0), "move", false)
		var move_usec := Time.get_ticks_usec() - started
		started = Time.get_ticks_usec()
		var go: bool = probe.execute_selected_fireteam_orders() if move else false
		probe.observe = false
		print("R8_COMMAND_AUDIT ", JSON.stringify({"iteration": iteration, "move": move, "go": go, "move_usec": move_usec, "go_usec": Time.get_ticks_usec() - started, "counts": probe.counts, "inclusive_usec_not_additive": probe.usec}))
	scene.queue_free()
	await process_frame
	print("R8_CPU_AUDIT_DONE")
	quit(0)
