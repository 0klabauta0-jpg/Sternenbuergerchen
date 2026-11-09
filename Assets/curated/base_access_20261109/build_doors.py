import bpy,bmesh,sys,json,os
sys.path.insert(0,r'C:/Users/bjoer/.codex/skills/blender-core/scripts')
import env_report
print('ENV',json.dumps(env_report.run()))
base=os.getcwd();out=os.path.join(base,'Assets/curated/base_access_20261109')
for name,cuts in {
'habitat_cutaway_01':[(-1.8,-.55,2.4,.5),(1.15,-.55,1.4,.5),(0,.15,.5,1.4),(0,2.5,2.1,1.1),(0,1.7,.55,1.8)],
'freihafen_hall_01':[(2.0,-1.7,.65,1.6)]}.items():
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.gltf(filepath=os.path.join(base,'Assets/curated/frontier_illustrated_20261101/structures_pass04',name+'.glb'))
 original=next(o for o in bpy.context.scene.objects if o.type=='MESH')
 bpy.context.view_layer.objects.active=original;original.select_set(True)
 bm=bmesh.new();bm.from_mesh(original.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001);bm.to_mesh(original.data);bm.free()
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.separate(type='LOOSE');bpy.ops.object.mode_set(mode='OBJECT')
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 changed=0
 for o in meshes:
  coords=[o.matrix_world@v.co for v in o.data.vertices];lo=[min(v[i] for v in coords) for i in range(3)];hi=[max(v[i] for v in coords) for i in range(3)]
  # Only thin upright architectural parts are door targets. Furnishings/floor untouched.
  if hi[2]-lo[2]<.35 or min(hi[0]-lo[0],hi[1]-lo[1])>.6:continue
  for i,(x,z,sx,sz) in enumerate(cuts):
   if hi[0]<x-sx/2 or lo[0]>x+sx/2 or hi[1]<-z-sz/2 or lo[1]>-z+sz/2:continue
   bpy.ops.mesh.primitive_cube_add(size=1,location=(x,-z,1.13));c=bpy.context.object;c.name='DoorCut';c.dimensions=(sx,sz,1.72);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
   mod=o.modifiers.new('TraversableDoor_'+str(i),'BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=c
   bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(c,do_unlink=True);changed+=1
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.00001);bm.to_mesh(o.data);bm.free();o.data.validate();o.data.update()
 bpy.ops.object.select_all(action='DESELECT')
 meshes=[o for o in meshes if len(o.data.vertices)>0]
 for o in meshes:o.select_set(True)
 bpy.context.view_layer.objects.active=meshes[0];bpy.ops.object.join();o=bpy.context.object;o.name=name
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.triangulate(bm,faces=list(bm.faces));bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.0001)
 bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.calc_area()<.0000001],context='FACES')
 bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.0001);bm.to_mesh(o.data);bm.free();o.data.validate();o.data.update()
 bpy.ops.wm.save_as_mainfile(filepath=os.path.join(out,'source',name+'.blend'))
 bpy.ops.export_scene.gltf(filepath=os.path.join(out,name+'.glb'),export_format='GLB',export_animations=False)
 print('OUTPUT',name,'parts',len(meshes),'cuts',changed,'faces',len(o.data.polygons))





