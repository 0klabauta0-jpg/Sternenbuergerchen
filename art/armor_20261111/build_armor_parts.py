import bpy,bmesh,json,sys,math,hashlib
from pathlib import Path
output=Path(sys.argv[sys.argv.index('--')+1]).resolve()
output.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
import qa_check
materials=[]
for name,color in [('M_Armor_Cloth',(0.045,0.12,0.13,1)),('M_Armor_Plate',(0.38,0.32,0.21,1)),('M_Armor_Edges',(0.08,0.12,0.13,1))]:
 material=bpy.data.materials.new(name)
 material.diffuse_color=color
 shader=next(node for node in material.node_tree.nodes if node.type=='BSDF_PRINCIPLED')
 shader.inputs['Base Color'].default_value=color
 shader.inputs['Roughness'].default_value=0.85
 materials.append(material)
parts=[('light_chest',(1.0,.18,1.0),.045,0),('medium_chest',(1.08,.27,1.06),.06,1),('heavy_chest',(1.22,.36,1.15),.085,1),('shoulder',(1.0,.65,.65),.12,1),('thigh',(.65,.2,1.0),.065,2),('shin',(.65,.24,1.0),.065,1),('collar',(1.0,.50,.22),.06,2),('back_plate',(1.0,.20,1.0),.045,2)]
reports=[]
for name,dimensions,bevel,material_index in parts:
 if name.endswith('_chest'):
  # Neck opening, shoulder cuts and a tapered waist replace the rejected box.
  profile=[(-.34,-.5),(.34,-.5),(.47,.18),(.46,.36),(.27,.5),(.15,.5),(.12,.38),(-.12,.38),(-.15,.5),(-.27,.5),(-.46,.36),(-.47,.18)]
  vertices=[(x*dimensions[0],y,z*dimensions[2]) for y in [-dimensions[1]/2,dimensions[1]/2] for x,z in profile]
  n=len(profile)
  faces=[tuple(reversed(range(n))),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
  mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.update()
  obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
  bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
 else:
  bpy.ops.mesh.primitive_cube_add(size=1)
  obj=bpy.context.object;obj.dimensions=dimensions
 obj.name=name
 bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 modifier=obj.modifiers.new('Armor chamfer','BEVEL')
 modifier.width=min(bevel,.025) if name.endswith('_chest') else bevel
 modifier.segments=1
 bpy.ops.object.modifier_apply(modifier=modifier.name)
 bm=bmesh.new();bm.from_mesh(obj.data)
 bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
 bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.000001)
 bmesh.ops.triangulate(bm,faces=list(bm.faces));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
 bm.to_mesh(obj.data);bm.free()
 obj.data.materials.append(materials[material_index])
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
 bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.03)
 bpy.ops.object.mode_set(mode='OBJECT')
 obj.data.validate(clean_customdata=True)
 obj['asset_role']='wearable_armor_part'
 obj['pivot_contract']='centered part; positioned by skeleton attachment'
 report=qa_check.run(objects=[obj.name],profile='game')
 if not report['pass']:
  raise RuntimeError(json.dumps(report))
 # A centered wearable part has no independent ground-contact requirement.
 report['accepted_warning_reason']='Centered wearable meshes are attached to bones; their origin is not a character ground pivot.'
 report['asset']=name
 reports.append(report)
 bpy.ops.object.select_all(action='DESELECT');obj.select_set(True)
 bpy.context.view_layer.objects.active=obj
 bpy.ops.export_scene.gltf(filepath=str(output/(name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_extras=True)
 obj.location.x=parts.index((name,dimensions,bevel,material_index))*1.5
 obj.location.z=dimensions[2]/2
bpy.ops.wm.save_as_mainfile(filepath=str(output/'armor_parts.blend'))
(output/'qa.json').write_text(json.dumps(reports,indent=2),encoding='utf-8')
print('ARMOR_PARTS_PASS',len(reports),'parts',flush=True)
