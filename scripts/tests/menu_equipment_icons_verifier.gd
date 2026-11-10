extends SceneTree
const ICONS=preload("res://scripts/ui/menu_equipment_icons.gd")
var checks:=0
var failures:=0
func check(value:bool,label:String)->void:
 checks+=1
 if value:print("PASS: ",label)
 else:failures+=1;printerr("FAIL: ",label)
func _initialize()->void:
 for item:String in ICONS.CELLS:
  var icon:Texture2D=ICONS.get_icon(item)
  check(icon is AtlasTexture,"menu item uses illustrated atlas: "+item)
  if icon is AtlasTexture:check(icon.region.size==Vector2(512,512),"item stays within its own square cell: "+item)
 check(ICONS.get_icon("rifle").region!=ICONS.get_icon("pistol").region,"rifle and pistol have distinct illustrations")
 check(ICONS.get_icon("mining_tool").region!=ICONS.get_icon("pistol").region,"yellow mining tool has its own illustration")
 check(ICONS.get_icon("rifle")==ICONS.get_icon("rifle"),"unchanged item reuses cached texture identity")
 var briefing:Dictionary=load("res://scripts/mission/singleplayer_job_contract.gd").get_briefing("satellite_recovery")
 check(briefing.body_name=="Glut" and briefing.body_kind=="Planet","briefing resolves actual star-system body")
 check(briefing.objectives.has("Satelliten-Absturzstelle finden") and briefing.objectives.has("Satellitendaten bergen"),"finding location and recovering data are separate objectives")
 print("MENU_ICONS_BRIEFING checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
