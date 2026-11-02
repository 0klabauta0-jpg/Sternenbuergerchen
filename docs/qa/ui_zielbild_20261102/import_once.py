"""One isolated import; disable editor plugins only, preserve GDExtensions."""
import argparse
import json
import subprocess

from _qa_common import ROOT, error_lines, isolated_profile, new_run_dir, write_json


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot_console")
    args = parser.parse_args()
    run = new_run_dir("import")
    command = [args.godot, "--headless", "--path", str(ROOT), "--editor", "--import", "--quit"]
    profile = {}
    try:
        with isolated_profile("SternenBuergerchen_UI_Zielbild_Import_QA", disable_editor_plugins=True) as profile:
            process = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
    except subprocess.TimeoutExpired as exc:
        (run / "import.log").write_bytes(exc.stdout or b"")
        write_json(run / "import_result.json", {**profile, "command": command, "passed": False, "timed_out": True, "exit_code": None})
        raise
    (run / "import.log").write_bytes(process.stdout)
    errors = error_lines(process.stdout.decode("utf-8", errors="replace"))
    proof = {**profile, "passed": process.returncode == 0 and not errors, "exit_code": process.returncode, "error_count": len(errors), "error_lines": errors, "command": command}
    write_json(run / "import_result.json", proof)
    print(json.dumps(proof, indent=2))
    print(f"Evidence: {run}", flush=True)
    raise SystemExit(0 if proof["passed"] else 1)


if __name__ == "__main__":
    main()
