extends SceneTree
## Personal und Trupp: die Ausruestungsspalte ist hoechstens 620 breit und nichts in ihr ragt ueber ihren Rand.

const PRESENTER: GDScript = preload("res://scripts/meta/homebase_operations_presenter.gd")

class SnapshotOwner extends Control:
	var snapshot: Dictionary = {}
	var _character_sheet_open := false
	func get_operations_snapshot() -> Dictionary:
		return snapshot.duplicate(true)
	var inventory: Dictionary = {}
	var equips: Array = []
	func request_operation(operation: String, payload: Dictionary) -> Dictionary:
		if operation == "inventory_equip":
			equips.append(payload.duplicate())
		if operation == "inventory_transfer":
			var from_items: Dictionary = inventory[String(payload.source_container_id)].items
			var to_items: Dictionary = inventory[String(payload.destination_container_id)].items
			var item := String(payload.item_id)
			var amount := mini(int(payload.amount), int(from_items.get(item, 0)))
			if amount > 0:
				from_items[item] = int(from_items[item]) - amount
				if int(from_items[item]) <= 0:
					from_items.erase(item)
				to_items[item] = int(to_items.get(item, 0)) + amount
		return {"ok": true, "message": ""}
	func get_personnel_inventory_view(unit_id: String, operations_snapshot: Dictionary = {}) -> Dictionary:
		var unit: Dictionary = Dictionary(operations_snapshot.get("focused_unit", {}))
		return {"inventory": inventory.duplicate(true), "unit": unit, "craft_id": "", "accessible": inventory.keys(), "equipment_allowed": true, "actor": null, "person": unit}

var _passed := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
	else:
		_failed += 1
		print("FAIL ", label)


func _run() -> void:
	var owner := SnapshotOwner.new()
	owner.snapshot = _snapshot()
	owner.inventory = {
		"base:homebase": {"capacity": 200, "items": {"ammo_light": 30, "bandage": 5}},
		"unit:fixture_alpha:backpack": {"capacity": 8, "armor_chip_capacity": 6, "items": {}},
	}
	root.add_child(owner)
	owner.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var presenter: Control = PRESENTER.new()
	presenter.call("configure", owner)
	owner.add_child(presenter)
	await process_frame
	presenter.set_process(false)
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		for mode in ["personnel", "squad"]:
			owner.size = Vector2(dimensions)
			owner.inventory["unit:fixture_alpha:backpack"].items = {}
			owner.inventory["base:homebase"].items = {"ammo_light": 30, "bandage": 5}
			owner.snapshot["mode"] = mode
			for _i in range(3):
				await process_frame
			presenter.call("refresh")
			presenter.call("_layout_columns")
			for _i in range(3):
				await process_frame
			var tag := "%dx%d %s" % [dimensions.x, dimensions.y, mode]
			var column: Control = (presenter.get("_columns") as Dictionary)["equipment"]
			print("EQUIPMENT_WIDTH ", tag, " ", column.size.x)
			_check(column.visible and column.size.x <= 620.0 + 0.5, tag + ": Ausruestungsspalte hoechstens 620 breit")
			var rect := column.get_global_rect()
			var worst := 0.0
			for node in column.find_children("*", "Control", true, false):
				var control := node as Control
				if control.is_visible_in_tree() and control.size.x > 0.0:
					worst = maxf(worst, control.get_global_rect().end.x - rect.end.x)
			_check(worst <= 1.0, tag + ": nichts ragt ueber den rechten Rand der Ausruestungsspalte (%.1f)" % worst)
			await _check_bag(presenter, owner, column, tag)
	print("HOMEBASE_EQUIPMENT_WIDTH: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


## Rüstungs-/Munitionsfach und Rucksack (Block "CarriedBackpack"): sichtbar, in der Spalte, unter dem Sekundär-Fach, nimmt Magazine per Ziehen an.
func _check_bag(presenter: Control, owner: Control, column: Control, tag: String) -> void:
	var bag := column.find_child("CarriedBackpack", true, false) as Control
	var secondary := column.find_child("InventorySlot_weapon_2", true, false) as Control
	_check(bag != null and secondary != null, tag + ": Fach-Block und Sekundaer-Fach vorhanden")
	if bag == null or secondary == null:
		return
	var rect := column.get_global_rect()
	var br := bag.get_global_rect()
	print("BAG ", tag, " bag=", br, " secondary=", secondary.get_global_rect(), " column=", rect)
	_check(bag.is_visible_in_tree() and br.size.x > 0.0, tag + ": Fach-Block sichtbar")
	_check(br.position.x >= rect.position.x - 0.5 and br.end.x <= rect.end.x + 0.5, tag + ": Fach-Block liegt waagerecht ganz in der Spalte")
	_check(br.position.y >= secondary.get_global_rect().end.y - 0.5, tag + ": Fach-Block liegt unter dem Sekundaer-Fach")
	_check(br.size.x <= secondary.get_global_rect().size.x + 2.0, tag + ": Fach-Block hoechstens so breit wie das Sekundaer-Fach (%.1f <= %.1f)" % [br.size.x, secondary.get_global_rect().size.x])
	_check_visible_without_scrolling(presenter, column, tag)
	_check_hatch(column, owner, bag, tag)
	await _check_slot_drops(column, owner, tag)
	var backpack := "unit:fixture_alpha:backpack"
	for item in ["ammo_light", "bandage"]:
		var payload := {"type": "inventory_item", "source_container_id": "base:homebase", "item_id": item, "label": item}
		var accepts: bool = bag.call("_can_drop_data", Vector2(10, 10), payload)
		_check(accepts, tag + ": Fach-Block nimmt %s an" % item)
		bag.call("_drop_data", Vector2(10, 10), payload)
		for _i in range(3):
			await process_frame
		_check(int(owner.inventory[backpack].items.get(item, 0)) > 0, tag + ": %s liegt nach dem Ablegen im Fach" % item)
		bag = column.find_child("CarriedBackpack", true, false) as Control
		_check(bag != null and bag.is_visible_in_tree(), tag + ": Fach-Block nach dem Ablegen noch sichtbar")
		if bag == null:
			return


## Figur, alle Faecher und der Anfang der Lagerliste liegen im sichtbaren Bereich des umgebenden Scrollbereichs (bei 1920x1080 ohne Scrollversatz).
func _check_visible_without_scrolling(presenter: Control, column: Control, tag: String) -> void:
	var scroll: ScrollContainer = null
	var node: Node = column.get_parent()
	while node != null:
		if node is ScrollContainer:
			scroll = node as ScrollContainer
			break
		node = node.get_parent()
	var view: Rect2 = scroll.get_global_rect() if scroll != null else presenter.get_viewport().get_visible_rect()
	var parts := {
		"Figur": column.find_child("PersonnelBodyPreview", true, false),
		"Rüstungsfach": column.find_child("InventorySlot_armor", true, false),
		"Primaer": column.find_child("InventorySlot_weapon_1", true, false),
		"Sekundaer": column.find_child("InventorySlot_weapon_2", true, false),
		"Fach-Block": column.find_child("CarriedBackpack", true, false),
		"Basislager": column.find_child("Inventory_base_homebase", true, false),
	}
	if parts["Figur"] == null:
		for candidate in column.find_children("*", "Control", true, false):
			if String((candidate as Control).get_script().resource_path if (candidate as Control).get_script() != null else "").ends_with("personnel_body_preview.gd"):
				parts["Figur"] = candidate
	print("SCROLL ", tag, " scroll=", scroll != null, " offset=", scroll.scroll_vertical if scroll != null else -1, " view=", view)
	var strict := tag.begins_with("1920x1080")
	if strict and scroll != null:
		_check(scroll.scroll_vertical == 0, tag + ": kein Scrollversatz")
	for part_name in parts:
		var control := parts[part_name] as Control
		_check(control != null and control.is_visible_in_tree(), tag + ": %s vorhanden und sichtbar" % part_name)
		if control == null or not strict:
			continue
		var r := control.get_global_rect()
		print("  ", part_name, " ", r)
		_check(r.position.y >= view.position.y - 0.5 and r.end.y <= view.end.y + 0.5, tag + ": %s liegt ganz im sichtbaren Bereich" % part_name)


## Leeres Faech: Schraffur (ohne Mausfang); belegtes Fach: keine.
func _check_hatch(column: Control, owner: Control, bag: Control, tag: String) -> void:
	var secondary := column.find_child("InventorySlot_weapon_2", true, false) as Control
	var primary := column.find_child("InventorySlot_weapon_1", true, false) as Control
	var sec_hatch := secondary.get_node_or_null("Hatch") as Control
	_check(sec_hatch != null and sec_hatch.mouse_filter == Control.MOUSE_FILTER_IGNORE, tag + ": leeres Sekundaer-Fach hat Schraffur ohne Mausfang")
	_check(primary.get_node_or_null("Hatch") == null, tag + ": belegtes Primaer-Fach hat keine Schraffur")
	var items: Dictionary = owner.inventory["unit:fixture_alpha:backpack"].items
	var bag_hatch := bag.get_node_or_null("Hatch")
	_check((bag_hatch != null) == items.is_empty(), tag + ": Fach-Block hat Schraffur genau wenn leer")


## Jedes Fach nimmt ein passendes Ablegen an; Rüstung und Waffe werden wirklich abgelegt (Equip-Anfrage mit richtigem Fach).
func _check_slot_drops(column: Control, owner: Control, tag: String) -> void:
	var cases := {"armor": "armor_light", "weapon_1": "rifle", "weapon_2": "pistol"}
	for key in cases:
		var slot := column.find_child("InventorySlot_" + String(key), true, false) as Control
		_check(slot != null and slot.is_visible_in_tree(), tag + ": Fach %s sichtbar" % key)
		if slot == null:
			continue
		var payload := {"type": "inventory_item", "source_container_id": "base:homebase", "item_id": cases[key], "label": cases[key]}
		_check(bool(slot.call("_can_drop_data", Vector2(10, 10), payload)), tag + ": Fach %s nimmt %s an" % [key, cases[key]])
		var before: int = (owner as SnapshotOwner).equips.size()
		slot.call("_drop_data", Vector2(10, 10), payload)
		for _i in range(2):
			await process_frame
		var equips: Array = (owner as SnapshotOwner).equips
		_check(equips.size() == before + 1 and String(Dictionary(equips[equips.size() - 1]).get("slot", "")) == String(key) and String(Dictionary(equips[equips.size() - 1]).get("item_id", "")) == String(cases[key]), tag + ": Ablegen in %s loest Anlegen aus" % key)


func _snapshot() -> Dictionary:
	var alpha := {"id": "fixture_alpha", "name": "Alexandra Lange", "role": "Truppfuehrung", "status": "Im Trupp", "portrait_path": "", "portrait_id": "char_portrait_001", "fireteam_id": "ft1", "can_assign": false, "can_remove": true, "can_edit": true, "loadout": {"armor": "medium", "weapon_1": "rifle", "weapon_2": "none"}}
	var bravo: Dictionary = alpha.duplicate(true)
	bravo.merge({"id": "fixture_bravo", "name": "Bora", "role": "Sanitaet"}, true)
	return {"singleplayer": {"supply": {"inventory": {"base:homebase": {}}}}, "mode": "squad", "roster": [alpha, bravo], "focused_unit": alpha, "focused_fireteam_id": "ft1", "focused_fireteam": {"id": "ft1", "label": "ALPHA", "members": [alpha, bravo], "busy": false}, "fireteams": [{"id": "ft1", "label": "ALPHA"}], "selected_craft": {}, "crafts": [], "mission_id": "grid_sweep", "missions": [{"id": "grid_sweep", "label": "Operation: Grid Sweep"}], "loadout_options": {"armor": [{"id": "medium", "label": "Medium"}, {"id": "heavy", "label": "Heavy"}], "weapon_1": [{"id": "rifle", "label": "Rifle"}], "weapon_2": [{"id": "none", "label": "None"}]}}
