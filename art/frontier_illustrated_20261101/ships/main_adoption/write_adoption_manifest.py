"""Hash a curated Ref03 integration set without traversing discarded history.
Does not run or rewrite the frozen historical Ref03 manifest writer.
"""
from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'project.godot').is_file())
PACKAGE=ROOT/'art/frontier_illustrated_20261101/ships/pass05_astra_ultra'
def record(path,role):
    path=Path(path);path=path if path.is_absolute() else ROOT/path
    return {'path':path.relative_to(ROOT).as_posix(),'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'role':role}
def main():
    original=json.loads((PACKAGE/'refinement_03/manifest.json').read_text(encoding='utf8'))
    core={r['path']:r for r in original['files']+original['dependencies']+[a['export'] for a in original['assets'].values()]}
    assert len(core)==120
    selected={}
    def add(path,role):
        item=record(path,role);selected[item['path']]=item
    for item in core.values():
        current=record(item['path'],'ref03_current_120')
        assert current['sha256']==item['sha256'] and current['bytes']==item['bytes'],item['path']
        selected[item['path']]=current
    add(PACKAGE/'refinement_03/manifest.json','frozen_source_manifest')
    for ancestor in original['predecessor_manifests']:
        add(ancestor['path'],'archival_manifest_only_not_transitive_history')
    for tool in (PACKAGE/'qa_tools').iterdir():
        if tool.is_file() and tool.suffix in ['.py','.md','.json']:
            add(tool,'common_qa_tool')
    for ref in original['provenance']['references']['sources']:
        add(ref['path'],'original_2d_reference')
        add(ref['package_copy']['path'],'packed_2d_reference')
    previous=json.loads((PACKAGE/'refinement_02/manifest.json').read_text(encoding='utf8'))
    for asset in previous['assets'].values():
        for field in ['source','export','audit']:
            add(asset[field]['path'],'ref02_comparison_baseline_'+field)
    for relative in ['README.md','refinement_02/README.md','refinement_02/cutlass/README.md','refinement_02/buccaneer/README.md']:
        path=PACKAGE/relative
        if path.is_file():add(path,'comparison_provenance')
    for relative in ['data/frontier_ship_visual_catalog.json','scripts/terrain/frontier_ship_visuals.gd','scripts/terrain/terrain_map_3d_view.gd','scripts/tests/frontier_art_preview.gd','scripts/tests/frontier_main_ship_adoption_verifier.gd']:
        add(relative,'active_integration_source')
    for path in HERE.rglob('*'):
        if path.is_file() and path.suffix in ['.py','.md'] and '__pycache__' not in path.parts:
            add(path,'adoption_reproduction_tool_or_documentation')
    files=sorted(selected.values(),key=lambda r:r['path'])
    output={'schema':'frontier.ship_main_adoption.v1','status':'user_authorized_ref03_adoption_technical_gate_passed_not_exact_2d_acceptance','current_ref03_verified_count':120,'selected_file_count':len(files),'selected_bytes':sum(r['bytes'] for r in files),'source_manifest':record(PACKAGE/'refinement_03/manifest.json','frozen_source_manifest'),'assets':original['assets'],'runtime_catalog':record(ROOT/'data/frontier_ship_visual_catalog.json','active_visual_identity'),'files':files,'reproduction':{'model_build':'Ref03 builders are independent project-authored geometry; editable final blends and generator dependencies retained.','comparison_baselines':'Ref02 final blends, GLBs and audits retained for proportional and matched before/after checks.','historical_manifest_writer':'NOT a portable archive rebuild: the unchanged original Ref03 writer validates all 269 protected predecessor artifacts, deliberately not all staged here. Use this separate curated hash writer.','external_qa':'Pinned qa_check.py and _bpyx.py copied unmodified; declared MIT in retained skill metadata. run_blender_tool.py supplies their import path without editing frozen builders.','environment':'Blender 5.2.3; Pillow/numpy for paint or comparison sheet generation. Frozen old commands/metadata retain original absolute environment paths; adapter does not assert arbitrary OS/tool portability.','budget':'New versioned Ref03 <25000 triangles per ship; original P04 <20000 gate unchanged.','dimensions':'Stylized 16m Cutlass and 11m Buccaneer, runtime scale .22, Godot +Z, source ground Y0; not canonical SC dimensions.'},'omissions':'Unneeded predecessor iteration meshes/renders and .blend1/backups remain local. No source files deleted. The three ancestor manifest files alone do not constitute their full archive.'}
    (HERE/'manifest.json').write_text(json.dumps(output,indent=2)+'\n',encoding='utf8')
    (HERE/'staging_paths.txt').write_text('\n'.join([r['path'] for r in files]+[(HERE/'manifest.json').relative_to(ROOT).as_posix(),(HERE/'staging_paths.txt').relative_to(ROOT).as_posix(),(HERE/'ref03_current_120_paths.txt').relative_to(ROOT).as_posix()])+'\n',encoding='utf8')
    (HERE/'ref03_current_120_paths.txt').write_text('\n'.join(sorted(core))+'\n',encoding='utf8')
    print(json.dumps({'current_verified':120,'selected':len(files),'megabytes':round(output['selected_bytes']/1048576,2),'manifest':str(HERE/'manifest.json')}))
if __name__=='__main__':main()
