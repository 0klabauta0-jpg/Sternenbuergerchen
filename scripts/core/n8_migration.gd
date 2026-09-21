extends RefCounted
const Old=preload("res://scripts/core/legacy_n7/save_validator.gd")
const Sites=preload("res://scripts/core/site_state.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")
const Regions=preload("res://scripts/core/regions.gd")
const Catalog=preload("res://scripts/core/catalog.gd")
static func prepare(payload:Variant,already_validated:bool=false) -> String:
 if not payload is Dictionary or not payload.get("state") is Dictionary:return "Zustand fehlt."
 if payload.state.has("site_revision"):return ""
 if not already_validated:
  var reason:String=Old.validate(payload)
  if not reason.is_empty():return "N7-Spielstand: "+reason
 var s:Dictionary=payload.state
 for item:String in ["food","medical_supplies"]:
  s.inventory[item]=0;s.cargo[item]=0
  for unit:Dictionary in s.crew.values():unit.backpack.items[item]=0
 Sites.extend(s)
 preload("res://scripts/core/market_stock.gd").extend(s)
 var moved:=false
 if s.ship.mode=="landed":
  var region:String=Regions.surface(s.region)
  if not Nav.landing_clear(region,s.ship):
   var origin:=Vector2(s.ship.position[0],s.ship.position[1]);var found:=false
   for radius in range(1,181):
    if found:break
    for direction in 32:
     var at:=origin+Vector2.from_angle(direction*TAU/32.0)*radius
     var candidate:Dictionary=s.ship.duplicate(true);candidate.position=[at.x,at.y]
     if Nav.landing_clear(region,candidate):s.ship.position=candidate.position;s.ship.target=candidate.position.duplicate();found=true;moved=true;break
   if not found:return "Keine sichere Landefläche für den alten Spielstand."
  for unit:Dictionary in s.crew.values():
   if unit.assignment=="aboard":unit.position=s.ship.position.duplicate();unit.target=unit.position.duplicate();continue
   var level:String=unit.get("level_region",s.region)
   var before:=Vector2(unit.position[0],unit.position[1]);var safe:=Nav.safe_near(level,before,s.ship)
   if not safe.is_finite():return "Keine sichere Crewposition."
   unit.position=[safe.x,safe.y];moved=moved or safe!=before
   if unit.assignment=="boarding":unit.target=Catalog.ship_access(s.ship)
   elif unit.assignment=="work":unit.target=Catalog.interaction_point("base","workbench")
   elif unit.assignment=="salvage":unit.target=Catalog.interaction_point("rust","satellite")
   elif unit.assignment=="gather":unit.target=Catalog.interaction_point(level,s.ground.activity.site_id)
   elif not Nav.walkable(level,Vector2(unit.target[0],unit.target[1]),s.ship):unit.target=unit.position.duplicate()
 if moved:
  s.log.append("N8: Schiff und Crew auf sichere benachbarte Flächen versetzt; Vorräte und Aufträge erhalten.")
  while s.log.size()>30:s.log.pop_front()
 return ""
