"""Bounded data/content guard; no browser or game execution."""
from pathlib import Path
import hashlib, json, re, subprocess

ROOT = Path(__file__).resolve().parents[3]
report = 'docs/reports/campaign_research_workbench.html'
text = (ROOT / report).read_text(encoding='utf-8-sig')
old = subprocess.check_output(['git', 'show', '6308e6f02:' + report], cwd=ROOT).decode('utf-8-sig')
pattern = r'<script id="baseline" type="application/json">\s*(.*?)\s*</script>'
data = json.loads(re.search(pattern, text, re.S)[1])
previous = json.loads(re.search(pattern, old, re.S)[1])
catalog = json.loads((ROOT / 'data/singleplayer/research.json').read_text(encoding='utf-8-sig'))
checks = []

def check(value, name):
    checks.append({'check': name, 'ok': bool(value)})
    if not value:
        raise AssertionError(name)

nodes = {n['id']: n for n in data['nodes']}
before = {n['id']: n for n in previous['nodes']}
check(len(nodes) == len(data['nodes']) == 23, '23 unique nodes')
check(before.keys() <= nodes.keys(), 'all 21 existing IDs retained')
check(all(nodes[k] == v for k, v in before.items() if k != 'research_industry'), 'other 20 existing nodes unchanged')
for key, node in catalog['nodes'].items():
    expected = node['requires_jobs'] + node['requires_research'] + ['craft_' + k for k in node['requires_fabricated']]
    check(not nodes[key]['proposal'] and nodes[key]['cost'] == node['cost'] and set(nodes[key]['requires']) == set(expected), 'runtime node matches: ' + key)
recipe = catalog['fabrication']['backpack_recycling']
craft = nodes['craft_backpack_recycling']
check(recipe['item'] == 'backpack' and recipe['inputs'] == {'salvage': 2} and craft['cost'] == recipe['cost'] == 20, 'material recipe and price match')
check(not craft['proposal'] and craft['requires'] == ['research_recycling'] and craft['credits'] == 0, 'separate paid manufacturing')
check('2 Bergungsgut' in craft['description'] and 'keine Materialbilanz' in craft['description'], 'material requirement and planning limit visible')
check(nodes['research_ground']['proposal'] and nodes['research_flight']['proposal'], 'vehicle and fleet proposals remain proposals')
visited, active = set(), set()

def visit(key):
    if key in active or key not in nodes:
        raise AssertionError('cycle or missing prerequisite: ' + key)
    if key in visited:
        return
    active.add(key)
    for dependency in nodes[key]['requires']:
        visit(dependency)
    active.remove(key)
    visited.add(key)

for key in nodes:
    visit(key)
check(len(visited) == 23, 'acyclic complete graph')
check(all(n['note'] == '' and n['decision'] == 'offen' for n in data['nodes']), 'baseline does not overwrite user notes')
for source, expected in data['source_hashes'].items():
    check(hashlib.sha256((ROOT / source).read_bytes()).hexdigest() == expected, 'current source hash: ' + source)
for node in data['nodes']:
    if node.get('source', '').startswith('data/singleplayer/research.json#'):
        value = catalog
        for part in node['source'].split('#')[1].split('.'):
            value = value[part]
check(True, 'research and recipe source fragments resolve')
scripts = lambda s: [m for m in re.findall(r'<script([^>]*)>(.*?)</script>', s, re.S) if 'id="baseline"' not in m[0]]
check(scripts(text) == scripts(old), 'executable JavaScript including storage/import/export unchanged')
check(re.findall(r'<style>(.*?)</style>', text, re.S) == re.findall(r'<style>(.*?)</style>', old, re.S), 'CSS unchanged')
check(re.findall(r'\bid="([^"]+)"', text) == re.findall(r'\bid="([^"]+)"', old), 'all control IDs unchanged')
(Path(__file__).parent / 'results.json').write_text(json.dumps({'checks': checks, 'failures': 0}, indent=2) + '\n', encoding='utf-8')
print('WORKBENCH_RECYCLING', len(checks), 'checks; 0 failures')
