"""Freeze provenance for the reviewed R05 candidate without changing geometry."""
from pathlib import Path
import hashlib,json,shutil,subprocess
ART=Path(__file__).resolve().parent
ROOT=ART.parents[1]
OUT=ROOT/'output/native_glut_maps'
shutil.copy2(OUT/'personnel_armor_visual_r05.gd',ART/'runtime_candidate.gd')
def record(p):
 return {'path':str(p.relative_to(ROOT)).replace('\\','/'),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
qa=json.loads((ART/'qa.json').read_text())
files=[ART/n for n in ['armor_r05_editable.blend','build_armor_r05.py','anatomical_fit.gdinc','runtime_candidate.gd','qa.json','runtime_metrics.json','review_armor_r05.py','review_shots.json','README.md']]
files += list((OUT/'armor_r05_parts').glob('*.glb'))
for pattern in ['armor_r05_native*.png','r05_revision_armor_*.png','armor_r05_walk_only_feet_*.png','armor_r05_neck_turn_*.png','armor_r05_fit_*.png']:
 files += list(OUT.glob(pattern))
files += [OUT/n for n in ['personnel_armor_visual_r05.gd','armor_r05_rig_test.gd_native.log','armor_r05_rig_test.gd_headless.log','armor_r05_walk_feet.gd_native.log','armor_r05_headturn_probe.gd_native.log']]
doc={'status':'candidate_ready_for_owner_integration_not_user_aesthetic_acceptance','date':'2026-11-11','blender':'5.1.1','godot':'4.6.2','source_body':record(ROOT/'Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb'),'references':json.loads((ART/'manifest.json').read_text())['reference_images'],'user_overrides':['sealed clear visor and rigid cheek/chin protection for light and medium','less bulk and body-envelope fitting','curved faceted shells with returning sides'],'qa':{'parts':len(qa),'passed':sum(x['pass'] for x in qa),'native_checks_passed':124,'headless_checks_passed':124,'accepted_warning':'centered wearable pivots, not ground props','other_warnings':[w for x in qa for w in x['warnings'] if 'lowest point' not in w],'aesthetic_acceptance':False},'runtime_metrics':json.loads((ART/'runtime_metrics.json').read_text()),'artifacts':[record(p) for p in files]}
(ART/'handoff_manifest.json').write_text(json.dumps(doc,indent=2),encoding='utf8')
print('HANDOFF_ARTIFACTS',len(files),'HELPER_SHA256',record(OUT/'personnel_armor_visual_r05.gd')['sha256'])
