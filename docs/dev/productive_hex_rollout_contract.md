# Produktive Hexwege und gespeicherte Zufallsdomänen · 13.11.2026

Arbeitsstand zu `docs/tasks/REVIEW_COMPLETION_2026_11_13.md`, Basis Main dc2ca9aca.
Dieser Vertrag beschreibt den neuen Kandidaten. Ausführungsergebnisse und die
noch offenen vollständigen Start-/ENet-/Leistungsabnahmen stehen im Task/QA-Bericht;
Kartenflags und ein bestandener Kapazitätstest ersetzen diese Abnahmen nicht.

## Karteninventar und Einstieg

`scripts/mission/productive_ground_maps.gd` ist der Katalog der mitgelieferten
Spielkarten. Die Lobby übernimmt außerdem gültige benutzererstellte Map-JSONs im
bestehenden Kartenverzeichnis. Deren Aufnahme hängt nicht von einem bekannten
Dateinamen ab. Neue Editorkarten verwenden Hex; ein expliziter Editor-Spieltest
aktiviert den gemeinsamen Hex-Owner auch bei einem alten importierten Layout.
Der MapData-Import selbst bleibt für historische Square8-Tests unverändert.

| Gruppe | Dateien unter maps/ | Laufzeit |
|---|---|---|
| Boden/Skirmish | Ground_Mission01_32x32, Ground_Mission02_128x128, fireteam_command_drill_24x24, frontier_workyard_24x20 | Hex |
| Außenposten | station_outpost_64x64, station_outpost_192x192 | Hex |
| Vorhandene kleine Spiel-/Sandboxkarten | wall_test_4x4, test_mission, test_mission_32x32_slots8 | Hex |
| Kampagne A/B/C | satellite_crash_site, trade_outpost, fortified_outpost | Hex; jeweils unverändert 512×256 |
| Weitere Kampagnenorte | polisa_station, distress_orbit | Hex; Luft-/Raumowner bleiben domänenspezifisch |
| Basisdarstellung | campaign_intro_base, homebase_frontier_exploration | Hexgeometrie; Basis verwendet die Feinnavigation |
| Physische Basisnavigation | base_interior_navigation | Hex; 384×392, vorhandene 16×8-Isometrie |

Alle Namen tragen `.json`; 14 Spielkarten und 3 Basisdateien. Dateinamen wie
`Ground_Mission01_32x32` und `wall_test_4x4` sind historische Kennungen, keine
verlässlichen Maßangaben. Die zwei markerlosen 8×8-Karten erhalten die bisherigen
Szenenmarker explizit in Hexkoordinaten: Alpha (3,7), Bravo (4,0), Ziel (4,4).
`wall_test_4x4` behält seinen geschlossenen Mauerring um das Ziel; Aufnahme in den
Katalog ist kein Nachweis eines abgeschlossenen Missionsszenarios.

Explizite historische Import-/Testdateien werden nicht als fertige Lobbykarten
angeboten, bleiben aber unverändert vorhanden und direkt in Tests/Editor ladbar:

| Datei | Grund |
|---|---|
| editor_terrain_visual_recovery_reference.json | 36-Felder-Grafik-/Editorreferenz |
| enemy_tactics_smoke_32x32.json | Sparse KI-Smoke-Fixture, 45 vorhandene Felder |
| facing_sightline_debug_12x12.json | Richtungs-/Sichtlinien-Verifier |
| hill_mechanics_16x16_testmap.json | Historische Höhen-/Rampenregression |
| task_156_contract_map.json | Vier-Felder-Contractfixture |
| task_157_editor_mvp_map.json | Vier-Felder-Editorfixture |
| test_lz_air_asset_threat_fixture.json | Acht-Felder-LZ-/Luftabwehrfixture |
| Test_mission_32x32.json | Ein-Feld-Vorlage mit Kommentar, kein gültiges JSON |

Frühere Square8-Originale der sieben konvertierten Karten liegen byteerhalten unter
`maps/legacy/*_square8_20261113.json`. Der reproduzierbare Migrationshelfer
`scripts/tools/migrate_productive_hex_maps_20261113.py` lässt Tilefakten und logische
Koordinaten unverändert und konvertiert Weltmarker, Patrouillenpunkte und
Darstellerzentren. Erfindet keine Rampen oder neue Terrain-/Schadensregeln.

## Besitzer und Grenzen

Produktive Bodenstarts benutzen MissionSetup → SimulationRoot → HexGroundRuntime,
die vorhandene Admission und begrenzte Bewegung/Reservierung. Sicht, Facing und
Boden-Schussfreigabe lesen denselben Hexadapter einschließlich Schablone und LOS.
Raumflug bleibt kontinuierlich auf seiner Raumebene; Zellenindex/Schusslinie und
Luft-Boden-Streuung verwenden ihre bestehenden Hexprojektionen. Daraus folgt
keine Umdeutung von Raumflug in schrittweise Bodenbewegung.

Basis-Betten, Modulwände und geparkte Schiffe kommen aus dem bestehenden
BaseInteriorNavigation-Clearanceindex. Dessen abgeleitete Blockzellen/Revision
werden dem Root-Admission-/Bewegungsplaner übergeben. Hexlauf startet keine zweite
AStar-Suche. Maskenleser mutieren nichts; Owner aktualisieren Geometrie/Revision.

### Annäherung und Aufsitzen am gelandeten Schiff

Die Schiffsmitte ist kein erreichbarer Fußgängerstandpunkt. Im tatsächlichen
Cutlass-Rückweg liegt das erste freie Hexzentrum bereits 148,782 Weltpixel von
der Mitte entfernt; die bisherigen 96/128-Pixel-Grenzen können dort nicht greifen.
Einsteigen, Extraktion, Return-Interaktion und Boarding lesen daher dieselbe
Zugangsprojektion aus dem gebundenen Schiffsprofil und der vorhandenen Hullmaske.
Sie verwendet die bestehende begrenzte Ausstiegsankersuche des Deploymentadapters.
Die Use-/Boardingradien bleiben erhalten und beziehen sich auf diese reale
Zugangsfläche. Fremde Schiffe, Terrain, Höhen, Belegung und Reservierungen bleiben
Hindernisse; die Zugangsprojektion räumt weder Zellen noch Fahrzeuge weg.

Für bereits anwesende Crew werden nur Ziele geplant und normale tokengebundene
Bewegungsbefehle ausgegeben. Kein erneutes Admittieren, Versetzen oder direkter
Positionswrite. Annahme, tatsächliche Ankunft und Boarding werden getrennt
bestätigt; eine fehlende Route meldet einen begründeten Fehler. UI und Netzwerk
verwenden dieselbe hostseitige Projektion, keine vom Client behauptete Position.
Veraltete Schiffsposition/Profile sowie andere Crew-/Runtime-Kontexte sind vor
Bewegung beziehungsweise Boarding erneut zu prüfen. Die bestehende Polisa-Route
und Legacy-Kompatibilität bleiben mit eigenen Nachbartests abgesichert.

## Zufall

Gameplayvergleiche benutzen normalisierte Werte 0..1; Prozentanzeigen bleiben
erlaubt. SimulationRoot besitzt die bestehenden drei unabhängigen Sequenzen:

| Domäne | Seed/Zustand | Verwendung |
|---|---|---|
| Boden | `combat_rng_seed` (Default 1), Godot-PCG-Zustand als kanonischer Int64-String | Treffer sowie Disziplin und Fehlidentifikation |
| Raum | `_space_fire_rng` (Default 1), bestehender 31-bit-LCG | validierte Raumwaffenschüsse, normalisierter Vergleich |
| Luft/Boden | `_air_ground_rng_state` (Default 1), bestehender 31-bit-LCG | Seed für reine Hexstreuung, lokale normalisierte Auswahl |

`gameplay_rng_state.gd` validiert und transportiert diese Zustände. Abgelehnte
Vorhaben, Replays und Readouts verbrauchen keine Rootwürfe; ein Client-Root kann
keinen lokalen Combatwurf liefern. Disziplin/Fehlidentifikation ohne zuständigen
Root schlagen geschlossen fehl, statt globale Würfel als Ersatz zu benutzen.
DamageModel ist rein; ungültige/nonfinite Würfe werden abgelehnt, 0% trifft nie,
100% trifft für jeden gültigen normalisierten Wurf.

LZ-Abweichung ist ein reiner, mit dem vorhandenen Commandseed reproduzierbarer
Geometrievorschlag aus zwei normalisierten lokalen Würfen; das tatsächliche
Landeergebnis gehört dem Transportowner. Startroster-/Namens-/Beziehungsaufbau
behält seine getrennten, explizit gesäten Generatoren und gespeicherten Resultate.
Zufällige Session-/Receipt-Seals sind Identitäten, keine Gameplayentscheidung.
Audio-/Darstellungszufall ist ebenfalls kein Kampfzustand.

## Speichern und Migration

Hex- und stabiler Missionscheckpoint ergänzen ihre vorhandenen v1-Schemata um
optionale `rng_streams`. Alte gültige Checkpoints ohne dieses Feld erhalten den
gespeicherten Combat-PCG-Zustand und dokumentiert Seed 1 für Raum und Luft. Neue
Saves erfassen alle drei. Prepare bindet alle drei Ausgangszustände; eine Änderung
vor Commit verwirft den gesamten Kandidaten ohne Teilpublikation.

Aktiver Save erfasst den entfernten Basisowner zusätzlich als `home_hex_tactical`.
Alle Personen an Bord werden gegen tatsächliche Crew-/Transport-/Ortsowner geprüft;
eine versteckte Bootstrap-Rekonstruktion benötigt den unveränderten, nochmals
dateigebunden validierten Restorepayload. Kein allgemeines Ignorieren von
Abwesenheits-/Belegungswahrheit. Der Missionscheckpoint kombiniert Ground und echte
Actor-Modelle in einer Roottransaktion; lebendige Holds/Vitals bleiben erhalten.

Stabile alte Missionen auf bereits identischer Hexgeometrie dürfen aus
`legacy_ground_positions.v1` migrieren: Frame, Terrainfingerprint, Overrides,
Actoridentitäten und alte Positionen müssen übereinstimmen. Die bestehende
Admission wählt eindeutige legale Zellen; der Eingang wird nicht verändert. Eine
Square8-Geometrie oder geänderte Karte wird nicht still geometrisch geraten.

Neue Kampagnen schreiben nach erfolgreicher Ownerkonfiguration ihren ursprünglichen
Home-Checkpoint vor weiteren Benutzeraktionen. Der fünfminütige Autosave-Erfolgstimer
beginnt erst nach tatsächlichem Erfolg. Fehlgeschlagene Exporte bleiben Fehler und
werden frühestens nach einer Sekunde erneut versucht; Force umgeht nur das Intervall.
Stationäre Sicherungsrichtungen erzeugen keine neue ausstehende Drehung. Echte
verzögerte/konkurrierende Drehungen blockieren einen partiellen Save weiterhin.

Ein neuerer fehlgeschlagener Force-Export verwirft auch ein noch laufendes älteres
Erfolgsintervall, ohne die letzte gültige Datei zu ersetzen. Die Ground-/Actor-
Transaktion bereinigt tote Handles und begrenzt beide Schemazweige gemeinsam auf
32 lebendige Vorbereitungen. Der Movementcodec erhält tatsächliche Post-Drop-
Sicherungsfelder explizit: kanonische Securitymodi (einschließlich historischem
`directional`), ganzzahliger Radius 0..256 und endlicher Winkel innerhalb ±2τ.
Unbekannte Felder, falsche Typen und ungültige Werte bleiben unzulässig.

Eine erreichte Hex-Bewegung bleibt als angenommener Befehl samt Haltung erhalten.
Der stabile Lifecycle akzeptiert sie ausschließlich mit Root-Ankunftsnachweis für
dieselbe Person, Zielzelle und dasselbe Commandtoken ohne Bewegungszusagen.
Bekannte reine Producer-Diagnosefelder werden bei der Intentannahme entfernt;
die wirksamen UnitCommand-Felder bleiben erhalten und werden streng gespeichert.

Checkpoint-Export und Restorevorbereitung dürfen für belegte Routensegmente und
Passagezusagen einen kalten Korridorindex mit höchstens 8192 Knoten vorbereiten.
Das ist ein begrenzter Savepfad, keine Tickarbeit; das normale Tickbudget bleibt
64 Knoten. Ein unvollständiger Index wird weiterhin abgelehnt.
Vorbereitungen bleiben über Legacy und Hex gemeinsam auf 32 lebende Handles
begrenzt. Verwaiste äußere Actor-/Batchrecords werden vor inneren Vorbereitungen
bereinigt; synchrone Publikationsguards werden nicht als Referenzkreis gehalten.

Beim letzten tatsächlich Root-bestätigten Ausstieg entfernt der Deploymentadapter
das erledigte Sequenzreceipt. Solange der Ausstieg noch nicht bestätigt wurde,
blockiert derselbe Transportguard weiterhin das Speichern. Es wird keine
Admission storniert und keine Person nur für einen Speicherpunkt verschoben.

Die versteckte Home-Vorprüfung verwendet einen eigenen tatsächlichen Adapter
mit dem bestehenden `sync_crafts`-Padbesitz und dem wiederhergestellten Supply-
und Campaignzustand. Sie schreibt nichts am lebenden Weltbesitz. Der spätere
Aboard- und Commitvergleich prüft exakt den validierten JSON-Wertebereich:
gleiche Keys, Struktur und Werte; nur mathematisch gleiche int/float-Zahlen
werden akzeptiert, ohne Epsilon, Feldverlust oder gelockerte Transportbelege.

## Gezielte Regressionen

- `review_completion_rng_verifier.gd`: tatsächliche Driver/Rootwürfe, Replikate,
  globale RNG-Unberührtheit, portable Domänen, veraltetes Prepare, 0/100%-Grenzen,
  stationäres Facing und Replay.
- `review_completion_maps_verifier.gd`: alle Katalogdateien in Originalgröße,
  authored Startmarker, 30 echte Actors, Rootbewegung/Belegung, Türänderung,
  echte A/B/C-Rampen, Checkpoint, Embark/Admission und Custom-Importgeometrie.
  Gemessene Aufwandszähler sind begrenzte Headless-Evidenz, keine FPS-Abnahme.
- `review_completion_base_clearance_verifier.gd`: tatsächlicher Clearanceindex,
  Bed-/Craftmasken, reine Leser und Root/Base-Bewegung sowie Admission.
- `review_completion_legacy_hex_verifier.gd`: tatsächlicher alter Ownerexport,
  Admissionmigration, native Neuspeicherung; falsche RNG-Typen/fehlende Felder/
  Overflow ohne Änderungen der Owner oder des Eingangspayloads. Dies ist kein
  Ersatz für ein authentisches vollständiges Altsavepaar.
- `review_completion_home_save_verifier.gd` und
  `campaign_hex_autosave_interval_verifier.gd`: normale initiale Datei vor Testsave,
  echte Boardingphase, Store-Reimport und ehrlicher begrenzter Fehlerretry.
- `review_completion_command_save_verifier.gd`: tatsächlicher angenommener
  Post-Drop-Befehl, portable Wiederherstellung und Erreichen des Ziels; ungültige
  Sicherungsfelder verursachen keine Owneränderung.
- `review_completion_checkpoint_numbers_verifier.gd`: exakter JSON-Zahlenbereich,
  verschachtelte Besitzdaten, fehlende/zusätzliche Felder, Reihenfolge,
  bool/string-Verwechslungen, Nicht-Endliches und unsichere Integer.
- Vollständiger ActiveContinue/Kampagnendurchlauf und ENet-Nachbargates bleiben
  verbindlich; Resultate werden ausschließlich nach tatsächlichem Lauf berichtet.


### Interaktionsankunft und Szenarioformationen (13.11.2026)

- Use stoppt erst, wenn die kanonischen Hexpositionen im unveränderten Objektradius liegen. Ein interpolierter Grenzübertritt allein ist keine Ankunft. Die Ausführung wartet auf das tatsächlich angenommene Hold-Token aller gebundenen fitten Mitglieder sowie das Ende von Bewegung und Routenbindungen; erst danach entstehen Ankunftsreceipt und Haltezeit. Ein außerhalb endender Stop nimmt die echte Annäherung wieder auf. Ersetzte Befehle und Kontakte können keine alte Receipt weiterverwenden.
- Szenario-Spawnmarker bleiben verbindliche, begehbare Anker. Ein freier Formationsoffset bleibt erhalten; ein alter Pixeloffset, der eine Hexwand trifft, wird vom vorhandenen atomaren Admissionplaner am expliziten Gruppenanker eingeordnet. Ein ungültiger authored Anker wird nicht durch beliebige freie Kartenfelder kaschiert.
- Enge Regressionen: `review_completion_hex_use_verifier.gd` (echte Rootbewegung/Stop beider Richtungen) und `review_completion_spawn_verifier.gd` (echte Setup-/Actor-/Rootadmission). Vollständiger tatsächlicher Continue und verbundene Stationroute bleiben zusätzliche Integrationsgates.

- Fireteam-Formation und Bounding behalten ihre bestehenden Ziele/Stages, doch Hex-Ankunft und Finalisierung fragen `SimulationRoot.has_hex_position_arrived` mit dem wirklichen Stage-Token ab. Der Abstand zur alten unquantisierten Pixelposition darf eine korrekt am Zielhex stehende Gruppe nicht festhalten. Historische Square8-Fälle behalten ihre bisherige Pixel-Toleranz.

### Stationsensemble entlang der Lagerhausachsen

Die ausdrücklich gewünschte rechtwinklige Stationsausrichtung ist eine begrenzte
Contentrevision der Station64/192, keine abweichende Visualwelt. Das zentrale
20×18-Feld-Ensemble wird offline mit `q' = q − floor((r−row_anchor)/2)` versetzt;
alle Tilefakten einschließlich Höhe, LOS, Türen und Deckung folgen derselben
bijektiven Zellpermutation. Betroffene Marker und Patrouillenpunkte folgen ihrer
tatsächlichen Zelle. Vier echte Rohrblockerzellen erhalten den Anschluss an das
unveränderte Lagerhausgebiet. Gebäude, Kamera, Karte außerhalb dieser begrenzten
Hülle und andere Karten bleiben unverändert.

`place_presentation.station_module_layout` beschreibt nur die gemeinsame
Modellprojektion innerhalb dieser belegten Hexhülle: originale rechtwinklige
Achsen, alternierender Viertelzellversatz und passende Segmentlänge. Es entstehen
keine verschobenen Gameplaykoordinaten. Bodenflächen bleiben zellgebunden.
Vorher-/Nachherbilder und tatsächliche Tür-/Route-/Map-/Restoregates sind nötig;
die reine Quelldatentransformation ist keine visuelle Abnahme.

Der Stationsdrill bindet seine Tür an `station_entry_door` auf dem tatsächlichen
östlichen Türblatt. `door_cells` benennt ausschließlich dessen zwei vorhandene
Blockerzellen (Rahmen und Blatt). Die freie Innenzelle `objective_point` bleibt
der Computer; sie darf nicht mehr stellvertretend als Tür geöffnet werden.
Der verbundene Stationstest geht über Rootbewegung vom Außenzugang durch beide
nach dem Use geöffneten Türzellen zum echten Computer. Seine AA-/Cargoabschnitte
bleiben begrenzte Netzwerk-Routingproben und sind kein vollständiger Feuerkampf.

Produktive Kampagnen-Active-Saves binden ihre Karten an den aktuellen, streng
validierten Home/A/B/C/Distress/Polisa-Katalog; Station64/192 gehören dort nicht
zu den erlaubten Orten. Diese Saves werden deshalb nicht migriert. Generische
Rootcheckpoints bleiben exakt fingerprintgebunden: ein alter Stationszustand
wird niemals still als neuer Kartenzustand interpretiert. Die alte Quellfassung
bleibt im dokumentierten Vorher-Snapshot als QA-Nachweis erhalten.

### Vollständige Startressourcenprüfung
Zusätzlich zur Root-/Belegungs-/Navi-/Save-Matrix werden die 17 authored Karten
über ihren tatsächlichen TerrainView-Startpfad geprüft. Für regionale A/B/C-Karten
muss der bestehende versteckte `configure_terrain_resource_prefill` alle erwarteten
Chunks innerhalb des unveränderten 256-MiB-Descriptor-/Ressourcenbudgets vorbereiten.
Erst dann darf der Cache an einen neuen echten TerrainView gehen; die initiale
Geometrie muss aus dem Cache wiederhergestellt und nicht neu gebaut werden.
Die übrigen Karten benutzen ihren normalen direkten Renderer, nicht künstlich
aktiviertes Regional-Prefill. Der Verifier protokolliert diesen Unterschied und
misst keine GPU-Gesamtspeichergrenze oder laufende Bildrate. Geplant/noch auszuführen:
`review_completion_map_preparation_verifier.gd`, `REVIEW_MAP_PREPARATION`.
