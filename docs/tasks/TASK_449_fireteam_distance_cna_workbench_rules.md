# TASK_449 - Fireteam Distance CNA Workbench Rules

## Ziel / Problem

Distanz-Mali und Distanz-Boni sollen fuer C/N/A einmal zentral definiert werden und dann fuer Move, Engage, Take und Defend identisch gelten.

## Sinnhaftigkeit / Ursache

Wenn Distanzwerte pro Command unterschiedlich versteckt sind, wird die Fireteam-Matrix schwer lesbar. Ein gemeinsames Distanz-C/N/A-Profil macht klar: Die Haltung bestimmt, wie Distanz bewertet wird; der Command bestimmt die Absicht.

## Umfang

- Gemeinsames Distanz-C/N/A-Profil im Behavior-Contract dokumentieren.
- Formation-Workbench um einen aufklappbaren Distanz-C/N/A-Editor erweitern.
- Kontakt-Initiative in der Workbench aus dem gemeinsamen Distanzprofil lesen.
- Distanzprofil im JSON-Export mitspeichern.

## Nicht-Ziele

- Keine Runtime-Aenderung.
- Keine finale Hit-Chance- oder Ballistikformel.
- Keine Command-spezifischen Distanz-Sonderregeln.

## Relevante Contracts / Dokumente

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_447_fireteam_contact_initiative_rules.md`
- `docs/tasks/TASK_448_fireteam_workbench_profile_clarity.md`
- `docs/reports/fireteam_formation_tuning_workbench.html`

## Akzeptanzkriterien

- Die Workbench zeigt einen aufklappbaren Editor fuer Distanz-C/N/A.
- C/N/A-Distanzprofile werden nicht pro Command gespeichert, sondern gemeinsam fuer alle Commands.
- Die Kontakt-Initiative nutzt die aktiven Distanzwerte der aktuellen Haltung.
- JSON-Export enthaelt `distance_profile_by_stance`.
- Der Contract sagt explizit, dass Move, Engage, Take und Defend dieselben Distanz-Mali/-Boni je C/N/A verwenden.

## Betroffene Dateien

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/reports/fireteam_formation_tuning_workbench.html`
- `docs/tasks/TASK_449_fireteam_distance_cna_workbench_rules.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung

- HTML-Script-Syntax pruefen.
- JSON-Export statisch pruefen.
- `git diff --check`

## Risiken / offene Punkte

- Das Distanzprofil ist ein Workbench-/Contract-Startwert und noch keine Runtime-Wahrheit.
- Die Werte muessen im Playtest kalibriert werden, bevor sie in den Combat-Resolver wandern.
