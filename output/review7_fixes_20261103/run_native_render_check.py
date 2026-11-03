"""Targeted real-renderer check using the unchanged isolated overlay and guard."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import sys
import uuid
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "scripts/tests"))
from run_review2_isolated import create_overlay, check_roster, ERROR, ANSI

baseline = json.loads((OUT / "roster_baseline.json").read_text())
before = check_roster(baseline)
token = uuid.uuid4().hex
project, app_name = create_overlay(ROOT, token)
user_root = Path(os.environ["APPDATA"]) / "Godot/app_userdata" / app_name
assert not user_root.exists()
output = OUT / "native_render" / (datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + token[:8])
output.mkdir(parents=True)
script = "scripts/tests/review7_fow_moving_view_verifier.gd"
log = output / "review7_native_fow_moving_view.log"
argv = ["godot_console.exe", "--path", str(project), "--script", str(project / script)]
env = dict(os.environ, SB_REVIEW2_USER_DIR=str(user_root), SB_REVIEW7_REQUIRE_GPU_READBACK="1")
timeout = False
exit_code = -1
try:
    with log.open("w", encoding="utf-8") as stream:
        try:
            exit_code = subprocess.run(argv, env=env, stdout=stream, stderr=subprocess.STDOUT,
                                       timeout=180, check=False).returncode
        except subprocess.TimeoutExpired:
            timeout = True
finally:
    after = check_roster(baseline)
text = ANSI.sub("", log.read_text(encoding="utf-8", errors="replace"))
errors = ERROR.findall(text)
isolated = "REVIEW2_ISOLATED_USER_DATA " in text and (user_root / "review2_isolation_canary.json").is_file()
marker = "REVIEW7_FOW_MOVING_VIEW_RESULT" in text
gpu = '"color_roundtrip_matches":true' in text and '"transform_roundtrip_matches":true' in text
passed = exit_code == 0 and not timeout and not errors and isolated and marker and gpu
captures = []
for capture in sorted((user_root / "review7_rendered").glob("*.png")):
    shutil.copy2(capture, output / capture.name)
    captures.append(capture.name)
case = {"name": "review7_native_fow_moving_view", "passed": passed, "exit_code": exit_code,
    "timed_out": timeout, "error_count": len(errors), "errors": errors[:20], "marker_found": marker,
    "isolation_verified": isolated, "user_dir": str(user_root), "project": str(project),
    "roster_before": before, "roster_after": after, "log": str(log), "argv": argv,
    "gpu_buffer_readback_verified": gpu, "captures": captures}
report = {"schema": "sternenbuergerchen.review7_native_render.v1", "checks": [case],
    "summary": {"selected": 1, "passed": int(passed), "failed": int(not passed)},
    "protected_roster": after, "all_user_dirs_unique": True,
    "scope": "Real renderer and MultiMesh buffers; targeted fixed fixture, no FPS or whole-game acceptance."}
(output / "report.json").write_text(json.dumps(report, indent=2))
print(json.dumps({"passed": passed, "exit_code": exit_code, "gpu_readback": gpu, "errors": errors,
                  "captures": captures, "report": str(output / "report.json")}))
sys.exit(0 if passed else 1)
