# TASK_362 - Homebase Aircraft State Manager Extraction

## Ziel
Aircraft-, Dropship- und Flightdeck-State soll aus `HomebaseScreen.gd` in einen eigenen State-/Validation-Manager gezogen werden, waehrend die Homebase-UI zunaechst nur delegiert.

## Status: GEPLANT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll. `HomebaseScreen.gd` enthaelt Aircraft-Definitionen, Pilotenzuordnung, Location, Dropship-State, Transit/Transfer-Checks, Status-Text und Panel-Rendering in einem Skript. Ein erster Schnitt sollte aber nur State/Validierung extrahieren, nicht gleichzeitig das komplette Panel neu bauen.

## Problem
Aircraft- und Dropship-Regeln sind mit UI-Rendering vermischt. Dadurch wird jede Homebase-Direct-Staging-Aenderung riskanter, weil echte Start-/Flightdeck-Bedingungen und Shipcard-Darstellung im selben Controller liegen.

## Ursache
Die Homebase ist historisch als monolithischer UI-Controller gewachsen: Roster, Fireteams, Loadout, Aircraft, Personnel Events und Mission Launch teilen Variablen und Refresh-Aufrufe.

## Umfang
- Neues `AircraftManager`-Skript fuer reine Daten-/Regellogik einfuehren.
- In den Manager verschieben:
  - Aircraft-Definitionen und Default-Build
  - ausgewaehltes Aircraft/Craft
  - Pilotenzuordnung
  - Craft-Location und Transitstatus
  - Dropship-Cargo-/Boarding-State
  - Ready-/Blocker-/Statusberechnung
- Shipcard-Rendering und konkrete Control-Erzeugung im ersten Schritt in `HomebaseScreen.gd` lassen.
- Homebase-Direct-Staging-Craft-Gates aus TASK_349 ueber den Manager abfragen.

## Akzeptanzkriterien
- [ ] `HomebaseScreen.gd` delegiert Aircraft-State und Ready-/Blocker-Pruefungen an einen Manager.
- [ ] Bestehende Dropship-, Pilot-, Cargo- und Transitvertraege bleiben unveraendert.
- [ ] Homebase-Direct-Missionstart nutzt weiter ein echtes Homebase-Dropship-Craft.
- [ ] Bestehende Homebase-/FOB-/Dropship-Verifier bleiben gruen.
- [ ] Keine neue SimulationRoot- oder Mission-Wahrheit im Manager.

## Erwartete Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/aircraft_manager.gd`
- `scripts/tests/task_362_homebase_aircraft_state_manager_extraction.gd`
- ggf. `scripts/tests/task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`
- ggf. `scripts/tests/bugfix_dropship_mission_flow_verifier.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_362_homebase_aircraft_state_manager_extraction.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_346_homebase_direct_staging_character_popup.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Der Manager darf kein zweiter MetaLayerFlow werden. Er besitzt nur Homebase-Aircraft-State und liefert klare Snapshots/Statuswerte.
- Panel-Controller-Extraktion kann spaeter folgen; hier bleibt der sichtbare UI-Aufbau bewusst unveraendert.
