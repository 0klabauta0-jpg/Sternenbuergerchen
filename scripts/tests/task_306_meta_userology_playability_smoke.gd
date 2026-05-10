extends SceneTree

const TEAM_NAME_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/team_name_generator.gd")
const APP_SHELL_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/app_shell_return_navigation_contract.gd")
const META_USEROLOGY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/meta_userology_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_306 Meta Userology Playability Smoke ===")
	var team_name: Dictionary = Dictionary(TEAM_NAME_GENERATOR_SCRIPT.call("generate_team_name", "task306", "player", 0))
	var nav: Dictionary = Dictionary(APP_SHELL_CONTRACT_SCRIPT.call("build_shell_snapshot", {"editor": {"dirty": true}}))
	var transit: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_transit_snapshot", [META_USEROLOGY_CONTRACT_SCRIPT.call("build_transit_entry", "unit_a", "operator", "homebase", "fob", "ship", 55.0, 9)]))
	var drag: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_drag_badge_contract"))
	var flightdeck: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_compact_flightdeck_card", {"craft_id": "ship", "display_name": "Sternlift", "pilot_unit_id": "pilot"}, [{"unit_id": "unit_a"}]))
	_assert(String(team_name.get("team_name", "")).strip_edges().length() > 4, "Smoke covers generated team name")
	_assert(bool(nav.get("all_primary_areas_covered", false)), "Smoke covers main-menu return routes")
	_assert(bool(drag.get("drag_preview_above_windows", false)), "Smoke covers NPC drag layer")
	_assert(int(transit.get("entry_count", 0)) == 1, "Smoke covers unified transit progress")
	_assert(Array(flightdeck.get("occupant_cards", [])).size() == 1, "Smoke covers dropship occupant card")
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
