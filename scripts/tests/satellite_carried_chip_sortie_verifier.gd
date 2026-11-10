extends "res://scripts/tests/campaign_visible_issuer_sortie_verifier.gd"
var carrier_id:String=""
func _move_and_use(mission:Node,interaction_id:String,step_id:String,map_path:String)->bool:
 if not await super._move_and_use(mission,interaction_id,step_id,map_path):return false
 if interaction_id=="satellite_data":
  var controller:Node=mission.get_node("TacticalController")
  var lead:Node=controller.get_current_fireteam_lead_unit(_team_id)
  carrier_id=String(lead.get_unit_id())
  if not await _wait(func():return int(_supply().inventory["unit:"+carrier_id+":backpack"].items.get("satellite_chip",0))==1,3000,"actual secured satellite data becomes one item in real lead backpack"):return false
  for i in 4:_runtime.observe_campaign_progress()
  _check(_chip_count()==1,"repeated authoritative observation cannot duplicate the chip")
  _check(String(_campaign().jobs.satellite_recovery.status)=="active","chip pickup alone does not complete or reward the mission")
  var forged:Dictionary=_runtime.request_operation("campaign_cargo",{"container_id":"unit:"+carrier_id+":backpack","item_id":"satellite_chip","amount":1})
  _check(not forged.get("ok",false),"UI cannot mint a campaign chip by command")
  controller.call("_open_character_overlay",carrier_id)
  var host:Node=controller.call("_get_character_overlay_host")
  var icon:TextureRect=host.find_child("CarriedInventoryItem_satellite_chip",true,false)
  _check(icon!=null and icon.texture!=null,"real lead details show carried satellite data with its menu icon")
  if DisplayServer.get_name()!="headless":
   for i in 8:await process_frame
   await RenderingServer.frame_post_draw
   DirAccess.make_dir_recursive_absolute("C:/dev/SternenBuergerchen/output/equipment_icons_20261110")
   root.get_texture().get_image().save_png("C:/dev/SternenBuergerchen/output/equipment_icons_20261110/satellite_carried_on_map.png")
  controller.call("_close_character_overlay")
 return true
func _wait_homebase()->bool:
 if not await super._wait_homebase():return false
 _check(not carrier_id.is_empty() and int(_supply().inventory["unit:"+carrier_id+":backpack"].items.get("satellite_chip",0))==1,"lead retains the recovered item through real return and sleeping")
 _check(_chip_count()==1,"successful return adds no second legacy cargo chip")
 var saved:Dictionary=STORE.load_checkpoint()
 _check(saved.get("ok",false),"carried quest chip checkpoint remains loadable")
 if saved.get("ok",false):
  var restored:RefCounted=load("res://scripts/core/singleplayer_supply_state.gd").new()
  _check(restored.restore_state(saved.payload.supply).get("ok",false),"pending chip supply restores through its real owner")
  _check(int(restored.get_supply_snapshot().inventory["unit:"+carrier_id+":backpack"].items.get("satellite_chip",0))==1,"checkpoint preserves exact carried chip quantity")
 if OS.get_cmdline_user_args().has("--transfer-chip-to-craft"):
  var moved:Dictionary=_runtime.request_operation("inventory_transfer",{"unit_id":carrier_id,"craft_id":_craft_id,"source_container_id":"unit:"+carrier_id+":backpack","destination_container_id":"craft:"+_craft_id,"item_id":"satellite_chip","amount":1})
  _check(moved.get("ok",false),"real home inventory transfer can place chip in cargo")
  _check(String(_runtime.call("_find_campaign_chip_container","satellite_chip",_craft_id))=="craft:"+_craft_id,"upload still resolves the existing cargo-storage route")
 return true
func _chip_count()->int:
 var total:=0
 for container:Dictionary in _supply().inventory.values():total+=int(container.get("items",{}).get("satellite_chip",0))
 return total
func _finish()->void:
 if _runtime!=null and String(_campaign().jobs.satellite_recovery.status)=="completed":_check(_chip_count()==0,"real home upload consumes the carried data item exactly once")
 await super._finish()
