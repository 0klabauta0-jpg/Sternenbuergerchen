import bpy,json
from pathlib import Path
from mathutils import Vector
ROOT=Path(r'C:/Users/bjoer/.codex/worktrees/grafikreferenzen-20261101/SternenBuergerchen')
OUT=ROOT/'output/grafik_20261101/model_studies'
RND=ROOT/'docs/reports/assets/grafik-2026-11-01/ship_studies'
for ship,length in [('cutlass',37.5),('buccaneer',15.25)]:
 bpy.ops.wm.open_mainfile(filepath=str(OUT/ship/'material_candidate.blend'))
 sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.device='GPU';sc.cycles.samples=16
 prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
 for d in prefs.devices:d.use=d.type=='OPTIX'
 mat=bpy.data.materials.new('QA_ONLY_barycentric_wire');nodes=mat.node_tree.nodes;links=mat.node_tree.links
 bs=next(n for n in nodes if n.type=='BSDF_PRINCIPLED');wire=nodes.new('ShaderNodeWireframe');wire.use_pixel_size=True;wire.inputs['Size'].default_value=.5
 mix=nodes.new('ShaderNodeMixRGB');mix.inputs[1].default_value=(.5,.55,.58,1);mix.inputs[2].default_value=(.003,.005,.008,1);links.new(wire.outputs['Fac'],mix.inputs[0]);links.new(mix.outputs[0],bs.inputs['Base Color']);bs.inputs['Roughness'].default_value=1
 for ob in [o for o in sc.objects if o.type=='MESH']:
  ob.data.materials.clear();ob.data.materials.append(mat)
  for p in ob.data.polygons:p.material_index=0
 sc.camera.location=Vector((1.15,1.7,1.15)).normalized()*length*1.56;sc.camera.rotation_euler=(-sc.camera.location).to_track_quat('-Z','Y').to_euler();sc.camera.data.ortho_scale=length*1.16;sc.render.filepath=str(RND/(ship+'_qa_wire.png'));bpy.ops.render.render(write_still=True)
 print('WIRE_RENDER '+ship,flush=True)
