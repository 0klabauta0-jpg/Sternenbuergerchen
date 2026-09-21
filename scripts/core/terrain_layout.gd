extends RefCounted
## Shared, deterministic elevation. Coordinates remain planar in save files.
const Regions=preload("res://scripts/core/regions.gd")
static var _patch_cache:Dictionary={}
static func patches(region:String) -> Array:
 if _patch_cache.has(region):return _patch_cache[region]
 var result:=_patches(region)
 var variant:=Regions.variant(region)
 if variant>0 and not result.is_empty():
  result=result.duplicate(true)
  if result.size()>1:
   var other:Dictionary=result[1]
   var target:Vector2=[Vector2.ZERO,Vector2(-400,-360),Vector2(210,250),Vector2(-400,220)][variant]
   var shift:Vector2=target-other.rect.position
   other.rect.position+=shift;other.ramp.position+=shift
  var ridge:Rect2=[Rect2(),Rect2(230,250,180,65),Rect2(-400,-360,150,70),Rect2(220,-350,160,80)][variant]
  result.append({"rect":ridge,"rise":5.0+variant,"ramp":Rect2(ridge.get_center().x-18,ridge.end.y,36,40)})
 _patch_cache[region]=result
 return result
static func _patches(region:String) -> Array:
 if region in ["station","space","orbit"] or Regions.underground(region):return []
 match Regions.archetype(region):
  "base":return [{"rect":Rect2(-60,-110,120,125),"rise":4.0,"ramp":Rect2(-10,15,20,24)},{"rect":Rect2(-55,-100,110,35),"rise":5.0,"ramp":Rect2(-10,-65,20,25)}]
  "bunker_surface":return [{"rect":Rect2(-100,-125,205,160),"rise":4.0,"ramp":Rect2(-18,35,36,28)},{"rect":Rect2(120,-140,120,90),"rise":9.0,"ramp":Rect2(156,-50,40,48)}]
  "distribution":return [{"rect":Rect2(-150,-130,310,310),"rise":4.0,"ramp":Rect2(-25,180,50,28)},{"rect":Rect2(200,-160,160,180),"rise":9.0,"ramp":Rect2(250,20,45,48)}]
  "tradepost":return [{"rect":Rect2(-65,-55,110,90),"rise":4.0,"ramp":Rect2(-12,35,24,26)},{"rect":Rect2(100,-170,120,100),"rise":9.0,"ramp":Rect2(130,-70,35,48)}]
  _:return [{"rect":Rect2(80,-190,140,130),"rise":4.0,"ramp":Rect2(128,-60,30,28)},{"rect":Rect2(-220,30,180,120),"rise":9.0,"ramp":Rect2(-150,150,40,48)}]
static var _outlines:Dictionary={}
static func outline(patch:Dictionary) -> PackedVector2Array:
 var r:Rect2=patch.rect;var key:=str(r)
 if _outlines.has(key):return _outlines[key]
 var x:=r.position.x;var z:=r.position.y;var w:=r.size.x;var d:=r.size.y
 var ramp:Rect2=patch.ramp
 var points:=PackedVector2Array([Vector2(x+13,z+2),Vector2(x+w*0.30,z-4),Vector2(x+w*0.56,z+2),Vector2(x+w-12,z),Vector2(x+w+3,z+16),Vector2(x+w-2,z+d*0.36),Vector2(x+w+4,z+d*0.69),Vector2(x+w-5,z+d-10),Vector2(x+w-17,z+d-2),Vector2(ramp.end.x+8,z+d),Vector2(ramp.end.x,z+d),Vector2(ramp.position.x,z+d),Vector2(ramp.position.x-8,z+d-2),Vector2(x+16,z+d-2),Vector2(x-3,z+d-14),Vector2(x+2,z+d*0.55),Vector2(x-4,z+d*0.27),Vector2(x+1,z+14)])
 _outlines[key]=points
 return points
static func height_at(region:String,at:Vector2) -> float:
 var height:=0.0
 for patch:Dictionary in patches(region):
  var rect:Rect2=patch.rect;var ramp:Rect2=patch.ramp
  if rect.grow(5).has_point(at) and Geometry2D.is_point_in_polygon(at,outline(patch)):height+=float(patch.rise)
  elif ramp.has_point(at):height+=float(patch.rise)*(1.0-(at.y-ramp.position.y)/ramp.size.y)
 return height
static func traversable(region:String,a:Vector2,b:Vector2) -> bool:
 if patches(region).is_empty():return true
 var steps:=maxi(1,ceili(a.distance_to(b)/0.45));var last:=height_at(region,a)
 for i in range(1,steps+1):
  var next:=height_at(region,a.lerp(b,float(i)/steps))
  if absf(next-last)>0.38:return false
  last=next
 return true
static func level_landing(region:String,rect:Rect2) -> bool:
 var height:=height_at(region,rect.get_center())
 for x in 5:
  for z in 5:
   if absf(height_at(region,rect.position+rect.size*Vector2(x/4.0,z/4.0))-height)>0.15:return false
 return true
static func ray_hit(region:String,origin:Vector3,direction:Vector3) -> Variant:
 if direction.y>=0:return null
 var last:=origin
 for i in range(1,1801):
  var point:=origin+direction*float(i)
  if point.y<=height_at(region,Vector2(point.x,point.z)):
   var low:=last;var high:=point
   for j in 14:
    var mid:Vector3=(low+high)*0.5
    if mid.y>height_at(region,Vector2(mid.x,mid.z)):low=mid
    else:high=mid
   return high
  last=point
 return null

static func flight_floor(region:String,at:Vector2,hull_radius:float) -> float:
 # Look ahead around the entire hull, so a cliff never teleports or clips the ship.
 var floor_height:=height_at(region,at)
 for patch:Dictionary in patches(region):
  var polygon:=outline(patch)
  var distance:=0.0
  if not Geometry2D.is_point_in_polygon(at,polygon):
   distance=INF
   for i in polygon.size():
    distance=minf(distance,at.distance_to(Geometry2D.get_closest_point_to_segment(at,polygon[i],polygon[(i+1)%polygon.size()])))
  var top:=height_at(region,(patch.rect as Rect2).get_center())
  floor_height=maxf(floor_height,top-maxf(0.0,distance-hull_radius)*0.25)
 return floor_height
