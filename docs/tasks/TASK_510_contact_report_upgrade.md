# TASK_510 - Contact Report Upgrade

## Ziel / Problem
Gegnerwissen soll nicht mehr nur als perfekter sichtbarer Feind oder bloßer Marker erscheinen. Der Spieler braucht lesbare Kontaktmeldungen mit Typ, ungefaehrerer Position, Confidence und Alter, damit die Tactical-Decision-Preview nicht heimlich Allwissenheit suggeriert.

## Sinnhaftigkeit / Ursache
TASK_506 bis TASK_509 machen Bewegungsentscheidungen vor `GO` lesbarer. Ohne reichere Contact Reports bleiben Line-of-Fire und Threat-Preview aber zu hart: entweder Feind bekannt oder nicht. Fuer Sternenbuergerchen ist die interessantere Taktiklage ein Contact Track mit Unsicherheit.

## Umfang
- `ContactTracker` liefert read-only Contact-Report-Felder.
- Combat-Driver reicht den aktuellen Tick und einen groben Enemy-Typ in den Tracker.
- TacticalController reichert Reports mit FTL-Reportqualitaet an und erzeugt deduplizierte `contact_report`-Event-Log-Eintraege.
- 2D-/3D-Overlays unterscheiden `current`, `last_known` und `stale` sichtbar.

## Nicht-Ziele
- Kein neues Fog-of-War-System.
- Keine perfekte Gegneridentifikation.
- Kein Combat-/Detection-Rewrite.
- Kein AI-Intent-Bubble- oder Hold-Fire-Slice.

## Relevante Contracts / Dokumente
- `docs/dev/contact_report_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/tasks/TASK_506_tactical_decision_clarity_contract.md`
- `docs/tasks/TASK_508_line_of_fire_threat_analyzer_mvp.md`
- `docs/tasks/TASK_509_combined_preview_overlay.md`

## Akzeptanzkriterien
- Contact-Snapshots enthalten Typ, approximate position, Confidence, Alter und `report_text`.
- Sichtbare Gegner, Last-Known und stale Kontakte sind in UI-/Render-Snapshots unterscheidbar.
- Event-Log bekommt kurze Contact-Report-Meldungen, ohne SimulationRoot-Commands oder Effects zu enqueuen.
- Threat-Preview kann Contact-Entries weiter als read-only Gegnerkontext nutzen.

## Betroffene Dateien
- `scripts/tactical/contact_tracker.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tactical/visuals/contact_map_overlay.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_510_contact_report_upgrade.gd`
- `docs/dev/contact_report_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_510_contact_report_upgrade.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_112_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_506_tactical_decision_clarity_contract.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Enemy-Typ-Erkennung ist bewusst grob und nutzt Rolle/Spezialwaffe.
- Contact-Report-Aggregation bleibt ein MVP pro Kontakt; spaeter kann daraus eine gruppierte Meldung wie "2 Gegner, vermutlich Riflemen" entstehen.
- Manueller F6-Sichttest ist auf Wunsch uebersprungen.
