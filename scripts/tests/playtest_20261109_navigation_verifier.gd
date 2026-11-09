extends SceneTree

const SCREEN: PackedScene = preload("res://scenes/meta/homebase_test_screen.tscn")
var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var screen: Control = SCREEN.instantiate()
	root.add_child(screen)
	await process_frame
	var presenter: Control = screen.get_node("OperationsRoot")
	var nav: Dictionary = presenter.get("_nav")
	for id in ["base", "personnel", "squad", "jobs", "map", "mission"]:
		_expect(nav.has(id), "Navigation exposes destination " + id)
	_expect(not bool(screen.call("request_operation", "legacy").get("ok", true)), "Normal bridge cannot enter legacy workbench")
	_expect(not bool(screen.call("request_operation", "navigate", {"mode": "fob"}).get("ok", true)), "FOB cannot be entered through normal operation")
	for cycle in range(3):
		for id in ["personnel", "mission", "squad"]:
			(nav[id] as Button).pressed.emit()
			await process_frame
			_expect(String(screen.call("get_operations_snapshot").get("mode", "")) == id, "Actual navigation button selects " + id)
			_expect(not screen.get_node("Panel").visible, "Repeated navigation keeps new operations visible")
	var return_button: Button = presenter.find_child("OperationsBack", true, false) as Button
	_expect(return_button != null and return_button.is_visible_in_tree(), "Operations has visible back action")
	if return_button != null:
		return_button.pressed.emit()
		_expect(String(screen.call("get_operations_snapshot").get("mode", "")) == "squad", "Back action returns to squad")
	(nav.mission as Button).pressed.emit()
	for frame in range(4):
		await process_frame
	var launch: Button = presenter.find_child("StartMission", true, false) as Button
	_expect(launch != null and launch.get_global_rect().end.y <= 720.0, "Primary departure action fits 1280x720")
	var fob: Button = presenter.find_child("Navigate_fob", true, false) as Button
	_expect(fob != null and fob.disabled, "FOB visibly disabled")
	screen.queue_free()
	await process_frame
	print("NAVIGATION_20261109: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _expect(value: bool, message: String) -> void:
	if value:
		passed += 1
		print("PASS: " + message)
	else:
		failed += 1
		print("FAIL: " + message)
