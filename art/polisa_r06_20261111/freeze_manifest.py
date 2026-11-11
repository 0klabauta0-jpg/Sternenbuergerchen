"""Hash the concrete private source/evidence package after final image inspection."""
import json,hashlib
from pathlib import Path
A=Path(__file__).resolve().parent
R=A.parents[1]
O=R/'output/native_glut_maps/polisa_r06_20261111'
def entry(p):return {'path':p.relative_to(R).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
source=[p for p in sorted(A.glob('*')) if p.is_file() and p.name!='manifest.json' and not p.name.endswith('.import')]
baseline=[p for p in sorted((A/'baseline_r04').glob('*')) if p.is_file() and not p.name.endswith('.import')]
refs=[p for p in sorted((A/'references').glob('*')) if p.suffix.lower() in ['.png','.jpg','.webp']]
deps=[R/'scripts/terrain/terrain_map_3d_view.gd',R/'shaders/terrain/hex_grid_coverage.gdshader',R/'scripts/terrain/personnel_armor_visual.gd',R/'Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb',R/'Assets/curated/personnel/armor_kenney_r07_20261111/body_r07_derived.glb']
evidence=[p for p in sorted(O.glob('*')) if p.is_file() and p.suffix.lower() in ['.json','.png','.gd','.log']]
data={'schema':'polisa_private_candidate_manifest_v1','revision':'R06','authoring_base_commit':'38bc35468','source_status':'FROZEN private R06 candidate; supersedes abandoned R05; Root owns production integration','source_files':[entry(p) for p in source],'baseline_r04':[entry(p) for p in baseline],'references':[entry(p) for p in refs],'runtime_dependencies_at_capture':[entry(p) for p in deps],'evidence':[entry(p) for p in evidence],'native_metrics':json.loads((O/'native_metrics.json').read_text(encoding='utf-8')),'offline':json.loads((O/'offline_checks.json').read_text(encoding='utf-8')),'limits':['No aesthetic user approval','No release, FPS, battle, journey or save acceptance','Port reserves are geometric, not implemented docking','Root owns live pad catalog, UI and camera/view integration','Grid image-readability status is documented separately in README']}
(A/'manifest.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for name in ['layout.json','layout_compiled.json','polisa_r06_visual.gd']:
 print(name,entry(A/name)['sha256'])
print('candidate map',entry(O/'polisa_station_candidate.json')['sha256'])
print('manifest',entry(A/'manifest.json')['sha256'])
