# Gemeinsame Orbitkarten: Readonly-Schnittstellenaudit

## Auftrag / Quellenstand
Nur Audit/Notiz, keine Produktedits, Tests oder Commits. Native Integrationsbasis
ec5bf93c0; Space-Worktree task/space-combat-implementation-20261111 unter
C:/Users/bjoer/.codex/worktrees/space-combat-plan-20261111/SternenBuergerchen.
Der zunächst gelesene SpaceHEAD war aa9177433 (Rootmeldung zuvor5748a9ce9).
SpaceChat änderte während des Audits SpaceWingState: ensure_flying_wings ist jetzt
vorhanden. Keine Aussage, dass diese laufenden Spaceänderungen hier integriert sind.
Gelesen: space_combat_contract, SPACE_ORBIT_WING_HANDOFF, existierende Reise-/
StrategicHexGrid-/StarSystemdaten und relevante Wing/Flight/Combat/Registry/Root APIs.

## Verbindliche Nutzergrenze
Strategische Sternkarte256x256 unverändert. EIN Orbitziel und EIN persistenter
lokaler512x256-Bereich je Stern/Planet/Mond, Warpankunft unten. Oben mittig rund256
Felder breiter, höchstens4Felder tiefer Körpersaum; Restkörper außerhalb. Anflug
zur Oberfläche erst am Saum, nur für geeignete Ziele. Raum ist für echte Blockaden
breit, kein Markerwahl-Bypass. Jedes fliegende Schiff inkl Dropship hat genau eine
1-bis6-Rotte, solo ebenso; kanonischer Owner bleibt SpaceWingState im SpaceChat.

## Bereits vorhandene APIs / Ownership
- Fleet.get_flight_state(craft_id) liefert im Spacebranch Travel.get_flight_state().
  Travel hält genau einen _flight:SpaceFlightState. Root.admit_space_actor für
  Player referenziert denselben Owner; keine neue lokale Simulationsinstanz nötig.
- Flight.configure/get_snapshot/bind_craft/commit_travel_pose/validate_motion/
  commit_motion tragen kontinuierliche planePosition, velocity, heading,
  angularVelocity, assist_mode, motion_mode und Revision/Tick. Noch KEINE area_id
  oder coordinate_frame; commit_travel_pose sperrt tactical statt sauberer
  expliziter areaTransition. Das muss SpaceChat erweitern, nicht KartenUI umgehen.
- Root.admit_space_actor, enter_space_tactical, commit_space_actor_motion,
  commit_space_fleet_motion und eigener Physiktakt sind vorhanden.
- SpaceCombatState hält Metadaten und referenziert Flight; SpaceShipRegistry
  indiziert diese Objekte aktuell nur nach cell, ohne Gebietstrennung.
- SpaceWingState ist alleiniger Mitgliedschafts-/Führungs-/Auftragsowner.
  Jetzt ensure_flying_wings(actor_id,flying_crafts,owned_crafts,pilots),
  reconcile_crafts sowie Command-Replay vorhanden. Atomare Flugaufnahme und
  vorhandene Legacy-/Enemy-/Neutral-Lifecycleverdrahtung mit SpaceChat abstimmen.
- Aktuelles NativeTravel._begin_approach prüft nur phase/orbit/Ortsbindung;
  NativeAdapter._in_destination_orbit ebenso. Raumpose/Saum fehlen vollständig.

## Kleinster gemeinsamer Interfacevorschlag (noch nicht implementiert)
1. Reiner Bodymapdescriptor get_orbit_area_definition(body_id):
   {schema_version,area_id:'orbit:<body_id>',body_id,grid_size:[512,256],
    coordinate_frame:'local_hex_plane',arrival_region,surface_rim,surface_links}.
   BodyID/AreaID/SternkartenOrbitID/SurfaceLocationID bleiben getrennt. Bodymap ist
   Daten-/Viewdefinition, kein zweiter Flight-/Wingowner. Eine geladene Area bleibt
   für alle Schiffe/Seiten desselben Körpers dieselbe; Ansicht ist kein Reset.
2. SpaceChat erweitert vorhandenen Flightsnapshot um space_area_id und
   coordinate_frame. Lokale Position bleibt HEX.axial_to_plane-Einheit,
   nicht Pixel/StrategicNormalized. Vorhandener Flight bleibt dasselbe Objekt.
   Root koordiniert prepare/commit_space_area_transition(craft_ids,target_area,
   entry,expected_revisions): Winginvariante, freie vollständige Footprints,
   bestehender Flight, Travelphase und Areaindex atomar zusammen umschalten.
   MapUI liest nur area-gefilterte Root/Flightprojektion und sendet bestehende
   Commands mit explizitem Area-/Revisionskontext; kein eigener Tick/Positionstore.
3. Root.preview_surface_approach(craft_id,location_id) liest echten Flight+Area+
   Footprint und Travelowner, liefert Gate/Reason + erwartete Flight/Area/Travel-
   Revisionen. Nur Root darf daraus autoritativen begin_approach-Kontext erzeugen;
   UI kann keinen amSaum-Beleg setzen. Root revalidiert denselben Stand beim
   verbindlichen Übergang. Vorhandene Pilot-/Payload-/Job-/Fuel-/LZgates bleiben.

Die genaue Methodennamenswahl liegt beim SpaceChat; diese Notiz benennt die
kleinste Datengrenze, keinen konkurrierenden neuen Owner.

## Konkrete Koordinaten-/256-Blocker
StrategicHexGrid.SIZE=(256,256), EXTENT=(256,221.70250336881628), contains nutzt
Offsetrechteck. Dieses Raster NICHT auf512 vergrößern: das würde Sternkarte,
Normierung und alle bisherigen Reisewege gleichzeitig umdeuten.
Betroffen im Spacebranch sind nicht nur Visuals:
- Root.admit_space_actor prüft SPACE_GRID.contains; Playerpositionmatch teilt
  position_plane durch StrategicEXTENT; Motioncommit indiziert denselben Weg.
- SpaceCombatState._occupied_cells und sync_moved_actors benutzen das256-Raster.
- SpaceNavigationResolver prüft world.blocked_cells und überstrichene Zellen
  per GRID.contains; SpaceCombatCommandContract prüft target_hex/path ebenso.
- SpaceShipRegistry._cells ist aktuell cell->craft ohne AreaID: identische
  Koordinate auf zwei Bodymaps würde Gegner/Belegung/Kollision vermischen.
- Travel._set_travel_pose multipliziert strategische Normposition mitEXTENT;
  lokales512Plane darf diesen Weg niemals verwenden. Im tactical-Zustand kann
  Travel._position weiter die alte strategische Position zeigen; sie ist kein
  zulässiger Saumbeleg und darf keine lokale Physicsposition überschreiben.

Nötig: separater lokaler Grid-/Boundsdescriptor im bestehenden Spacepfad,
gebietsgescope Indexschlüssel/Querys und world/command-areaID, nicht zweites
SpaceFlight-System. Reine Hexgeometrie kann geteilt werden, Grenzmaße nicht.

## Saum-/Ankunftsdetails vor Implementierung festlegen
Als klare Offsetkonvention wäre sichtbarer Saum x128..383,y0..3 möglich; das ist
nur der geometrische Vorschlag, noch kein zusätzlicher Nutzerwert. Renderkörper
und zulässiger Approachkorridor trennen: wenn dieselben Saumzellen solide blockiert
sind und Gate dort einen Anchor verlangt, wäre Anflug unerreichbar. Gate braucht
eine definierte erreichbare Saumkante/Anflugzone und freien vollständigen Rumpf,
keinen bloßen Mittelpunktcheck. Eine blockierende Rotte muss diesen Weg räumlich
verhindern können. Velocity/Orientierungsschwelle ist noch nicht festgelegt.

Ankunft unten für ganze Rotte mit freien Swept-/Mehrfeldfootprints verteilen;
keine Überlagerung aller Schiffe an einem Punkt. Volles Entrygebiet braucht einen
expliziten Pending/Failzustand statt Teleport an einem Blockader vorbei. Ein Gebiet
pro Körper, auch bei gleichzeitiger Ankunft mehrerer Flotten; Persistenz-/Sichtwechsel
ändert weder Actoridentitäten noch Wunden/Schilde/Orders. Mixed-area-Rottenorder und
staggered Arrival brauchen klare SpaceChatpolitik, keine UI-eigene Aufteilung.

## Reise-/Save-/Inhaltsrisiken
- StarSystem ist version2; ORBITS enthält5Körperorbits, sun hat KEINENOrbit.
  Neue Vorgabe braucht ausdrücklich auch Sunorbit/Bodymap ohne Surfacefreigabe.
  Aktuelle _valid_definition verlangt exakt ORBITS und genau3Eckmarker pro Orbit;
  bloßes Entfernen von2Markern oder Hinzufügen Sunorbit scheitert am Validator.
- target_orbit_marker_id, orbit_marker_id, UIliste/Klicks und SameMarker-Replay
  müssen versioniert auf ein Ziel pro Körper normalisiert werden; historische
  IDs nicht als drei räumliche Instanzen weiterführen. Gegenwärtige Home-only-
  Checkpoints speichern keinen Orbit, keine Away-Persistenz still freigeben.
- Adapter space_begin_approach ruft HEUTE authorize_departure (Fuel+Bind) VOR
  Travel.begin_approach. Neuer Saumgate muss vor erster Debit laufen und beim
  Rootcommit erneut denselben Flight-/Area-/Travelstand beweisen, sonst kann ein
  falscher/längst bewegter Saumklick Treibstoff kosten oder eine Blockade umgehen.
- Surfaceexit/Heimstart müssen ebenfalls areaEntry/Rotte gemeinsam herstellen;
  Landung entfernt aktive Areaindexbelegung sauber, ohne Flight/Wing neu zu kopieren.
  Bestand darf geerdet unzugeordnet bleiben, falls SpaceChatvertrag so festgelegt.
- Bestehender pauschaler combat_active-Travelgate blockiert bei motion_mode tactical
  selbst am zulässigen Saum sämtliche Reisecommands. Sicheren Rootübergang vorsehen;
  weder pauschal Combatgate löschen noch UI motion_mode zurückschreiben.

## Nächster abgegrenzter Schritt
Mit SpaceChat area/frame+Roottransition+SurfaceGate-Signaturen schriftlich fixieren,
danach dessen kanonische Owneränderungen integrieren. Orbitkarten-Task liefert
512x256-Daten und reine Darstellung/Commands. Keine Tests/Produktänderung in diesem
Audit; noch keine Bewegungs-, Blockade-, Native-, Netzwerk- oder Saveabnahme.
