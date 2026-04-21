# TASK_106 – Dropship-LZ, Insertion und verzoegerte Aktivierung

## Ziel
Die Dropship-Landezone ist die echte Startposition eines Fireteams. Nicht eingeflogene Teams existieren noch nicht in den Laufzeit-Registries und werden erst mit der Insertion steuerbar.

## Status: OFFEN

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_096_meta_missionmap_dropship_und_charactersheet_recovery.md](docs/tasks/TASK_096_meta_missionmap_dropship_und_charactersheet_recovery.md)
- Lies [TASK_105 – Leader-Nachfolge, Lead-Rueckgabe und UI-Synchronisierung](docs/tasks/TASK_105_loadoutmodifierresolver_zum_missionsstart.md)
- Pruefe den Git-Status

## Aufgabe

### 1. LZ als echte Startposition
- Die bestehende Dropship-LZ-Planung bestimmt die Startposition des jeweiligen Fireteams.
- Ein Fireteam erscheint nicht vor seiner Insertion auf der Karte.

### 2. Laufzeit-Aktivierung
- Nicht eingeflogene Fireteams fehlen in `UnitRegistry` und `FTLRegistry`.
- Erst die Insertion haengt das Fireteam in die Laufzeit ein.
- Erst danach kann das Fireteam Befehle und Ad-hoc-Orders empfangen.

### 3. Zeitliche Freischaltung
- Der Einflugzeitpunkt ist der Moment, ab dem das Fireteam steuerbar wird.
- Vorherige Plaene duerfen bereits existieren, laufen aber erst nach Aktivierung an.

### 4. Integrationspfad
- Bestehende Dropship-/LZ-Daten aus Meta und Mission bleiben die einzige Quelle fuer Position und Aktivierungszeitpunkt.
- Keine parallele Spawn-Wahrheit.

## Nicht-Ziele
- keine freie Fahrzeugsteuerung durch den Spieler
- keine neue offene Flugphysik
- keine zweite Missionsspawn-Architektur neben LZ und Insertion

## Akzeptanzkriterien
- Fireteams erscheinen erst nach Einflug in den Registries.
- Die LZ ist ihre reale Startposition.
- Vor der Insertion sind keine Befehle oder Ad-hoc-Orders fuer das Fireteam aktiv.
- Nach der Insertion ist das Fireteam sofort in die bestehende Missionslogik eingebunden.
