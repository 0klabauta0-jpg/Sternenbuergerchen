"""Reproduce adjacent failures from immutable original Main without changing WIP."""
from pathlib import Path
import io
import json
import os
import subprocess
import sys
import tarfile
import uuid

SOURCE = Path(__file__).resolve().parents[2]
BASE = "668423dcf5b76a7b7bb1010ae59337376911522e"
OUT = SOURCE / "output/review7_fixes_20261103"
baseline = SOURCE / ".godot" / ("review7_original_main_" + uuid.uuid4().hex)
baseline.mkdir()
archive = subprocess.check_output(["git", "archive", "--format=tar", BASE, "scripts", "project.godot"], cwd=SOURCE)
with tarfile.open(fileobj=io.BytesIO(archive)) as bundle:
    bundle.extractall(baseline, filter="data")
links = [{"source": str(SOURCE / name), "destination": str(baseline / name)}
         for name in ("addons", "Assets", "art", "data", "docs", "maps", "scenes", "shaders", "tests", ".godot")
         if (SOURCE / name).is_dir()]
spec = baseline / "links.json"
spec.write_text(json.dumps(links))
setup = baseline / "create_links.ps1"
setup.write_text('$ErrorActionPreference="Stop"\n'
                 '$links=Get-Content -LiteralPath $env:SB_REVIEW7_BASELINE_LINKS -Raw | ConvertFrom-Json\n'
                 'foreach($link in $links){New-Item -ItemType Junction -Path $link.destination -Target $link.source | Out-Null}\n')
subprocess.run(["powershell.exe", "-NoProfile", "-NonInteractive", "-File", str(setup)],
               env=dict(os.environ, SB_REVIEW7_BASELINE_LINKS=str(spec)), check=True, capture_output=True)
manifest = {"version": 1, "checks": [
    {"name": name, "script": "res://scripts/tests/" + name + ".gd", "success_marker": "=== RESULTS:", "timeout": 90}
    for name in ("task_1122_connected_mission_world_camera_exposure_contact_cluster_readability",
                 "bugfix_multiplayer_lobby_setup_and_asset_catalog_followup")]}
(OUT / "original_main_checks.json").write_text(json.dumps(manifest, indent=2))
(OUT / "original_main_context.json").write_text(json.dumps({"base": BASE, "baseline_source": str(baseline),
    "scope": "All tracked scripts and project.godot extracted from git archive; resource trees shared read-only by convention; working source never replaced."}, indent=2))
sys.exit(subprocess.run([sys.executable, str(SOURCE / "scripts/tests/run_review2_isolated.py"),
    "--project", str(baseline), "--manifest", str(OUT / "original_main_checks.json"),
    "--baseline", str(OUT / "roster_baseline.json"), "--output", str(OUT / "original_main_adjacent")], cwd=SOURCE).returncode)
