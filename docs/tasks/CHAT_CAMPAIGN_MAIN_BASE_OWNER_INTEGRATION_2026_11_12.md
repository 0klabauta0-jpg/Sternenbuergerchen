# Main-Port: Basis- und Supply-Owner

## Umfang und Grund
Die Chatfunktionen fuer Anwerbung, Shuttle-Heimweg, Originalbetten, modulare
Raeume und Lager bauen auf einer gemeinsamen juengeren Basis-/Hex-/Supply-
Implementierung auf, die auf Main fehlt. Der Chat-Diff laesst sich auf dem
aelteren Main nicht unmittelbar anwenden. `base_personnel_runtime.gd`,
`singleplayer_supply_state.gd`, `base_capacity_layout.gd` und
`base_interior_navigation.gd` werden deshalb aus dem Chatcommit uebernommen;
dazu die direkt benoetigten Raum-, Bett-, Fahrzeug-, Inventar- und
Supply-Contracts. Kein pauschaler Merge der Elternhistorie.
Die 20-zeilige Erweiterung des Basisactors stellt die erwartete
Ausrüstungsprojektion bereit. Der Checkpoint-Store wurde inklusive der
Validierung für erweiterte Mannschaften, Stationspersonen und Schiffsbelege
übernommen; dafür ist der Schiffs-Komponentenowner erforderlich.

## Mituebernommene Ownerpfade
Der Basisowner umfasst dabei auch seine zuvor vorhandenen Hex-Ground-,
Transport-/Checkpoint- und Infrastrukturpfade. Der Supply-Owner umfasst
ausserdem bestehende Forschungs-, Stationsschiff-, Komponenten- und
Skirmishpfade. Diese Semantik ist Bestandteil der uebernommenen Owner und
muss gegen die Main-Umgebung und deren bestehende Spielstaende regressions-
geprueft werden. Forschungskatalog und zugehoerige Definitionsdaten sind
direkte Laufzeitabhaengigkeiten; Stations- und Schiffskataloge werden im
separaten Stationsport betreut.

## Pruefung und Grenze
Raumplan, bezahlte Betten, echte Lagerkapazitaet und Save/Continue sowie
Anwerbungs- und Shuttlefolgen muessen auf dem integrierten Main-basierten
Stand erneut laufen. Eine einmalige Godot-Importpass/Class-Registry ist vor
der Interpretation von Tests erforderlich. Ein erster Versuch auf dem frischen
Worktree gab zwar Domain-PASS-Marker aus, zeigte aber fehlenden Class-Cache und
Autoload-Compile-Errors; er ist ausdruecklich KEIN Pruefnachweis.

Nach gemeinsamem Headless-Reimport und Ergaenzung der benoetigten
Ruestungsassets bestanden Raumplan, Lager, Geometrie, 64 Tuerdrehungen,
Originalbettmesh, echter Bett-/Gang-/Schlaf-/Continue-Pfad, echter
Lagercheckpoint und Unterkunfts-Altstand (8/8, Bericht
`output/base_port_checks/20261112T132703Z-pid37432/metadata/report.json`).
Der urspruengliche Main-Personalverifier wurde an den bereits geltenden
Vertrag angepasst: manueller Bewegungsauftrag unterbricht Schlaf, und ein
Checkpoint-Pilotentausch aktualisiert Craft und Fleet konsistent. Der Test
prueft erneuten Schlaf und Continue und besteht danach, Bericht
`output/base_port_checks/20261112T133049Z-pid5556/metadata/report.json`.
Die Output-Berichte sind lokale Artefakte, keine committeten Dateien. Der
Editorimport meldete weiterhin eine ObjectDB-Warnung und ist separat rot.

Der Main-Vorbereitungs-/Continue-Test deckte einen Unterschied in der
Ausrüstungssemantik auf: Main besaß anfangs zwei leichte Rüstungen im Lager,
aber der frühere Loadoutwechsel prüfte keinen Besitz; der Chatstand prüft
Inventar und lässt Figuren im Unteranzug starten. Der Main-Lagerbestand bleibt
erhalten, die Startfiguren werden im Neuspiel gezielt auf `suit` gesetzt und
der Loadoutcontract um `suit` ergänzt. Ein echter Test prüft Inventarentnahme,
Continue einer angelegten leichten Rüstung und Inventarrückgabe beim Ablegen;
er besteht (`output/base_port_checks/20261112T133735Z-pid16132/metadata/report.json`).

AP7 wurde selektiv mit dem neuen Root-/Ground-/Movement-Composite verbunden.
Der echte Save/Continue-Prueflauf in einem eigens kopierten Projekt besteht
17/0; die negative Continue-Pruefung auf unveraenderter nicht aktivierter
Basisnavigation besteht 3/0. Der Lauf bestaetigt unveraenderte Quelldateien
und ein isoliertes Profil; Report `.godot/hex_campaign_continue/8caa12219e4c47f1a4dc14054011b4d1/report.json` (lokales Artefakt).
Hex-Autosave wird nach 300000 ms erneut zugelassen; ein forcierter Aufruf
umgeht nur das Intervall und nicht Guard-, Transit- oder Pending-Sperren.
Der Grenz-/Guard-Test besteht (`output/base_port_checks/20261112T134258Z-pid25632/metadata/report.json`).

Nach selektiver Integration der Raum-/Luft-Simulationshunks wurde die Basis-/
Companion-Regression erneut ausgefuehrt: 11/11 (Raumplan, Lager, begehbare
Geometrie, Tuerdrehungen, Originalbett, Schlaf-/Continue, Altunterkunft,
Cargo, Shuttle und Autosave). Bericht lokal unter `output/base_port_checks/20261112T135753Z-pid32540/metadata/report.json`.
