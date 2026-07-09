extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_951_decision_overlay_real_f6_visual_review.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCHEMA := "sternenbuergerchen.decision_overlay_real_f6_visual_review.v1"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_951 Decision Overlay Real F6 Visual Review ===")
	_test_docs_and_static_hooks()
	await _test_controller_exports_human_readable_decision_overlay_review()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_951_decision_overlay_real_f6_visual_review: FAILED")
		quit(1)
		return
	print("TASK_951_decision_overlay_real_f6_visual_review: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_951 task file exists")
	_assert(task_text.contains("TASK_951 - Decision Overlay Real F6 Visual Review"), "Task names TASK_951")
	_assert(status_text.contains("TASK_951 - Decision Overlay Real F6 Visual Review"), "Implementation status tracks TASK_951")
	_assert(roadmap_text.contains("TASK_951 - Decision Overlay Real F6 Visual Review (implementiert"), "Roadmap marks TASK_951 implemented")
	_assert(command_contract_text.contains("Decision Overlay Real F6 Visual Review (TASK_951)"), "Mission feedback contract documents TASK_951")
	_assert(clarity_contract_text.contains("Decision Overlay Real F6 Visual Review (TASK_951)"), "Decision clarity contract documents TASK_951")
	_assert(controller_text.contains("get_decision_overlay_real_f6_visual_review_snapshot"), "Controller exposes TASK_951 review snapshot")
	_assert(controller_text.contains("_humanize_order_preview_threat_overlay_card"), "Controller humanizes debug choice ids")
	_assert(controller_text.contains("decision_overlay_real_f6_visual_review"), "Command feedback exports TASK_951 review snapshot")


func _test_controller_exports_human_readable_decision_overlay_review() -> void:
	var controller_script: Resource = load(CONTROLLER_PATH)
	if controller_script == null:
		_assert(false, "Controller script can be loaded")
		return
	var controller: Node = controller_script.new()
	get_root().add_child(controller)
	await process_frame
	if not controller.has_method("get_order_preview_threat_overlay_f6_hud_snapshot"):
		_assert(false, "Controller still has TASK_950 snapshot")
		controller.queue_free()
		return
	if not controller.has_method("get_decision_overlay_real_f6_visual_review_snapshot"):
		_assert(false, "Controller has TASK_951 public review snapshot")
		controller.queue_free()
		return
	var hud_snapshot: Dictionary = Dictionary(controller.call("get_order_preview_threat_overlay_f6_hud_snapshot"))
	var choice_line: String = String(hud_snapshot.get("mission_control_choice_line", ""))
	_assert(choice_line.contains("SAFE") and choice_line.contains("RISKY") and choice_line.contains("SUICIDAL"), "Choice line keeps risk tokens")
	_assert(not _contains_raw_choice_id(choice_line), "Choice line hides raw debug choice ids")
	_assert(choice_line.length() <= 96, "Choice line fits stricter visual-review limit")
	var cards: Array = Array(hud_snapshot.get("visible_choice_cards", []))
	_assert(cards.size() == 3, "HUD still exposes three choice cards")
	for card_variant in cards:
		var card: Dictionary = Dictionary(card_variant)
		_assert(not _contains_raw_choice_id(String(card.get("display_title", ""))), "Card display title hides raw ids")
		_assert(not _contains_raw_choice_id(String(card.get("display_text", ""))), "Card display text hides raw ids")
		_assert(not String(card.get("display_text", "")).strip_edges().is_empty(), "Card has player-facing display text")
	var review: Dictionary = Dictionary(controller.call("get_decision_overlay_real_f6_visual_review_snapshot"))
	_assert(String(review.get("schema", "")) == SCHEMA, "TASK_951 review schema matches")
	_assert(String(review.get("task_id", "")) == "TASK_951", "TASK_951 review task id matches")
	_assert(String(review.get("source_task_id", "")) == "TASK_950", "TASK_951 review links TASK_950")
	_assert(String(review.get("automated_readability_gate", "")) == "pass", "Automated readability gate passes")
	_assert(String(review.get("status", "")) == "ready_for_real_f6_sight_check", "Review is ready for real F6 sight check")
	_assert(bool(review.get("manual_review_required", false)), "Review still requires real visual confirmation")
	_assert(not bool(review.get("manual_review_done", true)), "Review does not fake manual visual confirmation")
	_assert(_snapshot_is_read_only(review), "TASK_951 review remains read-only")
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(feedback.get("order_preview_threat_overlay_choice_line", "")) == choice_line, "Command feedback uses the humanized choice line")
	_assert(String(Dictionary(feedback.get("decision_overlay_real_f6_visual_review", {})).get("schema", "")) == SCHEMA, "Command feedback embeds TASK_951 review")
	controller.queue_free()


func _contains_raw_choice_id(text: String) -> bool:
	return text.contains("covered_push") or text.contains("exposed_crossing") or text.contains("kill_zone_dash")


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
