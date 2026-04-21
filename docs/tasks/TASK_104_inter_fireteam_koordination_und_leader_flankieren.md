# TASK_104 – Inter-Fireteam-Koordination und Leader-initiiertes Flankieren

## Ziel
Mehrere Fireteams koordinieren ihre Bewegung bei engen Zielraeumen ueber einen `FireteamCoordinationManager`, und aggressive Leader koennen in guenstigen Gefechtssituationen eigenstaendig einen Ad-hoc-`flank` anstossen.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_102_adhocordercontroller_und_gefechts_sofortbefehle.md](docs/tasks/TASK_102_adhocordercontroller_und_gefechts_sofortbefehle.md)
- Lies [docs/tasks/TASK_103_suppression_interruption_und_return_to_plan.md](docs/tasks/TASK_103_suppression_interruption_und_return_to_plan.md)
- Pruefe den Git-Status

## Aufgabe

### 1. `FireteamCoordinationManager`
- Erkennt Ueberschneidungen von Zielraeumen innerhalb eines konfigurierbaren Radius.
- Arbeitet auf Fireteam- und Plan-Ebene, nicht auf Unit-Micro.

### 2. Inter-Fireteam-Bounding
- Fireteam mit hoeherem Leader-`leadership` bewegt sich zuerst.
- Andere Fireteams halten und decken.
- Nach Signal `fireteam_ready_to_advance` erfolgt Rollentausch.
- Ad-hoc-Befehle unterbrechen die Koordination nur temporaer.

### 3. Kommunikation nur ueber `EventRouter`
- Neue Signalvertraege duerfen erweitert, aber nicht gebrochen werden.
- Kein Direktzugriff der Koordination auf interne Laufzeitdaten anderer Manager.

### 4. Autonomes Leader-Flankieren
- Aktueller Leader darf ohne Spielerbefehl einen Ad-hoc-`flank` starten, wenn:
	- Trait `aggressive` oder `reckless`
	- `leadership > 0.7`
	- aktiver Feindkontakt
	- kein laufender Ad-hoc-Befehl
	- guenstiges Terrainfenster erkannt
- Das Ereignis wird als `leader_initiated_flank` ueber `EventRouter` signalisiert.

## Nicht-Ziele
- keine globale Gruppen-KI ueber alle Fireteams hinweg
- keine neue Commander-Hierarchie
- keine neue Persistenz fuer Koordinationszustand

## Akzeptanzkriterien
- Enge Wegpunktlagen loesen Bounding-Koordination aus.
- Kommunikation laeuft ausschliesslich ueber `EventRouter`.
- Leader koennen in passenden Lagen autonom flankieren.
- Ad-hoc-Unterbrechungen und Rueckkehr in die Koordination funktionieren.
