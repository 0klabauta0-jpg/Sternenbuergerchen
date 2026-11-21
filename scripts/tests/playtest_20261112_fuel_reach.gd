extends SceneTree
func _init() -> void: call_deferred("run")
func run() -> void:
 var supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
 assert(supply.configure([{"craft_id":"ship"}]).ok)
 var adapter = load("res://scripts/meta/singleplayer_runtime_adapter.gd").new(); adapter._supply = supply
 var locations := {"homebase":{}, "satellite_crash":{}, "trade_outpost":{}}
 supply._fuel_by_craft_id["ship"] = 10.0
 var actual: Dictionary = adapter.call("_fuel_reachability", "ship", locations) if adapter.has_method("_fuel_reachability") else {}
 # Regel 8 / Auftrag 21.11.: keine Hin-und-Rueck-Reserve mehr. Mit 10 Treibstoff ist die naechste Etappe (Abheben, 2) bei beiden bezahlbar;
 # der ganze Hinweg (12 bzw. 8) reicht nur zum Handelsposten.
 var ok: bool = actual.has("satellite_crash") and actual.satellite_crash.ok and not actual.satellite_crash.route_ok and actual.trade_outpost.ok and actual.trade_outpost.route_ok
 if not ok: printerr("FAIL: Reichweite muss den echten Etappenprüfungen entsprechen (nächste Etappe und ganzer Hinweg)")
 adapter.free(); print("PLAYTEST_FUEL_REACH checks=2 failed=%d" % (0 if ok else 1)); quit(0 if ok else 1)
