"""Hash the final private R08 source/evidence package after image inspection."""
import json, hashlib, subprocess
from pathlib import Path
A = Path(__file__).resolve().parent
R = A.parents[1]
O = R / 'output/native_glut_maps/polisa_r08_20261111'
def entry(p):
    return {'path': p.relative_to(R).as_posix(), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}
def source_file(p):
    return p.is_file() and not p.name.endswith(('.import', '.pyc')) and '__pycache__' not in p.parts
source = [p for p in sorted(A.glob('*')) if source_file(p) and p.name != 'manifest.json']
baseline = [p for p in sorted((A/'baseline_r04').rglob('*')) if source_file(p)]
archive = [p for p in sorted((A/'approved_r07').rglob('*')) if source_file(p)]
refs = [R/'art/polisa_r06_20261111/references/station_concept_ai.png']
deps = [R/p for p in ['maps/homebase_frontier_exploration.json', 'scripts/terrain/frontier_outpost_pad.gd', 'scripts/terrain/terrain_map_3d_view.gd', 'shaders/terrain/hex_grid_coverage.gdshader', 'scripts/terrain/personnel_armor_visual.gd', 'Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb', 'Assets/curated/personnel/armor_kenney_r07_20261111/body_r07_derived.glb']]
evidence = [p for p in sorted(O.glob('*')) if p.is_file() and p.suffix.lower() in ['.json', '.png', '.gd', '.log']]
data = {
    'schema': 'polisa_private_candidate_manifest_v1',
    'revision': 'R08',
    'authoring_base_commit': '472f1ad8f',
    'shared_worktree_head_at_freeze': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=R, text=True).strip(),
    'source_status': 'FROZEN private R08 candidate; preserves praised R07 form; Root owns production integration',
    'source_files': [entry(p) for p in source],
    'baseline_r04': [entry(p) for p in baseline],
    'approved_r07_archive': [entry(p) for p in archive],
    'references': [entry(p) for p in refs],
    'runtime_dependencies_at_freeze': [entry(p) for p in deps],
    'evidence': [entry(p) for p in evidence],
    'native_metrics': json.loads((O/'native_metrics.json').read_text(encoding='utf-8')),
    'offline': json.loads((O/'offline_checks.json').read_text(encoding='utf-8')),
    'limits': ['R07 user praise is preserved; no R08 aesthetic end acceptance claimed', 'No release, FPS, battle, journey or save acceptance', 'Ports are geometric dressing, not implemented docking', 'Passages are statically open geometry; no interactive door state', 'Root owns production, catalog, UI and camera/view integration', 'Native grid and image-readability evidence is documented in README']
}
(A/'manifest.json').write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
for name in ['layout.json', 'layout_compiled.json', 'polisa_r08_visual.gd', 'manifest.json']:
    print(name, entry(A/name)['sha256'])
print('candidate map', entry(O/'polisa_station_candidate.json')['sha256'])
