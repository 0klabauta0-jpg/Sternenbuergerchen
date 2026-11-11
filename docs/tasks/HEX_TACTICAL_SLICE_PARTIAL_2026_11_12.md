# AP8: kleiner zusammengesetzter Hex-Kandidat (Teilprobe)

## Ziel / Ursache
Eine neue hoechstens12Hex-Fixture verbindet vorhandene Groundbewegung, Rampe, echte Tuermutation, logische Sicht/Erkennung und Schusspruefung. Das ist ein begrenzter Zusammenschluss vorhandener Owner, keine neue Gameplayregel und keine produktive Kartenaktivierung.

## Scope / Nicht-Ziele
Nur neue scripts/tests/hex_tactical_slice_verifier.gd, diese Task und eigene QA. Keine Runtime-/Runner-/SharedDoc-/Gitmutation. Keine geerbte Gesamtmatrix, GPU, EXE oder A/B/C-Gefechte. Plan AP8: docs/superpowers/plans/2026-11-11-hex-sight-occupancy.md; hex_tactical_runtime_contract.md. Aufbauhilfe: vorhandene movement/door_guard/sight_consumers Fixtures, nicht deren gesamte Prueflisten.

## Aufbau / Akzeptanz
Zwoelf echte Terrainhexes: zehn im schmalen Korridor plus zwei getrennte Ausgaenge; H0, explizite Rampe, H1 mit geschlossener Tuer. Zwei registrierte Root-gebundene Capability-NPCs mit echten Commands warten davor; nach echter Driveroeffnung passieren sie exklusiv nacheinander. Ziel-NPC besitzt eigene logische Zelle. Driver/VisibilityCache/Detection lesen Feld und Facing, FireDecisionResolver prueft aktuelle Sicht; Root bestaetigt wirkliche Commandankunft. Actorimplementierungen liefern nur Capabilitymethoden, keinen Bewegungs-/Sicht-/Restoreowner. Driver subclass unterdrueckt lediglich automatischen Szenenstart.

## Aktivierungsgrenze / AP7 fehlt
Aktuell gibt es weder HexGroundRuntime.export_state()/restore_state() noch den AP7-Root-/Checkpoint-/Peeranschluss. Kein DummyRestore wird eingefuehrt. Die Probe meldet hoechstens HEX_TACTICAL_SLICE_PARTIAL_READY mit full_ap8=false; niemals den finalen HEX_TACTICAL_SLICE_PASS. AP6c/AP7 bleiben Tabletopownerarbeit. Nach dessen gesicherter API muss die endgueltige AP8-Abnahme separat erweitert werden; Teilprobe Exit0 ist keine Vollfreigabe.

## Dateien / lokale Pruefung / Risiken
Neue Fixture, eigener QA-Unterordner output/native_glut_maps/hex_tactical_slice_20261112 mit isoliertem Einzellauf und Manifest. Frisches privates Projekt/Profil, vorhandener Isolationguard, Kopie der tatsaechlichen Preloadclosure; Source- und Nutzerprofilhashschutz. Nur vorhandene Teile eng ausfuehren, Compile. Fehlender Restore-/Authorityowner bleibt explizit offen. Keine breite Testmatrix, keine native Darstellung-/Performancefreigabe, kein Staging/Commit.

## Teilstand / Freeze
Arbeitsbasis 2f47421c0. Neuer isolierter Einzellauf: 8 Checks, 0 Fehler; privater Einzelcompile Exit 0. Sourcehashschutz, echter Nutzerprofilhashschutz und privater Isolationcanary jeweils true. Evidenz Passage leader→follower, Rampenstandhoehe H+0.5 und erkannter logischer Beobachter bei (7,0). Kein Damageeffect/echtes Gefecht, sondern echte aktuelle Angriffbarkeitspruefung des FireDecisionResolvers. Driverstartup allein kontrolliert; Einheitlookup ueber echten UnitRegistry, Erkennung ueber vorhandenen Driver/HexDetectionState. AP7 export_state=false/restore_state=false; Checkpoint-/Peerowner nicht geprueft. AP6c-Producer-/Transportlebenslauf bleibt ausserhalb dieses Teilstands. Endgate weiterhin full_ap8=false.
