extends SceneTree
## Tankstelle am Flugdeck der Kampagnen-Heimatbasis: Das 3D-Terminal "refuel" ist eingeschaltet, heisst "Tanken",
## ist vom Startpunkt aus zu Fuss erreichbar, sein Aufruf oeffnet das Tankfenster, und 10 Einheiten Treibstoff kosten 20 Credits.
## Gilt fuer alle drei Karten (Kampagne, Erkundungskarte, Basis-Innenkarte). Abschlusszeile: HOMEBASE_REFUEL_TERMINAL passed=%d failed=%d
## Braucht ein Wegwerfprofil (SB_REVIEW2_USER_DIR), sonst Abbruch ohne Schreiben.

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const START = preload("res://scripts/meta/game_start_contract.gd")
const NAV = preload("res://scripts/meta/base_interior_navigation.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const FLOW: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")
const MAPS := ["res://maps/campaign_intro_base.json", "res://maps/homebase_frontier_exploration.json", "res://maps/base_interior_navigation.json"]

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var verdict: Dictionary = GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("HOMEBASE_REFUEL_TERMINAL refused: needs a throwaway profile (SB_REVIEW2_USER_DIR). Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	root.size = Vector2i(1920, 1080)
	for path: String in MAPS:
		await _check_map(path)
	await _check_flow()
	print("HOMEBASE_REFUEL_TERMINAL passed=%d failed=%d" % [_passed, _failed])
	quit(1 if _failed else 0)


func _terminal(layout: Dictionary) -> Dictionary:
	for terminal: Dictionary in layout.get("terminals", []):
		if String(terminal.get("id", "")) == "refuel":
			return terminal
	return {}


func _check_map(path: String) -> void:
	var tag := path.get_file()
	var layout: Dictionary = NAV.layout(path)
	var terminal := _terminal(layout)
	_check(not terminal.is_empty(), "%s: Terminal refuel ist vorhanden" % tag)
	_check(bool(terminal.get("enabled", false)), "%s: Terminal refuel ist eingeschaltet" % tag)
	_check(String(terminal.get("title", "")) == "Tanken", "%s: Terminal refuel heisst 'Tanken' (ist: %s)" % [tag, str(terminal.get("title", ""))])
	var map = NAV.load_map(path)
	var registry := REGISTRY.new()
	root.add_child(registry)
	var sizes = map.get_tile_size()
	registry.configure_iso_grid(map.get_grid_origin(), sizes.half_width, sizes.half_height, map.get_grid_topology())
	for tile in map.get_tiles():
		registry.register_tile(tile)
	var graph := NAV.new()
	graph.configure_graph(registry)
	var spawn := _grid(layout.get("avatar_spawn_grid", [0, 0]))
	var goal := _grid(terminal.get("grid", [0, 0]))
	var world_path: Array = graph.find_world_path(registry.grid_to_world(spawn), registry.grid_to_world(goal))
	_check(not world_path.is_empty(), "%s: Tankstelle ist vom Startpunkt aus erreichbar" % tag)
	registry.queue_free()
	await process_frame


func _check_flow() -> void:
	START.request_start(self, "campaign", "new")
	var flow: Node = FLOW.instantiate()
	root.add_child(flow)
	for i in 12:
		await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	var adapter: Node = flow.get("_singleplayer_runtime")
	var craft := String(flow.get_meta("singleplayer_bootstrap_craft_id"))
	# Aufruf des Terminals wie beim Ankommen der Person: dasselbe Signal, das die Basis sendet.
	var base: Node = null
	for node: Node in screen.find_children("*", "Control", true, false):
		if node.has_signal("terminal_open_requested"):
			base = node
			break
	_check(base != null, "Basiswelt mit Terminal-Signal gefunden")
	if base != null:
		base.emit_signal("terminal_open_requested", "refuel")
		for i in 40:
			await process_frame
	var services: Node = screen.find_child("BaseServices", true, false)
	_check(services != null and (services as Control).is_visible_in_tree(), "Aufruf der Tankstelle oeffnet das Tankfenster")
	var before: Dictionary = adapter.call("get_snapshot").supply
	var credits_before := float(before.get("credits", 0))
	var fuel_before := float(Dictionary(before.get("fuel_by_craft_id", {})).get(craft, 0))
	var result: Dictionary = screen.call("request_operation", "refuel", {"craft_id": craft, "amount": 10})
	for i in 10:
		await process_frame
	var after: Dictionary = adapter.call("get_snapshot").supply
	var credits_after := float(after.get("credits", 0))
	var fuel_after := float(Dictionary(after.get("fuel_by_craft_id", {})).get(craft, 0))
	_check(bool(result.get("ok", false)) and is_equal_approx(fuel_after - fuel_before, 10.0), "10 Einheiten Treibstoff gebucht (%s -> %s)" % [str(fuel_before), str(fuel_after)])
	_check(is_equal_approx(credits_before - credits_after, 20.0), "10 Einheiten kosten 20 Credits (%s -> %s)" % [str(credits_before), str(credits_after)])
	flow.queue_free()
	await process_frame


func _grid(raw) -> Vector2i:
	return Vector2i(int(raw[0]), int(raw[1]))


func _check(value: bool, label: String) -> bool:
	if value:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		printerr("FAIL: ", label)
	return value
