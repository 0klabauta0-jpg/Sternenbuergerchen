"""Real Vulkan slot readback; headless dummy values cannot prove a GPU mask."""
import subprocess

from _qa_common import ROOT, isolated_profile, new_run_dir, error_lines, write_json

run = new_run_dir("rendered_fow")
command = ["godot_console", "--path", str(ROOT), "--rendering-method", "forward_plus",
           "--rendering-driver", "vulkan", "--audio-driver", "Dummy", "--script",
           "res://scripts/tests/gm01_frontier_hex_fow_verifier.gd", "--", "--require-rendered-slots"]
with isolated_profile("SternenBuergerchen_Mission_A5_Edge_Rendered_FoW_QA") as profile:
    process = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=90)
(run / "fow.log").write_bytes(process.stdout)
log = process.stdout.decode("utf-8", errors="replace")
errors = error_lines(log)
passed = process.returncode == 0 and not errors and "GM01_HEX_FOW_RENDERED_ALL_PASS" in log
write_json(run / "process.json", {**profile, "command": command, "exit_code": process.returncode,
           "errors": errors, "passed": passed, "renderer": "vulkan", "headless": False,
           "scope": "Standalone visual-state fixture: real GPU transforms/alpha for every one of9408 slots during continual full snapshots, mode/team changes; no actors or gameplay proof."})
print(run)
assert passed, "Rendered FoW slot verification failed"
