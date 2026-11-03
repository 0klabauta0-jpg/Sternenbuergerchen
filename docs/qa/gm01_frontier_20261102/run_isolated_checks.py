"""Sequential targeted checks in a task-specific user directory."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent
project = ROOT / 'project.godot'
original = project.read_bytes()
legacy_output = ROOT/'output/grafik_20261101/pass07_runtime/headless_check.json'
legacy_bytes = legacy_output.read_bytes()
assert b'config/use_custom_user_dir' not in original
isolated = original.replace(b'[application]\n', b'[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="SternenBuergerchen_GM01_Frontier_Contracts"\n', 1)
manifest = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else QA/'checks_final.json'
runner = Path.home() / '.codex/skills/godot-game-verification/scripts/run_checks.py'


def restore_bytes(path, content):
    for attempt in range(20):
        try:
            path.write_bytes(content)
            return
        except OSError:
            if attempt == 19:
                raise
            time.sleep(0.2)


try:
    project.write_bytes(isolated)
    process = subprocess.run(['python', str(runner), '--project', str(ROOT), '--manifest', str(manifest), '--godot', 'godot_console', '--skip-import', '--output', str(QA/'checks_final')], cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=600)
finally:
    try:
        generated = legacy_output.read_bytes()
        if generated != legacy_bytes:
            (QA/'hex_runtime_slice_check.json').write_bytes(generated)
    finally:
        try:
            restore_bytes(legacy_output, legacy_bytes)
        finally:
            restore_bytes(project, original)
assert legacy_output.read_bytes() == legacy_bytes
assert project.read_bytes() == original
(QA/'checks_final_runner.log').write_bytes(process.stdout)
(QA/'checks_profile_isolation.json').write_text(json.dumps({'user_data_namespace':'SternenBuergerchen_GM01_Frontier_Contracts','isolated_user_data':True,'project_restored_byte_exact':True,'project_sha256':hashlib.sha256(original).hexdigest(),'test_project_sha256':hashlib.sha256(isolated).hexdigest(),'exit_code':process.returncode},indent=2)+'\n',encoding='utf-8')
print(process.stdout.decode('utf-8',errors='replace'))
raise SystemExit(process.returncode)
