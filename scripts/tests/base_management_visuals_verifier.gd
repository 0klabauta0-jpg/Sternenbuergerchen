extends SceneTree
var checks:=0
var failures:=0
func _init()->void:call_deferred("_run")
func check(value:bool,message:String)->void:
 checks+=1
 if value:print("PASS: ",message)
 else:failures+=1;printerr("FAIL: ",message)
func _run()->void:
 root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
 load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","new")
 var flow:Node=load("res://scenes/meta/meta_layer_test.tscn").instantiate();root.add_child(flow)
 for i in 8:await process_frame
 var screen:Node=flow.get_node("HomebaseScreen")
 var presenter:Node=screen.get("_operations_presenter")
 var services:Node=presenter.get("_services_view")
 var supply:RefCounted=flow.get("_singleplayer_runtime").get("_supply")
 var initial:Dictionary=supply.export_state().duplicate(true)
 for resolution:Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size=resolution;root.content_scale_size=resolution
  for section:String in ["jobs","build","workshop","data","ship","inventory"]:
   if section=="jobs":
    presenter.call("_navigate_from_sidebar","jobs")
    var board:Node=presenter.get("_job_board")
    if bool(board.get("_details_expanded")):board.call("_toggle_job_details","satellite_recovery")
    check(not board.get("_detail_card").visible,"mission details can remain compact and collapsed")
    board.get("_card_buttons").satellite_recovery.pressed.emit()
    check(board.get("_detail_card").visible,"mission title expands its real details")
   else:presenter.call("_open_base_management",section)
   await create_timer(0.22).timeout
   for i in 16:await process_frame
   var workspace:Control=presenter.get("_workspace")
   check(root.get_visible_rect().grow(1).encloses(workspace.get_global_rect()),"workspace fits "+section+str(resolution))
   check(bool(presenter.get("_right_flyout_active")) and presenter.get("_base").is_visible_in_tree(),"drawer keeps base visible behind "+section)
   var drawer:Control=presenter.call("_workspace_flyout_panel")
   check(drawer.size.x<workspace.size.x and root.get_visible_rect().encloses(drawer.get_global_rect()),"drawer remains narrower than base workspace")
   if section in ["build","workshop","data","ship"]:
    check(services.is_visible_in_tree(),"real styled "+section+" page is shown")
    var count:=0
    for action:Dictionary in services.get("_campaign_buttons").values():
     if action.button.is_visible_in_tree():
      count+=1
      check(action.card.is_visible_in_tree(),"visible action has visible card")
      check(root.get_visible_rect().grow(1).encloses(action.button.get_global_rect()),"real action fits visible viewport")
    # Sollwerte Stand 24.11.2026 (vorher 1 Bauaktion, 3 Werkstattaktionen vom 10.11.): Bau = Zweites Landepad + Wohncontainer mit vier Betten
    # (f8e667364, 23.11., Unterkunft B); Werkstatt = 11 x Herstellen + 5 x Entwickeln aus den gewachsenen Rezept- und Blaupausendaten; Daten = Hochladen.
    if section!="ship":check(count==(16 if section=="workshop" else (2 if section=="build" else 1)),"existing action count preserved for "+section+" (observed "+str(count)+")")
    var card_ids:Array=services.get("_cards").get_children().map(func(node:Node):return node.get_instance_id())
    for i in 8:services.refresh()
    check(services.get("_cards").get_children().map(func(node:Node):return node.get_instance_id())==card_ids,"unchanged snapshots preserve service cards")
    if section=="ship":
     check(not services.get("_buy").is_visible_in_tree() and not services.get("_sell").is_visible_in_tree(),"home tankservice contains no shop buy or sell actions")
     for button:Button in services.get("_tool_buttons").values():check(not button.is_visible_in_tree(),"home tankservice hides tool purchases")
     check(services.get("_refuel").size.x<services.get("_ship_panel").size.x*.8,"refuel uses a compact action button")
     var display:Dictionary=services.get("_snapshot").duplicate(true)
     display.service_contexts_by_craft_id[String(services.get("_selected_craft_id"))]={"location_id":"trade_outpost","craft_busy":false}
     services.refresh(display)
     check(services.get("_buy").is_visible_in_tree(),"trade-post projection retains the existing purchase controls")
     services.refresh()
   if section=="jobs":
    var board:Node=presenter.get("_job_board")
    check(board.get("_job_cards").get_child_count()==1,"Smart Mobile initially shows only the unlocked satellite mission")
    check(board.get("_details").get_global_rect().size.x>=250,"selected mission retains readable detail column")
    check(root.get_visible_rect().encloses(board.get("_accept").get_global_rect()),"first mission acceptance is visible without scrolling")
    # Der Himmelskoerper heisst im Spiel Neralis (campaign_display_catalog.gd BODY_NAMES; auch review_completion_job_briefing_verifier), nicht mehr "Glut (Planet)".
    var briefing_text:String=String(board.get("_details").text)
    check(briefing_text.contains("Himmelskörper: Neralis (Mond)") and briefing_text.contains("Einsatzgebiet: Aschental") and not briefing_text.contains("Glut") and String(board.get("_objectives").text).contains("Satelliten-Absturzstelle finden"),"body destination and actual objective are distinct in briefing")
   if section=="inventory":
    check(presenter.get("_inventory_panel").get("_identity_portrait").is_visible_in_tree(),"original portrait is shown in shared identity and equipment card")
    check(drawer.size.x>=800,"equipment drawer is wider for the enlarged figure and slots")
    var rest_row:Control=presenter.get("_inventory_panel").get("_rest_row")
    check(rest_row.size.y<=45 and rest_row.size.x<300,"rest label remains one compact line and does not displace equipment")
    check(presenter.get("_inventory_panel").get("_slots").get_global_rect().position.y<rest_row.get_global_rect().end.y+20,"equipment follows the rest switch without a blank vertical gap")
   if DisplayServer.get_name()!="headless":
    await RenderingServer.frame_post_draw
    DirAccess.make_dir_recursive_absolute("C:/dev/SternenBuergerchen/output/base_management_visuals_20261110")
    root.get_texture().get_image().save_png("C:/dev/SternenBuergerchen/output/base_management_visuals_20261110/%s_%d.png"%[section,resolution.x])
 # standing_clock ist die Spieluhr der Daueraufträge (6eb30e252, 24.11.; Flow tickt sie je Bild) und laeuft waehrend der Navigation weiter. Sie ist weder
 # Vorrat noch Fracht: Sie darf nur vorwaerts laufen; jeder andere Eintrag (Credits, Bestand, Fracht, Sperren, Zaehler) muss unveraendert sein.
 var after_state:Dictionary=supply.export_state().duplicate(true)
 var clock_after:float=float(after_state.get("standing_clock",-1.0))
 var clock_before:float=float(initial.get("standing_clock",0.0))
 after_state["standing_clock"]=initial.get("standing_clock")
 check(after_state==initial and clock_after>=clock_before,"visual navigation changes no supply or cargo")
 presenter.get("_flyout_close").pressed.emit()
 check(not bool(presenter.get("_right_flyout_active")) and String(presenter.get("_mode"))=="base","drawer closes back to the base")
 var floating:Control=flow.get("_singleplayer_services")
 floating.show();floating.fit_to_viewport()
 for i in 8:await process_frame
 check(floating.size.x<=340,"compact floating service view retains narrow width")
 flow.queue_free();await process_frame
 print("MANAGEMENT_VISUALS checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)

