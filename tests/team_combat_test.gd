extends SceneTree
var checks:=0
var failed:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failed+=1;printerr("FAIL ",label)
func run() -> void:
	check(ResourceLoader.exists("res://scripts/core/team_combat.gd"),"team combat exists")
	if failed:quit(1);return
	var a:Node=preload("res://scripts/core/simulation_root.gd").new(3)
	var b:Node=preload("res://scripts/core/simulation_root.gd").new(4)
	# Isolated combat fixture; full travel is tested in the product journey.
	a.auto_tick=false;b.auto_tick=false;root.add_child(a);root.add_child(b)
	a._state.region="rust";b._state.region="rust"
	a._state.crew.ida.position=[-210,192];a._state.crew.ida.target=[-210,192]
	b._state.crew.jaro.position=[-205,192];b._state.crew.jaro.target=[-205,192]
	var combat=load("res://scripts/core/team_combat.gd").new()
	var cores:Array[Node]=[a,b];var planets:Array[String]=["rust","rust"]
	check(not combat.attack(cores,planets,0,"ida","team0:jaro").is_empty(),"friendly fire forbidden")
	var separate:Array[String]=["rust","ice"]
	check(not combat.attack(cores,separate,0,"ida","team1:jaro").is_empty(),"other planet cannot be attacked")
	check(combat.attack(cores,planets,0,"ida","team1:jaro").is_empty(),"enemy targeted on same map")
	combat.tick(cores,planets,0.05)
	check(b._state.crew.jaro.health<100,"host applies enemy damage")
	check(a._state.crew.jaro.health==100,"ally with same local unit ID untouched")
	var health:float=b._state.crew.jaro.health
	combat.tick(cores,planets,0.05)
	check(b._state.crew.jaro.health==health,"repeated frame obeys weapon cooldown")
	for i in 100:
		a._state.crew.ida.attack_cooldown=0
		combat.tick(cores,planets,1)
	check(b._state.crew.jaro.health==0 and b._state.crew.jaro.assignment=="downed","enemy injury uses existing recovery")
	check(b._state.crew.jaro.respawn_remaining==20,"enemy receives finite recovery timer")
	check(a._state.credits==180,"PvP damage does not mint NPC kill rewards")
	print("TEAM_COMBAT ",checks," checks, ",failed," failures")
	quit(1 if failed else 0)
