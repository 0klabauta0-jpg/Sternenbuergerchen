# TASK_101 – FireteamBehaviorResolver, geplantes Flankieren und Standardverhalten

## Ziel
`FireteamBehaviorResolver` leitet aus dem aktuellen Leader ein vollstaendiges Laufzeitprofil ab und liefert damit die Grundlage fuer geplantes `flank`, Standardverhalten ohne aktive Orders und das spaetere Suppression-/Ad-hoc-System.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_048_persoenlichkeitsmerkmale.md](docs/tasks/TASK_048_persoenlichkeitsmerkmale.md)
- Lies [docs/tasks/TASK_088_leadership_bonus.md](docs/tasks/TASK_088_leadership_bonus.md)
- Pruefe den Git-Status

## Kontext
- Die Bestandsskala fuer Skills liegt bei `0.0–1.0`.
- Die im Prompt beschriebenen `0–100`-Formeln muessen daher in dieselbe Wirkung uebersetzt werden, nicht wortwoertlich uebernommen werden.

## Aufgabe

### 1. `FireteamBehaviorResolver`
- Berechnet pro Fireteam:
	- `advance_style`
	- `cover_priority`
	- `fire_discipline`
	- `cohesion_threshold`
	- `suppression_threshold`

### 2. Prompt-Formeln auf Bestands-Skala abbilden
- `advance_style`:
	- `aggressive` oder `reckless` -> `rush`
	- `cautious` -> `creep`
	- sonst `bounding`, wenn `toughness > 0.6`
	- sonst `creep`
- `cover_priority = clampf(1.0 - toughness, 0.1, 0.9)`
- `fire_discipline`:
	- `move` -> `hold_fire`
	- `defend` -> `semi_disciplined`
	- `engage` -> `fire_at_will`
	- `flank` -> `semi_disciplined`, wenn `leadership > 0.6`, sonst `fire_at_will`
	- `take` -> `fire_at_will`
- `cohesion_threshold = clampf(200.0 - (leadership * 150.0), 50.0, 180.0)`
- `suppression_threshold = max(1, floori(toughness * 5.0))`
	- `reckless` -> Ergebnis * 3
	- `cautious` -> Ergebnis * 0.5

### 3. Geplantes `flank`
- Spieler setzt nur eine grobe Flankenposition.
- Der Fireteam-Leader bestimmt den konkreten Annaeherungsweg autonom.
- Traits und Leadership beeinflussen dabei Direkheit, Deckungssuche und Terrainnutzung.
- Bei Start des geplanten Flankierens wird `flank_initiated` ueber `EventRouter` gesendet.

### 4. Standardverhalten ohne aktive Befehle
- Default ist `hold_position`.
- Bei LOS-Kontakt wird `fire_at_will` genutzt.
- `cautious` sucht aktiv Cover im kleinen Umkreis.
- `aggressive` und `reckless` bleiben eher exponiert.
- Keine selbststaendige Bewegung ohne aktiven Befehl oder Phasenwechsel.

## Nicht-Ziele
- keine persistente AI-State-Machine
- keine Sozialdynamik
- keine freie autonome Langstreckennavigation ohne Befehl

## Akzeptanzkriterien
- Verhaltensprofile werden pro Laufzeitlage neu berechnet.
- `engage` ist Teil der Fire-Discipline-Ableitung.
- Geplantes `flank` ist leadergesteuert und traitabhaengig.
- Fireteams ohne aktive Orders fallen auf nachvollziehbares Standardverhalten zurueck.
