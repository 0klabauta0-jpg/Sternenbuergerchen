# Hexreservierungen: autoritativer Commit und Tickkern

## Ziel / Ursache

Den reinen Planer aus30840746c (hier161d62dff) an denselben Ground-Owner
binden. Ein Vorschlag ist noch keine Zusage. Gemeinsam angenommene Freigaben,
stehende Belegung und Gegenkanten müssen vor jeder Mutation konsistent sein.

## Umfang / Nicht-Ziele

Versionierter Ground-Snapshot mit committed_segments und
committed_corridor_grants. `commit_plan(plan, expected_revision)` prüft die
ganze Transaktion und übernimmt alles oder nichts. Dauerhafte Zusagen liegen
im Ground-Owner. Keine Actortransforms, UI-/Save-/Netzwerkänderung und keine
aktive Karte. Rendering und laufende Move-Commands folgen im AP5-Anschluss.

Der kleine Tick-/Handoffkern aus AP5 wird hier als notwendige Grundlage
mitgeführt: Nur so lassen sich zeitliche Belegung, ablaufende Kanten und
gemeinsame Feldwechsel tatsächlich prüfen. Er publiziert reine Ereignisse;
erst die nachfolgende Anbindung bewegt sichtbare Actors. Root-Ticks dürfen
diesen Kern synchronisieren, Read-Getter mutieren ihn nicht.

## Verträge / Dateien

- docs/dev/hex_reservation_plan_contract.md (übernommener reiner Helfer)
- docs/dev/hex_tactical_runtime_contract.md
- docs/dev/explicit_hex_ramps_contract.md
- docs/superpowers/plans/2026-11-11-hex-sight-occupancy.md, AP4/5

Dateien: HexGroundRuntime, SimulationRoot-Tick-/Commitadapter, kleiner neuer
Owner-Verifier und bestehender isolierter Runner. Resolver bleibt zunächst
der unveränderte übernommene Freeze. Alle weiter notwendigen Änderungen am
Resolver ausdrücklich prüfen und mit koordinierendem Chat abstimmen.

Abgestimmte Ergänzung: Registry besitzt einen auf4096 Einträge begrenzten,
revisionierten legalen Hexnachbarcache. Planer darf ihn als abgeleitete
Geometrie verwenden, ohne Gameplayzustand zu schreiben. Runtime-Türbegehbarkeit
verwendet `TerrainTileData.allows_registry_step` mit beiden maßgeblichen
Registrygates; Authoring-`allows_step`/`endpoint_height` behalten ihre Defaults.
A*, HPA und Root-Schrittguard verwenden denselben internen Rampenkern.

## Akzeptanz

- SnapshotSchemaV1 ist ausdrücklich vorhanden; Planer kann echte Snapshots lesen.
- Falsche Owner-/Terrainrevision, ungültige Segmente oder gemeinsame Konflikte
  weisen ohne Teilmutation zurück. Geteilte Freigaben gelten nur gemeinsam.
- Maximal drei zukünftige Handoffs je NPC; stehende Belegung bleibt reserviert.
- Feldwechsel an start+ceil(duration/2), Gegenkante über volle Segmentdauer;
  gleichzeitig fällige Feldwechsel sind eine atomare Gruppe.
- Laufende Posthandoffkanten bleiben bis Ende erhalten; keine vorzeitige Ankunft.
- Read-Payloads sind Kopien. Hotpath-Unitreads finden ihre eigene kleine Route
  über einen ID-Index statt alle Segmente anderer NPCs abzusuchen.
- Release/Kontextwechsel räumen Zusagen; Terrainänderungen dürfen keine
  verbotenen Übergänge ausführen. Keine Actor-/UIwahrheit aus diesen Ereignissen.
- Bei Terrainrevisionen werden auch stehende aktive Korridorgruppen geometrisch
  neu geprüft. Ungültige Gruppen werden mit `hex_corridor_invalidated` verworfen;
  weiterhin legale Schritte bleiben erhalten. Eine neue Seitentür darf keinen
  Widerspruch aus zwingend erhaltener und zugleich verbotener Gruppe erzeugen.

## Lokale Prüfung / Grenzen

Neue kleine Cases `reservation_owner` und vorhandenes `reservation`, höchstens
zwölf Terrainfelder je Grundfixture. RED/GREEN vor Code, kein großes Gefecht,
keine native Bewegungs-/GPU-/Performanceabnahme. Konservativer local64-Graph
und existing_commitment-Grenze des reinen Planers bleiben sichtbar; kein
Versprechen allgemeiner Deadlockfreiheit oder global optimaler Korridore.
Vor aktiver großer Karte sind die übrigen AP4/5-/Lifecycle-/Savegrenzen nötig.
