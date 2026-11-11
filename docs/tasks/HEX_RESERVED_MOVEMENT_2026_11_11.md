# AP5: reservierte Bewegung mit stetiger Darstellung

Ziel/Ursache: Tatsächliche Move-Commands müssen über die autoritativen Zusagen
laufen. Renderframes dürfen Positionen darstellen, aber keinen Feldbesitz oder
Sicht-/Erkennungszustand fortschreiben. Basis04dc691bb auf eigenem Taskbranch.

Verträge: explicit_hex_ramps_contract.md, hex_tactical_runtime_contract.md,
hex_reservation_plan_contract.md und AP5 im Arbeitsplan. Dateien: Ground,
SimulationRoot, FireteamMovementController, gezielter Actorpositions-/Höhenleser
in TerrainMap3DView, Türmutationsowner und kleine isolierte Verifier.

Umfang in kleinen Schritten:
1. Reine Motionprojektion samt gemeinsamer Rampenendpunkthöhe; Rootreadadapter.
2. Gebündelte echte Move-Absichten, vorhandene Geschwindigkeit/Terrainfaktoren,
   Tickdauern aus physischem Hexmaß; kein Halt an jedem Zentrum.
3. Continuation, tatsächliche Zielankunft und sichere Auftrags-/Verwundungs-
   behandlung; keine verwaisten eigenen oder fremden Zusagen.
4. Aktive Hex-NPCs aus Legacy-Avoidance/Spacing-Mutationen nehmen; Actorvisuals
   lesen Projektion. Türschließen während belegter/zugesagter Passage beim
   bestehenden Mutationsowner abweisen oder verzögern.

Nichtziele: aktive große Karten, Basis-/Save-/Netzwerkumbau (AP6/7), breite
Gefechts-/GPU-/Performancetests oder EXE. Koordinierendem Chat vorbehaltene
View-Raster-/Kamera-/Deckownerfunktionen und MissionSetup-Kamerafunktion erhalten.

Akzeptanz: kleine Folge-/Gegenverkehrsfixtures, Mitte und Segmentende getrennt,
sechs Richtungen gleiche physische Geschwindigkeit, Rampe längs und passend
seitlich, Plateauflanke gesperrt, Revision/Ankunft/Abbruch und Legacyzweig.
Rampenprojektion verbindet Zentrum→geteilten Endpunkt→Zentrum; Plateau bleibt
bis zur Kante flach. Read-/Rendercalls mutieren keine Gameplayrevision.

Lokale Prüfung: RED/GREEN pro schmalem Schritt, höchstens zwölf Felder je
Bewegungsfixture. Frischer Review vor kohärentem Commit; große Tests später.

Risiken/offen: Abbruch während gemeinsam zugesagter Freigaben verlangt eine
sichere gemeinsame Stoppgrenze; bloßes Löschen eigener Zukunftsschritte wäre
falsch. Türguard und Basis-/Saveüberlappung vor Änderung konkret abstimmen.
Skillabhängiger Bewegungsschussabzug ist als Verhalten gefordert; Zahlen sind
noch keine abgenommene Balance und vor Aktivierung ausdrücklich kenntlich zu machen.

Erster gesicherter Teil: reine Motionprojektion56/0, Rootowner53/0,
Facingregression24/0. View-/Actor-/Commandanbindung ist damit noch nicht erfolgt.
Frischer Review schloss Nichtregional-0-Sentinelregression mit33/1→53/0.
Höhenskala ist nun reiner Readparameter aus vorhandenem Darstellungsowner,
keine neue Konfigurationsvoraussetzung oder gespeicherte Ground-Wahrheit.
