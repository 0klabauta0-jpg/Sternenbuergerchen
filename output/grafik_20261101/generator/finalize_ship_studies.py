import json,hashlib
from pathlib import Path
ROOT=Path(r'C:/Users/bjoer/.codex/worktrees/grafikreferenzen-20261101/SternenBuergerchen')
OUT=ROOT/'output/grafik_20261101/model_studies'
RND=ROOT/'docs/reports/assets/grafik-2026-11-01/ship_studies'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
godot=json.loads((OUT/'godot_import_capture.json').read_text(encoding='utf-8-sig'))
index={'schema':'sternenbuergerchen.ship_material_study_index.v1','status':'Material studies only. Source geometry retained. No runtime or art acceptance.','latest_user_direction':'More Wimmelbild, slightly fewer details. Detailed source meshes remain visibly too busy; simplification is pending.','ships':{}}
for ship in ['cutlass','buccaneer']:
 p=OUT/ship/'manifest.json';m=json.loads(p.read_text());e=godot['ships'][ship]
 checks={'geometry_unchanged':m['geometry_unchanged'],'engine_triangle_count_matches':e['triangles']==m['objects'][0]['triangles'],'engine_materials_present':len(e['materials'])==6 and 'MISSING' not in e['materials'],'native_capture_files_written':all(c['error']==0 and Path(c['path']).is_file() for c in e['captures'])}
 assert all(checks.values())
 m['godot_import_check']=checks
 m['godot_visual_review']='All four native engine captures opened. Front axis, silhouette, pivot and scale are consistent. Black backface areas and jagged shading expose inherited source normal/topology defects; visual/runtime gate is not passed.'
 m['blender_visual_review']='Front, rear, game-distance comparisons and true barycentric wire views opened. Ivory masses, slate shell, dark glazing and small ochre accents are visible. Original fine greebles remain. Geometric paint masks still have rough boundaries; authored semantic panel assignment is needed.'
 m['game_distance_limit']='Illustrative orthographic distance check only; no production tactical camera or gameplay scene acceptance.'
 m['latest_direction_gap']='Source geometry was not simplified. Wimmelbild/fewer-details target remains pending in 3D.'
 m['qa_wire_render']='Cycles barycentric shader, 0.5 pixel wires; temporary QA material only, saved candidate geometry unmodified.'
 m['qa_uv_maps']=0
 m['renders_sha256']={f.name:sha(f) for f in sorted(RND.glob(ship+'*.png'))}
 p.write_text(json.dumps(m,indent=2),encoding='utf8')
 index['ships'][ship]={'manifest':str(p.relative_to(ROOT)).replace('\\','/'),'manifest_sha256':sha(p),'triangles':e['triangles'],'materials':6,'qa_pass':False,'technical_import_checks':checks,'blender_source':m['baseline_renders'],'blender_candidate':m['candidate_renders'],'godot_captures':{c['view']:str(Path(c['path']).relative_to(ROOT)).replace('\\','/') for c in e['captures']},'wire':str((RND/(ship+'_qa_wire.png')).relative_to(ROOT)).replace('\\','/')}
(OUT/'study_index.json').write_text(json.dumps(index,indent=2),encoding='utf8')
print(json.dumps({s:{'triangles':i['triangles'],'technical_checks':i['technical_import_checks'],'qa_pass':i['qa_pass']} for s,i in index['ships'].items()},indent=2))
