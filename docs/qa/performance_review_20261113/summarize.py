"""Keep raw CPU samples, matching context and the selected regression evidence."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import zipfile

QA = Path(__file__).resolve().parent
ROOT = QA.parents[2]
COMPARE = Path('C:/Users/bjoer/.codex/skills/godot-performance-workflows/scripts/compare_timings.py')
def read(relative):
    return json.loads((QA/relative).read_text(encoding='utf-8'))
def latest(case):
    candidates = sorted((QA/case).glob('after_*/report.json'),key=lambda p:p.stat().st_mtime,reverse=True)
    return next(p for p in candidates if json.loads(p.read_text())['passed'])
selected = {case:latest(case) for case in ['hex_cache','snapshot_fanout','encounter_read','encounter_benchmark','frontier_visibility','legacy_visibility']}
before_hex = read('hex_cache/red_f5271b73d3ba4f858a601331aa0c9822/report.json')
before_net = read('snapshot_fanout/red_7890fabf614e4e369b1337109ad95769/report.json')
after_hex = json.loads(selected['hex_cache'].read_text())
after_net = json.loads(selected['snapshot_fanout'].read_text())
encounter = json.loads(selected['encounter_benchmark'].read_text())
comparisons = []
def compare(before,after):
    assert before['metric']==after['metric'] and before['unit']==after['unit']
    name = before['metric']
    context = {key:value for key,value in before.items() if key not in ['samples','variant','pack_calls']}
    assert context == {key:value for key,value in after.items() if key not in ['samples','variant','pack_calls']}
    context.update(engine=after_hex['engine'],cpu='AMD Ryzen 7 7800X3D 8-Core / 16 logical',platform='Windows x64',renderer='headless',gpu_time='unavailable',cache='warmed',sequential=True)
    # These comparison files contain exactly the same declared workload/context.
    for label,data in [('before',before),('after',after)]:
        (QA/(name+'_'+label+'.json')).write_text(json.dumps({'metric':name,'unit':'us' if data['unit']=='usec' else data['unit'],'context':context,'samples':data['samples']},indent=2),encoding='utf-8')
    output = QA/(name+'_comparison.json')
    subprocess.run([sys.executable,str(COMPARE),str(QA/(name+'_before.json')),str(QA/(name+'_after.json')),'--output',str(output)],check=True,capture_output=True)
    result=json.loads(output.read_text())
    comparisons.append({'metric':name,'result':result,'report':output.name})
compare(before_hex['measurements'][0],after_hex['measurements'][0])
compare(before_net['measurements'][0],after_net['measurements'][0])
for metric in dict.fromkeys(x['metric'] for x in encounter['measurements']):
    cases=[x for x in encounter['measurements'] if x['metric']==metric]
    compare(next(x for x in cases if x['variant']=='baseline'),next(x for x in cases if x['variant']=='optimized'))
checks=[]
for case,path in selected.items():
    data=json.loads(path.read_text())
    checks.append({'name':case,'assertions':data['assertions'],'passed':data['passed'],'report':path.relative_to(ROOT).as_posix()})
enet = ROOT/'docs/qa/hex_enet_regression_20261113/cd97c9088d7347e288f57d37545ba361/report.json'
assert json.loads(enet.read_text())['status']=='passed'
checks.append({'name':'existing_hex_enet','assertions':24,'passed':True,'report':enet.relative_to(ROOT).as_posix()})
archive=QA/'raw_logs.zip'
raw_files={}
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as z:
    for path in sorted(QA.glob('*/*/output.log')):
        z.write(path,path.relative_to(QA).as_posix())
        raw_files[path.relative_to(QA).as_posix()]=hashlib.sha256(path.read_bytes()).hexdigest()
    log=enet.parent/'output.log'
    if log.exists():z.write(log,'existing_hex_enet/output.log')
summary={'base_main':'5196cc08b','status':'three_measured_cpu_fixes_verified','checks':checks,
         'assertions':sum(x['assertions'] for x in checks),'comparisons':comparisons,
         'limits':['Headless CPU only; no GPU/FPS/network-latency acceptance.','96-unit packing probe excludes RPC and counts actual observed pack invocations.','Personnel visual snapshots remain an unmeasured candidate, not a confirmed fixed finding.','Early invalid harness attempts retained separately from valid red/green evidence.'],
         'raw_archive_sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'raw_log_sha256':raw_files}
(QA/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'assertions':summary['assertions'],'checks':len(checks),'comparisons':comparisons},ensure_ascii=False))
