"""Freeze the actual candidate sources/exports/evidence; no model mutations."""
from pathlib import Path
import hashlib,json,datetime
ART=Path(__file__).resolve().parent;ROOT=ART.parents[1];OUT=ROOT/'output/native_glut_maps';PARTS=OUT/'armor_r06_parts'
def record(path):
 return {'path':path.relative_to(ROOT).as_posix(),'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
qa=json.loads((ART/'qa.json').read_text());body=json.loads((ART/'body_source_audit.json').read_text())
assert len(qa)==30 and all(q['pass'] for q in qa)
assert body['pass'] and all(body['raw_loop_serialization_identical'].values())
assert (ART/'runtime_candidate.gd').read_bytes()==(OUT/'personnel_armor_visual_r06.gd').read_bytes()
assert (ART/'body_shape_profile.json').read_bytes()==(PARTS/'body_shape_profile.json').read_bytes()
sources=[p for p in ART.iterdir() if p.suffix in ['.blend','.py','.gd','.gdinc','.json','.md'] and p.name not in ['handoff_manifest.json']]
sources+=list((ART/'validation').glob('*'))
references=[ROOT/'art/armor_orc_morozov_20261111'/f'{family}_turnaround_ai_r04.png' for family in ['light','medium','heavy']]
native=[]
for pattern in ['armor_r06_native*.png','armor_r06_body_compare*.png','armor_r06_walk_only_feet*.png','armor_r06_neck_turn*.png','r06_revision_armor*.png']:
 native+=list(OUT.glob(pattern))
logs=[OUT/name for name in ['armor_r06_probe.gd_native.log','armor_r06_rig_test.gd_headless.log','armor_r06_rig_test.gd_native.log','armor_r06_body_test.gd_headless.log','armor_r06_walk_feet.gd_native.log','armor_r06_headturn_probe.gd_native.log','armor_r06_body_probe.gd_native.log','armor_r06_metrics.gd_headless.log','build_armor_r06.log','build_body_r06.log','review_armor_r06.log','audit_body_source.log']]
exports=sorted(PARTS.glob('*.glb'))+[PARTS/'body_shape_profile.json']
assert len(list(PARTS.glob('*.glb')))==31
manifest={
 'revision':'armor_kenney_r06_20261111','status':'candidate_ready_for_root_integration_not_user_aesthetic_acceptance',
 'generated_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),
 'blender':'5.1.1','godot':'4.6.2','wearable_glbs':30,'reference_body_glbs':1,
 'runtime_profile':'output/native_glut_maps/armor_r06_parts/body_shape_profile.json',
 'runtime_helper':record(OUT/'personnel_armor_visual_r06.gd'),
 'outfits':json.loads((ART/'runtime_metrics.json').read_text()),
 'checks':{'wearable_geometry_qa':[30,0],'rig_headless':[132,0],'rig_native':[132,0],'body_projection':[154,0],'body_source_audit':True,
           'walk_clip':'walk','walk_normalized_phases':[.15,.42,.70],'head_turn_degrees':[-25,25]},
 'accepted_warnings':['Wearable origins centered at attachment, not ground.','One enclosed hidden internal carrier in each Light and Heavy torso.','Inherited original body: 215 coincident-position vertices, 432 open boundary edges, 12 split islands; independently identical to original.'],
 'limits':['No aesthetic user acceptance.','Shoulder/neck forms more segmented than painted targets.','Actual idle legs are bent; reference stance differs.','Extreme sitting/transport poses and broad FPS/release checks not covered.','Body material/wire images precede source-export-only winding/custom-normal correction; vertex geometry is identical and runtime profile/helper unchanged.'],
 'sources':[record(p) for p in sorted(sources)],'references':[record(p) for p in references],
 'exports':[record(p) for p in exports], 'native_evidence':[record(p) for p in sorted(native)],
 'blender_review':[record(p) for p in sorted(ART.glob('*.png'))], 'logs':[record(p) for p in logs]}
(ART/'handoff_manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
print(json.dumps({'manifest':record(ART/'handoff_manifest.json'),'exports':len(exports),'native_images':len(native),'sources':len(sources),'review_images':len(manifest['blender_review'])}))
