extends SceneTree

var failures := 0
func _init() -> void: call_deferred("run")
func check(condition: bool, label: String) -> void:
	print(("PASS: " if condition else "FAIL: ") + label)
	if not condition: failures += 1
func run() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	flow.set("_current_meta_view", "homebase")
	var presenter: Node = flow.get_node("HomebaseScreen").get("_operations_presenter")
	presenter.set("_mode", "base")
	flow.call("_refresh_singleplayer_services")
	var toggle: Button = flow.get("_singleplayer_services_toggle")
	var panel: Control = flow.get("_singleplayer_services")
	check(toggle.visible and not panel.visible, "base starts with compact service control")
	toggle.pressed.emit()
	check(panel.visible and toggle.text == "Versorgung schließen", "service panel opens")
	flow.call("_refresh_singleplayer_services")
	check(panel.visible, "periodic refresh preserves open state")
	toggle.pressed.emit()
	flow.call("_refresh_singleplayer_services")
	check(not panel.visible and toggle.visible, "service panel closes and remains accessible")
	check(not toggle.tooltip_text.is_empty(), "service purpose is described")
	flow.queue_free()
	await process_frame
	if failures == 0: print("CAMPAIGN_SERVICE_TOGGLE_PASS")
	quit(0 if failures == 0 else 1)
