import json,hashlib
from pathlib import Path
root=Path.cwd();base=root/'art/frontier_illustrated_20261101/structures';p=base/'manifest.json';m=json.loads(p.read_text())
for name,asset in m['assets'].items():
 raw=json.loads((base/'qa'/(name+'_qa_raw.json')).read_text());asset['evaluated_source_totals']={k:sum(v.get(k,0) for v in raw['objects'].values()) for k in ['verts','faces','tris','boundary_edges','nonmanifold_edges','degenerate_faces','zero_length_edges','inconsistent_normals_edges','inside_out_islands']}
 assert asset['evaluated_source_totals']['tris']==asset['glb']['triangles']
 asset['views_opened']=['front','rear','random','wire'];asset['view_renderer']='Blender Workbench, same geometry; material front/rear plus deterministic per-part colors and wire; native Godot acceptance belongs to parent preview task'
 asset['qa_image_sha256']={kind:hashlib.sha256((base/'qa'/(name+'_'+kind+'.png')).read_bytes()).hexdigest() for kind in ['front','rear','random','wire']}
 asset['source_reference_sha256']={f:hashlib.sha256((root/f).read_bytes()).hexdigest() for f in asset['references']}
 assert hashlib.sha256((root/asset['export_glb']).read_bytes()).hexdigest()==asset['glb']['sha256']
 assert hashlib.sha256((root/asset['source_blend']).read_bytes()).hexdigest()==asset['source_blend_sha256']
 assert hashlib.sha256((root/asset['generator']).read_bytes()).hexdigest()==asset['generator_sha256']
 roundtrip=json.loads((base/'qa/pass02_glb_roundtrip.json').read_text())['assets'][name]
 assert roundtrip['glb_sha256']==asset['glb']['sha256'] and roundtrip['pass']
 asset['glb_roundtrip']=roundtrip
 asset['glb_roundtrip_warning_acceptance']={
  'duplicate verts':'glTF corner vertices split for flat face normals and palette material boundaries; no loose vertices; editable source part topology separately checked.',
  'hidden back-to-back faces':'Closed editable components retain hidden contact caps; shelves support cases and frames contact shells. No same-facing coplanar overlap found.'}
 asset['footprint_delta_from_pass01_m']=[0.0,0.028,0.0] if name=='workshop_01' else [0.0,0.0,0.0]
 asset['visual_review_note']='All four final views opened; supported workbench, rack/cases, frame/bands and service connections inspected. Candidate only; native play-distance and user acceptance remain separate.'
 asset['technical_file_checks_pass']=True
p.write_text(json.dumps(m,indent=2),encoding='utf8')
print(json.dumps({name:asset['evaluated_source_totals'] for name,asset in m['assets'].items()},indent=2))
