extends SceneTree
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
 if not ok:failures+=1;printerr("FAIL ",label)
func run() -> void:
 root.size=Vector2i(1440,900)
 var game:Node=load("res://scenes/game.tscn").instantiate();game.load_on_start=false;game.save_path="res://output/n8-market-window-unused.json";root.add_child(game)
 await process_frame;game.simulation.auto_tick=false
 game.simulation._state.region="station"
 await create_timer(0.2).timeout
 game.hud.select_object("market","market")
 await create_timer(0.2).timeout
 check(game.hud._action_buttons.has("buy_food") and game.hud._action_buttons.has("buy_medical_supplies"),"both goods visible in real market UI")
 check("Nachschub" in game.hud._context_text.text,"real market shows restock timer")
 game.hud._action_buttons.buy_food.emit_signal("pressed")
 await create_timer(0.2).timeout
 check(game.simulation.snapshot().cargo.food==0 and game.simulation.snapshot().hauling.jobs.size()==1,"market button schedules physical delivery")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/n8-market.png")
 print("N8 MARKET WINDOW failures=",failures);quit(failures)
