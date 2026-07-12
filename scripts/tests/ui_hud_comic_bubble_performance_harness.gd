class_name UIHudComicBubblePerformanceHarness
extends RefCounted

const HOMEBASE_SCENE_PATH: String = "res://scenes/meta/homebase_test_screen.tscn"
const FOB_SCENE_PATH: String = "res://scenes/meta/fob_test_screen.tscn"
const MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const COMIC_BUBBLE_SETTINGS_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_settings.gd")
const COMIC_BUBBLE_RUNTIME_GATE_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_runtime_gate.gd")
const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const SCREEN_WAIT_FRAMES: int = 8


func run_all(scene_parent: Node) -> Dictionary:
	scene_parent.get_window().size = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	var screens: Dictionary = {}
	screens["homebase"] = await _measure_scene(scene_parent, "homebase", HOMEBASE_SCENE_PATH)
	screens["fob"] = await _measure_scene(scene_parent, "fob", FOB_SCENE_PATH)
	screens["mission_hud"] = await _measure_scene(scene_parent, "mission_hud", MISSION_SCENE_PATH)
	screens["main_menu"] = await _measure_scene(scene_parent, "main_menu", MAIN_MENU_SCENE_PATH)
	await _drain_owned_ui_delays(scene_parent)
	var bubbles: Dictionary = await _measure_bubble_modes(scene_parent)
	var theme: Dictionary = _measure_theme_reuse()
	return {
		"schema_version": 1,
		"screens": screens,
		"bubbles": bubbles,
		"theme": theme,
		"summary": _build_summary(screens, bubbles, theme),
	}


func _measure_scene(scene_parent: Node, scenario_id: String, scene_path: String) -> Dictionary:
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		return {
			"scenario_id": scenario_id,
			"scene_path": scene_path,
			"ok": false,
			"error": "missing_scene",
		}
	var started_usec: int = Time.get_ticks_usec()
	var scene_root := packed_scene.instantiate()
	scene_parent.add_child(scene_root)
	await _wait_frames(scene_parent, SCREEN_WAIT_FRAMES)
	var elapsed_usec: int = Time.get_ticks_usec() - started_usec
	var counts: Dictionary = _count_ui_nodes(scene_root)
	var fixed_window: Dictionary = _build_fixed_window_snapshot(scene_parent)
	scene_root.queue_free()
	await _wait_frames(scene_parent, 2)
	return {
		"scenario_id": scenario_id,
		"scene_path": scene_path,
		"ok": true,
		"ready_usec": elapsed_usec,
		"counts": counts,
		"fixed_window": fixed_window,
	}


func _measure_bubble_modes(scene_parent: Node) -> Dictionary:
	var payloads: Array = _make_bubble_payloads(8, "ftl_command_feedback")
	var thought_payloads: Array = _make_bubble_payloads(6, "npc_thought_peek")
	var off_snapshot: Dictionary = await _measure_bubble_mode(scene_parent, "off", payloads, false)
	var minimal_snapshot: Dictionary = await _measure_bubble_mode(scene_parent, "minimal", payloads, false)
	var normal_snapshot: Dictionary = await _measure_bubble_mode(scene_parent, "normal", payloads, false)
	var thought_hidden: Dictionary = await _measure_bubble_mode(scene_parent, "normal", thought_payloads, false, COMIC_BUBBLE_SETTINGS_SCRIPT.CATEGORY_NPC_THOUGHT_PEEK)
	var thought_hold: Dictionary = await _measure_bubble_mode(scene_parent, "normal", thought_payloads, true, COMIC_BUBBLE_SETTINGS_SCRIPT.CATEGORY_NPC_THOUGHT_PEEK)
	return {
		"off": off_snapshot,
		"minimal": minimal_snapshot,
		"normal": normal_snapshot,
		"thought_hidden": thought_hidden,
		"thought_hold": thought_hold,
	}


func _measure_bubble_mode(scene_parent: Node, mode: String, payloads: Array, thought_peek_active: bool, category: String = COMIC_BUBBLE_SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK) -> Dictionary:
	var gate = COMIC_BUBBLE_RUNTIME_GATE_SCRIPT.new()
	gate.call("set_settings", {
		"mode": mode,
		"max_active_bubbles_total": 4,
		"max_thought_bubbles_total": 4,
		"command_feedback_cooldown_msec": 0,
		"thought_feedback_cooldown_msec": 0,
	})
	gate.call("set_thought_peek_override", thought_peek_active)
	var performance_snapshot: Dictionary = Dictionary(gate.call("build_filter_performance_snapshot", payloads, category, 1000))
	var filtered_payloads: Array = Array(gate.call("filter_payloads", payloads, category, 1000))
	var render_snapshot: Dictionary = await _render_bubble_payloads(scene_parent, filtered_payloads)
	gate.call("clear_thought_peek_override")
	return {
		"mode": mode,
		"category": category,
		"thought_peek_active": thought_peek_active,
		"gate": performance_snapshot,
		"render": render_snapshot,
	}


func _render_bubble_payloads(scene_parent: Node, payloads: Array) -> Dictionary:
	var map_data: RefCounted = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task219_bubble_perf", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	scene_parent.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"feedback_bubble_dicts": payloads,
	})
	await _wait_frames(scene_parent, 8)
	var snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	primary_view.queue_free()
	await _wait_frames(scene_parent, 2)
	return {
		"feedback_bubble_visual_count": int(snapshot.get("feedback_bubble_visual_count", 0)),
		"feedback_bubble_entries": Array(snapshot.get("feedback_bubble_entries", [])).duplicate(true),
		"render_transparency_budget": Dictionary(snapshot.get("render_transparency_budget", {})).duplicate(true),
	}


func _make_bubble_payloads(count: int, category: String) -> Array:
	var result: Array = []
	for index in range(count):
		var important: bool = index % 3 == 0
		result.append({
			"bubble_id": "task219_%s_%02d" % [category, index],
			"display_type": "comic_bubble",
			"visual_only": true,
			"anchor_position": Vector2(96.0 + float(index * 12), 120.0 + float(index * 8)),
			"text": "OK" if not important else "CONTACT",
			"path": "",
			"unit_id": "task219_unit_%02d" % index,
			"fireteam_id": "blue",
			"feedback_state": "contact" if important else "accepted",
			"feedback_action": "move",
			"source": "fireteamleader_command_feedback" if category != COMIC_BUBBLE_SETTINGS_SCRIPT.CATEGORY_NPC_THOUGHT_PEEK else "npc_thought",
			"purpose": "npc_thought" if category == COMIC_BUBBLE_SETTINGS_SCRIPT.CATEGORY_NPC_THOUGHT_PEEK else "command_feedback",
			"priority": 100 if important else 10,
		})
	return result


func _measure_theme_reuse() -> Dictionary:
	TACTICAL_UI_THEME_SCRIPT.call("clear_stylebox_cache")
	var first_stylebox: StyleBoxFlat = TACTICAL_UI_THEME_SCRIPT.call("build_flat_stylebox", Color("151c21"), Color("4d5a63"), 6, 1, Vector4(8.0, 6.0, 8.0, 6.0))
	var second_stylebox: StyleBoxFlat = TACTICAL_UI_THEME_SCRIPT.call("build_flat_stylebox", Color("151c21"), Color("4d5a63"), 6, 1, Vector4(8.0, 6.0, 8.0, 6.0))
	var third_stylebox: StyleBoxFlat = TACTICAL_UI_THEME_SCRIPT.call("build_flat_stylebox", Color("252d33"), Color("4d5a63"), 6, 1, Vector4(8.0, 6.0, 8.0, 6.0))
	var snapshot: Dictionary = Dictionary(TACTICAL_UI_THEME_SCRIPT.call("get_stylebox_cache_snapshot"))
	return {
		"same_stylebox_reused": first_stylebox == second_stylebox,
		"different_stylebox_distinct": first_stylebox != third_stylebox,
		"cache_snapshot": snapshot,
	}


func _count_ui_nodes(node: Node, depth: int = 0) -> Dictionary:
	var counts: Dictionary = {
		"node_count": 1,
		"control_count": 0,
		"visible_control_count": 0,
		"label_count": 0,
		"rich_text_label_count": 0,
		"texture_rect_count": 0,
		"button_count": 0,
		"panel_container_count": 0,
		"scroll_container_count": 0,
		"max_depth": depth,
	}
	if node is Control:
		counts["control_count"] = 1
		counts["visible_control_count"] = 1 if (node as Control).visible else 0
	if node is Label:
		counts["label_count"] = 1
	if node is RichTextLabel:
		counts["rich_text_label_count"] = 1
	if node is TextureRect:
		counts["texture_rect_count"] = 1
	if node is Button:
		counts["button_count"] = 1
	if node is PanelContainer:
		counts["panel_container_count"] = 1
	if node is ScrollContainer:
		counts["scroll_container_count"] = 1
	for child in node.get_children():
		var child_counts: Dictionary = _count_ui_nodes(child, depth + 1)
		for key_variant in child_counts.keys():
			var key: String = String(key_variant)
			if key == "max_depth":
				counts[key] = maxi(int(counts.get(key, 0)), int(child_counts.get(key, 0)))
			else:
				counts[key] = int(counts.get(key, 0)) + int(child_counts.get(key, 0))
	return counts


func _build_fixed_window_snapshot(scene_parent: Node) -> Dictionary:
	var target_size: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	var actual_size: Vector2i = scene_parent.get_window().size
	return {
		"target_size": target_size,
		"actual_size": actual_size,
		"matches_target": actual_size == target_size,
	}


func _build_summary(screens: Dictionary, bubbles: Dictionary, theme: Dictionary) -> Dictionary:
	return {
		"screen_count": screens.size(),
		"has_homebase": screens.has("homebase") and bool(Dictionary(screens.get("homebase", {})).get("ok", false)),
		"has_fob": screens.has("fob") and bool(Dictionary(screens.get("fob", {})).get("ok", false)),
		"has_mission_hud": screens.has("mission_hud") and bool(Dictionary(screens.get("mission_hud", {})).get("ok", false)),
		"has_main_menu": screens.has("main_menu") and bool(Dictionary(screens.get("main_menu", {})).get("ok", false)),
		"has_ui_counts": _all_screens_have_counts(screens),
		"fixed_window_stable": _all_screens_fixed(screens),
		"bubble_off_zero": int(Dictionary(Dictionary(bubbles.get("off", {})).get("render", {})).get("feedback_bubble_visual_count", -1)) == 0,
		"bubble_normal_capped": int(Dictionary(Dictionary(bubbles.get("normal", {})).get("render", {})).get("feedback_bubble_visual_count", 99)) <= 4,
		"thought_hold_bounded": int(Dictionary(Dictionary(bubbles.get("thought_hold", {})).get("render", {})).get("feedback_bubble_visual_count", 99)) <= 4,
		"thought_hidden_zero": int(Dictionary(Dictionary(bubbles.get("thought_hidden", {})).get("render", {})).get("feedback_bubble_visual_count", -1)) == 0,
		"theme_reuse_enabled": bool(theme.get("same_stylebox_reused", false)) and bool(theme.get("different_stylebox_distinct", false)),
	}


func _all_screens_have_counts(screens: Dictionary) -> bool:
	for screen_variant in screens.values():
		var counts: Dictionary = Dictionary(Dictionary(screen_variant).get("counts", {}))
		if int(counts.get("control_count", 0)) <= 0 or int(counts.get("label_count", 0)) <= 0:
			return false
	return true


func _all_screens_fixed(screens: Dictionary) -> bool:
	for screen_variant in screens.values():
		var fixed_window: Dictionary = Dictionary(Dictionary(screen_variant).get("fixed_window", {}))
		if not bool(fixed_window.get("matches_target", false)):
			return false
	return true


func _wait_frames(scene_parent: Node, frame_count: int) -> void:
	var tree := scene_parent.get_tree()
	for _index in range(maxi(frame_count, 0)):
		await tree.process_frame


func _drain_owned_ui_delays(scene_parent: Node) -> void:
	if scene_parent == null:
		return
	await _wait_frames(scene_parent, 4)
