# TASK_586 - Debrief Return To Homebase Handoff

## Ziel / Problem
TASK_585 macht eine kleine Mini-AAR-Debrief-Struktur lesbar. Der naechste spielbare Schritt ist der Rueckweg aus dem Debrief in den Homebase-/Meta-Loop, ohne dass alte Mission- oder UI-Zustaende still weiterhaengen.

## Sinnhaftigkeit / Ursache
Der vorhandene `MetaLayerFlow` kann bereits `Debrief -> Homebase` anzeigen. Der Pfad war aber nicht als eigener Contract pruefbar: Signalbindung, Zielscreen, MissionResult-Erhalt, aktive Mission und Navigation waren nur implizit.

## Umfang
- `MetaLayerFlow.get_debrief_return_homebase_handoff_snapshot()` als read-only Handoff-Snapshot.
- Snapshotfelder fuer aktuellen Meta-View, Ziel-View, Return-Action, Signalbindung, Debrief-/Homebase-Sichtbarkeit, MissionResult-Erhalt und aktiven Missionszustand.
- Kleiner Test-Helfer `request_debrief_return_homebase_for_test()`, der ausschliesslich den bestehenden Return-Handler nutzt.
- Automatischer Verifier fuer den Zustand vor und nach dem Return.
- Laufender HTML-Zwischenbericht wird aktualisiert und bleibt als Arbeitsbericht nutzbar.

## Nicht-Ziele
- Kein neues Debrief-Layout.
- Keine XP-/Skill-Vergabe.
- Keine Ammo- oder echte Suppression-Auswertung.
- Kein neues Missionssystem und kein Multiplayer-Session-Rewrite.
- Keine neue Gameplay-Wahrheit im Debrief oder Homebase-HUD.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_585_mini_aar_debrief_screen_stub.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Snapshot-Schema ist `sternenbuergerchen.debrief_return_homebase_handoff.v1`.
- Snapshot setzt `read_only = true` und `ui_sets_gameplay_truth = false`.
- Vor dem Return ist Debrief sichtbar, Homebase nicht sichtbar und der Return-Action-Pfad verbunden.
- Nach dem Return ist Homebase sichtbar, Debrief verborgen und die Meta-Navigation wieder sichtbar.
- Das letzte MissionResult bleibt zwischen MetaLayerFlow und Debrief erhalten.
- Die aktive Mission ist nach dem Debrief-Return nicht mehr als laufende Mission registriert.
- Der laufende HTML-Zwischenbericht nennt TASK_586 als erledigten Arbeitsstand und TASK_587 als naechsten visuellen Anschluss.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_586_debrief_return_homebase_handoff.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_586_debrief_return_homebase_handoff.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_585_mini_aar_debrief_screen_stub.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_584_mini_aar_combat_metrics_shell.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_586 macht nur den Rueckweg pruefbar. Der Debrief selbst ist weiterhin optisch und spielerisch roh.
- XP, Skillentwicklung, echte Ammo-/Suppression-Auswertung und ein schoener AAR-Screen bleiben Folgearbeit.
- Der naechste sinnvolle Schritt ist `TASK_587 - Debrief Visual Polish Pass`.
