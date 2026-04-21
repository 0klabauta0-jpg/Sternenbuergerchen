# TASK_109 - TacticalStanceController und TacticalStancePanel

## Ziel
Der Spieler kann pro ausgewaehltem Fireteam eine taktische Haltung anfordern. Diese Haltung ist keine direkte Mikrobefehlssteuerung, sondern eine fluechtige Vorgabe, die der aktuelle Fireteam-Lead innerhalb seiner Trait- und Skill-Grenzen in das abgeleitete Verhalten uebersetzt.

## Status: OFFEN

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_098_taktische_fireteam_auswahl_und_mehrfachselektion.md](docs/tasks/TASK_098_taktische_fireteam_auswahl_und_mehrfachselektion.md)
- Lies [docs/tasks/TASK_101_fireteambehaviorresolver_und_standardverhalten.md](docs/tasks/TASK_101_fireteambehaviorresolver_und_standardverhalten.md)
- Pruefe den Git-Status

## Aufgabe

### 1. `TacticalStanceController`
- Verwalte pro Fireteam die fluechtige Haltung:
  - `cautious`
  - `normal`
  - `aggressive`
- Die Haltung wird nicht im `FireteamOrderPlan` gespeichert.
- Die Haltung gilt bis zur naechsten Aenderung oder bis zu einem globalen Phasenuebergang.

### 2. Integration in die Verhaltensableitung
- `FireteamBehaviorResolver` beruecksichtigt die Haltung bei:
  - `advance_style`
  - `cover_priority`
  - `suppression_threshold`
- Trait-Sonderfaelle bleiben erhalten:
  - `reckless` ignoriert `cautious` weitgehend
  - `cautious` setzt `aggressive` nur teilweise um

### 3. UI `TacticalStancePanel`
- Zeige fuer aktuell ausgewaehlte Fireteams die Buttons:
  - `Vorsichtiger`
  - `Normal`
  - `Aggressiver`
- Das Panel arbeitet nur auf Fireteam-Ebene, nie auf einzelnen Units.
- Mehrfachauswahl soll eine Haltung gesammelt auf mehrere Fireteams anwenden koennen.

### 4. Visuelle Rueckmeldung
- Die aktuelle Haltung wird an der Unit oder im Statusbereich als Badge `C`, `N` oder `A` sichtbar.
- Bei Phasenwechsel wird die Haltung automatisch auf `normal` zurueckgesetzt.
- Haltung und Ad-hoc-Befehle bleiben parallel sichtbar und kompatibel.

## Nicht-Ziele
- keine neuen Phasenregeln
- keine Ad-hoc-Befehlslogik
- keine Persistenz im Meta-Layer

## Akzeptanzkriterien
- Pro Fireteam kann zwischen `cautious`, `normal` und `aggressive` umgeschaltet werden.
- Die Haltung wirkt auf die abgeleiteten Verhaltenswerte, ohne selbst als Planzustand gespeichert zu werden.
- Das Panel funktioniert fuer Einzel- und Mehrfachauswahl.
- Nach einem Phasenwechsel stehen alle Fireteams wieder auf `normal`.
