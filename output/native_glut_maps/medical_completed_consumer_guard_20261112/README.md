# Drivercompleted: ein Consumerfehler, zwei tatsächliche Fälle

Godot4.6.2, privates Projekt/Profil ohne Hauptszene. Driver.simulation_root_path
ist auf den echten RigRoot gebunden. Echter Root, Manager, Ground, TestUnit und
Medical-/Completedhandler; kontrolliert werden ausschließlich Driver-Ready und
UI-/Broadcastgrenzen. Keine medizinische Modell-/Receiptfälschung.

RED vor Produktfix:3/1, check Exit1, Import/Compile0; red.log und red_report.json
bewahren Quellhashes und Ergebnis. Ein früher Completed-Subscriber sieht echten
committedReceipt/Fit/neuesGroundziel, ruft dann echtes apply_damage(1000).
Echter Driver-Vitalhandler setzt neuen Downlinger. Bisher löschte anschließend
Drivercompleted den Linger und meldete READY trotz Down. Dieser Fall ist RED.

GREEN nach genau acht Guardzeilen:4/0, check/Import/Drivercompile0; report.json
und check.log sind kanonisch. Neuer Down behält Linger und DOWN, kein READY.
Positive Fitkontrolle meldet weiterhin READY und räumt den alten Downlinger.
Dafür wird nur ihr separater Vital-Subscriber vor dem tatsächlichen Fitcommit
abgehängt, damit Completedcleanup beobachtbar bleibt. Actor/Root/Manager laufen
unverändert; keine medizinischen Werte werden dafür gesetzt.

Der Guard arbeitet ausschließlich für den vorhandenen Hexpfad, liest den reinen
Root-Actorvalidator und aktuelles Fit/Embarked/Ground. PlainNode-/Legacypfade ohne
Hexcapability laufen unverändert. Keine Root-/Manager-/anderen Driverbodywrites,
kein neuer Ticket-/Ereignisvertrag. Actorersetzung/Netz/Native/GesamtAP6/7/8 werden
nicht durch diese zwei Fälle abgenommen.

Source-/Originalprofilidentität und privater Canary jeweils true. run.py
kopiert die echte Preloadclosure und unterdrückt die geerbten Suitecallbacks;
dieser Lauf enthält ausschließlich die zwei expliziten Consumerfälle.
Historische Repro medical_completed_consumer_order_20261112 bleibt unverändert.

Kanonische Dateien: .gdignore, check.gd, run.py, import.log, driver_compile.log,
check.log, report.json, red.log, red_report.json, red_driver_compile.log,
README.md, SHA256SUMS.txt. Private Projekte unter .godot nicht integrieren.
Kein Stage/Commit, keine GPU-/Main-/breite Matrix.
