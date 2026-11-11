"""Bounded embedded-baseline data check. No browser/game execution."""
import hashlib,json,re,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
report=ROOT/'docs/reports/campaign_research_workbench.html'
html=report.read_text(encoding='utf-8-sig')
before=subprocess.check_output(['git','show','HEAD:docs/reports/campaign_research_workbench.html'],cwd=ROOT).decode('utf-8-sig')
pattern=r'<script id="baseline" type="application/json">\s*(.*?)\s*</script>'
data=json.loads(re.search(pattern,html,re.S)[1]);old=json.loads(re.search(pattern,before,re.S)[1]);checks=[]
def check(ok,label):
    checks.append({'check':label,'ok':bool(ok)})
    if not ok: raise AssertionError(label)
nodes={n['id']:n for n in data['nodes']};previous={n['id']:n for n in old['nodes']}
research=json.loads((ROOT/'data/singleplayer/research.json').read_text(encoding='utf-8-sig'))
check(len(nodes)==len(data['nodes'])==21,'21 unique baseline node IDs')
check(previous.keys()<=nodes.keys(),'All18 existing IDs retained')
updated=set(research['nodes'])
check(all(nodes[k]==n for k,n in previous.items() if k not in updated),'Other14 previous nodes unchanged, including vehicle proposals')
for id,r in research['nodes'].items():
    n=nodes[id]
    requires=set(r['requires_jobs']+r['requires_research']+['craft_'+b for b in r['requires_fabricated']])
    check(n['proposal'] is False and n['cost']==r['cost'] and n['title']==r['title'] and set(n['requires'])==requires,'Runtime research node and prerequisites match: '+id)
for blueprint,parent in [('medium_armor','research_medium'),('heavy_armor','research_heavy'),('salvage_tool','research_industry')]:
    n=nodes['craft_'+blueprint];recipe=research['fabrication'][blueprint]
    check(not n['proposal'] and n['cost']==recipe['cost'] and n['requires']==[parent] and n['credits']==0,'Separate paid fabrication: '+blueprint)
    check(str(recipe['cost']) in nodes[parent]['reward'],'Research reward quotes separate manufacturing cost: '+blueprint)
check(nodes['research_ground']['proposal'] and nodes['research_flight']['proposal'] and 'bleiben Vorschläge' in nodes['research_industry']['description'],'Vehicles/fleet/processing remain proposals')
visited=set();active=set()
def visit(id):
    check(id in nodes,'Referenced node exists: '+id) if id not in nodes else None
    if id in active: raise AssertionError('Dependency cycle '+id)
    if id in visited:return
    active.add(id)
    for parent in nodes[id]['requires']:visit(parent)
    active.remove(id);visited.add(id)
for id in nodes:visit(id)
check(len(visited)==21,'All prerequisites exist; dependency graph is acyclic')
check(all(n['note']=='' and n['decision']=='offen' for n in data['nodes']),'Baseline contains no overwritten user notes/choices')
for source,expected in data['source_hashes'].items():check(hashlib.sha256((ROOT/source).read_bytes()).hexdigest()==expected,'Current source hash: '+source)
for n in data['nodes']:
    if n.get('source','').startswith('data/singleplayer/research.json#'):
        value=research
        for part in n['source'].split('#')[1].split('.'):value=value[part]
check(True,'New research/fabrication source fragments resolve')
scripts=lambda s:[m for m in re.findall(r'<script([^>]*)>(.*?)</script>',s,re.S) if 'id="baseline"' not in m[0]]
check(scripts(html)==scripts(before),'Executable JavaScript unchanged byte-for-byte: storage/import/export/user drafts')
check(re.findall(r'<style>(.*?)</style>',html,re.S)==re.findall(r'<style>(.*?)</style>',before,re.S),'Styles/layout unchanged')
check(re.findall(r'<[^>]+\bid="([^"]+)"',html)==re.findall(r'<[^>]+\bid="([^"]+)"',before),'All HTML control IDs unchanged')
result={'status':'pass','checks':len(checks),'failures':0,'limits':'Embedded JSON/source/static preservation only; no browser/native/game tests','results':checks}
out=Path(__file__).with_name('results.json');out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f"BASELINE_REFRESH {len(checks)} checks,0 failures; executable JS/CSS/HTML control IDs unchanged")
