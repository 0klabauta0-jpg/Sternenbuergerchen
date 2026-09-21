extends RefCounted
## Fixed early economy. Routes expose the exact catalog prices; no UI profit simulation.
static func overrides(region: String) -> Dictionary:
	match region:
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
