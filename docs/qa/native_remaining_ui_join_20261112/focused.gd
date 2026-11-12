extends SceneTree
var passed := 0
var failed := 0
func _init() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
 passed += int(ok)
 failed += int(not ok)
 print("PASS " if ok else "FAIL ",label)
func run() -> void:
 var config = load("res://scripts/meta/skirmish_start_configuration.gd").new()
 var contract = load("res://scripts/meta/game_start_contract.gd")
 var available: bool = config.has_method("build_points_start") and config.has_method("build_experience_patch") and config.has_method("match_experience_template")
 check(available,"required points and experience APIs exist")
 if not available:
  print("UI_JOIN ",passed," passed, ",failed," failed")
  quit(1)
  return
 for budget: int in [1000,1500]:
  var draft := {"budget":budget,"base_setup":true,"people":[],"ships":[]}
  var result: Dictionary = config.call("build_points_start",draft)
  check(result.ok and result.points_budget == budget and result.roster.is_empty() and result.crafts.is_empty(),"empty base begins with full selected budget %d" % budget)
  check(result.infrastructure.paid and result.infrastructure.pads == 0,"no free infrastructure %d" % budget)
  check(contract.call("request_start",self,"skirmish","new","",draft).ok,"contract accepts budget %d" % budget)
  draft.budget = 17
  var consumed: Dictionary = contract.call("consume_start",self)
  check(consumed.points_draft.budget == budget,"contract snapshots draft %d" % budget)
  check(not Dictionary(contract.call("consume_start",self)).has("points_draft"),"draft consumed once %d" % budget)
 check(not contract.call("request_start",self,"campaign","new","",{"budget":1000,"base_setup":true,"people":[],"ships":[]}).ok,"campaign rejects points draft")
 check(not contract.call("request_start",self,"skirmish","new","",{"budget":1001,"base_setup":true,"people":[],"ships":[]}).ok,"invalid budget rejected")
 for category: String in ["operator","pilot","medic"]:
  for level: String in ["junior","trained","veteran"]:
   var unit := {"unit_id":"kept","display_name":"Existing person","roster_role_category":category,"armor_id":"heavy","progression":{"missions":3}}
   var before := unit.duplicate(true)
   var patch: Dictionary = config.call("build_experience_patch",unit,level)
   check(patch.ok and unit == before,"template proposal pure "+category+level)
   unit.merge(patch.patch,true)
   var matched: Dictionary = config.call("match_experience_template",unit)
   check(matched.matches_template and matched.experience_id == level and unit.unit_id == "kept" and unit.armor_id == "heavy" and unit.progression.missions == 3,"exact template preserves identity/gear/history "+category+level)
   unit.skill_values.accuracy += 0.01
   check(not config.call("match_experience_template",unit).matches_template,"individual profile detected "+category+level)
 var help: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/contextual_help_catalog.json"))
 var ids := {}
 for entry: Dictionary in help.entries:
  check(not ids.has(entry.help_id),"unique help "+String(entry.help_id)) if ids.has(entry.help_id) else 0
  ids[entry.help_id] = true
 check(ids.has("shell.map_controls") and ids.has("campaign.equip") and ids.has("polisa.fuel"),"new map help and newer campaign/polisa help coexist")
 var portraits: Dictionary = load("res://scripts/meta/portrait_identity_catalog.gd").load_catalog()
 for number in range(45,49):
  var entry: Dictionary = portraits.entries_by_id.get("char_portrait_%03d" % number,{})
  check(not entry.is_empty() and ResourceLoader.exists(String(entry.get("path",""))),"drawn portrait catalog and resource %d" % number)
 var dialog = load("res://scripts/ui/skirmish_points_dialog.gd").new()
 root.add_child(dialog)
 await process_frame
 var requested: Array = []
 dialog.start_requested.connect(func(draft: Dictionary): requested.append(draft.budget))
 dialog.find_child("StartBudget1000",true,false).emit_signal("pressed")
 dialog.find_child("StartBudget1500",true,false).emit_signal("pressed")
 check(requested == [1000,1500],"actual budget buttons emit distinct authoritative drafts")
 dialog.queue_free()
 await process_frame
 print("UI_JOIN ",passed," passed, ",failed," failed")
 quit(0 if failed == 0 else 1)
