# Driver: aktueller medizinischer Zustand vor Respawn-READY

## Ziel und Ursache

Ein früher Subscriber des bereits korrekt committeten Managercompleted-Signals
kann den echten Actor erneut verwunden. Der spätere Drivercallback darf dessen
neuen Downlinger nicht löschen und kein veraltetes READY senden.

## Umfang und Nichtziele

Nur Guard am Anfang von MissionCombatLoopDriver._on_unit_respawn_completed.
Bestehender reiner Root-Actorvalidator liefert Scope-/Registry-/Knownidentität;
echter Vitalstatus und Groundpräsenz werden frisch gelesen. Nur aktiver/deklarierter
Hexpfad, Legacy/PlainNode-Fixtures behalten bisherigen Callback. Keine Root-/
Manager-/Sicht-/AI-/Tick-/Net-/anderen Driverbodies ändern. Kein neuer Tickettakt,
kein Actorersetzungs- oder umfassender medizinischer Ereignisvertrag.

## Quellen und Akzeptanz

AGENTS und Projektpflichtdokumente; Hexruntimevertrag und
HEX_RESPAWN_TRANSACTION_2026_11_12. Historische echte Repro unter
output/native_glut_maps/medical_completed_consumer_order_20261112 bleibt erhalten.
Neue private Probe bindet Driver.simulation_root_path an tatsächlichen RigRoot.
Früher Completed-Subscriber ruft echtes apply_damage; echter Driver-Vitalhandler
erzeugt Downlinger. Später Drivercompleted muss ihn erhalten/READY unterlassen.
Positive Fitkontrolle muss weiterhin READY und Lingerbereinigung liefern.

## Dateien / Prüfung / Risiken

Ein Produktmethodenguard, diese Task und eigene private QA unter
output/native_glut_maps/medical_completed_consumer_guard_20261112.
Zwei gezielte tatsächliche Owner-/Consumerfälle, RED vor Fix und GREEN danach,
Godotimport/Compile, Quell-/Profil-/Canaryguards. Keine große Matrix/GPU/EXE/Git.
Rootcommit bleibt historisch erfolgreich; nur überholte Verbraucherseiteneffekte
werden unterdrückt. Der Guard ergänzt keine Spieleinheiten um Fakecapabilities.

## Ergebnis / Freeze

Sauberer tatsächlicher RED3/1 vor Produktänderung: ausschließlich intervenierter
Downfall falsch READY; Fitkontrolle bereits positiv. Nach acht additiven Guardzeilen
GREEN4/0, Import/Drivercompile Exit0, keine Engine-/Script-/Leakfehler. Quellhash-,
Originalprofil- und privater Canaryguard true. Nur diese zwei Fälle, keine Suite.
Historische vorherige Repro bleibt unverändert. Kein Stage/Commit.
