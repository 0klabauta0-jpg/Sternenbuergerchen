# TASK_112 - ContactTracker und ContactMapOverlay

## Ziel
Ein `ContactTracker` fuehrt gestufte Feinderkennungszustaende pro Fireteam ein und verteilt bestaetigte Kontakte mit Verzogerung an andere Friendlies. Ein `ContactMapOverlay` visualisiert diese Kontaktlage in der Missionsansicht.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_111_fireteamsecuritycontroller_und_overwatch.md](docs/tasks/TASK_111_fireteamsecuritycontroller_und_overwatch.md)
- Lies [docs/tasks/TASK_091_awareness_detection_delay.md](docs/tasks/TASK_091_awareness_detection_delay.md)
- Lies [docs/tasks/TASK_092_stealth_sichtreichweite.md](docs/tasks/TASK_092_stealth_sichtreichweite.md)
- Pruefe den Git-Status

## Kontext
- `ContactTracker` verwaltet missionslokale Kontaktinformationen als eigene Datenlage pro Fireteam.
- Der Tracker loest nicht selbst Bewegung, Feuer oder Sektorwechsel aus, sondern beliefert die dafuer zustaendigen Systeme mit Kontaktzustand, letzter Position und Zeitstempeln.
- Die Darstellung im `ContactMapOverlay` bleibt rein lesend.

## Aufgabe

### 1. `ContactTracker`
- Verwalte pro bekanntem Feind und Fireteam die Zustaende:
  - `unknown`
  - `suspected`
  - `spotted`
  - `confirmed`
  - `lost`
- Halte letzte bekannte Position, Tick-Zeitstempel und meldende Fireteams fest.

### 2. Zustandsuebergaenge
- `suspected` steht fuer ungenaue Hinweise oder weitergereichte Meldungen.
- `spotted` steht fuer kurzen LOS-Kontakt.
- `confirmed` steht fuer stabilen, aktuellen LOS-Kontakt.
- `lost` speichert die letzte bekannte Position nach Kontaktabriss.

### 3. Informationsweitergabe
- `confirmed`-Kontakte werden zeitverzoegert an andere Friendly-Fireteams weitergegeben.
- Die Verzoegerung skaliert mit `leadership`.
- Empfangende Fireteams erhalten mindestens `suspected`.

### 4. Wirkung auf das Verhalten
- `suspected` liefert genug Information, damit Sicherungs- oder Overwatch-Systeme sich auf den Sektor ausrichten koennen.
- `spotted` und `confirmed` liefern den noetigen Kontaktzustand fuer bestehende Kampf- und Feuerfreigabelogik.
- `lost` haelt die letzte bekannte Position weiter als Bezug fuer Sicherung oder spaetere Flanken-Entscheidungen.
- Die konkrete Reaktion bleibt in den konsumierenden Systemen und wird nicht in den Tracker gezogen.

### 5. `ContactMapOverlay`
- Visualisiere:
  - `suspected` als Fragezeichen
  - `spotted` als halbtransparentes Feind-Icon
  - `confirmed` als volles Feind-Icon
  - `lost` als ausgegrautes Feind-Icon
- Darstellung ist rein lesend und veraendert keinen Simulationszustand.

## Nicht-Ziele
- keine komplette Wahrnehmungs-KI-Neuarchitektur
- keine eigene Minimap
- keine globale Commander-Intel-Persistenz ausserhalb der Mission
- keine eigene Overwatch- oder Security-Ausfuehrung
- keine direkte Gameplay-Mutation an Units

## Akzeptanzkriterien
- Fireteams fuehren Feindkontakte mit den fuenf Erkennungszustaenden.
- Bestaetigte Kontakte werden verzoegert an andere Fireteams weitergegeben.
- Die Kontaktzustaende wirken auf Ausrichtung, Feuerfreigabe und Overwatch.
- Die Missionsansicht visualisiert `suspected`, `spotted`, `confirmed` und `lost` unterscheidbar.

## Umsetzung
- `scripts/tests/contact_tracker.gd` fuehrt die missionslokale Kontaktlage pro Friendly-Fireteam mit `suspected`, `spotted`, `confirmed` und `lost`, inklusive letzter Position, Tick-Zeitstempel und leadership-skaliert verzogerter Relay-Weitergabe bestaetigter Kontakte.
- `MissionCombatLoopDriver` speist den Tracker aus bestehendem LOS- und Detection-Delay, exponiert Snapshots nach aussen und nutzt `spotted`/`confirmed` als zusaetzliche Feuerfreigabe-Intel fuer Friendly-Angriffe; `spotted` erhaelt dabei den vorgesehenen Accuracy-Malus.
- `MissionTacticalSandboxController` reicht die Kontakt-Snapshots an Security und UI weiter, ohne selbst neue Gameplay-Wahrheit aufzubauen.
- `FireteamSecurityController` akzeptiert nun neben sichtbaren Enemy-Nodes auch Contact-Entries, sodass `suspected` und `lost` bereits fuer Sicherungsrichtung und Hauptbedrohung genuegen.
- `scripts/tests/contact_map_overlay.gd` visualisiert die Kontaktlage getrennt von Plan- und Security-Layern als rein lesendes Karten-Overlay.
- `scripts/tests/task_112_verifier.gd` deckt Zustandsuebergaenge, Relay-Delay, Security-Konsum von Kontakt-Hinweisen, Overlay-Aggregation und Missionsintegration headless ab.
