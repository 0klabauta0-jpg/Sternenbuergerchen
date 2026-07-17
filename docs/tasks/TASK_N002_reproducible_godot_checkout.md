# TASK_N002 — Reproducible Godot Checkout

## Goal / problem

Make a clean checkout import and start in Godot 4.6.2 without UID, autoload, parse, or export-configuration failures.

## Cause / value

The isolated `TASK_1179` rerun stopped before final assertions in conditions involving UID/autoload and an already-instanced runtime. Product evidence is not trustworthy until a clean tracked checkout can reproduce the project entry and clearly separate setup faults from runtime defects.

## Scope

- Remove `*.uid` from `.gitignore`; track required Godot UID sidecars.
- Add `/builds/`, ignore `export_credentials.cfg`, and retain `.godot/` ignore behavior.
- Add a sanitized tracked Windows `export_presets.cfg` with selected project resources and no secrets or personal absolute paths.
- Add a fresh-checkout verifier that copies or clones tracked files to an external temporary directory, imports headlessly, checks parse/autoload output, starts minimally, and validates export configuration.

## Non-goals

- Do not conceal a distinct runtime failure by weakening the verifier.
- Do not change mission logic, move product entry paths, add credentials, or claim that `TASK_1180` is integrated.

## Relevant contracts / documents

- `docs/CURRENT_GAME_STATE.md` and `docs/qa/CURRENT_EVIDENCE.md` created by `TASK_N001`
- `project.godot`, `.gitignore`, and existing export/resource configuration
- `docs/tasks/TASK_1179_ground_mission_objective_playthrough.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`

## Acceptance criteria

- A configuration contract test fails before the tracked config/UID changes and passes after.
- A fresh external checkout reports no UID, autoload, or parse failures and its minimal headless start exits successfully.
- The export configuration is sanitized and reproducibly valid.
- `TASK_1179` runs twice after fresh import to its true outcome/debrief gate; if it exposes a distinct defect, evidence records the command, artifact, and caveat rather than overstating success.

## Affected areas

Git ignore/export configuration, generated UID sidecars, focused fresh-checkout verifier, and current evidence documentation. No command-authority or scene-architecture refactor.

## Verification

Capture the red configuration test; run the verifier in a newly created external temporary directory; headlessly import and start; run `TASK_1179` twice; record exact evidence; run `git diff --check`.

## Risks / open points

Generated sidecars may expose missing resource references. The end-to-end trace is intentionally expensive; a setup pass does not excuse a later runtime failure.

## Dependency / exit gate

Requires the N001 evidence vocabulary and baseline. `TASK_N003` may start only when clean-checkout results and the `TASK_1179` outcome are recorded honestly on the committed checkout.
