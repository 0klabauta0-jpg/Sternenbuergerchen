# TASK_105 – Leader-Nachfolge, Lead-Rueckgabe und UI-Synchronisierung

## Ziel
Faellt ein Fireteam-Lead im Einsatz aus, wird automatisch ein Nachfolger bestimmt. Kommt der urspruengliche Lead per Respawn oder Einflug zurueck, uebernimmt er sofort wieder die Fuehrung. Alle Lead-Anzeigen in Mission, FOB und Meta werden synchron gehalten.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_088_leadership_bonus.md](docs/tasks/TASK_088_leadership_bonus.md)
- Lies [TASK_104 – Inter-Fireteam-Koordination und Leader-initiiertes Flankieren](docs/tasks/TASK_104_inter_fireteam_koordination_und_leader_flankieren.md)
- Pruefe den Git-Status

## Aufgabe

### 1. Automatische Nachfolge
- Faellt der aktuelle Lead aus, uebernimmt das Mitglied mit dem hoechsten `leadership`.
- Bei Gleichstand entscheidet `toughness`.

### 2. Rueckgabe an den urspruenglichen Lead
- Kommt der urspruengliche Lead per Respawn oder spaeterer Insertion zurueck, uebernimmt er automatisch wieder die Fuehrung.
- Gilt nur fuer die laufende Mission.

### 3. Laufende Orders fortsetzen
- Aktiver Wegpunkt und aktiver Ad-hoc-Befehl werden nicht verworfen.
- Der neue Lead uebernimmt den aktuellen Zustand ohne Unterbrechung.

### 4. UI-Synchronisierung
- Gelber Lead-Stern wechselt sofort in der taktischen Ansicht.
- FOB- und Meta-Ansichten spiegeln denselben Lead fuer die laufende Mission.
- Die autonome Flankierlogik bindet sich immer an den aktuellen Lead.

## Nicht-Ziele
- keine dauerhafte Meta-Persistenz der Missions-Nachfolge
- keine manuelle Lead-Wahl ausserhalb bestehender Systeme

## Akzeptanzkriterien
- Nachfolge greift automatisch bei Lead-Ausfall.
- Rueckkehr des urspruenglichen Leads stellt dessen Fuehrung wieder her.
- Laufende Planschritte bleiben erhalten.
- Alle Lead-Markierungen wechseln sichtbar mit.
