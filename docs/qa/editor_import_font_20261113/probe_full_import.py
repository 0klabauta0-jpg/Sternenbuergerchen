"""Bounded fresh source-copy import. Does not use the checkout's .godot cache."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time
import uuid
from probe_process import run as run_process, fingerprint

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
run = OUT / "local_runs" / ("full_" + uuid.uuid4().hex)
project = run / "project"
project.mkdir(parents=True)
paths = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
base = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT).decode().strip()
real_user = Path(os.environ["APPDATA"]) / "Godot/app_userdata/Sternenbuergerchen"
real_before = fingerprint(real_user)
hashes = {}
for rel in paths:
    if not rel or not (ROOT / rel).is_file():
        continue
    source = ROOT / rel
    target = project / rel
    target.parent.mkdir(parents=True, exist_ok=True)
    content = source.read_bytes()
    hashes[rel] = hashlib.sha256(content).hexdigest()
    target.write_bytes(content)
config = project / "project.godot"
config.write_text(re.sub(r'config/name="[^"]+"', 'config/name="SB-Codex-Import-' + run.name + '"', config.read_text(encoding="utf-8")), encoding="utf-8")
profile = run / "private_profile"
profile.mkdir()
env = dict(os.environ, APPDATA=str(profile), LOCALAPPDATA=str(profile))
engine = shutil.which("godot_console.exe")
version = subprocess.check_output([engine, "--version"]).decode().strip()
assert version.startswith("4.6.2."), "Pinned Godot 4.6.2 required"
args = [engine, "--headless", "--path", str(project), "--editor", "--import", "--verbose", "--log-file", str(run / "godot.log")]
assert not (project / ".godot").exists()
(run / "sources.json").write_text(json.dumps(hashes, indent=2), encoding="utf-8")
print("FRESH_IMPORT", run, "files=", len(hashes), flush=True)
start = time.time()
with (run / "import.log").open("wb") as log:
    code = run_process(args, env=env, log=log, timeout=1200)
text = (run / "import.log").read_text(encoding="utf-8", errors="replace")
result = dict(run=str(run.relative_to(ROOT)), base=subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT).decode().strip(), args=args, exit=code, seconds=round(time.time()-start,2), fresh_cache=True, private_profile=str(profile), copied_files=len(hashes), source_unchanged=all(hashlib.sha256((ROOT / rel).read_bytes()).hexdigest()==sha for rel,sha in hashes.items()), imported_files=len(list((project / ".godot" / "imported").glob("*"))), errors=[x for x in text.splitlines() if "ERROR:" in x or "SCRIPT ERROR:" in x or "Leak" in x or "leaked" in x], tail=text.splitlines()[-30:])
result.update(base=base, real_profile_unchanged=real_before == fingerprint(real_user))
result.update(engine_version=version, timeout_seconds=1200,
              cleanup_diagnostics=[line for line in text.splitlines() if "Orphan StringName" in line or "unclaimed string names" in line],
              import_complete="loading_editor_layout" in text and "[ DONE ]" in text)
(run / "summary.json").write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
print(json.dumps(result, ensure_ascii=False), flush=True)
