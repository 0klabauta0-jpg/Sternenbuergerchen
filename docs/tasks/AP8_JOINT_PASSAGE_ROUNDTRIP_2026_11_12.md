# AP8: laufende Passage mit echtem Ground-/Movement-Roundtrip

## Ziel / Ursache
Bestehende12Tile-Teilprobe verbindet Bewegung, Rampe, Tuer, Detection, Sicht und
Angreifbarkeit. Neu sollen angenommene Passagezusagen UND echte Zielabsichten
im selben Rootkomponentenverbund einen JSONroundtrip durchlaufen und fortsetzen.

## Umfang / Nichtziele
Nur scripts/tests/hex_tactical_slice_verifier.gd, diese Task und eigene QA/Runner
unter output/native_glut_maps/ap8_joint_passage_roundtrip_20261112. Kein Produkt-
oder Sharedrunnerwrite, Stage/Commit, globale Kartenaktivierung, GPU/native/EXE.
ScreenbridgeWIP nicht kopieren/testen; bei HomebaseScreen in Closure Freeze fragen.

## APIs / Akzeptanz
Groundv2.export_state und Movementv1.export_state einer tatsaechlich laufenden
Passage. Ground.prepare_restore_state/get_prepared_restore_ground, Movement.
prepare_restore_state(...,targetGround). Beide echten validate_prepared_restore
VOR erstem Write; dann Ground._publish_prepared_restore und direkt Movementtail.
Keine handgeschriebenen Preparedresultate, kein Actorpositionwrite, keine neue
Ownerinstanz oder Runtimekonfiguration. Die bisherigen Consumers laufen danach
bis zu beiden echten Commandankuenften weiter. Nur bestehende12Hexes verwenden.

## Grenzen / lokale Pruefung
Kleiner privater RED/GREEN mit bestehenden Profil-/Quellguards und Canary.
PARTIAL/full_ap8=false bleibt: kein Rootcheckpoint, Serverpublikations- oder
Receiveranschluss, kein echter Netzwerkpeer oder vollständiger AP7-/AP8-Pass.

## Tatsächlicher Zwischenbefund
Neuer12Tile-JOIN erreicht die laufende Leader-Rampenpassage und exportiert Groundv2.
Movementexport lehnt das vom echten Root gestempelte Dictionaryfeld _hex_lifecycle
ab (movement_save_unsupported_command_field). Keine Fixturebereinigung oder
Produktschreibrechte dafür beansprucht. Guarded RED10/2 bei weiterhin acht grünen
bisherigen Consumerchecks liegt als actual_root_red.log/report im eigenen Paket.
Fortsetzung erst nach Ownerfix und Freeze; kein Erfolgmarker bei diesem Zustand.

## Abschluss / Freeze
Nach eingefrorenem Ownerfix erneuter ORIGINAL-RootJoin, kein Fixturestampstrip.
Export/Prepare/TargetCandidate/AllValidate/Groundtail/Movementtail und anschliessend
alle bestehenden Consumers gruen. Ein eigener Zusatzcheck hatte faelschlich eine
Peerauthoritaetspruefung am internen Movementvalidator erwartet; das ist keine
zugesagte API. Archiviert15/1, Fixture korrigiert auf tatsaechliche Root-Facing-/
Stop-/Releasegates. Final15/0, CompileExit0 und alle Quell-/Profil-/Canaryguards true.
Gleiche echten Root-/Ground-/Movement-/Registry-/KnownActors bleiben gebunden.
Keine Actorposition durch Restorefixture gesetzt. PARTIAL/full_ap8=false bleibt.
