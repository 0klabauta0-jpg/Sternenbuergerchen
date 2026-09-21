extends RefCounted
## Authoritative physical consignments. A unit is in a crate, a carrier or its destination.
const Catalog=preload("res://scripts/core/catalog.gd")
const Nav=preload("res://scripts/core/ground_navigation.gd")
const Regions=preload("res://scripts/core/regions.gd")
const Numbers=preload("res://scripts/core/legacy_validator_v2.gd")
const Travel=preload("res://scripts/core/crew_travel.gd")
static func empty_world() -> Dictionary:return {"next":1,"crates":{}}
static func extend(s:Dictionary) -> void:
 if not s.has("hauling"):s.hauling={"jobs":[]}
 if not s.has("freight_world"):s.freight_world=empty_world()
 if not s.has("freight_team"):s.freight_team=0
static func area(s:Dictionary) -> String:return "base:%d"%int(s.get("freight_team",0)) if s.region=="base" else str(s.region)
static func v(a:Array) -> Vector2:return Vector2(a[0],a[1])
static func inbound(s:Dictionary) -> int:
 var total:=0
 for j:Dictionary in s.get("hauling",{"jobs":[]}).jobs:
  if j.destination=="cargo":total+=int(j.held)+mini(int(j.left),int(s.freight_world.crates.get(j.crate,{}).get("amount",0)))
 return total
static func count(items:Dictionary) -> int:
 var total:=0
 for value:Variant in items.values():total+=int(value)
 return total
static func summary(s:Dictionary) -> String:
 var jobs:Array=s.get("hauling",{"jobs":[]}).jobs
 if jobs.is_empty():return "Keine Verladung aktiv."
 var carrying:=0;var waiting:=0
 for j:Dictionary in jobs:
  carrying+=int(j.held)
  if str(j.unit).is_empty():waiting+=1
 return "%d Ladeaufträge · %d Kisten getragen · %d warten auf Crew"%[jobs.size(),carrying,waiting]
static func destination(s:Dictionary,kind:String) -> Array:
 return Catalog.ship_access(s.ship) if kind=="cargo" else Catalog.interaction_point(s.region,"storage" if kind=="inventory" else "market")
static func can_order(s:Dictionary,from:Array,to:Array) -> String:
 if s.freight_world.crates.size()>=9900 or int(s.freight_world.next)>=999999900:return "Zu viele offene Frachtkisten. Erst vorhandene Ware abholen."
 if s.hauling.jobs.size()>=32:return "Zu viele offene Ladeaufträge."
 if s.travel.active or s.ship.mode!="landed":return "Verladung braucht ein gelandetes Schiff."
 if Nav.path(s.region,v(from),v(to),s.ship).is_empty():return "Kein begehbarer Ladeweg zwischen Quelle und Ziel."
 return ""
static func crate(s:Dictionary,item:String,amount:int,point:Array) -> String:
 var id:="fracht-%d"%int(s.freight_world.next);s.freight_world.next+=1
 s.freight_world.crates[id]={"item":item,"amount":amount,"position":point.duplicate(),"region":s.region,"area":area(s),"owner":int(s.freight_team)}
 return id
static func job(s:Dictionary,id:String,amount:int,target:String,price:int=0,worker:String="") -> void:
 var box:Dictionary=s.freight_world.crates[id]
 s.hauling.jobs.append({"crate":id,"item":box.item,"left":amount,"held":0,"unit":"","preferred":worker,"destination":target,"price":price,"phase":"waiting","delay":0.0,"delivered":0,"region":s.region})
static func order(s:Dictionary,item:String,amount:int,from:Array,target:String,price:int=0) -> void:
 job(s,crate(s,item,amount,from),amount,target,price)
static func pickup(s:Dictionary,c:Dictionary) -> String:
 if not c.get("crate_id") is String or not s.freight_world.crates.has(c.crate_id):return "Frachtkiste ist nicht mehr vorhanden."
 var box:Dictionary=s.freight_world.crates[c.crate_id]
 if box.area!=area(s):return "Fracht liegt auf einer anderen Karte."
 # Mission evidence is personal until cross-career objective ownership is implemented.
 if box.item=="blackbox" and box.owner!=s.freight_team:return "Diese Blackbox ist an den Bergungsauftrag der anderen Crew gebunden."
 var worker:String=str(c.get("unit_id",""))
 if not s.crew.has(worker) or s.crew[worker].health<=0 or s.crew[worker].assignment!="idle":return "Eine freie gesunde Person auswählen."
 if s.crew[worker].get("level_region",s.region)!=s.region:return "Person befindet sich auf einer anderen Ebene."
 for j:Dictionary in s.hauling.jobs:
  if j.crate==c.crate_id:return "Für diese Kiste läuft bereits ein Ladeauftrag."
 var free:int=int(s.ship.capacity)-count(s.cargo)-inbound(s)
 if free<=0:return "Frachtraum voll oder für laufende Verladung reserviert."
 var error:=can_order(s,box.position,destination(s,"cargo"))
 if not error.is_empty():return error
 if Nav.path(s.region,v(s.crew[worker].position),v(box.position),s.ship).is_empty():return "Kiste nicht erreichbar."
 job(s,c.crate_id,mini(free,int(box.amount)),"cargo",0,worker)
 return ""
static func release(s:Dictionary,j:Dictionary) -> void:
 if not str(j.unit).is_empty():
  var unit:Dictionary=s.crew[j.unit]
  if unit.assignment=="hauling":unit.assignment="idle";unit.target=unit.position.duplicate()
 j.unit=""
static func interrupt(s:Dictionary,id:String) -> void:
 for j:Dictionary in s.hauling.jobs:
  if j.unit!=id:continue
  if int(j.held)>0:
   var point:Vector2=v(s.crew[id].position)
   for step in 12:
    var nearby:=point+Vector2.from_angle(step*TAU/12)*1.6
    if Nav.clear(s.region,point,nearby,s.ship):point=nearby;break
   crate(s,j.item,int(j.held),[point.x,point.y]);j.held=0
  release(s,j);j.phase="waiting";j.delay=0.0
static func cancel(s:Dictionary) -> void:
 for id:String in s.crew:interrupt(s,id)
 s.hauling.jobs.clear()
static func tick(s:Dictionary,delta:float,logger:Callable,excluded:Array[String]=[]) -> void:
 for j:Dictionary in s.hauling.jobs.duplicate():
  var box:Dictionary=s.freight_world.crates.get(j.crate,{})
  if int(j.held)==0 and (int(j.left)==0 or box.is_empty() or int(box.get("amount",0))==0):
   release(s,j);s.hauling.jobs.erase(j);continue
  if j.region!=s.region or s.ship.mode!="landed" or s.travel.active:continue
  if str(j.unit).is_empty():
   for id:String in s.crew:
    if id in excluded:continue
    var unit:Dictionary=s.crew[id]
    if not str(j.preferred).is_empty() and j.preferred!=id:continue
    if unit.health<=0 or not unit.assignment in ["idle","aboard"] or unit.get("level_region",s.region)!=s.region or not str(unit.attack_target).is_empty():continue
    var from:Array=Catalog.ship_access(s.ship) if unit.assignment=="aboard" else unit.position
    if Nav.path(s.region,v(from),v(box.position),s.ship).is_empty():continue
    if unit.assignment=="aboard":
     var travel:=Travel.new();travel.bind(s,logger)
     if not travel.dispatch({"type":"disembark","unit_id":id}).is_empty():continue
    j.unit=id;j.phase="pickup";unit.assignment="hauling";unit.target=box.position.duplicate();break
   continue
  var unit:Dictionary=s.crew[j.unit]
  if unit.health<=0:interrupt(s,j.unit);continue
  if v(unit.position).distance_to(v(unit.target))>0.05:continue
  j.delay+=delta
  if j.delay<1.0:continue
  if j.phase=="pickup":
   if box.is_empty() or int(box.amount)<=0:continue
   # Competing requests reserve no crate contents until a carrier actually arrives.
   box.amount-=1;j.left-=1;j.held=1;j.phase="deliver";j.delay=0.0
   unit.target=destination(s,j.destination)
   if box.amount==0:s.freight_world.crates.erase(j.crate)
  else:
   if j.destination=="cargo" and count(s.cargo)>=int(s.ship.capacity):continue
   if j.destination=="inventory" and int(s.inventory[j.item])>=10000000:continue
   if j.destination=="market":
    var stock:Dictionary=s.market_stock[s.region].items
    if int(stock[j.item])>=10000000 or int(s.credits)+int(j.price)>1000000000:continue
    stock[j.item]+=1;s.credits+=int(j.price)
   else:s[j.destination][j.item]+=1
   j.held=0;j.delivered+=1;j.delay=0.0
   if int(j.left)>0 and s.freight_world.crates.has(j.crate):j.phase="pickup";unit.target=s.freight_world.crates[j.crate].position.duplicate()
   else:
    logger.call("Ladeauftrag abgeschlossen: %d × %s."%[int(j.delivered),Catalog.item_name(j.item)])
    release(s,j);s.hauling.jobs.erase(j)
static func blackboxes(s:Dictionary) -> int:
 var result:=0
 for box:Dictionary in s.get("freight_world",empty_world()).crates.values():
  if box.item=="blackbox" and box.owner==s.get("freight_team",0):result+=int(box.amount)
 for j:Dictionary in s.get("hauling",{"jobs":[]}).jobs:
  if j.item=="blackbox":result+=int(j.held)
 return result
static func validate(s:Dictionary) -> String:
 if not s.has("hauling") and not s.has("freight_world") and not s.has("freight_team"):return ""
 if not Numbers.whole(s.get("freight_team"),0,1):return "Frachtteam ungültig."
 var world:Variant=s.get("freight_world")
 if not world is Dictionary or not Numbers.whole(world.get("next"),1,1000000000) or not world.get("crates") is Dictionary or world.crates.size()>10000:return "Frachtwelt ungültig."
 for id:Variant in world.crates:
  if not id is String or not id.begins_with("fracht-") or not id.trim_prefix("fracht-").is_valid_int() or int(id.trim_prefix("fracht-"))<=0 or int(id.trim_prefix("fracht-"))>=int(world.next):return "Kistenkennung ungültig."
  var box:Variant=world.crates[id]
  if not box is Dictionary or not box.get("item") in Catalog.ITEMS or not Numbers.whole(box.get("amount"),1,10000000) or not box.get("region") in Regions.ALL or not Numbers.whole(box.get("owner"),0,1):return "Kistenbestand ungültig."
  if not Numbers.position_valid(box.get("position"),Catalog.bounds(box.region)) or box.get("area")!=("base:%d"%int(box.owner) if box.region=="base" else box.region):return "Kistenort ungültig."
 var haul:Variant=s.get("hauling")
 if not haul is Dictionary or not haul.get("jobs") is Array or haul.jobs.size()>32:return "Ladeaufträge ungültig."
 var workers:Dictionary={}
 for j:Variant in haul.jobs:
  if not j is Dictionary or not j.get("crate") is String or not j.get("item") in Catalog.ITEMS or not j.get("destination") in ["cargo","inventory","market"] or j.get("region")!=s.region:return "Frachtauftrag ungültig."
  if not Numbers.whole(j.get("left"),0,10000000) or not Numbers.whole(j.get("held"),0,1) or not Numbers.whole(j.get("delivered"),0,10000000) or not Numbers.whole(j.get("price"),0,1000000000) or not Numbers.number(j.get("delay"),0,1000000000):return "Frachtmenge ungültig."
  if not j.get("phase") in ["waiting","pickup","deliver"] or not j.get("unit") is String or not j.get("preferred") in ["","ida","jaro"]:return "Trägerphase ungültig."
  if j.destination=="inventory" and s.region!="base":return "Lagerauftrag außerhalb der Basis."
  if j.destination=="market" and (not s.region in Regions.MARKETS or not Catalog.prices(s.region).has(j.item) or j.price!=Catalog.prices(s.region)[j.item].sell):return "Verkaufspreis ungültig."
  if j.destination!="market" and j.price!=0:return "Unbegründete Frachtzahlung."
  if s.ship.mode!="landed" or s.travel.active:return "Verladung im Flug."
  if world.crates.has(j.crate) and (world.crates[j.crate].item!=j.item or world.crates[j.crate].area!=area(s)):return "Frachtquelle widersprüchlich."
  if j.unit.is_empty():
   if j.phase!="waiting" or j.held!=0:return "Verwaiste Tragelast."
  else:
   if not s.crew.has(j.unit) or workers.has(j.unit) or s.crew[j.unit].assignment!="hauling" or s.crew[j.unit].health<=0:return "Trägerbindung ungültig."
   workers[j.unit]=true
   if j.phase=="waiting" or (j.phase=="deliver")!=(j.held==1):return "Tragelast widersprüchlich."
   var target:Array=destination(s,j.destination) if j.phase=="deliver" else world.crates.get(j.crate,{}).get("position",s.crew[j.unit].target)
   if v(target).distance_to(v(s.crew[j.unit].target))>0.01:return "Ladeziel widersprüchlich."
 for id:String in s.crew:
  if s.crew[id].assignment=="hauling" and not workers.has(id):return "Person ohne Ladeauftrag."
 return ""
