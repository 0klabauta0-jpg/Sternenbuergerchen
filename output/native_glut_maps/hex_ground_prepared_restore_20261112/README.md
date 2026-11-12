# Ground Prepared Restore — begrenzter Ownernachweis

Godot4.6.2, privates Projekt ohne Hauptszene und mit frischem privaten
Userverzeichnis; genaue Pfade und Quellhashes stehen in report.json.
Originalprofil vor/nach unverändert, Isolationcanary vorhanden, alle kopierten
Quellen nach Lauf unverändert. Keine Laufzeit-/Profilkopie des Spiels gelesen.

Ergebnis:14/0, Import0, Ground-Einzelcompile0; keine Script-/Enginefehler oder
Leakmeldungen. run.py baut ausschließlich die echte Preloadclosure der Fixture.
Die Fixture verwendet echten Ground/Terrain/Tile und höchstens12 Felder.

Geprüft: mutierungsfreies Prepare, detached Zielground, fehlender Inputalias,
öffentlicher Publish in dieselbe Liveinstanz, kein Target→Livealias, verbrauchte
und fremde Handles, Revision-/Tick-/Terrainrace, Kandidatenmutation,
same-object Reconfigure, atomare Ablehnung ungültigen Savezustands sowie echter
validierter privater Tail. Saveziel verwendet das heutige V2-Schema und die
bestehende Savevalidierung; deren gesamte35er Matrix wird hier nicht wiederholt.

API: prepare_restore_state(state), get_prepared_restore_ground(handle),
validate_prepared_restore(handle), publish_prepared_restore(handle).
Root-private _publish_prepared_restore(handle,validation) ausschließlich nach
ALLEN Ownervalidierungen, ohne Callback/await dazwischen. Der Getter ist eine
Leseliehgabe für Movementprepare, keine zusätzliche Gameplayautorität.
Ein separat vorbereiteter Wertpatch verhindert Aliasbesitz durch den Zielground.

Nicht nachgewiesen: atomarer Root-/Movementverbund, Checkpointaktivierung,
Basis-/Transportrestore, AP7/AP8 insgesamt, Netzfilter, native Ansicht oder FPS.
Produktkarten und Sharedrunner unverändert. Kein Stage/Commit.

Kanonisch: diese README, run.py, report.json, import.log, ground_compile.log,
check.log, .gdignore und SHA256SUMS.txt; dazu Produktdatei, neue Task und Verifier.
Private Projekte unter .godot sind Ausführungskopien, keine Integrationsdateien.
