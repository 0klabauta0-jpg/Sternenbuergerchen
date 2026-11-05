extends SceneTree

const CATALOG = preload("res://scripts/meta/portrait_identity_catalog.gd")
const META = preload("res://scripts/meta/meta_layer_flow.gd")
const FOB = preload("res://scenes/meta/fob_test_screen.tscn")
const DEBRIEF = preload("res://scenes/meta/debrief_test_screen.tscn")
var passed := 0
var failed := 0
var homebase_returns := 0
var legacy_returns := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var entry: Dictionary = CATALOG.load_catalog().entries[0]
	var legacy: String = entry.legacy_paths[0]
	var expected: String = entry.path
	var flow = META.new()
	flow.set("_all_team_units", [{"unit_id":"portrait_consumer_probe", "portrait_path":legacy, "portrait_id":entry.id}])
	check(flow.call("_resolve_unit_portrait_path", "portrait_consumer_probe") == expected, "Meta transport resolves saved portrait identity to the new portrait")
	check(flow.call("_resolve_unit_portrait_path", "missing") == "", "Unknown unit does not acquire a fabricated transport identity")
	flow.free()
	var fob = FOB.instantiate()
	var texture = fob.call("_load_portrait_texture", legacy)
	check(texture is AtlasTexture and texture.resource_path == expected, "Legacy FOB tools resolve old saved paths through the same portrait catalog")
	check(fob.call("_load_portrait_texture", "") == null, "Empty portrait keeps the existing absent-value behavior")
	fob.free()
	var debrief = DEBRIEF.instantiate()
	debrief.connect("return_to_homebase_requested", func(): homebase_returns += 1)
	debrief.connect("return_to_fob_requested", func(): legacy_returns += 1)
	root.add_child(debrief)
	debrief.show()
	await process_frame
	var home := debrief.get_node("Panel/Margin/VBox/ButtonRow/ReturnToHomebaseButton") as Button
	var old := debrief.get_node("Panel/Margin/VBox/ButtonRow/ReturnToFOBButton") as Button
	check(home.is_visible_in_tree() and not home.disabled, "Normal debrief offers a usable Homebase return")
	check(not old.visible and old.focus_mode == Control.FOCUS_NONE, "Normal debrief omits the deferred FOB staging stop")
	home.pressed.emit()
	check(homebase_returns == 1, "Real primary button emits the existing Homebase callback once")
	debrief.call("_on_return_to_fob_pressed")
	check(legacy_returns == 1, "Legacy FOB callback remains available for compatibility tools")
	debrief.queue_free()
	await process_frame
	print("PORTRAIT_CONSUMERS_RETURN: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)
