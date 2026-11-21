# Godot-Prüfung des Tripo-Tankers

Das separate Godot-4.6.2-Projekt lädt die GLB-Dateien über
`GLTFDocument.append_from_file()` und `generate_scene()`. Es misst die
tatsächlich importierten Mesh-Oberflächen und ihre transformierten Vertices.
Der Verifier prüft Maße, Zentrierung, Bodenpivot, Dreiecke, Materialien, UVs,
Albedo-Texturen und eingebettete Bilder. `import_evidence.json` hält Messwerte
und SHA-256-Hashes fest.

Für den Größenvergleich verwendet das Projekt den Entermesser-GLB aus dem
Main-Katalog. Vor dem Import wird sein SHA-256 geprüft. Der Katalog setzt den
Maßstab auf 0,22 und das 16 Einheiten lange Modell damit auf 3,52 Welt-Einheiten.
Der Tanker ist 9,5744 Welt-Einheiten lang.

`segmented_*.png` zeigt den bereinigten Tanker mit den einzelnen Materialien.
`atlas_*.png` zeigt dessen Atlasfassung. Die Aufnahmen für Vorder- und
Heckansicht verwenden paarweise dieselbe orthografische Kamera, Ausleuchtung
und Auflösung. `scale_*.png` zeigt Tanker und Entermesser bei Spielmaßstab.
`capture_evidence.json` dokumentiert Renderer und Kamera. Die Aufnahmen
stammen aus dem separaten Projekt mit dem Godot-Kompatibilitätsrenderer.

## Wiederholen

Aus diesem Ordner in PowerShell aufrufen. Der Import benötigt die drei
Tanker-Exporte und das Entermesser-GLB am Pfad in `models.gd`.

```powershell
$engine = (Get-Command godot_console.exe).Source
python C:/Users/bjoer/.codex/skills/godot-game-verification/scripts/run_checks.py --project . --manifest checks.json --godot $engine --output check_runs
$capture = Start-Process -FilePath (Get-Command python.exe).Source -ArgumentList @('capture_hidden.py', $engine) -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput 'capture_stdout.log' -RedirectStandardError 'capture_stderr.log'
$capture.ExitCode
python compare_pngs.py
```

Der Aufnahmeprozess benutzt einen separaten Windows-Desktop. Das Vergleichsskript
benötigt Pillow und misst Farbkanalabweichungen zwischen den Bildpaaren im
sichtbaren Schiffsbereich. Die Zahlen beschreiben die Aufnahmen bei dieser
festen Beleuchtung. Visuelle Freigabe und Einsatz im Spiel sind eigene
Prüfschritte.
