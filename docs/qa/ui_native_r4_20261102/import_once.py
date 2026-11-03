"""Import scripts once, preserving the byte-exact project configuration."""
from pathlib import Path
import hashlib
import json
import re
import subprocess
import time

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent
project = ROOT / "project.godot"
original = project.read_bytes()
temporary, replacements = re.subn(rb"(\[editor_plugins\][\r\n]+)enabled=PackedStringArray\([^\r\n]*\)", rb"\1enabled=PackedStringArray()", original)
assert replacements == 1, "Expected exactly one editor_plugins section"
result = None
try:
    project.write_bytes(temporary)
    result = subprocess.run(["godot_console", "--headless", "--path", str(ROOT), "--editor", "--import", "--quit"], cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
    (QA / "import.log").write_bytes(result.stdout)
finally:
    for attempt in range(10):
        try:
            project.write_bytes(original)
            break
        except OSError:
            if attempt == 9:
                raise
            time.sleep(0.2)
assert project.read_bytes() == original, "Project configuration was not restored"
log = result.stdout.decode("utf-8", errors="replace") if result else ""
errors = re.findall(r"(?im)^(?:SCRIPT ERROR:|ERROR:|.*ObjectDB instances leaked|.*Resources still in use)", log)
proof = {"passed": result is not None and result.returncode == 0 and not errors,
         "exit_code": result.returncode if result else None, "error_count": len(errors),
         "editor_plugins_temporarily_disabled": True, "gdextensions_disabled": False,
         "project_restored_byte_exact": True, "project_sha256": hashlib.sha256(original).hexdigest()}
(QA / "import_result.json").write_bytes((json.dumps(proof, indent=2) + "\n").encode())
print(json.dumps(proof, indent=2))
raise SystemExit(0 if proof["passed"] else 1)
