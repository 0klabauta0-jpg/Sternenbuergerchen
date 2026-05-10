extends SceneTree

const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const NPC_COMPACT_CARD_SCRIPT: GDScript = preload("res://scripts/meta/npc_compact_card.gd")
const NPC_META_CARD_SCRIPT: GDScript = preload("res://scripts/meta/npc_meta_card.gd")
const META_USEROLOGY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/meta_userology_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_301 NPC Card Drag Z-Order Badges Tooltips ===")
	var unit: Dictionary = Dictionary(Array(Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task301", 20)).get("units", []))[0])
	var compact: Control = NPC_COMPACT_CARD_SCRIPT.new()
	root.add_child(compact)
	compact.call("setup_from_profile", unit, {"compact_mode": true, "source_context": "fob_unassigned"})
	var meta: Control = NPC_META_CARD_SCRIPT.new()
	root.add_child(meta)
	meta.call("setup_from_profile", unit, {"selectable": true})
	await process_frame
	var compact_snapshot: Dictionary = Dictionary(compact.call("get_card_userology_snapshot"))
	var meta_snapshot: Dictionary = Dictionary(meta.call("get_card_userology_snapshot"))
	var contract: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_drag_badge_contract"))
	_assert(int(compact_snapshot.get("drag_preview_z_index", 0)) >= int(contract.get("drag_preview_z_index", 0)), "Drag preview uses top z-order contract")
	_assert(bool(compact_snapshot.get("drag_preview_above_windows", false)), "Drag preview is above windows")
	_assert(Vector2(compact_snapshot.get("badge_minimum_size", Vector2.ZERO)).x >= 22.0, "Compact badges are readable")
	_assert(Vector2(meta_snapshot.get("badge_minimum_size", Vector2.ZERO)).x >= 22.0, "Character sheet/meta badges are readable")
	_assert(bool(compact_snapshot.get("badge_tooltips_available", false)) and bool(meta_snapshot.get("badge_tooltips_available", false)), "Badge tooltips are available")
	compact.queue_free()
	meta.queue_free()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
