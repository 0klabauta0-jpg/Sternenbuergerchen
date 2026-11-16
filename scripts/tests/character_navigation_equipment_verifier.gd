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
 presenter.call("set_interface_settings_path_for_tests","user://nav_groups_fixture.cfg")
 presenter.call("set_nav_group_open","mission",true)
 check(flight.visible and flight.find_child("OpenBaseServices",true,false)!=null,"Flugdeck reveals its Tankservice child")
 flight.find_child("OpenBaseServices",true,false).pressed.emit()
 check(flight.visible and presenter.get("_services_view").get("_section")=="ship","Tankservice opens real ship service and keeps the submenu open")
 screen.request_operation("details",{"unit_id":"campaign_leader"})
 for i in 12:await process_frame
 var popup:Control=screen.get_node("CharacterSheetPopup")
 var panel:Node=popup.find_child("CharacterInventoryPanel",true,false)
 var preview:Control=panel.get("_body_preview")
 check(popup.is_visible_in_tree(),"actual NPC details opened")
 check(String(preview.get_meta("preview_unit_id",""))=="campaign_leader","full-body preview uses actual selected actor")
 check(bool(preview.get_meta("preview_uses_existing_model",false)),"full-body preview uses existing map character model")
 check(is_equal_approx(preview.size.y,500.0),"shared character card uses a substantially larger figure")
 check(bool(preview.get_meta("preview_idle_pose",false)),"preview freezes existing idle pose rather than showing the bind pose")
 check(panel.get("_identity_portrait").texture!=null,"original identity portrait is retained beside the shared character name")
 check(panel.get("_badges").get_child_count()>=3,"actual character bonuses also appear in equipment view")
 check(panel.get("_rest_row").size_flags_horizontal==Control.SIZE_SHRINK_BEGIN and panel.get("_rest_row").get_child(0)==panel.get("_rest"),"rest switch is compact and immediately left of its label")
 check(popup.find_child("CharacterDerivationOverview",true,false)==null,"unused origins box is removed from character overview")
 for key:String in ["armor","weapon_1","weapon_2"]:
  check(not preview.get_global_rect().intersects(panel.get("_slots").get_node("InventorySlot_"+key).get_global_rect()),"equipment slot does not cover the figure: "+key)
 var before:Dictionary=screen.get_personnel_inventory_view("campaign_leader").inventory.duplicate(true)
 var slot:Control=panel.get("_slots").get_node("InventorySlot_weapon_1")
 slot.payload_dropped.emit({"source_container_id":"base:homebase","item_id":"medictool"})
 for i in 8:await process_frame
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
  var expected_popup:Rect2i=screen.call("get_native_r2_layout_snapshot").character_popup
  check(is_equal_approx(popup.size.y,float(expected_popup.size.y)),"popup uses available screen height above the command dock")
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw
   DirAccess.make_dir_recursive_absolute("C:/dev/SternenBuergerchen/output/character_navigation_20261110")
   root.get_texture().get_image().save_png("C:/dev/SternenBuergerchen/output/character_navigation_20261110/details_%d.png"%resolution.x)
 flow.queue_free();await process_frame
 print("CHARACTER_NAVIGATION checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
