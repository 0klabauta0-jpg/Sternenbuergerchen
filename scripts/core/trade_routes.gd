extends RefCounted
## Fixed early economy. Routes expose the exact catalog prices; no UI profit simulation.
static func overrides(region: String) -> Dictionary:
 var result:Dictionary=_base_prices(region)
 var variant:int=preload("res://scripts/core/regions.gd").variant(region)
 if variant>0:
  var food:Array=[[18,12],[26,18],[24,16],[12,8]][variant]
  var medicine:Array=[[70,48],[80,55],[55,38],[90,62]][variant]
  result.food={"buy":food[0],"sell":food[1]};result.medical_supplies={"buy":medicine[0],"sell":medicine[1]}
 return result
static func _base_prices(region: String) -> Dictionary:
 match region.get_slice("_v",0):
  "station":return {"parts":{"buy":24,"sell":18},"alloy":{"buy":160,"sell":145}}
  "distribution_friendly":return {"parts":{"buy":44,"sell":36},"scrap":{"buy":8,"sell":6}}
  "tradepost":return {"scrap":{"buy":18,"sell":14},"alloy":{"buy":110,"sell":85}}
 return {}
static func routes() -> Array:
 var result: Array=[{"from":"station","to":"distribution_friendly","item":"parts"},{"from":"distribution_friendly","to":"tradepost","item":"scrap"},{"from":"tradepost","to":"station","item":"alloy"}]
 for route: Dictionary in result:
  route.buy=overrides(route.from)[route.item].buy
  route.sell=overrides(route.to)[route.item].sell
  route.margin=route.sell-route.buy
 return result
