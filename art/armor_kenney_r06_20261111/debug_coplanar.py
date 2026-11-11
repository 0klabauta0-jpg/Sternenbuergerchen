import bpy,sys
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
art=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(art/'armor_r06_editable.blend'))
sys.path.insert(0,str(Path.home()/'.codex/skills/blender-asset-qa/scripts'));import qa_check
ob=bpy.data.objects['torso_medium'];verts=[v.co.copy() for v in ob.data.vertices];tris=[tuple(f.vertices) for f in ob.data.polygons];normals=[f.normal.copy() for f in ob.data.polygons]
bvh=BVHTree.FromPolygons(verts,tris,epsilon=0);pairs=set()
for ti,t in enumerate(tris):
 a,b,c=(verts[i] for i in t);n=normals[ti];cen=(a+b+c)/3
 for p in (cen,cen.lerp(a,.6),cen.lerp(b,.6),cen.lerp(c,.6)):
  for _,_,tj,_ in bvh.find_nearest_range(p,.001):
   if ti==tj or set(t)&set(tris[tj]) or n.dot(normals[tj])<.999:continue
   a2,b2,c2=(verts[i] for i in tris[tj]);n2=normals[tj];q=p-n2*n2.dot(p-a2)
   if qa_check._point_in_tri(q,a2,b2,c2,n2):pairs.add(tuple(sorted((ti,tj))))
for i,j in pairs:print('PAIR',i,j,tuple(round(v,4) for v in ob.data.polygons[i].center),tuple(round(v,4) for v in ob.data.polygons[j].center),'MAT',ob.data.polygons[i].material_index,ob.data.polygons[j].material_index)
