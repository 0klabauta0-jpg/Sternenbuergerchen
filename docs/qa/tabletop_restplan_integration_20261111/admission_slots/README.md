# AP6b Gruppenvormerkungen im gemeinsamen Stand

Sourcea74514742 wurde erst gemeinsam mit Fix0535b3b2f importiert. Der enge
unabhaengige Review fand zuvor den Registry-only-Actor ohne Root-Exitbindung;
der Nachreview bestaetigt dessen Korrektur. Elternimporte68ca862aa/0a63027d7.
Nur additive Status-/Roadmapkonflikte, Produktcode konfliktfrei zusammengefuehrt.

Frischer privater gemeinsamer Lauf:
`python scripts/tests/run_hex_tactical_check.py --case admission_slots`
88 bestanden, 0 Fehler, Quell-/Spielerprofilschutz und Isolation bestaetigt.
Exakte Quelldateihashes und Log liegen bei. Keine erneute breite Testmatrix.

Ground besitzt alle reservierten Gruppenplaetze; Personen an Bord erhalten
noch keine Bodenbelegung. Einzelne echte Deployeffects uebernehmen einen Slot.
Abbruch, Terrainwechsel und Despawn raeumen ungenutzte Slots auf; alte Move-/
Embarkpayloads sind an Actorlebenszyklus und Ortskontext gebunden. Neue Admission
verlangt nun ausdrueckliche Root-Knownbindung desselben Actors.

AP6c-Controllersequenz, produktiver Setup-/Deployadapter und Basisaktionen sind
noch nicht fertig; neue Hexdeploy-Anwesenheit verlangt admission_id. Keine
Produktionskartenaktivierung. AP7/8 folgen, grosse AP9-Abnahme spaeter. Keine EXE.
