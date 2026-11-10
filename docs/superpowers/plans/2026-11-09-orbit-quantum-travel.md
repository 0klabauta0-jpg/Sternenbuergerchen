# Orbit Quantum Travel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Mondbasis -> Mondorbit -> abbrechbarer Quantum -> Planetenorbit -> bewusster Ortsanflug und Rueckweg.

**Architecture:** SimulationRoot routet Commands an einen langlebigen Reiseowner. Runtimeadapter verbindet Bereitschaft/Fuel/Ortsdaten mit diesem Owner; MetaLayerFlow laedt erst nach explizitem Anflug. UI liest denselben Snapshot und sendet Operations.

**Tech Stack:** Godot 4.6.2, GDScript, lokale JSON-Daten.

**Spec:** `docs/tasks/ORBIT_QUANTUM_TRAVEL_2026_11_09.md`, `docs/dev/orbit_quantum_travel_contract.md`.

## Global Constraints

- Ein Planet, ein kleiner Mond, bestehende Orte `homebase`, `satellite_crash`, `trade_outpost`.
- Quantum-Sprung zunaechst 3 Sekunden, Abbruchposition bleibt erhalten.
- Keine zweite Payload-, Fuel-, Missions- oder Gameplaywahrheit in UI.
- Keine Midflight-Saves, neuen Raumkaempfe oder Multiplayer-Reiseregeln.
- Isolierte Testprofile, headless/Hintergrund, kein Push oder EXE-Export.

## Review Focus

- Abflug ohne Ortswahl darf Onboarding oder Mission nicht vorzeitig starten.
- Abbruch unmittelbar vor Ankunft und Doppelklick duerfen nicht teleportieren/duplizieren.
- Anflugfehler muessen in einer bedienbaren Sternkarte enden, ohne Teilbuchung.
- Rueckflug/Ergebnis darf noch keinen Heimatcheckpoint erzeugen.
- Skirmish-/MP-Handoffs ausserhalb der Ortsreisen duerfen nicht umgeleitet werden.

### Task 1: Reiseowner und autoritative Commands

**Files:** Create `scripts/core/singleplayer_space_travel_state.gd`, `data/singleplayer/star_system.json`, `scripts/tests/space_travel_state_verifier.gd`; modify `scripts/core/simulation_root.gd`.

**Interfaces:** `configure() -> Dictionary`; `get_snapshot() -> Dictionary`; `apply_command(command:Dictionary, authority_context:Dictionary={}) -> Dictionary`. SimulationRoot `configure_singleplayer_owners(campaign,supply,onboarding=null,travel=null)`. Category `singleplayer_space_travel`; operations `launch_to_orbit`, `start_quantum`, `abort_quantum`, `advance`, `begin_approach`, `finish_approach`, `enter_orbit`, `land_homebase`. Lifecycle/advance require trusted `runtime_authorized`. Snapshot contains phase/craft_id/orbit_id/position/target_orbit_id/origin_position/progress/elapsed_seconds/duration_seconds/location_id/revision plus system definitions.

- [x] Write/run failing domain verifier for route, abort at midpoint, restart, foreign craft, unknown orbit, boundary and request replay.
- [x] Implement minimal owner and add fourth optional owner to SimulationRoot routing.
- [x] Run domain verifier, assert arrival at 3 seconds, no motion after abort and matching-orbit approach only.

### Task 2: Sternkartenansicht

**Files:** Create `scripts/ui/star_map_screen.gd`, optional `scripts/ui/star_map_canvas.gd`, `scripts/tests/star_map_ui_verifier.gd`; modify `scripts/meta/singleplayer_region_map_presenter.gd`.

**Interfaces:** `configure(snapshot_provider:Callable, command_handler:Callable)`; `refresh(snapshot:Dictionary={})`; `get_ui_snapshot() -> Dictionary`. Runtime operations `space_start_quantum`, `space_abort_quantum`, `space_begin_approach`, `space_land_homebase`, `space_close_map`, existing `select_destination`.

- [x] Write/run failing UI verifier for grounded/orbit/quantum/stopped, handler calls and visible load-boundary copy.
- [x] Render moon/planet/orbit/ship/route and fixed controls; throttle read-only refresh to at most 10 Hz, no tree rebuilds per tick.
- [x] Reuse view in region preview. Test selected location without approach, campaign locks and command rejection messages.

### Task 3: Reale Abflug-, Anflug- und Rueckkehrbruecke

**Files:** Modify `scripts/meta/singleplayer_runtime_adapter.gd`, `scripts/meta/meta_layer_flow.gd`, targeted homebase readiness/presentation and onboarding copy if needed; create `scripts/tests/orbit_quantum_flow_verifier.gd`.

**Interfaces:** Runtime snapshot adds `space_travel`; operation bridge delegates to SimulationRoot. `validate_space_launch(craft_id)` checks pad/pilot/payload without concrete destination. `advance_space_travel(delta)` advances owner only. `space_begin_approach` authorizes selected real location once then starts visible transition; flow instantiates only after transition. Existing mission transfer completion hands the real craft back to orbital travel before home landing.

- [x] Write/run failing real-flow verifier: launch leaves `_active_mission` null, jump abort/restart, selection leaves mission null, approach starts correct map only after transition.
- [x] Split launch readiness from destination readiness; wire star map view and late mission timer/instance. Keep original Skirmish/MP paths.
- [x] Intercept real return at map boundary; preserve mission result and craft/payload, show planet orbit, require moon arrival and landing before home state.
- [x] Test invalid/no-payload launch, locked trade, duplicate approach, fuel receipts, explicit return and completed-mission return.

### Task 4: Regression, Review und Dokumentation

**Files:** Adapt real loop drivers `scripts/tests/playtest_20261109_singleplayer_loop_smoke.gd` / `campaign_intro_loop_smoke.gd` as actual paths require; update task, implementation status and QA evidence under `docs/qa/orbit_quantum_20261109/`.

- [x] Run new verifiers, relevant existing campaign/supply/departure/checkpoint/menu and Skirmish gates with private profiles.
- [x] Run actual campaign two-sortie loop at 1x with new orbital route; verify both home checkpoints and both location scenarios.
- [x] Independent source review of all changed production files; resolve concrete findings and rerun affected checks.
- [x] `git diff --check`, inspect diff/scope and report exact tested behavior plus native visibility limits. Keep local task branch, no push/Mainintegration; separater gepruefter Kandidatenexport.
