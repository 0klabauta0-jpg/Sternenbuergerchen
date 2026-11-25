extends SceneTree
## Personal und Trupp: die Ausruestungsspalte ist hoechstens 620 breit und nichts in ihr ragt ueber ihren Rand.

const PRESENTER: GDScript = preload("res://scripts/meta/homebase_operations_presenter.gd")

class SnapshotOwner extends Control:
	var snapshot: Dictionary = {}
	var _character_sheet_open := false
	func get_operations_snapshot() -> Dictionary:
		return snapshot.duplicate(true)
	func request_operation(_operation: String, _payload: Dictionary) -> Dictionary:
		return {"ok": true, "message": ""}

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
	root.add_child(owner)
	owner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var presenter: Control = PRESENTER.new()
	presenter.call("configure", owner)
	owner.add_child(presenter)
	await process_frame
	presenter.set_process(false)
	for dimensions in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		for mode in ["personnel", "squad"]:
			root.content_scale_size = dimensions
			root.size = dimensions
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
	print("HOMEBASE_EQUIPMENT_WIDTH: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _snapshot() -> Dictionary:
	var alpha := {"id": "fixture_alpha", "name": "Alexandra Lange-Hohenstein", "role": "Truppfuehrung", "status": "Im Trupp", "portrait_path": "", "portrait_id": "char_portrait_001", "fireteam_id": "ft1", "can_assign": false, "can_remove": true, "can_edit": true, "loadout": {"armor": "medium", "weapon_1": "rifle", "weapon_2": "none"}}
	var bravo: Dictionary = alpha.duplicate(true)
	bravo.merge({"id": "fixture_bravo", "name": "Bora", "role": "Sanitaet"}, true)
	return {"mode": "squad", "roster": [alpha, bravo], "focused_unit": alpha, "focused_fireteam_id": "ft1", "focused_fireteam": {"id": "ft1", "label": "ALPHA", "members": [alpha, bravo], "busy": false}, "fireteams": [{"id": "ft1", "label": "ALPHA"}], "selected_craft": {}, "crafts": [], "mission_id": "grid_sweep", "missions": [{"id": "grid_sweep", "label": "Operation: Grid Sweep"}], "loadout_options": {"armor": [{"id": "medium", "label": "Medium"}, {"id": "heavy", "label": "Heavy"}], "weapon_1": [{"id": "rifle", "label": "Rifle"}], "weapon_2": [{"id": "none", "label": "None"}]}}
