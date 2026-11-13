# Frischen Editorimport eingrenzen — 13.11.2026

Basis `6bdc3b5ef`, Branch `task/editor-import-font-20261113`. Keine Übernahme
von Desktop, Tastatur oder Maus. Engine bleibt Godot 4.6.2; vorhandener
Projektcache, Originalprofile, Quellen und fremdes WIP bleiben erhalten.

## Bisher belegte Diagnose

Der frühere Mainimport ist nativ abgestürzt: Windows ApplicationError 1000
und WER 1001, Ausnahme `0xc0000005`, Moduloffset `0x3cde7c2` in `godot.exe`.
Siehe `previous_crash_events.json`. Passender lokaler Minidump vom 13.11.,
06:41:53: `Godot_v4.6.2-stable_win64.exe.15804.dmp` unter LocalAppData/CrashDumps.
Statische Prüfung durch den Agenten: ungültiger READ von `0xffffffffffffffff`,
RIP `0x7ff6cbf9e7c2`, Modulbase `0x7ff6c82c0000`; PE-Unwindfunktion im Bereich
`0x3cde300–0x3cded31`. Installierte EXE ohne lokale passende Symbole/PDB;
kein belastbarer Funktionsname. Der Dump wird wegen möglicher Speicherinhalte
nicht eingecheckt. Kein Debugger an einem Nutzerprozess und keine Downloads.

Der letzte Fortschritt nennt die Gamecube-TTF. Das beweist keine Fontursache.
Agentprüfung fand korrekte SFNT-Tabellenchecksummen/-grenzen, normale Größen,
keine extremen Boundingboxen und keine aktiven Pfad-/UIDreferenzen auf diese
beiden Rohassetfonts in scripts/scenes/data/shaders/project.godot. Das ersetzt
keinen Outlineinterpretertest.

## Kleine ausführbare Proben

`python docs/qa/editor_import_font_20261113/probe_fonts.py`

Je frisches privates Projekt, leerer `.godot`-Cache und eigene APPDATA:
TTF mit Originalmetadata, OTF mit Originalmetadata, TTF mit Defaultmetadata.
Alle drei Import-Exits0; erzeugte `.fontdata` vorhanden, FontFile-Daten geladen,
Textbreite berechnet, privates `user://` zur Laufzeit geprüft, Quellenhashes
unverändert. `font_probes.json` hält Engineversion und Ergebnisse fest.
Keine Fontänderung aufgrund des letzten Fortschrittseintrags vorgenommen.

## Gesamtabgleich

`python docs/qa/editor_import_font_20261113/probe_full_import.py`

Kopiert alle vorhandenen git-getrackten Dateien ohne `.godot` und ohne
Junctions/Hardlinks. Nur Projektname wird in der Kopie durch einen eindeutigen
Testnamen ersetzt. Alle aktivierten Plugins und originalen Importeinstellungen
bleiben aktiv. Originaldateien werden vor/nach dem Lauf gehasht. Import hat
20 Minuten Zeitlimit. Dieser erste Lauf mit 33.838 Dateien endete nach 358,12s
mit Exit0 und 21.074 Importdateien, vollständigem Reimport-/Editorlayoutabschluss
und unveränderten Originalquellen. Keine Script-/Enginefehler, keine ObjectDB-
Leakmeldung. Es bleibt `Orphan StringName: Node` / ein unbeanspruchter StringName
beim Editorende; diese Aufräumdiagnose wird nicht verschwiegen.

`full_import.json` enthält die erste Runnerfassung: APPDATA isoliert, aber kein
Vorher/Nachher-Fingerprint des Originalprofils. Die mittlerweile verbesserte
Runnerfassung erfasst diesen Fingerprint und die Basis vor dem Kopieren und
schreibt dieselben Bytes, die sie hasht. Ihr kompletter Neuimport wurde nicht
erneut ausgeführt; diese zusätzlichen Guards werden nicht rückwirkend behauptet.

`python docs/qa/editor_import_font_20261113/verify_full_cache.py <local_runs/full_ID>`

Die anschließende Runtimeprobe lädt beide Fonts und instanziiert das tatsächliche
Hauptmenü aus genau diesem frischen Cache. Exakter `user://`-Pfad, Quellen und
echtes Spielerprofil geprüft; Exit0, Marker, keine Fehler/Leaks. Ergebnis:
`fresh_cache_runtime.json`. Der Quellenvergleich stammt aus dem Gesamtimport;
der Runtimecheck belegt zusätzlich den unveränderten echten Profilfingerprint.

`verify_probe_process.py` prüft den neuen Timeouthelfer mit einem echten Python-
Launcher samt Kindprozess: Timeout geliefert und Kind beendet. Kein verbleibender
Prozess (`timeout_verification.json`). Fontproben mit verschärften Log-, Quellen-,
Metadaten- und Profilguards erneut bestanden.

`evidence_logs.zip` enthält rohe Logs und die vollständige Quellenhashliste ohne
Cache oder Profile. SHA256 der ZIP und ihrer Einzeldateien: `summary.json`.
Ergebnis: frischer Gesamtimport wieder möglich, früherer nativer Absturz weiterhin
ohne bewiesene Ursache. Kein Produktfix auf Verdacht; diese Task ist ein
abgeschlossener Diagnoseschritt, keine Zusage sporadischer Absturzfreiheit.

## Externe Vergleichshinweise, keine lokale Ursachenzuordnung

Godot dokumentiert einen [GDExtension-/Headless-Absturz beim Beenden](https://github.com/godotengine/godot/issues/111645)
sowie einen [WorkerThread-Absturz nach Cleanimport](https://github.com/godotengine/godot/issues/123622).
Unser früherer Import endete ohne Abschlussmarker mitten im Fortschritt; ohne
symbolisierten Stack kann keiner dieser Befunde als identische Ursache gelten.
Der [ältere Fontfallback-Deadlock](https://github.com/godotengine/godot/issues/103696)
ist ebenfalls kein Beweis für diesen Windows-Access-Violation-Abbruch.

## Grenzen

Ein erfolgreicher Einzelimport schließt einen sporadischen Parallelfehler nicht
aus. Kein stilles Abschalten von Plugins oder unbewiesener Engine-/Assetfix.
Keine neue EXE, native GPU-/FPS- oder vollständige Spielabnahme.
