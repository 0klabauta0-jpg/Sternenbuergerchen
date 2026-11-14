"""Refresh final mechanical metadata from the actual exported GLB."""
import json,struct
from pathlib import Path
OUT=Path(__file__).resolve().parents[1]/'art/ship_models_20261114/caterpillar'
with (OUT/'caterpillar.glb').open('rb') as f:
    f.read(12);n,_=struct.unpack('<II',f.read(8));doc=json.loads(f.read(n))
nodes={n['name']:n for n in doc['nodes']}
m=json.loads((OUT/'metrics.json').read_text());v=json.loads((OUT/'verification.json').read_text())
m['source_original_triangles']=m['source']['objects'][0]['triangles']
m['source_normalized_welded_triangles']=m.pop('source_triangles',m.get('source_normalized_welded_triangles',242973))
m['triangle_reduction_percent']=100*(1-m['output_triangles']/m['source_original_triangles'])
m['root_translation_gltf']=nodes['Caterpillar'].get('translation',[0,0,0])
m['bounds_blender']=v['fresh_glb'];m['ground_offset']=m['root_translation_gltf'][1]
m['mechanical_clearance_m']=.006
m['pipeline']={'solidify_thickness_hull':.014,'voxel_hull':.007,'solidify_thickness_doors':.008,'voxel_doors':.004,'smooth_factor':.5,'smooth_iterations':2,'planar_dissolve':False,'uv_required':False,'palette':'four new constant materials, source textureless'}
for c in m['controls']:
    t=nodes[c['node']].get('translation',[0,0,0]);c['pivot_local_blender']=[t[0],-t[2],t[1]];c['translation_gltf_at_rest']=t;c.pop('pivot',None)
m['qa_warnings_accepted']={'back_to_back_contacts':'Six triangle pairs in four contacts: closed moving doors must retain their mating skins for opening; lift mount is an intentional assembly contact. No same-facing overlap or topology errors.'}
(OUT/'metrics.json').write_text(json.dumps(m,indent=2))
