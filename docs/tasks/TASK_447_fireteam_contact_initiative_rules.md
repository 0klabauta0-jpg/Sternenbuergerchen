# TASK_447 - Fireteam Contact Initiative Rules

## Ziel / Problem

FOV, Entfernung, Sichtweite, Formation und Buddyteams sollen nicht nur sichtbar sein, sondern als nachvollziehbare Regel auf die Zeit bis zum ersten koordinierten Schuss und auf Zielhilfe wirken.

## Sinnhaftigkeit / Ursache

In den Playtests ist unklar, warum ein Fireteam bei Kontakt schnell, langsam oder gar nicht feuert. Ohne explizite Kontakt-Initiative bleibt die Verbindung zwischen Sicherungsbild, Sichtbereich, Waffenreichweite, Buddyteam-Kommunikation und erster Feuerfreigabe unsichtbar.

## Umfang

- Kontakt-Initiative als Contract-Regel mit Sekundenmodifikatoren festhalten.
- Team-Zielhilfe als separaten Bonus definieren, damit Buddyteams nicht nur schneller, sondern auch sauberer auf denselben Kontakt wirken.
- Formation-Workbench um sichtbare Kontakt-Initiative-Diagnose und JSON-Export erweitern.
- Character-Sheet-Hooks fuer spaetere Runtime-Integration benennen, ohne sie jetzt als Combat-Wahrheit einzubauen.

## Nicht-Ziele

- Keine direkte Runtime-Aenderung im Combat-Loop.
- Keine neue Trefferwahrscheinlichkeitsformel.
- Keine finale Charakterbogen-Balance.
- Kein Skill-/Trait-Rework.

## Relevante Contracts / Dokumente

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_445_html_report_workbench_standard.md`
- `docs/tasks/TASK_446_fireteam_workbench_spacing_runtime_pass.md`
- `docs/reports/fireteam_formation_tuning_workbench.html`

## Akzeptanzkriterien

- Der Behavior-Contract definiert `contact_initiative_seconds` und `team_target_support_percent`.
- FOV, Ziel ausserhalb/innerhalb des Sektors, Waffen-/Sichtdistanz, Buddyteams, lose Wolke und Command/Stance haben konkrete Startwerte.
- Buddyteams geben einen Kommunikations-/Zielhilfe-Bonus; lose Wolke hat einen Koordinationsmalus.
- Die Formation-Workbench zeigt Sekunden bis zum ersten koordinierten Schuss, Kontaktentfernung, FOV-Lage, Buddy-Effekt und Team-Zielhilfe.
- Der JSON-Export enthaelt die Kontakt-Initiative-Diagnose inklusive Modifikatoren.
- Character-Sheet-Werte sind als spaetere Hooks benannt und in den Hilfetexten sichtbar, aber noch nicht in Runtime-Code verankert.

## Betroffene Dateien

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/reports/fireteam_formation_tuning_workbench.html`
- `docs/tasks/TASK_447_fireteam_contact_initiative_rules.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/meta/character_sheet_formatter.gd`

## Lokale Pruefung

- Formation-Workbench lokal oeffnen und Kontakt-Initiative beim Verschieben/Rotieren plausibel beobachten.
- HTML-Script-Syntax pruefen.
- `git diff --check`

## Risiken / offene Punkte

- Die Formel ist ein Startwert und muss nach Playtests kalibriert werden.
- Die Workbench ist ein Diagnose- und Kommunikationswerkzeug, keine Runtime-Wahrheit.
- Die spaetere Runtime-Anbindung muss CombatFireDecisionResolver, Kontaktstatus und Character-Sheet-Werte sauber ueber bestehende Contracts integrieren.
