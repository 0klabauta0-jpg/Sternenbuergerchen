# Polisa: lokale Schiffsabholung

Status: auf b67b307b0 implementiert und begrenzt integriert/geprueft. Additive Tactical-Schiffs-/Pad-/Crewbereiche wurden vom Tabletop-Chat freigegeben, seine Move/Root/Ground/Actorbereiche blieben unangetastet. Heimat-Rueckkehrpad bleibt reserviert. Vertrag polisa_local_ship_pickup_contract.md; gemeinsame QA polisa_local_pickup_integration_20261111. Native Gesamt-/Presence-/Saveabnahme weiter offen; kein Main/EXE. Der Bewegungsquellchat schliesst seine gesicherten AP5-Schritte separat ab.

## Problem / Ursache
Der echte Stationskauf liefert Cutlass/Buccaneer heute auf ein gebautes freies Heimatpad. Lokale Abholung braucht dagegen ein reales geparktes Schiff, lokale Personen, einen legitimen Abflug und spaetere Heimkehr. Fulfillment setzt derzeit homebase; Travel.register_craft beginnt grounded; authorize_return und Servicekontext erwarten einen Heimat-Ausflug mit Campaigndeparture und Outboundtoken. Stationaere Geburt besitzt diese Vorgeschichte nicht. Kaufbelegvalidator und Checkpointrekonstruktion akzeptieren nur Heimatlieferung.

## Scope / Nicht-Ziele
Nur vorhandene Cutlass/Buccaneer lokal am vorhandenen Polisa-Root erwerben, auf freiem kompatiblem Pad aufnehmen, echte lokale Crew/Pilot eindeutig zuweisen/boarden, regulär abfliegen und zur Heimat bringen. Bestehende Supply-, Travel-, Location-, Tactical- und SimulationRoot-Owner weiterverwenden. Verbindlicher Minimalumfang: bei Kauf weiterhin ein gebautes freies Heimatpad als Rueckkehrpad reservieren; lokale Erwerbspad-ID und Heimatpad-ID sind getrennte Fakten. Der vorhandene Heimkehr-/Saveanschluss bleibt erhalten.

Kein neues Reise-/Personensimulationssystem, keine UI-only Lieferung, keine neuen Fahrzeuge/Modelle, kein Schiffswaffen-/Komponenten- oder Warpumbau, kein Stationslookdev. Checkpoint bleibt all_grounded und homebase/waiting_pad, ohne aktive Transfers; Away-Saves werden nicht freigegeben.

## Belegte Padfakten und Koordinatenpfad
Quelle: art/polisa_r08_20261111/author_layout.py:39-42 erzeugt IDs/Center/Size/Class und Aliase; :48 verknuepft spawn_alpha und ship_return mit polisa_pad_01, spawn_bravo mit polisa_pad_05. Aktuelle Daten sind layout.json und layout_compiled.json. data/singleplayer/locations.json fuehrt dieselben sieben landing_pad_ids. maps/polisa_station.json enthaelt bereits ALLE sieben gleichnamigen Marker, nicht nur spawn_alpha.

| ID / Alias | Klasse | lokales Center (x,z) | Deckgroesse |
| --- | --- | --- | --- |
| polisa_pad_01 / B_M1 | M | -29,30 | 12x12 |
| polisa_pad_02 / B_M2 | M | -15,30 | 12x12 |
| polisa_pad_03 / B_L3 | L | 0,36 | 16x24 |
| polisa_pad_04 / B_S4 | S | 14,27 | 8x6 |
| polisa_pad_05 / B_S5 | S | 24,27 | 8x6 |
| polisa_pad_06 / B_S6 | S | 14,35 | 8x6 |
| polisa_pad_07 / B_S7 | S | 24,35 | 8x6 |

build_candidate.py:28-29 addiert origin_plane=[0,-70]. :59-63 snappt diese Weltplaneposition auf die naechste begehbare Hexzelle und schreibt deren Isoposition x=(plane_x-plane_z)*64, y=(plane_x+plane_z)*32 als Mapmarker. Beispiel polisa_pad_01 im aktuellen Produktmap: (693.5787887413871,-2202.7893943706936); polisa_pad_03: (2129.599407845959,-1096.7997039229795). Runtime muss MapData.get_marker_position(pad_id) lesen statt diese Zahlen oder unsnapped lokale Center zu duplizieren. Layoutklasse/Deck-/Reservegroesse sind reine gemeinsame Daten, keine Belegungswahrheit. Aktueller Controller _get_authored_campaign_pad_position liest nur spawn_alpha; der fehlende Anschluss ist die Mehrpad-Auswahl/Reservierung beim lokalen Tacticalowner. R08 reserve_envelope ist nur Artreserve, noch keine bestaetigte Cutlass-/Buccaneer-Kompatibilitaet.

## Owner / betroffene Anschlussdateien
- scripts/core/singleplayer_supply_state.gd: Credits, endlicher Bestand, Fuel/Craftcontainer, idempotenter Kaufbeleg; _station_buy_ship:664, validate_station_receipts:712.
- scripts/meta/singleplayer_runtime_adapter.gd: autorisierter synchroner Kauf-/Service-/Routeadapter; _fulfill_polisa_ship:1023, _service_context:403, authorize_return:514, _home_pad_for und Checkpointexport. Kein versteckter UI-State.
- scripts/core/singleplayer_fleet_travel_state.gd und singleplayer_space_travel_state.gd: vorhandener indexierter Reiseowner; register_craft:10 startet heute grounded, _launch:113 fuehrt zum Mondorbit. Neue autorisierte Surfaceinitialisierung direkt polisa, keine erfundene Reise.
- scripts/meta/meta_layer_flow.gd: vorhandene Craftdefinitionen, _craft_location_runtime, _bind_location_visit, _admit_existing_location und reale Abflug-/Heimkehrbridges. Kein neuer Root, keine Doppeladmission von Personen.
- scripts/tests/mission_tactical_sandbox_controller.gd: reale geparkte Card/Sequence, Padreservation, assign_campaign_pilot:13670, request_campaign_crew_boarding:13715, retire_location_craft_visit. Produktlegacy nur nach Ownerfreigabe anfassen. SimulationRoot bleibt Embark-/Presence-Commitowner.
- scripts/mission/*command_contract.gd nur passende neue Operationen/Validierung; optional kleiner reiner gemeinsamer Padfaktenhelper. scripts/core/singleplayer_campaign_state.gd nur bei bewusst erweitertem echten Herkunftsvertrag, nie Fake-Heimatdeparture.
- scripts/meta/campaign_checkpoint_store.gd: bestehende home-only-Pruefung und Kaufbeleg-/Fleetrekonstruktion; scripts/ui/polisa_station_screen.gd und data/singleplayer/polisa_station.json erst nach Backendanschluss. Bestehende Orts-/Layoutdaten wiederverwenden, keine neue Geometrie.

## Umsetzungsschritte
1. Datenvertrag und Dateibesitz abstimmen: Kauf-ID, Craft-ID/Modell, Erwerbsort/-pad, reserviertes Heimatpad, lokale Herkunft/Abflugbeleg, Crew-/Pilot-IDs, Fireteams. Alte Heimatlieferbelege erhalten expliziten Legacydefault.
2. Reine Padfakten gegen aktuelle Mapmarker validieren; lokalen Tacticalowner um freie kompatible Padreservation und echte stationaere Craftaufnahme erweitern. Bestehende Cards/Sequences/Parkpositionen und belegte Feldlandungen mitpruefen.
3. Bestehenden Travelowner um vertrauenswuerdige idempotente stationaere Registrierung surface/polisa erweitern; Fuel/Container beim Supplyowner registrieren. Alle gueltigen Voraussetzungen pruefen, bevor Flotte, Belegung, Geld oder Bestand mutieren. Bei Fehlern keine halbe Lieferung.
4. Vorhandenes Fulfillment mit realer lokaler Aufnahme verbinden. Kauf startet unbemannt; weder Pilot noch Crew werden erfunden. Besuchsidentitaet darf keinen fremden Auftrag erwerben. Explizite Serviceschiffwahl bleibt UIChoice.
5. Eindeutigen lokalen Crew-/Pilot-Handoff zwischen realen Schiffen/Boden und Besuchsidentitaeten anschliessen. Bisher betrachtet Boarding den ganzen Orts-Sortiepool, optional Fireteam; assign_campaign_pilot verhindert keine Doppelzuweisung. Zugehoerigkeit/Kapazitaet und lebende UnitRegistry-/SimulationRoot-Präsenz prüfen, vorhandene Embarkeffekte verwenden, source und target atomar konsistent halten.
6. Echten lokalen Abflug-/Heimkehrvertrag anschliessen: vorhandene Park-/Pilot-/Crewgates, Surfaceexit, Treibstoff und Retire nutzen. Keine Heimat-Outboundbelege erfinden. authorize_return und _service_context muessen stationaere Herkunft legitim lesen. Primaerauftrag eines anderen Besuchs unveraendert lassen.
7. Versionierten Erwerbsbeleg validieren und am spaeter erlaubten Heimatcheckpoint rekonstruieren. Erwerbspad darf nach Abflug wieder frei werden; Beleg ist kein dauerhafter Belegungsowner. Alte Heimatlieferung bleibt kompatibel. UI lokale Option erst anbieten, wenn alle Owner angeschlossen sind.

## Akzeptanz / kleine lokale Prueffaelle
- Freies kompatibles Pad: ein echtes geparktes Schiff im selben Root, surface/polisa, endlicher Bestand/Geld genau einmal. Wiederholung derselben Request-ID liefert denselben Craft ohne zweite Mutation; Konflikt-ID wird abgewiesen.
- Volles/unpassendes Pad, fehlender Owner/Marker, veralteter Serviceintent oder fehlendes Heimat-Rueckkehrpad: keinerlei Abbuchung/Flotten-/Container-/Padhalbzustand.
- Reale vorhandene Person uebernimmt Pilot-/Crewrolle genau eines Schiffs; keine Doppelactors, Doppelpilot- oder Doppelbesuchszuordnung. Andere Crew/anderer laufender Ort bleibt erhalten. Ungueltiger/toter/entfernter Pilot und fehlendes Boarding blockieren realen Abflug.
- Abflug/Heimkehr nutzt echte lokale Herkunft, genau eine Fuelabbuchung pro bestaetigtem Abschnitt, korrekte zugehoerige Crewretire-/Rueckkehrdaten. Kein erfundener Heimat-Outboundtoken; keine fremde Auftragsmutation.
- Heimatcheckpoint bleibt waehrend stationaerer Anwesenheit/Transit gesperrt. Nach echter Heimkehr bleiben alter Heimatlieferbeleg und neuer lokaler Erwerbsbeleg ladbar; manipulierte IDs/Pads/Modelle/Doppelbelege werden vor Mutation abgewiesen.
- Nur winzige Owner-/zwei-Craft-Fixtures und betroffene Compilepruefungen nach Implementierung. Native Mehrortreise/Bedienung, groessere Gefechte, Save-/Netz-/Performanceabnahme spaeter.

## Risiken / offene Punkte / aktueller Pruefstand
Crew-/Pilotzuordnung ist der kritische Lifecycleanschluss, keine reine Kaufansicht. Padklassen brauchen bestaetigte Modellkompatibilitaet. Kaufcallback muss ohne await und nach vollstaendiger Vorpruefung committen oder sauber rueckrollen. Stationaere Herkunft und Belegmigration muessen gemeinsam mit Root/Tabletop abgestimmt werden. Reserviertes Heimatpad ist der bestaetigte Integrationsumfang. Nur Readonly-Quellenpruefung/JSON-Auszug und Dokumentationsdiff; keine Produktedits, Tests oder Commits in diesem Auftrag.

## Tactical APIplanung auf b67b307b0
Geplant additive Controlleroperationen preview_station_craft_admission(craft_definition,requested_pad_id='') und admit_station_craft(craft_definition,pad_id,request_id). Preview liefert gepruefte echte Mapmarkerposition, PadID, Modell-/Footprintfakten und Ownersignatur. Commit revalidiert vor allen Mutationen und fuegt unbemannte COMPLETE-Parallelsequence plus echte Card hinzu, kein Personenspawn/Setupreset. Kein planning_state_changed oder fremdes Runtime-Signal vor konsistenter Flowzuordnung; Root fuehrt danach die explizite Projektion/Benachrichtigung aus. Request-ID-Replay muss dasselbe Schiff liefern, Konfliktreplay und Padrennen vor Mutation ablehnen.

Handoff preview_station_crew_handoff(source_craft_id,target_craft_id,unit_ids,pilot_id,trusted_membership) und commit_station_crew_handoff(...,request_id,trusted_membership). Root liefert aktuellen vertrauenswuerdigen Flow-Visitmembership-Snapshot; keine UI-Zuordnung als Autoritaet. Nur echte lokale deployed/lebende Personen werden zwischen Source/Target neu zugeordnet, eindeutiger Pilot und reale Kapazitaet. Keine Bewegung/Teleport/Embarkmutation im Handoff; danach bestehendes echtes Boarding zum Target nutzen. Flow committed denselben Membershipwechsel vor Signals. Bestehender SimulationRoot bleibt Presenceowner.

Footprint muss aktuellen Produktpfad abbilden: terrain_map_3d_view._add_dropship_proxy skaliert aktuellen FRONTIER role-dropship auf Catalogscale und _get_dropship_rotation_y_for_payload; _world_to_3d_position projiziert world->gridfloat->Hexplane mal aktuelle _get_3d_cell_size. Deshalb zur Layoutplane vergleichen: gerenderte Bodyausdehnung geteilt durch aktuelle cell_size, gedreht um tatsaechliche Landeyaw und versetzt um gesnappte Markerabweichung. Catalogbounds allein ohne View-/Gridmaß reichen nicht. Der allgemeine Dropshiprenderer nimmt derzeit role dropship (Cutlass) unabhaengig Craft.model_id; konservative Aufnahme muss den wirklich gerenderten Koerper einschliessen, auch fuer Buccaneer, solange kein gesonderter Rendereranschluss freigegeben ist. Keine SC-Realgroessen, keine Artreserve als Kompatibilitaetsbeweis. Heimat-S8x6 bleibt Nutzerreferenz.

## Aktueller Tactical-Kandidat nach Ownerfreigabe
Root hat additive Controller-Crew-/Padbodies und engen Primary3D-Identitaetsreader freigegeben; keine Root/Ground/Driver/Actor-/Movement-/Facingbodies angefasst. Neuer reiner Helper scripts/mission/polisa_station_craft_runtime.gd, Produktanschluss im bestehenden Tacticalcontroller und terrain_map_3d_view.gd. Kapazitaet verbindlich Cutlass8/Buccaneer1, jeweils inkl. Pilot. Admission und Handoff sind request-idempotent und emit-free; finalize_station_craft_update ist der gesonderte Publish nach konsistentem Flow/Travel/Supplycommit.

Handoff normale Operatoren nur als vollstaendige Fireteams gegen ALLE ortslokalen Actors. Bekannter Sourcepilot darf trotz temporaerer ft1-Actorsortierung einzeln wechseln. Retire loescht vorhandene Teamplaene nur, wenn nach Ausschluss der abreisenden IDs kein weiterer deployed/embarked lokaler Member diesesTeams bleibt. Keine Actorfireteam-Umschreibung, kein Handoff-Teleport/Embark. Flightguard/Boarding/Deployment/Extraction lesen jetzt exakte Craftvisitcrew statt ganzen Ort; Boarding aktualisiert eigene Parallelsequence, vorhandener Effectadapter queued echte Presenceeffekte.

Catalogmodellidentitaet model_id/craft_type/visual_asset_id wird durch Card-Sanitizer und VisualEntry zum bestehenden Renderer gegeben, Buccaneer bleibt vorhandenes Buccaneermodell. Bodyprojection liest denselben Catalogscene-/Scale-/Yaw-/Cellsizepfad und zentriert AABB wie _normalize_asset_model_instance. Aktuelle Bodyfitpruefung ist getrennt von immutable receipt_pad_compatible Rev1 (beide Ref03modelle in allen7R08Pads bei historischem Catalogmaßstab/1.0Cellsize belegt); historische Kaufbelege haengen nicht von heutiger Belegung ab.

Kleine Produktprobe output/native_glut_maps/polisa_local_pickup_20261111/controller_fixture.gd:23/0 mit echter R08MapData+TerrainRegistry+Primary3D-Reader, zwei geparkten Ownercards/Sequences, Actors und echtem Effectadapter. Simulation/Presencecommit sind begrenzte Fixtureowner; keine echte komplette Reise. Reiner Helper27/0 inkl. Catalogdateihashes und beide Modellhuellen bei360Yaw auf allen7Pads. Admission/Replay/Padbelegung, tempft1-Pilotwechsel, exactCrew, Pendingpresence, Buccaneerprojection und Erhalt zurueckbleibender ft1Plaene geprueft. Kein Commit/Push; Root integriert Flow/Backend separat. Keine native/GPU-/grossenTests.


Review-Folge: Handoffsnapshot filtert Craftkarten auf aktuelle trusted_membership.keys. Historische ready-Heimkehrkarten sind keine lokalen Pilotenbesitzer. Zusaetzlicher echter Controllerfall mit historischer C.ready-Karte und gleicher Pilot-ID bestaetigt legitimen Source->Target-Handoff:24/0, Controllercompile erneut sauber.


Rawassign-Reviewfolge: assign_campaign_pilot ignoriert historische ready-Aliaskarten ohne aktiven geparkten Ortsbesuch. Eigene exactCrew bleibt erforderlich; eine frisch aufgenommene Stationskarte ohne publizierten Visit ist leer und darf nicht Legacy-Gesamtsortie erben. Zusaetzlicher eigenerPilot-/fremderCrew-Check:26/0 aktuelle Controllerprobe, Compile sauber.

## Kleine Vertikalprobe und Modusflag-Delta
Aktuelle Vertikalprobe vertical_fixture.gd verbindet echten Flow/Adapter/SimulationRoot/Supply/Travel/Equipment/BasePersonnel mit Tactical/R08Map/Registry/Modelreader:10/0. Initialer Sourcebesuch, Actors und remote Base._states sind kontrollierter Fixtureaufbau; echte Kauf-/Visit-/Handoff-/Basebinding-/Boardingmethoden laufen zusammen. Handoff bewegt niemanden; erst explizite Fixtureplatzierung am Target erlaubt echten Rootqueue-Embark nur fuer den uebertragenen Piloten. Presencegrenze queued_not_committed, keine echte Bewegung/Heimkehr-/Gefechtsabnahme.

Dabei Modusflag-Bypass eng korrigiert: get_campaign_pilot_flight_guard und request_campaign_crew_boarding ueberspringen station_pad_id/local_station_purchase-Craftpflicht nicht mehr, wenn campaign_ground_pilot_id fehlt. Alte Nichtstationspfade bleiben wie zuvor. Probe laeuft absichtlich ohne Campaignmarker und blockiert unbemanntes Stationsschiff. Controllercompile erneut sauber; keine weitere Produktmutation in diesem Folgeauftrag.

## Legacy-Root-Commit und kleiner Heimkehranschluss
Separate vertical_return_fixture.gd/.log:18/0. Reale BasePersonnelbindung als Adapterkind plus vorhandenes SimulationRoot.configure_base_personnel, damit Ownercompleteguard tatsaechlich mitprueft. Vorhandenes Legacy _process_effects committed genau den Pilot-Embark (Meta/Visibility); exactFlightguard wird bereit, Sourceoperatoren bleiben deployed. Danach echter Adapter return_homebase, vorhandener Surfaceexit-/Flowretirementendpunkt, Root-bound Warp und echte HomeLanding: Base._unit_is_home nur fuer uebertragenen Piloten true, zwei Operatoren weiterhin away. Keine Produktbodies fuer diese Folge geaendert.

Grenze ausdruecklich: Surfaceexit/Retirementendpunkte werden im Fixture explizit aufgerufen, keine Abfluganimation bis zum Exit oder automatische Framecallbackkette simuliert. Kein Walking-/Flug-/Native-/Save-/Gefechtsbeleg. Root-Embark/Deploybodies unveraendert Tabletopbesitz. Vorherige10erLogs bleiben archiviert; vertical_queued_original.gd sichert deren alte Quelle. Aktuelle18erQuelle benutzt korrekte echte Baseownerbindung.


Aktueller kanonischer Vertikalbeleg: NUR output/native_glut_maps/polisa_local_pickup_20261111/vertical_return_fixture.gd + vertical_return_fixture.log,18/0 im echten verbundenen Ownerpfad inkl. LegacyPresencecommit und expliziten Heimkehrendpunkten. Fruehere10/14Quellen/Logs sind historische Entwicklung, keine aktuellen Abnahmetargets. CURRENT_ARTIFACTS.txt/README/SHA256SUMS und vertikale Ownersourcehashes benennen Stand/Grenzen; Root fuehrt frisch18er + separateFlow/Backendpruefung aus. Finalfreeze, keine weitere Probe/Produktmutation.
