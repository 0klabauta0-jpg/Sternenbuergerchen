"""Render and bind the scoped Cutlass refinement comparison; sources are read-only."""
import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = next(p for p in HERE.parents if (p / 'docs/PROJECT_BRIEF.md').exists())
PASS = ROOT / 'art/frontier_illustrated_20261101/ships/pass05_astra_ultra'
RENDERER = PASS / 'qa_tools/render_matched.py'
BLENDER = Path('C:/Users/bjoer/AppData/Local/Programs/Blender Foundation/Blender 5.2/blender.exe')


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for key in ('source', 'glb', 'audit', 'expect-source', 'expect-glb'):
        parser.add_argument('--' + key, required=True)
    parser.add_argument('--skip-render', action='store_true')
    args = parser.parse_args()
    source, glb, audit_path = map(lambda x: Path(x).resolve(), (args.source, args.glb, args.audit))
    expected = {source: args.expect_source.lower(), glb: args.expect_glb.lower()}
    for path, wanted in expected.items():
        if sha(path) != wanted:
            raise ValueError('Frozen input hash differs: ' + str(path))
    audit = json.loads(audit_path.read_text(encoding='utf8'))
    if not audit.get('pass') or not audit.get('ready_for_technical_handoff'):
        raise ValueError('Numeric audit is not ready for technical handoff')
    if audit['inputs']['blend_sha256'] != expected[source] or audit['inputs']['glb_sha256'] != expected[glb]:
        raise ValueError('Numeric audit binds different asset bytes')
    audit_hash = sha(audit_path)
    commands = []
    for name, path, views, modes in (
        ('new', source, 'front,rear,side,top,game', 'material'),
        ('source_diagnostics', source, 'front,rear', 'random,wire'),
        ('roundtrip', glb, 'front,rear,game', 'material'),
    ):
        command = [str(BLENDER), '-b', '--factory-startup', '--python-exit-code', '1', '-P', str(RENDERER), '--',
                   '--input', str(path), '--output-dir', str(HERE / name), '--target-length', '16',
                   '--views', views, '--modes', modes, '--front-az', '-52', '--front-el', '35',
                   '--rear-az', '-128', '--rear-el', '35']
        commands.append(command)
        if not args.skip_render:
            subprocess.run(command, check=True, cwd=ROOT)
    subprocess.run([sys.executable, str(HERE / 'verify_refinement_conditions.py'), '--comparison-dir', str(HERE),
                    '--audit', str(audit_path)], check=True, cwd=ROOT)
    references = ROOT / 'docs/reports/assets/grafik-2026-11-01'
    subprocess.run([sys.executable, str(HERE / 'compose_refinement_sheets.py'), '--asset', 'Cutlass',
                    '--comparison-dir', str(HERE), '--reference-front', str(references / '08_cutlass_vorne_wimmel.png'),
                    '--reference-rear', str(references / '09_cutlass_hinten_wimmel.png')], check=True, cwd=ROOT)
    for path, wanted in expected.items():
        if sha(path) != wanted:
            raise ValueError('Input changed during review: ' + str(path))
    if sha(audit_path) != audit_hash:
        raise ValueError('Audit changed during review')
    record = {
        'source': {'path': str(source), 'sha256': expected[source]},
        'glb': {'path': str(glb), 'sha256': expected[glb]},
        'numeric_audit': {'path': str(audit_path), 'sha256': audit_hash},
        'render_commands': commands,
        'helpers': {str(path): sha(path) for path in (RENDERER, HERE / 'verify_refinement_conditions.py', HERE / 'compose_refinement_sheets.py')},
        'matched_conditions_sha256': sha(HERE / 'matched_conditions.json'),
        'sheets_manifest_sha256': sha(HERE / 'sheets/manifest.json'),
        'note': 'Artifact and condition bindings only. Image inspection is separately reported; this is not Godot integration or aesthetic acceptance.',
    }
    (HERE / 'package_binding.json').write_text(json.dumps(record, indent=2), encoding='utf8')
    print('Bound final source, GLB, numeric audit, render conditions and sheets.')


if __name__ == '__main__':
    main()
