# Orbitowner-Integration und Polisa-Flightidentitaet

## Ziel / Ursache
Gesicherten Space-Stand 613a03c3c mit unserer Basis 3fb8d2985 zusammenfuehren,
beide Historien erhalten. Der gemeinsame Flight muss auch bei lokaler Polisa-
Geburt dieselbe Craft-ID wie sein bestehender Travelowner tragen: configure()
erstellt ohne ID einen __unassigned__-Flight, initialize_surface bindet ihn
bislang nicht. Keine neue Flug-/Reisewahrheit einfuehren.

## Umfang / Nicht-Ziele
Separater Worktree orbit-owner-integration-20261111, Branch
task/orbit-owner-integration-20261111. Mergekonflikte hunkweise unter Erhalt
unserer Door-/PreparedTravel-/Warp-/Polisa-Grenzen aufloesen. Anschliessender
Bugfix ausschliesslich in den beiden Traveldateien, nach echtem RED.
Roottransition bleibt fixtureonly; keine produktive Orbitkarte, kein Flag,
keine volle Orbitreise, kein Main/Push/EXE. 799b1b025 ist nicht Bestandteil.
Supply/Campaign/Adapter nur unveraenderte gesicherte Source-Mergeaenderungen.

## Vertraege / Akzeptanz
orbital_approach_contract, prepared_space_area_travel_contract,
ORBITAL_APPROACH_MAPS_2026_11_11, SPACE_COMBAT_EXECUTION_2026_11_11.
Polisa-Geburt behaelt genau ein Flightobjekt mit exakter ID; falsche bestehende
Flightidentitaet wird vor Travel-/Pose-/Revision-/Requestmutation abgewiesen.
Unbekannter Ort mutiert nichts. Vorhandene Prepare-/Replay-/Releasegrenzen und
Door-/Warphooks bleiben erhalten.

## Dateien / lokale Pruefung
Merge: SimulationRoot, Travelowner, Spacegrundlagen und gesicherte Adapter/UI-
Erweiterungen sowie Statusdokumente. Enger Fix: singleplayer_space_travel_state.gd,
gegebenenfalls Fleetdelegation. Kleine isolierte Pruefungen: PreparedTravel15,
RealRootFixture14 und PolisaBirthIdentity; keine breite Suite.

## Risiken / Status
Gemeinsame Basis 84dd; Cherry-Doubles erzeugen Dokukonflikte. SpaceTravelreader
muss den gemeinsamen Flight behalten; keine strategischen Posewrites in lokale
Areas zulassen. Konflikt-/Quellschutz-/Pruefbericht folgt in eigener QA.

## Ergebnis
Merge 8f62183f7 mit elf aufgeloesten Konfliktdateien. Supply/Campaign/Store,
Ground/DoorDriver, Profilmath/Actor und TerrainView byteidentisch zur eigenen
Basis. Polisa-IDprobe sauber RED1/3, nach zweizeiligem initialize_surface-Fix
GREEN4/0. PreparedTravel15/0 und echte Root-/Travelfixture14/0 frisch gruen,
Quell-/Nutzerprofilguard und private Canary bestanden. Konfliktentscheidungen,
gesicherte Hashes und Grenzen: docs/qa/orbit_owner_integration_20261111/README.md.
Keine Kartenaktivierung oder vollstaendige Orbitreise, Parent uebernimmt selbst.
