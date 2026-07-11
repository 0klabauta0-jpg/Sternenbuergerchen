# TASK_1141 - Mission Control Decision Language and Diagnostic Hierarchy Polish

## Ziel / Problem
Mission Control zeigt nach TASK_1140 weiterhin rohe `NEXT/WHY`-, `NO FIRE`-, LOS- und Range-Diagnose. Damit widerspricht die rechte Kontrollflaeche der klaren deutschen Selected-Fireteam-Lesung.

## Ursache / Sinn
Der finale Bottom-Dock-Priorisierer schreibt die technische Combat-Evidence direkt in das sichtbare Label. Die Evidence ist fachlich richtig, braucht aber eine getrennte Spielersprache.

## Umfang
- Den bestehenden Decision-Presenter um eine kompakte Mission-Control-Zeile erweitern.
- Die sichtbare `NEXT/WHY`-Zeile im Bottom-Dock durch `NAECHSTER GRIFF` und `GRUND` ersetzen.
- Roh-Evidence in Snapshots und Tooltip erhalten.
- Contact Fire bleibt die erste sichtbare Zeile, wenn aktive Fire-Evidence vorliegt.

## Nicht-Ziele
- Keine Aenderung an Combat-, LOS-, Range-, Contact-, FireEvent- oder Multiplayer-Wahrheit.
- Kein Umbau des Mission-Control-Panels.
- Keine Aenderung an Commands, Effects, RPCs oder Snapshotfeldern.

## Akzeptanzkriterien
- Mission Control zeigt keine rohen Einzelcodes `NEXT` oder `WHY` mehr.
- Die kompakte Spielerzeile nennt Handlung und Grund in einer kurzen Kontrollzeile.
- `CONTACT FIRE` bleibt bei aktiver Evidence zuerst.
- Rohdiagnose bleibt unveraendert pruefbar.
- Bestehende Bottom-Dock-, Multiplayer- und Performance-Gates bleiben gruen oder werden nur auf den neuen sichtbaren Presenter-Vertrag aktualisiert.

## Betroffene Dateien
- `scripts/ui/selected_fireteam_decision_presenter.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1141_mission_control_decision_language_diagnostic_hierarchy_polish.gd`
- relevante sichtbare HUD-Verifier
- Status, Roadmap und HTML-Arbeitsbericht

## Lokale Pruefung
- TASK_1141-Verifier
- TASK_833 bis TASK_836
- TASK_1118/1119 oder naechster passender Perspektiv-Verifier
- TASK_222
- echter Full-HD-Capture

## Risiken / offene Punkte
Historische HUD-Verifier erwarten teils die rohe zweite Zeile. Nur deren sichtbare Presenter-Erwartung darf auf TASK_1141 aktualisiert werden; die zugrunde liegende `decision_line` bleibt absichtlich roh.
