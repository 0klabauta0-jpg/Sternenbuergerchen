# TASK_937 - Release First Exchange Followup Fix Player Polish Visual Findings

## Ziel / Problem
TASK_936 stellt den Recapture-/Review-Rahmen nach dem TASK_935-Player-Polish bereit. Noch fehlt der read-only Findings-Schnitt, der aus Manifest, Screenshotpfad und manuellem Spielerblick entscheidet, ob der erste Fire-Exchange endlich smoke-ready ist oder ob noch ein enger Final-Tuning-Slice noetig bleibt.

## Sinnhaftigkeit / Ursache
Der Recapture-Rahmen darf keine Akzeptanz behaupten. TASK_937 trennt deshalb technische Capture-Evidence, fehlenden Sichtbefund, belegte Restreibung und echte Akzeptanz fuer den First-Exchange-Playability-Smoke.

## Umfang
- TASK_936-Snapshot/Manifest als Quelle pruefen.
- Positive Evidenz erhalten:
  - CONTACT FIRE in #17/#18/#19.
  - trusted Window-Handle-Capture.
  - TASK_935-Player-Polish-Style.
  - TASK_934-Findings und TASK_933-Recapture-Basis.
- Manuellen Sichtbefund strukturiert auswerten:
  - Player-Polish-Fire-Lane als erste Weltbewegung.
  - Lane vor FIRE/CONTACT-Text und Zielcluster.
  - Source-/Target-Anker tragen Richtung ohne Scheibenwirkung.
  - Label/Halo/Grid bleiben im Hintergrund.
  - Command-Surfaces bleiben bedienbar.
- `accepted_for_first_exchange_playability_smoke` nur bei sauberem manuellen Befund setzen.
- Bei Restreibung einen engen TASK_938-Final-Tuning-Slice statt Combat-/HUD-Truth-Drift empfehlen.
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
- `docs/tasks/TASK_936_release_first_exchange_followup_fix_player_polish_recapture.md`
- `docs/tasks/TASK_935_release_first_exchange_followup_fix_player_polish.md`
- `docs/tasks/TASK_934_release_first_exchange_followup_fix_visual_findings.md`
- `docs/tasks/TASK_933_release_first_exchange_followup_fix_recapture.md`
- `docs/tasks/TASK_932_release_first_exchange_final_readability_followup_fix.md`
- `docs/reports/spielstand_zwischenbericht_task935_936_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupFixPlayerPolishVisualFindings.build_snapshot()` blockt fehlende oder falsche TASK_936-/TASK_935-/TASK_934-/TASK_933-/TASK_932-Metadaten.
- Ohne manuellen Sichtbefund bleibt der Snapshot `needs_manual_review`.
- Bei positiver manueller Sichtpruefung empfiehlt der Snapshot `TASK_938 - Release First Exchange Playability Smoke`.
- Bei Restreibung empfiehlt der Snapshot `TASK_938 - Release First Exchange Followup Fix Player Polish Final Tuning`.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_937_release_first_exchange_followup_fix_player_polish_visual_findings.md`
- `scripts/mission/release_first_exchange_followup_fix_player_polish_visual_findings.gd`
- `scripts/tests/task_937_release_first_exchange_followup_fix_player_polish_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task935_936_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_937_release_first_exchange_followup_fix_player_polish_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_936_release_first_exchange_followup_fix_player_polish_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_937 ersetzt keinen echten Playability-Smoke. Ohne akzeptierten Sichtbefund bleibt der naechste Schritt ein enger Folgepolish oder ein echter manueller Review. Erst bei Akzeptanz wird der kurze Smoke sinnvoll.

## Naechster Schritt
Bei Akzeptanz: TASK_938 - Release First Exchange Playability Smoke.

Bei Restreibung: TASK_938 - Release First Exchange Followup Fix Player Polish Final Tuning.
