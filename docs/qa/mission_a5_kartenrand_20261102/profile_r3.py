"""One unchanged 1920 GO/refresh leg with opt-in read-only engine timing hooks."""
import argparse
import subprocess
from _qa_common import ROOT, new_run_dir, isolated_profile, error_lines, write_json

parser = argparse.ArgumentParser()
parser.add_argument('--readout-only', action='store_true')
args = parser.parse_args()
run = new_run_dir('diagnostic_r3')
command = ['godot_console', '--headless', '--path', str(ROOT), '--script', 'res://scripts/tests/ui_native_r3_mission_readout_verifier.gd', '--', '--a5-r3-readout-only' if args.readout_only else '--a5-r3-profile']
with isolated_profile('SternenBuergerchen_Mission_A5_Edge_Profile_QA') as profile:
    result = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=100)
(run / 'profile.log').write_bytes(result.stdout)
errors = error_lines(result.stdout.decode('utf-8', errors='replace'))
write_json(run / 'process.json', {**profile, 'command': command, 'exit_code': result.returncode, 'errors': errors, 'scope': 'Read-only primary label diagnosis at both sizes' if args.readout_only else 'Single headless GO/refresh leg with timing hooks; not the two-resolution R3 gate or native FPS evidence.'})
print(run)
assert result.returncode == 0 and not errors
