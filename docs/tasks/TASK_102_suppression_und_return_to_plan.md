# TASK_102 – AdHocOrderController und Gefechts-Sofortbefehle

## Ziel
Ein `AdHocOrderController` fuehrt kurzfristige Commander-Eingriffe in laufende Gefechte ein. Diese Befehle werden nicht in Phasenplaenen gespeichert, laufen sofort an und kehren nach Abschluss automatisch zum unterbrochenen Plan zurueck.

## Status: OFFEN

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_097_taktische_befehlsdatenmodelle_und_vertraege.md](docs/tasks/TASK_097_taktische_befehlsdatenmodelle_und_vertraege.md)
- Lies [docs/tasks/TASK_101_fireteambehaviorresolver_und_standardverhalten.md](docs/tasks/TASK_101_fireteambehaviorresolver_und_standardverhalten.md)
- Pruefe den Git-Status

## Aufgabe

### 1. `AdHocOrderController`
- Nimmt Ad-hoc-Befehle fuer Fireteams im laufenden Gefecht an.
- Ad-hoc-Befehle sind nur verfuegbar bei LOS-Kontakt oder aktivem Beschuss.
- Befehle werden nicht im `FireteamOrderPlan` gespeichert.

### 2. Unterstuetzte Ad-hoc-Befehle
- `flank`
- `disengage`
- `fall_back`
- `focus_fire`
- `hold_till_last_man`

### 3. Abschluss und Rueckkehr
- Nach Abschluss eines Ad-hoc-Befehls kehrt das Fireteam automatisch zum naechsten `pending`-Wegpunkt des laufenden Plans zurueck.
- `hold_till_last_man` bleibt aktiv, bis alle Members ausfallen oder der Commander manuell abbricht.
- Ein manueller `Return to Plan`-Befehl bricht auch laufende Ad-hoc-Befehle sofort ab.

### 4. `AdHocOrderPanel` und visuelle Trennung
- Kontextpanel ist nur sichtbar, wenn ein Fireteam im Gefecht ist.
- Geplante Befehle:
	- durchgezogene Linie
	- Fireteam-Farbe
	- Wegpunktsymbol
- Ad-hoc-Befehle:
	- gestrichelte Linie
	- Weiss mit Fireteam-Rand
	- kleines Sofort-Icon an der Unit
	- Label `AD-HOC: [typ]`

### 5. Sonderfall `flank`
- Als Ad-hoc-Befehl wird `flank` sofort gestartet.
- Der Spieler gibt nur eine Zielposition vor.
- Der Leader entscheidet weiterhin den konkreten Weg autonom.

## Nicht-Ziele
- keine Suppression
- keine globale Phasenlogik
- keine Gegner-Patrouillen

## Akzeptanzkriterien
- Ad-hoc-Befehle sind nur im Gefecht verfuegbar.
- Sie werden sofort ausgefuehrt und nicht im Plan gespeichert.
- Nach Abschluss erfolgt automatisch die Rueckkehr zum Plan.
- Planung und Ad-hoc sind auf der Karte klar unterscheidbar.
