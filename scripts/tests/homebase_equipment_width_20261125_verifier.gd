extends SceneTree
## Personal und Trupp: die Ausruestungsspalte ist hoechstens 620 breit und nichts in ihr ragt ueber ihren Rand.

const PRESENTER: GDScript = preload("res://scripts/meta/homebase_operations_presenter.gd")

class SnapshotOwner extends Control:
	var snapshot: Dictionary = {}
	var _character_sheet_open := false
	func get_operations_snapshot() -> Dictionary:
		return snapshot.duplicate(true)
	var inventory: Dictionary = {}
	func request_operation(operation: String, payload: Dictionary) -> Dictionary:
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


func _snapshot() -> Dictionary:
	var alpha := {"id": "fixture_alpha", "name": "Alexandra Lange", "role": "Truppfuehrung", "status": "Im Trupp", "portrait_path": "", "portrait_id": "char_portrait_001", "fireteam_id": "ft1", "can_assign": false, "can_remove": true, "can_edit": true, "loadout": {"armor": "medium", "weapon_1": "rifle", "weapon_2": "none"}}
	var bravo: Dictionary = alpha.duplicate(true)
	bravo.merge({"id": "fixture_bravo", "name": "Bora", "role": "Sanitaet"}, true)
	return {"singleplayer": {"supply": {"inventory": {"base:homebase": {}}}}, "mode": "squad", "roster": [alpha, bravo], "focused_unit": alpha, "focused_fireteam_id": "ft1", "focused_fireteam": {"id": "ft1", "label": "ALPHA", "members": [alpha, bravo], "busy": false}, "fireteams": [{"id": "ft1", "label": "ALPHA"}], "selected_craft": {}, "crafts": [], "mission_id": "grid_sweep", "missions": [{"id": "grid_sweep", "label": "Operation: Grid Sweep"}], "loadout_options": {"armor": [{"id": "medium", "label": "Medium"}, {"id": "heavy", "label": "Heavy"}], "weapon_1": [{"id": "rifle", "label": "Rifle"}], "weapon_2": [{"id": "none", "label": "None"}]}}
