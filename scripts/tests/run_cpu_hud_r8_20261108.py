"""Use the serial private runner with all prior and R8 source inputs pinned."""
from __future__ import annotations
import hashlib
from pathlib import Path
import run_cpu_hud_r7_20261108 as previous
import run_runtime_hitches_r4_20261107 as runner
EXTRA_INPUTS = (
    "scripts/tests/cpu_hud_r8_20261108_audit.gd",
    "scripts/tests/cpu_hud_r8_20261108_waypoint_verifier.gd",
    "scripts/tests/runtime_hitches_r4_20261107_command_projection_verifier.gd",
    "scripts/tests/runtime_hitches_r4_20261107_fog_los_verifier.gd",
    "scripts/terrain/terrain_tile_data.gd",
    "scripts/tests/run_cpu_hud_r8_20261108.py",
    "scripts/tests/cpu_hud_r8_20261108_regression_manifest.json",
)
def source_pins(root: Path, script: str) -> dict:
    pins = previous.source_pins(root, script)
    for relative in EXTRA_INPUTS:
        pins[relative] = hashlib.sha256((root / relative).read_bytes()).hexdigest()
    return pins
if __name__ == "__main__":
    runner.source_pins = source_pins
    raise SystemExit(runner.main())
