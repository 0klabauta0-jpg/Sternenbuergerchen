"""Bounded, private Godot regression gates for the nine Astra review fixes."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import uuid

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
CASES = {
    'menu': ('astra_menu_fixes_20261113.gd', 'ASTRA_MENU_FIXES'),
    'network': ('astra_network_fixes_20261113.gd', 'ASTRA_NETWORK_FIXES'),
    'hex_combat': ('astra_hex_combat_fixes_20261113.gd', 'ASTRA_HEX_COMBAT_FIXES'),
    'campaign': ('astra_campaign_fixes_20261113.gd', 'ASTRA_CAMPAIGN_FIXES'),
    'encounter_return': ('astra_encounter_return_fixes_20261113.gd', 'ASTRA_ENCOUNTER_RETURN_FIXES'),
    'active_continue': ('campaign_active_mission_continue_verifier.gd', 'CAMPAIGN_ACTIVE_CONTINUE'),
    'network_contract': ('task_166_multiplayer_authority_command_contract_verifier.gd', 'RESULTS'),
    'door_authority': ('task_697_door_interaction_multiplayer_authority_check.gd', 'RESULTS'),
    'leader': ('astra_leader_fixes_20261113.gd', 'ASTRA_LEADER_FIXES'),
    'connected_interactions': ('task_1093_connected_station_route_full_interaction_trace.gd', 'RESULTS'),
    'parallel_interactions': ('task_1102_parallel_fireteam_interaction_ownership_recovery.gd', 'RESULTS'),
}


def fingerprint(path):
    return {str(p.relative_to(path)): [hashlib.sha256(p.read_bytes()).hexdigest(), p.stat().st_mtime_ns]
            for p in path.rglob('*') if p.is_file()} if path.exists() else {}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--case', required=True, choices=['import', *CASES])
    parser.add_argument('--timeout', type=int, default=240)
    args = parser.parse_args()
    if not 10 <= args.timeout <= 600:
        parser.error('timeout must be between 10 and 600 seconds')
    spec = importlib.util.spec_from_file_location('isolation', ROOT/'scripts/tests/run_review2_isolated.py')
    helper = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(helper)
    run_id = uuid.uuid4().hex
    out = ROOT/'docs/qa/astra_fixes_20261113'/args.case/run_id
    out.mkdir(parents=True)
    project, app = helper.create_overlay(ROOT, run_id)
    user = Path(os.environ['APPDATA'])/'Godot/app_userdata'/app
    real_user = Path(os.environ['APPDATA'])/'Godot/app_userdata/Sternenbuergerchen'
    before = fingerprint(real_user)
    tracked = subprocess.check_output(['git', 'ls-files', '-z', 'scripts', 'scenes', 'data', 'project.godot'], cwd=ROOT).decode().split('\0')
    entries = sorted(set(p for p in tracked if p) | {str(p.relative_to(ROOT)).replace('\\', '/') for p in (ROOT/'scripts/tests').glob('astra_*_20261113.gd')})
    def source_hashes():
        return {p: hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in entries if (ROOT/p).is_file()}
    hashes = source_hashes()
    engine = shutil.which('godot_console.exe')
    version = subprocess.check_output([engine, '--version'], text=True).strip()
    assert version.startswith('4.6.2.'), version
    command = [engine, '--headless', '--path', str(project)]
    if args.case == 'import':
        command += ['--editor', '--import']
    else:
        command += ['--script', 'res://scripts/tests/' + CASES[args.case][0]]
    env = dict(os.environ, SB_REVIEW2_USER_DIR=str(user))
    if args.case == 'active_continue':
        env['POLISA_TEST_PROFILE'] = str(user)
    with (out/'output.log').open('wb') as log:
        proc = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT)
        deadline = time.monotonic() + args.timeout
        termination_reason = None
        while proc.poll() is None:
            try:
                proc.wait(timeout=min(1.0, max(0.01, deadline - time.monotonic())))
            except subprocess.TimeoutExpired:
                pass
            # Fail fast on a real engine error. This also bounds recursive error
            # storms; the full log remains evidence and the case can never pass.
            current_log = (out/'output.log').read_text(encoding='utf-8', errors='replace')
            if re.search(r'^\s*(?:SCRIPT ERROR:|ERROR:|Parse Error:|Compile Error:)', current_log, re.M):
                termination_reason = 'engine_error'
            elif time.monotonic() >= deadline:
                termination_reason = 'timeout'
            if termination_reason and proc.poll() is None:
                subprocess.run(['taskkill', '/PID', str(proc.pid), '/T', '/F'], capture_output=True)
                proc.wait(timeout=20)
        code = 124 if termination_reason == 'timeout' else proc.returncode
    text = re.sub(r'\x1b\[[0-9;]*m', '', (out/'output.log').read_text(encoding='utf-8', errors='replace'))
    errors = re.findall(r'^.*(?:SCRIPT ERROR:|ERROR:|Parse Error:|Compile Error:|ObjectDB instances leaked|resources still in use at exit).*$', text, re.M)
    guards = dict(source_unchanged=hashes == source_hashes(), real_profile_unchanged=before == fingerprint(real_user))
    if args.case == 'import':
        # Editor imports do not instantiate runtime autoloads; the application
        # name/config is isolated by create_overlay, so no runtime canary is expected.
        marker_ok = '[ DONE ]' in text and 'update_scripts_classes' in text
        assertions, failures = 0, 0
    else:
        pattern = r'RESULTS: (\d+) passed, (\d+) failed' if CASES[args.case][1] == 'RESULTS' else re.escape(CASES[args.case][1]) + r' passed=(\d+) failed=(\d+)'
        marker = re.search(pattern, text)
        assertions, failures = (int(marker[1]), int(marker[2])) if marker else (0, -1)
        marker_ok = assertions > 0 and failures == 0
        guards['private_canary'] = (user/'review2_isolation_canary.json').is_file() and 'REVIEW2_ISOLATED_USER_DATA ' in text
    report = dict(case=args.case, engine=version, exit_code=code, command=command, termination_reason=termination_reason,
                  passed=code == 0 and not errors and marker_ok and all(guards.values()),
                  assertions=assertions, failures=failures, errors=errors, guards=guards,
                  source_sha256=hashes, log_sha256=hashlib.sha256((out/'output.log').read_bytes()).hexdigest(),
                  import_kind='incremental shared resource cache' if args.case == 'import' else None)
    (out/'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    if report['passed']:
        print(f"{args.case}: PASS ({assertions} assertions, all guards intact)")
    else:
        print(text[-6000:])
        brief = {k: v for k, v in report.items() if k not in ['source_sha256', 'command', 'errors']}
        brief.update(error_count=len(errors), first_errors=errors[:4])
        print('GATE_FAILURE', json.dumps(brief))
    print('REPORT', out/'report.json')
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
