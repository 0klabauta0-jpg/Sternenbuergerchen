"""Bind this frozen candidate to audits, comparisons and preserved predecessors."""
from pathlib import Path
import json, hashlib, importlib.util
HERE=Path(__file__).resolve().parent
PACKAGE=HERE.parent
ROOT=next(p for p in HERE.parents if (p/'project.godot').exists())
TASK='docs/tasks/ART_2026_11_01_astra_ship_revision.md'
spec=importlib.util.spec_from_file_location('manifest_helpers',PACKAGE/'refinement_01/write_manifest.py')
helpers=importlib.util.module_from_spec(spec);spec.loader.exec_module(helpers)
record=helpers.record;records=helpers.file_records;sha=helpers.sha

def main():
    predecessors=[PACKAGE/'manifest.json',PACKAGE/'refinement_01/manifest.json',PACKAGE/'refinement_02/manifest.json']
    protected={};exceptions=[]
    for p in predecessors:
        for item in records(json.loads(p.read_text(encoding='utf8'))):
            if item['path']==TASK:
                exceptions.append({'path':TASK,'historical_sha256':item['sha256'],'reason':'Explicitly allowed continuation of own task documentation.'});continue
            current=record(ROOT/item['path'])
            assert current['bytes']==item['bytes'] and current['sha256']==item['sha256'],item['path']
            protected[item['path']]=current
    assets={
        'cutlass':helpers.verified_asset(HERE/'cutlass/review/final/independent_qa.json'),
        'buccaneer':helpers.verified_asset(HERE/'buccaneer/audit.json')}
    cut_metrics=json.loads((HERE/'cutlass/review/final/evaluated_proportions.json').read_text(encoding='utf8'))
    layout=cut_metrics['user_layout_checks']
    assert layout['rear_remains_outermost'] and layout['preserved_cabin_turret_exact_geometry']
    assert abs(layout['fore_nozzle_diameter_to_rear']-.5)<1e-5
    bucc_metrics=json.loads((HERE/'buccaneer/evaluated_proportions.json').read_text(encoding='utf8'))
    assert bucc_metrics['pass'] and not bucc_metrics['unexpected_changed_common_parts']
    assert bucc_metrics['unchanged_common_parts']==87 and bucc_metrics['side_glass_min_relative_height']['current']>=.49
    assets['cutlass']['proportion_metrics']=record(HERE/'cutlass/review/final/evaluated_proportions.json')
    assets['buccaneer']['proportion_metrics']=record(HERE/'buccaneer/evaluated_proportions.json')
    for name,a in assets.items():
        rd=HERE/'review'/name
        c=json.loads((rd/'matched_conditions.json').read_text(encoding='utf8'))
        assert c['pass'] and not c['errors'] and len(c['checks'])==8
        for binding in c['hash_bindings']:
            p=Path(binding['path']);p=p if p.is_absolute() else ROOT/p
            assert binding['pass'] and sha(p)==binding['expected'],p
        pb=json.loads((rd/'package_binding.json').read_text(encoding='utf8'))
        for label,assetkey in [('source','source'),('glb','export'),('numeric_audit','audit')]:
            assert sha(Path(pb[label]['path']))==pb[label]['sha256']==a[assetkey]['sha256']
        for required in ['VISUAL_REVIEW.md','sheets/Ziel_und_Neu.png','sheets/Vorher_und_Neu.png']:
            assert (rd/required).is_file()
        extra='Vorher_und_Neu_Oben.png' if name=='cutlass' else 'Vorher_und_Neu_Seite.png'
        assert (rd/'sheets'/extra).is_file()
        assert sha(rd/'matched_conditions.json')==pb['matched_conditions_sha256']
        assert sha(rd/'sheets/manifest.json')==pb['sheets_manifest_sha256']
        sheets=json.loads((rd/'sheets/manifest.json').read_text(encoding='utf8'))
        def check_path_hashes(value):
            if isinstance(value,dict):
                if 'path' in value and 'sha256' in value:
                    p=Path(value['path']);p=p if p.is_absolute() else ROOT/p
                    assert sha(p)==value['sha256'],p
                for v in value.values():check_path_hashes(v)
            elif isinstance(value,list):
                for v in value:check_path_hashes(v)
        check_path_hashes(sheets);check_path_hashes(pb)
        a['comparison']={'conditions':record(rd/'matched_conditions.json'),'bindings':record(rd/'package_binding.json'),'equal_condition_pairs':8,'hash_bindings':len(c['hash_bindings'])}
    files=[]
    for p in sorted(HERE.rglob('*')):
        if not p.is_file() or p==HERE/'manifest.json':continue
        rel=p.relative_to(HERE)
        if any(x.startswith('iteration') or x=='__pycache__' for x in rel.parts):continue
        if p.suffix.lower() in ['.py','.md','.json','.png','.blend','.glb']:files.append(record(p))
    data={
        'schema':'sternenbuergerchen.ship_refinement.v2',
        'status':'reviewed_candidates_not_user_approved_not_integrated',
        'scope':'User-directed four-engine Cutlass with smaller rear pods and narrower forewings; Buccaneer solid lower cockpit tub with upper-half glazing.',
        'predecessor_manifests':[record(p) for p in predecessors],
        'preserved_unique_artifacts':len(protected),'documentation_exceptions':exceptions,
        'assets':assets,'files':files,'task':record(ROOT/TASK),
        'dependencies':[record(PACKAGE/p) for p in ['refinement_01/write_manifest.py','qa_tools/verify_ship.py','qa_tools/consolidate_glb.py','qa_tools/render_matched.py','qa_tools/tool_manifest.json','reference_sources.json']],
        'provenance':{'geometry':'Project-authored procedural modifications; no imported external 3D meshes.','references':json.loads((PACKAGE/'reference_sources.json').read_text(encoding='utf8')),'rights':'No new rights to underlying spacecraft designs asserted.'},
        'integration':{'native_godot':'pending main chat','git':'task/grafikreferenzen-20261101; no checkout, commit or push','dimensions':'stylized inferred 16m Cutlass and11m Buccaneer','orientation':'Blender -Y forward Z up maps to GLB/Godot +Z forward Y up; centered ground pivot'},
    }
    (HERE/'manifest.json').write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    for item in records(data):
        current=record(ROOT/item['path'])
        assert current['bytes']==item['bytes'] and current['sha256']==item['sha256'],item['path']
    print(json.dumps({'manifest':str(HERE/'manifest.json'),'preserved_unique_artifacts':len(protected),'new_records':len(list(records(data))),'assets':{n:a['triangles'] for n,a in assets.items()}}))

if __name__=='__main__':main()

