extends SceneTree
## Real selected-card construction with counted neighboring dispatch sinks.
## Only UI visibility/preview inputs change; no unit or gameplay state is patched.

const MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const ROW_PATH: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow"
const SCROLL_PATH: String = "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll"

var _passed := 0
var _failed := 0


class DispatchProbe extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var selected_calls := 0
	var profile_builds := 0
	var mini_calls := 0
	var ad_hoc_calls := 0
	var overlay_calls := 0
	var opened_unit_id := ""
	func _ready() -> void:
		set_process(false)
		set_physics_process(false)
	func _refresh_selected_fireteam_cards() -> void:
		selected_calls += 1
		super._refresh_selected_fireteam_cards()
	func _build_fireteam_card_profile(unit: Node):
		profile_builds += 1
		return super._build_fireteam_card_profile(unit)
	func _refresh_fireteam_mini_cards() -> void:
		mini_calls += 1
	func _refresh_ad_hoc_panel_visibility() -> void:
		ad_hoc_calls += 1
	func _update_character_overlay() -> void:
		overlay_calls += 1
	func _on_fireteam_card_open_requested(unit_id: String, _profile, _source_context: String) -> void:
		opened_unit_id = unit_id
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
	func reset_counts() -> void:
		selected_calls = 0
		profile_builds = 0
		mini_calls = 0
		ad_hoc_calls = 0
		overlay_calls = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := MISSION_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(12):
		await process_frame
	var owner := scene.get_node_or_null("TacticalController")
	var row := scene.get_node_or_null(ROW_PATH) as HBoxContainer
	var scroll := scene.get_node_or_null(SCROLL_PATH) as Control
	_check(owner != null and row != null and scroll != null, "Real mission fixture exposes the selected member-card subtree")
	if owner == null or row == null or scroll == null:
		scene.queue_free()
		await process_frame
		_finish()
		return
	var probe := DispatchProbe.new()
	probe.name = "HiddenCardDispatchProbe"
	scene.add_child(probe)
	var ids := PackedStringArray(owner.get("_selected_fireteam_ids"))
	_check(not ids.is_empty(), "Fixture has a real selected fireteam")
	probe.configure_selection(ids)
	var cases: Array[Dictionary] = [
		{"id": "a5_hidden_by_ancestor", "a5": true, "ancestor_visible": false, "selected_calls": 0},
		{"id": "a5_revealed", "a5": true, "ancestor_visible": true, "selected_calls": 1},
		{"id": "legacy_hidden", "a5": false, "ancestor_visible": false, "selected_calls": 1},
		{"id": "legacy_revealed", "a5": false, "ancestor_visible": true, "selected_calls": 1},
	]
	for spec in cases:
		probe.set_meta("native_a5_legacy_setup_complete", bool(spec.a5))
		row.visible = true
		scroll.visible = bool(spec.ancestor_visible)
		probe.preview_mode = not probe.preview_mode
		probe.reset_counts()
		_check(row.visible and row.is_visible_in_tree() == bool(spec.ancestor_visible), "%s fixture distinguishes local from effective visibility" % spec.id)
		probe.call("_refresh_runtime_mission_hud_surfaces", true)
		_check(probe.selected_calls == int(spec.selected_calls), "%s periodic dispatch refreshes only the required selected-card surface" % spec.id)
		_check(probe.profile_builds == 0 if int(spec.selected_calls) == 0 else probe.profile_builds > 0, "%s avoids hidden A5 profile construction and keeps required profiles current" % spec.id)
		_check(probe.mini_calls == 1, "%s preserves the mini-card dispatch" % spec.id)
		_check(probe.ad_hoc_calls == 1, "%s preserves the ad-hoc visibility dispatch" % spec.id)
		_check(probe.overlay_calls == 1, "%s preserves the open character-overlay dispatch" % spec.id)
	_test_nonforced_handoffs(probe, row, scroll)
	# Explicit diagnostics/details remain independent of the periodic A5 skip.
	probe.set_meta("native_a5_legacy_setup_complete", true)
	row.visible = true
	scroll.visible = false
	# Re-seed the actual current source independently of the preceding RED cases.
	probe.call("_refresh_selected_fireteam_cards")
	var before_ids := _live_child_ids(row)
	probe.preview_mode = not probe.preview_mode
	probe.reset_counts()
	probe.call("_refresh_selected_fireteam_cards")
	var current_cards := _live_member_cards(row)
	_check(probe.selected_calls == 1 and probe.profile_builds > 0, "Explicit refresh builds fresh profiles even while the A5 strip is hidden")
	_check(not current_cards.is_empty() and _live_child_ids(row) != before_ids, "Changed UI inputs replace the explicit selected-card projection")
	for card in current_cards:
		_check(String(card.call("get_source_context")) == "mission_selected_fireteam_member", "Explicit card retains its existing selected-member source context")
		var unit_id := String(card.call("get_unit_id"))
		_check(not unit_id.is_empty(), "Explicit card still represents a real member identity")
		_check(card.is_connected("card_open_requested", Callable(probe, "_on_fireteam_card_open_requested")), "Explicit card retains its character-opening callback")
		probe.opened_unit_id = ""
		card.emit_signal("card_open_requested", unit_id, card.call("get_profile"), card.call("get_source_context"))
		_check(probe.opened_unit_id == unit_id, "Existing card signal routes the same member identity to the character callback")
	# Revealing a non-A5 surface must synchronously consume current UI inputs.
	probe.set_meta("native_a5_legacy_setup_complete", false)
	scroll.visible = true
	probe.preview_mode = not probe.preview_mode
	probe.reset_counts()
	probe.call("_refresh_runtime_mission_hud_surfaces", true)
	_check(probe.selected_calls == 1 and probe.profile_builds > 0, "Revealed legacy surface rebuilds current cards in the same dispatch")
	probe.free()
	scene.queue_free()
	for _frame in range(3):
		await process_frame
	_finish()


func _test_nonforced_handoffs(probe: DispatchProbe, row: HBoxContainer, scroll: Control) -> void:
	for handoff in ["reveal_same_inputs", "leave_a5_same_inputs"]:
		# Seed the old selected projection independently for each regression case.
		probe.call("_refresh_selected_fireteam_cards")
		# Build no selected cards for the new source state, but let the outer
		# group consume that source signature. No frame/tick elapses in this test.
		probe.set_meta("native_a5_legacy_setup_complete", true)
		row.visible = true
		scroll.visible = false
		probe.preview_mode = not probe.preview_mode
		probe.reset_counts()
		probe.call("_refresh_runtime_mission_hud_surfaces", false)
		_check(probe.selected_calls == 0 and probe.profile_builds == 0, "%s hidden A5 consumes the group refresh without building selected profiles" % handoff)
		_check(String(probe.get("_last_periodic_fireteam_cards_signature")) == String(probe.call("_build_periodic_fireteam_cards_signature")), "%s hidden group signature is genuinely current" % handoff)
		var before_ids := _live_child_ids(row)
		var before_source := String(probe.call("_build_selected_fireteam_cards_runtime_signature"))
		if handoff == "reveal_same_inputs":
			scroll.visible = true
		else:
			probe.set_meta("native_a5_legacy_setup_complete", false)
		_check(String(probe.call("_build_selected_fireteam_cards_runtime_signature")) == before_source, "%s transition changes no selected-card source input" % handoff)
		probe.reset_counts()
		probe.call("_refresh_runtime_mission_hud_surfaces", false)
		_check(probe.selected_calls == 1 and probe.profile_builds > 0, "%s non-forced handoff synchronously builds previously hidden current profiles" % handoff)
		_check(_live_child_ids(row) != before_ids, "%s non-forced handoff replaces the stale selected projection" % handoff)
		_check(probe.mini_calls == 1 and probe.ad_hoc_calls == 1 and probe.overlay_calls == 1, "%s handoff retains neighboring group dispatches" % handoff)
		probe.reset_counts()
		probe.call("_refresh_runtime_mission_hud_surfaces", false)
		_check(probe.selected_calls == 0 and probe.profile_builds == 0, "%s unchanged non-forced follow-up skips selected work" % handoff)
		_check(probe.mini_calls == 0 and probe.ad_hoc_calls == 0 and probe.overlay_calls == 0, "%s unchanged non-forced follow-up keeps the group quiescent" % handoff)


func _live_child_ids(row: Node) -> PackedInt64Array:
	var result := PackedInt64Array()
	for child in row.get_children():
		if not child.is_queued_for_deletion():
			result.append(child.get_instance_id())
	return result


func _live_member_cards(row: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in row.get_children():
		if not child.is_queued_for_deletion() and child.has_method("get_source_context"):
			result.append(child)
	return result


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		print("FAIL: ", label)


func _finish() -> void:
	print("HUD_ARCHITECTURE_20261106_HIDDEN_CARDS: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("HUD_HIDDEN_CARDS_VERIFY_PASS")
	quit(1 if _failed > 0 else 0)
