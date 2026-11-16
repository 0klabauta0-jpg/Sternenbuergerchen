extends SceneTree

const OUT_DIR: String = "res://docs/qa/mission_a5_20261115/"
const PATHS: Array = [
	["TacticalUI/BottomDock", "TacticalUI/BottomDock"],
	["FireteamPanel", "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel"],
	["FireteamMiniPanel", "TacticalUI/FireteamMiniPanel"],
	["A5TargetOrderPanel", "TacticalUI/A5TargetOrderPanel"],
	["MissionIdentityPanel", "TacticalUI/MissionIdentityPanel"],
	["MissionDropshipPanel", "TacticalUI/MissionDropshipPanel"],
	["MissionDropshipPanel/CompactCard", "TacticalUI/MissionDropshipPanel/CompactCard"],
	["TacticalEventLogPanel", "TacticalUI/TacticalEventLogPanel"],
	["TacticalStancePanel", "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox/TacticalStancePanel"],
	["A5FireRuleSelector", "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/A5FireRuleSelector"],
	["A5FireRuleHeading", "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/A5FireRuleHeading"],
	["A5TeamBoard", "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/A5TeamBoard"],
	["A5BoardStatus", "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/A5BoardStatus"],
	["A5TeamSummary", "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/A5TeamSummary"],
	["A5TeamPortraits", "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/A5TeamPortraits"],
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for size_value in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		root.content_scale_size = Vector2i.ZERO
		root.size = size_value
		var mission: Node = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
		var setup: Node = mission.get_node("MissionSetup")
		setup.set("defer_friendly_runtime_activation", false)
		setup.set("selected_team_unit_ids", PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie", "unit_delta"]))
		setup.set("selected_team_fireteam_ids", PackedStringArray(["ft1", "ft1", "ft2", "ft3"]))
		root.add_child(mission)
		for _i in range(24):
			await process_frame
		var controller: Node = mission.get_node("TacticalController")
		controller.call("_set_selected_fireteams", PackedStringArray(["ft1"]), false)
		controller.call("_update_ui")
		for _i in range(12):
			await process_frame
		await RenderingServer.frame_post_draw
		var tag: String = "%dx%d" % [size_value.x, size_value.y]
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT_DIR + "roh_%s.png" % tag))
		var lines: PackedStringArray = []
		for spec in PATHS:
			var node := mission.get_node_or_null(String(spec[1])) as Control
			if node == null:
				lines.append("%s\tFEHLT\t-" % spec[0])
			else:
				lines.append("%s\t%s\t%s" % [spec[0], str(node.get_global_rect()), str(node.is_visible_in_tree())])
		var f := FileAccess.open(ProjectSettings.globalize_path(OUT_DIR + "rechtecke_%s.txt" % tag), FileAccess.WRITE)
		f.store_string("\n".join(lines) + "\n")
		f.close()
		var planning: Dictionary = Dictionary(controller.call("get_planning_state"))
		planning["mission_drop_craft_id"] = "a5_ui_lz_1"
		planning["mission_drop_state"] = "waiting"
		planning["mission_drop_cards"] = [
			{"craft_id": "a5_ui_lz_1", "craft_type": "dropship", "display_name": "Entermesser", "state": "waiting", "eta_seconds": 0, "progress": 0, "passenger_count": 2, "embarked_unit_ids": ["unit_alpha"], "has_lz_position": true, "has_embarked_payload": true, "approach_angle": "NW"},
			{"craft_id": "a5_ui_lz_2", "craft_type": "dropship", "display_name": "Zweites Schiff", "state": "to_mission", "eta_seconds": 30, "progress": 0, "passenger_count": 0, "embarked_unit_ids": [], "has_lz_position": false}]
		controller.call("set_planning_state", planning)
		for _i in range(16):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT_DIR + "mit_schiff_%s.png" % tag))
		var ship_node := mission.get_node_or_null("TacticalUI/MissionDropshipPanel") as Control
		var f2 := FileAccess.open(ProjectSettings.globalize_path(OUT_DIR + "rechtecke_mit_schiff_%s.txt" % tag), FileAccess.WRITE)
		f2.store_string("MissionDropshipPanel\t%s\n" % str(ship_node.get_global_rect()))
		f2.close()
		mission.queue_free()
		for _i in range(4):
			await process_frame
	quit(0)
