# TASK_1134 - Selected Fireteam Stance Control Consistency

## Ziel / Problem
Der grosse `#17 Selected Fireteam`-Bereich verwendet fuer dieselben taktischen Haltungen noch einen eigenen, technisch gepraegten `C / N / A`-Vertrag. Die Fireteam-Mini-Cards zeigen seit TASK_1133 dagegen `VORS / NORM / OFF` mit Icons, Wirkungstooltips und eindeutigem Auswahlzustand.

## Ursache / Sinnhaftigkeit
Beide Oberflaechen schreiben bereits ueber denselben bestehenden Tactical-Stance-Pfad. Darstellung und spaetere Refresh-Logik wurden jedoch getrennt aufgebaut. Dadurch benennt dieselbe Entscheidung je nach Blickrichtung anders und der grosse Bereich kann die lesbare Darstellung wieder ueberschreiben.

## Umfang
- Der grosse Stance-Bereich nutzt dieselben lesbaren Segmentlabels, Icons und Wirkungstooltips wie die Mini-Cards.
- Der aktive gemeinsame Zustand ist klar markiert.
- Bei gemischter Mehrfachauswahl ist kein einzelnes Segment als gemeinsam aktiv markiert.
- Zusammenfassung und Bedienhilfe verwenden Spielsprache statt Diagnosekuerzel.
- Bestehende Buttonnamen, Help-IDs und Callbacks bleiben kompatibel.

## Nicht-Ziele
- Keine Aenderung an Stance-Werten, Movement- oder Combat-Doctrine.
- Keine Aenderung an SimulationRoot, Commands, RPCs, Snapshots oder Multiplayer-Autoritaet.
- Keine Reconciliation der veralteten TASK_421-/TASK_425-Erwartungen; das bleibt ein eigener Folgetask.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1133_fireteam_mini_card_stance_control_readability.md`
- `docs/tasks/TASK_109_tactical_stance.md`
- `docs/tasks/TASK_429_fireteam_behavior_modes_runtime.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Beide Stance-Oberflaechen zeigen `VORS / NORM / OFF` in derselben Reihenfolge.
- Alle drei Segmente besitzen dasselbe Icon und denselben Wirkungstooltip wie ihre Mini-Card-Gegenstuecke.
- Genau eine gemeinsame Haltung ist bei homogener Auswahl sichtbar aktiv; bei gemischter Auswahl keine.
- Ein Klick im grossen Bereich nutzt weiterhin `set_selected_fireteams_tactical_stance()` und bleibt auf den gewaehlten Fireteam-Satz begrenzt.
- Die Steuerung bleibt im Full-HD-Selected-Fireteam-Panel ohne Ueberlauf lesbar.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1134_selected_fireteam_stance_control_consistency.gd`
- Status-, Roadmap- und HTML-Arbeitsbericht

## Lokale Pruefung
- TASK_1134 Runtime-Verifier mit RED/GREEN-Nachweis
- TASK_1133, TASK_109 und TASK_429
- TASK_180 und TASK_1128 Full-HD
- TASK_503, TASK_773 und TASK_222
- `git diff --check`

## Risiken / offene Punkte
Der grosse Bereich ist breiter als die Mini-Card, liegt aber in einem dichten unteren HUD-Dock. Feste Segmenthoehe, kurze Beschriftung und vorhandene Icons duerfen den restlichen Fireteam-Inhalt nicht verdraengen.

TASK_1136 erweitert die damalige `HALTUNG NORMAL`-Zusammenfassung um die kompakte, sichtgepruefte Wirkungszeile. Auswahl-, Icon-, Tooltip- und Callback-Vertrag dieses Tasks bleiben unveraendert.
