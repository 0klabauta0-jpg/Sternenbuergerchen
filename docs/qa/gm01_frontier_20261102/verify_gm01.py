"""Pin current sources to clean contracts, actual normal starts and native PNGs."""
from pathlib import Path
import datetime
import argparse
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rel(path):
    return path.resolve().relative_to(ROOT).as_posix()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--refresh-source-pins', action='store_true')
    args = parser.parse_args()
    accepted = []
    latest = {}
    for report_path in sorted((QA/'checks_final').glob('*/metadata/report.json')):
        for item in json.loads(report_path.read_text(encoding='utf-8'))['checks']:
            item['_report_file'] = str(report_path)
            latest[item['name']] = item
    assert len(latest) == 24
    for item in latest.values():
        assert item['passed'] and item['exit_code'] == 0 and item['marker_found'] and item['error_count'] == 0, item['name']
        log_path = Path(item['_report_file']).parent.parent/'logs'/Path(item['log']).name
        log = log_path.read_text(encoding='utf-8', errors='replace')
        match = re.search(r'RESULTS: (\d+) passed, (\d+) failed', log) or re.search(r'GM01_FRONTIER_REBUILD_RESULT passed=(\d+) failed=(\d+)', log)
        if match:
            count, failed = map(int, match.groups())
        else:
            prefix = next(p for p in ['FRONTIER_RUNTIME_SLICE_RESULT ', 'FRONTIER_HEX_MOVEMENT ', 'FRONTIER_HEX_RENDER '] if p in log)
            details = json.loads(log.split(prefix, 1)[1].splitlines()[0])
            count, failed = details['passed'], details['failed']
        assert count > 0 and failed == 0
        accepted.append({'name':item['name'], 'assertions':count, 'passed':True, 'log':rel(log_path)})
    isolation = json.loads((QA/'checks_profile_isolation.json').read_text(encoding='utf-8'))
    assert isolation['isolated_user_data'] and isolation['project_restored_byte_exact'] and isolation['exit_code'] == 0
    assert isolation['project_sha256'] == sha(ROOT/'project.godot')
    terrain = ROOT/'maps/Ground_Mission01_32x32.json'
    data = json.loads(terrain.read_text(encoding='utf-8'))
    assert data['grid_size'] == {'x':48, 'y':48} and len(data['tiles']) == 2304
    assert data['authored_visual_layout_id'] == 'gm01_frontier_outpost_v1'
    assert terrain.read_bytes() == (QA/'candidate_GM01_hex48x48.json').read_bytes()
    native = json.loads((QA/'frontier_capture_results.json').read_text(encoding='utf-8'))
    assert {tuple(n['logical_size']) for n in native} == {(1920,1080), (1280,720)}
    native_results = []
    paths = set()
    for entry in native:
        actual_path = ROOT/entry['source_report']
        actual = json.loads(actual_path.read_text(encoding='utf-8'))
        process = json.loads((actual_path.parent/'process.json').read_text(encoding='utf-8'))
        assert actual['passed'] > 0 and actual['failed'] == 0 and entry['exit_code'] == 0 and entry['error_count'] == 0
        assert actual['facts']['isolated_user_data'] and not actual['facts']['time_acceleration'] and not actual['facts']['private_simulation_state_writes']
        assert actual['facts']['default_map']['sha256'] == sha(terrain)
        for filename, expected in actual['facts'].get('sources_sha256', {}).items():
            if filename == 'res://project.godot':
                assert expected == process['test_project_sha256']
            else:
                assert sha(ROOT/filename.removeprefix('res://')) == expected, 'Native source drift: '+filename
        assert len(actual['captures']) == 9
        for capture in actual['captures']:
            path = ROOT/capture['path'].removeprefix('res://')
            assert sha(path) == capture['sha256']
            assert [capture['width'], capture['height']] == entry['logical_size']
        stage = next(s for s in actual['stages'] if s['id'] == 'mission_started')['details']['render']
        assert stage['tile_count'] == 2304 and stage['authored_visual_layout_active']
        for asset in stage['authored_visual_assets']:
            path = ROOT/asset['path'].removeprefix('res://')
            assert sha(path) == asset['sha256']
            paths.add(path)
        native_results.append({'resolution':entry['logical_size'],'assertions':actual['passed'],'passed':True,'report':rel(actual_path),'native_captures':len(actual['captures'])})
    exported = json.loads((QA/'html_export_qa.json').read_text(encoding='utf-8'))
    html = ROOT/'docs/reports/STERNENBUERGERCHEN_GM01_FRONTIER_2026-11-02.html'
    assert exported['status'] == 'PASS' and exported['report_sha256'] == sha(html)
    assert json.loads((QA/'import_result.json').read_text(encoding='utf-8'))['passed']
    pin_path = QA/'SOURCE_SNAPSHOT.json'
    previous_pins = json.loads(pin_path.read_text(encoding='utf-8'))['sha256'] if pin_path.exists() else {}
    if not args.refresh_source_pins:
        assert previous_pins, 'Create initial pins explicitly with --refresh-source-pins after fresh evidence'
        for filename, expected in previous_pins.items():
            assert sha(ROOT/filename) == expected, 'Pinned source changed: '+filename
    paths.update(ROOT/name for name in previous_pins)
    changed = subprocess.check_output(['git','diff','HEAD','--name-only'],cwd=ROOT,text=True,encoding='utf-8').splitlines()
    new = subprocess.check_output(['git','ls-files','--others','--exclude-standard'],cwd=ROOT,text=True,encoding='utf-8').splitlines()
    paths.update(ROOT/p for p in changed+new if p.startswith(('scripts/', 'data/', 'maps/')) and (ROOT/p).is_file())
    paths.add(ROOT/'project.godot')
    paths.add(ROOT/'data/mission_scenarios/ground_mission01_default.json')
    paths.add(ROOT/'scripts/tests/frontier_main_startup_verifier.gd')
    paths.add(ROOT/'scripts/tests/mission_test_setup.gd')
    paths.add(ROOT/'scripts/terrain/frontier_ship_visuals.gd')
    for dependency in [
        'scripts/terrain/frontier_art_profile.gd', 'scripts/terrain/frontier_art_geology.gd',
        'scripts/terrain/frontier_art_dressing.gd', 'scripts/terrain/frontier_closed_buildings.gd',
        'scripts/terrain/frontier_worklife.gd', 'scripts/terrain/frontier_access_anchors.gd',
        'scripts/terrain/hex_grid.gd', 'scripts/terrain/hex_ground_batch.gd',
        'scripts/terrain/terrain_pathfinder.gd', 'scripts/terrain/hpa_pathfinder.gd',
        'scripts/terrain/hpa_navigation_graph.gd', 'scripts/core/simulation_root.gd',
        'shaders/terrain/frontier_ground.gdshader', 'shaders/terrain/frontier_contact_paint.gdshader',
        'scenes/meta/homebase_test_screen.tscn', 'scenes/tests/mission_reactivity_test.tscn',
        'data/terrain_3d_asset_mapping.json',
        'scripts/tests/mission_combat_loop_driver.gd', 'scripts/tests/mission_tactical_sandbox_controller.gd',
        'scripts/meta/homebase_screen.gd', 'scripts/meta/meta_layer_flow.gd', 'scripts/meta/meta_ui_skin.gd',
        'scripts/ui/tactical_ui_theme.gd', 'scripts/mission/mission_briefing_panel_presenter.gd',
        'docs/qa/gm01_frontier_20261102/build_report.py',
        'docs/qa/gm01_frontier_20261102/verify_gm01.py',
        'docs/qa/gm01_frontier_20261102/startup_gm01.py',
        'docs/qa/gm01_frontier_20261102/run_isolated_checks.py',
    ]:
        paths.add(ROOT/dependency)
    paths.add(ROOT/'data/frontier_ship_visual_catalog.json')
    paths.add(ROOT/'Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/cutlass_01.glb')
    source = {rel(p):sha(p) for p in sorted(paths)}
    if args.refresh_source_pins:
        pin_path.write_text(json.dumps({'schema':'sternenbuergerchen.gm01_source.v1','sha256':source},indent=2)+'\n',encoding='utf-8')
    summary = {'schema':'sternenbuergerchen.gm01_frontier_qa.v1','checked_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'status':'PASS','map_sha256':sha(terrain),'grid_size':[48,48],'tile_count':2304,'engine_gates':accepted,'engine_assertions':sum(x['assertions'] for x in accepted),'normal_starts':native_results,'normal_start_assertions':sum(x['assertions'] for x in native_results),'html_qa':rel(QA/'html_export_qa.json'),'source_snapshot':rel(QA/'SOURCE_SNAPSHOT.json'),'scope':'bounded map/navigation/editor/normal-time Cutlass deployment and GO; no full campaign, balance, multiplayer, long-run performance or release acceptance'}
    (QA/'VERIFIKATION.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:summary[k] for k in ['status','grid_size','tile_count','engine_assertions','normal_start_assertions']},indent=2))


if __name__ == '__main__':
    main()
