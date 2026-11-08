"""Use the existing serial private runner, extending its frozen input set for R5."""
from __future__ import annotations

import hashlib
from pathlib import Path

import run_runtime_hitches_r4_20261107 as runner

_original_pins = runner.source_pins
EXTRA_INPUTS = (
    "scripts/mission/mission_interaction_point_binding.gd",
    "scripts/tactical/mission_runtime_index.gd",
    "scripts/tests/run_cpu_hud_r5_20261108.py",
    "scripts/tests/cpu_hud_r5_20261108_audit.gd",
    "scripts/tests/cpu_hud_r5_20261108_identity_verifier.gd",
    "scripts/tests/cpu_hud_r5_20261108_status_verifier.gd",
    "scripts/tests/cpu_hud_r5_20261108_scenario_parse_verifier.gd",
    "scripts/tests/cpu_hud_r5_20261108_regression_manifest.json",
)


def source_pins(root: Path, script: str) -> dict:
    pins = _original_pins(root, script)
    for relative in EXTRA_INPUTS:
        pins[relative] = hashlib.sha256((root / relative).read_bytes()).hexdigest()
    return pins


if __name__ == "__main__":
    runner.source_pins = source_pins
    raise SystemExit(runner.main())
