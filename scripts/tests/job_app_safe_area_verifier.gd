extends SceneTree
var checks:=0
var failed:=0
func check(value:bool,label:String)->void:
 checks+=1
 if value:print("PASS: ",label)
 else:failed+=1;printerr("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func click_control(control:Control)->void:
 var point:Vector2=control.get_global_rect().get_center()
 var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point
 root.push_input(motion,true)
 await process_frame
 var hovered:Control=root.gui_get_hovered_control()
 print("CLICK ",control.name," point=",point," hovered=",hovered.get_path() if hovered!=null else "none")
 var press:=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;press.button_mask=MOUSE_BUTTON_MASK_LEFT;press.position=point;press.global_position=point
 root.push_input(press,true)
 var release:=press.duplicate();release.pressed=false;release.button_mask=0
 root.push_input(release,true)
 for i in 4:await process_frame
func click_point(point:Vector2)->void:
 var motion:=InputEventMouseMotion.new();motion.position=point;motion.global_position=point;root.push_input(motion,true)
 await process_frame
 var press:=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;press.button_mask=MOUSE_BUTTON_MASK_LEFT;press.position=point;press.global_position=point;root.push_input(press,true)
 var release:=press.duplicate();release.pressed=false;release.button_mask=0;root.push_input(release,true)
 for i in 4:await process_frame
func capture(label:String)->void:
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 var folder:=ProjectSettings.globalize_path("res://output/job_app_safe_area_native")
 DirAccess.make_dir_recursive_absolute(folder)
 root.get_texture().get_image().save_png(folder+"/"+label+".png")
func run()->void:
 root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
 load("res://scripts/meta/game_start_contract.gd").request_start(self,"campaign","new")
 var flow:Node=load("res://scenes/meta/meta_layer_test.tscn").instantiate();root.add_child(flow);current_scene=flow
 for i in 24:await process_frame
 var screen:Node=flow.get_node("HomebaseScreen")
 var presenter:Node=screen.get("_operations_presenter")
 var board:Node=presenter.get("_job_board")
 presenter.get("_flyout_scrim").gui_input.connect(func(event:InputEvent):
  if event is InputEventMouseButton and event.pressed:print("SCRIM_PRESS ",event.position))
 for resolution:Vector2i in [Vector2i(1920,1080),Vector2i(1280,720)]:
  root.size=resolution;root.content_scale_size=resolution
  presenter.call("_navigate_from_sidebar","jobs")
  await create_timer(.3).timeout
  for i in 6:await process_frame
  var base:Node=presenter.get("_base")
  var dock:Control=base.get_node("BasePersonnelActions")
  print("RECTS ",resolution," workspace=",presenter.get("_workspace").get_global_rect()," app=",board.get_global_rect()," dock=",dock.get_global_rect()," accept=",board.get("_accept").get_global_rect())
  check(board.is_visible_in_tree(),"Smart Mobile opens")
  if board.get("_details_expanded"):board.call("_toggle_job_details","satellite_recovery")
  await click_control(board.get("_card_buttons").satellite_recovery)
  check(board.is_visible_in_tree() and presenter.is_workspace_flyout_open() and board.get("_details_expanded"),"real title click keeps app open and expands first job")
  await create_timer(.35).timeout
  check(board.is_visible_in_tree() and presenter.is_workspace_flyout_open(),"periodic refresh retains app")
  check(board.get_global_rect().end.y<=dock.get_global_rect().position.y-8,"Smart Mobile remains above base bottom band")
  check(board.get("_accept").get_global_rect().end.y<=dock.get_global_rect().position.y-8,"accept action remains above bottom band")
  check(board.get_global_rect().grow(1).encloses(board.get("_accept").get_global_rect()),"accept action stays inside the visible app")
  await capture("mobile_%d"%resolution.x)
  var unit:String=String(screen.get_operations_snapshot().focused_unit.id)
  screen.request_operation("details",{"unit_id":unit})
  for i in 8:await process_frame
  var popup:Control=screen.get_node("CharacterSheetPopup")
  print("DETAIL_RECT ",popup.get_global_rect()," panel=",popup.get_node("PopupPanel").get_global_rect())
  for node_name in ["PopupScroll","CharacterInventoryScroll","PopupHeaderRow"]:
   var node:Control=popup.find_child(node_name,true,false)
   print("DETAIL_MIN ",node_name," min=",node.get_combined_minimum_size()," rect=",node.get_global_rect())
  check(popup.get_global_rect().end.y<=dock.get_global_rect().position.y-8,"character details remain above bottom band")
  check(popup.get_node("PopupPanel").get_global_rect().end.y<=dock.get_global_rect().position.y-8,"actual details panel stays above band")
  check(root.get_visible_rect().grow(1).encloses(popup.get_node("PopupPanel").get_global_rect()),"details including close control fit viewport width")
  await capture("details_%d"%resolution.x)
  await click_control(popup.find_child("ClosePopupButton",true,false))
  check(not popup.is_visible_in_tree(),"actual details close button stays usable")
  if popup.is_visible_in_tree():screen.call("_on_close_sheet_button_pressed")
 presenter.call("_navigate_from_sidebar","jobs")
 await create_timer(.3).timeout
 if not board.get("_details_expanded"):board.call("_toggle_job_details","satellite_recovery")
 for i in 4:await process_frame
 await click_control(board.get("_accept"))
 var runtime:Node=flow.get("_singleplayer_runtime")
 var campaign:Dictionary=runtime.get("_campaign").get_campaign_snapshot()
 check(campaign.jobs.satellite_recovery.status=="accepted","actual accept button reaches campaign owner")
 check(board.is_visible_in_tree(),"accept keeps selected job visible")
 await click_control(presenter.get("_flyout_close"))
 check(not presenter.is_workspace_flyout_open() and not board.is_visible_in_tree(),"explicit app close remains functional")
 presenter.call("_navigate_from_sidebar","jobs")
 await create_timer(.3).timeout
 var scrim:Control=presenter.get("_flyout_scrim")
 var outside:=Vector2(scrim.get_global_rect().end.x-16,scrim.get_global_rect().position.y+40)
 await click_point(outside)
 check(not presenter.is_workspace_flyout_open(),"outside click still closes the app")
 flow.queue_free();current_scene=null
 for i in 4:await process_frame
 print("JOB_APP_SAFE_AREA checks=%d failed=%d"%[checks,failed])
 if failed==0:print("JOB_APP_SAFE_AREA_PASS")
 quit(1 if failed else 0)
