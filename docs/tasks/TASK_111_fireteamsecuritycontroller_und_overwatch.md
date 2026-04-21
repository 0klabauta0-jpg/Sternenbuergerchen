# TASK_111 - FireteamSecurityController und Overwatch

## Ziel
Ein `FireteamSecurityController` verteilt Sicherungssektoren fuer haltende Fireteams, und ein `OverwatchController` loest vorbereitete Reaktionsschuesse auf Bewegung aus. Beide Systeme arbeiten auf Fireteam-Ebene und greifen auf bestehende Sicht-, Terrain- und Kampfsysteme zurueck, ohne deren Struktur zu ersetzen.

## Status: OFFEN

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_101_fireteambehaviorresolver_und_standardverhalten.md](docs/tasks/TASK_101_fireteambehaviorresolver_und_standardverhalten.md)
- Lies [docs/tasks/TASK_103_suppression_interruption_und_return_to_plan.md](docs/tasks/TASK_103_suppression_interruption_und_return_to_plan.md)
- Pruefe den Git-Status

## Aufgabe

### 1. `FireteamSecurityController`
- Aktiv bei `defend`, `hold_position`, `take` und am Ende einer Befehlskette, solange keine aktive Bewegung laeuft.
- Unterstuetze die Sicherungsmodi:
  - `360`
  - `directional`
- Die Moduswahl folgt weiter aus `leadership`, Traits und Kontaktlage.

### 2. Sektorverteilung
- Bei `360` werden fit Members auf gleich breite Sektoren verteilt.
- Bei `directional` richten sich alle Members auf die letzte bekannte Hauptbedrohung aus.
- Feindkontakt in ungesichertem Sektor loest einen leadership-abhaengigen Sektorwechsel aus.

### 3. `OverwatchController`
- Overwatch wird aktiv bei haltenden Fireteams und am Ende einer Befehlskette.
- Ein fit Member feuert sofort, wenn sich ein Feind in Sichtbereich und Reichweite bewegt.
- Overwatch ist getrennt von `fire_at_will` und gibt einen kleinen Accuracy-Bonus.

### 4. Unterbrechungen
- Overwatch endet bei:
  - neuem Bewegungsbefehl
  - Suppression
  - Ad-hoc-`disengage`
  - Ad-hoc-`fall_back`
- Sicherungssektoren muessen sich entsprechend neu aufbauen koennen.

### 5. Darstellung
- Sicherungsrichtung und Overwatch-Bereitschaft muessen in der taktischen Ansicht lesbar sein.
- Bestehende Planlinien werden nicht ersetzt, sondern nur um den Sicherheits-/Bereitschaftszustand ergaenzt.

## Nicht-Ziele
- keine komplette Waffen- oder Ballistik-Neuarchitektur
- keine persistenten Sector-Layouts im Meta-Layer
- keine Gegner-Patrouillen

## Akzeptanzkriterien
- Haltende Fireteams nutzen entweder `360` oder `directional` nachvollziehbar.
- Feinde, die sich in beobachtete Sektoren hineinbewegen, koennen Overwatch ausloesen.
- Overwatch wird bei Bewegung, Suppression oder Rueckzugs-Ad-hoc korrekt deaktiviert.
- Die taktische Ansicht macht Sicherungsmodus und Overwatch-Zustand sichtbar.
