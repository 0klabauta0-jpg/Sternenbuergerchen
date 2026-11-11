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
