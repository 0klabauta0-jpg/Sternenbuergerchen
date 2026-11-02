"""Local helpers for sequential, isolated A5 map-edge QA wrappers."""
from contextlib import contextmanager
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import time

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent


def new_run_dir(group):
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S_%fZ")
    folder = QA / group / stamp
    folder.mkdir(parents=True, exist_ok=False)
    return folder


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8", newline="\n")


def res_path(path):
    return "res://" + path.resolve().relative_to(ROOT).as_posix()


def error_lines(log):
    return re.findall(r"(?im)^\s*(?:SCRIPT ERROR:|Parse Error|Compile Error|ERROR:|.*ObjectDB instances leaked|.*resources still in use.*)", log)


@contextmanager
def isolated_profile(namespace, disable_editor_plugins=False):
    """Temporarily set a task-only user://; always restore project bytes."""
    project = ROOT / "project.godot"
    original = project.read_bytes()
    if b"config/use_custom_user_dir" in original or b"config/custom_user_dir_name" in original:
        raise RuntimeError("Existing custom profile: do not nest or parallelize QA wrappers.")
    marker = b"[application]\n"
    if original.count(marker) != 1:
        raise RuntimeError("Expected exactly one LF [application] section; project left unchanged.")
    isolated = original.replace(marker, marker + (f'config/use_custom_user_dir=true\nconfig/custom_user_dir_name="{namespace}"\n').encode("utf-8"), 1)
    if disable_editor_plugins:
        isolated, replacements = re.subn(rb"(\[editor_plugins\][\r\n]+)enabled=PackedStringArray\([^\r\n]*\)", rb"\1enabled=PackedStringArray()", isolated)
        if replacements != 1:
            raise RuntimeError("Expected exactly one editor_plugins section; project left unchanged.")
    facts = {
        "user_data_namespace": namespace,
        "isolated_user_data": True,
        "original_project_sha256": hashlib.sha256(original).hexdigest(),
        "test_project_sha256": hashlib.sha256(isolated).hexdigest(),
        "project_restored_byte_exact": False,
        "editor_plugins_temporarily_disabled": disable_editor_plugins,
        "gdextensions_disabled": False,
    }
    try:
        project.write_bytes(isolated)
        yield facts
    finally:
        for attempt in range(20):
            try:
                project.write_bytes(original)
                break
            except OSError:
                if attempt == 19:
                    raise
                time.sleep(0.2)
        facts["project_restored_byte_exact"] = project.read_bytes() == original
        if not facts["project_restored_byte_exact"]:
            raise RuntimeError("QA project restoration was not byte exact.")
