# Einzelspieler: Orte und Auftraege

Stand: 09.11.2026. Implementierungsvertrag fuer AP4–AP8, kein Nachweis fertiger Features.

## Besitzer und Lebenszyklus

SimulationRoot verarbeitet autorisierte Kampagnencommands. Ein langlebiger
SingleplayerCampaignState bleibt ausserhalb der deaktivierbaren Erkundung und
der austauschbaren Mission. MetaLayerFlow bindet diesen Owner und orchestriert
Szenen; UI und Presenter senden nur Commands und lesen Snapshots.
Aircraft-/Transportowner behalten Payload, Boarding und Flugphasen pro craft_id.
Campaign referenziert Craft-/Ort-/Job-IDs, simuliert keinen zweiten Transit.
Die zusaetzliche Orbit-/Quantum-Reise folgt `orbit_quantum_travel_contract.md`:
ein SimulationRoot-gebundener Reiseowner besitzt nur Orbitposition und
Reisephase. Abheben ist vom ortsgebundenen Missionsanflug getrennt. Erst der
ausdrueckliche Anflug bindet Ort/Job und startet die zugehoerige Karteninstanz.

## Daten und Zustaende

- location_id: homebase, satellite_crash, trade_outpost; jeweils Name,
  Regionposition, map_file_path, scenario_file_path, landing_pad_ids, services.
- job_id: satellite_recovery, getrennt von location_id. Mehrere Jobs duerfen
  denselben Ort referenzieren. Job enthaelt Titel, Objectivebezug und Belohnung.
- Status: offered -> accepted -> active -> completed oder failed.
- Annahme startet keinen Flug. Zielwahl startet keine Mission. Handelsbesuch
  braucht keinen Kampfauftrag. completed besitzt eine stabile Abschluss-ID.
- Abschluss nur mit bestaetigtem Runtime-/Scenariobeleg, niemals durch
  Szenenladen, Naehe, Kartenwahl oder UI-Button allein.
- Abbruch/Fehlschlag vergibt keine Erfolgsbelohnung; Ergebnis erneut anzeigen
  erzeugt keinen zweiten Abschlussbeleg.
- Die beiden neuen friedlichen Einzelspielerorte verwenden das gespeicherte
  Landepad. LZ-Klick und Runtime-Drop validieren dieselbe gespeicherte Position;
  ein belegtes Pad bleibt fuer ein zweites Schiff gesperrt, dessen Vorbereitung
  und Wartezustand bleiben unabhaengig. Legacy-/verbundene freie LZ bleiben erhalten.
- Rueckkehr am Schiff bestaetigt nur das tatsaechlich geparkte Schiff des aktiven
  Auftrags. MissionSetup erhaelt dessen unveraenderliche Craft-/Job-/Szenario-IDs
  vom Runtime-Handoff. Ein fehlendes, fremdes oder abgeflogenes Schiff kann keinen
  crew_returned-Beleg erzeugen. Frueher expliziter Rueckflug bleibt moeglich;
  nach tatsaechlicher Heimkehr ohne Abschluss wird der Auftrag fehlgeschlagen
  und die verlassene Instanz geschlossen, ohne Belohnung.

## Bruecke und Pruefung

get_operations_snapshot()/request_operation(operation, payload) bleiben die
UI-Bruecke. accept_job und select_destination delegieren an den autoritativen
Commandpfad. Snapshot zeigt accepted_job_ids, selected_job_id,
selected_location_id, bestaetigten Jobstatus und Completionbelege.
Unbekannte IDs, Ort/Job-Widerspruch und unzulaessige Uebergaenge werden mit
konkretem Grund abgelehnt. Tests pruefen Annahme ohne Flug, Wechsel, mehrere
Jobs am selben Ort, Handelsbesuch, Abbruch und Erhalt bei Szenenwechsel.

Kein Savegame-Migrationsauftrag; isolierte Profile, normale Nutzerdaten erhalten.

## Playtestrevision 10.11.2026: sichtbarer Rueckweg

Die kompakte gelandete Schiffskarte bietet Einsteigen und Abheben direkt an.
Einsteigen beauftragt den bestehenden Truppweg zum tatsaechlichen geparkten
Schiff; die autoritative Boardingpruefung bleibt erhalten. Abheben verlangt
bestaetigte Anwesenheit des Piloten und die vorhandenen Transportgates.
Weltklick am gelandeten Schiff setzt denselben Craftfokus wie die Schiffskarte.
Spielertexte verwenden benannte Interaktionen statt COM/BLOCKED/NEXT; rohe
Diagnosefelder bleiben fuer bestehende Snapshots erhalten.
