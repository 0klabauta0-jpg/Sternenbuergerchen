# AP6b: verbindliche Root-Actorbindung

Integrationsreview des gesicherten `a74514742`: Ein nur in UnitRegistry geführter
Actor konnte zugelassen werden, obwohl der Root-Lookup lediglich auf die Registry
zurückfiel. Ohne register_known_unit fehlte das Tree-Exitcleanup und Actor.free()
konnte seine Groundzelle zurücklassen.

Root verlangt nun vor tatsächlicher Actorzulassung den expliziten gültigen
Known-Eintrag desselben Actors. Der tatsächliche Registry-only→Admission→free-
Fall scheitert damit ohne Groundmutation. Bestehende ordnungsgemäß gebundene
Actors behalten ihre bereits geprüfte Zulassung und ereignisbasierte Freigabe.

Kleiner privater Headless-Slotcase: sauberer RED87/1, GREEN88/0. Beide Original-
Reports/Logs in binding_fix_runs.zip, finale Quellenhashes und Profil-/Isolations-
guards in manifest.json. Keine neue Prüffläche, native Mission, große Matrix,
Performancebehauptung, EXE oder Kartenaktivierung. Die konkrete Produceranbindung
AP6 sowie AP7/8 bleiben weiter offen.
