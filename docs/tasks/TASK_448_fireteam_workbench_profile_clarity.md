# TASK_448 - Fireteam Workbench Profile Clarity

## Ziel / Problem

Die Formation-Workbench soll klarer zeigen, was Command/C/N/A automatisch setzt, was nur ein Preset ist, was als manuelle Formation entsteht und was als Command-/Stance-Regel exportiert wird.

## Sinnhaftigkeit / Ursache

Beim Durchgehen der Workbench waren mehrere Begriffe unklar: `Override`, `Command darf Grundformation/Sicherung mitsetzen`, gespeicherte Formation, Sicherungsbild, FOV/Sicht und Meter/Tiles. Dadurch war nicht eindeutig, ob ein Wert schon Runtime-Wahrheit ist oder nur ein exportierter Kandidat.

## Umfang

- Sicht-% und FOV in der Workbench koppeln: breiteres FOV senkt Sichtreichweite, hoehere Sicht schmalert FOV.
- C/N/A-Profilwerte sichtbar zusammenfassen, inklusive Speed, Sicht, FOV, Deckung und kurzer Verhaltensbeschreibung.
- Sicherungsbild- und Formation-Buttons sprachlich auf `aktuelles Command + C/N/A` zuschneiden.
- Kleine Formationsbibliothek im Workbench-State ergaenzen: benannte Kandidaten speichern, laden und loeschen.
- Meter/Tiles klar trennen: Basis-Sicht ist Meter, Tile-Sicht ist Diagnose mit 1,5m pro Tile, Waffenreichweite kommt aus WeaponData-Tiles.

## Nicht-Ziele

- Keine Runtime-Aenderung.
- Keine automatische Uebernahme der Workbench-JSON in Godot-Code.
- Kein finaler Formation-/Sicherungs-Authoring-Editor im Spiel.
- Keine Aenderung an WeaponData selbst.

## Relevante Contracts / Dokumente

- `docs/dev/html_report_workbench_contract.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_445_html_report_workbench_standard.md`
- `docs/tasks/TASK_447_fireteam_contact_initiative_rules.md`
- `docs/reports/fireteam_formation_tuning_workbench.html`

## Akzeptanzkriterien

- Wenn FOV manuell erhoeht wird, sinkt Sicht-% sichtbar; wenn Sicht-% erhoeht wird, sinkt FOV sichtbar.
- Die Workbench zeigt das aktuelle Command-/C/N/A-Profil als lesbare Zusammenfassung.
- Der Text unterscheidet Preset, gespeicherten Kandidat und Command-/Stance-Regel.
- Sicherungsbild- und Formation-Speichern/Loeschen beziehen sich klar auf das aktuelle Command + C/N/A.
- Benannte Formationen koennen innerhalb der Workbench gespeichert, geladen, geloescht und als JSON exportiert/importiert werden.
- Basis-Sicht zeigt Meter und daraus berechnete Tiles; Waffenreichweite zeigt Tiles und daraus abgeleitete Design-Meter.

## Betroffene Dateien

- `docs/reports/fireteam_formation_tuning_workbench.html`
- `docs/tasks/TASK_448_fireteam_workbench_profile_clarity.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung

- HTML-Script-Syntax pruefen.
- JSON-Export/Import statisch pruefen.
- `git diff --check`

## Risiken / offene Punkte

- Die Bibliothek ist ein Workbench-Kommunikationsformat, keine Runtime-Datenbank.
- Die FOV/Sicht-Kopplung ist ein Tuningmodell und muss nach Playtests kalibriert werden.
