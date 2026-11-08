# R4: Fog-Freshness und tatsaechliche Visualaenderung trennen

Untertask zu `RUNTIME_HITCHES_R4_2026_11_07.md`, Basis Main3b12b2878.
Root besitzt Engine und Git. Der enge Terrain-Fog-Hunk wurde nach realem RED
freigegeben und implementiert; alle Engine-Nachpruefungen laufen durch Root.

## Bestaetigter Quellbefund / zu messende Ursache
`MissionSetup._sync_fog_dynamic_target_visibility` publiziert bei sichtbaren
Targets in jedem Sync einen neuen `last_seen_tick`. Im TerrainView geht dieser
Tick sowohl in die Snapshot- als auch in die dynamische Visualsignatur ein.
Der View verwendet ihn ansonsten nur im Normalizer, nicht fuer Geometrie oder
Zulassung. `set_fog_of_war_state` baut Kontakte immer und Orders bei geaenderter
dynamischer Signatur neu. Eine reine Freshnessaenderung kann somit Markers und
Labels wegwerfen/neu erzeugen. Millisekundenanteil ist noch kein isolierter
Ursachenbeweis und muss Root im frischen Profil separat messen.

## Umfang und Nicht-Ziele
Nur Darstellungscache/-invalidierung in TerrainMap3DView. Snapshot und dessen
aktuelle Ticks/Revisionen bleiben frisch und defensiv; Runtime-Fog und LOS sind
weiter die Wahrheit. Keine Sichtweiten-/Workbudget-/Actor-/Rateaenderung, kein
neuer Wissenstand, kein zeitlicher UIcache. Kontakt-/Ordergeometrie darf nur
bei effektiv identischen Eingaben wiederverwendet werden. Source-, Auswahl-,
Mode-, Team-, Position-, Zulassungs- oder Darstellungswechsel muessen wirken.

## Akzeptanz / enges RED
- Echte kleine MapData, wirklicher TerrainView und nichtleere Contact-/Order-
  Controls. Ein nur fortgeschriebener Kontakt-Tick veraendert die gelesene
  Fogsnapshot-Freshness, laesst aber beide bestehenden Nodegruppen identisch
  und ruft weder Contact- noch Order-Rebuild auf.
- Gleiche Terrainkenntnis bei neuer Revision behaelt ebenfalls identische
  visuelle Projektion; die gelesene Revision wird dennoch uebernommen.
- Eine bewegte Last-known-Position wird sichtbar projiziert. Entfernung eines
  Kontakts/aller Kenntnis unter Blackout entfernt die tatsaechlichen Markers.
  Mode-/Teamwechsel duerfen keine alte sichtbare Zulassung behalten.
- Ein anschliessender veraenderter Contactpayload/ausgewaehltes Fireteam muss
  weiterhin frische Geometrie, Farben/Profiltext und Filterzulassung liefern.
- Exakte Positions-, Detection-/Target-/Terrainkenntniswechsel invalidieren
  auch bei gleichem Tick bzw. gleicher Revision. Reine Visibility-Delta-
  Metadaten werden frisch gespeichert, ohne identische Geometrie neu zu bauen.
- Map-/Tilewerte und uebergebene Payloads bleiben unveraendert. Der Test
  erzeugt weder Actors noch Commands, Fire-Events oder Gameplaywissen.

## Dateien / Pruefung / Grenzen
Neuer Verifier `runtime_hitches_r4_20261107_fog_projection_verifier.gd`, Marker
`R4_FOG_PROJECTION_PASS`. Produktdatei:
`scripts/terrain/terrain_map_3d_view.gd`, nur Fog-Setter/Signaturen.
Vertraege: AGENTS, ARCHITECTURE, CODEX_RULES, Fog-Modi und
mission_hud_projection_authority_contract. CPU-Nodeidentitaet ist kein
GPU-/FPS-/physischer Spielbeweis; native zeitliche Sichtpruefung folgt separat.

## Risiken / offene Punkte
Ein Cache darf keine notwendige Admissionaenderung verschlucken. Ein einfacher
Tick- oder Revisionvergleich reicht deshalb nicht als globale Visualsignatur.
Vollstaendige aktuelle Snapshotdaten sind von geometrischer Gleichheit zu
trennen. Keine FPS-/GPU-/Spielakzeptanz aus den CPU-Assertions ableiten.

## Umsetzung / gebundener Nachweis
- Root meldete gegen unveraenderte Quelle: **17 PASS / 3 RED**, keine
  Enginefehler. Exakt Timestamp-Contact, Timestamp-Order und Revision-Nodes
  waren rot. Historischer RED bleibt unangetastet.
- Vollstaendige normalisierte Snapshots bleiben unabhaengig von der
  Geometriesignatur frisch. Diese ignoriert ausschliesslich `last_seen_tick`;
  alle anderen Kontaktfelder einschliesslich exakter Position bleiben darin.
- Kontakte und Orders werden bei geaenderter dynamischer Projektion oder
  tatsaechlich geaendertem Terrainwissen neu gebaut. Nur Timestamp/Revision
  behalten die wirklichen Nodes. Kein Scheduler-/Sichtweiten-/Runtimehunk.
- Der kleine Verifier ergaenzt angrenzende Admission-, Detection-, exakte
  Positions- und Snapshot-Metadatenfaelle. Root-GREEN und nativer
  Performancevergleich sind **PENDING**; kein Millisekundengewinn behauptet.
