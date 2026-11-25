extends SceneTree
## Flugdeck-Aufbau v2 (20261125): von links Schiffsdetail, Schiffsleiste, Liste Personal, Liste Trupps, Vorschau.
var checks := 0
var failures := 0
func _init() -> void: call_deferred("_run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)
	else:
		print("PASS: ", label)
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	screen.request_operation("navigate", {"mode": "mission"})
	var presenter: Node = screen.get("_operations_presenter")
	var specs := {Vector2i(1920, 1080): [400, 240, 250, 330], Vector2i(1280, 720): [340, 200, 220, 280]}
	for resolution in specs:
		root.size = resolution
		(screen as Control).set_deferred("size", Vector2(resolution))
		await process_frame
		if (screen as Control).size != Vector2(resolution): (screen as Control).size = Vector2(resolution)
		for i in 24: await process_frame
		presenter.refresh()
		for i in 4: await process_frame
		var tag := "%s" % resolution
		var columns: Dictionary = presenter.get("_columns")
		var order: Array = ["equipment", "flight", "roster", "squad"]
		var spec: Array = specs[resolution]
		var previous_end := -1.0
		var in_order := true
		for index in order.size():
			var column: Control = columns[order[index]]
			check(column.visible, "column %s visible %s" % [order[index], tag])
			var rect := column.get_global_rect()
			if rect.position.x < previous_end - 0.5: in_order = false
			previous_end = rect.end.x
			print("WIDTH %s %s=%d" % [tag, order[index], int(rect.size.x)])
			if rect.size.x > float(spec[index]) + 1.0:
				for node in column.find_children("*", "Control", true, false):
					if (node as Control).get_combined_minimum_size().x > float(spec[index]) - 30.0: print("MINWIDE ", node.get_path(), " ", (node as Control).get_combined_minimum_size())
			check(rect.size.x <= float(spec[index]) + 1.0, "column %s width <= %d %s" % [order[index], spec[index], tag])
			if resolution.x == 1920: check(absf(rect.size.x - float(spec[index])) <= 1.0, "column %s width is %d at 1920" % [order[index], spec[index]])
		check(in_order, "columns run equipment, flight, roster, squad from the left %s" % tag)
		var workspace: Control = presenter.get("_workspace")
		print("WORKSPACE %s=%s flow=%s" % [tag, workspace.size, (flow as Control).size if flow is Control else "-"])
		check(columns.squad.get_global_rect().end.x <= workspace.get_global_rect().end.x + 1.0, "columns fit the workspace %s" % tag)
		var stage: Control = presenter.get("_reference_stage")
		print("STAGE %s visible=%s rect=%s" % [tag, stage.visible, Rect2(stage.position, stage.size)])
		var preview: Rect2 = presenter.get("_preview_layout_rect")
		var base_node: Control = presenter.get("_base")
		if resolution.x == 1920:
			check(preview.size.x >= 280.0 and (stage.visible or base_node.is_visible_in_tree()), "preview present and >= 280 wide %s" % tag)
			check(preview.position.x >= columns.squad.position.x + columns.squad.size.x - 1.0, "preview right of the lists %s" % tag)
		else:
			check(preview.size.x == 0.0 and not stage.visible, "preview hidden when narrow %s" % tag)
		var flight: Control = columns.flight
		for button_name in ["BoardFireteam", "UnboardFireteam", "StartMission"]:
			var button: Button = presenter.find_child(button_name, true, false)
			check(button != null, "button %s exists %s" % [button_name, tag])
			if button == null: continue
			check(button.size.x <= 200.0 and button.size.y <= 40.0, "button %s is small %s" % [button_name, tag])
			check(button.mouse_filter != Control.MOUSE_FILTER_IGNORE and button.pressed.get_connections().size() > 0, "button %s clickable %s" % [button_name, tag])
			if button.is_visible_in_tree():
				check(flight.get_global_rect().grow(1).encloses(button.get_global_rect()), "button %s inside flight column %s" % [button_name, tag])
		# Nichts ragt seitlich ueber den Spaltenrand.
		for key in order:
			var column: Control = columns[key]
			var edge := column.get_global_rect().grow(1)
			var overflow := 0
			for node in column.find_children("*", "Control", true, false):
				var control: Control = node
				if not control.is_visible_in_tree() or control.size.x <= 0.0: continue
				var rect := control.get_global_rect()
				if rect.position.x < edge.position.x or rect.end.x > edge.end.x:
					overflow += 1
					printerr("OVERFLOW ", key, " ", control.get_path(), " ", rect)
			check(overflow == 0, "nothing sticks out of column %s %s" % [key, tag])
		var snapshot: Dictionary = screen.call("get_operations_snapshot")
		var crafts: Array = Array(snapshot.get("crafts", []))
		var selected: Dictionary = Dictionary(snapshot.get("selected_craft", {}))
		check(crafts.size() > 0, "snapshot has ships %s" % tag)
		var gold := 0
		for craft_variant in crafts:
			var craft: Dictionary = Dictionary(craft_variant)
			var card: Node = presenter.find_child("ShipCard_" + String(craft.id).validate_node_name(), true, false)
			check(card != null, "ShipCard for %s %s" % [craft.id, tag])
			if card != null and bool(card.get_meta("selected", false)):
				gold += 1
				check(String(craft.id) == String(selected.get("id", "")), "highlighted card is the selected ship %s" % tag)
		check(gold == 1, "exactly one ship card highlighted %s" % tag)
		var detail: Control = presenter.find_child("ShipDetail", true, false)
		check(detail != null and detail.is_visible_in_tree() and columns.equipment.is_ancestor_of(detail), "ShipDetail shown in the equipment column %s" % tag)
		if detail != null:
			check(detail.find_child("PilotSlot", true, false) != null, "ShipDetail has PilotSlot %s" % tag)
			check(detail.find_child("Cargo", true, false) != null, "ShipDetail has Cargo %s" % tag)
			var wanted := clampi(int(selected.get("crew_capacity", 0)) - 1, 0, 4)
			var troop := 0
			for node in detail.find_children("TroopSlot_*", "", true, false): troop += 1
			check(troop == wanted, "TroopSlot count %d == %d %s" % [troop, wanted, tag])
		for team_variant in Array(snapshot.get("fireteams", [])):
			var team: Dictionary = Dictionary(team_variant)
			var row: Node = presenter.find_child("TeamRow_" + String(team.id).validate_node_name(), true, false)
			check(row != null and row.is_visible_in_tree(), "TeamRow for %s %s" % [team.id, tag])
			if row != null and not Array(team.members).is_empty():
				check(row.find_child("LeaderStar", true, false) != null, "TeamRow %s shows leader star %s" % [team.id, tag])
		var roster_rows: Dictionary = presenter.get("_rows")
		check(roster_rows.size() == Array(snapshot.get("roster", [])).size() and roster_rows.size() > 0, "Personal list holds the whole roster %s" % tag)
		check(columns.roster.visible and presenter.find_child("ReturnPersonToRoster", true, false) != null, "Personal list reachable %s" % tag)
	flow.queue_free()
	await process_frame
	print("FLUGDECK_LAYOUT_V2 passed=%d failed=%d" % [checks - failures, failures])
	quit(1 if failures else 0)
