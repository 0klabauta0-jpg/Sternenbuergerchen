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
 check(game.simulation.snapshot().cargo.food==0 and game.simulation.snapshot().hauling.jobs.size()==1,"market button orders physical freight")
 for tick in 1200:
  game.simulation.advance(0.05)
  var jobs:Array=game.simulation.snapshot().hauling.jobs
  if not jobs.is_empty() and jobs[0].held==1:break
 await create_timer(0.2).timeout
 check(game.world._units.ida.get_node("Model/CarriedFreight").visible,"carrier visibly holds crate")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/n8-hauling.png")
 game.hud._action_buttons.cancel_hauling.emit_signal("pressed")
 game.hud.dismiss_context()
 await create_timer(0.2).timeout
 var crates:Dictionary=game.simulation.snapshot().freight_world.crates
 check(crates.size()==1,"cancel creates visible dropped crate")
 var id:String=crates.keys()[0]
 var node:Node3D=game.world._freight.nodes[id]
 var screen:Vector2=game.world._camera.unproject_position(node.global_position+Vector3.UP*0.6)
 var hit:Dictionary=game.world._hit_at(screen)
 check(not hit.is_empty() and hit.collider.get_meta("kind","")=="freight","crate can be picked without NPC occlusion")
 var mouse:=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_RIGHT;mouse.position=screen;mouse.pressed=true;Input.parse_input_event(mouse)
 await process_frame
 mouse=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_RIGHT;mouse.position=screen;mouse.pressed=false;Input.parse_input_event(mouse)
 await create_timer(0.2).timeout
 check(game.simulation.snapshot().hauling.jobs.size()==1,"real right click orders selected NPC to recover crate")
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/n8-freight-pickup.png")
 print("HAUL WINDOW failures=",failures);quit(failures)
