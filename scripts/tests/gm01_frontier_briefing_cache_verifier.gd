extends SceneTree
## Actual Homebase UI, source fingerprints and commands; only private scratch
## files are edited. No transport/boarding timer or mission simulation is patched.
const HOMEBASE = preload("res://scenes/meta/homebase_test_screen.tscn")
const PANEL = preload("res://scripts/mission/mission_briefing_panel_presenter.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const ROSTER = preload("res://scripts/npc/unit_roster_presets.gd")
const READINESS = preload("res://scripts/mission/pre_mission_readiness_presenter.gd")
const PANEL_PATH := "Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel"
var passed := 0
var failed := 0
var scratch := ""
var files: Array[String] = []


class ProbeHomebase extends "res://scripts/meta/homebase_screen.gd":
	var catalog_probe_path := ""
	func _mission_briefing_catalog_source_paths() -> PackedStringArray:
		var paths: PackedStringArray = super._mission_briefing_catalog_source_paths()
		if not catalog_probe_path.is_empty():
			paths.append(catalog_probe_path)
		return paths


class CountingPresenter extends RefCounted:
	var calls := 0
	var delegate = preload("res://scripts/mission/mission_briefing_panel_presenter.gd").new()
	func build_snapshot_from_files(scenario: String, map: String, play_mode: String) -> Dictionary:
		calls += 1
		return delegate.build_snapshot_from_files(scenario, map, play_mode)


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(text)
	file.close()
	if not files.has(path):
		files.append(path)


func _scenario(path: String, map: String, title: String) -> void:
	_write(path, JSON.stringify({"version": 1, "scenario_id": "cache_probe", "display_name": title,
		"map_file_path": map, "briefing": {"title": title, "summary": "Scratch briefing",
		"minimap_mode": "terrain_only", "recommended_loadout": [{"label": "Rifle", "role_id": "rifle",
		"armor_id": "medium", "weapon_ids": ["sniper", "rocket_launcher"], "count": 1, "reason": "Probe"}]}}))


func _context(screen: Node, scenario: String, map: String) -> void:
	# Set the explicit blank case as well: the public setter intentionally keeps
	# its old path on blank input, so this fixture tests the downstream fallback.
	screen.set("_selected_mission_map_path", map)
	screen.call("set_mission_context", [{"mission_id": "cache_probe", "mission_name": "Cache probe",
		"map_file_path": map, "scenario_file_path": scenario, "slot_count": 8}], map, "Cache probe", 8, "cache_probe")


func _fresh_readiness(screen: Node, label: String) -> void:
	var expected: Dictionary = READINESS.new().build_snapshot({
		"briefing": screen.call("get_mission_briefing_panel_snapshot"),
		"loadout": screen.call("get_briefing_loadout_bridge_snapshot"),
		"aircraft": screen.call("get_aircraft_panel_snapshot"),
		"staging": screen.call("get_homebase_direct_staging_snapshot"),
		"can_start": screen.call("can_request_mission_start")})
	var actual: Dictionary = screen.call("get_pre_mission_readiness_snapshot")
	var same := true
	for key in ["overall_state", "can_start", "ready_count", "warn_count", "blocked_count", "items", "summary_text"]:
		same = same and actual.get(key) == expected.get(key)
	check(same, label + ": every readiness semantic field remains fresh from current DTOs")
	# R4 keeps a compact raw summary above the folded details. The detailed
	# readiness label deliberately prefixes the action cue; it is not raw DTO text.
	var state := String(expected.get("overall_state", "")).strip_edges().to_lower()
	var cue := "Naechster Griff: STOP-Chips loesen -> Dropship/Pilot/Boarding pruefen"
	if state == "ready":
		cue = "Naechster Griff: Start Mission -> LZ waehlen -> Drop -> Preview lesen -> GO"
	elif state == "warn":
		cue = "Naechster Griff: Start pruefen -> WARN-Chips lesen -> bewusst Start Mission"
	var summary := String(expected.get("summary_text", "")).strip_edges()
	var expected_detail := cue if summary.is_empty() else "%s | %s" % [cue, summary]
	var compact := screen.get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/R2PreparationStatus") as Label
	check(compact != null and compact.text == String(expected.get("summary_text", ""))
		and String(actual.get("rendered_summary_text", "")) == expected_detail,
		label + ": compact summary and detailed action-cue readout match the current readiness model")


func _same_second_edit(path: String, before: String, after: String) -> bool:
	if before.to_utf8_buffer().size() != after.to_utf8_buffer().size():
		return false
	for _attempt in range(4):
		_write(path, before)
		var modified := FileAccess.get_modified_time(path)
		_write(path, after)
		if FileAccess.get_modified_time(path) == modified:
			return true
	return false


func _run() -> void:
	scratch = "user://gm01_briefing_cache_" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(scratch))
	var map_a := scratch + "/map_a.json"
	var map_b := scratch + "/map_b.json"
	var map_missing := scratch + "/map_missing.json"
	var scenario_a := scratch + "/scenario_a.json"
	var scenario_b := scratch + "/scenario_b.json"
	var scenario_missing := scratch + "/scenario_missing.json"
	var catalog := scratch + "/declared_catalog.json"
	MAP.create_empty("A", Vector2i(4, 4), Vector2.ZERO).save_to_file(map_a)
	MAP.create_empty("B", Vector2i(4, 4), Vector2(111.0, -37.0)).save_to_file(map_b)
	files.append_array([map_a, map_b])
	_scenario(scenario_a, map_a, "Cache A")
	_scenario(scenario_b, map_b, "Cache B")
	_write(catalog, "{\"revision\":1}")
	var screen: Control = HOMEBASE.instantiate()
	screen.set_script(ProbeHomebase)
	screen.set("catalog_probe_path", catalog)
	var presenter := CountingPresenter.new()
	screen.set("_mission_briefing_panel_presenter", presenter)
	var roster: Array = ROSTER.get_homebase_roster()
	screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo"]))
	_context(screen, scenario_a, map_a)
	root.add_child(screen)
	await process_frame
	check(presenter.calls == 1, "Initial real Homebase panel builds exactly one file-derived snapshot")
	var first_panel := screen.get_node(PANEL_PATH)
	var first_snapshot: Dictionary = screen.call("get_mission_briefing_panel_snapshot")
	screen.hide()
	for _index in range(3):
		screen.call("setup_roster", roster, PackedStringArray(["unit_alpha", "unit_bravo"]))
		_context(screen, scenario_a, map_a)
		screen.call("set_mission_occupancy", 3, 1)
		screen.call("set_mission_launch_state", false, "Transport changing")
	check(presenter.calls == 1 and screen.get_node(PANEL_PATH) == first_panel, "Repeated hidden roster/context/occupancy updates reuse the one snapshot and panel")
	_fresh_readiness(screen, "Hidden DTO refresh")
	first_snapshot["title"] = "External corruption"
	screen.call("_update_mission_info")
	check(String(Dictionary(screen.call("get_mission_briefing_panel_snapshot")).get("title")) == "Cache A", "Public snapshot remains detached from the cached presentation")
	var recommendation: Dictionary = Array(first_snapshot.get("loadout_card_entries", []))[0]
	var recommendation_id := String(recommendation.get("recommendation_id", ""))
	var cards := first_panel.get_node("BriefingMargin/BriefingVBox/BriefingLoadoutCards")
	var button := cards.get_child(0) as Button
	button.pressed.emit()
	check(String(Dictionary(screen.call("get_briefing_loadout_bridge_snapshot")).get("selected_recommendation_id")) == recommendation_id, "Cached panel preserves real recommendation-button callbacks")
	screen.call("set_selected_unit_ids", PackedStringArray())
	var apply_button := first_panel.get_node("BriefingMargin/BriefingVBox/BriefingLoadoutBridgeRow/BriefingLoadoutApplyButton") as Button
	check(apply_button.disabled, "Cache hit disables apply immediately when selected operators become empty")
	_fresh_readiness(screen, "Empty selection")
	screen.call("set_selected_unit_ids", PackedStringArray(["unit_alpha"]))
	# Clearing selection also clears aligned fireteam assignments. Reassign via
	# the normal DTO API so the confirmed action has a real staged operator.
	screen.call("set_fireteam_context", PackedStringArray(["ft1"]), [{"id": "ft1", "label": "ALPHA",
		"lead_unit_id": "unit_alpha", "loadout": "medium", "respawn_enabled": false}])
	check(not apply_button.disabled, "Cache hit re-enables the existing loadout action for a new selection")
	var before_apply: Dictionary = screen.call("get_briefing_loadout_bridge_snapshot")
	var applied: Dictionary = screen.call("apply_selected_briefing_loadout_recommendation_to_selected_units")
	var after_apply: Dictionary = screen.call("get_briefing_loadout_bridge_snapshot")
	var patch: Dictionary = recommendation.get("loadout_patch_preview", {})
	var actual_loadout: Dictionary = Dictionary(after_apply.get("selected_unit_loadouts", {})).get("unit_alpha", {})
	var before_loadout: Dictionary = Dictionary(before_apply.get("selected_unit_loadouts", {})).get("unit_alpha", {})
	var matches_patch := true
	var changed := false
	for key in ["armor", "weapon_1", "weapon_2"]:
		matches_patch = matches_patch and String(actual_loadout.get(key, "")) == String(patch.get(key, ""))
		changed = changed or actual_loadout.get(key) != before_loadout.get(key)
	check(int(after_apply.get("apply_count", 0)) == int(before_apply.get("apply_count", 0)) + 1
		and Array(applied.get("applied_unit_ids", [])) == ["unit_alpha"]
		and String(after_apply.get("feedback_text", "")).contains("auf 1 Operatoren angewendet.")
		and matches_patch and changed, "Confirmed action applies the selected recommendation to the real assigned Alpha member exactly once")
	# Exercise the normal next DTO refresh, rather than assuming this command's
	# return dictionary is the separately rendered readiness presentation.
	screen.call("set_mission_occupancy", 3, 1)
	_fresh_readiness(screen, "Changed loadout")
	var changed_roster := roster.duplicate(true)
	for unit in changed_roster:
		if String(unit.get("unit_id", "")) == "unit_alpha":
			unit["display_name"] = "Cache Updated Alpha"
	screen.call("setup_roster", changed_roster, PackedStringArray(["unit_alpha"]))
	screen.call("set_transport_state", [{"craft_id": "cache_craft", "craft_type": "dropship", "display_name": "Cache craft",
		"texture_path": "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png", "supports_cargo": false}],
		{"cache_craft": "unit_delta"}, [], [], {"cache_craft": "homebase"}, {}, {}, [])
	_fresh_readiness(screen, "Changed roster/transport")
	check(presenter.calls == 1, "Loadout, roster and transport updates do not reload unchanged briefing sources")
	var map_before := FileAccess.get_file_as_string(map_a)
	var map_after := map_before.replace("\"cover_value\": 0", "\"cover_value\": 7")
	check(map_after != map_before and _same_second_edit(map_a, map_before, map_after), "Scratch map edit has identical byte length, path and modification second")
	screen.call("_update_mission_info")
	check(presenter.calls == 2, "Changed map content SHA invalidates even a same-size same-second source")
	check(_same_second_edit(scenario_a, FileAccess.get_file_as_string(scenario_a), FileAccess.get_file_as_string(scenario_a).replace("Cache A", "Cache Z")), "Scratch scenario edit also preserves byte length/path/modification second")
	screen.call("_update_mission_info")
	check(presenter.calls == 3 and String(Dictionary(screen.call("get_mission_briefing_panel_snapshot")).get("title")) == "Cache Z", "Changed scenario content rebuilds and renders its new briefing")
	_context(screen, scenario_b, map_b)
	check(presenter.calls == 4 and String(Dictionary(screen.call("get_mission_briefing_panel_snapshot")).get("title")) == "Cache B", "Switching source paths invalidates the existing single snapshot")
	var before_catalog := presenter.calls
	_write(catalog, "{\"revision\":2}")
	screen.call("_update_mission_info")
	var sources: PackedStringArray = screen.call("_mission_briefing_catalog_source_paths")
	check(presenter.calls == before_catalog + 1 and sources.has("res://data/terrain_tile_catalog.json"), "Declared catalog content participates in the real guard, including production TerrainTileCatalog")
	_context(screen, scenario_missing, map_b)
	var missing_calls := presenter.calls
	screen.call("_update_mission_info")
	check(presenter.calls == missing_calls, "Repeated missing source is represented explicitly and remains bounded")
	_scenario(scenario_missing, map_b, "Recovered")
	screen.call("_update_mission_info")
	check(presenter.calls == missing_calls + 1 and String(Dictionary(screen.call("get_mission_briefing_panel_snapshot")).get("title")) == "Recovered", "Missing scenario becoming present invalidates and renders the recovered source")
	_scenario(scenario_missing, map_missing, "Fallback")
	_context(screen, scenario_missing, "")
	var missing_map_calls := presenter.calls
	MAP.create_empty("Recovered map", Vector2i(3, 3), Vector2.ZERO).save_to_file(map_missing)
	files.append(map_missing)
	screen.call("_update_mission_info")
	var fallback: Dictionary = screen.call("get_mission_briefing_panel_snapshot")
	check(presenter.calls == missing_map_calls + 1 and int(fallback.get("minimap_visual_sample_count", 0)) == 9, "Blank explicit path fingerprints the actual scenario-resolved map, including missing-to-present recovery")
	var current_panel := screen.get_node(PANEL_PATH)
	current_panel.get_parent().remove_child(current_panel)
	current_panel.free()
	var before_recreate := presenter.calls
	screen.call("_update_mission_info")
	var replacement := screen.get_node(PANEL_PATH)
	check(replacement != null and presenter.calls == before_recreate and replacement.has_meta("mission_briefing_snapshot"), "Recreated panel renders the existing snapshot without another heavy source build")
	var replacement_button := replacement.get_node("BriefingMargin/BriefingVBox/BriefingLoadoutCards").get_child(0) as Button
	replacement_button.pressed.emit()
	check(not String(Dictionary(screen.call("get_briefing_loadout_bridge_snapshot")).get("selected_recommendation_id", "")).is_empty(), "Recreated recommendation controls retain their callbacks")
	screen.show()
	screen.call("_update_mission_info")
	_fresh_readiness(screen, "Visible before actionability")
	var signature_a: String = screen.call("_build_mission_briefing_source_signature", scenario_missing, "", "multiplayer_pvp")
	var signature_b: String = screen.call("_build_mission_briefing_source_signature", scenario_missing, "", "singleplayer")
	check(signature_a != signature_b, "Play mode participates in the source context")
	screen.queue_free()
	await process_frame
	for path in files:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed])
	if failed == 0:
		print("GM01_FRONTIER_BRIEFING_CACHE_ALL_PASS")
	quit(0 if failed == 0 else 1)
