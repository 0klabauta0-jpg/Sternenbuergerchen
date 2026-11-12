"""Run recruitment probes and reject Godot runtime errors even on exit code 0."""
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
godot = shutil.which("godot_console.exe") or shutil.which("godot")
if not godot:
    raise SystemExit("Godot executable not found")
for name in ("polisa_recruit_offer_verifier.gd", "polisa_recruit_view_verifier.gd"):
    result = subprocess.run([godot, "--headless", "--path", str(ROOT), "--script", f"scripts/tests/{name}"], capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=120)
    output = result.stdout + result.stderr
    if result.returncode or "SCRIPT ERROR:" in output or "ERROR:" in output or "PASS:" not in output:
        print(output)
        raise SystemExit(f"FAIL: {name}")
    print(f"PASS: {name}, no Godot errors")
