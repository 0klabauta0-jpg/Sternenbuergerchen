"""Post-capture input-only fix: real Vulkan GUI fixture, separate from normal route."""
import hashlib
import subprocess

from _qa_common import ROOT, isolated_profile, new_run_dir, error_lines, write_json

run = new_run_dir("rendered_groups")
names = ["scripts/tests/mission_tactical_sandbox_controller.gd",
         "scripts/ui/mission_a5_dropship_presenter.gd",
         "scripts/tests/ui_a5_reference_groups_verifier.gd"]
sources = {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest() for name in names}
command = ["godot_console", "--path", str(ROOT), "--rendering-method", "forward_plus",
           "--rendering-driver", "vulkan", "--audio-driver", "Dummy", "--script",
           "res://scripts/tests/ui_a5_reference_groups_verifier.gd", "--", "--require-rendered-ui"]
with isolated_profile("SternenBuergerchen_Mission_A5_Edge_Rendered_Groups_QA") as profile:
    process = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=100)
(run / "groups.log").write_bytes(process.stdout)
log = process.stdout.decode("utf-8", errors="replace")
errors = error_lines(log)
unchanged = all(hashlib.sha256((ROOT / name).read_bytes()).hexdigest() == value for name, value in sources.items())
passed = process.returncode == 0 and not errors and unchanged and "A5_REFERENCE_GROUPS_RENDERED_ALL_PASS" in log
write_json(run / "process.json", {**profile, "command": command, "exit_code": process.returncode,
           "errors": errors, "passed": passed, "renderer": "vulkan", "headless": False,
           "source_sha256": sources, "sources_unchanged": unchanged,
           "scope": "Native GUI fixtures: card/details geometry, real callbacks, focus, scroll, tooltip hit filters. Public UI hydration is separate from normal-start actor/transport evidence; no OS pointer-hover proof."})
print(run)
assert passed, "Rendered UI group verification failed"
