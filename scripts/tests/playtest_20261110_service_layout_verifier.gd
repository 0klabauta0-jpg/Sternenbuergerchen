extends SceneTree
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var layer:=CanvasLayer.new(); root.add_child(layer)
	var panel: Control=load("res://scripts/meta/singleplayer_services_presenter.gd").new(); layer.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.position=Vector2(root.get_visible_rect().size.x-350,80); panel.size=Vector2(330,510)
	for frame in 8: await process_frame
	if panel.has_method("fit_to_viewport"): panel.call("fit_to_viewport")
	for frame in 8: await process_frame
	var supply=load("res://scripts/core/singleplayer_supply_state.gd").new(); supply.configure(["c"])
	var snapshot: Dictionary={"supply":supply.get_supply_snapshot(),"crafts":[{"craft_id":"c","display_name":"Entermesser","location_id":"trade_outpost","busy":false}],"service_contexts_by_craft_id":{"c":{"location_id":"trade_outpost","craft_busy":false}},"space_travel":{"craft_id":"c","phase":"surface"}}
	panel.call("configure",func():return snapshot,func(_operation:String,_payload:Dictionary):return {"ok":true})
	var bounds:=panel.get_global_rect(); var viewport:=panel.get_viewport_rect()
	var ok: bool=viewport.encloses(bounds) and bounds.position.y>=190 and bounds.size.y<600 and not panel.get("_feedback").text.contains("Kein reales Schiff")
	print("SERVICE_LAYOUT passed=",ok," bounds=",bounds," viewport=",viewport," minimum=",panel.get_combined_minimum_size()," feedback=",panel.get("_feedback").text)
	layer.queue_free(); await process_frame; quit(0 if ok else 1)

