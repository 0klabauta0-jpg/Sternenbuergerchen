# TASK_934 - Release First Exchange Followup Fix Visual Findings

## Ziel / Problem
TASK_933 stellt den frischen Recapture-/Review-Rahmen nach dem TASK_932-Follow-up-Fix bereit. Noch fehlt der read-only Findings-Schnitt, der aus Manifest, Screenshotpfad und manuellem Spielerblick entscheidet, ob der erste Fire-Exchange jetzt smoke-ready ist oder ob noch ein enger Folgepolish noetig bleibt.

## Sinnhaftigkeit / Ursache
Der Recapture-Rahmen darf keine Akzeptanz behaupten. TASK_934 trennt deshalb technische Capture-Evidence, fehlenden Sichtbefund, belegte Restreibung und echte Akzeptanz fuer den First-Exchange-Playability-Smoke.

## Umfang
- TASK_933-Snapshot/Manifest als Quelle pruefen.
- Positive Evidenz erhalten:
  - CONTACT FIRE in #17/#18/#19.
  - trusted Window-Handle-Capture.
  - TASK_932-Follow-up-Fix-Style.
  - TASK_931-Findings und TASK_930-Recapture-Basis.
- Manuellen Sichtbefund strukturiert auswerten:
  - Follow-up-Fix-Fire-Lane als erste Weltbewegung.
  - Lane vor FIRE/CONTACT-Text und Zielcluster.
  - Source-/Target-Anker tragen Richtung ohne Scheibenwirkung.
  - Label/Halo/Grid bleiben im Hintergrund.
  - Command-Surfaces bleiben bedienbar.
- `accepted_for_first_exchange_playability_smoke` nur bei sauberem manuellen Befund setzen.
- Bei Restreibung einen engen TASK_935-Follow-up-Polish statt Combat-/HUD-Truth-Drift empfehlen.
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
- `docs/tasks/TASK_933_release_first_exchange_followup_fix_recapture.md`
- `docs/tasks/TASK_932_release_first_exchange_final_readability_followup_fix.md`
- `docs/tasks/TASK_931_release_first_exchange_final_readability_visual_findings.md`
- `docs/tasks/TASK_930_release_first_exchange_final_readability_recapture.md`
- `docs/reports/spielstand_zwischenbericht_task932_ausblick_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupFixVisualFindings.build_snapshot()` blockt fehlende oder falsche TASK_933-/TASK_932-/TASK_931-/TASK_930-/TASK_929-Metadaten.
- Ohne manuellen Sichtbefund bleibt der Snapshot `needs_manual_review`.
- Bei positiver manueller Sichtpruefung empfiehlt der Snapshot `TASK_935 - Release First Exchange Playability Smoke`.
- Bei Restreibung empfiehlt der Snapshot `TASK_935 - Release First Exchange Followup Fix Player Polish`.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_934_release_first_exchange_followup_fix_visual_findings.md`
- `scripts/mission/release_first_exchange_followup_fix_visual_findings.gd`
- `scripts/tests/task_934_release_first_exchange_followup_fix_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task932_ausblick_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_934_release_first_exchange_followup_fix_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_933_release_first_exchange_followup_fix_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_934 ersetzt keinen echten Playability-Smoke. Ohne akzeptierten Sichtbefund bleibt der naechste Schritt ein enger Folgepolish oder ein echter manueller Review. Erst bei Akzeptanz wird der kurze Smoke sinnvoll.

## Naechster Schritt
Bei Akzeptanz: TASK_935 - Release First Exchange Playability Smoke.

Bei Restreibung: TASK_935 - Release First Exchange Followup Fix Player Polish.
