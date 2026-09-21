extends RefCounted
## Deliberately small economic starter AI: no free materials or fabricated progress.
static func decide(state:Dictionary) -> Dictionary:
	if state.region!="base" or state.work.active or state.travel.active:return {}
	if state.contract.status=="available":return {"type":"accept_contract"}
	var recipe:="repair" if state.ship.condition<100 else "toolkit" if state.inventory.toolkit<2 else "armor" if state.inventory.armor<2 else ""
	if recipe.is_empty():return {}
	var spec:Dictionary=preload("res://scripts/core/catalog.gd").recipes()[recipe]
	for item:String in spec.materials:
		if state.inventory[item]<spec.materials[item]:return {}
	for id:String in state.crew:
		var unit:Dictionary=state.crew[id]
		if unit.assignment=="idle" and unit.health>0 and unit.skill>=spec.min_skill:return {"type":"assign_work","unit_id":id,"recipe_id":recipe}
	return {}
