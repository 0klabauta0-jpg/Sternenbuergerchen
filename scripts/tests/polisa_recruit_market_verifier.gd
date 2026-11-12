extends SceneTree
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var market_script = load("res://scripts/meta/polisa_recruitment_market.gd")
	if market_script == null: _fail("market missing"); return
	var market = market_script.new()
	var profile := {"unit_id":"r1","skill_values":{"leadership":0.5},"communication_values":{"speech_quality":0.5}}
	var opened: Dictionary = market.open("batch1",profile,{})
	if not opened.get("ok",false) or opened.offers.size()!=4: _fail("offer count"); return
	var id := String(opened.offers[0].id)
	var quoted: Dictionary = market.quote(id)
	if not quoted.get("ok",false) or quoted.profile.unit_id != id or int(quoted.price) < 200: _fail("quote"); return
	opened.offers[0].price = 1
	if int(market.quote(id).price) < 200: _fail("snapshot mutation"); return
	if market.quote("unknown").get("ok",false): _fail("unknown offer"); return
	if not market.open("batch1",profile,{}).get("ok",false) or market.quote(id).price != quoted.price: _fail("stable batch"); return
	var saved: Dictionary=market.export_state()
	var restored=market_script.new()
	if not restored.restore_state(saved).get("ok",false) or restored.quote(id) != quoted: _fail("market restore"); return
	saved.offers[0].price = 1
	if restored.restore_state(saved).get("ok",false): _fail("tampered offer accepted"); return
	print("PASS: stable isolated recruit market")
	quit(0)
func _fail(message: String) -> void: printerr("FAIL: "+message); quit(1)
