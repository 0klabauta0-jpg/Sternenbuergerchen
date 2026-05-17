# TASK_464 - Fireteam Contact Scan Fire Feedback Readability

## Ziel / Problem
- Fireteams laufen im Engage sichtbar zwischen Gegner, ohne Feuer zu eroeffnen oder Bindungsfeuer zu zeigen.
- Security-/Defend-Facing wirkt zu statisch; die Sichtlinien sollen leicht links/rechts scannen, damit Kontakte beim Vorruecken lesbarer werden.
- Rote Enemy-Marker duerfen die eigentlichen NPC-Modelle und Waffen nicht verdecken.
- #17 Unit-Karten sollen fuer Playtests ausgeschriebene Stance-/Fire-/Aim-Infos zeigen statt nur kurzer Abkuerzungen.

## Sinnhaftigkeit / Ursache
- Combat darf nicht von UI-/Canvas-Sichtbarkeit abhaengen. Wenn ein Enemy-Node im Runtime-/Registry-Pfad aktiv ist, bleibt er ein moegliches Ziel, auch wenn 2D-/FOW-Visuals ihn lokal ausblenden.
- Das vorhandene Security-Facing mit Scan-Offset wird im 3D-View von statischen `facing_angle`/`map_facing_angle`-Metadaten ueberdeckt.
- Die Enemy-Basis ist als rote Hilfe gedacht, liegt visuell aber zu dominant auf dem Modell.
- Die Playtest-Karten brauchen lesbare Runtime-Information, damit Befehlszustand, Haltung und Waffenbereitschaft ohne Code-Suche nachvollziehbar sind.

## Umfang
- Aktive Enemy-Ziele im Combat-Loop aus Registry/Vital-State ableiten, nicht aus Canvas-Sichtbarkeit.
- Security-Scan im 3D-Facing sichtbar priorisieren und den Scan-Winkel leicht vergroessern.
- Enemy-Basis als flachere, niedrigere, transparentere Unter-Fuss-Markierung rendern.
- #17 Fireteam-Member-Karten mit ausgeschriebenen Fire-/Stance-/Aim-/Bewegungsinfos anreichern.
- Regressionstest fuer hidden Canvas Enemy, Security-Scan-Prioritaet und Kartenlesbarkeit ergaenzen.

## Nicht-Ziele
- Keine neue Enemy-KI oder Patrol-Doctrine.
- Keine neue FOV-/Raycast-Architektur.
- Keine finale UI-Neugestaltung von #17.
- Keine Balance-Aenderung an C/N/A-Werten.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_458_fireteam_contact_decision_diagnostics.md`
- `docs/tasks/TASK_459_fireteam_engage_orientation_enemy_proxy_fix.md`
- `docs/tasks/TASK_463_fireteam_auto_defend_guard_enemy_model_visibility.md`

## Akzeptanzkriterien
- Ein aktiver, registrierter Enemy kann beschossen werden, auch wenn sein CanvasItem fuer 2D/FOW unsichtbar ist.
- Security-Facing mit `security_facing_active` gewinnt im Visualpfad gegen alte statische Facing-Metadaten und sweeped sichtbar.
- Enemy-Basis wird im Snapshot als flache, niedrigere Hostile-Markierung dokumentiert und verdeckt das Modell weniger.
- #17-Karten zeigen ausgeschriebene Begriffe wie `vorsichtig`, `aggressiv`, `Feuer frei` und `Aim up`.
- Der neue Task-Verifier laeuft headless durch.

## Betroffene Dateien
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tactical/fireteam_security_controller.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_464_fireteam_contact_scan_fire_feedback_readability.gd`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_464_fireteam_contact_scan_fire_feedback_readability.gd`
- Relevante Regressionen TASK_458/TASK_459/TASK_463.
- `git diff --check`

## Risiken / offene Punkte
- Wenn danach weiter kein Feuer kommt, muss der naechste Slice die konkrete Kontakt-Diagnose im Fenster auswerten (`no_los`, `out_of_range`, `cooldown`, `attacker_not_engage_ready`).
- Enemy-Patrouillen und finales Gegnerverhalten bleiben getrennte Tasks.
