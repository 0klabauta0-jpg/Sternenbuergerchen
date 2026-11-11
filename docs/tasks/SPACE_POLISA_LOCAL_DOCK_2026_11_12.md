# Lokaler Polisa-Dockanschluss – Schnittstellenentwurf

## Ziel und Ursache

Polisa bleibt die bestehende begehbare R08-Station mit ihren Pads und
Services. Ein Schiff soll sie künftig im vorhandenen lokalen Glut-2-Bereich
gezielt anfliegen, den Besuch beginnen und von dort wieder abdocken können.
Der heutige strategische Stationsweg bleibt bis zum paarigen Anschluss aktiv.
Dieser Entwurf schaltet nichts frei und implementiert noch keinen Flugweg.

## Umfang, Abgrenzung und Verträge

Relevant: `SPACE_COMBAT_EXECUTION_2026_11_11.md`,
`scripts/mission/orbit_approach_layout.gd`, bestehender Polisa-Visit-/Pad-,
Crew-, Fuel- und Reisevertrag sowie der Raumkampf-Flight-/Wing-/Claimsowner.
Keine AP6c-/AP7- oder Personnel-/Controller-Bodies ändern. Kein neues Modell,
Renderer, UI-State, V3-Live-JSON, Save-Bump oder Flagwechsel. Glut 2 ist der
Körper; Polisa ist ein eigenes Stationsziel und keine Planetenoberfläche.

## Gemeinsamer reiner Layoutdeskriptor

Ein späteres `polisa_station_dock_layout.gd` liefert rein und deterministisch
`build() -> Dictionary`, ohne SceneTree, Kamera, Owner oder Gameplaymutation:

```
schema: "space_station_dock_layout.v1"
revision: "polisa_glut2_dock_v1"
body_id: "glut_2"
area_id: "orbit_approach:glut_2"
station_id: "polisa"
target_id: "polisa_station_dock"
map_bounds: Rect2i(0, 0, 512, 256)
coordinate_system: "offset_hex"
station_anchor: Vector2i(256, 124)
station_block: Rect2i(244, 116, 24, 12)
dock_gate: Vector2i(256, 133)
```

Die Zahlen sind explizite Spielkartenkoordinaten, keine Meter oder aus der
Kamera abgeleitete Geometrie. `station_block` bezeichnet die für diese lokale
Raumkarte reservierten Offsetfelder `[244,268) × [116,128)`; `dock_gate` liegt
frei außerhalb des Blocks. Die existierende Körperlayout- und Eintrittsband-
Geometrie bleibt maßgeblich. Vor Runtime-Nutzung werden Bounds, Abstand und
Block-/Körper-/Eintrittsband-Überschneidung geprüft. Die Raumkartenstation ist
eine Zielrepräsentation; R08-Pads und deren Maßstab bleiben im Stationsort
und werden durch den bestehenden Padowner ausgewählt, nicht aus dieser
Raumkartengeometrie abgeleitet. UI und Simulation beziehen dieselbe Revision;
eine andere Revision oder ungültige Geometrie lehnt die Transaktion ab.

## Root-/Fleet-Grenze

- **Anflug:** Ein expliziter Stationsauftrag nennt Schiff und `target_id`.
  Root validiert aktuellen Glut-2-Area-/Flight-/Wingowner, Layoutrevision,
  vollständigen Schiffsfootprint, Gate- und Claimzustand sowie echte Pilot-/
  Crew- und bestehende Visit-/Pad-/Fuel-Voraussetzungen. Die Navigation bleibt
  beim bestehenden lokalen Flight- und Claimsowner. Erst am bestätigten freien
  Gate bereitet Root den vorhandenen Stationsbesuch und den Fleet-Übergang
  gemeinsam vor; alle Validierungen vor der synchronen Publikation. Retry mit
  gleicher Request-ID ist idempotent; Fehler verändern keinen Owner.
- **Abbruch:** Vor der Commitgrenze wird nur der Anflugauftrag beendet; Schiff,
  Flugpose, Rotte und lokale Area bleiben erhalten. Nur eigene Claims werden
  freigegeben. Keine Visit-/Pad-/Fuel-Buchung und kein zweiter Pilotstatus.
  Nach erfolgreichem Commit gilt der bereits bestehende Visit-/Abreisepfad,
  kein rückwirkender Abbruch.
- **Abdocken:** Root prüft echte Visitidentität, Pilot/Crew, verfügbares Gate
  samt vollständigem Footprint und aktuelle Revisionen. Die vorhandenen
  Station-/Pad-/Visit- und Fuelregeln bleiben zuständig. Root bereitet Flight,
  lokalen Index/Claims, Fleet-Reisezustand und Rotte gemeinsam vor, publiziert
  sie synchron und meldet Erfolg erst danach. Bei Blockade bleibt der Besuch
  unverändert; Retry erzeugt kein zweites Schiff und keine zweite Buchung.
- Fleet verwaltet Reisephase und Referenz auf denselben Flightowner; Root
  koordiniert die bereichsübergreifende Transaktion. UI liest Deskriptor und
  autoritative Projektionen und sendet Aufträge. Sie erzeugt keine Dockpose,
  Claim-, Visit-, Pilot- oder Treibstoffwahrheit. Die genaue Adapter- und
  Receipt-Signatur wird bei der Implementierung an vorhandene Owner gebunden.

### Konkrete vorhandene Operations- und Receiptgrenze

- `space_begin_approach` in `singleplayer_runtime_adapter.gd` ruft heute
  `authorize_departure` und `SimulationRoot.commit_singleplayer_departure`
  auf. Diese Transaktion bereitet Supply (`prepare_route_fuel`), Campaign
  (`prepare_departure`) und Fleet (`prepare_space_area_transition`) vor und
  speichert `_departure_group_receipts`; das Root-Event folgt nach Commit.
  Für lokales Polisa erhält genau dieser Pfad eine **separate Stationsgate-**
  **prüfung** statt `preview_surface_deactivation`. Der Gameplayort bleibt
  `location_id=polisa`, der Gatekontext bindet zusätzlich `target_id` und
  Layoutrevision. Der resultierende Fleet-Übergang bleibt `begin_approach`;
  `finish_space_approach` und der bestehende Visit-/Padablauf bleiben erhalten.
  `preview_departure` und tatsächliche Wirtschaftskandidaten werden erneut
  gelesen; ein Navigationauftrag allein belastet weder Supply noch Campaign.
- `singleplayer_space_travel_state.gd::_prepare_space_area_transition_state`
  kennt bereits strategisches `begin_approach` für Polisa und den lokalen
  Oberflächenzweig. Ein eigener lokaler Stationszweig muss Glut-2-Area,
  Stationstarget und Gatebeleg prüfen; er darf `surface_location_id` nicht
  umdeuten. Fleet bindet denselben unveränderten Kontext mittels
  `bind_space_area_transition_context`, prüft Kandidat und Owner-Epoche mit
  `validate_prepared_space_area_transition` und publiziert erst im Root-Tail
  mit `_publish_prepared_space_area_transition`. Die vorhandenen Fleet- und
  Root-Receipts binden Request, Operation, Schiff, Context und Owner; ein
  Replay darf keine zweite Deaktivierung oder Fuel-/Campaignbuchung auslösen.
- `enter_space_orbit` routet heute strategische Polisa-Abreise über
  `commit_singleplayer_station_orbit` und lokale Oberflächenrückkehr über
  `commit_singleplayer_local_return`. Ein expliziter **lokaler** Stationszweig
  benötigt denselben echten `preview_station_orbit_departure`-Pilot- und
  Visitbeleg sowie deren vorhandene Fuelquittung, aber eine vorbereitete
  lokale Flight-/Indexreaktivierung am Stationsgate. Er darf nicht bloß den
  strategischen `station_orbit`-Zweig ausführen. Für ein auf Polisa neu
  erworbenes Schiff ohne lokalen inaktiven Actor ist die erstmalige Admission
  gesondert an echte Visit-/Equipment-/Pilotowner zu binden; fehlt dieser
  Nachweis, bleibt diese Variante abgewiesen und der Legacyweg erhalten.
- Vor Commit abgebrochene Navigation ist ein lokaler Move-/Claimabbruch. Nach
  `begin_approach` verwendet ein Abbruch die bestehende schiffsgebundene
  Cancel-/Returnquittung und deren bereits bezahlten Abflug; kein pauschales
  Fuel-Rollback. Ein späterer Reapproach prüft Gate, Pilot und Ziel neu und
  verwendet den konkreten alten Abflugbeleg ohne erneute Routenbuchung.
- `space_area_grid.gd` ist bislang Bounds-only; Hindernis- und Claimswahrheit
  liegt bei `space_combat_state.gd`. Stationsblock und Körpermaske einmal pro
  Area/Layoutrevision aufbereiten und im bestehenden Index-/Claimsweg nutzen,
  nicht pro Bewegungstick oder in UI neu aufbauen. Root ergänzt ausschließlich
  für die passende Area im `get_space_area_snapshot`-DTO die lesbare Ziel-ID
  und Layoutrevision; daraus entsteht weder ein Auftrag noch eine Freigabe.

Die hier genannten Erweiterungen sind **geplant**, nicht bereits implementiert.
Vor dem ersten Codepaket den von Parent gelieferten Deskriptorstand übernehmen
und dessen Schema prüfen; keine Controller- oder AP6-Bodies berühren.

## Akzeptanz, Prüfung und Risiken

Kleine Layoutprobe: deterministische Revision/Koordinaten, Gate im Bounds und
frei von Stationsblock, Körper und Eintrittsband, keine Surfacezuordnung.
Anschließend gezielte Owner-/Adapterproben für erfolgreichen Anflug/Abdocken,
Abbruch, blockiertes Gate, fehlenden Piloten, veraltete Revision und Replay;
dabei R08-Pad-/Visit-/Crew-/Fuelbestand unverändert prüfen. Erst nach paarigem
Anschluss und gesondertem echten Boarding-/Spielweg-Nachweis Umschaltung prüfen.
Die vorgesehene Raumkartengeometrie ist ein technischer Startwert; sichtbare
Gestaltung und Spielgefühl sind noch nicht abgenommen.

Betroffene Dateien später voraussichtlich: neuer Layoutdeskriptor und kleiner
Verifier, `simulation_root.gd`, Fleet-/Travelowner und vorhandener Runtimeadapter.
Diese Skizze ändert keine Produktdateien.
