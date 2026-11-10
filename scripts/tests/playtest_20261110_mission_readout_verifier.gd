extends SceneTree
func _init() -> void:
	var hud=load("res://scripts/ui/mission_a5_hud_layout.gd")
	var context: Dictionary={"singleplayer_scenario_id":"satellite_recovery","confirmed_interactions":{}}
	var initial: Dictionary=hud.build_player_readout(context)
	context.confirmed_interactions={"satellite_data":{"complete":true}}
	var recovered: Dictionary=hud.build_player_readout(context)
	context.confirmed_interactions.ship_return={"complete":true}
	var returned: Dictionary=hud.build_player_readout(context)
	var text:=JSON.stringify([initial,recovered,returned])
	var ok:=text.contains("Satellitendaten sichern") and text.contains("Daten gesichert") and text.contains("Einsteigen und abheben")
	print("MISSION_READOUT passed=",ok)
	quit(0 if ok else 1)
