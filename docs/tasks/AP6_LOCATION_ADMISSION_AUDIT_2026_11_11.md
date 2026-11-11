# AP6: Ortszulassung, BasePersonnel und Polisa-Besatzung

Status: Readonly-Anschlusshilfe, keine Produktedits/Tests/Commits. Parent beim Read
e8d108aa2; Tabletopquelle C:/dev/SternenBuergerchen-worktrees/hex-ground-foundation-
20261111 beim Read e4c098f63, AP6-Embark/DeployBatch noch geplant. Source-WIP nicht
übernommen. Übergeordnet: hex_tactical_runtime_contract und aktueller Polisa-Vertrag.

## Identität und tatsächliche Owner
- Personenschlüssel bleibt dieselbe unit_id aus bestehendem Roster. Supply besitzt
  Container unit:<id>:backpack/Inventar; Loadoutowner und vorhandene Profile behalten
  Ausrüstung/Skills. AP6 erzeugt weder neue IDs noch kopierte Inventare/Piloten.
- BasePersonnelRuntime besitzt _states, Basewege/-betten/-aktionen und remote
  Transportbindung. Er baut BaseTerrainRegistry und BaseUnitRegistry und registriert
  BasePersonnelActor bei seinem MetaRoot. BasePersonnelActor ist nur Node2D mit
  unit_id und Loadoutprojektion, kein voller MissionsNPC/HexActor; kein eigener
  Healthbestand (get_vital_state fit ist kein bestätigter Missionszustand).
- Baseposition bleibt im Actor gespeichert, auch wenn die Person weit weg ist.
  Snapshot projiziert dann status away über _unit_is_home; _states.status aboard
  bezeichnet remote Ausflugsschiffsbindung, NICHT tatsächliches Sitzen auf Polisa.
  BasisActor-/Registrypräsenz beweist daher keine aktive Hexbelegung am Missionsort.
- MissionSetup + Ortsroot besitzen tatsächliche MissionsNPCs, UnitRegistry und
  bekannte Unitlookupobjekte; Tactical hält deployed-/embarked-/Card-/Sequence-
  Projektionen. Groundowner soll ausschließlich deren tatsächliche Bodenbelegung
  und Bewegung besitzen. Beide Actorrepräsentationen dürfen dieselbe Personen-ID
  tragen, aber niemals zwei aktiv simulierende Hexpositionen für dieselbe Person.

## Konkrete vorhandene Übergabepfade im Parent
1. Heimatboarding: BasePersonnel._board_team enthält echten Pilot+Crew, validiert
   jeden Baseweg, wartet auf Ankunft, ruft bestehenden _request_operation_from_base
   board und beobachtet _are_homebase_payload_fireteams_boarded. _states werden
   erst danach aboard. Basebewegung läuft per BaseRoot.enqueue_command; Baseowner
   konfiguriert derzeit NICHT configure_hex_ground_runtime. Nicht blind auf NPC-
   Hexadmission umstellen oder registrierte BasisActor pauschal als BodenNPC zulassen.
2. Missionsaufnahme: Flow._admit_existing_location bindet genaue incomingVisitIDs,
   erweitert Setupconfigs/loadouts und ruft apply_runtime_selection_contract(true,
   incoming_units). Bestehende Orte/Actors anderer Schiffe werden behalten, nicht
   neu aufgebaut. AP6 muss den fertigen Actor zu dieser ID aus diesem Root/Registry
   lesen; kein Reparenting der BasisNode und keine Vollneuaufnahme der Ortscrew.
3. Deploy: request_campaign_crew_deployment bestimmt ausschließlich _campaign_craft_
   crew; _deploy_next_embarked_unit_for_sequence setzt derzeit Controllerdeployed-
   Projektionen und queued dropship_deploy_unit. Root resolve_known_unit setzt Meta,
   runtime_active Registry/Leader/FTLbindung, Position/Visibility/Status. Das ist die
   künftige AP6-Gruppenadmissionsgrenze, nicht ein zusätzlicher UI-Schritt.
4. Embark: request_campaign_crew_boarding prüft echtes eigenes Crewset, lebenden
   Actor, Schiff geparkt, Distanz CAMPAIGN_BOARDING_RADIUS und Pendingeffects.
   Danach queued er bestehende Embarkeffects und aktualisiert Card/Sequences.
   Root setzt dropship_embarked und versteckt denselben Actor. AP6 soll hier
   aktuelle Groundbewegung/Belegung/Claims lösen, nicht Person oder Lookup löschen.
5. Extraction: request_campaign_extraction erstellt echten Rückwegauftrag;
   _advance_campaign_extraction wartet auf vorhandenes Boarding/Pending. Kein
   Kamera-/Viewwechsel und kein bloßer Cardstatus darf Distanz-/Presencegates ersetzen.
6. Surfaceexit: Flow._finish_space_surface_departure nimmt genau die unit_ids des
   eigenen Visits und ruft retire_location_craft_visit nach bestätigtem Travelcommit.
   Retirement entfernt nur diesen Craft-/Crewkontext. Geteilte Fireteamrestcrew am
   Ort bleibt aktiv, auch bei Solo-Pilotabflug. Keine globale Clearfunktion einsetzen.
7. Homecoming: _finish_space_home_landing arbeitet mit zurückkehrendem Missionsort,
   bestehender Transport-/Loadoutprojektion und echter Reise-Heimlandung. Base-
   _unit_is_home erfordert zugehöriges Schiff homebase ohne Pending + grounded.
   Fernaktorposition niemals als Baseposition/Spawnkoordinate zurückschreiben.

## Polisa-Handoff: erhaltene wichtige Korrekturen
Flow.handoff_polisa_station_crew validiert Replay, beide realen lokalen Craftvisits,
Pendingzustand, globale Pilot-Eindeutigkeit, exakte Quellenmitgliedschaft und
Tactical.preview_station_crew_handoff. Personen müssen echte lebende deployed
MissionsNPCs ohne Embark/Deployeffekt sein; Capacity Cutlass8/Buccaneer1. Ganze
Fireteams bleiben zusammen, vorhandener Sourcepilot darf über bekannten engen
Pilot-Solo-Ausnahmevertrag wechseln. Kein allgemeines Split-/Teleportrecht.

Vor finalem Controllercommit wird der lebende gebundene BasePersonnelOwner über
validate_remote_craft_handoff geprüft. Danach folgen emitfrei Controllercommit,
BasePersonnel.commit_remote_craft_handoff, Visits mit parallelen unit_ids/fireteam_ids
und globales Pilotenmapping; erst dann Finalizesignale. Basecommit verändert NUR
remote craft_id, keine Positions-/deployed-Wahrheit. Dies verhindert den früheren
Fehler: tatsächliche Rückkehr im neuen Schiff, aber Basiszustand noch am Sourcecraft
und damit weiterhin away. AP6 darf diesen Schritt nicht durch eigenen Crewstore ersetzen.

Handoff zwischen zwei Schiffen auf DEMSELBEN Stationsdeck ist selbst KEIN Deploy,
Embark oder Ortswechsel: dieselben NPCs/Hexzellen/Bewegungen bleiben erhalten.
Erst ausdrückliches Einsteigen am Ziel darf Groundpräsenz lösen. Keine zweite
Hexadmission oder Teleport zum Zielpad durch reine Crewneuzuordnung.

Historische campaign_ground_pilot_id ist Legacy-/Szenariomarker, niemals aktueller
Pilotowner. Eigene Card.pilot_unit_id und echter Visit/Crewset/Actor/Pendingeffect
sind entscheidend. stationäre unbemannte Schiffe auch Noncampaign brauchen echten
Pilot-/Crewguard. Bereits repariertes _campaign_craft_crew_ids: vorhandene Visits
aber eigener Visit fehlt => leer, kein Rückfall auf gesamten Sortiepool. Ebenso
fremde Primaryjob-/Pilotenmetadaten beim zusätzlichen Schiff nicht übernehmen.

## AP6: kleinste koordinierte Rootgrenze
- Tabletopsource hat bereits Ground.admit_units(placements) als ganze Gruppe und
  Ground.release_unit sowie Root.admit_hex_ground_units/release_hex_ground_unit.
  Bestehende dropship effects sind noch Einzelwrites, KEIN fertiger DeployBatch.
- DeployBatch muss alle echten Actoridentitäten, lokalen Root/Registry, Map-/Terrain-
  Revision, eindeutige unit_ids, freie/gehbare/claimfreie Zielhexes, logische Höhe/
  Facing und komplette Gruppe vorbereiten. Bisherige LZ-Weltoffsets sind Kandidaten,
  keine zulässigen Groundzellen. Kein Teildeploy, wenn nur ein Ziel blockiert ist.
- EmbarkBatch prüft ganze konkrete Crew/Pending/Distanz und aktuellen Groundstand;
  dann Reservations-/Movement-/Occupancyrelease und Actorpresence gemeinsam.
  UnitRegistry/Rootknownlookup dürfen das NPCobjekt für Boarding/Equipment/Rückkehr
  behalten; Groundrelease ist kein endgültiges Entfernen der Personenidentität.
- Controller darf committed deployed-/embarked-Projektionen erst aus tatsächlichem
  Rootresult/Effectcommit übernehmen. Seine heutigen Queue-vorher-Projektionen
  dürfen bei AP6-Reject nicht als erfolgte Gruppenadmission stehenbleiben.
- Release/Retire darf nur tatsächliche lokale Hexteilnehmer dieses Visits betreffen;
  Baseprojektionen, ferne Actors und verbliebene Teammitglieder nicht freigeben.
  Alle Revalidierungen vor erstem Write, dann synchrone Publication/Finalizes.

## Besitz / spätere Prüfung
Tabletopsource besitzt Ground-/RootEmbark/DeployBatch und Actor-/Presenceanbindung.
Parent besitzt Flow/PolisaVisit-/BaseTransport-/Basepositionadapter, abgestimmt,
nicht als parallele Rootimplementierung. UI bleibt Auswahl+Commandprojektion.
Später klein prüfen: zweiCrafts/einOrt, Basisprojektion remote, SoloPilot/Restteam,
Missingownvisit failclosed, belegte Deployzelle ganzerBatch reject, echte Boarding-
Release+ReDeploy derselben MissionactorIDs und Rückkehr im Zielcraft. Keine Tests
in diesem Audit, keine behauptete AP6-/Native-/Multiplayerabnahme.
