"""Create an immutable candidate copy cheaply from the owned baseline copy."""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import uuid

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]


def main():
    baseline = Path(sys.argv[1]).resolve()
    parent = (ROOT/'.godot/completion_snapshots').resolve()
    if not baseline.is_relative_to(parent) or not (baseline/'project.godot').is_file():
        raise RuntimeError('An existing owned source snapshot is required')
    target = parent/uuid.uuid4().hex
    target.mkdir()
    # Hardlinks point only at immutable baseline copies, never the working tree.
    for name in ['scripts', 'scenes', 'maps', 'data', 'shaders']:
        for folder, dirs, files in os.walk(baseline/name):
            dirs[:] = [d for d in dirs if d != '__pycache__']
            destination = target/Path(folder).relative_to(baseline)
            destination.mkdir(parents=True, exist_ok=True)
            for filename in files:
                os.link(Path(folder)/filename, destination/filename)
    for name in ['Assets', 'art', 'addons', 'docs', 'tests', '.godot']:
        if (ROOT/name).is_dir():
            subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive', '-Command',
                            'New-Item -ItemType Junction -Path $env:SB_LINK_TARGET -Target $env:SB_LINK_SOURCE | Out-Null'],
                           env=dict(os.environ, SB_LINK_TARGET=str(target/name), SB_LINK_SOURCE=str(ROOT/name)),
                           capture_output=True, check=True, timeout=30)
    for source in ROOT.iterdir():
        if source.is_file() and (source.name == 'project.godot' or source.suffix in {'.svg', '.tres', '.res', '.gdextension', '.import'}):
            shutil.copy2(source, target/source.name)
    spec = importlib.util.spec_from_file_location('runner', ROOT/'scripts/tests/run_review_completion_20261113.py')
    runner = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(runner)
    files = runner.source_files()
    captured = {}
    for name in files:
        data = (ROOT/name).read_bytes()
        captured[name] = hashlib.sha256(data).hexdigest()
        destination = target/name
        if not destination.is_file() or hashlib.sha256(destination.read_bytes()).hexdigest() != captured[name]:
            if not destination.resolve().is_relative_to(target):
                raise RuntimeError('Binary/shared source changed during snapshot preparation: '+name)
            destination.parent.mkdir(parents=True, exist_ok=True)
            temporary = destination.with_name(destination.name+'.snapshot-new')
            temporary.write_bytes(data)
            os.replace(temporary, destination)  # replace our hardlink, preserve baseline bytes
    matches = files == runner.source_files() and all((ROOT/p).is_file() and hashlib.sha256((ROOT/p).read_bytes()).hexdigest() == h for p,h in captured.items())
    (target/'snapshot_manifest.json').write_text(json.dumps({'baseline':str(baseline), 'matches_worktree_at_capture':matches, 'source_sha256':captured}, indent=2))
    print(json.dumps({'snapshot':str(target), 'matches_worktree_at_capture':matches, 'files':len(files)}))
    return 0 if matches else 1


if __name__ == '__main__':
    sys.exit(main())
