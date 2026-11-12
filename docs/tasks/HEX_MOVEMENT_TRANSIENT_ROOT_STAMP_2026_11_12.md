# Movementsave: echten transienten Rootstempel behandeln

## Problem / Ziel
Root.enqueue_command stempelt echte Bewegungsbefehle mit _hex_lifecycle. Der
portable Movementsave muss diese abgeleitete inprocessIdentitaet validieren und
auslassen; alte ActorIDs duerfen nicht als Commandabsicht restauriert werden.
## Umfang / Nichtziele
Nur neuer Savepackpfad in hex_movement_command_runtime.gd und eigenerTask/QA.
Keine stage_move/tick/readout/Root-/Sharedrunneraenderung. Andere unbekannte
Commandfelder weiter rejecten, keine Bereinigung echter Rootfixture.
## Strategie / Akzeptanz
Vorhandenes _hex_lifecycle nur exakt {context,lifecycle,actor} mit echten Integern
und gueltigem Wertebereich akzeptieren, dann gebundenen echten
Owner._is_current_hex_payload(command) pruefen. Erst dann beim Packen auslassen.
Stale/malformed/unknown Marker failclosed. Restore bleibt unstamped und nutzt
bestehende PreparedActor-/Owner-/Groundbindungen; spaetere Rootcommands stempelt
Root selbst neu. Kleine echteRoot.enqueue_command->Movementprobe plus Stale/
Malformed/UnknownHostmarker und PortableRoundtrip, RED/GREEN mit privatem Runner.
## Dateien / Grenzen
Runtime, output/native_glut_maps/hex_movement_transient_root_stamp_20261112,
dieseTask. Root-AP8Join laeuft danach separat beim Parent/AP8Agent. Keine volle
Rootcheckpoint-/Spiel-/Performancefreigabe, keine grossen Tests/Gitaktionen.

## Ergebnis
Produktfreeze, echteRootprobe RED1/1 -> GREEN9/0 inklusive Compile und allen
Isolationsguards. SourceDTO unveraendert, keine Fixturebereinigung/Rootedits.
Exakte Runpfade und Dateihashes im eigenen README/Manifest. Parent/AP8Agent kann
Originaljoin unveraendert wiederholen. Keine Stage-/Commit-/Sharedrunneraktionen.
