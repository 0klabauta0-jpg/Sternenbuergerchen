# Windows-Paket und öffentliche Spielanleitung

## Ziel und Ursache
Zuerst eine startfähige Windows-EXE aus dem integrierten GitHub-Stand bauen und
ausliefern. Danach eine öffentliche, mobil lesbare Spielanleitung erstellen,
die Bedienung, Orte, Kampagne, Koop/PvP und die tatsächlichen Trefferwürfe erklärt.
Der private Arbeitsbericht bleibt privat.

## Basis und Umfang
Bewusst aktuelles Main `39c36fa4ccd0c5c16ab357dee2b2208aeb961566`, da dieser
integrierte Stand ausgeliefert werden soll. Eigener Taskbranch; fremdes WIP im
Hauptcheckout bleibt erhalten. Bestehender Godot-4.6.2-Exportweg, notwendige
Runtime-Dateien, Buildnachweis und kleiner Starttest des exportierten Pakets.
Keine neue breite Reviewrunde, keine Desktopübernahme, keine Änderungen echter
Spielstände. Ein erfolgreicher Fünfer-Kampagnendurchlauf bleibt unbestätigt.

## Dokumente
- docs/dev/export_runtime_package_contract.md
- data/export_runtime_package_contract.json
- docs/dev/productive_hex_rollout_contract.md
- docs/dev/combat_loop_authority_contract.md
- docs/dev/starmap_smart_mobile_contract.md
- docs/qa/review_completion_20261113/summary.json

## Akzeptanz
- Quellstand auf GitHub geprüft; Export einem vollständigen Commit zugeordnet.
- EXE, PCK und benötigte DLLs vollständig, Hashmanifest vorhanden.
- Echter Paketstart in isoliertem Profil, ohne aktive Desktopfenster und ohne
  Parse-/Ladefehler; Umfang des Tests ausdrücklich dokumentiert.
- Öffentliche Anleitung aus aktuellem Runtimecode abgeleitet, Trefferformeln
  einschließlich Grenzen und Beispielen nachvollziehbar. Keine geplanten
  Funktionen als vorhanden ausgeben; Unterschiede zwischen Boden und Raum nennen.
- Mobil bedienbar, Tastaturbedienung und interne Links geprüft, öffentliche
  Veröffentlichung und Zugang ohne Anmeldung verifiziert.

## Dateien und Prüfungen
Exportskripte/-vertrag nur bei nötigem Buildfix; Nachweise unter
docs/qa/windows_release_20261114/. Anleitung unter docs/player_guide/.
Build-/Paket-Smoke, gezielte Fehlerregression bei tatsächlichem Fix und
Headless-Browserprüfung der Anleitung. Keine EXE-Binaries im normalen Gitverlauf.

## Risiken
Exportvorlagen/ungepackte Laufzeitressourcen können den Build blockieren.
Ein Starttest ersetzt keine vollständige Kampagnen-, WAN- oder FPS-Abnahme.
Unsignierter Windows-Playtestbuild; Paketdateien müssen zusammenbleiben.
