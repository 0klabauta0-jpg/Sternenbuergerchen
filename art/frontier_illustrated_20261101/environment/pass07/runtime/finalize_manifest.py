"""Seal the bounded runtime evidence after the parent final suite finishes."""
from pathlib import Path
import hashlib,json,sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
OUT=ROOT/'output/grafik_20261101/pass07_runtime'
SOURCES=['scripts/terrain/terrain_map_3d_view.gd','scripts/terrain/frontier_art_profile.gd','scripts/editor/map_editor.gd','scripts/tests/mission_test_setup.gd','data/terrain_3d_asset_mapping.json','data/terrain_surface_visual_theme_catalog.json','data/terrain_tile_catalog.json','maps/frontier_workyard_24x20.json','data/mission_scenarios/frontier_workyard_24x20.json','scripts/tools/generate_frontier_workyard_24x20.gd','scripts/tests/frontier_runtime_map_slice_verifier.gd']
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rel(p):return str(p.relative_to(ROOT)).replace('\\','/')
def main():
    assert len(sys.argv) in (2,3),'Pass parent strict report, optionally followed by the unchanged-check retry report.'
    parent_path=Path(sys.argv[1]).resolve()
    parent=read(parent_path)
    parent_provenance={'evidence_kind':parent.get('evidence_kind','single_strict_report'),'source_reports':parent.get('source_reports',[]),'scope_note':parent.get('scope_note','')}
    for source in parent_provenance['source_reports']:
        assert sha(ROOT/source['path'])==source['sha256']
    if parent_provenance['source_reports']:
        parent_provenance['all_pass_in_single_run']=False
    effective={c['name']:c for c in parent['checks']}
    retry_info=None
    if len(sys.argv)==3:
        retry_path=Path(sys.argv[2]).resolve();retry=read(retry_path)
        assert all(c['passed'] for c in retry['checks'])
        for check in retry['checks']:
            original=effective[check['name']]
            assert not original['passed'],'A retry must replace a recorded failure, not broaden a passing gate.'
            def script_arg(c):return c['argv'][c['argv'].index('--script')+1]
            assert script_arg(original)==script_arg(check)
            effective[check['name']]=check
        retry_info={'path':rel(retry_path),'sha256':sha(retry_path),'checks':[c['name'] for c in retry['checks']],'original_failures_retained':True,'interpretation':'Same-script retry on unchanged frozen production. Initial raw failure/timeout remains linked; not a clean single-run claim.'}
    assert all(c['passed'] for c in effective.values()) and len(effective)>=27
    native=read(OUT/'native_check.json');headless=read(OUT/'headless_check.json');legacy=read(OUT/'legacy_baseline_comparison.json')
    assert native['passed']==40 and native['failed']==0
    assert headless['passed']==40 and headless['failed']==0
    assert native['editor_authoring']['error_count']==0 and native['editor_authoring']['warnings']==['map_has_no_cover_tiles']
    assert legacy['assertion_sets_identical'] and not legacy['overall_legacy_gates_pass']
    assert not (OUT/'baseline_head').exists()
    for path,expected in native['source_sha256'].items():
        assert sha(ROOT/path.removeprefix('res://'))==expected,path
    controls=native['runtime_controls'];assert len(controls)==4
    for v in controls:
        p=ROOT/v['path'].removeprefix('res://')
        assert sha(p)==v['sha256'] and p.stat().st_size>10000
        v['path']=rel(p);v['opened']=True
        assert v['map_sha256']==sha(ROOT/'maps/frontier_workyard_24x20.json')
    asset=ROOT/'Assets/curated/frontier_illustrated_20261101/structures_pass04/utility_fuel_01.glb'
    assert sha(asset)=='7e7c54b23548b95ee0483a9233f2c5fd256eaac5a01f153c8b8b7c2a1240b274'
    source_entries=[{'path':p,'sha256':sha(ROOT/p)} for p in SOURCES]
    snapshots=HERE/'source';snapshots.mkdir(exist_ok=True)
    for p in ['scripts/terrain/frontier_art_profile.gd','scripts/tools/generate_frontier_workyard_24x20.gd']:
        (snapshots/(Path(p).name+'.txt')).write_bytes((ROOT/p).read_bytes())
    result={'schema':'sternenbuergerchen.pass07_runtime_map_slice.v1','status':'bounded regular-map graphics/authoring candidate frozen; no artistic or full-playthrough approval','task':'docs/tasks/ART_2026_11_01_pass07_paths_runtime.md','branch':'task/grafikreferenzen-20261101; intentional unintegrated continuation on501201b0c, no broad merge','runtime_sources':source_entries,'map':read(OUT/'authoring.json'),'scenario':'data/mission_scenarios/frontier_workyard_24x20.json','entry':{'editor_scene':'scenes/editor/map_editor.tscn','scenario_action':'Mission Scenario -> Load -> frontier_workyard_24x20.json -> Live Test','mission_scene':'scenes/tests/mission_reactivity_test.tscn','api_start_policy_changed':False,'activation':'The pre-existing mission PackedScene sets defer_friendly_runtime_activation=false; Meta selects its own value separately. No new API/override/teleport was retained.','controlled_roster':'Existing MissionSetup roster fields select four real units in BLUE for the reproducible diagnostic runner; normal editor scene defaults unchanged.','interactive_command':'Godot --path . --script scripts/tests/frontier_runtime_map_slice_verifier.gd -- --play-workyard'},'authority':'Saved TerrainMapData owns surface/occupied cells; TerrainRegistry indexes them; existing TacticalController MOVE/GO routes through FireteamMovementController to SimulationRoot. Renderer owns no navigation or gameplay truth.','profile_priority':'Explicit set_frontier_art_enabled(true/false) > CLI fallback --frontier-art-v1 > saved theme. clear_frontier_art_override restores CLI/theme. Topology independent of theme; legacy defaults square8.','asset':{'path':rel(asset),'sha256':sha(asset),'source_manifest':'art/frontier_illustrated_20261101/structures/pass04/manifest.json','new_geometry':False,'triangles':3100,'materials':6,'runtime_scale':0.35,'ground_y':0,'new_collision_nodes':False,'new_navigation_system_or_nodes':False,'authored_reservation_cells':7,'los_or_cover_feature_added':False},'qa':{'headless':{'passed':40,'failed':0,'path':rel(OUT/'headless_check.json'),'sha256':sha(OUT/'headless_check.json')},'native':{'passed':40,'failed':0,'path':rel(OUT/'native_check.json'),'sha256':sha(OUT/'native_check.json')},'own_strict_matrix':{'path':rel(HERE/'checks.json'),'effective_passed':10,'failed':2,'all_pass':False,'note':'Initial own CLI test wrongly rendered before Tree entry; repaired test-only bootstrap probe has a clean4/4 strict rerun. TASK158/159 remain red and unchanged.'},'legacy_baseline':legacy,'legacy_comparison_path':rel(OUT/'legacy_baseline_comparison.json'),'parent_final':{'path':rel(parent_path),'sha256':sha(parent_path),'checks':len(effective),'effective_all_pass':True,'all_pass_in_single_run':all(c['passed'] for c in parent['checks']),'retry':retry_info,'scope':'Parent selected current relevant gates; not a claim that the two separately executed legacy gates pass.'},'editor_authoring':native['editor_authoring']},'movement':native['movement'],'runtime_controls':controls,'renderer':native['renderer'],'metadata_corrections':native.get('metadata_corrections',[]),'visual_review':{'opened_all_four_final_controls':True,'finding':'Distinct road/dust fields, full tank frame and tile-zero contact, normal unit proxies and actual changed positions. No missing/imported/inverted main surfaces seen.','marker':'White diamond is saved rally_workyard custom marker; not missing ground or a fallback.','close_camera_limit':'Utility contact-only close-up crops HUD/upper figure; not UI acceptance.','scope':'Leader trace only, accelerated3x actual engine physics, stopped within85 physical world units; not complete squad arrival/normal-speed/Meta/LZ/combat/campaign/performance acceptance.'},'authoring_warning_fix':{'original_count':481,'cause':'480 flat cells inherited generic edge_type=cliff, plus absent cover content','fix':'Generator explicitly stores edge_type=none; retained Red assertion and initial native images','remaining_warning':'map_has_no_cover_tiles','retained_first_controls':'output/grafik_20261101/pass07_runtime/r01_flat_edge_warning/'},'remaining_work':['Multi-cell placement/erase/rotation footprint tooling','Large building/pad/ramp data integration','Full Hex editor tools/network/save migration','Meta/player-LZ deployment and broader playability acceptance'],'not_changed':['SimulationRoot/Unit/FTL implementation','Meta/deployment entry policy','original utility GLB bytes','Root preview/path/pad/building/report source','Astra/Citizen/ship assets','Git commits/pushes'], 'baseline_provenance':read(OUT/'baseline_source_provenance.json')}
    result['qa']['parent_final'].update(parent_provenance)
    (HERE/'manifest.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps({'manifest':rel(HERE/'manifest.json'),'sources':source_entries,'parent_checks':len(parent['checks']),'native':40,'own_effective_matrix':'10/12, 2 identical HEAD legacy failures'}))
if __name__=='__main__':main()
