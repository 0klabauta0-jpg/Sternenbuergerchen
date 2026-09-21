extends SceneTree
const Campaign=preload("res://scripts/core/team_campaign.gd")
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
 if not ok:failures+=1;printerr("FAIL ",label)
func run() -> void:
 var sim:=Campaign.new(3);sim.auto_tick=false;root.add_child(sim)
 var old:Dictionary=sim._payload()
 for team:Dictionary in old.teams:
  for key:String in ["site_revision","site_records","discovery_site","world_claims"]:team.state.erase(key)
  for item:String in ["food","medical_supplies"]:
   team.state.inventory.erase(item);team.state.cargo.erase(item)
   for unit:Dictionary in team.state.crew.values():unit.backpack.items.erase(item)
  team.state.erase("market_stock")
  team.state.base.erase("infrastructure")
  team.state.blueprints.erase("build_solar")
  for id:String in team.state.resources.keys():
   if "_v" in id:team.state.resources.erase(id)
  for id:String in team.state.ground.enemies.keys():
   if "_v" in id:team.state.ground.enemies.erase(id)
 for world:Dictionary in old.worlds.values():
  world.erase("claims")
  for id:String in world.resources.keys():
   if "_v" in id:world.resources.erase(id)
  for id:String in world.enemies.keys():
   if "_v" in id:world.enemies.erase(id)
 for personal:Dictionary in old.personal:
  for record:Dictionary in personal.values():record.erase("site_records");record.erase("discovery_site")
 var path:="res://output/n8-legacy-team.json"
 var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(old));f.close()
 var result:Dictionary=sim.load_game(path)
 check(result.ok,"N7 team save migrates: "+str(result))
 check(sim.snapshot().credits==180,"migration preserves credits")
 check(sim.save_game("res://output/n8-migrated-team.json").ok,"migrated team saves consistently")
 old.teams[0].state.credits=-1
 f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(old));f.close()
 check(not sim.load_game(path).ok and sim.snapshot().credits==180,"invalid legacy save rejected atomically")
 print("N8 LEGACY TEAM failures=",failures);quit(failures)
