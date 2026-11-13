"""One protected actual-Main scene case; shares only imported resources."""
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
ROOT = Path(__file__).resolve().parents[3]
CASES = {
    'multicraft': ('game_review_multicraft_20261112.gd', r'GAME_REVIEW_MULTICRAFT checks=([1-9]\d*) failed=0', 180),
    'active_continue': ('campaign_active_mission_continue_verifier.gd', r'CAMPAIGN_ACTIVE_CONTINUE passed=([1-9]\d*) failed=0', 360),
}

def fingerprint(path):
    return {str(p.relative_to(path)): [hashlib.sha256(p.read_bytes()).hexdigest(), p.stat().st_mtime_ns]
            for p in path.rglob('*') if p.is_file()} if path.exists() else {}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--case', choices=CASES, required=True)
    args = parser.parse_args()
    entry, marker, timeout = CASES[args.case]
    spec = importlib.util.spec_from_file_location('main_isolation', ROOT/'scripts/tests/run_review2_isolated.py')
    helper = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(helper)
    run_id = 'main-hex-' + uuid.uuid4().hex
    out = Path(__file__).parent / args.case / run_id
    out.mkdir(parents=True)
    real_user = Path(os.environ['APPDATA']) / 'Godot/app_userdata/Sternenbuergerchen'
    before = fingerprint(real_user)
    project, app = helper.create_overlay(ROOT, run_id)
    # The historical multicraft guard also requires its explicit APPDATA marker.
    private_appdata = out/'game_review_20261112_profiles'
    private_user = private_appdata/'Godot/app_userdata'/app
    env = dict(os.environ, APPDATA=str(private_appdata), SB_REVIEW2_USER_DIR=str(private_user))
    if args.case == 'active_continue':
        env['POLISA_TEST_PROFILE'] = str(private_user)
    sources = ['scripts/core/hex_movement_command_runtime.gd', 'scripts/core/simulation_root.gd',
               'scripts/meta/explorable_homebase.gd', 'scripts/meta/meta_layer_flow.gd',
               'scripts/ui/global_escape_menu.gd', 'scripts/ui/main_menu_screen.gd',
               'scripts/tests/mission_combat_loop_driver.gd', 'scripts/tests/'+entry]
    hashes = {p: hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}
    command = [shutil.which('godot_console.exe'), '--headless', '--path', str(project),
               '--script', 'res://scripts/tests/'+entry]
    started = time.monotonic()
    timed_out = False
    with (out/'output.log').open('w', encoding='utf-8') as stream:
        try:
            code = subprocess.run(command, env=env, stdout=stream, stderr=subprocess.STDOUT, timeout=timeout).returncode
        except subprocess.TimeoutExpired:
            code = 124
            timed_out = True
    output = helper.ANSI.sub('', (out/'output.log').read_text(encoding='utf-8', errors='replace'))
    matched = re.search(marker, output)
    errors = helper.ERROR.findall(output)
    source_ok = all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in hashes.items())
    profile_ok = before == fingerprint(real_user)
    canary = (private_user/'review2_isolation_canary.json').is_file()
    ok = code==0 and matched is not None and not errors and source_ok and profile_ok and canary
    report = dict(case=args.case, passed=bool(ok), exit_code=code, elapsed=time.monotonic()-started,
                  timed_out=timed_out, assertions=int(matched.group(1)) if matched else None,
                  errors=errors, source_unchanged=source_ok, real_profile_unchanged=profile_ok,
                  private_canary=canary, source_sha256=hashes, command=command,
                  private_user=str(private_user), shared_import_cache_only=True)
    (out/'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps({k:v for k,v in report.items() if k not in ['command','source_sha256','private_user']}, indent=2))
    print(out/'report.json')
    return 0 if ok else 1

if __name__=='__main__':
    raise SystemExit(main())
