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
 root.size=Vector2i(1920,1080)
 load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","new")
 var flow:Node=load("res://scenes/meta/meta_layer_test.tscn").instantiate();root.add_child(flow)
 for i in 8:await process_frame
 var screen:Node=flow.get_node("HomebaseScreen")
 var presenter:Node=screen.get("_operations_presenter")
 check(presenter.find_child("OperationsBack",true,false)==null,"duplicate Zur Truppansicht button removed")
 var flight:Control=presenter.get("_flight_management_bar")
 check(not flight.visible,"flight submenu starts folded")
 presenter.get("_nav").mission.mouse_entered.emit()
 check(flight.visible and flight.find_child("OpenBaseServices",true,false)!=null,"Flugdeck reveals its Tankservice child")
 flight.find_child("OpenBaseServices",true,false).pressed.emit()
 check(not flight.visible and presenter.get("_services_view").get("_section")=="ship","Tankservice opens real ship service and folds submenu")
 screen.request_operation("details",{"unit_id":"campaign_leader"})
 for i in 12:await process_frame
 var popup:Control=screen.get_node("CharacterSheetPopup")
 var panel:Node=popup.find_child("CharacterInventoryPanel",true,false)
 var preview:Control=panel.get("_body_preview")
 check(popup.is_visible_in_tree(),"actual NPC details opened")
 check(String(preview.get_meta("preview_unit_id",""))=="campaign_leader","full-body preview uses actual selected actor")
 check(bool(preview.get_meta("preview_uses_existing_model",false)),"full-body preview uses existing map character model")
 check(preview.size.y>=500,"shared character card gives the figure more vertical room")
 check(bool(preview.get_meta("preview_idle_pose",false)),"preview freezes existing idle pose rather than showing the bind pose")
 check(panel.get("_identity_portrait").texture!=null,"original identity portrait is retained beside the shared character name")
 var badges:Control=panel.get("_badges")
 check(badges.get_child_count()>=3 and badges.get_children().all(func(child):return child is TextureRect and child.texture!=null and not child.tooltip_text.is_empty()),"actual character bonuses use the existing rank icons and tooltips")
 check(panel.get("_rest_row").size_flags_horizontal==Control.SIZE_SHRINK_BEGIN and panel.get("_rest_row").get_child(0)==panel.get("_rest"),"rest switch is compact and immediately left of its label")
 check(popup.find_child("CharacterDerivationOverview",true,false)==null,"unused origins box is removed from character overview")
 for key:String in ["armor","weapon_1","weapon_2"]:
  check(not preview.get_global_rect().intersects(panel.get("_slots").get_node("InventorySlot_"+key).get_global_rect()),"equipment slot does not cover the figure: "+key)
 var before:Dictionary=screen.get_personnel_inventory_view("campaign_leader").inventory.duplicate(true)
 var slot:Control=panel.get("_slots").get_node("InventorySlot_weapon_1")
 slot.payload_dropped.emit({"source_container_id":"base:homebase","item_id":"medictool"})
 for i in 8:await process_frame
 var feedback:Label=popup.find_child("CharacterInventoryFeedback",true,false)
 check(not feedback.visible and feedback.text.is_empty(),"successful equipment change leaves no stock update heading")
 var after:Dictionary=screen.get_personnel_inventory_view("campaign_leader").inventory
 check(int(after["base:homebase"].items.get("medictool",0))==int(before["base:homebase"].items.get("medictool",0))-1,"equipping consumes one actual free item")
 check(int(after["base:homebase"].items.get("pistol",0))==int(before["base:homebase"].items.get("pistol",0))+1,"previously carried pistol returns once to free base stock")
 check(String(screen.get_personnel_inventory_view("campaign_leader").unit.loadout.weapon_1)=="medictool","equipment slot calls existing authoritative equip operation")
 check(popup.find_child("CharacterSheetDetails_vehicles",true,false)!=null and not popup.find_child("CharacterSheetDetails_vehicles",true,false).visible,"vehicle values begin folded")
 for key:String in ["methods","functions","roles","specialty"]:
  var toggle:Button=popup.find_child("CharacterSheetToggle_"+key,true,false)
  var branch:Control=popup.find_child("CharacterSheetDetails_"+key,true,false)
  check(toggle!=null and branch!=null,"derived tree has "+key+" branch")
  if toggle!=null:toggle.pressed.emit();check(branch.visible,"tree branch expands independently")
 var resolver=load("res://scripts/meta/npc_rank_badge_resolver.gd")
 var hover:String=resolver.format_badge_tooltip({"label":"Pilot","score":0.6,"reason":"Piloteneignung: bester Fahrzeugwert 0.70, Wahrnehmung 0.60, Disziplin 0.55 und Meldequalität 0.50."})
 check(hover.contains("\nWahrnehmung") and hover.contains("\nDisziplin") and hover.contains("\nMeldequalität"),"badge hover lists real factor names and values vertically")
 for resolution:Vector2i in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(3440,1440)]:
  root.size=resolution;root.content_scale_size=resolution
  screen.call("_update_character_sheet_visibility")
  for i in 12:await process_frame
  print("DETAIL_RECT requested=",resolution," viewport=",root.get_visible_rect()," popup=",popup.get_global_rect())
  check(Rect2(Vector2.ZERO,Vector2(resolution)).grow(1).encloses(popup.get_global_rect()),"full-height popup fits "+str(resolution))
  check(popup.size.y>=resolution.y-25,"popup uses available screen height")
  var equipment_column := popup.find_child("CharacterInventoryScroll",true,false) as Control
  check(popup.get_global_rect().encloses(equipment_column.get_global_rect()),"wider equipment column remains inside the popup "+str(resolution))
  var portrait:Control=panel.find_child("IdentityPortrait",true,false)
  var name_row:Label=panel.find_child("IdentityName",true,false)
  var primary:Label=panel.find_child("PrimaryRole",true,false)
  var secondary:Label=panel.find_child("SecondaryRole",true,false)
  var status:Label=panel.find_child("PersonnelCondition",true,false)
  var rest_row:Control=panel.get("_rest_row")
  var armor:Control=panel.get("_slots").get_node("InventorySlot_armor")
  check(portrait.size.x>=112 and portrait.size.y>=140,"portrait stays legible "+str(resolution))
  check(name_row.global_position.x>=portrait.get_global_rect().end.x+8 and name_row.global_position.y<portrait.get_global_rect().end.y,"profile facts start beside the portrait "+str(resolution))
  check(primary.get_global_rect().end.y<=secondary.global_position.y and secondary.get_global_rect().end.y<=status.global_position.y and not secondary.clip_text,"role and status rows remain separate and uncut "+str(resolution))
  check(panel.find_child("IdentityProfile",true,false)==null,"header omits callsign, origin and age "+str(resolution))
  check(primary.get_line_count()==1 and secondary.get_line_count()==1,"Anja's two role labels each fit on one line "+str(resolution))
  check(rest_row.get_parent()==name_row.get_parent() and rest_row.global_position.x>=name_row.get_global_rect().end.x and absf(rest_row.global_position.y-name_row.global_position.y)<=5,"rest switch sits after the name on the same line "+str(resolution))
  check(armor.global_position.y-panel.global_position.y<185,"first equipment slot starts close to the header "+str(resolution))
  check(status.text.begins_with("Status: ") and status.text.contains("FT1"),"header keeps authoritative assignment status "+str(resolution))
  var identity:Control=panel.get("_identity")
  check(identity.get_global_rect().end.y<=armor.global_position.y,"equipment begins after identity and status "+str(resolution))
  var camera:Camera3D=preview.get("_camera")
  var bounds:AABB=preview.get("_model_bounds")
  var frame:=Rect2(Vector2.ZERO, camera.get_viewport().get_visible_rect().size)
  var model_rect:=Rect2(camera.unproject_position(bounds.position), Vector2.ZERO)
  for corner in 8:
   model_rect=model_rect.expand(camera.unproject_position(bounds.get_endpoint(corner)))
  print("DETAIL_MODEL preview=",preview.size," frame=",frame," model=",model_rect," bounds=",bounds," camera=",camera.size)
  check(model_rect.size.y>=300 and frame.encloses(model_rect),"full model fits the tighter camera frame "+str(resolution))
  var visible_model:=Rect2(preview.global_position+model_rect.position,model_rect.size)
  check(not visible_model.intersects(portrait.get_global_rect()) and not visible_model.intersects(rest_row.get_global_rect()),"portrait and rest switch clear the rendered model "+str(resolution))
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw
   var capture_dir := OS.get_environment("STERNENBUERGERCHEN_DETAIL_CAPTURE_DIR")
   if capture_dir.is_empty():
    capture_dir=ProjectSettings.globalize_path("res://output/character_navigation_20261110")
   DirAccess.make_dir_recursive_absolute(capture_dir)
   root.get_texture().get_image().save_png(capture_dir.path_join("details_%d.png"%resolution.x))
 root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720)
 for i in 4:await process_frame
 screen.call("_update_character_sheet_visibility")
 var view:Dictionary=screen.get_personnel_inventory_view("campaign_leader")
 var unit:Dictionary=view.unit.duplicate()
 unit.secondary_role="Aufklärung, Fernmeldekoordination und technische Einsatzunterstützung"
 unit.condition="injured"
 panel.call("update_snapshot",view.inventory,unit,view.craft_id,view.accessible,view.equipment_allowed,view.actor)
 for i in 12:await process_frame
 var long_secondary:Label=panel.find_child("SecondaryRole",true,false)
 var readiness:Label=panel.find_child("ReadinessStatus",true,false)
 var armor_slot:Control=panel.get("_slots").get_node("InventorySlot_armor")
 check(long_secondary.get_line_count()>1 and readiness.visible and readiness.text=="Bereitschaft: Verletzt","long roles wrap and independent readiness stays visible")
 check(readiness.get_global_rect().end.y<=armor_slot.global_position.y and badges.get_global_rect().end.y<=armor_slot.global_position.y,"long role and readiness keep equipment clear")
 flow.queue_free();await process_frame
 print("CHARACTER_NAVIGATION checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
