"""Read-only source scan; writes evidence only beside this file. No deletion verdicts."""
from pathlib import Path
import collections
import hashlib
import json
import re
import struct
import subprocess
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
MODEL_EXT = {'.glb', '.gltf', '.fbx', '.obj', '.blend'}
TEXT_EXT = {'.gd', '.tscn', '.tres', '.json', '.py', '.ps1', '.md', '.godot', '.cfg'}
PATTERN = re.compile(r'res://[^"\r\n\t<>]*?\.(?:glb|gltf|fbx|obj|blend)(?=["\s,;)\]]|$)', re.I)

def read_json(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def walk(value, pointer=''):
    if isinstance(value, dict):
        for key, child in value.items():
            yield from walk(child, pointer + '/' + str(key))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from walk(child, pointer + '/' + str(index))
    else:
        yield pointer, value

def role(path):
    p = path.as_posix()
    if p.startswith(('scripts/tests/', 'scenes/tests/')):
        return 'test_or_preview_inspect_caller'
    if p.startswith(('scripts/tools/', 'art/')):
        return 'offline_builder_or_art_history'
    if p.startswith('docs/'):
        return 'documentation'
    return 'product_source_or_data_not_reachability_proof'

files = subprocess.check_output(['rg', '--files', 'Assets', 'scripts', 'scenes', 'maps', 'data', 'art', 'docs/dev'], cwd=ROOT, text=True).splitlines()
models = sorted(p.replace('\\', '/') for p in files if Path(p).suffix.lower() in MODEL_EXT and p.startswith('Assets'))
refs = collections.defaultdict(list)
json_errors = []
for name in files:
    path = Path(name)
    if path.suffix.lower() not in TEXT_EXT:
        continue
    # Historical rendered evidence is not a live consumer. Keep source/generator manifests.
    if any(part in {'qa', 'captures', 'check_runs', 'source_assets'} for part in path.parts):
        continue
    text = (ROOT / path).read_text(encoding='utf-8-sig', errors='replace')
    if path.suffix == '.json':
        try:
            data = json.loads(text)
            for pointer, value in walk(data):
                if isinstance(value, str) and Path(value).suffix.lower() in MODEL_EXT:
                    normalized = value.replace('\\', '/')
                    if normalized.startswith('Assets/'):
                        normalized = 'res://' + normalized
                    if normalized.startswith('res://'):
                        refs[normalized].append({'file': path.as_posix(), 'json_pointer': pointer, 'role': role(path)})
        except ValueError as error:
            json_errors.append({'file': path.as_posix(), 'error': str(error)})
    else:
        for line_no, line in enumerate(text.splitlines(), 1):
            for match in PATTERN.finditer(line):
                refs[match.group()].append({'file': path.as_posix(), 'line': line_no, 'role': role(path)})

mapping = read_json(ROOT / 'data/terrain_3d_asset_mapping.json')['models']
palette = read_json(ROOT / 'data/terrain_tile_catalog.json')['tile_types']
by_type = {e['type_id']: e for e in palette}
map_uses = collections.defaultdict(list)
map_summary = []
for name in sorted((ROOT / 'maps').glob('*.json')):
    try:
        data = read_json(name)
    except ValueError:
        # Already recorded above with exact path; invalid fixtures are not maps.
        continue
    if not isinstance(data, dict) or not isinstance(data.get('tiles'), list):
        continue
    counts = collections.Counter()
    for tile in data['tiles']:
        for field in ('type_id', 'object_type_id'):
            if tile.get(field):
                counts[(field, tile[field])] += 1
    rel = name.relative_to(ROOT).as_posix()
    map_summary.append({'file': rel, 'tiles': len(data['tiles']), 'grid_topology': data.get('grid_topology', 'square8'), 'authored_visual_layout_id': data.get('authored_visual_layout_id', ''), 'has_homebase_layout': 'homebase_exploration' in data, 'has_place_presentation': 'place_presentation' in data})
    for (field, type_id), count in sorted(counts.items()):
        entry = mapping.get(type_id, {})
        resolved_key = type_id
        if not entry:
            # Same direction fallback as TerrainMap3DView._strip_direction_suffix.
            for suffix in ('_ne', '_nw', '_se', '_sw'):
                if type_id.endswith(suffix) and type_id[:-len(suffix)] in mapping:
                    resolved_key = type_id[:-len(suffix)]
                    entry = mapping[resolved_key]
                    break
        use = {'file': rel, 'field': field, 'type_id': type_id, 'count': count, 'mapping_key': resolved_key if entry else None}
        map_uses[type_id].append(use)
        if entry.get('model_path'):
            refs[entry['model_path']].append(dict(use, role='stored_tile_via_mapping_visual_override_possible'))

inventory = []
external_missing = []
external_dependencies = []
for name in models:
    path = ROOT / name
    raw = path.read_bytes()
    model_refs = refs.get('res://' + name, [])
    type_ids = [k for k, v in mapping.items() if v.get('model_path') == 'res://' + name]
    item = {'path': name, 'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest(), 'literal_and_mapping_references': model_refs, 'mapping_type_ids': type_ids, 'palette_type_ids': [k for k in type_ids if k in by_type], 'reference_status': 'references_found_inspect_roles' if model_refs else 'no_static_reference_found_dynamic_or_history_unresolved'}
    if path.suffix.lower() in {'.glb', '.gltf'}:
        try:
            if path.suffix.lower() == '.glb':
                length, chunk_type = struct.unpack_from('<II', raw, 12)
                assert chunk_type == 0x4E4F534A
                gltf = json.loads(raw[20:20+length].decode('utf-8').rstrip('\x00 '))
            else:
                gltf = json.loads(raw)
            for record in gltf.get('images', []) + gltf.get('buffers', []):
                uri = record.get('uri', '')
                if uri and not uri.startswith('data:'):
                    target = path.parent / unquote(uri)
                    dep = {'model': name, 'uri': uri, 'exists': target.is_file()}
                    external_dependencies.append(dep)
                    if not dep['exists']:
                        external_missing.append(dep)
        except (ValueError, AssertionError, struct.error) as error:
            item['gltf_inspection_error'] = str(error)
    inventory.append(item)

templates = [{'path': ref, 'references': uses} for ref, uses in refs.items() if '{' in ref]
missing = [{'path': ref, 'references': uses} for ref, uses in refs.items() if '{' not in ref and not (ROOT / ref[6:]).is_file()]
duplicates = collections.defaultdict(list)
for item in inventory:
    duplicates[item['sha256']].append(item['path'])
buildings = []
for key, entry in mapping.items():
    if any(token in key for token in ('building', 'hangar', 'gebaeude', 'habitat', 'workshop')):
        related_ids = [k for k in by_type if k == key or any(k == key + suffix for suffix in ('_ne', '_nw', '_se', '_sw'))]
        uses = [u for group in map_uses.values() for u in group if u.get('mapping_key') == key]
        buildings.append({'type_id': key, 'model_path': entry.get('model_path'), 'palette_type_ids': related_ids, 'stored_map_uses': uses})

result = {'scope': 'Assets models; direct references in product sources/data, art source metadata and docs/dev; top-level saved map tile usage via terrain mapping; glTF external dependencies. No UID resolution, dynamic execution, savegame scan or visual acceptance.', 'source_head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(), 'model_count': len(inventory), 'reference_target_count': len(refs), 'json_errors': json_errors, 'templated_paths_not_missing_resources': templates, 'missing_literal_model_paths': missing, 'missing_external_gltf_dependencies': external_missing, 'external_gltf_dependency_count': len(external_dependencies), 'byte_identical_groups': [v for v in duplicates.values() if len(v) > 1], 'maps': map_summary, 'building_palette_and_placements': buildings, 'models': inventory}
(OUT / 'inventory.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({k: result[k] for k in ['source_head', 'model_count', 'reference_target_count', 'external_gltf_dependency_count', 'json_errors', 'missing_external_gltf_dependencies']}, ensure_ascii=False))
print('missing literal model paths:', len(missing), 'building mapping entries:', len(buildings), 'maps:', len(map_summary))
for item in inventory:
    if any(part in item['path'] for part in ('/structures/', '/structures_pass', '/base_access_')):
        print(item['path'], 'refs', len(item['literal_and_mapping_references']))
