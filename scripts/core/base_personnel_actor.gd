extends Node2D
## Runtime projection of one existing campaign roster identity. No health copy.
var unit_id: String = ""
func get_unit_id() -> String:
	return unit_id
func get_team_id() -> String:
	return "homebase_local"
func get_vital_state() -> String:
	return "fit"
