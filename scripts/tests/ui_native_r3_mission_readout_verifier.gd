extends SceneTree

const SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const BASE := "TacticalUI/BottomDock/BottomMargin/BottomRow/"
const STRATEGIC := BASE + "StrategicPanel"
const RAW_STATUS := STRATEGIC + "/StrategicMargin/StrategicScroll/StrategicVBox/StrategicStatusLabel"
const IDENTITY := "TacticalUI/MissionIdentityPanel"
const RAW_IDENTITY := IDENTITY + "/MissionIdentityMargin/MissionIdentityVBox/"
const TEAM := BASE + "FireteamPanel"
const TRANSPORT := "TacticalUI/MissionDropshipPanel"
const TRANSPORT_IDENTITY := TRANSPORT + "/CompactCard/Contents/Header/Identity"
var _checks := 0
var _failures: PackedStringArray = []
var _hud: Object = load("res://scripts/ui/mission_a5_hud_layout.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("A5_R3_STAGE projection")
	_check_projection()
	print("A5_R3_STAGE scene1920")
	await _check_scene(Vector2i(1920, 1080))
	if OS.get_cmdline_user_args().has("--a5-r3-profile"):
		for failure in _failures:
			print("R3_PROFILE_FAILURE ", failure)
		print("R3_PROFILE_COMPLETE failures=", _failures.size())
		quit(0 if _failures.is_empty() else 1)
		return
	await _check_scene(Vector2i(1280, 720))
	if OS.get_cmdline_user_args().has("--a5-r3-readout-only"):
		for failure in _failures:
			print("R3_READOUT_ONLY_FAILURE ", failure)
		print("A5_R3_READOUT_ONLY_COMPLETE failures=", _failures.size())
		quit(0 if _failures.is_empty() else 1)
		return
	for failure in _failures:
		push_error(failure)
	print("Mission R3 readout: %d checks, %d failures" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("PASS: native mission R3 readout")
	quit(0 if _failures.is_empty() else 1)


func _check_projection() -> void:
	_check(_hud.has_method("build_player_readout"), "R3 has a pure read-only player projection")
	if not _hud.has_method("build_player_readout"):
		return
	var context := {"objective": {}, "transport_cards": [], "selection_count": 0, "feedback": "AWAITING INPUT"}
	var original := context.duplicate(true)
	var empty: Dictionary = _hud.call("build_player_readout", context)
	_check(context == original and bool(empty.get("read_only", false)) and not bool(empty.get("ui_sets_gameplay_truth", true)), "projection neither mutates input nor owns gameplay truth")
	_check(empty.get("mission_text") == "Einsatzziel nicht verfügbar", "missing objective does not invent a mission goal")
	_check(empty.get("transport_text") == "Kein Dropship im Einsatz", "empty transport does not claim a waiting or ready craft")
	_check(empty.get("order") == "Auftrag: Fireteam auswählen", "empty selection has one actionable instruction")
	context = {"objective": {"available": true, "owning_team_id": "", "capture_progress": 0.0}, "local_team_id": "friendly", "selection_count": 1, "target_selected": true, "planned_count": 0, "feedback": "AWAITING INPUT"}
	var neutral: Dictionary = _hud.call("build_player_readout", context)
	_check(neutral.get("mission_text") == "Einsatzziel sichern", "neutral objective uses real objective state rather than route fallback")
	_check(neutral.get("order") == "Auftrag: Befehl auswählen" and String(neutral.get("feedback", "")).is_empty(), "ordinary no-plan state avoids repeated empty instructions")
	context.objective = {"available": true, "owning_team_id": "friendly", "capture_progress": 1.0}
	_check(Dictionary(_hud.call("build_player_readout", context)).get("mission_text") == "Einsatzziel gesichert", "confirmed local capture has a clear success state")
	context.objective.contested = true
	_check(Dictionary(_hud.call("build_player_readout", context)).get("mission_text") == "Einsatzziel umkämpft", "contested objective takes precedence over previous ownership")
	context.objective = {"available": true, "owning_team_id": "opponent", "capture_progress": 1.0}
	_check(Dictionary(_hud.call("build_player_readout", context)).get("mission_text") == "Einsatzziel gegnerisch besetzt", "opponent ownership is not reported as local success")
	context.objective = {"available": true, "owning_team_id": "", "capturing_team_id": "friendly", "capture_progress": 0.45}
	_check(Dictionary(_hud.call("build_player_readout", context)).get("mission_text") == "Einsatzziel sichern · 45 %", "partial confirmed capture is progress rather than completed success")
	context.transport_cards = [{"craft_id": "real_craft", "state": "to_mission", "eta_seconds": 7}]
	_check(String(Dictionary(_hud.call("build_player_readout", context)).get("transport_text")).contains("Im Anflug"), "transport text follows the existing card state")
	context.transport_cards.append({"craft_id": "other_craft", "state": "waiting"})
	_check(String(Dictionary(_hud.call("build_player_readout", context)).get("transport_text")).contains("2 Dropships"), "multiple transports are explicit rather than a fabricated single state")
	context.feedback = "FIRE HOLD REQUEST (1)"
	context.planned_count = 2
	var pending: Dictionary = _hud.call("build_player_readout", context)
	_check(pending.get("feedback") == "Anfrage wird geprüft" and pending.get("order") == "Auftrag: 2 Befehle geplant", "pending request preserves the confirmed plan instead of claiming acceptance")
	context.feedback = "INTERACTION NETWORK BLOCKED"
	_check(Dictionary(_hud.call("build_player_readout", context)).get("feedback") == "Aktion blockiert · Details", "blocked source feedback is explicit and keeps the full reason in details")
	context.feedback = "FIRE HOLD REQUEST REJECTED"
	_check(Dictionary(_hud.call("build_player_readout", context)).get("feedback") == "Aktion blockiert · Details", "rejection takes precedence over a request token in the source")
	context.feedback = "UNRECOGNIZED INTERNAL DIAGNOSTIC"
	_check(String(Dictionary(_hud.call("build_player_readout", context)).get("feedback", "")).is_empty(), "unmapped diagnostics do not leak into the primary player status")
	context.route_active = false
	context.route_cue = {"next_step_id": "wait", "cue_line": "CUE WAIT: Route pruefen"}
	_check(not str(_hud.call("build_player_readout", context)).contains("Route pruefen"), "inactive route cannot manufacture a next-step instruction")
	context.route_active = true
	context.route_cue = {"next_token": "DOOR", "runtime_status": "blocked"}
	_check(Dictionary(_hud.call("build_player_readout", context)).get("mission_text") == "Tür öffnen · blockiert", "active route uses the existing gate status without pretending it is usable")
	context.focused_order_label = "DEFEND"
	_check(Dictionary(_hud.call("build_player_readout", context)).get("order") == "Auftrag: Halten", "focused existing command uses its readable German label")
	context.focused_order_label = ""
	context.feedback = "GO BLUE"
	context.executing_count = 1
	context.can_execute = true
	var running: Dictionary = _hud.call("build_player_readout", context)
	_check(running.get("order") == "Auftrag: Wird ausgeführt" and running.get("feedback") == "Ausführung läuft", "confirmed running plan is not presented as merely planned or waiting for another start")
	context.selection_count = 2
	_check(Dictionary(_hud.call("build_player_readout", context)).get("order") == "Auftrag: 1 von 2 Teams aktiv", "mixed selection does not claim every selected team is executing")


func _check_scene(size: Vector2i) -> void:
	print("A5_R3_STAGE create ", size)
	root.content_scale_size = Vector2i.ZERO
	root.size = size
	var scene := SCENE.instantiate()
	var detached_controller := scene.get_node("TacticalController")
	var detached_grid := scene.get_node(BASE + "CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid")
	_hud.call("configure", detached_controller, {})
	_check(not detached_controller.is_inside_tree() and not detached_grid.has_meta("native_a5_geometry_signature"), "%dx%d: pre-tree planning configuration leaves viewport geometry to normal ready" % [size.x, size.y])
	# Exercise the same public hydration entry used by MetaFlow before add_child,
	# including its selection/UI/runtime-surface callbacks, not only the helper.
	detached_controller.call("set_planning_state", {"has_selected_tile": false})
	print("A5_R3_STAGE detached_hydrated ", size)
	_check(not detached_controller.has_meta("native_a5_window_viewport") and not detached_grid.has_meta("native_a5_geometry_signature"), "%dx%d: public set_planning_state before tree entry performs no viewport layout" % [size.x, size.y])
	root.add_child(scene)
	for _frame in range(16):
		await process_frame
	print("A5_R3_STAGE ready ", size)
	var prefix := "%dx%d: " % [size.x, size.y]
	var controller := scene.get_node("TacticalController")
	_check(detached_grid.has_meta("native_a5_geometry_signature"), prefix + "normal ready configures deferred mission geometry after tree entry")
	var identity := scene.get_node(IDENTITY) as Control
	var strategic := scene.get_node(TRANSPORT) as Control
	_check(strategic.get_global_rect().size.y <= 192.0, prefix + "ordinary dropship summary is bounded to its short primary contents")
	_check(not strategic.get_global_rect().intersects(identity.get_global_rect()), prefix + "upper summaries do not overlap")
	var labels: Array[Label] = []
	for spec in [[IDENTITY, "A5MissionHeading"], [IDENTITY, "A5MissionState"], [TRANSPORT_IDENTITY, "A5TransportHeading"], [TRANSPORT_IDENTITY, "A5TransportState"]]:
		var label := scene.get_node_or_null(String(spec[0]) + "/" + String(spec[1])) as Label
		var drawable := label != null and label.is_visible_in_tree() and label.get_visible_line_count() > 0
		_check(drawable, prefix + String(spec[1]) + " is an actually drawable primary readout")
		if not drawable:
			_print_readout_facts(prefix, label)
		if label != null:
			labels.append(label)
			_check(label.get_theme_font_size("font_size") >= 13, prefix + String(spec[1]) + " keeps readable type rather than shrinking it")
			_check(not label.text.contains("#15") and not label.text.contains("#18") and not label.text.contains("ACT CUE") and not label.text.contains("Host"), prefix + String(spec[1]) + " uses player language instead of diagnostic dumps")
			if String(spec[0]) == TRANSPORT_IDENTITY:
				var font_height := ceilf(label.get_theme_font("font").get_height(label.get_theme_font_size("font_size")))
				var parent := label.get_parent() as Control
				_check(label.custom_minimum_size.y >= font_height and label.size.y >= font_height and parent.get_global_rect().encloses(label.get_global_rect()), prefix + String(spec[1]) + " reserves a complete native font line inside the actual compact header")
	var raw_status := scene.get_node(RAW_STATUS) as Label
	var raw_header := scene.get_node(RAW_IDENTITY + "MissionIdentityHeaderLabel") as Label
	var raw_body := scene.get_node(RAW_IDENTITY + "MissionIdentityBodyLabel") as Label
	_check(not raw_status.is_visible_in_tree() and not raw_header.is_visible_in_tree() and not raw_body.is_visible_in_tree(), prefix + "raw source nodes stay owned and available but leave the primary display")
	var legacy_transport := scene.get_node(STRATEGIC) as Control
	_check(not legacy_transport.is_visible_in_tree(), prefix + "legacy transport summary does not duplicate the visible compact Cutlass card")
	for name in ["A5TransportHeading", "A5TransportState"]:
		var legacy_label := legacy_transport.get_node_or_null(name) as Label
		_check(legacy_label != null and not legacy_label.is_visible_in_tree(), prefix + "legacy " + name + " remains available without a second visible readout")
	if OS.get_cmdline_user_args().has("--a5-r3-readout-only"):
		scene.queue_free()
		for _frame in range(2):
			await process_frame
		return
	var details := identity.get_node_or_null("A5ReadoutDetailsButton") as Button
	_check(details != null and not details.get_signal_connection_list("pressed").is_empty(), prefix + "upper summaries provide a real explicit details affordance")
	if details != null:
		print("A5_R3_STAGE open_details ", size)
		details.pressed.emit()
		var popup := scene.get_node("TacticalUI/A5TeamDetailsPopup") as PopupPanel
		var text := popup.get_node("Margin/Box/Scroll/Text") as Label
		_check(popup.visible and not paused, prefix + "readout details open without pausing the mission")
		_check(text.text.contains(raw_status.text) and text.text.contains(raw_header.text) and text.text.contains(raw_body.text), prefix + "complete current diagnostic source text remains reachable")
		popup.hide()
		print("A5_R3_TIME details_closed ", size, " ", Time.get_ticks_msec())
	var layer := scene.get_node("TacticalUI")
	var grid := scene.get_node(BASE + "CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid")
	var writes := int(layer.get_meta("native_a5_rect_write_count", 0))
	var applies := int(grid.get_meta("native_a5_geometry_apply_count", 0))
	for _refresh in range(3):
		controller.call("_update_ui", false, false)
	print("A5_R3_TIME refreshed ", size, " ", Time.get_ticks_msec())
	_check(writes == int(layer.get_meta("native_a5_rect_write_count", 0)) and applies == int(grid.get_meta("native_a5_geometry_apply_count", 0)), prefix + "stable text refreshes do not rebuild geometry")
	await _check_stance_after_light_refresh(scene, controller, prefix)
	print("A5_R3_TIME stance1 ", size, " ", Time.get_ticks_msec())
	var order := scene.get_node("TacticalUI/A5TargetOrderPanel/Contents/Order") as Label
	var ids := PackedStringArray(controller.call("_get_available_fireteam_ids"))
	controller.call("_set_selected_fireteams", PackedStringArray(), false)
	controller.call("_update_ui", false, false)
	_check(order.text == "Auftrag: Fireteam auswählen", prefix + "light refresh immediately replaces the previous team's order without resizing")
	if not ids.is_empty():
		controller.call("_set_selected_fireteams", PackedStringArray([ids[0]]), false)
		var refs: Array = controller.call("_create_waypoints_for_selected_fireteams", controller.call("_get_target_position"))
		controller.call("_update_ui", false, false)
		var context: Dictionary = controller.call("_build_native_player_readout_context") if controller.has_method("_build_native_player_readout_context") else {}
		_check(not refs.is_empty() and int(context.get("planned_count", 0)) > 0, prefix + "real existing planner supplies the order state")
		if _hud.has_method("build_player_readout"):
			_check(order.text == String(Dictionary(_hud.call("build_player_readout", context)).get("order", "")), prefix + "native order follows its current confirmed planner rather than stale source text")
		var go := scene.get_node(BASE + "CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoCommandMatrixButton") as Button
		controller.call("_refresh_button_state")
		_check(not go.disabled, prefix + "actual existing GO control is available for the real planned order")
		go.pressed.emit()
		print("A5_R3_TIME go ", size, " ", Time.get_ticks_msec())
		controller.call("_update_ui", false, false)
		var running_context: Dictionary = controller.call("_build_native_player_readout_context") if controller.has_method("_build_native_player_readout_context") else {}
		var confirmed: Dictionary = controller.get("_phase_execution_by_fireteam")
		_check(confirmed.has(ids[0]) and int(running_context.get("executing_count", 0)) == 1, prefix + "real GO callback activates the existing owner before the running readout appears")
		var feedback := scene.get_node("TacticalUI/A5TargetOrderPanel/Contents/Feedback") as Label
		_check(order.text == "Auftrag: Wird ausgeführt" and feedback.text == "Ausführung läuft", prefix + "real running plan has no redundant start-again instruction")
		await _check_stance_after_light_refresh(scene, controller, prefix + "after actual GO: ")
		print("A5_R3_TIME stance2 ", size, " ", Time.get_ticks_msec())
	var selector := scene.get_node(TEAM + "/A5FireRuleSelector") as OptionButton
	_check(selector.item_count == 4, prefix + "readout work preserves all original fire-rule choices")
	var cards := scene.get_node_or_null("TacticalUI/MissionDropshipPanel") as Control
	if cards != null and cards.visible:
		_check(not cards.get_global_rect().intersects(identity.get_global_rect()), prefix + "compact transport controls remain separate from the mission objective")
	_check_completed_return_readout(controller, prefix)
	print("A5_R3_TIME completed_return ", size, " ", Time.get_ticks_msec())
	scene.queue_free()
	for _frame in range(2):
		await process_frame
	print("A5_R3_TIME freed ", size, " ", Time.get_ticks_msec())


func _check_completed_return_readout(controller: Node, prefix: String) -> void:
	# Synchronous UI-source fixtures only: no actor, SimulationRoot, position or
	# flight timer is changed, and the original source is restored before a frame.
	var original_cards: Array = Array(controller.get("_mission_drop_cards")).duplicate(true)
	var original_craft := String(controller.get("_mission_drop_craft_id"))
	controller.set("_mission_drop_craft_id", "")
	var completed := {"craft_id": "readout_completed_return", "state": "to_fob", "eta_seconds": 0, "passenger_count": 0, "embarked_unit_ids": []}
	var active := {"craft_id": "readout_active_flight", "state": "to_mission", "eta_seconds": 7, "passenger_count": 0, "embarked_unit_ids": []}
	controller.set("_mission_drop_cards", [completed])
	_check(bool(controller.call("_is_completed_empty_mission_dropship_card", completed)), prefix + "existing owner predicate confirms the completed empty return fixture")
	var only_completed: Dictionary = controller.call("_build_native_player_readout_context")
	_check(Array(only_completed.get("transport_cards", [])).is_empty(), prefix + "completed empty return alone leaves no active transport in the readout")
	_check(Dictionary(_hud.call("build_player_readout", only_completed)).get("transport_text") == "Kein Dropship im Einsatz", prefix + "completed return does not remain visibly labelled as a return flight")
	controller.set("_mission_drop_cards", [completed, active])
	var mixed: Dictionary = controller.call("_build_native_player_readout_context")
	var visible: Array = Array(mixed.get("transport_cards", []))
	_check(visible.size() == 1 and String(Dictionary(visible[0]).get("craft_id", "")) == "readout_active_flight", prefix + "completed return beside an active flight does not inflate the active count")
	_check(String(Dictionary(_hud.call("build_player_readout", mixed)).get("transport_text", "")).contains("Im Anflug"), prefix + "remaining transport keeps its real active state")
	# The contact-focus predicate also recognizes empty departing cards. R3 must
	# not reuse that broader hide condition for an actually departing craft.
	controller.set("_mission_drop_cards", [{"craft_id": "readout_departing", "state": "outbound", "passenger_count": 0, "embarked_unit_ids": []}])
	var departing: Dictionary = controller.call("_build_native_player_readout_context")
	_check(Array(departing.get("transport_cards", [])).size() == 1, prefix + "active empty departure remains visible without borrowing the contact-focus filter")
	controller.set("_mission_drop_cards", original_cards)
	controller.set("_mission_drop_craft_id", original_craft)


func _check_stance_after_light_refresh(scene: Node, controller: Node, prefix: String) -> void:
	var profile := OS.get_cmdline_user_args().has("--a5-r3-profile") and prefix.contains("after actual GO")
	if profile:
		for spec in [["TacticalController", "set_mission_visible_frame_timing_debug_enabled"], ["SimulationRoot", "set_runtime_tick_budget_debug_enabled"], ["SimulationRoot", "set_navigation_debug_enabled"], ["CombatLoopDriver", "set_combat_tick_budget_debug_enabled"], ["Primary3DView", "set_runtime_frame_timing_debug_enabled"]]:
			var node := scene.get_node_or_null(spec[0])
			if node != null and node.has_method(spec[1]):
				node.call(spec[1], true)
		var simulation := scene.get_node_or_null("SimulationRoot")
		if simulation != null:
			simulation.connect("tick_processed", _record_profile_navigation_tick.bind(simulation))
	var layer := scene.get_node("TacticalUI")
	var grid := scene.get_node(BASE + "CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid")
	var stance_path := TEAM + "/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox/TacticalStancePanel/MarginContainer/VBoxContainer/HBoxContainer/"
	var writes := int(layer.get_meta("native_a5_rect_write_count", 0))
	var applies := int(grid.get_meta("native_a5_geometry_apply_count", 0))
	var readable := true
	var drawable := true
	# Exercise the production light path repeatedly, with real idle frames after
	# the legacy stance writer. A full-refresh-only fixture hid this regression.
	for _refresh in range(16):
		var profile_started := Time.get_ticks_usec()
		var physics_before := Engine.get_physics_frames()
		controller.call("_update_ui", false, false)
		# The normal mission can refresh command availability after the readout.
		# This path used to overwrite full words with the old 9px abbreviations.
		controller.call("_refresh_button_state")
		controller.call("_apply_fireteam_panel_action_button_contract")
		await process_frame
		if profile and (_refresh < 4 or _refresh == 15):
			var observation := {"frame": _refresh, "elapsed_usec": Time.get_ticks_usec() - profile_started, "physics_frames": Engine.get_physics_frames() - physics_before}
			for spec in [["TacticalController", "get_mission_visible_frame_timing_debug_snapshot"], ["TacticalController", "get_mission_ui_refresh_timing_debug_snapshot"], ["TacticalController", "get_mission_runtime_surface_timing_debug_snapshot"], ["SimulationRoot", "get_runtime_tick_budget_debug_snapshot"], ["SimulationRoot", "get_navigation_debug_snapshot"], ["CombatLoopDriver", "get_combat_tick_budget_debug_snapshot"], ["CombatLoopDriver", "get_combat_hotspot_debug_snapshot"], ["Primary3DView", "get_runtime_frame_timing_debug_snapshot"]]:
				var node := scene.get_node_or_null(spec[0])
				if node != null and node.has_method(spec[1]):
					observation[spec[1]] = node.call(spec[1])
			print("A5_R3_PROFILE ", JSON.stringify(observation))
		for spec in [["CautiousButton", "Vorsichtig"], ["NormalButton", "Normal"], ["AggressiveButton", "Offensiv"]]:
			var button := scene.get_node(stance_path + String(spec[0])) as Button
			readable = readable and button.text == String(spec[1]) and button.get_theme_font_size("font_size") >= 13
			drawable = drawable and button.is_visible_in_tree() and button.size.x >= 88.0 and button.size.y >= 28.0 and not button.get_signal_connection_list("pressed").is_empty()
	_check(readable, prefix + "repeated real light refreshes retain full readable selected-team stance labels")
	_check(drawable, prefix + "light-refreshed stance controls remain drawable with their existing callbacks")
	_check(writes == int(layer.get_meta("native_a5_rect_write_count", 0)) and applies == int(grid.get_meta("native_a5_geometry_apply_count", 0)), prefix + "stance restoration never rebuilds A5 geometry or queues idle rect writes")


func _record_profile_navigation_tick(tick: int, simulation: Node) -> void:
	# Opt-in evidence only: sample every active-query tick, rather than only the
	# last physics tick of a slow process frame (which can already be idle).
	var snapshot: Dictionary = simulation.call("get_navigation_debug_snapshot")
	var queries: Array = []
	for query in snapshot.get("last_queries", []):
		if int(query.get("tick", -1)) == tick:
			queries.append(query)
	if queries.is_empty():
		return
	var hpa = simulation.get("_hpa_pathfinder")
	print("A5_NAV_QUERY_TICK ", JSON.stringify({"tick": tick, "queries": queries, "last_hpa_query": hpa.call("get_last_query_debug_snapshot")}))


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)


func _print_readout_facts(prefix: String, label: Label) -> void:
	if label == null:
		print("A5_R3_READOUT_DIAGNOSTIC ", JSON.stringify({"viewport": prefix, "missing_label": true}))
		return
	var ancestors: Array = []
	var ancestor: Node = label
	while ancestor != null and ancestors.size() < 8:
		var fact := {"path": str(ancestor.get_path()), "class": ancestor.get_class()}
		if ancestor is CanvasItem:
			fact["visible"] = (ancestor as CanvasItem).visible
			fact["in_tree_visible"] = (ancestor as CanvasItem).is_visible_in_tree()
		if ancestor is Control:
			var control := ancestor as Control
			fact["rect"] = str(control.get_global_rect())
			fact["minimum"] = str(control.get_combined_minimum_size())
			fact["clips"] = control.clip_contents
		ancestors.append(fact)
		ancestor = ancestor.get_parent()
	print("A5_R3_READOUT_DIAGNOSTIC ", JSON.stringify({"viewport": prefix, "text": label.text, "visible_line_count": label.get_visible_line_count(), "line_count": label.get_line_count(), "font_size": label.get_theme_font_size("font_size"), "autowrap": label.autowrap_mode, "max_lines_visible": label.max_lines_visible, "clip_text": label.clip_text, "ancestors": ancestors}))
