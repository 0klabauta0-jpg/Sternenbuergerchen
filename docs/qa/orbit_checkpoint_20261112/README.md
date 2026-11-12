# Lokale Orbit-Checkpointbausteine, 12.11.2026

Godot4.6.2, isolierte Profile/harte65-s-Grenze. Befehle, Dauer und Profil sind
jeweils im gleichnamigen JSON erhalten; vollständige stdout/stderr unverändert.
Bei Scriptfehler beendet der kleine Runner ausschließlich seinen eigenen Prozess.

Abschließende gezielte Belege:
- flight-/travel-/fleet-strategic-regression: jeweils PASS und exit0.
- local-flight-normal-ticks: Root-Launch, kanonischer Mondorbit, Entry, Move,
  detached Fleet/Travel/Flight, Warpdeparture, gleiche Request-Replays und
  manipulierte/fehlende Maps/fehlgeschlagene Ownerexports:123/0, exit0.
- local-surface-canonical-cache-fixed: tatsächliche Root-Bewegung über1610
  normale0.05-s-Simulationsschritte zum echten Surfacegate, Departure,
  finish_approach, Inactive-Roundtrip, terminale Intent-Fixtureprojektion,
  frische Fleet/Combatbindungen und tatsächlicher fuel-backed Localreturn:
  33/0, exit0. Nichtkanonische Bodycachemaske ausdrücklich abgewiesen.
- receipt-prebinding-final:29/0, exit0.
- orbit-intent-final:39/0, exit0.
Alle abschließenden Prüfungen ohne Script-/Parse-/Compile-/ERROR-/
Leakzeilen und mit leerem stderr. Kein nativer Renderer oder Echtzeit-FPS-Beleg.

Korrekturen / erhaltene rote Diagnostik:
- Erste Receiptprüfung fand unzulässige Typinferenz; explizites bool korrigiert.
- Anfangs fehlte zwischen zwei echten Area-Übergängen im Fixture ein normaler
  Folgetick; jetzt führt das Fixture tatsächliche Root-Ticks aus, ohne Tick-
  Zähler, Flightpose, Actor, Tempo, Timer oder Receipts zu überschreiben.
- Der historisch benannte _fixture_area_blockers ist laut tatsächlichem
  Runtimeproducer ein deterministischer kanonischer Bodymaskencache. Ein
  pauschaler Guard sperrte damit normale laufende Flüge. Nun werden Masken
  exakt gegen die kanonische Geometrie geprüft und für Frische gestempelt;
  sie werden nicht als zweite Geometriewahrheit gespeichert. Ziel baut lazy neu.
- Frühere rote und diagnostische Protokolle bleiben als solche erhalten.

Grenzen: echte Ownerproducer, aber Adapter-/Pilotgates sind Fixtureeingaben;
terminales Intent ist ausdrücklich Fixtureprojektion. Simulationsschritte sind
kein zusätzlicher 1×-Rundflug. Full-Datei-/Scene-Continue und anschließende
Produktbefehle bleiben Companion-Gesamtgate. Die echten neuen A/B-Rundflüge
84/0 liegen getrennt in ../two_moon_native_roundtrips_20261112.
Capability bleibt standardmäßigfalse, Polisa direkter Reiseweg. Atmosphären-
/Combat-/Stationbirth-/instabile Übergangssaves bleiben ausdrücklich gesperrt.
