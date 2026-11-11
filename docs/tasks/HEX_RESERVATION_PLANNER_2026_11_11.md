# AP4: reiner Hex-Reservierungsplaner

Basis: task/native-glut-maps-20261110, 7c9b5c7b1; bewusst nicht Main.
Ziel/Ursache: Feld- und Gegenkantenintervalle aus einem Owner-Snapshot planen,
ohne eine zweite Belegungswahrheit oder aktive Bewegung einzufuehren.
Umfang: neuer statischer build_hex_plan-Einstieg im bestehenden Resolver,
eigener Verifier und eigener Snapshotvertrag. Legacy-APIs bleiben unveraendert.
Nichtziele: GroundOwner/SimulationRoot/Driver/Runner/Actors mutieren, AP5,
Main/EXE, GPU und grosse Tests. Kein Commit/Push dieses Teilauftrags.
Vertraege: explicit_hex_ramps_contract.md, hex_tactical_runtime_contract.md,
hex_reservation_plan_contract.md und AP4 des Plans 2026-11-11-hex-sight-occupancy.
Akzeptanz: reine Planung, Versionsgate, stationaere Belegung, halboffene
Intervalle am handoff_tick, Gegenkanten, drei Schritte/16 neue Requests,
vollstaendige pending-Anfragen, deterministische Prioritaet/Wartezeit und
Rampenuebergaenge aus TerrainTileData. Kleine Fixtures maximal zwoelf Felder.
Dateien: scripts/tactical/bottleneck_reservation_resolver.gd,
scripts/tests/hex_reservation_verifier.gd, eigener Contract und QA.
Pruefung: isoliertes Privatprojekt nur mit Preload-Closure dieses Verifiers;
RED/GREEN und git diff --check; bestehender Runner wird nicht editiert.
Risiken: Owner muss denselben versionierten Snapshot und Atomarcommit liefern.
AP5 und Lifecycle sind separate Arbeit. Reservierungszusage allein bewegt nichts.

Ledger: Schema vor Code an Root gesendet, kanonischer handoff_tick nach Spec
bestaetigt. Snapshot-Keyfreeze wird mit Tabletop abgestimmt.

Abschluss: Keyfreeze mit Tabletop bestaetigt: reservation_schema_version:1,
committed_segments und committed_corridor_grants zwingend; kanonischer
handoff_tick, keine redundanten End-/Leave-/Enterzeiten. Reiner Planer und
lokaler64Feldgraph implementiert, 16Requests/3Schritte, Ruecksetzsuche ueber
denselben Graph mit gemeinsamem64Besuchsbudget. Kein langlebiger Cache.
Privatfixture RED0/1 wegen fehlender API beobachtet; GREEN26/0, Import/RunExit0,
keine Script-/Leakfehler. Unabhaengiger Review des erstenFreeze ohneBlocker;
abschliessende kleine Raeumausnahme separat zum Nachreview gemeldet.
QA: docs/qa/hex_reservation_planner_20261111/README.md.
Offen bleiben Ownercommit/AP5, bewusste konservative Wartebehandlung vor
ausstehenden Commitfeldwechseln und grosse Tests. Keine Main-/EXE-Integration.
