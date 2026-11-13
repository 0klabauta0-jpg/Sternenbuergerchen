"""Bounded private Godot checks; native rendering uses a never-activated desktop."""
import argparse
import ctypes
from ctypes import wintypes
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
ERRORS = re.compile(r'^.*(?:SCRIPT ERROR:|ERROR:|Parse Error:|Compile Error:|ObjectDB instances leaked|resources still in use at exit).*$', re.M)


def fingerprint(path):
    return {str(p.relative_to(path)): [hashlib.sha256(p.read_bytes()).hexdigest(), p.stat().st_mtime_ns]
            for p in path.rglob('*') if p.is_file()} if path.exists() else {}


def source_files():
    raw = subprocess.check_output(['git', 'ls-files', '-co', '--exclude-standard', '-z',
                                   'scripts', 'scenes', 'maps', 'data', 'shaders', 'Assets', 'art', 'project.godot'], cwd=ROOT)
    paths = set(raw.decode().split('\0'))
    changed = subprocess.check_output(['git', 'diff', '--name-only', '-z', 'HEAD'], cwd=ROOT).decode().split('\0')
    text_extensions = {'.gd', '.tscn', '.tres', '.json', '.gdshader', '.py', '.ps1', '.godot', '.cfg'}
    return sorted(p for p in paths if p and (ROOT/p).is_file()
                  and (Path(p).suffix in text_extensions or p in changed))


def snapshot_sources(run_id, entries):
    """Copy mutable game code/data before a run, so agents can keep working."""
    target = ROOT/'.godot/completion_snapshots'/run_id
    target.mkdir(parents=True, exist_ok=False)
    baseline = {p: hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in entries}
    for name in ['scripts', 'scenes', 'maps', 'data', 'shaders']:
        if (ROOT/name).is_dir():
            shutil.copytree(ROOT/name, target/name, ignore=shutil.ignore_patterns('__pycache__'))
    # Binary assets are immutable during these probes; maps, catalogs, shaders,
    # model selection and visual scripts above are actual isolated copies.
    for name in ['Assets', 'art', 'addons', 'docs', 'tests', '.godot']:
        if (ROOT/name).is_dir():
            subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive', '-Command',
                            'New-Item -ItemType Junction -Path $env:SB_LINK_TARGET -Target $env:SB_LINK_SOURCE | Out-Null'],
                           env=dict(os.environ, SB_LINK_TARGET=str(target/name), SB_LINK_SOURCE=str(ROOT/name)),
                           capture_output=True, check=True, timeout=30)
    for source in ROOT.iterdir():
        if source.is_file() and (source.name == 'project.godot' or source.suffix in {'.svg', '.tres', '.res', '.gdextension', '.import'}):
            shutil.copy2(source, target/source.name)
    actual = {p: hashlib.sha256((target/p).read_bytes()).hexdigest() for p in entries}
    current = {p: hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in entries}
    if baseline != actual or baseline != current or entries != source_files():
        raise RuntimeError('Sources changed during snapshot copy; preserved snapshot is rejected. Retry after the current edit.')
    return target


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--case', required=True)
    parser.add_argument('--script')
    parser.add_argument('--marker', default=r'REVIEW_COMPLETION passed=(\d+) failed=(\d+)')
    parser.add_argument('--timeout', type=int, default=300)
    parser.add_argument('--native', action='store_true')
    parser.add_argument('--snapshot', action='store_true', help='Copy mutable sources before running; binary assets must remain unchanged.')
    parser.add_argument('--source-snapshot', help='Run a previously captured source tree; its exact source hashes are recorded.')
    parser.add_argument('--arg', action='append', default=[])
    args = parser.parse_args()
    if not re.fullmatch(r'[a-zA-Z0-9_-]+', args.case) or not 10 <= args.timeout <= 900:
        parser.error('safe case name and 10..900 second timeout required')
    if args.case != 'import':
        path = Path((args.script or '').removeprefix('res://'))
        if path.is_absolute() or '..' in path.parts or path.suffix != '.gd' or not (ROOT/path).is_file():
            parser.error('--script must name an existing project .gd resource')
    spec = importlib.util.spec_from_file_location('isolation', ROOT/'scripts/tests/run_review2_isolated.py')
    isolation = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(isolation)
    run_id = uuid.uuid4().hex
    out = ROOT/'docs/qa/review_completion_20261113'/args.case/run_id
    out.mkdir(parents=True)
    entries = source_files()
    source = snapshot_sources(run_id, entries) if args.snapshot else ROOT
    if args.source_snapshot:
        source = Path(args.source_snapshot).resolve()
        if not source.is_relative_to((ROOT/'.godot/completion_snapshots').resolve()) or not (source/'project.godot').is_file():
            raise RuntimeError('Existing snapshot must be an owned complete private source tree')
        entries = [p for p in entries if (source/p).is_file()]
    project, app = isolation.create_overlay(source, run_id)
    user = Path(os.environ['APPDATA'])/'Godot/app_userdata'/app
    real_user = Path(os.environ['APPDATA'])/'Godot/app_userdata/Sternenbuergerchen'
    before = fingerprint(real_user)
    def hashes():
        return {p: hashlib.sha256((source/p).read_bytes()).hexdigest() for p in entries if (source/p).is_file()}
    before_sources = hashes()
    engine = shutil.which('godot_console.exe')
    version = subprocess.check_output([engine, '--version'], text=True, timeout=30).strip()
    if not version.startswith('4.6.2.'):
        raise RuntimeError('Unexpected Godot version: ' + version)
    command = [engine, '--path', str(project), '--log-file', str(out/'engine.log')]
    command += ['--rendering-method', 'gl_compatibility', '--resolution', '1280x720'] if args.native else ['--headless']
    command += ['--editor', '--import'] if args.case == 'import' else ['--script', 'res://' + str(path).replace('\\', '/')]
    if args.arg:
        command += ['--', *args.arg]
    env = dict(os.environ, SB_REVIEW2_USER_DIR=str(user), POLISA_TEST_PROFILE=str(user),
               SB_REVIEW_COMPLETION_CAPTURE_DIR=str(out/'images'))
    startupinfo = None
    desktop = None
    desktop_name = None
    if args.native:
        user32 = ctypes.WinDLL('user32', use_last_error=True)
        user32.CreateDesktopW.argtypes = (wintypes.LPCWSTR, wintypes.LPCWSTR, wintypes.LPVOID, wintypes.DWORD, wintypes.DWORD, wintypes.LPVOID)
        user32.CreateDesktopW.restype = wintypes.HANDLE
        user32.CloseDesktop.argtypes = (wintypes.HANDLE,)
        desktop_name = 'CodexReview_' + run_id
        desktop = user32.CreateDesktopW(desktop_name, None, None, 0, 0x10000000, None)
        if not desktop:
            raise ctypes.WinError(ctypes.get_last_error())
        startupinfo = subprocess.STARTUPINFO()
        startupinfo.lpDesktop = desktop_name
        startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startupinfo.wShowWindow = subprocess.SW_HIDE
    proc = None
    start = time.monotonic()
    termination = None
    try:
        with (out/'output.log').open('wb') as log:
            proc = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT, startupinfo=startupinfo)
            while proc.poll() is None:
                try:
                    proc.wait(timeout=1)
                except subprocess.TimeoutExpired:
                    pass
                current = (out/'output.log').read_text(encoding='utf-8', errors='replace')
                if ERRORS.search(current):
                    termination = 'engine_error'
                elif time.monotonic()-start >= args.timeout:
                    termination = 'timeout'
                if termination and proc.poll() is None:
                    subprocess.run(['taskkill', '/PID', str(proc.pid), '/T', '/F'], capture_output=True, timeout=20)
                    proc.wait(timeout=20)
    finally:
        if proc is not None and proc.poll() is None:
            subprocess.run(['taskkill', '/PID', str(proc.pid), '/T', '/F'], capture_output=True, timeout=20)
            proc.wait(timeout=20)
        if desktop:
            user32.CloseDesktop(desktop)
    output = re.sub(r'\x1b\[[0-9;]*m', '', (out/'output.log').read_text(encoding='utf-8', errors='replace'))
    errors = ERRORS.findall(output)
    guards = dict(source_unchanged=before_sources == hashes(), real_profile_unchanged=before == fingerprint(real_user))
    assertions, failures = 0, 0
    if args.case == 'import':
        marker_ok = '[ DONE ]' in output and 'update_scripts_classes' in output
    else:
        match = re.search(args.marker, output)
        assertions, failures = (int(match[1]), int(match[2])) if match else (0, -1)
        marker_ok = assertions > 0 and failures == 0
        guards['private_canary'] = (user/'review2_isolation_canary.json').is_file() and 'REVIEW2_ISOLATED_USER_DATA ' in output
    report = dict(case=args.case, run_id=run_id, passed=proc.returncode == 0 and not termination and not errors and marker_ok and all(guards.values()),
                  exit_code=proc.returncode, termination_reason=termination, assertions=assertions, failures=failures,
                  elapsed_seconds=time.monotonic()-start, engine=version, command=command, errors=errors, guards=guards,
                  source_sha256=before_sources, source_guard_scope='textual product sources and changed tracked assets',
                  source_snapshot=str(source) if source != ROOT else None,
                  log_sha256=hashlib.sha256((out/'output.log').read_bytes()).hexdigest(),
                  private_desktop=desktop_name, desktop_activated=False, os_input_sent=False,
                  renderer='gl_compatibility' if args.native else 'headless',
                  import_kind='incremental shared resource cache' if args.case == 'import' else None,
                  user_dir=str(user), project=str(project))
    (out/'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps({k: report[k] for k in ['case', 'run_id', 'passed', 'assertions', 'failures', 'elapsed_seconds', 'errors', 'guards']}))
    print(out/'report.json')
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    sys.exit(main())
