extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1129 Tactical Communication Bubble Typography and Mode Contract Reconciliation ===")
	root.size = Vector2i(1920, 1080)
	var map_data: RefCounted = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task1129_bubble_contract", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 3)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	primary_view.call("configure_from_map", map_data)
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"feedback_bubble_dicts": [
			_world_thought("blue_lead", Vector2(96.0, 96.0), "Leader haelt Winkel."),
			_world_thought("blue_medic", Vector2(160.0, 96.0), "Medic bleibt nah."),
			_world_thought("blue_engineer", Vector2(224.0, 96.0), "Technik ist klar."),
			_hud_command(),
		],
	})
	for _frame in range(8):
		await process_frame
	var entries: Array = Array(Dictionary(primary_view.call("get_render_snapshot")).get("feedback_bubble_entries", []))
	var world_entries: Array = _entries_for_anchor_space(entries, "")
	var hud_entries: Array = _entries_for_anchor_space(entries, "hud")
	_assert(world_entries.size() == 3, "World thought bubbles dedupe by Unit instead of collapsing the Fireteam")
	_assert(_entries_have_distinct_units(world_entries, 3), "World thought entries retain three distinct Unit IDs")
	_assert(hud_entries.size() == 1, "HUD command bubble remains deduped at Fireteam mini-card level")
	_assert(int(Dictionary(hud_entries[0]).get("hud_font_size", 0)) >= 10 if not hud_entries.is_empty() else false, "HUD bubble snapshot exposes a readable font size of at least 10 px")
	primary_view.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _world_thought(unit_id: String, anchor_position: Vector2, text: String) -> Dictionary:
	return {
		"bubble_id": "bubble_npc_thought_focus",
		"display_type": "comic_bubble",
		"visual_only": true,
		"source": "npc_thought_peek",
		"purpose": "npc_thought",
		"category": "npc_thought_peek",
		"fireteam_id": "blue",
		"unit_id": unit_id,
		"anchor_position": anchor_position,
		"text": text,
		"path": "res://Assets/Comic/comic-6.png",
	}


func _hud_command() -> Dictionary:
	return {
		"bubble_id": "bubble_ftl_ack",
		"display_type": "comic_bubble",
		"visual_only": true,
		"source": "fireteamleader_command_feedback",
		"purpose": "ftl_response",
		"category": "ftl_command_feedback",
		"fireteam_id": "blue",
		"unit_id": "blue_lead",
		"anchor_space": "hud",
		"hud_anchor_source": "fireteam_mini_card",
		"hud_anchor_position": Vector2(260.0, 160.0),
		"anchor_position": Vector2(96.0, 96.0),
		"text": "Roger, BLUE bewegt sich.",
		"max_size": Vector2i(148, 52),
	}


func _entries_for_anchor_space(entries: Array, anchor_space: String) -> Array:
	var result: Array = []
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("anchor_space", "")).strip_edges().to_lower() == anchor_space:
			result.append(entry)
	return result


func _entries_have_distinct_units(entries: Array, expected_count: int) -> bool:
	var unit_ids: Dictionary = {}
	for entry_variant in entries:
		unit_ids[String(Dictionary(entry_variant).get("unit_id", "")).strip_edges()] = true
	unit_ids.erase("")
	return unit_ids.size() == expected_count


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
