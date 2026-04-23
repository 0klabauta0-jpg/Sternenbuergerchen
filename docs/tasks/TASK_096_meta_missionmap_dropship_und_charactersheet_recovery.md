# TASK_096 – Meta-Layer Recovery: Missionskarte, Dropship-LZ und Character-Sheet-Umbau

## Ziel
Die fruehere read-only `Mission`-/`MissionMap`-Overview ist inzwischen durch die echte Missionskarte im Meta-Layer ersetzt. Die verbleibenden Recovery-Punkte aus Homebase, FOB, Dropship-Flow und Character Sheet sollen hier gebuendelt sauber zu Ende gebaut werden.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_078_meta_navigation_map_ansicht.md`
- Lies `docs/tasks/TASK_079_fob_fireteam_staging_ausbau.md`
- Lies `docs/tasks/TASK_081_meta_ui_harmonisierung_fob_homebase_loadout.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_081 muss als Basis vorhanden sein.
- Der bestehende Homebase -> FOB -> Mission -> Debrief-Flow darf funktional nicht regressieren.
- UI bleibt Anzeige- und Staging-Schicht; Gameplay-Wahrheit bleibt ausserhalb der Meta-UI.

## Kontext
- TASK_078 hatte zwischenzeitlich eine read-only Map-Overview eingefuehrt; der alte separate `meta_map_screen`-Pfad ist inzwischen wieder entfernt, und `Mission` zeigt jetzt die eingebettete echte Missionskartenvorschau.
- `IMPLEMENTATION_STATUS.md` beschreibt mehrere spaetere Meta-Recoveries bereits als vorhanden, unter anderem leeres Flight Deck, nummerierte Fenster und ausgegraute Pilot-/Transportkarten waehrend Transfer. Der aktuelle Nutzerstand deutet darauf hin, dass mindestens Teile davon fehlen, regressiert sind oder nicht vollstaendig durchverdrahtet wurden.
- Die eigentliche Missionskarte mit NPCs soll vor Missionsstart bereits als `Mission`-Ansicht sichtbar sein; ein separates Mission-Briefing als eigener Screen wird nicht mehr benoetigt.

## Aufgabe

### 1. Alte Mission-Overview ersetzen
- Entferne die bisherige read-only `MissionMap`-/Map-Overview als primaere `Mission`-Ansicht.
- Der Button `Mission` im Meta-Layer soll immer zur echten Missionskarte fuehren, also zu der Ansicht mit Karte und NPCs, nicht zu einem separaten Briefing-Screen.
- Die Missionskartenansicht soll ebenfalls oben links die drei Buttons `Homebase`, `FOB` und `Mission` tragen, analog zu den anderen Meta-Screens.
- Das bisherige separate Mission-Briefing kann entfallen; relevante Kurzinfos sollen sinnvoll und kompakt in die Header von Homebase und FOB verteilt werden.
- Die Headerhoehe und Grundmasse von Homebase und FOB duerfen dadurch nicht wachsen.

### 2. Missionskarte fuer Meta-Planung erweitern
- Die Missionskartenansicht soll vor Missionsstart bereits dieselbe Kartenbasis nutzen wie die eigentliche Spielflaeche.
- Fenster oder Hauptbereiche in Homebase, FOB und Missionskarte sollen eine kleine sichtbare Nummer oben links erhalten, damit sich UI-Bereiche leichter referenzieren lassen.
- Es soll klar benennbar sein, welche Ansicht die echte Karte ist; die irrefuehrende alte `MissionMap`-Overview soll nicht parallel als zweiter Kartenbegriff bestehen bleiben.

### 3. Dropship-LZ und Anflug sichtbar machen
- Fuer das Dropship soll auf der Karte eine Landezone (`LZ`) definierbar sein.
- Zusaetzlich soll die Anflugrichtung aus `NW`, `NE`, `SW`, `SE` waehltbar sein.
- LZ und Anflugwinkel muessen auf der Karte sichtbar markiert werden, in dreivierteltransparentem Gruen.
- Das Dropship selbst soll als Modell/Sprite auf der Karte dargestellt werden.
- Nach der Landung sollen die transportierten Passagiere bzw. Fireteams aussteigen koennen.
- Sobald das Fireteam abgesetzt wurde, darf die Fireteam-Karte nicht weiter im Dropship haengen bleiben.

### 4. Homebase-/FOB-Transferzustand korrigieren
- Das Transferfenster in der Homebase soll beim Start leer sein.
- In der FOB sollen NPC-Karten in Fenster 1 waehrend des laufenden Transits zur FOB sichtbar deaktiviert bzw. ausgegraut sein.
- Fuer diese transitierenden NPC-Karten soll wie bei den Schiffen ein Fortschrittsbalken sichtbar sein.
- Dasselbe Verhalten muss fuer Transport-/Pilotkarten konsistent bleiben; falls die bisher beschriebene Recovery nur teilweise greift, ist sie hier kontrolliert zu reparieren statt doppelt neu zu bauen.

### 5. Missionsslots und Piloten korrigieren
- Piloten sollen auf die Missionsslot-Kapazitaet mit angerechnet werden.
- Die Slot-Anzeige in Headern und Mission-Kontext muss diesen Zaehlpfad korrekt widerspiegeln.

### 6. Character Sheet komplett neu ordnen
- Portrait linksbuendig.
- Rechts daneben der Name; der Bereich darunter bleibt bewusst anschlussfaehig fuer spaetere Zusatzinfos.
- Darunter linksbuendig deutschsprachige Sektionen und Labels in dieser Reihenfolge:
  - `TRAIT:`
  - `KURZBESCHREIBUNG:`
  - `KERNWERTE (0,00 - 1,00):`
  - `Accuracy:`
  - `Speed:`
  - `Toughness:`
  - `Awareness:`
  - `Recognition:`
  - `Stealth:`
  - `Discipline:`
  - `Leadership:`
  - `KOMMUNIKATION:`
  - `Speech Quality:`
  - `Speech Quantity:`
  - `PLATTFORM-SKILLS (nur falls relevant):`
  - `Ground Vehicle Handling:`
  - `Dropship Piloting:`
  - `Freighter Piloting:`
  - `Fighter Piloting:`
  - `ABGELEITET:`
  - `Method Tags:`
  - `Function Scores:`
  - `Primary Specialty:`
  - `Secondary Specialty:`
  - `VERHALTENSPROFIL:`
  - `Initiative:`
  - `Order Fidelity:`
  - `Signature Control:`
  - `Contact Stability:`
  - `Autonomy:`
- Rechts neben den Kernwerten soll jeweils ein Fortschrittsbalken sitzen, der den Wert zugleich visuell und numerisch lesbar macht.

### 7. Portrait- und Card-Politur
- Darius Holt soll ein anderes, korrektes Portrait erhalten.
- Der bisherige `tracked`-Button auf der Dropship-Shipcard ist fachlich zu klaeren; falls er keine klare V1-Funktion hat, soll er entfernt oder eindeutig umbenannt werden.

## Architekturhinweise
- Keine zweite Missionswahrheit in der Meta-UI erzeugen; Kartenansicht liest und visualisiert vorhandenen Missions-/Map-State.
- LZ, Anflugrichtung und Dropship-Visualisierung sollen an den bestehenden Map-/Mission-Kontext angebunden werden, nicht als isolierte UI-Sonderlogik.
- Transfer-, Boarding- und Deboarding-Status bleiben kleine Meta-Orchestrierungszustaende und werden nicht zu einer grossen Fahrzeug- oder Kampagnensimulation ausgeweitet.
- Character-Sheet-Umbau soll vorhandene Profildaten und Formatter weiterverwenden, statt ein zweites Profilmodell einzufuehren.

## Nicht-Ziele
- keine neue frei editierbare Kartenplaner- oder Editor-Schicht im Meta-Layer
- keine echte Dropship-Physik, Flugpfad-Simulation oder beschiessbare Fahrzeuge
- keine neue Persistenzarchitektur fuer Portraits, Missionsbriefings oder Transportlogik
- kein ungeplanter Refactor des gesamten Meta-Layers ausserhalb der oben genannten Punkte

## Betroffene Bereiche
- `scripts/meta/meta_layer_flow.gd`
- `scenes/tests/mission_reactivity_test.tscn`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/fob_screen.gd`
- `scripts/meta/character_sheet_formatter.gd`
- Shipcard-/Flight-Deck-/Transport-bezogene Meta-Szenen und Skripte
- Roster-/Portrait-Zuordnung fuer Darius Holt

## Akzeptanzkriterien
- [x] `Mission` fuehrt im Meta-Layer immer zur echten Missionskarte und nicht mehr zu einer read-only Text-Overview.
- [x] Die Missionskartenansicht besitzt dieselben drei Navigationsbuttons wie Homebase und FOB.
- [x] Das alte separate Mission-Briefing ist entfernt oder in Homebase-/FOB-Header kompakt aufgegangen, ohne deren Groesse zu vergroessern.
- [x] Fensterbereiche tragen kleine sichtbare Nummern oben links.
- [x] In der Homebase startet das Transferfenster leer.
- [x] In der FOB werden transitierende NPC-Karten in Fenster 1 ausgegraut und mit Fortschrittsbalken angezeigt.
- [x] Piloten werden in die Missionsslot-Kapazitaet eingerechnet.
- [x] Auf der Karte koennen LZ und Anflugrichtung (`NW`, `NE`, `SW`, `SE`) definiert und in transparentem Gruen dargestellt werden.
- [x] Das Dropship ist auf der Karte sichtbar, Passagiere steigen nach Landung aus, und abgesetzte Fireteams verschwinden aus der Dropship-Karte.
- [x] Das Character Sheet folgt dem neuen Layout mit deutschem Label-Block und Fortschrittsbalken fuer Kernwerte.
- [x] Darius Holt nutzt ein anderes, korrektes Portrait.
- [x] Der `tracked`-Button ist entweder fachlich klar erklaert und sinnvoll benannt oder aus der Dropship-Shipcard entfernt.

## Abschluss dieses Recovery-Slice
- Die echten Tactical-HUD-Labels in `mission_reactivity_test.tscn` tragen jetzt direkt die gemeinsamen `#15` bis `#18`-Nummern statt alter Platzhaltertexte.
- `scripts/tests/task_096_recovery_verifier.gd` deckt die drei spaeten Recovery-Risiken jetzt gezielt ab: nummerierte Tactical-HUD-Labels, ausgegraute FOB-Transitkarten mit Fortschrittsbalken sowie den Character-Sheet-Aufbau mit deutschem Label-Block und Kernwert-Balken.
- Der Dropship-Kontext wurde abschliessend auf einen alten `tracked`-Button geprueft. Verbleibende Shipcard-Aktionen heissen fachlich klar `Board` und `Send`.

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_096_recovery_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add TASK_096 for mission map and meta UI recovery"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren
