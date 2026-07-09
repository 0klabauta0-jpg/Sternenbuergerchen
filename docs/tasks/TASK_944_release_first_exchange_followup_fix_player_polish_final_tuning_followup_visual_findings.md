# TASK_944 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Visual Findings

## Ziel / Problem
TASK_943 stellt den Recapture-/Review-Rahmen nach dem TASK_942-Followup-Fix bereit. Noch fehlt der read-only Findings-Schnitt, der aus TASK_943-Manifest, Screenshotpfad und manuellem Spielerblick entscheidet, ob der erste Fire-Exchange endlich smoke-ready ist oder ob noch ein enger Folgefix noetig bleibt.

## Sinnhaftigkeit / Ursache
Der Recapture-Rahmen darf keine Akzeptanz behaupten. TASK_944 trennt technische Capture-Evidence, fehlenden Sichtbefund, belegte Restreibung und echte Akzeptanz fuer den First-Exchange-Playability-Smoke. Damit bleibt der Smoke ein bewusstes Gate statt ein stiller Seiteneffekt eines Presentation-Fixes.

## Umfang
- TASK_943-Snapshot/Manifest als Quelle pruefen.
- Positive Evidenz erhalten:
  - CONTACT FIRE in #17/#18/#19.
  - trusted Window-Handle-Capture.
  - TASK_942-Followup-Fix-Style.
  - TASK_941-Gate, TASK_940-Findings und TASK_938-Final-Tuning-Basis.
- Manuellen Sichtbefund strukturiert auswerten:
  - Followup-Fire-Lane als erste Weltbewegung.
  - Lane vor FIRE/CONTACT-Text und Zielcluster.
  - Source-/Target-Anker tragen Richtung ohne Scheibenwirkung.
  - Label/Halo/Grid bleiben im Hintergrund.
  - Command-Surfaces bleiben bedienbar.
- `accepted_for_first_exchange_playability_smoke` nur bei sauberem manuellen Befund setzen.
- Bei Restreibung einen engen TASK_945-Folgefix statt Combat-/HUD-Truth-Drift empfehlen.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein neuer Capture.
- Kein Visual-Polish.
- Kein Smoke-Run.
- Keine neuen FireEvents, DamageEvents, Commands oder Movement-Entscheidungen.
- Keine neue UI-, Contact-, Mission- oder Multiplayer-Wahrheit.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_943_release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.md`
- `docs/tasks/TASK_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.md`
- `docs/tasks/TASK_941_release_first_exchange_final_tuning_playability_smoke_gate.md`
- `docs/tasks/TASK_940_release_first_exchange_followup_fix_player_polish_final_tuning_visual_findings.md`
- `docs/tasks/TASK_939_release_first_exchange_followup_fix_player_polish_final_tuning_recapture.md`
- `docs/tasks/TASK_938_release_first_exchange_followup_fix_player_polish_final_tuning.md`
- `docs/reports/spielstand_zwischenbericht_task943_944_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupFixPlayerPolishFinalTuningFollowupVisualFindings.build_snapshot()` blockt fehlende oder falsche TASK_943-/TASK_942-/TASK_941-/TASK_940-/TASK_939-/TASK_938-Metadaten.
- Ohne manuellen Sichtbefund bleibt der Snapshot `needs_manual_review`.
- Bei positiver manueller Sichtpruefung empfiehlt der Snapshot `TASK_945 - Release First Exchange Playability Smoke`.
- Bei Restreibung empfiehlt der Snapshot `TASK_945 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Fix`.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_944_release_first_exchange_followup_fix_player_polish_final_tuning_followup_visual_findings.md`
- `scripts/mission/release_first_exchange_followup_fix_player_polish_final_tuning_followup_visual_findings.gd`
- `scripts/tests/task_944_release_first_exchange_followup_fix_player_polish_final_tuning_followup_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task943_944_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_944_release_first_exchange_followup_fix_player_polish_final_tuning_followup_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_943_release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_944 ersetzt keinen echten Playability-Smoke. Ohne akzeptierten Sichtbefund bleibt der naechste Schritt ein enger Folgepolish oder ein echter manueller Review. Bei Akzeptanz sollte der naechste Slice wirklich ein kurzer Spielbarkeits-Smoke werden, nicht noch eine weitere Mikropolish-Schleife.

## Naechster Schritt
Bei Akzeptanz: TASK_945 - Release First Exchange Playability Smoke.

Bei Restreibung: TASK_945 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Fix.
