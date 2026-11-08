"""Check portable report assets, source hashes and cross-reference coverage."""
import hashlib
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
REPORTS = ROOT / 'docs/reports'
ASSETS = REPORTS / 'assets/ui-flow-bilanz-2026-11-08'
manifest = json.loads((ASSETS / 'manifest.json').read_text(encoding='utf-8'))
data = json.loads((HERE / 'snapshot_data.json').read_text(encoding='utf-8'))
html = (REPORTS / manifest['report']['file']).read_bytes()
assert hashlib.sha256(html).hexdigest() == manifest['report']['sha256']
for entry in manifest['files']:
    raw = (ASSETS / entry['file']).read_bytes()
    assert hashlib.sha256(raw).hexdigest() == entry['sha256'], entry['file']
    assert len(raw) == entry['bytes'], entry['file']
ids = {s['id'] for s in data['sources']}
for section in ['screens', 'flow', 'issues', 'decisions', 'ideas']:
    for item in data[section]:
        assert set(item.get('sources', [])) <= ids, (section, item['id'])
for section in ['screens', 'flow']:
    for item in data[section]:
        for field in ['target', 'native', 'image']:
            if item.get(field):
                assert item[field] in data['images'], (section, item['id'], field)
for image in data['images'].values():
    assert (REPORTS / image['src']).is_file(), image['src']
for source in data['sources']:
    assert (REPORTS / source['path']).is_file(), source['path']
assert b'__REPORT_DATA__' not in html
assert not re.search(rb'<(?:script|link)[^>]+(?:src|href)=["\x27]https?://', html)
assert b'fetch(' not in html and b'XMLHttpRequest' not in html
assert not list(ASSETS.rglob('*.gd')), 'Source evidence must not register Godot scripts'
assert data['meta']['pin'].startswith('33bc504c4')
assert len(data['chats']) == 5
result = dict(report_hash=True, verified_assets=len(manifest['files']),
              images=len(data['images']), sources=len(ids),
              screens=len(data['screens']), flow_steps=len(data['flow']),
              issues=len(data['issues']), decisions=len(data['decisions']),
              ideas=len(data['ideas']), missing_references=0,
              no_external_runtime_dependencies=True,
              no_new_game_tests=True,
              file_browser_check='blocked by browser tool URL policy; not claimed')
(HERE / 'snapshot_verification.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2))
