# Kampagnen-Playtest 10.11.2026 — Baseline und AP1

Basis 046b6d91a; laufende Nutzer-EXE r02 stimmt laut Buildbericht mit diesem Pin ueberein. Screenshot stammt vom Nutzer; der Prozess wurde nur lesend identifiziert, nicht bedient oder geschlossen.

Historischer Baseline-Quelllauf mit privatem APPDATA: 152/0, aber zwei fehlende generierte GLB-Caches erzeugten Enginefehler. Deshalb kein sauberer Baseline-PASS. Diese vier generierten Cachedateien wurden aus dem identischen Exportcheckout wiederhergestellt, keine Originalmodelle veraendert.

AP1 Regression RED 5 Fehler fuer fehlende produktive Boarding-/Abflugcontrols, Karten-Schiffsauswahl und lesbare Zielnamen. Struktur-GREEN 6/0. Echter Kampagnen-Zweiausflug ueber die neue sichtbare Einsteigen-Schaltflaeche: 151/0, Exit 0, keine Engine-/Scriptfehler. Beide Personen laufen physisch; kein Teleport, genau zwei Payload-IDs; expliziter Abflug erst nach Runtimebestaetigung. Zweimal Continue geprueft. Script: scripts/tests/playtest_20261110_extraction_loop.gd. Rohlogs lokal unter output/playtest_20261110.

Native Gestaltung, Karten-Picking und Aufloesungskollisionen werden im gemeinsamen nativen Abschluss geprueft; der Headlesslauf ist keine Stilabnahme. AP2..AP10 bleiben offen.

AP2 mode verifier 6/0. AP3 shared field footprint/skill/hover/dynamic-anchor verifier 11/0; real combined loop with landing away from spawn and immediate RMB path 152/0, Exit0/errors0. Historical TASK311 rotation check is 7/1 both here and on untouched source 046b6d91a (separate private profile); not a new regression or green gate. Native final comparison still outstanding.

AP6: endliche Container und atomarer Ausruestungstausch, Domain-Verifier ohne Fehler; echter Runtimepfad 7/0. Erster Gesamtlauf fand Pilot-Zugriff zu streng und wurde korrigiert, zweiter kompletter Kampagnenlauf 152/0, Exit0, keine Engine-/Scriptfehler. Neue Einkaufspruefung liest tatsaechliche Schiffsfracht statt Fernlieferung ins Basislager. Native Personalaufnahme kontrolliert: geteiltes Panel/echte Portraits vorhanden, lange Itemnamen und fehlende initiale Rucksackcontainer dabei gefunden und korrigiert. Kompaktere Geometrie/Planetmarker folgen AP7; DnD/Input und drei Aufloesungen bleiben AP10-Abnahme.
