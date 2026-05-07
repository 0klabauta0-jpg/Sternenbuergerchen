# TASK_289 - Final Sneaky Code Review Patch Queue

## Ziel
Am Ende der Tactical-/Help-/Playability-/Review-Reihe soll eine intensive Code-Review-Runde stattfinden. Sie priorisiert echte Bugs, Architekturverletzungen, UI-Wahrheits-Rueckfaelle, ungetestete Entscheidungszweige und Doku-/Code-Drift.

Das Ergebnis ist kein allgemeines Bauchgefuehl, sondern eine konkrete Befundliste plus Patchqueue.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_283 - Post Tactical Docs Consistency Audit
- TASK_284 - Gameplay Truth Architecture Boundary Audit
- TASK_285 - Tactical Decision Branch Integrity Review
- TASK_286 - UI Feedback Truth Regression Review
- TASK_287 - Editor Save Multiplayer Contract Regression Review
- TASK_288 - Regression Gate Coverage Gap Audit

## Kontext
Nach vielen neuen Befehlen und Entscheidungslogiken ist die Gefahr gross, dass irgendwo ein kleiner Nebenpfad, ein alter Default oder ein UI-State unbemerkt falsch bleibt. Dieser Review nimmt die Haltung einer echten Code Review ein: Findings zuerst, Schweregrad, Datei/Zeile, Reproduktionspfad, Tests und Patchvorschlag.

## Umfang
1. Review-Fokus:
   - Gameplay-Wahrheit.
   - Command-/FTL-/Unit-Ebenen.
   - TacticalRules und Breakouts.
   - AirAssetStatus und Meta-Folgen.
   - UI/Help/Bubbles/Map-Snapshots.
   - Editor/Save/Load/Multiplayer.
   - Testabdeckung und Gates.
2. Befundformat:
   - Prioritaet P0/P1/P2/P3.
   - Datei und Zeile.
   - Risiko.
   - Repro/Beispiel.
   - empfohlene Korrektur.
   - Test/Gate, der danach laufen muss.
3. Patchqueue:
   - Kleine, klar geschnittene Patchtasks.
   - Keine Sammelmonster.
   - Reihenfolge nach Risiko.
4. Abschlussentscheidung:
   - "Ready for polish", "needs architecture fixes", "needs playability fixes" oder "blocked".
5. Optional:
   - Inline-Code-Review-Kommentare fuer konkrete lokale Befunde, wenn im Toolkontext sinnvoll.

## Nicht-Ziele
- Keine direkte Umsetzung aller Findings.
- Kein kompletter Refactor.
- Kein neues Feature.
- Kein kosmetischer Stilreview ohne Verhalten-/Architekturrisiko.

## Akzeptanzkriterien
- [x] Review-Report fuehrt Findings zuerst und priorisiert nach Risiko.
- [x] Jeder P0/P1-Befund hat konkrete Datei/Zeile und Patchvorschlag.
- [x] Patchqueue ist in kleine Tasks geschnitten.
- [x] Offene Doku-/Testluecken sind separat von Codebugs markiert.
- [x] Abschlussentscheidung ist klar.
- [x] `git diff --check` und relevante Gates sind als Abschlussstatus dokumentiert.

## Erwartete Dateien
- `docs/reviews/final_sneaky_code_review_patch_queue.md`
- optional Folge-Tasks fuer erste Patchqueue-Fixes
- `scripts/tests/task_289_final_sneaky_code_review_patch_queue.gd`
- `docs/tasks/TASK_289_final_sneaky_code_review_patch_queue.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_289_final_sneaky_code_review_patch_queue.gd`
- [x] Relevante Gates aus TASK_288 nach Befundlage.
- [x] `git diff --check`

## Risiken
- Review darf nicht in Stilgeschmack abrutschen. Findings brauchen Bug-, Risiko- oder Architekturbezug.
- Patchqueue darf nicht so gross werden, dass niemand weiss, womit man startet.

## Ergebnis
- `docs/reviews/final_sneaky_code_review_patch_queue.md` dokumentiert Findings zuerst, zwei P1-Diagnosefixes, kleine P2/P3-Patchqueue und die Abschlussentscheidung `Ready for polish`.
- `CommanderIntent` und `AirAssetStatus` tragen jetzt `normalization_warnings`, damit sichere Fallbacks nicht mehr still bleiben.
- `MultiplayerSnapshotContract` spiegelt diese Diagnose-IDs kompakt in CommanderIntent- und AirAssetStatus-Snapshots.
- `scripts/tests/task_289_final_sneaky_code_review_patch_queue.gd` prueft Reportform, Diagnose-Fixes, Snapshot-Kompaktheit und Patchqueue.

## Naechster Schritt
TASK_290 wird als Wochenabschluss vorbereitet. Die verbleibenden P2/P3-Punkte muessen im User-Handbuch als bekannte Einschraenkung oder manuelle Pruefung erkennbar bleiben.
