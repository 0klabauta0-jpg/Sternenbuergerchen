extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok:failures+=1;printerr("FAIL ",message)
func run() -> void:
	root.size=Vector2i(1440,900)
	var game=load("res://scenes/game.tscn").instantiate()
	game.load_on_start=false
	game.save_path="res://output/n8-probe-save.json"
	root.add_child(game)
	await process_frame
	game.simulation.auto_tick=false
	await create_timer(1.0).timeout
	var original: Dictionary=game.simulation.snapshot()
	var hints=preload("res://scripts/ui/onboarding_hint.gd")
	check(hints.target(original).get("id")=="contracts","new mission points to computer")
	var sample:=original.duplicate(true)
	sample.contract.status="recovered"
	check(hints.target(sample).get("id")=="storage","recovered box points to storage")
	sample.contract.status="claimed"
	check(hints.target(sample).is_empty(),"completed mission removes marker")
	sample.region="rust"
	check(hints.target(sample).is_empty(),"no home marker in other region")
	game.world.guidance_mode=2
	await process_frame
	check(game.world._guide.visible,"world marker visible")
	game.world.guidance_mode=0
	await process_frame
	check(not game.world._guide.visible,"world marker can be disabled")
	game.world.guidance_mode=1
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/n8-base-initial.png")
	game.hud._blueprints.open_tree(original)
	await create_timer(0.3).timeout
	check(game.hud._blueprints.visible,"blueprints visible")
	check(game.hud._blueprints._buttons.has("research_materials") and game.hud._blueprints._start.disabled,"research tree shows locked bench prerequisite")
	check(game.simulation.snapshot()==original,"read-only UI preserves entire snapshot")
	await RenderingServer.frame_post_draw
	game.hud._blueprints.get_texture().get_image().save_png("res://output/n8-blueprints-initial.png")
	game.hud._blueprints.hide()
	game.travel_chart.open_chart(original)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	game.travel_chart.get_texture().get_image().save_png("res://output/n8-chart-initial.png")
	game.travel_chart.hide()
	game.set_process(false)
	var team_view:Dictionary=original.duplicate(true)
	team_view.campaign={"team":0,"home":"rust","planet":"rust","started":false,"lobby_open":true,"members":{1:0,7:0,8:1},"homes":["rust","ice"],"planets":preload("res://scripts/core/team_campaign.gd").PLANETS,"max_per_team":8,"ai":[false,false]}
	game.travel_chart.open_chart(team_view)
	await create_timer(0.3).timeout;await RenderingServer.frame_post_draw
	game.travel_chart.get_texture().get_image().save_png("res://output/n8-chart-teams.png")
	game.travel_chart.hide()
	game.team_lobby.present(team_view,true);game.team_lobby.popup_centered()
	await create_timer(0.3).timeout;await RenderingServer.frame_post_draw
	game.team_lobby.get_texture().get_image().save_png("res://output/n8-lobby.png")
	print("REFERENCE_UX 9 checks; failed=",failures)
	quit(1 if failures else 0)

