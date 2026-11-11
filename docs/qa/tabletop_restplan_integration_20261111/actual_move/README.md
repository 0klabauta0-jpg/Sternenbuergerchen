# AP5 echte Movecommands: gemeinsame Integration

Quelle a66b84522a1cc3d34d7dd22e9460735c9cd77788, Parent d00eba780.
Unabhaengiger enger Readonlyreview ohne konkreten Blocker. Als c5e536d0d auf
unseren Polisa-Abholstand d539cbe89 uebernommen. Einziger Mergekonflikt:
.gitattributes-Append, beide Evidenzpfadsaetze vollstaendig erhalten. Root und
Implementierungsstatus automatisch zusammengefuehrt; eigene Warp-/Equipment-
Requesthooks unveraendert erhalten, keine Ship-/Meta-/Viewbodies im Quellpatch.

## Frische gemeinsame Pruefung
`python scripts/tests/run_hex_tactical_check.py --case movement`:42/0, Prozess0,
Quellguard und private Canary gueltig, echtes Nutzerprofil unveraendert.
movement_report.json enthaelt die tatsaechlichen gemeinsamen Quellhashes und
Ausfuehrungspfade; movement.log den vollstaendigen Originaloutput. Isoliertes
Projekt, Root/UnitRegistry/CapabilityActors, keine Hauptszene/echte Schlacht.

Polisa-Return-Vertikalprobe im selben Rootstand erneut18/0. Echter bestehender
Presencecommit und Ownerheimkehrpfad; Weg-/Animationsendpunkte sind kontrolliert
gesetzt/ausgeloest, keine native Reise-/Spielgefuehlsabnahme. Root und neuer
HexMovementCommandRuntime separat check-only0. Logs/results.json daneben.
Keine alte komplette Hexnachbarmatrix wiederholt; deren Sourcebelege bleiben
in docs/qa/hex_move_commands_20261111.

## Umfang / Grenzen
Angenommene Ziele, inkrementelle Navigation mit Dauerprofilcache, echte Ground-
Zusagen, logische Ankunft/Hold/Wunde, stetige2DActorprojektion/Facing und
logisches Capture; parallele LegacyAvoidance/Spacing fuer zugelassene Hexunits
unterbunden. Keine Produktionskarte aktiviert. 3DView-/Fireteamankunft,
Tuermutationsguard, Bewegungsschuss/Backoff und AP6–8 Lifecycle/Save/Authority
bleiben im Tabletop-Chat. Keine breite Performance-/GPU-/Netz-/Gefechtsabnahme,
kein Mainmerge und keine neue EXE.
