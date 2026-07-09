# TASK_940 - Release First Exchange Followup Fix Player Polish Final Tuning Visual Findings

## Ziel / Problem
TASK_939 stellt den Recapture-/Review-Rahmen nach dem TASK_938-Final-Tuning bereit. Noch fehlt der read-only Findings-Schnitt, der aus TASK_939-Manifest, Screenshotpfad und manuellem Spielerblick entscheidet, ob der erste Fire-Exchange endlich smoke-ready ist oder ob noch ein enger Folgefix noetig bleibt.

## Sinnhaftigkeit / Ursache
Der Recapture-Rahmen darf keine Akzeptanz behaupten. TASK_940 trennt technische Capture-Evidence, fehlenden Sichtbefund, belegte Restreibung und echte Akzeptanz fuer den First-Exchange-Playability-Smoke.

## Umfang
- TASK_939-Snapshot/Manifest als Quelle pruefen.
- Positive Evidenz erhalten:
  - CONTACT FIRE in #17/#18/#19.
  - trusted Window-Handle-Capture.
  - TASK_938-Final-Tuning-Style.
  - TASK_937-Findings und TASK_935-Player-Polish-Basis.
- Manuellen Sichtbefund strukturiert auswerten:
  - Final-Tuning-Fire-Lane als erste Weltbewegung.
  - Lane vor FIRE/CONTACT-Text und Zielcluster.
  - Source-/Target-Anker tragen Richtung ohne Scheibenwirkung.
  - Label/Halo/Grid bleiben im Hintergrund.
  - Command-Surfaces bleiben bedienbar.
- `accepted_for_first_exchange_playability_smoke` nur bei sauberem manuellen Befund setzen.
- Bei Restreibung einen engen TASK_941-Folgefix statt Combat-/HUD-Truth-Drift empfehlen.
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
- `docs/tasks/TASK_939_release_first_exchange_followup_fix_player_polish_final_tuning_recapture.md`
- `docs/tasks/TASK_938_release_first_exchange_followup_fix_player_polish_final_tuning.md`
- `docs/tasks/TASK_937_release_first_exchange_followup_fix_player_polish_visual_findings.md`
- `docs/tasks/TASK_936_release_first_exchange_followup_fix_player_polish_recapture.md`
- `docs/tasks/TASK_935_release_first_exchange_followup_fix_player_polish.md`
- `docs/reports/spielstand_zwischenbericht_task939_ausblick_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupFixPlayerPolishFinalTuningVisualFindings.build_snapshot()` blockt fehlende oder falsche TASK_939-/TASK_938-/TASK_937-/TASK_936-/TASK_935-Metadaten.
- Ohne manuellen Sichtbefund bleibt der Snapshot `needs_manual_review`.
- Bei positiver manueller Sichtpruefung empfiehlt der Snapshot `TASK_941 - Release First Exchange Playability Smoke`.
- Bei Restreibung empfiehlt der Snapshot `TASK_941 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Fix`.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_940_release_first_exchange_followup_fix_player_polish_final_tuning_visual_findings.md`
- `scripts/mission/release_first_exchange_followup_fix_player_polish_final_tuning_visual_findings.gd`
- `scripts/tests/task_940_release_first_exchange_followup_fix_player_polish_final_tuning_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task939_ausblick_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_940_release_first_exchange_followup_fix_player_polish_final_tuning_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_939_release_first_exchange_followup_fix_player_polish_final_tuning_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_938_release_first_exchange_followup_fix_player_polish_final_tuning.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_940 ersetzt keinen echten Playability-Smoke. Ohne akzeptierten Sichtbefund bleibt der naechste Schritt ein enger Folgepolish oder ein echter manueller Review. Erst bei Akzeptanz wird der kurze Smoke sinnvoll.

## Naechster Schritt
Bei Akzeptanz: TASK_941 - Release First Exchange Playability Smoke.

Bei Restreibung: TASK_941 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Fix.
