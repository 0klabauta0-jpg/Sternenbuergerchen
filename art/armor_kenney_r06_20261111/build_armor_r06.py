"""R06 authored armor volumes. Blender 5.1.1, own background scene only.

Local Z up, -Y front. Three approved R04 turnarounds are construction targets.
The original Kenney body is never remodelled. This file is editable source.
"""
import bpy, bmesh, math, json, sys, hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
ART=Path(__file__).resolve().parent
OUT=ROOT/'output/native_glut_maps/armor_r06_parts'
OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
sys.path.insert(0,str(Path.home()/'.codex/skills/blender-asset-qa/scripts'))
import qa_check
M=[]
for name,color,metal,rough in [
 ('Ceramic',(.38,.32,.255,1),.08,.78),
 ('Graphite',(.049,.057,.071,1),.05,.9),
 ('Titanium',(.13,.15,.18,1),.18,.68),
 ('Amber',(.98,.49,.075,1),.12,.53),
 ('Visor',(.014,.028,.043,1),.45,.24)]:
 m=bpy.data.materials.new('M_Armor_'+name);m.diffuse_color=color
 p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
 p.inputs['Base Color'].default_value=color;p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 M.append(m)
clear=bpy.data.materials.new('M_Armor_ClearVisor');clear.diffuse_color=(.55,.73,.84,.10)
clear.surface_render_method='DITHERED';clear.use_backface_culling=True
p=next(n for n in clear.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
p.inputs['Base Color'].default_value=(.55,.73,.84,1);p.inputs['Alpha'].default_value=.10;p.inputs['Roughness'].default_value=.10;p.inputs['Metallic'].default_value=.12
M.append(clear)

class Mesh:
 def __init__(self,name):self.name=name;self.v=[];self.f=[];self.m=[]
 def add(self,v,f,m=0):
  off=len(self.v);self.v+=v;self.f += [tuple(i+off for i in p) for p in f]
  self.m += m if isinstance(m,list) else [m]*len(f)
 def object(self):
  me=bpy.data.meshes.new(self.name);me.from_pydata(self.v,[],self.f);me.update()
  ob=bpy.data.objects.new(self.name,me);bpy.context.collection.objects.link(ob)
  for m in M:me.materials.append(m)
  for f,mi in zip(me.polygons,self.m):f.material_index=mi
  return ob

def plate(a,pts,front=-.45,thick=.10,mat=0,bevel=.07,inset=None,curve=0):
 """Faceted convex plate with swept rim, bevel and true side returns."""
 n=len(pts);cx=sum(p[0] for p in pts)/n;cz=sum(p[1] for p in pts)/n
 fun=front if callable(front) else lambda x,z:front
 v=[(x,thick,z) for x,z in pts]
 v += [(x,0,z) for x,z in pts]
 v += [(cx+(x-cx)*(1-bevel),-.025,cz+(z-cz)*(1-bevel)) for x,z in pts]
 f=[tuple(reversed(range(n)))];mi=[1]
 for i in range(n):
  j=(i+1)%n;f.extend([(i,j,j+n,i+n),(i+n,j+n,j+2*n,i+2*n)]);mi += [mat,mat]
 f.append(tuple(range(2*n,3*n)));mi.append(mat if inset is None else inset)
 if curve:
  # A real five-point cross section, not a bevel on a flat polygon. The
  # central front stays in place while the sides return around the body.
  me=bpy.data.meshes.new('curved_shell');me.from_pydata(v,[],f);me.update()
  for poly,material in zip(me.polygons,mi):poly.material_index=material
  bm=bmesh.new();bm.from_mesh(me)
  half=max(abs(x-cx) for x,z in pts)
  for t in [-.5,0,.5]:
   bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=(cx+t*half,0,0),plane_no=(1,0,0),clear_inner=False,clear_outer=False)
  for p in bm.verts:p.co.y+=fun(p.co.x,p.co.z)+curve*((p.co.x-cx)/half)**2
  bm.verts.ensure_lookup_table();bm.verts.index_update()
  a.add([tuple(p.co) for p in bm.verts],[tuple(p.index for p in face.verts) for face in bm.faces],[face.material_index for face in bm.faces]);bm.free();bpy.data.meshes.remove(me)
 else:a.add([(x,y+fun(x,z),z) for x,y,z in v],f,mi)

def octagon(x0,z0,w,h,cut=.2):
 return [(x0-w*.5+cut*w,z0-h*.5),(x0+w*.5-cut*w,z0-h*.5),(x0+w*.5,z0-h*.5+cut*h),(x0+w*.5,z0+h*.5-cut*h),(x0+w*.5-cut*w,z0+h*.5),(x0-w*.5+cut*w,z0+h*.5),(x0-w*.5,z0+h*.5-cut*h),(x0-w*.5,z0-h*.5+cut*h)]

def folded_pectoral(a,pts,light):
 t=Mesh('folded_pectoral')
 plate(t,pts,lambda x,z:-.43+.25*abs(x),.16 if not light else .18,0,.11,curve=.075 if light else .10)
 me=bpy.data.meshes.new('fold_temp');me.from_pydata(t.v,[],t.f);me.update()
 for f,m in zip(me.polygons,t.m):f.material_index=m
 bm=bmesh.new();bm.from_mesh(me)
 bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=(0,0,.18),plane_no=(0,0,1),clear_inner=False,clear_outer=False)
 for v in bm.verts:v.co.y += abs(v.co.z-.18)*(.32 if light else .55)-(.060 if light else .15)
 bm.verts.ensure_lookup_table();bm.verts.index_update()
 a.add([tuple(v.co) for v in bm.verts],[tuple(v.index for v in f.verts) for f in bm.faces],[f.material_index for f in bm.faces]);bm.free();bpy.data.meshes.remove(me)

def loft(a,rings,mat=1,n=12,profile=None,caps=True):
 profile=profile or [(math.cos(2*math.pi*j/n)*.5,math.sin(2*math.pi*j/n)*.5) for j in range(n)]
 n=len(profile);v=[]
 for z,w,d,*cy in rings:v += [(x*w,y*d+(cy[0] if cy else 0),z) for x,y in profile]
 f=[];mi=[]
 if caps:f.append(tuple(reversed(range(n))));mi.append(mat if isinstance(mat,int) else 1)
 for i in range(len(rings)-1):
  for j in range(n):f.append((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j));mi.append(mat if isinstance(mat,int) else mat(i,j))
 if caps:f.append(tuple(range((len(rings)-1)*n,len(rings)*n)));mi.append(mat if isinstance(mat,int) else 1)
 a.add(v,f,mi)

def tube(a,path,r=.035,mat=0,n=6):
 v=[]
 for i,p in enumerate(path):
  tang=Vector(path[min(i+1,len(path)-1)])-Vector(path[max(i-1,0)])
  tang.normalize();u=tang.cross(Vector((0,1,0))).normalized();w=tang.cross(u).normalized()
  v += [tuple(Vector(p)+r*(math.cos(j*2*math.pi/n)*u+math.sin(j*2*math.pi/n)*w)) for j in range(n)]
 f=[tuple(reversed(range(n)))]
 for i in range(len(path)-1):
  for j in range(n):f.append((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j))
 f.append(tuple(range((len(path)-1)*n,len(path)*n)));a.add(v,f,mat)

PROFILE=[(0,-.51),(.30,-.48),(.47,-.30),(.50,.04),(.43,.33),(.25,.47),(0,.50),(-.25,.47),(-.43,.33),(-.50,.04),(-.47,-.30),(-.30,-.48)]

def clear_visor(a):
 rows=[(.29,.45,.53,-.27),(.12,.45,.57,-.16),(-.10,.445,.58,-.14),(-.26,.40,.53,-.24),(-.355,.29,.44,-.35)]
 cols=9;v=[]
 for inner in [False,True]:
  for z,w,front,edge in rows:
   for j in range(cols):
    t=-1+2*j/(cols-1)
    v.append((t*w,edge-(front+edge)*math.cos(t*math.pi/2)+(.008 if inner else 0),z))
 n=len(rows)*cols;outer=[]
 for row in range(len(rows)-1):
  for col in range(cols-1):
   i=row*cols+col;outer.append((i,i+1,i+cols+1,i+cols))
 f=outer+[tuple(i+n for i in reversed(face)) for face in outer]
 border=list(range(cols))+[r*cols+cols-1 for r in range(1,len(rows))]+list(range(n-2,n-cols-1,-1))+[r*cols for r in range(len(rows)-2,0,-1)]
 for i,j in zip(border,border[1:]+border[:1]):f.append((i,j,j+n,i+n))
 a.add(v,f,5)
 # Continuous dark gasket, with the upper/lower ends seated beneath the shell.
 for edge in [list(range(cols)),[r*cols for r in range(len(rows))],[r*cols+cols-1 for r in range(len(rows))]]:
  tube(a,[v[i] for i in edge],.010,1,n=6)
 # Low, closed-section neck ring provides an explicit suit interface.
 rv=[];rf=[];nr=len(PROFILE)
 for w,d,z in [(.67,.70,-.487),(.67,.70,-.455),(.36,.38,-.455),(.36,.38,-.487)]:
  rv += [(x*w,y*d+.05,z) for x,y in PROFILE]
 for row in range(4):
  for j in range(nr):rf.append((row*nr+j,row*nr+(j+1)%nr,((row+1)%4)*nr+(j+1)%nr,((row+1)%4)*nr+j))
 a.add(rv,rf,1)
 # Fixed lower cheek seals close the gap between chin cup and rear shell.
 for s in [-1,1]:
  face=[(s*.43,-.22,-.32),(s*.29,-.365,-.465),(s*.26,.10,-.487),(s*.40,.05,-.27)]
  back=[(x-s*.045,y+.015,z) for x,y,z in face]
  a.add(face+back,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],1)

def helmet(family):
 a=Mesh('helmet_'+family);heavy=family=='heavy'
 if heavy:
  rings=[(-.49,.53,.61,-.045),(-.38,.75,.78,-.045),(-.20,.91,.91,-.015),(-.08,.98,.97,0),(.04,1,.94,.005),(.075,1,1.035,0),(.20,.97,1.02,.012),(.37,.82,.90,.048),(.48,.48,.64,.075),(.50,.20,.35,.08)]
  def material(i,j):return 4 if i==3 and j in [10,11,0,1] else 1 if i==2 and j in [10,11,0,1] else 2
  loft(a,rings,material,profile=PROFILE)
  a.m[-1]=2
  # Small recessed-looking integrated ventilation slots, no protruding mask.
  for side in [-1,1]:
   for z in [-.23,-.29]:
    pts=octagon(side*.17,z,.10,.024)
    plate(a,pts,lambda x,z:-.489+.17*abs(x),.025,1,.18)
 else:
  # Crown and rear shell share a real open-face boundary, never a bucket.
  # Front brow is a shallow M shape; rear tapers away from the lower jaw.
  rings=[(-.49,.56,.56,.10),(-.25,.87,.84,.075),(.29,1,1,0),(.35,.97,1.01,.018),(.46,.70,.81,.06),(.49,.27,.48,.08)]
  profile=[(0,-.51),(.12,-.51),(.32,-.47),(.47,-.30),(.50,.04),(.43,.33),(.25,.47),(.10,.50),(0,.50),(-.10,.50),(-.25,.47),(-.43,.33),(-.50,.04),(-.47,-.30),(-.32,-.47),(-.12,-.51)]
  v=[]
  for inside in [False,True]:
   for i,(z,w,d,cy) in enumerate(rings):
    for j,(x,y) in enumerate(profile):
     zz=z
     if i==2:zz += -.03 if j in [0,1,15] else .025 if j in [2,14] else -.08 if j in [3,13] else -.14 if j in [4,12] else -.09
     if inside:zz-=.028 if i>=2 else 0
     v.append((x*(w-(.07 if inside else 0)),y*(d-(.06 if inside else 0))+cy,zz))
  n=16;k=len(rings);off=n*k;outer=[];mi=[]
  for i in range(k-1):
   for j in range(n):
    if i<2 and j in [13,14,15,0,1,2]:continue
    outer.append((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j))
    mi.append(5 if i==1 and j in range(4,12) else 1 if i<2 else 0)
  outer.append(tuple(range((k-1)*n,k*n)));mi.append(0)
  f=outer+[tuple(t+off for t in reversed(q)) for q in outer];materials=mi+[1]*len(outer)
  edges={}
  for q in outer:
   for x,y in zip(q,q[1:]+q[:1]):
    key=tuple(sorted((x,y)));edges[key]=(edges.get(key,(0,x,y))[0]+1,x,y)
  for count,x,y in edges.values():
   if count==1:f.append((y,x,x+off,y+off));materials.append(2 if x//n>=2 else 1)
  # Cut the crown inlay into the shell with parallel edges. A radial sector
  # would pinch into an hourglass at the crown, unlike the approved top view.
  me=bpy.data.meshes.new('crown_inlay');me.from_pydata(v,[],f);me.update()
  for poly,mat in zip(me.polygons,materials):poly.material_index=mat
  bm=bmesh.new();bm.from_mesh(me)
  for co,no in [((-.115,0,0),(1,0,0)),((.115,0,0),(1,0,0)),((0,0,-.08),(0,0,1)),((0,0,.14),(0,0,1))]:
   bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=co,plane_no=no,clear_inner=False,clear_outer=False)
  for face in bm.faces:
   c=face.calc_center_median()
   if face.material_index==5:face.material_index=0 if c.z>-.08 else 1
   if face.material_index==0 and abs(c.x)<.115 and (c.z>.35 or c.z>.14 and c.y>.12):face.material_index=2
  bm.verts.ensure_lookup_table();bm.verts.index_update()
  a.add([tuple(v.co) for v in bm.verts],[tuple(v.index for v in f.verts) for f in bm.faces],[f.material_index for f in bm.faces]);bm.free();bpy.data.meshes.remove(me)
  if family in ['light','medium']:
   # Medium protection is a continuous rigid lower helmet shell. Deep cheek
   # returns meet the ear housing; a chamfered chin cup stays below the mouth.
   path=[(-.46,-.115,-.10,.26),(-.43,-.235,-.27,.20),(-.29,-.365,-.375,.18),(-.13,-.425,-.415,.15),(0,-.44,-.42,.15),(.13,-.425,-.415,.15),(.29,-.365,-.375,.18),(.43,-.235,-.27,.20),(.46,-.115,-.10,.26)]
   vv=[];ff=[];mm=[]
   for x,y,z,h in path:
    depth=.14 if abs(x)>.4 else .12
    if family=='light':h*=.72;depth*=.75
    vv += [(x,y+.014,z-h/2),(x,y+depth-.014,z-h/2),(x,y+depth,z-h/2+.014),(x,y+depth,z+h/2-.014),(x,y+depth-.014,z+h/2),(x,y+.014,z+h/2),(x,y,z+h/2-.014),(x,y,z-h/2+.014)]
   ff.append(tuple(reversed(range(8))));mm.append(0)
   for j in range(len(path)-1):
    for k in range(8):
     ff.append((j*8+k,j*8+(k+1)%8,(j+1)*8+(k+1)%8,(j+1)*8+k));mm.append(1 if k in [1,2,3] else 0)
   ff.append(tuple(range((len(path)-1)*8,len(path)*8)));mm.append(0)
   a.add(vv,ff,mm)
   plate(a,octagon(0,-.425,.25 if family=='light' else .29,.11 if family=='light' else .15,.17),-.46,.065 if family=='light' else .085,0,.13)
   clear_visor(a)
  # The longitudinal inlay is integrated into the crown faces, no floating strip.
  plate(a,octagon(0,.346,.12,.035),-.501,.052,3,.1)
  q=Mesh('rear_marker');plate(q,octagon(0,.015,.13,.03),-.49,.055,3,.1)
  a.add([(x,-y,z) for x,y,z in q.v],q.f,q.m)
 # Faceted ear couplers: rectangular bevel form for ORC, circles for Morozov.
 for s in [-1,1]:
  q=Mesh('tmp')
  ear_profile=[(-.5,-.32),(-.32,-.5),(.32,-.5),(.5,-.32),(.5,.32),(.32,.5),(-.32,.5),(-.5,.32)]
  loft(q,[(-.035,.22,.26),(.025,.25,.29),(.06,.21,.25)] if heavy else [(-.035,.29,.21),(.025,.33,.23),(.06,.28,.19)],2 if heavy else 0,n=8,profile=None if heavy else ear_profile)
  a.add([(s*(.48+z),y+.04,x-.06) for x,y,z in q.v],q.f,q.m)
  q=Mesh('tmp');loft(q,[(-.012,.135,.16),(.012,.135,.16)] if heavy else [(-.012,.23,.145),(.012,.23,.145)],1,n=8,profile=None if heavy else ear_profile)
  a.add([(s*(.544+z),y+.04,x-.06) for x,y,z in q.v],q.f,q.m)
  if not heavy:
   q=Mesh('tmp');plate(q,octagon(0,0,.047,.18),0,.035,3,.1)
   a.add([(s*(.552-y),x+.015,z-.04) for x,y,z in q.v],q.f,q.m)
 return a

def torso(family):
 a=Mesh('torso_'+family);light=family=='light';heavy=family=='heavy'
 loft(a,[(-.50,.48,.42),(-.25,.56,.49),(.18,.70,.54),(.39,.66,.49),(.50,.44,.38)],1)
 if not heavy:
  for s in [-1,1]:
   pts=[(.035,.40),(.23,.47),(.43,.27),(.43,.07),(.24,-.035),(.04,.015)]
   if light:pts=[(x*.84,z*.64+.07) for x,z in pts]
   else:pts=[(x*1.10,(z-.20)*.80+.20) for x,z in pts]
   folded_pectoral(a,[(s*x,z) for x,z in pts],light)
   # Harness really crosses shoulder from breast to dorsal plate.
   tube(a,[(s*.24,-.30,.39),(s*.27,-.12,.48),(s*.25,.18,.45),(s*.20,.32,.30)],.030 if light else .047,0)
  for z,w in ([(-.15,.50),(-.31,.43)] if light else [(-.15,.60),(-.31,.54),(-.47,.48)]):
   plate(a,[(-w*.5,z+.055),(0,z+.075),(w*.5,z+.055),(w*.5+.02,z-.035),(0,z-.075),(-w*.5-.02,z-.035)],lambda x,z:-.49+abs(x)*.23,.15,0,.14,curve=.055)
   plate(a,octagon(0,z+.005,.095,.027),-.514,.047,3,.1)
  # Back follows same shoulder/waist hierarchy, not a rectangular backpack.
  back=Mesh('temp')
  plate(back,[(-.19,.34),(.19,.34),(.34,.19),(.27,-.045),(0,-.08),(-.27,-.045),(-.34,.19)],lambda x,z:-.42+.10*abs(x),.24,0,.16,curve=.065)
  for z,w in [(-.18,.47),(-.35,.39)]:plate(back,octagon(0,z,w,.14),-.43,.25,0,.15)
  if not light:back.v=[(x*.84,y,z) for x,y,z in back.v]
  if light:
   back=Mesh('temp');plate(back,octagon(0,.14,.37,.26),-.49,.30,0,.12);plate(back,octagon(0,-.14,.35,.10),-.45,.27,0,.12)
  a.add([(x,-y,z) for x,y,z in back.v],back.f,back.m)
 else:
  shield=[(-.32,.40),(.32,.40),(.43,.25),(.37,-.25),(.20,-.43),(0,-.47),(-.20,-.43),(-.37,-.25),(-.43,.25)]
  plate(a,shield,lambda x,z:-.45+.29*abs(x)+.09*max(0,-z),.18,2,.10,curve=.07)
  plate(a,[(-.24,.23),(.24,.23),(.28,.12),(.22,-.25),(0,-.36),(-.22,-.25),(-.28,.12)],lambda x,z:-.51+.25*abs(x)+.12*max(0,-z),.08,0,.12,curve=.055)
  for s in [-1,1]:
   tube(a,[(s*.29,-.37,-.27),(s*.37,-.34,.15),(s*.31,-.31,.38),(s*.28,-.14,.47),(s*.28,.26,.42),(s*.31,.32,-.20)],.037,1)
   plate(a,octagon(s*.31,.29,.10,.063),-.40,.065,0,.10)
  for z,w in [(.32,.28),(.04,.25),(-.23,.28)]:
   b=Mesh('tmp');plate(b,octagon(0,z,w,.24),lambda x,z:-.41+abs(x)*.2,.24,0,.18);a.add([(x,-y,z) for x,y,z in b.v],b.f,b.m)
  plate(a,octagon(.19,.33,.095,.026),-.431,.075,3,.12)
 return a

def sleeve(family,kind):
 a=Mesh(kind+'_'+family);heavy=family=='heavy';light=family=='light'
 if kind=='pauldron':
  # Closed proximal curved roof. Local +Z points inward to shoulder joint.
  rings=[(-.5,.65,.78),(-.38,.94,.98),(-.08,1.07,1.04),(.22,1.00,.94),(.41,.77,.73),(.5,.30,.44)] if light else [(-.50,.65,.70),(-.43,.86,.91),(-.28,.98,1.02),(-.22,.98,1.02),(-.19,.88,.89),(.04,1.08,1.10),(.10,1.08,1.10),(.13,.96,.98),(.30,1.02,1.03),(.43,.72,.78),(.50,.28,.45)]
  if family=='medium':rings=[(-.50,.65,.70),(-.40,.85,.92),(-.23,1.02,1.05),(-.17,1.02,1.05),(-.14,.89,.92),(.26,1.04,1.05),(.42,.73,.80),(.50,.28,.45)]
  shoulder_profile=[(0,-.54),(.22,-.50),(.40,-.36),(.5,-.12),(.5,.17),(.36,.40),(.17,.5),(-.17,.5),(-.36,.40),(-.5,.17),(-.5,-.12),(-.40,-.36),(-.22,-.50)]
  loft(a,rings,lambda i,j:2 if not light and i in ([3] if family=='medium' else [3,6]) else 0,profile=shoulder_profile)
  plate(a,octagon(0,.24,.19,.055),-.535 if not light else -.49,.10,3,.1)
  return a
 # Proper cuff/greave volume; protective front wraps laterally around the limb.
 loft(a,[(-.50,.25,.24),(-.39,.35,.28),(.19,.42,.32),(.40,.38,.30),(.50,.25,.24)],1,n=10)
 # Hidden mounting tongue joins the curved shell to its under-suit carrier.
 # It lies inside the body's envelope in the anatomical fit.
 plate(a,octagon(0,0,.20,.55),-.29,.26,1,.05)
 mat=2 if heavy and kind in ['shin','upper_arm','hand_guard'] else 0
 if kind=='thigh' and heavy:
  plate(a,octagon(0,0,.55,.86,.17),lambda x,z:-.375+.18*abs(x),.26,1,.10,curve=.06)
  for s in [-1,1]:
   plate(a,[(s*.23,.45),(s*.43,.37),(s*.45,-.23),(s*.30,-.44),(s*.17,-.28)],lambda x,z:-.35+abs(x)*.25,.34,0,.16)
  for z in [-.22,.13]:plate(a,octagon(0,z,.69,.105),lambda x,z:-.44+.25*abs(x),.39,1,.1,curve=.10)
 else:
  pts=[(-.29,.46),(.29,.46),(.45,.25),(.36,-.35),(.18,-.48),(-.18,-.48),(-.36,-.35),(-.45,.25)]
  if light:pts=[(x*.65,z*.78) for x,z in pts]
  plate(a,pts,lambda x,z:-.53+.23*abs(x)+.035*z,.32,mat,.15,curve=.12 if light else .15)
  if not light and kind!='thigh':
   plate(a,[(-.16,.25),(.16,.25),(.13,-.28),(-.13,-.28)],lambda x,z:-.56+.23*abs(x)+.15*(x/.45)**2+.035*z,.065,2 if not heavy else 1,.14,curve=.001)
  if kind=='forearm' and heavy:plate(a,octagon(0,-.18,.065,.14),-.62,.07,3,.12)
 if kind=='thigh' and not light:a.v=[(x,y-.35*max(z,0),z) for x,y,z in a.v]
 return a

def knee(family):
 a=Mesh('knee_'+family);heavy=family=='heavy'
 plate(a,octagon(0,0,.94,.88,.21),lambda x,z:-.30+.16*abs(x),.32,0,.18,inset=None,curve=.16)
 if heavy:
  for z in [-.16,.16]:plate(a,octagon(0,z,.55,.07),-.34,.09,2,.16)
 else:plate(a,octagon(0,0,.47,.43,.26),-.345,.06,2,.13)
 return a

FOOT_TEMPLATE=None
def boot(family):
 """Own protective shell conforms to the authoritative Kenney foot envelope.

 Foot and Toes weighted vertices determine the actual ankle/heel/toe shape.
 The original rig/mesh is retained hidden as provenance, never overwritten.
 """
 global FOOT_TEMPLATE
 if FOOT_TEMPLATE is None:
  before=set(bpy.data.objects)
  bpy.ops.import_scene.gltf(filepath=str(ROOT/'Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb'))
  imported=set(bpy.data.objects)-before
  body=next(o for o in imported if o.type=='MESH' and o.name.startswith('character'))
  rig=next(o for o in imported if o.type=='ARMATURE')
  foot=rig.matrix_world@rig.data.bones['LeftFoot'].head_local
  toes=rig.matrix_world@rig.data.bones['LeftToes'].head_local
  front=toes-foot;front.z=0;front.normalize();right=Vector((0,0,1)).cross(front)
  ids={body.vertex_groups[n].index for n in ['LeftFoot','LeftToes']}
  pts=[]
  for v in body.data.vertices:
   if any(g.group in ids and g.weight>.45 for g in v.groups):
    p=body.matrix_world@v.co;pts.append(Vector((p.dot(right),-p.dot(front),p.z)))
  lo=Vector(tuple(min(v[i] for v in pts) for i in range(3)));hi=Vector(tuple(max(v[i] for v in pts) for i in range(3)));center=(lo+hi)*.5;size=hi-lo
  bm=bmesh.new()
  for v in pts:bm.verts.new(tuple((v[i]-center[i])/size[i] for i in range(3)))
  bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001)
  hull=bmesh.ops.convex_hull(bm,input=list(bm.verts),use_existing_faces=False)
  remove=[v for v in bm.verts if not v.link_faces]
  if remove:bmesh.ops.delete(bm,geom=remove,context='VERTS')
  # A dedicated sole edge is cut into the hull, preserving the rounded toe.
  for co,no in [((0,0,-.31),(0,0,1)),((0,0,.12),(0,0,1)),((0,-.14,0),(0,1,0))]:
   bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=co,plane_no=no,clear_inner=False,clear_outer=False)
  bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.verts.ensure_lookup_table();bm.verts.index_update()
  FOOT_TEMPLATE=([tuple(v.co) for v in bm.verts],[tuple(v.index for v in f.verts) for f in bm.faces])
  bm.free()
  for ob in imported:ob.hide_render=True;ob.hide_viewport=True;ob['reference_role']='unaltered original Kenney body, boot envelope only'
 a=Mesh('boot_'+family);v,f=FOOT_TEMPLATE
 mats=[]
 for face in f:
  c=sum((Vector(v[i]) for i in face),Vector())/len(face)
  material=1 if c.z<-.31 else 0 if family=='medium' else 2 if family=='heavy' else 0 if c.y<-.14 else 1
  if c.z>.12 and c.y>-.14:material=1
  mats.append(material)
 a.add(v,f,mats)
 return a

def pelvis(family):
 a=Mesh('pelvis_'+family);heavy=family=='heavy'
 loft(a,[(-.50,.35,.40),(-.10,.57,.55),(.20,.68,.64),(.5,.65,.60)],1)
 if heavy:plate(a,octagon(0,.27,.28,.28),-.48,.18,2,.13)
 if family!='light':
  for s in [-1,1]:plate(a,octagon(s*.32,.25,.26 if heavy else .16,.38 if heavy else .23),lambda x,z:-.38+.07*abs(x),.24,2 if heavy else 0,.14)
 return a

def collar():
 a=Mesh('collar');n=12;v=[]
 # Four nested rings give a real angular padded horseshoe, lower at the throat.
 for width,depth,z in [(1,.85,-.30),(1.04,.94,.18),(.84,.80,.46),(.67,.62,.33),(.66,.60,-.30)]:
  for x,y in PROFILE:
   zz=z + (.09 if y>0 else -.16)*min(1,abs(y)*2)
   v.append((x*width,y*depth,zz))
 f=[];mi=[]
 for i in range(5):
  for j in range(n):f.append((i*n+j,i*n+(j+1)%n,((i+1)%5)*n+(j+1)%n,((i+1)%5)*n+j));mi.append(2 if i in [1,2] else 1)
 a.add(v,f,mi)
 # Flush colored safety tabs are part of the collar surface. Subdivide the
 # two angled front faces with shared boundary topology; never floating decals.
 me=bpy.data.meshes.new('collar_grid');me.from_pydata(a.v,[],a.f);me.update()
 for poly,mat in zip(me.polygons,a.m):poly.material_index=mat
 bm=bmesh.new();bm.from_mesh(me);bm.faces.ensure_lookup_table()
 edges=set(bm.faces[1].edges)|set(bm.faces[10].edges)
 bmesh.ops.subdivide_edges(bm,edges=list(edges),cuts=7,use_grid_fill=True)
 for face in bm.faces:
  c=face.calc_center_median()
  if .33<abs(c.x)<.43 and c.y<-.25 and (-.25<c.z<-.20 or -.15<c.z<-.10):face.material_index=3
 bm.verts.ensure_lookup_table();bm.verts.index_update()
 out=Mesh('collar');out.add([tuple(v.co) for v in bm.verts],[tuple(v.index for v in f.verts) for f in bm.faces],[f.material_index for f in bm.faces]);bm.free();bpy.data.meshes.remove(me)
 return out

exec(compile((ART/'primary_shells.py').read_text(encoding='utf8'),str(ART/'primary_shells.py'),'exec'))

parts=[]
for fam in ['light','medium','heavy']:
 parts += [helmet(fam),torso(fam),pelvis(fam),sleeve(fam,'pauldron'),sleeve(fam,'forearm'),knee(fam)]
 parts += [sleeve(fam,'thigh'),sleeve(fam,'shin'),boot(fam)]
 if fam=='heavy':
  parts += [sleeve(fam,'upper_arm'),sleeve(fam,'hand_guard'),collar()]

reports=[];objects=[]
for a in parts:
 ob=a.object();objects.append(ob)
 bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
 bm=bmesh.new();bm.from_mesh(ob.data)
 # Keep deliberate intersecting component volumes separate; merging equal
 # vertices of independent plates can introduce non-manifold contacts.
 bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
 bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
 bmesh.ops.triangulate(bm,faces=list(bm.faces))
 bm.to_mesh(ob.data);bm.free();ob.data.update()
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=math.radians(58),island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT')
 # Authored flat facets are intentional: controlled broad planes, no inflated smoothing.
 for p in ob.data.polygons:p.use_smooth=p.material_index==5
 ob['reference_status']='R06 model candidate, not aesthetic acceptance'
 ob['front_axis']='Blender -Y / Godot +Z'
 report=qa_check.run(objects=[ob.name],profile='game');report['asset']=ob.name;reports.append(report)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(ob.name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_extras=True)
 ob.location=((len(objects)-1)%6*1.6,(len(objects)-1)//6*1.6,.55)
bpy.ops.wm.save_as_mainfile(filepath=str(ART/'armor_r06_editable.blend'))
(ART/'qa.json').write_text(json.dumps(reports,indent=2),encoding='utf8')
(ART/'manifest.json').write_text(json.dumps({'blender':bpy.app.version_string,'source':'build_armor_r06.py','parts':[{'name':a.name,'bytes':(OUT/(a.name+'.glb')).stat().st_size,'sha256':hashlib.sha256((OUT/(a.name+'.glb')).read_bytes()).hexdigest()} for a in parts],'reference_images':[{'path':str(p.relative_to(ROOT)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in (ROOT/'art/armor_orc_morozov_20261111').glob('*turnaround_ai_r04.png')]},indent=2),encoding='utf8')
print('R06_BUILD',len(parts),'parts','QA',sum(r['pass'] for r in reports),'/',len(parts),flush=True)
