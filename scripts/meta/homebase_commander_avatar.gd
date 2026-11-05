extends Node2D
## Ephemeral exploration actor. SimulationRoot owns position after placement.
const UNIT_ID: String = "homebase_commander_avatar"


func get_unit_id() -> String:
	return UNIT_ID


func get_team_id() -> String:
	return "homebase_local"


func get_vital_state() -> String:
	return "fit"
