# Kampagnen-Playtest 10.11.2026 — Baseline und AP1

Basis 046b6d91a; laufende Nutzer-EXE r02 stimmt laut Buildbericht mit diesem Pin ueberein. Screenshot stammt vom Nutzer; der Prozess wurde nur lesend identifiziert, nicht bedient oder geschlossen.

Historischer Baseline-Quelllauf mit privatem APPDATA: 152/0, aber zwei fehlende generierte GLB-Caches erzeugten Enginefehler. Deshalb kein sauberer Baseline-PASS. Diese vier generierten Cachedateien wurden aus dem identischen Exportcheckout wiederhergestellt, keine Originalmodelle veraendert.

AP1 Regression RED 5 Fehler fuer fehlende produktive Boarding-/Abflugcontrols, Karten-Schiffsauswahl und lesbare Zielnamen. Struktur-GREEN 6/0. Echter Kampagnen-Zweiausflug ueber die neue sichtbare Einsteigen-Schaltflaeche: 151/0, Exit 0, keine Engine-/Scriptfehler. Beide Personen laufen physisch; kein Teleport, genau zwei Payload-IDs; expliziter Abflug erst nach Runtimebestaetigung. Zweimal Continue geprueft. Script: scripts/tests/playtest_20261110_extraction_loop.gd. Rohlogs lokal unter output/playtest_20261110.

Native Gestaltung, Karten-Picking und Aufloesungskollisionen werden im gemeinsamen nativen Abschluss geprueft; der Headlesslauf ist keine Stilabnahme. AP2..AP10 bleiben offen.
