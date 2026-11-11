"""REFERENCE STUDY ONLY: neutral comparisons of existing CC0 accessories.

The user explicitly declined adopting these meshes. Never copy this script's
outputs into the production armor library. build_outfit_parts.py authors the
own helmet geometry used in the game.
"""
import bpy,bmesh,json,math,sys,hashlib
from pathlib import Path
OUT=Path(sys.argv[sys.argv.index('--')+1]).resolve()
SOURCE=Path('C:/Users/bjoer/Pictures/Sternenbürger/Animated Characters Bundle/Accessories')
sys.path.insert(0,str(Path.home()/'.codex/skills/blender-asset-qa/scripts'))
import qa_check
reports=[]
for source_name,target in [('militaryHelmet.fbx','helmet_medium_pack'),('racingHelmet.fbx','helmet_heavy_pack')]:
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.fbx(filepath=str(SOURCE/source_name),use_anim=False)
 originals=[o for o in bpy.context.scene.objects if o.type=='MESH' and 'GogglesTop' not in o.name]
 palette=[]
 for name,color,metal,rough in [('M_Armor_Ceramic',(.52,.50,.45,1),.16,.57),('M_Armor_Graphite',(.035,.045,.061,1),.08,.86),('M_Armor_Titanium',(.14,.17,.21,1),.55,.40),('M_Armor_Amber',(.85,.39,.065,1),.25,.46),('M_Armor_Visor',(.009,.021,.036,1),.65,.20)]:
  m=bpy.data.materials.new(name);m.diffuse_color=color
  p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
  p.inputs['Base Color'].default_value=color;p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
  palette.append(m)
 copies=[]
 for original in originals:
  mesh=original.data.copy();obj=bpy.data.objects.new(original.name+'_Armor',mesh);bpy.context.collection.objects.link(obj)
  obj.matrix_world=original.matrix_world.copy()
  source_materials=[m.name for m in mesh.materials]
  mapping={}
  for index,name in enumerate(source_materials):
   if 'Visor' in original.name: material=4 if '4' in name else 2
   elif 'Goggles' in original.name: material=1 if 'Black' in name else 4
   elif 'Green 1' in name or 'White' in name: material=0
   elif 'Green 2' in name or 'Steel' in name: material=2
   else: material=1
   mapping[index]=material
  face_materials=[mapping.get(f.material_index,0) for f in mesh.polygons]
  mesh.materials.clear()
  for m in palette:mesh.materials.append(m)
  for face,index in zip(mesh.polygons,face_materials):face.material_index=index
  bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
  bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
  copies.append(obj)
 for original in list(bpy.context.scene.objects):
  if original not in copies:bpy.data.objects.remove(original,do_unlink=True)
 bpy.ops.object.select_all(action='SELECT');bpy.context.view_layer.objects.active=copies[0]
 bpy.ops.object.join();obj=bpy.context.object;obj.name=target
 bm=bmesh.new();bm.from_mesh(obj.data)
 bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
 bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.000001)
 bmesh.ops.triangulate(bm,faces=list(bm.faces));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
 bm.to_mesh(obj.data);bm.free();obj.data.validate(clean_customdata=True)
 # Keep the source accessory's constructed forms; only normalize its pivot.
 center=sum((v.co for v in obj.data.vertices),__import__('mathutils').Vector())/len(obj.data.vertices)
 for vertex in obj.data.vertices:vertex.co-=center
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.025);bpy.ops.object.mode_set(mode='OBJECT')
 report=qa_check.run(objects=[obj.name],profile='game');report['asset']=target
 report['source']=str(SOURCE/source_name);report['source_sha256']=hashlib.sha256((SOURCE/source_name).read_bytes()).hexdigest()
 report['accepted_warning_reason']='Wearable accessory with a centered bone pivot; source CC0 shell and visor are intentional constructed subparts.'
 reports.append(report)
 (OUT/'qa_pack_helmets.json').write_text(json.dumps(reports,indent=2),encoding='utf-8')
 if not report['pass']:raise RuntimeError(json.dumps(report))
 bpy.ops.wm.save_as_mainfile(filepath=str(OUT/(target+'.blend')))
 bpy.ops.export_scene.gltf(filepath=str(OUT/(target+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_extras=True)
print('PACK_ARMOR_HELMETS_PASS',len(reports),flush=True)
