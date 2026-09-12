extends SceneTree
## Runs as separate real product launches. All saves stay in the test output folder.
var game: Node
var phase := "initial"
var checks := 0
var failed := 0
const ROUNDTRIP := "res://output/lifecycle-roundtrip.json"
const RECOVERY := "res://output/lifecycle-recovery.json"

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--phase="): phase=argument.trim_prefix("--phase=")
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://output"))
	if phase=="guards":
		var broken:=FileAccess.open(RECOVERY,FileAccess.WRITE)
		broken.store_string("{}");broken.close()
	game=load("res://scenes/game.tscn").instantiate()
	game.save_path=RECOVERY if phase in ["guards","recovered"] else ROUNDTRIP
	game.load_on_start=phase!="initial"
	root.add_child(game)
	game.simulation.auto_tick=false
	await process_frame
	match phase:
		"initial":
			game.send_command({"type":"accept_contract"})
			game.send_command({"type":"toggle_pause"})
			_check(game.simulation.snapshot().contract.status=="active","First session has real progress")
		"restore":
			_check(game.simulation.snapshot().contract.status=="active","Normal startup restores contract")
			_check(game.simulation.snapshot().paused,"Normal startup restores pause")
			game.send_command({"type":"assign_work","unit_id":"ida","recipe_id":"toolkit"})
			_check(game.simulation.snapshot().work.active,"Can continue restored session")
		"guards":
			_check(not game._auto_save_allowed,"Invalid initial save is protected")
			_check(FileAccess.get_file_as_string(RECOVERY)=="{}","Rejected file was not overwritten")
			game._on_action("save",{})
			_check(game._auto_save_allowed,"Successful explicit save restores autosave")
			game.send_command({"type":"accept_contract"})
			game.save_path="res://output/nonexistent-save-directory-"+str(OS.get_process_id())+"/campaign.json"
			game._quit()
			await process_frame
			_check(game.hud._toast.text.contains("Beenden abgebrochen"),"Failed exit save keeps product open with an error")
			game.save_path=RECOVERY
		"recovered":
			_check(game.simulation.snapshot().contract.status=="active","Progress after recovery survives a normal close")
			var roundtrip: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROUNDTRIP))
			_check(roundtrip.state.work.active,"Second normal close saved continued work")
			print("USER_SAVE_DIRECTORY ",ProjectSettings.globalize_path("user://"))
	if failed>0: quit(1);return
	print("SAVE_LIFECYCLE_PASS phase=",phase," checks=",checks)
	game._quit()

func _check(condition: bool,label: String) -> void:
	checks+=1
	if not condition:
		failed+=1
		push_error("SAVE_LIFECYCLE_FAIL "+label)
