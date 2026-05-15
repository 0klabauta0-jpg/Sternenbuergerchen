extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_418_fireteam_mini_card_suppression_explainer.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HTML_PATH: String = "res://docs/reports/fireteam_mini_card_explainer.html"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_418 Fireteam Mini Card Suppression Explainer ===")
	await _test_fireteam_mini_card_shows_suppression()
	_test_docs_and_html()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_fireteam_mini_card_shows_suppression() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)

	var controller := scene.get_node_or_null("TacticalController")
	var card_list := scene.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox")
	_assert(controller != null and card_list != null, "Drill scene exposes controller and mini card list")
	if controller == null or card_list == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	controller.set("_suppression_state_by_fireteam", {
		"drill": {
			"value": 1.0,
			"threshold": 2.0,
			"is_suppressed": false,
			"is_heavily_suppressed": false,
			"applied_level": 0,
			"hold_until_msec": 0,
		},
	})
	controller.call("_refresh_fireteam_mini_cards")

	var drill_card := card_list.get_node_or_null("FireteamMiniCard_Drill") as Control
	_assert(drill_card != null, "Drill mini card exists")
	if drill_card != null:
		var stage_label := drill_card.get_node_or_null("Margin/VBox/StageLabel") as Label
		var supp_bar := drill_card.find_child("MiniSuppressionBar", true, false) as ProgressBar
		var stored_snapshot: Dictionary = Dictionary(drill_card.get_meta("mission_fireteam_status_card_snapshot", {}))
		var stored_suppression: Dictionary = Dictionary(stored_snapshot.get("suppression", {}))
		_assert(stage_label != null and stage_label.text.contains("SUPP 50%"), "Mini card text contains SUPP percentage")
		_assert(supp_bar != null and bool(supp_bar.get_meta("mission_fireteam_mini_suppression_bar", false)), "Mini card owns suppression progress bar")
		_assert(supp_bar != null and supp_bar.visible and supp_bar.custom_minimum_size.y >= 6.0, "Mini card renders SUPP as a visible bar")
		_assert(supp_bar != null and is_equal_approx(float(supp_bar.value), 1.0), "Suppression bar value follows fireteam suppression state")
		_assert(supp_bar != null and is_equal_approx(float(supp_bar.max_value), 2.0), "Suppression bar max follows fireteam threshold")
		_assert(int(stored_suppression.get("percent", -1)) == 50, "Stored status snapshot carries suppression percent")
		_assert(String(stored_suppression.get("state", "")) == "contact", "Suppression snapshot distinguishes contact pressure from pinned")
		_assert(drill_card.custom_minimum_size.y <= 92.0, "Mini card stays compact after adding SUPP")

	var snapshots: Array = Array(controller.call("get_fireteam_status_card_snapshot"))
	var drill_snapshot: Dictionary = _find_snapshot(snapshots, "drill")
	_assert(int(drill_snapshot.get("suppression_percent", -1)) == 50, "Public fireteam status snapshot reports suppression percent")
	_assert(String(drill_snapshot.get("suppression_state", "")) == "contact", "Public snapshot reports suppression state")
	scene.queue_free()
	await _wait_frames(2)


func _test_docs_and_html() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var html_text: String = _read_text(HTML_PATH)
	_assert(task_text.contains("TASK_418 - Fireteam Mini Card Suppression Explainer"), "TASK_418 task file exists")
	_assert(status_text.contains("TASK_418 - Fireteam Mini Card Suppression Explainer"), "Implementation status documents TASK_418")
	_assert(roadmap_text.contains("TASK_418 - Fireteam Mini Card Suppression Explainer"), "Roadmap lists TASK_418")
	for token in ["SUPP", "Fireteam Mini-Karte", "GO Statt Sichtbarem Plan", "Schematisches Abbild"]:
		_assert(html_text.contains(token), "Mini-card explainer contains %s" % token)


func _find_snapshot(snapshots: Array, fireteam_id: String) -> Dictionary:
	for snapshot_variant in snapshots:
		if typeof(snapshot_variant) != TYPE_DICTIONARY:
			continue
		var snapshot: Dictionary = Dictionary(snapshot_variant)
		if String(snapshot.get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id.strip_edges().to_lower():
			return snapshot
	return {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
