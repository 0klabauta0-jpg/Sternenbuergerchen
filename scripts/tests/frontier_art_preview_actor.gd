extends Node2D
## Synthetic preview actor. Position is mutated only by SimulationRoot after setup.
var unit_id: String = ""
func get_unit_id() -> String:
	return unit_id
