# TASK_571 - Fire Rule Controls Readability Polish

## Ziel / Problem
Die mit TASK_570 angebundene Feuerdisziplin muss im Missions-HUD sichtbar und schnell bedienbar werden. Der Spieler soll vor `GO` sehen und setzen koennen, ob ein Fireteam `hold`, `return`, `free` oder `suppress` nutzt.

## Sinnhaftigkeit / Ursache
TASK_570 hat die Fire-Rule technisch bis in `UnitCommand` und Combat-Resolver-Diagnostik getragen, aber der naechste spielbare Hebel fehlt noch im Command-Workflow. Ohne kompakte Controls bleibt Feuerdisziplin eine versteckte Regel statt einer taktischen Entscheidung.

## Umfang
- Vier kompakte Fire-Rule-Buttons im bestehenden Command-Grid.
- Buttons nutzen den vorhandenen `set_selected_fireteams_fire_rule()`-Pfad.
- Aktiver Zustand liest aus dem bestehenden Fireteam-Fire-Rule-Snapshot.
- Button-Hilfen, Marker und Command-Hierarchy-Metadaten fuer die neue Bedienung.
- Read-only Snapshot fuer Verifier und Bericht.
- HTML-Zwischenbericht aktualisiert.

## Nicht-Ziele
- Kein neues Combat-System.
- Kein Suppression-/Ammo-/Morale-Rewrite.
- Keine neue Gameplay-Wahrheit im HUD.
- Kein Umbau der Mission-Scene oder des gesamten Command-Layouts.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_command_rules_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- `HF`, `RF`, `FW` und `SUP` sind als Fire-Rule-Controls im Command-Grid vorhanden.
- Die Buttons sind ohne Fireteam-Auswahl deaktiviert und bei Auswahl bedienbar.
- Ein Button-Klick setzt die Fire-Rule ueber den bestehenden Mission-Controller-Pfad.
- Der aktive Button spiegelt die Fire-Rule der aktuellen Auswahl wider; gemischte Auswahl erzeugt keinen falschen aktiven Einzelzustand.
- Command-Hierarchy- und Help-Metadaten benennen die Controls.
- Preview/UI bleibt read-only und committed keine Movement-/Combat-Commands.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/ui/mission_command_hierarchy_contract.gd`
- `scripts/tests/task_571_fire_rule_controls_readability_polish.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `scripts/tests/task_571_fire_rule_controls_readability_polish.gd`
- Relevante Regressionen aus TASK_570
- `git diff --check`

## Risiken / offene Punkte
- Der finale FullHD-F6-Sichttest bleibt Folgearbeit, weil dieser Task die Bedienbarkeit automatisch pruefbar macht, aber nicht den menschlichen Eindruck ersetzt.
- `suppress` bleibt vorerst ein Fire-Rule-/Diagnosezustand und noch kein vollstaendiges Unterdrueckungs-/Ammo-System.
