extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1154 Fireteam Contact Loss Language Clarity ===")
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	for _frame in range(12):
		await process_frame
	var controller := mission.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission exposes tactical controller")
	if controller != null:
		_assert(String(controller.call("_format_fireteam_visible_contact_text", "lost", 1)) == "1 KONTAKT WEG", "One lost contact cannot be read as one lost operator")
		_assert(String(controller.call("_format_fireteam_visible_contact_text", "lost", 2)) == "2 KONTAKTE WEG", "Multiple lost contacts keep explicit contact semantics")
		_assert(String(controller.call("_format_fireteam_visible_contact_text", "confirmed", 2)) == "2 KONTAKTE BEST.", "Confirmed contacts name their information domain")
		_assert(String(controller.call("_format_fireteam_visible_contact_text", "spotted", 1)) == "1 KONTAKT SICHT", "Spotted contact remains compact and explicit")
		_assert(String(controller.call("_format_fireteam_visible_contact_text", "suspected", 2)) == "2 KONTAKTE VERM.", "Suspected contacts remain compact and explicit")
		_assert(String(controller.call("_format_fireteam_visible_contact_text", "", 0)) == "KEIN KONTAKT", "No-contact state remains unchanged")
		var health_text := String(controller.call("_format_fireteam_visible_health_text", {"fit_count": 5, "total_count": 5}))
		_assert(health_text == "FIT 5/5", "Health remains a separate truthful status")
		var long_movement_state := {
			"effective_style": "bounding",
			"readability_status_line": "BND 1/18 G2/2 | 3 move | 2 cover",
		}
		var compact_movement := String(controller.call("_compact_fireteam_movement_text", long_movement_state, {}))
		_assert(compact_movement == "BND", "Mini-card movement keeps the short style instead of the full map diagnostic")
		var snapshot := Dictionary(controller.call("_build_fireteam_status_card_entry", "blue", [], {}, {
			"state": "lost",
			"count": 1,
		}))
		_assert(snapshot.has("movement_detail_text"), "Full movement readability remains available outside the compact line")
	mission.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
