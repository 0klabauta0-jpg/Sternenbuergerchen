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

- **Anflug:** Der bestehende Movebefehl führt zum Dockgate; er erzeugt keinen
  neuen Docknavigationsjob und keine eigene Reservierungswahrheit. Ein späterer
  ausdrücklicher Dockcommit nennt Schiff, `target_id` und Layoutrevision.
  Root validiert aktuellen Glut-2-Area-/Flight-/Wingowner, Layoutrevision,
  vollständigen Schiffsfootprint, Gate- und Claimzustand sowie echte Pilot-/
  Crew- und bestehende Visit-/Pad-/Fuel-Voraussetzungen. Die Navigation bleibt
  beim bestehenden lokalen Flight- und Claimsowner. Erst am bestätigten freien
  Gate bereitet Root den vorhandenen Stationsbesuch und den Fleet-Übergang
  gemeinsam vor; alle Validierungen vor der synchronen Publikation. Retry mit
  gleicher Request-ID ist idempotent; Fehler verändern keinen Owner.
- **Abbruch:** Vor der Commitgrenze wird nur der vorhandene Moveauftrag beendet; Schiff,
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
  Für lokales Polisa wird ein separater Dockcommit mit eigener Stationsgate-
  prüfung vorbereitet; er darf nicht `preview_surface_deactivation` benutzen.
  Der Gameplayort bleibt `location_id=polisa`; der Kontext bindet zusätzlich
  `target_id` und Layoutrevision. Eine neue Fleetoperation
  `begin_station_dock` führt in die bestehende Visit-Übergangsphase `approach`;
  `finish_space_approach` und der Visit-/Padablauf bleiben erhalten.
  `preview_departure` und tatsächliche Wirtschaftskandidaten werden erneut
  gelesen; ein Navigationauftrag allein belastet weder Supply noch Campaign.
- `singleplayer_space_travel_state.gd::_prepare_space_area_transition_state`
  kennt bereits strategisches `begin_approach` für Polisa und den lokalen
  Oberflächenzweig. Die neue Operation `begin_station_dock` muss Glut-2-Area,
  Stationstarget und Gatebeleg prüfen; er darf `surface_location_id` nicht
  umdeuten. Fleet bindet denselben unveränderten Kontext mittels
  `bind_space_area_transition_context`, prüft Kandidat und Owner-Epoche mit
  `validate_prepared_space_area_transition` und publiziert erst im Root-Tail
  mit `_publish_prepared_space_area_transition`. Die vorhandenen Fleet- und
  Root-Receipts binden Request, Operation, Schiff, Context und Owner; ein
  Replay darf keine zweite Deaktivierung oder Fuel-/Campaignbuchung auslösen.
  Ihr Context enthält exakt `operation=begin_station_dock`, Schiff, Polisa,
  Ziel-ID, Layoutrevision und erwartete Ownerrevisionen; Dock-Request- und
  Context-IDs erhalten den eigenen Präfix `station-dock:`. Rückkehr erhält
  analog `undock_station` und `station-undock:`. Legacy-`begin_approach`-,
  `enter_orbit`- und Receipt-IDs werden weder umgedeutet noch wiederverwendet.
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
  `begin_station_dock` verwendet ein Abbruch die bestehende schiffsgebundene
  Cancel-/Returnquittung und deren bereits bezahlten Abflug; kein pauschales
  Fuel-Rollback. Ein späterer Reapproach prüft Gate, Pilot und Ziel neu und
  verwendet den konkreten alten Abflugbeleg ohne erneute Routenbuchung.
- `space_area_grid.gd` ist bislang Bounds-only; Hindernis- und Claimswahrheit
  liegt bei `space_combat_state.gd`. Stationsblock und Körpermaske einmal pro
  Area/Layoutrevision aufbereiten und im bestehenden Index-/Claimsweg nutzen,
  nicht pro Bewegungstick oder in UI neu aufbauen. Root ergänzt ausschließlich
  für die passende Area im `get_space_area_snapshot`-DTO genau
  `dock_targets:[{target_id:"polisa_station_dock",revision:"polisa_glut2_dock_v1"}]`,
  sobald der statische Block-/Gatevertrag dort tatsächlich gilt. Keine Gate-
  koordinaten als Befugnis: Root prüft tatsächliche Flight-/Footprintpräsenz.

Die folgende Statusangabe unterscheidet implementierte Ownerpfade von noch
ausstehender Integration und Spielwegabnahme; keine Controller- oder
AP6-Bodies wurden in diesem Paket geändert.

Stand: Der geprüfte Deskriptor ist selektiv übernommen. `space_area_grid.gd`
cached dessen Glut-2-Stationsblock einmal und wendet ihn auf lokale Bounds-/
Footprint-/Claimprüfungen an. Eine enge Prüfung für Block, freies Gate, andere
Area, unveränderliche Projektion und echte Claimvalidierung ist grün.
Fleet und Travel bereiten jetzt getrennte `begin_station_dock`-/
`undock_station`-Kandidaten mit Ziel- und Layoutbindung vor; ein isolierter
Owner-Test deckt Phasenwechsel, ungültige Revision und Replay ab. Der Test
setzt den lokalen Flightzustand als Fixture; Root-, Boarding-, Fuel- und
Adaptertransaktion sind noch nicht angeschlossen oder dadurch nachgewiesen.
Root kann das tatsächliche Stationsgate nun lesend anhand von Flight-, Travel-,
Area-, Wing-, Index- und Claimrevisionen prüfen. Die Probe deckt Gatepräsenz,
fehlende Gatepräsenz und veraltete Revision ab. Sie autorisiert keinen Besuch.
Eine weitere lesende Vorstufe validiert die Flight-/Indexdeaktivierung am
Stationgate. Der getrennte Dock-/Undockpfad verbindet inzwischen vorhandene
Root-/Fleet-/Flight-/Supply-/Campaign-Owner, schiffsspezifische Token,
Abbruch, Wiederanflug und verzögerte Ereignisse. Public-Adapterauftrag:
`space_begin_station_dock` mit `craft_id`, `location_id=polisa`,
`target_id=polisa_station_dock`, `layout_revision=polisa_glut2_dock_v1`
und optionaler `request_id`; Rückweg über vorhandenes `enter_space_orbit`.
Root-AreaDTO: `dock_targets` mit Ziel-ID und Revision. Eine begrenzte
Ownerprobe prüft Abbruch, Wiederanflug ohne zweite Hinbuchung, Pilot fehlt,
belegtes Gate, Rückflug-Fuel und Replay/Events. Pilot und Visit sind darin
Fixtures: echter Stationsbesuch, AP6-Boarding, UI und native Abnahme offen.
Neu auf Polisa erworbene Schiffe ohne eigenen inaktiven Spaceactor bleiben
ausdrücklich außerhalb dieses Pfades. Kein Flag- oder Live-JSON-Wechsel.

Für einen lokalen Kauf gibt es zusätzlich die lesende Rootvorprüfung
`preview_station_purchase_local_admission`: Sie bindet echten Supplykauf,
Stationsvisit-/Pilotguard, Equipmentprofil, Flight-/Fleetowner, Pflichtrotte
und freien vollständigen Footprint am Stationsgate. Die kleine Kaufprobe nutzt
echte Kauf-/Equipment-/Travelowner und Pilot-/Flowfixtures und prüft auch
fehlenden Piloten, fremden Besucher und ein belegtes Gate. Es werden weder
Flight noch Index, Rotte, Fuel oder Reise publiziert. Der explizite Adapter-
Ownerpfad `enter_purchased_station_local_orbit` bereitet inzwischen Flight,
Index, Fleet, Pflichtrotte und Rückflugfuel gemeinsam vor und publiziert sie
atomar; sein Replaytoken leitet sich vom echten Kaufbeleg ab. Die enge
Kaufprobe prüft blockiertes Gate, Aufnahme, Fuel, Rotte, Replay und Events.
Der Legacy-Start wählt diesen Pfad noch nicht; UI-Integration und echter
AP6-Visitnachweis bleiben offen.

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
