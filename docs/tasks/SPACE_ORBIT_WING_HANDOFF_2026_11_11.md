# Lokale Orbitbereiche und Rotten: Integrationsgrenze

## Ziel / Ursache

Die Nutzerfestlegung aus dem parallelen Chat ersetzt die bisherigen drei
Orbitmarker und die Annahme, dass fliegende Schiffe ohne Rotte bleiben dürfen.
Strategische Karte: 256×256. Je Stern/Planet/Mond ein lokaler Orbitbereich
512×256; Warpankunft unten, oben mittig ein 256 Felder breiter, etwa vier
Felder tiefer Saum, übriger Himmelskörper außerhalb der Karte. Weiteranflug
zur Oberfläche nur am Saum und nur für landbare Ziele. Raumblockaden sind
räumlich zu spielen. Jedes fliegende Schiff einschließlich Dropship/Cutlass
gehört genau einer Rotte mit 1–6 Schiffen an; Einzelflieger bilden eine Rotte.

## Umfang / Nicht-Ziele

Hier nur Owner- und Integrationsvorschlag, keine Produktmutation. Keine zweite
Rottenverwaltung, kein zweiter Flugzustand und kein globaler Umbau der
strategischen 256×256-Karte. Boden-NPC und Tabletop bleiben beim anderen Chat.

## Relevante Verträge / Dokumente

- `docs/dev/space_combat_contract.md`, Abschnitt Karte und Rotten.
- `docs/superpowers/plans/2026-11-11-space-combat.md`, AP04/AP04a.
- `docs/dev/orbit_quantum_travel_contract.md`: bisherige Markerbeschreibung
  ist durch die neue Nutzerentscheidung als Ziel überholt, im Produkt noch da.

## Vorgeschlagene Ownergrenze

- `scripts/core/space_wing_state.gd`: einziger Owner für Rottenmitgliedschaft,
  Führer und Rottenaufträge; die UI hält keine zweite Rottenwahrheit.
- `scripts/core/simulation_root.gd`: atomare Koordination von Flugaufnahme,
  Mitgliedschaft und Übergängen; ein autoritativer Physiktakt.
- `scripts/core/space_flight_state.gd`: gemeinsame Bewegungswahrheit pro Schiff
  für Reise und Kampf; eine Bereichs-ID muss die lokale Pose eindeutig binden.
- `singleplayer_fleet_travel_state.gd` / `singleplayer_space_travel_state.gd`:
  bestehende Owner für Reisephase, zugeordneten Orbit und Übergangs-/Anfluggate.
- Der Orbitkarten-Chat verantwortet Darstellung und Kartenintegration. Seine
  Karte liest Raumprojektionen und sendet Commands; sie erzeugt weder einen
  weiteren Flugowner noch einen zweiten Rottenbestand. Gemeinsame konkrete
  API und Besitz gemeinsam berührter Dateien erst abstimmen.

## Konkretisierte gemeinsame Grenze

Der Orbitkarten-Chat meldet `OrbitApproachLayout.build(body_id)` mit
`body_map_id = "orbit_approach:" + URI-kodierte kanonische Body-ID`,
`map_bounds = Rect2i(0,0,512,256)`, unterem Eintrittsband
`Rect2i(0,224,512,32)`, `body_cells` und `gate_cells`. Der Saum ist nominal
256 Felder breit und höchstens vier Felder tief; das Gate liegt in der ersten
freien Zelle unter der Körpermaske. Ein Sonnenorbit erzeugt kein frei erfundenes
Oberflächenziel. Der alte Drei-Marker-Pfad bleibt bis zum vollständigen
Anschluss produktiv.

Für unseren Bereich schlagen wir folgende Root-Operationen vor; dies sind
**Vertragsentwürfe, noch keine implementierten APIs**:

```
prepare_space_area_transition(craft_id, area_id, target_pose,
    expected_flight_revision, expected_travel_revision, authority_context) -> Dictionary
commit_space_area_transition(transition_token, authority_context) -> Dictionary
```

Die Vorbereitung prüft Quelle/Ziel und Revisionswerte, kanonisches Layout,
gültige bereichslokale Pose, vollständigen freien Footprint und die planbare
eindeutige Rottenzuordnung. Sie erzeugt nur einen Root-internen, einmaligen
Token, keine Spielzustandsänderung. Commit prüft beide Revisionen, Besitz,
Footprint/Belegung und Voraussetzungen erneut; Flugzustand samt
`space_area_id`/`coordinate_frame`, Reisephase, räumliche Indizes und
Wingzuordnung werden als eine fachliche Transaktion geändert. Dafür müssen
Owner ihre Änderungen vorab vorbereiten und ohne nachträgliche Fehler
übernehmen können; falls das bestehende Owner-API das nicht garantiert, ist
eine explizite transaktionale Lösung nötig. Ein fehlgeschlagener oder
veralteter Übergang hinterlässt keine Teilmutation; ein identisch wiederholter
Commit darf keine zweite Bewegung oder Rotte erzeugen.

Der Reise-/Surface-Owner akzeptiert später ausschließlich einen vom Root aus
Flight-/Area-/Travelrevision sowie Position und echtem Gate abgeleiteten
Kontext. Vor Treibstoffabbuchung erfolgt eine Vorschau, beim Commit eine
erneute Prüfung; kein UI-Boolean ist Nachweis einer Saumposition. Die genaue
Tokenform, Travel-Prepare-/Commit-Schnittstelle, Rücktritt von Reservierungen
und Legacy-Abbildung werden mit dem Reiseowner gemeinsam finalisiert.

Als gemeinsamer Travel-Arbeitsvertrag sind vereinbart:
`prepare_space_area_transition(craft_id, expected_travel_revision,
source_area_id, target_area_id, root_context) -> Dictionary`,
`validate_prepared_space_area_transition(candidate, root_context) -> Dictionary`
und `commit_prepared_space_area_transition(candidate, root_context) -> Dictionary`.
Der Root-private Kontext bindet Request-ID und -Signatur, erlaubte Operation,
Ziel und Phase. Gleiche Quell-/Zielarea beweist weder Saumnähe noch ein
Landungsziel. Das heutige Travel-API bietet diese Methoden noch nicht.
Der Root hält den Kandidaten privat. Der spätere stille Publish-Tail darf keine
alten Travelcommands oder `_arrive` erneut aufrufen und veröffentlicht Events
erst nach gemeinsamer Übernahme. Erste Roottransition ausschließlich als
nichtproduktive Warp-/Area-Ownerfixture: `release_space_area_transition(token)`
bei Abbruch/Fehler/Ownerwechsel/Ablauf; Requestsignatur und Receipt verhindern
Wiederholung und geänderte Nutzung desselben Requests. Unmittelbar vor dem
signal-/awaitfreien Tail alle beteiligten Owner und Belegung erneut prüfen.
Oberflächenanflug benötigt zusätzlich vorbereitete Supply-, Campaign- und
Departureänderungen; ein Travelcandidate allein reicht nicht. Kein Fueldebit
vor vollständigem Prepare und keine ausgleichenden Dummyrefunds.

Dateibesitz: Wir bearbeiten `space_flight_state.gd`, bereichsbezogene
Raumregistry/-navigation, Raumcommands, Wingowner und die Raumtransition in
`simulation_root.gd`. Der andere Chat bearbeitet Orbitlayout/-vertrag und
Ansicht sowie nach gesichertem Import Reisegate und Migration. Gemeinsam
berührte Root-/Adapterdateien erst nach konkreter Abstimmung integrieren;
kein gegenseitiges Bearbeiten uncommitteter Änderungen.

## Vorschau für Oberflächenanflug: enger Schnittstellenentwurf

Root-Owner, zunächst ohne produktiven Aufrufer:

```
preview_surface_approach(craft_id, location_id,
    expected_flight_revision, expected_travel_revision,
    expected_area_revision, expected_wing_revision,
    authority_context) -> Dictionary
```

`area_revision` bezeichnet die monotone Revision des **autoritativen
Bereichsbelegungsindex**, nicht eine UI- oder Kartenrevision; zusätzlich
trägt der Vorschlag die kanonische Layoutrevision. Flightrevision bindet auch
Koordinatenrahmen und Bereichs-ID. Die Vorschau liest den tatsächlich
registrierten Flightowner und vollständigen aktuellen Rumpffootprint,
überprüft eigene eindeutige Rottenmitgliedschaft, Travelphase/-revision,
Orbit-/Körper-/Ortsbindung, Grenzen und Belegung. Alle Rumpffelder müssen
frei von Körpermaske und fremden Schiffen sein; mindestens ein Rumpffeld
muss eine echte freie Gatezelle des zugeordneten Körpers berühren. Ein
großer Rumpf muss also nicht in die nur eine Zelle tiefe Gatereihe passen.
Die genannte Regel ist mit dem parallelen Orbitchat als technische Auslegung
abgestimmt; die konkrete Produktabnahme steht noch aus. Reine Cursor-, Ziel- oder Darstellungswerte
sind kein Saumnachweis.

Der Rückgabewert ist eine kurzlebige **Vorschau**, keine selbständige
Freigabe und kein vom Adapter vertrauenswürdig unterschreibbares UI-Token.
Vor Commit sind alle beteiligten Revisionen, der vollständige Footprint,
Location-/Bodybindung und vorbereitete Supply-/Campaign-/Departure-Owner
erneut zu prüfen; Pilot, Crew, Job und Fuel bleiben bei den bestehenden
Ownern. Sonnen ohne gültiges Oberflächenziel ergeben keine Freigabe. Root
verantwortet diese Geometrie-/Indexgrenze; der andere Chat verantwortet
vorerst reine Adaptergates sowie vorbereitete Supply-/Campaignpatches. Echte
Authoritybindung, Replay, Eventreihenfolge und signal-/awaitfreier gemeinsamer
Tail bleiben vor der Produktaktivierung offen.

## Übergangsarten und inaktiver Flugzustand: Abstimmungsvorschlag

Warpankunft, Oberflächenanflug/-abflug und Stationsverkehr sind verschiedene
Übergänge. Root muss `transition_kind` aus gebundenem Travel-/Zielzustand
ableiten; kein frei gesetztes UI-Feld. `warp_arrival` wählt unten einen freien
vollständigen Footprint. `surface_approach` benötigt gültige Body→Surface-
Verknüpfung, echten Gatekontakt und vollständig vorbereitete beteiligte Owner.
`surface_exit` reaktiviert dasselbe Flightobjekt an einem freien Saumplatz;
Stationsanflug/-abflug braucht eigene typisierte Geometrie und darf keinen
Planetenatmosphärensaum erfinden. Die alte Drei-Marker-Reise bleibt bis zum
vollständigen Ersatz produktiv.

Vorschlag für neue Übergänge: Ein ausdrücklicher inaktiver Flugmodus sperrt
Raumcommands und entfernt nur die aktive Registrybelegung und Korridorclaims;
Flightobjekt, Rotte und ein einziger Posezustand bleiben erhalten. Als
Rückkehrbezug könnte dessen letzter lokaler Rahmen samt Area-ID erhalten
bleiben, ohne dass diese inaktive Pose eine belegte Raumzelle darstellt.
Legacy-Oberflächenfahrzeuge besitzen dagegen strategischen Rahmen und leere
Area-ID. Der künftige `surface_exit` muss beide Herkunftsformen explizit
prüfen und den Zielsaum vollständig neu validieren. Dies ist noch keine
beschlossene Produktsemantik: Der jetzige Travelcandidate akzeptiert als
Source ausschließlich `""`; Unterstützung für inaktive lokale Herkunft,
genaue Flugmodus-/Positions-/Geschwindigkeitssemantik und Authority-API
müssen mit dem Travelowner abgestimmt und vor Mutation implementiert werden.
Kein temporäres Umstellen der Flightpose über Legacy-Reiseschreiber.

## Akzeptanzkriterien / kleine Arbeitsschritte

1. Bereichs-ID, strategische/lokale Koordinaten, Atomarität, Saumgeometrie,
   Ankunftsverteilung und Lookup-/Indexgrenzen gemeinsam festlegen.
2. Eintritt/Umgruppierung sicherstellen: jedes fliegende eigene, neutrale oder
   feindliche Schiff genau einer Rotte; bestehendes ungeerdetes Legacy-Schiff
   und Einzelschiff mitprüfen. Geerdeter Bestand darf unzugeordnet bleiben.
3. Separaten 512×256-Lokalindex einführen; vorhandene Sternkarte und
   `StrategicHexGrid` nicht still vergrößern. Zwei Bereichs-IDs mit derselben
   lokalen Koordinate dürfen sich nicht gegenseitig blockieren.
4. Warpankunft unten, ein Ziel pro Körper, Oberfläche nur am Saum und nach
   vorhandener Berechtigung. Alten Marker-/Savevertrag explizit migrieren.
5. Dieselben Schiffs-/Rottenzustände für Reise, Kampf, Ansicht und Rückkehr
   prüfen; keine Heilung/Teleportation durch Ansichtswechsel.

## Betroffene Dateien / lokale Prüfung

Voraussichtlich die genannten Owner, Grid-/Registry- und Travelcontracts,
Stern-/Orbitkartenprojektion und Checkpointvalidierung. Gezielte Verifier für
Atomarität, Gebietstrennung, Eintritt, Saumgate und Legacy; keine große
Testrunde vor Integration. Die vorhandenen Fixtureprüfungen beweisen diese
neuen Anforderungen nicht.

## Risiken / offene Punkte

Der aktuelle `SpaceFlightState` hat keine Bereichs-ID; `StrategicHexGrid`
begrenzt auf 256×256; `SpaceWingState` erlaubt momentan unzugeordnete Schiffe.
Die API-/Dateibesitzabstimmung ist noch offen. Vorschläge wie automatische
Einzelrotten sind technische Umsetzungsideen und keine zusätzliche
Nutzerentscheidung. Keine native, Multiplayer- oder Saveabnahme erfolgt.
