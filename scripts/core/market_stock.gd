extends RefCounted
## One physical stock per named market; only the authoritative clock replenishes it.
const Catalog=preload("res://scripts/core/catalog.gd")
const Regions=preload("res://scripts/core/regions.gd")
const INTERVAL:=300.0
const LIMIT:=10000000
static func capacity(item:String) -> int:return 24 if item in ["scrap","ore","food"] else 12 if item in ["parts","alloy","med_charge","medical_supplies"] else 4
static func goods(region:String) -> Array:
 var result:Array=Catalog.prices(region).keys()
 if region=="station":
  for id:String in preload("res://scripts/core/base_infrastructure.gd").offers():result.append("power:"+id)
 return result
static func initial() -> Dictionary:
 var markets:Dictionary={}
 for region:String in Regions.MARKETS:
  var goods:Dictionary={}
  for item:String in goods(region):goods[item]=capacity(item)
  markets[region]={"items":goods,"remaining":INTERVAL}
 return markets
static func extend(state:Dictionary) -> void:
 if not state.has("market_stock"):state.market_stock=initial()
static func advance(markets:Dictionary,delta:float) -> void:
 for market:Dictionary in markets.values():
  market.remaining-=delta
  if market.remaining>0.000001:continue
  var deliveries:=1+int(floor(maxf(0.0,-float(market.remaining))/INTERVAL))
  market.remaining=minf(INTERVAL,market.remaining+INTERVAL*deliveries)
  for item:String in market.items:
   var cap:=capacity(item)
   if market.items[item]<cap:market.items[item]=mini(cap,int(market.items[item])+maxi(1,cap/2)*deliveries)
static func validate(value:Variant) -> String:
 if not value is Dictionary or value.size()!=Regions.MARKETS.size():return "Marktbestände fehlen."
 for region:String in Regions.MARKETS:
  var market:Variant=value.get(region)
  if not market is Dictionary or market.size()!=2 or not market.get("items") is Dictionary or market.items.size()!=goods(region).size():return "Marktbestand ungültig."
  var timer:Variant=market.get("remaining")
  if not (timer is int or timer is float) or not is_finite(float(timer)) or timer<=0 or timer>INTERVAL:return "Nachschubzeit ungültig."
  for item:String in goods(region):
   var stock:Variant=market.items.get(item)
   if not (stock is int or stock is float) or not is_finite(float(stock)) or float(stock)!=floorf(float(stock)) or stock<0 or stock>LIMIT:return "Händlerware ungültig."
 return ""
