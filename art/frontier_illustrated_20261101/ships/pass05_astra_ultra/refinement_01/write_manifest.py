"""Bind final refinement files, independent audits and comparison evidence by SHA-256.

Run with normal Python from the worktree root, passing --cutlass-audit.
Does not modify Blender assets, exports, earlier Pass05 evidence or runtime files.
"""
import argparse
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
PACKAGE = HERE.parent
ROOT = next(p for p in HERE.parents if (p / 'project.godot').exists())


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def record(path):
    p = Path(path).resolve()
    assert p.is_file() and p.stat().st_size, p
    return {'path': p.relative_to(ROOT).as_posix(), 'bytes': p.stat().st_size, 'sha256': sha(p)}


def file_records(value):
    if isinstance(value, dict):
        if all(k in value for k in ('path', 'bytes', 'sha256')):
            yield value
        for v in value.values():
            yield from file_records(v)
    elif isinstance(value, list):
        for v in value:
            yield from file_records(v)


def verified_asset(audit_path):
    audit = json.loads(Path(audit_path).read_text(encoding='utf8'))
    assert audit['pass'] and audit['ready_for_technical_handoff'], audit_path
    assert not audit['errors'] and not audit['warnings'], audit_path
    src = record(audit['inputs']['blend'])
    glb = record(audit['inputs']['glb'])
    assert src['sha256'] == audit['inputs']['blend_sha256']
    assert glb['sha256'] == audit['inputs']['glb_sha256']
    raw = audit['direct_glb']['raw_summary']
    assert raw['meshes'] == 1 and audit['source']['triangles'] < 25000
    summary = {}
    for label in ('direct_glb_comparison', 'roundtrip_comparison'):
        data = audit[label]
        summary[label] = {k: data[k] for k in (
            'pass', 'matched_corners', 'max_position_error_m',
            'max_normal_vector_error', 'max_uv_coordinate_error')}
        summary[label]['materials_and_full_texture_pixels_pass'] = data['materials']['pass']
    return {
        'source': src, 'export': glb, 'audit': record(audit_path),
        'source_parts': len(audit['source']['objects']),
        'triangles': audit['source']['triangles'], 'glb_summary': raw,
        'bbox_blender': audit['source']['bbox'],
        'bbox_gltf_godot': audit['direct_glb']['bbox'],
        'contact_components': len(audit['contact_graph']['components']),
        'qa': {'pass': True, 'errors': 0, 'warnings': 0, **summary},
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cutlass-audit', required=True)
    args = parser.parse_args()
    prior_manifest = PACKAGE / 'manifest.json'
    prior = json.loads(prior_manifest.read_text(encoding='utf8'))
    protected = list(file_records(prior))
    for item in protected:
        current = record(ROOT / item['path'])
        assert current['bytes'] == item['bytes'] and current['sha256'] == item['sha256'], item['path']
    assets = {
        'cutlass': verified_asset(args.cutlass_audit),
        'buccaneer': verified_asset(HERE / 'buccaneer/audit.json'),
    }
    scope_path = HERE / 'buccaneer/scope_check.json'
    scope = json.loads(scope_path.read_text(encoding='utf8'))
    assert scope['pass'] and not scope['unexpected_changed_common_parts']
    assets['buccaneer']['geometry_scope_check'] = record(scope_path)
    for name, asset in assets.items():
        for required in ('VISUAL_REVIEW.md', 'sheets/Ziel_und_Neu.png', 'sheets/Vorher_und_Neu.png', 'sheets/manifest.json'):
            assert (HERE / 'review' / name / required).is_file(), (name, required)
        conditions_path = HERE / 'review' / name / 'matched_conditions.json'
        conditions = json.loads(conditions_path.read_text(encoding='utf8'))
        assert conditions['pass'] and not conditions['errors'] and len(conditions['checks']) == 8
        for binding in conditions['hash_bindings']:
            path = Path(binding['path'])
            if not path.is_absolute():
                path = ROOT / path
            assert binding['pass'] and sha(path) == binding['expected'], str(path)
        asset['matched_comparison'] = record(conditions_path)
        asset['matched_camera_and_light_pairs'] = len(conditions['checks'])
    review_files = [record(p) for p in sorted((HERE / 'review').rglob('*'))
                    if p.is_file() and p.suffix in ('.png', '.json', '.md', '.py')
                    and not any(part.startswith('iterations_') for part in p.parts)]
    authoring_files = [record(p) for p in sorted(HERE.rglob('*'))
                       if p.is_file() and p.suffix in ('.py', '.md')
                       and 'review' not in p.relative_to(HERE).parts
                       and 'iterations' not in p.relative_to(HERE).parts
                       and 'source' not in p.relative_to(HERE).parts]
    authoring_files.append(record(ROOT / 'docs/tasks/ART_2026_11_01_astra_ship_revision.md'))
    dependencies = [record(PACKAGE / p) for p in (
        'qa_tools/verify_ship.py', 'qa_tools/consolidate_glb.py',
        'qa_tools/render_matched.py', 'qa_tools/tool_manifest.json',
        'buccaneer/make_paint_textures.py', 'reference_sources.json')]
    dependencies.extend(record(p) for p in sorted((PACKAGE / 'buccaneer/textures').glob('*.png')))
    dependencies.extend(record(p) for p in sorted((HERE / 'cutlass/textures').glob('*.png')))
    data = {
        'schema': 'sternenbuergerchen.ship_refinement.v1',
        'status': 'separate_refined_model_candidates_not_user_approved_not_integrated',
        'scope': 'Cutlass engine cowls and front endplates; Buccaneer engine pods',
        'previous_manifest': record(prior_manifest),
        'previous_hashed_file_records_unchanged': len(protected),
        'references': json.loads((PACKAGE / 'reference_sources.json').read_text(encoding='utf8')),
        'provenance': {
            'geometry': 'Project-authored refinement of the prior project-authored Pass05 sources. No external OBJ geometry.',
            'textures': 'Existing project-authored procedural textures retained; included in packed BLEND and GLB.',
            'reference_rights': 'Existing generated project concepts; no new license grant for underlying third-party spacecraft designs asserted.',
            'qa_dependency_license': 'Locally installed Blender skill helpers are MIT; original tool_manifest records them.',
        },
        'assets': assets, 'review_files': review_files,
        'authoring_and_documentation': authoring_files, 'dependencies': dependencies,
        'integration_notes': {
            'native_godot_validation': 'Pending main chat, intentionally not performed in this asset-only work.',
            'orientation': 'Blender -Y forward maps to glTF/Godot +Z; Z up maps to Y up.',
            'pivot': 'Whole XY bounding box centered and minimum Z=0 in Blender.',
            'suggested_runtime_scale': 0.22,
            'dimensions': 'Stylized lengths 16m Cutlass and 11m Buccaneer, not canonical vehicle dimensions.',
            'git': 'Continuation of unintegrated task/grafikreferenzen-20261101; no checkout, commit or push.',
        },
    }
    target = HERE / 'manifest.json'
    target.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n', encoding='utf8')
    print(json.dumps({'manifest': str(target), 'old_records_unchanged': len(protected),
                      'new_hashed_records': len(list(file_records(data))),
                      'assets': {k: {'triangles': v['triangles'], 'source_parts': v['source_parts']} for k, v in assets.items()}}))


if __name__ == '__main__':
    main()
