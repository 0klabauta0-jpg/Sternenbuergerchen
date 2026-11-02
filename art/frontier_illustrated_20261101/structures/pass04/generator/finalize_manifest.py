"""Validate and collect Pass04 evidence; never modify Blender sources or GLBs."""
from pathlib import Path
import hashlib
import json
import struct

HERE = Path(__file__).resolve().parents[1]
ROOT = HERE.parents[3]
QA = HERE / 'qa'
P3 = HERE.parent / 'pass03'
ASSETS = ['habitat_cutaway_01', 'freihafen_hall_01', 'utility_fuel_01']
VIEWS = ['front', 'rear', 'top', 'game', 'random', 'wire', 'roundtrip_front', 'roundtrip_game']


def read(path):
    return json.loads(Path(path).read_text(encoding='utf-8'))


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def rel(path):
    return Path(path).relative_to(ROOT).as_posix()


def file_record(path):
    return {'path': rel(path), 'sha256': sha(path)}


def normalize(value):
    if isinstance(value, dict):
        return {key: normalize(item) for key, item in value.items()}
    if isinstance(value, list):
        return [normalize(item) for item in value]
    return value.replace('\\', '/') if isinstance(value, str) else value


def main():
    roundtrip = read(QA / 'roundtrip.json')
    assert roundtrip['pass']
    rows, retained, sources = [], [], {}
    for asset in ASSETS:
        row = normalize(read(QA / (asset + '_manifest.json')))
        rt = normalize(next(item for item in roundtrip['assets'] if item['asset'] == asset))
        assert row['qa_pass'] and not row['qa_errors'] and rt['pass'] and not rt['raw_errors']
        assert sha(ROOT / row['source']) == row['source_sha256']
        export = ROOT / row['export']['path']
        assert sha(export) == row['export']['sha256'] == rt['glb_sha256']
        data = export.read_bytes()
        length = struct.unpack_from('<I', data, 12)[0]
        gltf = json.loads(data[20:20 + length])
        assert len(gltf['meshes']) == len(gltf['nodes']) == 1
        assert len(gltf['materials']) == row['export']['materials'] <= 12
        assert not any(gltf.get(key) for key in ['animations', 'skins', 'images', 'cameras'])
        assert 'KHR_lights_punctual' not in gltf.get('extensions', {})
        assert rt['maximum_bidirectional_nearest_vertex_error_m'] <= .00003
        assert rt['material_assignment_matches_source']
        assert rt['triangles'] == row['geometry']['triangles'] == row['export']['triangles']
        assert rt['ground_z'] == 0
        row['qa'] = {'pass': True, 'raw': file_record(QA / (asset + '_raw.json')),
                     'source_warnings': row['qa_warnings'], 'source_errors': row['qa_errors']}
        row['roundtrip'] = rt
        row['views'] = normalize(read(QA / (asset + '_views.json')))
        row['opened_images'] = [file_record(QA / (asset + '_' + view + '.png')) for view in VIEWS]
        row['warning_acceptance'] = {
            'hidden_contacts': 'Closed assembly parts retain hidden back-to-back mounting faces. Architecture inherits repeated wall-module abutments; utility retains two service-deck/cabinet contact pairs. Raw names/counts preserved. No visible z-fighting in the opened views.',
            'duplicate_source_positions': 'Inherited Kenney console/pipe/panel mounting shells were split at nonmanifold source contacts; two capped hose meshes retain separate cap-edge vertices. No loose vertices or floating geometry.',
            'open_boundaries': 'Inherited Kenney shell openings and split hidden mounting seams are recorded. No watertight or manufacturing claim.',
            'glb_seams': 'GLB import preserves normal/material seam copies. Bidirectional positions, bounds and per-material triangle counts match exactly without import repair. Exported hoses are visibly more faceted than smooth source curves at close range.',
            'uv': 'Constant-color untextured materials intentionally omit UVs.'}
        if asset != 'utility_fuel_01':
            prior = read(P3 / 'qa' / (asset + '_manifest.json'))
            assert sha(ROOT / row['retained_pass03_source']) == row['retained_pass03_source_sha256'] == prior['source_sha256']
            assert sha(ROOT / prior['export']['path']) == row['retained_pass03_export_sha256'] == prior['export']['sha256']
            assert max(abs(a-b) for a, b in zip(row['dimensions_blender_m'], prior['dimensions_blender_m'])) < .00001
            retained.append({'asset': asset, 'source': file_record(ROOT / row['retained_pass03_source']),
                             'export': file_record(ROOT / prior['export']['path']), 'unchanged': True,
                             'bbox_unchanged_within_m': .00001})
        if asset == 'habitat_cutaway_01':
            row['functional']['functional_zones'] = [
                'sleep: two actual Kenney bed-single bases, fitted blankets and locker',
                'storage: six shelf cases and two actual Kenney container-wide canisters',
                'work: supported bench, tool board, vise, actual Factory maintenance case and backed service conduit',
                'stay: actual Kenney table-display without display ship, two chairs and Kenney computer']
        elif asset == 'freihafen_hall_01':
            row['functional']['human_scale'] = 'factory-derived opening about5.3m clear width/3.6m high; office doorway0.83m wide; desk0.85m above floor; lower office roof2.97m'
        for item in row['kenney_geometry_reuse']:
            assert sha(ROOT / item['source']) == item['source_sha256']
            assert sha(ROOT / item['license_path']) == item['license_sha256']
            source = sources.setdefault(item['source'], {
                'path': item['source'], 'sha256': item['source_sha256'], 'pack': item['pack'],
                'license': item['license'], 'license_path': item['license_path'],
                'license_sha256': item['license_sha256'], 'usages': [], 'modifications': [],
                'original_file_unchanged': True})
            source['usages'].append({'asset': asset, 'instance': item['instance'],
                                     'retained_objects': item['retained_objects']})
            for op in item['operations']:
                if op not in source['modifications']:
                    source['modifications'].append(op)
            if item.get('original_pack_path'):
                original = Path(item['original_pack_path'])
                assert sha(original) == item['source_sha256']
                source['original_pack_path'] = original.as_posix()
                source['copy_byte_identical_to_original_pack'] = True
        rows.append(row)
    references = []
    for name in ['references/current/01_rostgrenze_cutaway.png',
                 'references/current/02_freihafen_distribution_center.png',
                 '03_aussenposten_stilstudie.png']:
        entry = file_record(ROOT / 'docs/reports/assets/grafik-2026-11-01' / name)
        entry['classification'] = 'user-supplied style image; no verified in-game screenshot or gameplay specification'
        references.append(entry)
    page = 'https://robertsspaceindustries.com/en/comm-link/engineering/13360-WIP-Idris-Deck-Gallery'
    sc = []
    for number, key in [(1, 'gnl90odf4g6uyr'), (6, 'mg1puwox31wf5r')]:
        entry = file_record(HERE / 'references' / ('rsi_idris_powerplant_' + str(number) + '_wip_2013.jpg'))
        entry.update({'url': 'https://robertsspaceindustries.com/media/' + key + '/source/Idris_powerplant_' + str(number) + '.jpg',
                      'page': page, 'classification': 'official RSI 2013 WIP in-engine imagery, not current gameplay',
                      'used_for': 'supported industrial groupings, legible pipe couplings/control units and restrained material contrast; no exact geometry copied',
                      'not_redistributed_as_game_texture': True})
        sc.append(entry)
    support = []
    for path in [ROOT / 'Assets/curated/kenney/space_station/models/Textures/colormap.png',
                 ROOT / 'Assets/curated/kenney/factory/models/Textures/colormap.png',
                 HERE / 'source_assets/Assets/curated/kenney/factory/models/Textures/colormap.png']:
        entry = file_record(path)
        entry.update({'license': 'Kenney CC0', 'role': 'source atlas sampled for palette mapping; not embedded in derivative GLBs'})
        support.append(entry)
    dependencies = [HERE / 'generator' / name for name in ['build_pass04.py', 'review_pass04.py', 'verify_roundtrip.py', 'finalize_manifest.py']]
    dependencies += [P3 / 'generator' / name for name in ['build_cutaways.py', 'kenney_modules.py', 'review_cutaways.py']]
    result = {
        'schema': 'sternenbuergerchen.pass04_structures.v1', 'task': 'docs/tasks/ART_2026_11_01_pass04.md',
        'status': 'frozen visual candidates; Blender source/fresh GLB QA passed; native review and user approval belong to parent task',
        'blender': '5.2.3 LTS', 'generator': rel(HERE / 'generator/build_pass04.py'),
        'generator_sha256': sha(HERE / 'generator/build_pass04.py'),
        'dependencies': [file_record(path) for path in dependencies],
        'qa_skill_script': {'path': 'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts/qa_check.py',
                            'sha256': sha(Path('C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts/qa_check.py')),
                            'unmodified': True},
        'references': references, 'official_industrial_references': sc,
        'official_reference_page_snapshot': file_record(HERE / 'references/rsi_idris_source_page.html'),
        'assets': rows, 'kenney_sources': list(sources.values()), 'kenney_supporting_files': support,
        'retained_pass03_originals': retained,
        'qa_runs': {'source': file_record(QA / 'build_r02.log'), 'review': file_record(QA / 'review_r02.log'),
                    'roundtrip': file_record(QA / 'roundtrip_r01.log'),
                    'iteration_note': 'build_r01 was a failed mounting-contact iteration; not accepted as final. build_r02 and the matching fresh roundtrip are final evidence.'},
        'native_interface': {'runtime_scale': .35, 'front_godot': '+Z', 'front_blender': '-Y',
                             'pivot': 'full BBox XY-centered / minZ0', 'units': 'metres',
                             'collision_navigation_lights': False, 'runtime_changes_owned_by_parent': True},
        'visual_review': {'opened': True, 'images_per_asset': 8,
                          'forms': 'Existing P3 rooms/loading aisle preserved; warmer panels, dusty broad base fields, two maintenance cases and service conduits. Utility has a supported twin vertical vessel frame with a connected pump/manifold/control unit.',
                          'limits': 'Intentional architectural cutaway retains high rear/left walls that hide interiors from reverse views. Workbench renders review geometry/palette, not native PBR quality. Fine service details become secondary at fixed overview scale. No extra scratches, decals or greeble cloud.'},
        'not_claimed': ['user visual approval', 'current Star Citizen gameplay appearance', 'native Godot verification by this generator',
                        'refuelling/cargo/interior gameplay', 'authored collision/navigation', 'general performance/release acceptance']}
    (HERE / 'manifest.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps({'manifest': rel(HERE / 'manifest.json'), 'pass': True,
                      'assets': [{'asset': row['asset'], **row['export']} for row in rows]}, indent=2))


if __name__ == '__main__':
    main()
