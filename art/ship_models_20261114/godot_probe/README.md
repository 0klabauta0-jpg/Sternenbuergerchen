# Isolierter Godot-Import der Schiffskandidaten

Dieses kleine Godot-4.6.2-Projekt importiert die GLB-Dateien aus den fuenf
Nachbarordnern direkt per `GLTFDocument`. Der Hauptprojekt-Cache, Autoloads,
Runtime und die laufende Blender-Sitzung werden dabei nicht verwendet.

`probe.gd` prueft vorhandene Geometrie, endliche Positionen/Transforms,
vollstaendige Einheitsnormalen, Indexgrenzen, Dreiecks-/Materialzahlen gegen
die GLB-Accessors, Bounds, zentrierten Bodenpivot und vorhandene Animationen.
Jeder Report bindet seine Ergebnisse an den SHA-256 der gelesenen GLB-Datei.
Source-Topologie, Selbstschnitt, UV-Qualitaet, Gameplay-Kollisionen und
kuenstlerische Abnahme werden durch diesen Enginecheck nicht bewiesen.

Die Caterpillar-Animation wird bei einem Drittel, zwei Dritteln und am Ende
abgetastet. Acht seitliche `CargoDoor_*`-Bauteile und `ServiceLiftDeck` muessen
sich bewegen; `Hull` bleibt fest. Eine weitere Bugklappe wird in den
Bewegungsdaten aufgefuehrt. Der Zentrierungscheck bezieht sich bei dieser
beweglichen Baugruppe auf `Hull`: der neu modellierte seitliche Aufzug
erweitert den Gesamtumriss. Beide Bounds und der Gesamtmittelpunkt stehen
getrennt im Bericht. Das kombinierte Demonstrationsclip soll am Ende
wieder geschlossen sein. Es ist keine Gameplay-Ansteuerung.

Headless-Pruefung mit strenger Fehler-/Leak-Erkennung:

```powershell
python C:/Users/bjoer/.codex/skills/godot-game-verification/scripts/run_checks.py --godot C:/Users/bjoer/AppData/Local/Programs/Godot/Godot_v4.6.2-stable_win64_console.exe --project . --manifest checks.json --filter all_ships --output verification
```

Native Aufnahmen (tatsaechlich in Godot gerenderte importierte Modelle):

```powershell
./run_native.ps1
```

Mit `-Ships 'prospector,vulture,gladius,hornet'` lassen sich die statischen
Modelle separat pruefen. Der Runner startet nur seinen eigenen begrenzten
Prozess; native Aufnahmen verwenden Compatibility/OpenGL, 960x720, 30 FPS,
gleiches Studiolicht und je Modell eine feste Kamera-/Ausschnittsdefinition.
Geschlossene und geoeffnete Caterpillar verwenden dasselbe Framing.
Die Bodenplatte darf fuer einen abgesenkten Aufzug unterhalb des Hull-Pivots
liegen; die numerische Bodenpivotpruefung verwendet die geschlossene Pose.

`runs/` enthaelt jeweils neue JSON-Reports und Aufnahmen, `verification/`
die unveraenderten Logs des strengen Headless-Runners, `native_logs/` die
nativen Prozesslogs. Fruehere Laeufe sind historische Zwischenstaende; nur
die SHA-Zuordnung entscheidet, zu welcher GLB-Version sie gehoeren.
