# TASK_925 - Release First Exchange Followup Player Polish Visual Findings

## Ziel / Problem
TASK_924 stellt den frischen Recapture-/Review-Rahmen nach TASK_923 bereit. Noch fehlt der read-only Findings-Schnitt, der aus Manifest, Screenshotpfad und manuellem Spielerblick entscheidet, ob der erste Fire-Exchange jetzt smoke-ready ist oder ob noch ein enger Player-Polish noetig bleibt.

## Sinnhaftigkeit / Ursache
Der Recapture-Rahmen darf keine Akzeptanz behaupten. TASK_925 trennt deshalb technische Capture-Evidence, fehlenden Sichtbefund, belegte Restreibung und echte Akzeptanz fuer den First-Exchange-Playability-Smoke.

## Umfang
- TASK_924-Snapshot/Manifest als Quelle pruefen.
- Positive Evidenz erhalten:
  - CONTACT FIRE in #17/#18/#19.
  - trusted Window-Handle-Capture.
  - TASK_923-Player-Polish-Style.
  - TASK_920-Follow-up-Basis.
- Manuellen Sichtbefund strukturiert auswerten:
  - Fire-Lane als erste Weltbewegung.
  - Lane vor FIRE/CONTACT-Text und Zielcluster.
  - Source-/Target-Anker tragen Richtung.
  - Label/Halo/Grid bleiben im Hintergrund.
  - Command-Surfaces bleiben bedienbar.
- `accepted_for_first_exchange_playability_smoke` nur bei sauberem manuellen Befund setzen.
- Bei Restreibung einen engen TASK_926-Polish statt Combat-/HUD-Truth-Drift empfehlen.
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
- `docs/tasks/TASK_924_release_first_exchange_followup_player_polish_recapture.md`
- `docs/tasks/TASK_923_release_first_exchange_followup_world_read_player_polish.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupPlayerPolishVisualFindings.build_snapshot()` blockt fehlende oder falsche TASK_924-/TASK_923-/TASK_921-/TASK_922-/TASK_920-Metadaten.
- Ohne manuellen Sichtbefund bleibt der Snapshot `needs_manual_review`.
- Bei positiver manueller Sichtpruefung empfiehlt der Snapshot `TASK_926 - Release First Exchange Playability Smoke`.
- Bei Restreibung empfiehlt der Snapshot `TASK_926 - Release First Exchange Followup Player Polish Tuning`.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_925_release_first_exchange_followup_player_polish_visual_findings.md`
- `scripts/mission/release_first_exchange_followup_player_polish_visual_findings.gd`
- `scripts/tests/task_925_release_first_exchange_followup_player_polish_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_925_release_first_exchange_followup_player_polish_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_924_release_first_exchange_followup_player_polish_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_925 ersetzt keinen echten Playability-Smoke. Ohne akzeptierten Sichtbefund bleibt der naechste Schritt ein enger Polish oder ein echter manueller Review. Erst bei Akzeptanz wird der kurze Smoke sinnvoll.

## Naechster Schritt
Bei Akzeptanz: TASK_926 - Release First Exchange Playability Smoke.

Bei Restreibung: TASK_926 - Release First Exchange Followup Player Polish Tuning.
