# R4: doppelte Terrain-LOS im Fog-Owner entfernen

Untertask zu `RUNTIME_HITCHES_R4_2026_11_07.md`. Root besitzt Engine, Git
und Produktfreigabe. Der eine Fog-Auswertungshunk wurde nach Root-RED
freigegeben und implementiert; alle Engine-Nachpruefungen laufen durch Root.

## Problem / bestaetigte Ursache
`FogOfWarSystem._evaluate_tile_visibility` fragt fuer einen zugelassenen
Observer/Tile erst `has_line_of_sight_between_points` und anschliessend
`has_line_of_sight_with_terrain` ab. Die reale `LineOfSightSystem` delegiert
bereits aus der ersten Methode vollstaendig an die zweite. Ein freier Strahl
wird damit zweimal mit identischen Argumenten ausgewertet; ein geblockter
Strahl kehrt nach der ersten Abfrage zurueck. Der bereits vorhandene
`_observer_can_see_tile`-Pfad behandelt die zweite API korrekt als Fallback.
Die Doppelarbeit ist im Code bestaetigt, ihr Millisekundenanteil noch offen.

## Umfang / Nicht-Ziele
Nur vorhandene LOS-API-Prioritaet in der Fog-Tileauswertung berichtigen: eine
vollstaendige Abfrage pro Pair, bestehender Terrain-only-Fallback bleibt.
Keine Sichtweiten-, Positions-, Observer-, Workbudget- oder Latenzaenderung.
Kein neuer Cache, kein Scheduler-/Workerumbau, kein Render-/Combat-Ownerhunk.
Candidate-Sammlung, eingefrorene Samples, statische Invalidation und atomarer
Commit bleiben unveraendert. Keine Budgetreduzierung als Performancegewinn.

## Akzeptanz / enges RED
- Echte LOS-Subclass zaehlt echte `super`-Abfragen mit echten Registrytiles;
  freie, blockierte, ausserhalb Reichweite liegende und mehrfache Observer-
  Faelle liefern exakt dieselben Resultate/Zaehler wie der reale direkte LOS-
  Oracle. Je abgetastetem Pair hoechstens eine komplette Terrain-LOS.
- Terrain-only und Points-only sind echte Adapter um denselben LOS-Owner;
  beide API-Fallbacks, Mode-off und fehlendes Tile bleiben korrekt.
- Square- und Hex-Topologie: voller Aufbau und Dirty-Bewegung produzieren
  identische vollstaendige Team-/Delta-Snapshots gegen den Terrain-only-Oracle.
  Kandidatenreihenfolge/-cursor, verarbeitete Tiles und atomare Publication
  bleiben bei gleichem unveraendertem 512-Tilebudget gleich.
- Registry/Tilewerte und reine Queryinputs bleiben unveraendert. Die Tests
  sind explizite synthetische Komponentenfixtures, kein physischer Spielbeweis.

## Dateien / lokale Pruefung
RED: `scripts/tests/runtime_hitches_r4_20261107_fog_los_verifier.gd`, Marker
`R4_FOG_LOS_PASS`. Nach Root-RED nur `_evaluate_tile_visibility` in
`scripts/core/fog_of_war_system.gd`; Root gibt diesen Hunk einzeln frei.
Vorhandene R3-Single-Slice-, TASK1189-, TASK224/225-/Hex-Fog-Nachbargates
bleiben relevant; danach nativer Vollbildvergleich durch Root.
Runner pins enthalten Fog-Owner, reale LOS-Klasse und automatisch den jeweils
ausgewaehlten Verifier bereits; keine Runneraenderung erforderlich.

## Architektur / Risiken / offene Punkte
Fog-Owner bleibt Wahrheit, API2 ist Fallback zum vollstaendigen API1. Ein
allgemeines Walltimebudget fuer 2048 Candidate-Lookups/512 Tileauswertungen
ist davon getrennt: Yield nur an stabiler Cursorgrenze, niemals halbfertige
Sicht publizieren, aktuellen Target-LOS nicht anhalten, statische Invalidation
vor jedem Slice und bisherige 350-ms-Stalenessgrenze pruefen. Langsamere
Arbeitsscheiben allein beweisen keine tragfaehige kuerzere Sichtlatenz.
## Gebundener Nachweis / Status
- Root-RED: `output/runtime_hitches_r4_20261107/fog_los_red/20261107T091002Z-b7b203ce`,
  **50 PASS / 8 RED**, keine Enginefehler, stabile Quellen. Exakt die acht
  vollstaendigen LOS-Callcount-Pruefungen waren rot; Result-/Fallback-/Job-
  /Candidate-/Atomic-/Purityparitaet war bereits gruen.
- Implementiert ausschliesslich `_evaluate_tile_visibility`: Die vollstaendige
  Point-API bleibt bevorzugt, die Terrain-API ist jetzt deren Fallback wie im
  vorhandenen `_observer_can_see_tile`. Argumente, Rueckgabe, Counter, Bereich,
  Cursor, Budgets, Revision und Commit sind unveraendert.
- Root-GREEN: `output/runtime_hitches_r4_20261107/fog_los_green/20261107T091218Z-08894182`,
  **58 PASS / 0 FAIL**, exit0, keine Enginefehler, stabile Quellen.
  Fog-Owner SHA256:
  `544b976ad1f76ea430bbc5b160be107e947366a41a8ccb6ef7d0dc92cdb5b822`.
- Neuer nativer Performancevergleich bleibt **PENDING**. Noch kein
  Millisekundengewinn behauptet; kein Budgetumbau in diesem Task.
