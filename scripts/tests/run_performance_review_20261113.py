"""Run one bounded CPU probe in the existing protected private runtime overlay."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import uuid
import sys

sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--case', required=True, choices=['hex_cache', 'snapshot_fanout', 'encounter_read', 'encounter_benchmark', 'personnel_read', 'legacy_visibility', 'frontier_visibility'])
parser.add_argument('--phase', required=True, choices=['before', 'red', 'after'])
args = parser.parse_args()
spec = importlib.util.spec_from_file_location('isolation', ROOT/'scripts/tests/run_review2_isolated.py')
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)
run_id = uuid.uuid4().hex
out = ROOT/'docs/qa/performance_review_20261113'/args.case/(args.phase+'_'+run_id)
out.mkdir(parents=True)
project, app = helper.create_overlay(ROOT, run_id)
user = Path(os.environ['APPDATA'])/'Godot/app_userdata'/app
real_user = Path(os.environ['APPDATA'])/'Godot/app_userdata/Sternenbuergerchen'
def fingerprint(path):
    return {str(p.relative_to(path)):[hashlib.sha256(p.read_bytes()).hexdigest(),p.stat().st_mtime_ns]
            for p in path.rglob('*') if p.is_file()} if path.exists() else {}
before = fingerprint(real_user)
entry = 'scripts/tests/performance_'+args.case+'_20261113.gd'
entry = {'legacy_visibility':'scripts/tests/task_1191_shared_combat_visibility_cache.gd',
         'frontier_visibility':'scripts/tests/frontier_hex_visibility_verifier.gd'}.get(args.case,entry)
sources = [entry, 'scripts/mission/combat_visibility_cache.gd', 'scripts/core/simulation_root.gd',
           'scripts/core/hex_visibility_query.gd', 'scripts/core/hex_sight_runtime_adapter.gd',
           'scripts/meta/campaign_space_encounter_presenter.gd', 'scripts/meta/singleplayer_runtime_adapter.gd',
           'scripts/core/base_personnel_runtime.gd', 'scripts/meta/explorable_homebase.gd']
hashes = {p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources if (ROOT/p).exists()}
engine = shutil.which('godot_console.exe')
version = subprocess.check_output([engine,'--version'], text=True).strip()
assert version.startswith('4.6.2.')
command = [engine,'--headless','--path',str(project),'--script','res://'+entry,'--','--phase='+args.phase]
env = dict(os.environ, SB_REVIEW2_USER_DIR=str(user))
with (out/'output.log').open('wb') as log:
    proc = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        code = proc.wait(timeout=150)
    except subprocess.TimeoutExpired:
        subprocess.run(['taskkill','/PID',str(proc.pid),'/T','/F'],capture_output=True)
        proc.wait(timeout=20)
        code = 124
text = re.sub(r'\x1b\[[0-9;]*m','',(out/'output.log').read_text(encoding='utf-8', errors='replace'))
errors = re.findall(r'^.*(?:SCRIPT ERROR:|ERROR:|ObjectDB instances leaked|resources still in use).*$' ,text,re.M)
marker = re.search(r'PERFORMANCE_(?:REVIEW|ENCOUNTER_READ) passed=(\d+) failed=(\d+)',text)
if args.case in ['legacy_visibility','frontier_visibility']:
    marker = re.search(r'RESULTS: (\d+) passed, (\d+) failed',text)
if args.case == 'snapshot_fanout':
    found = re.search(r'PERFORMANCE_SNAPSHOT_FANOUT checks=(\d+) failures=(\d+)',text)
    marker = [None,str(int(found[1])-int(found[2])),found[2]] if found else None
guards = dict(source_unchanged=all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in hashes.items()),
              real_profile_unchanged=before==fingerprint(real_user),private_canary=(user/'review2_isolation_canary.json').exists())
measurements = [json.loads(line.removeprefix('PERF_SAMPLE ')) for line in text.splitlines() if line.startswith('PERF_SAMPLE ')]
report = dict(case=args.case,phase=args.phase,engine=version,exit=code,errors=errors,command=command,
              passed=code==0 and not errors and marker is not None and marker[2]=='0' and all(guards.values()),
              assertions=int(marker[1]) if marker else 0, failed=int(marker[2]) if marker else None,
              measurements=measurements,source_sha256=hashes,**guards)
(out/'report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(text[-6000:])
print('REPORT',out/'report.json')
raise SystemExit(0 if report['passed'] else 1)
